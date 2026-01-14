#!/bin/bash

#################################################################################
# Setup APatch Root para Motorola G8 Plus (doha)
# Automatiza la instalación de APatch con boot patching vía dd
#
# Uso: bash setup_apatch.sh
#################################################################################

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir con color
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

ask_continue() {
    read -p "$(echo -e ${BLUE})[Presiona ENTER para continuar]${NC} " -r
}

#################################################################################
# Verificaciones previas
#################################################################################

print_status "Verificando requisitos..."

# Verificar adb
if ! command -v adb &> /dev/null; then
    print_error "adb no encontrado. Instala Android SDK Platform Tools."
    exit 1
fi
print_success "adb disponible"

# Verificar APatch.apk
if [ ! -f "APatch.apk" ]; then
    print_error "APatch.apk no encontrado en la carpeta actual"
    print_status "Descárgalo desde: https://github.com/bmax121/APatch/releases"
    exit 1
fi
print_success "APatch.apk encontrado"

# Verificar conexión ADB
if ! adb devices | grep -q "device"; then
    print_error "Device no conectado o depuración USB no habilitada"
    print_status "Pasos:"
    print_status "1. Habilita USB Debugging en Ajustes > Opciones de desarrollador"
    print_status "2. Autoriza esta computadora en el pop-up del device"
    print_status "3. Ejecuta este script nuevamente"
    exit 1
fi
print_success "Device conectado"

DEVICE_SERIAL=$(adb devices | grep -E "^[A-Z0-9]+\s+device$" | awk '{print $1}')
print_success "Device: $DEVICE_SERIAL"

#################################################################################
# PASO 1: Extraer boot.img
#################################################################################

print_status "PASO 1: Extrayendo boot.img del device..."

# Detectar slot activo
SLOT=$(adb shell "getprop ro.boot.slot_suffix" | tr -d '\r')
print_status "Slot activo: $SLOT"

# Mapeo de slot a partición
if [ "$SLOT" = "_a" ]; then
    BOOT_PARTITION="/dev/block/bootdevice/by-name/boot_a"
    BOOT_PARTITION_NUM="53"
elif [ "$SLOT" = "_b" ]; then
    BOOT_PARTITION="/dev/block/bootdevice/by-name/boot_b"
    BOOT_PARTITION_NUM="54"
else
    print_error "Slot desconocido: $SLOT"
    exit 1
fi

# Activar ADB root
print_status "Activando ADB root..."
adb root > /dev/null 2>&1 || true
sleep 2

# Verificar root
if ! adb shell "id" | grep -q "uid=0"; then
    print_error "No se pudo obtener permisos root en ADB"
    exit 1
fi
print_success "ADB root activado"

# Extraer boot.img
BOOT_FILE="boot${SLOT}.img"
print_status "Extrayendo boot.img desde $BOOT_PARTITION..."
adb shell "dd if=$BOOT_PARTITION of=/data/local/tmp/boot.img bs=4M" > /dev/null 2>&1
adb pull /data/local/tmp/boot.img "$BOOT_FILE" > /dev/null
adb shell "rm /data/local/tmp/boot.img" > /dev/null 2>&1

if [ ! -f "$BOOT_FILE" ]; then
    print_error "No se pudo extraer boot.img"
    exit 1
fi

FILE_SIZE=$(du -h "$BOOT_FILE" | cut -f1)
print_success "boot.img extraído: $BOOT_FILE ($FILE_SIZE)"

#################################################################################
# PASO 2: Instalar APatch.apk
#################################################################################

print_status "PASO 2: Instalando APatch.apk..."

if adb install APatch.apk | grep -q "Success"; then
    print_success "APatch.apk instalado"
else
    print_warning "APatch.apk ya estaba instalado"
fi

sleep 2

#################################################################################
# PASO 3: MANUAL - Parchear boot en la app (No automatizable)
#################################################################################

print_warning "PASO 3: Parcheo Manual Requerido"
print_status "=========================================="
echo ""
echo -e "${YELLOW}Sigue estos pasos EN EL DEVICE FÍSICAMENTE:${NC}"
echo ""
echo "1. Abre la app ${BLUE}APatch${NC}"
echo "2. En la pantalla principal, presiona ${BLUE}'Select boot image'${NC}"
echo "3. Selecciona: ${YELLOW}$BOOT_FILE${NC}"
echo "4. Presiona ${BLUE}'Patch'${NC} y espera (2-3 minutos)"
echo "5. Cuando termine, presiona ${BLUE}'OK'${NC}"
echo "6. La app mostrará: ${GREEN}'Boot image patched successfully'${NC}"
echo "7. Guarda/exporta el boot parchado si es necesario"
echo ""
print_status "Vuelve aquí cuando hayas terminado en el device"
echo ""
ask_continue

#################################################################################
# PASO 4: Copiar boot parchado y flashearlo
#################################################################################

