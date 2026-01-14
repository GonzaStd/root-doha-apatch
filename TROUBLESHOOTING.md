# 🛠️ TROUBLESHOOTING - root-doha-apatch

## Problemas Comunes

### ❌ `adb: device not found`

**Síntomas:**
```
$ adb devices
List of devices attached
$ ./setup_apatch.sh
adb: device not found
```

**Causas posibles:**
1. USB Debugging no está habilitado
2. La computadora no está autorizada en el device
3. Cable USB defectuoso
4. Drivers ADB no están instalados

**Soluciones:**

**Paso 1: Habilitar USB Debugging**
```bash
# En el DEVICE (físicamente):
Ajustes
  > Sistema
    > Información del dispositivo
      > Tap "Número de compilación" 7 veces
        ← Device dirá "Ya eres desarrollador"

Ajustes
  > Sistema
    > Opciones de desarrollador
      > Depuración USB ✓ (habilitar)
```

**Paso 2: Autorizar esta computadora**
```bash
# Conecta cable USB
# En el device debe aparecer pop-up:
# "¿Permitir depuración USB desde este dispositivo?"
# ✓ Presiona PERMITIR
# ✓ Marca "Recordar esta selección" (opcional)
```

**Paso 3: Reconectar ADB**
```bash
adb kill-server
adb start-server
adb devices
# Debe mostrar: ZY2276XGKK device
```

**Si sigue sin funcionar:**
```bash
# Reinstala drivers
fastboot --version  # Verificar instalación

# En Windows (usar zadig si es necesario)
# En Linux: ya está incluido en android-platform-tools
# En macOS: brew install android-platform-tools
```

---

### ❌ `APatch.apk not found`

**Síntomas:**
```
./setup_apatch.sh
[✗] APatch.apk no encontrado en la carpeta actual
```

**Solución:**
```bash
# Descarga desde:
# https://github.com/bmax121/APatch/releases

# O copia si ya la tienes:
cp ~/Downloads/APatch.apk .

# Verifica:
ls -lh APatch.apk
```

---

### ❌ `dd: permission denied`

**Síntomas:**
```
Extrayendo boot.img...
dd: open('/dev/block/bootdevice/by-name/boot_b'): Permission denied
```

**Causa:**
El comando `adb root` no funcionó correctamente.

**Solución:**
```bash
# En la PC:
adb kill-server
adb start-server
adb root
sleep 2

# Verifica que ahora devuelva uid=0:
adb shell "id"
# uid=0(root) gid=0(root) ...

# Si sigue sin funcionar:
# 1. Rebootea el device
# 2. Habilita "Opciones de desarrollador" nuevamente
# 3. Vuelve a ejecutar el script
```

---

### ❌ `Boot image not found` (en device)

**Síntomas:**
Durante el paso de parcheo, APatch no ve el boot.img

**Causa:**
El archivo no se copió correctamente al device, o APatch busca en ubicación diferente.

**Solución:**
```bash
# Verifica qué archivos hay en el device:
adb shell "ls -la /sdcard/"
adb shell "ls -la /sdcard/Downloads/"
adb shell "ls -la /data/local/tmp/"

# Si no está, cópialo manualmente:
adb push boot_b.img /sdcard/
adb push boot_b.img /data/local/tmp/

# Luego en APatch:
"Select boot image" → navega a /sdcard/ o /data/local/tmp/
```

---

### ❌ `Boot parchado not found` después del parcheo

**Síntomas:**
```
[✗] No se encontró boot parchado en el device
Ubicaciones esperadas:
  - /data/adb/ap/backup/boot.img
  - /data/adb/ap/backup/boot_patched.img
  - ...
```

**Causas:**
1. El parcheo falló en la app APatch
2. APatch guarda en ubicación diferente
3. Permisos de archivo

**Solución:**

**Opción A: Exportar manualmente desde APatch**
```bash
# En el device en la app APatch:
# Después de presionar "Patch", busca un botón "Export" o "Save"
# Guarda el archivo a /sdcard/

# Luego en la PC:
adb pull /sdcard/boot_patched.img ./
adb push boot_patched.img /data/local/tmp/boot_patched.img
```

**Opción B: Buscar en ubicaciones alternativas**
```bash
# En la PC:
adb shell "find /data -name '*boot*' -o -name '*patch*' 2>/dev/null"
adb shell "find /sdcard -name '*boot*' -o -name '*patch*' 2>/dev/null"

# Una vez encontrado:
adb pull /ruta/encontrada/boot_patched.img ./
```

**Opción C: Reintentar parcheo**
```bash
# En el device:
# Abre APatch nuevamente
# "Select boot image" → boot_b.img
# "Patch" → espera completación
# Presiona "OK"
# Espera a que muestre ubicación del archivo guardado
```

---

### ❌ `Device no bootea` después del flasheo

**Síntomas:**
- Device se queda en bootloader
- O cuelga en LineageOS splash screen
- O rebootea indefinidamente

**Importancia:** ⚠️ CRÍTICO - Posible soft-brick

**Solución (Recovery):**

