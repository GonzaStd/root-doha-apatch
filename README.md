# Root Motorola G8 Plus con APatch

Guía completa y automatizada para rootear el **Motorola G8 Plus (doha)** con **LineageOS 22.1** usando **APatch v0.12.2**.

## ⚠️ Requisitos Previos

- **Device:** Motorola G8 Plus (XT2019-2, codename: doha)
- **ROM:** LineageOS 22.1 (UNOFFICIAL build, o similar)
  - Descarga desde: [XDA Thread](https://xda-developers.com)
- **Estado requerido:**
  - Bootloader desbloqueado (`flashing_unlocked`)
  - Verity deshabilitada (`vbmeta state: disabled`)
  - Device en estado de firmware limpio (sin root previo)
- **Herramientas en PC:**
  - `adb` y `fastboot` configurados
  - Python 3.x (opcional, para script mejorado)
  - `git`

## 📋 Compatibilidad Verificada

✅ Motorola G8 Plus (doha, XT2019-2)
✅ LineageOS 22.1 (build 2025-03-18, UNOFFICIAL-amogus_doha)
✅ APatch v0.12.2 (build 11142)
✅ Bootloader MBM-3.0 con Preflash validation habilitado
✅ Kernel 4.14.190+ con SELinux

**Nota:** Esta guía **NO** funcionará con fastboot directo debido a `Preflash validation` del bootloader Motorola. La solución es usar `dd` vía ADB root.

---

## 🚀 Proceso de Instalación

### Paso 0: Preparación

1. **Descarga los archivos necesarios:**
   ```bash
   # Descarga LineageOS 22.1 ROM
   # Descarga APatch.apk desde: https://github.com/bmax121/APatch/releases
   ```

2. **Instala ROM limpio en el device:**
   - Rebootea a recovery
   - Wipe data/factory reset
   - Flashea ROM vía sideload: `adb sideload lineage-22.1-*.zip`
   - Rebootea a sistema

3. **Habilita USB Debugging:**
   - Ajustes > Sistema > Información del dispositivo
   - Toca "Número de compilación" 7 veces
   - Ajustes > Sistema > Opciones de desarrollador
   - Activa "Depuración USB"
   - Autoriza esta computadora en el pop-up

### Paso 1: Ejecutar el Script Automatizado

```bash
# Coloca APatch.apk en la carpeta scripts/
cd root-doha-apatch
bash scripts/setup_apatch.sh
```

El script hará automáticamente:
- ✅ Extrae boot.img del slot activo
- ✅ Copiar a la PC
- ✅ Instalar APatch.apk en el device
- ✅ Aguardar a que parchees el boot en la app
- ✅ Flashear boot parchado vía `dd`
- ✅ Rebootear

### Paso 2: Manual - Parchear Boot en la App (⚙️ No automatizable)

Cuando el script pausar y lo indique:

1. **En el device físicamente:**
   - Abre la app **APatch**
   - Presiona **"Select boot image"**
   - Selecciona el boot.img que se copió
   - Presiona **"Patch"**
   - Espera a que termine (2-3 minutos)
   - Presiona **"OK"** cuando termine

2. **En la PC:**
   - Presiona **ENTER** en el script cuando hayas terminado

### Paso 3: Instalación Persistente

Cuando el device rebootee después del flasheo:

1. **Abre APatch nuevamente**
2. **Presiona "Instalar"** (Install)
3. Se ejecutará el instalador
4. Presiona **"OK"**

### Paso 4: Verificación Final

El script ejecutará automáticamente:

```bash
adb shell "su -c 'id && echo ROOT_VERIFICADO'"
```

Si ves `uid=0(root)` → ✅ **Root funcional**

### Paso 5: Confirmación de Persistencia

```bash
adb reboot
sleep 60
adb shell "su -c 'id'"
```

Si aún tiene `uid=0(root)` después del reboot → ✅ **ROOT PERSISTENTE - ¡COMPLETADO!**

---

## 📝 Script de Automatización

El script `scripts/setup_apatch.sh` incluye:

1. **Verificación de requisitos** (adb, APatch.apk)
2. **Extracción de boot.img** del device
3. **Instalación de APatch.apk**
4. **Pausa para parcheo manual** (guía interactiva)
5. **Flasheo automático** del boot parchado con `dd`
6. **Reboot y verificación** de root

### Uso Manual (Sin Script)

Si prefieres hacerlo manualmente:

```bash
# 1. Extraer boot.img
adb root
adb shell "dd if=/dev/block/bootdevice/by-name/boot_b of=/sdcard/boot.img bs=4M"
adb pull /sdcard/boot.img ./

# 2. Instalar APatch.apk
adb install APatch.apk

# 3. [MANUAL] Abre APatch, parchea boot.img, guarda como boot_patched.img

# 4. Flashear boot parchado
adb push boot_patched.img /data/local/tmp/
adb shell "dd if=/data/local/tmp/boot_patched.img of=/dev/block/bootdevice/by-name/boot_b bs=4M && sync"
adb reboot

# 5. Después del reboot - Abre APatch y presiona "Instalar"

# 6. Verificar
adb shell "su -c 'id'"
adb reboot
sleep 60
adb shell "su -c 'id'"
```

---

## ⚠️ Troubleshooting

### Problema: `adb: device not found`
- Solución: Habilita USB Debugging en Ajustes > Opciones de desarrollador
- Autoriza esta computadora en el pop-up del device

### Problema: `dd: permission denied`
- Solución: Ejecuta `adb root` antes de `dd`
- Verifica que `adb shell id` muestre `uid=0`

### Problema: Device no bootea después de flasheo
- Es improbable pero si ocurre:
  - Rebootea a recovery
  - Flashea ROM completo nuevamente
  - Vuelve al Paso 0

### Problema: APatch muestra "Instalar" cada vez que rebootea
- Solución: Presiona "Instalar" una segunda vez
- Espera a que complete (puede tomar 1-2 minutos)
- Los binarios se copiaran a `/system/bin/su`

### Problema: Root desaparece después del reboot
- Solución: APatch requiere instalación persistente
  - Abre APatch después de cada primer reboot
  - Presiona "Instalar" y espera completación
  - Rebootea nuevamente para verificar

---

## 🔄 ¿Por Qué Este Método?

### Limitación de Fastboot (❌ No Funciona)

El bootloader Motorola MBM-3.0 tiene `Preflash validation` habilitado, que **rechaza cualquier boot.img modificado** incluso con:
- ✅ Bootloader desbloqueado
- ✅ vbmeta deshabilitado  
- ✅ Imagen correctamente formada

Error típico: `Preflash validation failed`

### Solución: `dd` vía ADB Root (✅ Funciona)

Bypasea completamente el bootloader escribiendo directamente en `/dev/block/mmcblk0p54` sin pasar por validación fastboot.

**Ventajas:**
- Evita validación de firma del bootloader
- Sin riesgos de soft-brick
- Acceso root desde el inicio del sistema
- Aplicable a cualquier ROM/kernel en slot activo

---

## 📄 Licencia

MIT License - Ver `LICENSE` para detalles completos.

Usa libremente, modifica y distribuye mientras cites la fuente original.

---

## 🙋 Créditos

- **APatch**: [bmax121/APatch](https://github.com/bmax121/APatch)
- **LineageOS**: [LineageOS Project](https://lineageos.org)
- **Motorola Moto G8 Plus**: Community XDA-Developers

---

## 📞 Soporte

Para issues específicos:
1. Verifica Troubleshooting arriba
2. Revisa logs: `adb shell "logcat -d | grep -i 'apatch\|kpatch\|su'"`
3. Reporta en [APatch Issues](https://github.com/bmax121/APatch/issues)

---

**Última actualización:** Enero 14, 2026
**Versión:** 1.0
**Status:** ✅ Probado y Funcional