print_status "PASO 4: Extrayendo boot parchado del device..."

# APatch típicamente guarda en /data/adb/ap/backup/
# O puede estar en /sdcard/ o /data/
# Intentamos encontrarlo

PATCHED_BOOT_CANDIDATES=(
    "/data/adb/ap/backup/boot.img"
    "/data/adb/ap/backup/boot_patched.img"
    "/sdcard/Documents/boot.img"
    "/sdcard/boot_patched.img"
    "/data/local/tmp/boot_patched.img"
)

PATCHED_BOOT_PATH=""
for path in "${PATCHED_BOOT_CANDIDATES[@]}"; do
    if adb shell "[ -f '$path' ]" 2>/dev/null; then
        PATCHED_BOOT_PATH="$path"
        print_success "Boot parchado encontrado: $path"
        break
    fi
done

if [ -z "$PATCHED_BOOT_PATH" ]; then
    print_error "No se encontró boot parchado en el device"
    print_status "Ubicaciones esperadas:"
    for path in "${PATCHED_BOOT_CANDIDATES[@]}"; do
        print_status "  - $path"
    done
    print_status "Intenta exportar manualmente desde APatch y ejecuta:"
    print_status "  adb pull <ruta_en_device> boot_patched.img"
    exit 1
fi

# Copiar boot parchado
adb pull "$PATCHED_BOOT_PATH" "boot_patched_${SLOT}.img" > /dev/null
print_success "Boot parchado copiado: boot_patched_${SLOT}.img"

# Copiar al device para flashear
adb push "boot_patched_${SLOT}.img" /data/local/tmp/boot_patched.img > /dev/null 2>&1
print_success "Boot parchado copiado al device"

#################################################################################
# PASO 5: Flashear boot parchado con dd
#################################################################################

print_status "PASO 5: Flasheando boot parchado..."

if ! adb shell "dd if=/data/local/tmp/boot_patched.img of=/dev/block/mmcblk0p${BOOT_PARTITION_NUM} bs=4M && sync" > /dev/null 2>&1; then
    print_error "Error al flashear boot"
    exit 1
fi

print_success "Boot parchado flasheado correctamente"

# Limpiar
adb shell "rm /data/local/tmp/boot_patched.img" > /dev/null 2>&1

#################################################################################
# PASO 6: Rebootear
#################################################################################

print_status "PASO 6: Rebooteando device..."
adb reboot

print_status "Esperando device (60 segundos)..."
sleep 60

if ! adb devices | grep -q "device"; then
    print_warning "Device no conectado aún, esperando más..."
    sleep 30
fi

if ! adb devices | grep -q "device"; then
    print_error "Device no se conectó después del reboot"
    exit 1
fi

print_success "Device rebooteado exitosamente"

#################################################################################
# PASO 7: MANUAL - Instalar APatch persistentemente
#################################################################################

print_warning "PASO 7: Instalación Persistente (Manual)"
print_status "=========================================="
echo ""
echo -e "${YELLOW}EN EL DEVICE:${NC}"
echo ""
echo "1. Abre la app ${BLUE}APatch${NC} nuevamente"
echo "2. Presiona ${BLUE}'Instalar'${NC} (Install)"
echo "3. Presiona ${BLUE}'OK'${NC} y espera a que complete (1-2 minutos)"
echo "4. Verás mensajes de instalación"
echo "5. Cuando termine, presiona ${BLUE}'OK'${NC}"
echo ""
print_status "Vuelve aquí cuando hayas terminado"
echo ""
ask_continue

#################################################################################
# PASO 8: Verificar root
#################################################################################

print_status "PASO 8: Verificando root..."

# Activar ADB root si es necesario
adb root > /dev/null 2>&1 || true
sleep 2

if adb shell "su -c 'id'" | grep -q "uid=0(root)"; then
    print_success "ROOT FUNCIONAL ✓"
else
    print_error "Root no disponible"
    exit 1
fi

#################################################################################
# PASO 9: Verificar persistencia (Reboot final)
#################################################################################

print_status "PASO 9: Verificando persistencia..."
print_status "Rebooteando device..."

adb reboot
print_status "Esperando device (60 segundos)..."
sleep 60

if ! adb devices | grep -q "device"; then
    print_warning "Device no conectado, esperando más..."
    sleep 30
fi

# Verificar root después del reboot
if adb shell "su -c 'id'" 2>/dev/null | grep -q "uid=0(root)"; then
    print_success "ROOT PERSISTENTE ✓✓✓"
    echo ""
    print_success "=========================================="
    print_success "¡ROOT INSTALACIÓN COMPLETADA EXITOSAMENTE!"
    print_success "=========================================="
    echo ""
    adb shell "su -c 'id'"
else
    print_error "Root NO es persistente después del reboot"
    print_status "Intenta abrir APatch nuevamente y presionar 'Instalar'"
    exit 1
fi

print_success "Instalación finalizada"