```bash
# 1. Rebootea a recovery
fastboot reboot recovery

# 2. En recovery: "Wipe data/factory reset"
# 3. En recovery: Flashea ROM completo nuevamente
adb reboot recovery
# Luego en recovery: Apply update from ADB > sideload
adb sideload lineage-22.1-*.zip

# 4. Rebootea
adb reboot

# 5. El device debería bootear normalmente (sin root)
# 6. Vuelve a ejecutar el script desde el principio
```

**Si recovery tampoco arranca:**
```bash
# Contacta a soporte de APatch o revertir a firmware stock
```

---

### ⚠️ `APatch muestra "Instalar" después del reboot`

**Síntomas:**
- Después del primer reboot, abres APatch
- Dice "Funcionando" pero también "Instalar"
- Esto es NORMAL

**Explicación:**
APatch no había instalado sus binarios persistentes en `/system/bin/su` todavía.

**Solución (Normal):**
```bash
# Esto es ESPERADO después del primer reboot

# 1. Abre APatch en el device
# 2. Presiona "Instalar"
# 3. Espera 1-2 minutos
# 4. Presiona "OK"
# 5. Rebootea nuevamente
adb reboot
sleep 60

# 6. Verifica que ahora persiste:
adb shell "su -c 'id'"
# uid=0(root) ← SI PERSISTE, ¡éxito!
```

---

### ❌ `Root desaparece después del reboot`

**Síntomas:**
```bash
adb shell "su -c 'id'"
# Funciona

adb reboot
sleep 60
adb shell "su -c 'id'"
# /system/bin/sh: su: inaccessible or not found
```

**Causa:**
APatch no completó la instalación persistente correctamente.

**Solución:**

**Paso 1: Reinstalar desde APatch**
```bash
# En el device:
# 1. Abre APatch
# 2. Presiona "Instalar" (Install)
# 3. Espera completación
# 4. Presiona "OK"
```

**Paso 2: Reboot de confirmación**
```bash
# En la PC:
adb reboot
sleep 60
adb shell "su -c 'id'"
# Debe mostrar uid=0(root)
```

**Paso 3: Si aún no persiste**
```bash
# Posible corrupción de /system
# Reflashea ROM completamente:

adb reboot recovery
# En recovery: Wipe data/factory reset
# En recovery: Apply update from ADB
adb sideload lineage-22.1-*.zip

# Luego vuelve a intentar el root desde el principio
bash setup_apatch.sh
```

---

### ⚠️ `SELinux violations en logs`

**Síntomas:**
```bash
adb shell "logcat -d | grep -i 'avc.*denied'"
# Múltiples líneas de "avc: denied"
```

**Explicación:**
Es normal que APatch genere algunos SELinux denials. No afecta funcionalidad.

**Verificación:**
```bash
# Si root aún funciona, ignora los warnings:
adb shell "su -c 'id'"
# uid=0(root) ← Si funciona, está todo bien
```

---

### ❌ `Script falla al buscar boot parchado`

**Síntomas:**
```
[✗] No se encontró boot parchado en el device
Solución: intenta exportar manualmente desde APatch
```

**Pasos manuales:**

```bash
# 1. En el device en APatch:
# - Presiona "Select boot image" → boot_b.img
# - Presiona "Patch"
# - Cuando termine, busca un botón "Export" o similar
# - Guarda a /sdcard/boot_patched.img

# 2. En la PC:
adb pull /sdcard/boot_patched.img ./

# 3. Flashea manualmente:
adb push boot_patched.img /data/local/tmp/
adb root
sleep 2
adb shell "dd if=/data/local/tmp/boot_patched.img of=/dev/block/mmcblk0p54 bs=4M && sync"
adb reboot

# 4. Continúa con verificación manual
```

---

## Verificación de Salud del Sistema

Después de completar la instalación, verifica:

```bash
# 1. Root funcional
adb shell "su -c 'id'"
# Debe mostrar: uid=0(root) gid=0(root)

# 2. Binarios en lugar
adb shell "ls -la /system/bin/su"
# -rwxr-xr-x (o similar)

# 3. Kernel patch activo
adb shell "dmesg | grep -i 'kpatch\|apatch'" | head
# Puede no mostrar nada (es ok)

# 4. APatch app instalada
adb shell "pm list packages | grep apatch"
# package:me.bmax.apatch

# 5. Reboot y persistencia
adb reboot
sleep 60
adb shell "su -c 'id'"
# Debe persistir
```

---

## Contacto/Soporte

Si el problema persiste:

1. **Revisa logs detallados:**
   ```bash
   adb logcat -d > logcat.txt
   adb shell "cat /tmp/recovery.log" > recovery.txt
   adb shell "dmesg > dmesg.txt"
   ```

2. **Repositorios de soporte:**
   - APatch Issues: https://github.com/bmax121/APatch/issues
   - LineageOS doha: XDA-Developers forum

3. **Información útil para reporte:**
   - Output de `adb shell "getprop"`
   - Logs de `logcat`, `dmesg`, `recovery.log`
   - Versión de APatch exacta
   - Versión de LineageOS

---

**Última actualización:** 2026-01-14 | **Versión:** 1.0
