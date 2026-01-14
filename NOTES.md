# Notas Técnicas - Root Doha APatch

## Detalles de la Implementación

### Device Target
- **Modelo:** Motorola Moto G8 Plus
- **Codename:** doha
- **SKU:** XT2019-2
- **Bootloader:** MBM-3.0-doha_retail-f9b10e522bd-210802

### ROM Objetivo
- **OS:** LineageOS 22.1
- **Android:** Android 15 (API 35)
- **Build:** 2025-03-18 (UNOFFICIAL-amogus_doha)
- **Kernel:** Linux 4.14.190+ con SELinux

### Root Tool
- **Herramienta:** APatch
- **Versión:** v0.12.2 (build 11142)
- **Repositorio:** https://github.com/bmax121/APatch
- **Licencia:** GPL-3.0

### Método: ¿Por qué `dd` y no fastboot?

#### Limitación de Fastboot (❌ NO FUNCIONA)

El bootloader Motorola MBM-3.0 implementa `Preflash validation` que:
- Verifica firma de boot.img **ANTES** de flashear
- Rechaza cualquier imagen modificada
- No puede ser deshabilitado incluso con bootloader desbloqueado

**Evidencia:**
```
fastboot flash boot_b apatch_patched.img
target reported max download size of 536870912 bytes
sending 'boot_b' (65536 KB)...
OKAY [  2.234s]
writing 'boot_b'...
Preflash validation failed
FAILED (remote failure)
fastboot: error: Command failed
```

#### Solución: `dd` vía ADB Root (✅ FUNCIONA)

**Flujo:**
1. `adb root` → Obtener acceso root en ADB
2. `adb shell dd if=boot_patched.img of=/dev/block/mmcblk0p54` → Escribir directamente
3. Bypasea completamente validación del bootloader
4. Bootea normalmente con kernel parchado

**Ventajas:**
- Evita validación de firma
- Sin interacción del bootloader
- Acceso root inmediato
- Aplicable a ROMs personalizadas

### Flujo de Instalación

```
┌─────────────────────────────┐
│ ROM Limpio (LineageOS 22.1) │
└──────────────┬──────────────┘
               │
               ▼
      ┌────────────────┐
      │ Habilita ADB + │
      │ Superusuario   │
      └────────┬───────┘
               │
               ▼
      ┌──────────────────────┐
      │ Extrae boot.img      │
      │ (de slot activo)     │
      └────────┬─────────────┘
               │
               ▼
      ┌──────────────────────┐
      │ Instala APatch.apk   │
      └────────┬─────────────┘
               │
               ▼
      ┌──────────────────────┐
      │ [MANUAL]             │
      │ Parchea boot en app  │
      │ APatch selecciona    │
      │ boot.img y lo parchea│
      └────────┬─────────────┘
               │
               ▼
      ┌──────────────────────┐
      │ Flashea con dd:      │
      │ /data/local/tmp/... →│
      │ /dev/block/mmcblk... │
      └────────┬─────────────┘
               │
               ▼
      ┌──────────────────────┐
      │ Rebootea con boot    │
      │ parchado en slot     │
      └────────┬─────────────┘
               │
               ▼
      ┌──────────────────────┐
      │ [MANUAL]             │
      │ APatch "Instalar"    │
      │ Instala su binario   │
      └────────┬─────────────┘
               │
               ▼
      ┌──────────────────────┐
      │ ✓ ROOT FUNCIONAL     │
      │ ✓ ROOT PERSISTENTE   │
      └──────────────────────┘
```

### Particiones del Device

```
Partición   | Número | Función
------------|--------|-------------------
boot_a      | p53    | Kernel + Ramdisk A
boot_b      | p54    | Kernel + Ramdisk B
system      | p37/71 | Sistema (A/B)
vendor      | p38/72 | Vendor (A/B)
product     | p39/73 | Product (A/B)
...         | ...    | Datos, cache, etc
```

**Nota:** Moto G8 Plus usa **dual-slot A/B**, necesario detectar slot activo con:
```bash
adb shell "getprop ro.boot.slot_suffix"  # Devuelve "_a" o "_b"
```

### Archivos Generados

Durante la instalación se crean:
- `boot_a.img` o `boot_b.img` - Boot original extraído
- `boot_patched_a.img` o `boot_patched_b.img` - Boot parchado

### Binarios Instalados por APatch

```
/system/bin/su                 - Binario su para root
/data/adb/ap/bin/apd           - APatch daemon
/data/adb/ap/bin/magiskboot    - Herramienta de boot
/data/adb/ap/bin/magiskpolicy  - Política SELinux
```

### SELinux Context

- **Antes:** `u:r:init:s0` (init context)
- **Después:** `u:r:magisk:s0` (APatch usa contexto Magisk para compatibilidad)

### Logs Útiles

**Verificar kernel patch cargado:**
```bash
adb shell "dmesg | grep -i 'kpatch\|apatch'"
```

**Verificar binarios de su:**
```bash
adb shell "which su && su -c 'id'"
```

**Recovery log (si es necesario):**
```bash
adb shell "cat /tmp/recovery.log"
```

### Limitaciones Conocidas

1. **APatch requiere instalación manual en cada prime reboot**
   - Solución: Presionar "Instalar" en la app después del primer reboot

2. **Bootloader MBM-3.0 rechaza fastboot**
   - Solución: Usar `dd` directo vía ADB root

3. **ROM debe ser actualizable via OTA**
   - LineageOS 22.1 soporta OTA correctamente
   - APatch preserva OTA capability

### Testing Realizado ✓

- ✓ Device bootea normalmente con kernel parchado
- ✓ Root funcional inmediatamente post-patch
- ✓ Root persiste después de múltiples reboots
- ✓ APatch app reporta "Installed" correctamente
- ✓ `su -c 'id'` retorna uid=0(root) esperado
- ✓ SELinux context correcto: `u:r:magisk:s0`
- ✓ LineageOS ROM intacta, sin corrupción
- ✓ Recuperable si falla (volver a fastboot + ROM)

### Alternativas Evaluadas ❌

1. **Fastboot flash** - Rechazado por Preflash validation
2. **Recovery flashable ZIP** - Signature verification failed
3. **Magisk** - Mismos problemas de fastboot
4. **KernelSU** - No compilado en kernel LineageOS
5. **Superuser.apk clásico** - Requiere compilación del kernel

### Conclusión

El método `adb root + dd` es la **única solución viable** para este device/ROM debido a las restricciones del bootloader Motorola MBM-3.0.

---

**Último actualizado:** 2026-01-14
**Versión:** 1.0
**Autor:** root-doha-apatch contributors
