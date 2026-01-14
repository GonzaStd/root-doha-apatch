# 🚀 QUICKSTART - root-doha-apatch

**Tiempo estimado:** 15-20 minutos

## TL;DR

```bash
# 1. Prepara el device
# - Instala LineageOS 22.1
# - Habilita USB Debugging
# - Conecta a PC

# 2. Coloca APatch.apk en esta carpeta
cp ~/Downloads/APatch.apk .

# 3. Ejecuta el script
bash scripts/setup_apatch.sh

# 4. Sigue los pasos interactivos
# (El script te guiará en cada paso)

# 5. ¡LISTO! Root persistente
adb shell "su -c 'id'"
# uid=0(root) gid=0(root) ...
```

## Requisitos Previos

- ✅ **Device:** Moto G8 Plus (doha)
- ✅ **ROM:** LineageOS 22.1
- ✅ **Bootloader:** Desbloqueado
- ✅ **PC:** adb + fastboot configurados
- ✅ **USB Debugging:** Habilitado en el device

## Pasos Detallados

### 1️⃣ Prepara el Device

```bash
# En el device:
# Ajustes > Información del dispositivo > tap "Número de compilación" 7 veces
# Ajustes > Opciones de desarrollador > Depuración USB ✓
# Conecta el cable USB
```

### 2️⃣ Descarga APatch.apk

```bash
# Descarga desde: https://github.com/bmax121/APatch/releases
# O copias el que ya tienes
cp /path/to/APatch.apk .
```

### 3️⃣ Ejecuta el Script

```bash
bash scripts/setup_apatch.sh
```

El script hará:
- ✓ Extraer boot.img
- ✓ Instalar APatch.apk
- ✓ Guiarte en parcheo manual
- ✓ Flashear boot parchado
- ✓ Verificar root
- ✓ Confirmar persistencia

### 4️⃣ Durante la Ejecución

Cuando el script lo indique:

**Paso A - Parchear en la app:**
1. Abre APatch en el device
2. "Select boot image" → elige el boot extraído
3. "Patch" → espera a que termine
4. "OK"
5. Vuelve y presiona ENTER en el script

**Paso B - Instalar persistente:**
1. Abre APatch nuevamente
2. "Instalar" → espera completación
3. "OK"

### 5️⃣ Verificar

```bash
# El script automáticamente verifica, pero puedes hacerlo manualmente:
adb shell "su -c 'id'"
# Debe mostrar: uid=0(root)

# Reboot adicional para confirmar persistencia:
adb reboot
sleep 60
adb shell "su -c 'id'"
# Debe SEGUIR mostrando: uid=0(root)
```

## Troubleshooting Rápido

| Problema | Solución |
|----------|----------|
| `adb: device not found` | Habilita USB Debugging + Autoriza en device |
| `permission denied` en dd | Ejecuta `adb root` antes |
| APatch "Instalar" cada reboot | Presiona "Instalar" una 2da vez |
| Device no bootea | Vuelve a fastboot + flashea ROM nuevamente |
| Root desaparece | APatch requiere instalación persistente (Paso B) |

## Archivos Importantes

```
.
├── README.md           ← Documentación completa
├── NOTES.md            ← Detalles técnicos
├── LICENSE             ← MIT License
└── scripts/
    └── setup_apatch.sh ← Script principal (EJECUTA ESTO)
```

## Compatibilidad

- ✅ Motorola G8 Plus (doha, XT2019-2)
- ✅ LineageOS 22.1 (Android 15)
- ✅ APatch v0.12.2+
- ❌ Otros devices (adaptable pero no testeado)

## Después de Root

Ahora puedes:
- 📱 Instalar apps que requieren root
- 🔐 Usar Magisk modules (si instalas Magisk después)
- 🛡️ Modificar sistema con root access
- 🔌 Usar ADB como superusuario

## ¿Necesitas Ayuda?

1. Lee `README.md` para documentación completa
2. Lee `NOTES.md` para detalles técnicos
3. Revisa los logs: `adb logcat -d | grep -i apatch`
4. Reporta en [APatch Issues](https://github.com/bmax121/APatch/issues)

---

**Versión:** 1.0 | **Última actualización:** 2026-01-14 | **Estado:** ✅ Probado

**¡Comienza ahora: `bash scripts/setup_apatch.sh`**
