# ma-proton

**ma-proton** es una suite completa de traducción y capa de compatibilidad de Windows para macOS, inspirada en la arquitectura de **Valve Proton** pero adaptada para el kernel **Darwin** y la API gráfica **Apple Metal**.

Permite ejecutar videojuegos y aplicaciones de Windows (x86_64 y x86) en macOS (tanto Apple Silicon M1/M2/M3/M4 como Intel) traduciendo llamadas Win32, sincronización NT y gráficos DirectX directamente a primitivas nativas de macOS.

---

## ⚡ Características Principales

* **Pipeline Gráfico DirectX a Metal:**
  * Soporte para **Apple D3DMetal (GPTK)** para DirectX 11 y 12 nativos a Metal con compilación de shaders HLSL/DXIL en tiempo real.
  * Soporte para **DXMT** (capa abierta de Direct3D 11 a Metal).
  * Soporte para **DXVK** (DirectX 9/10/11 a Vulkan sobre MoltenVK).
* **Sincronización Darwin MSync:**
  * Equivalente en macOS al `Fsync` de Linux en Proton.
  * Emplea semáforos Mach y primitivas privadas `ulock` para sincronización de hilos con latencia inferior al microsegundo.
* **Compatibilidad Total con Apple Silicon:**
  * Gestión automática de Rosetta 2 y ajuste de granularidad de páginas de memoria de 4 KB (Windows) a 16 KB (Darwin).
  * Arquitectura *New WOW64* para ejecutar títulos de 32 bits sin requerir librerías Unix de 32 bits.
* **Integración con Steam:**
  * Compatible con el contrato de ejecución de Steam (`waitforexitandrun`, `STEAM_COMPAT_DATA_PATH`, `SteamAppId`).
* **Metal Performance HUD Integrado:**
  * Monitorización de FPS, frametimes, uso de memoria GPU y resolución en pantalla con solo añadir `--hud`.

---

## 🚀 Instalación Rápida

Para instalar `ma-proton` en tu sistema y crear el enlace simbólico en `~/.local/bin/ma-proton`:

```bash
git clone https://github.com/rhythmcreative/ma-proton.git # o en tu carpeta local
cd ma-proton
./install.sh
```

Asegúrate de que `~/.local/bin` esté en tu `$PATH` (en tu `~/.zshrc`):
```bash
export PATH="${HOME}/.local/bin:${PATH}"
```

---

## 🛠️ Comandos y Uso

### 1. Diagnóstico del Sistema y Motores
Muestra la GPU Metal activa, el estado de Rosetta 2 y los motores Wine Darwin detectados:
```bash
ma-proton status
```

### 2. Ejecutar un Juego
```bash
ma-proton run "/ruta/al/juego/Game.exe"
```

Con argumentos adicionales:
```bash
# Ejecutar con el Metal Performance HUD activado
ma-proton run "/ruta/al/juego/Game.exe" --hud

# Forzar backend gráfico específico (gptk, dxmt, dxvk o wined3d)
ma-proton run "/ruta/al/juego/Game.exe" --backend gptk

# Usar un prefijo personalizado
ma-proton run "/ruta/al/juego/Game.exe" --prefix ~/.mi_prefijo
```

### 3. Usar un Perfil Preconfigurado
`ma-proton` incluye perfiles optimizados para juegos exigentes:
```bash
ma-proton run "/ruta/al/juego/Cyberpunk2077.exe" --profile cyberpunk2077
```

### 4. Herramientas del Prefijo
```bash
# Abrir panel de configuración de Wine
ma-proton winecfg

# Abrir Editor del Registro de Windows
ma-proton regedit

# Abrir Administrador de Tareas
ma-proton taskmgr

# Abrir Símbolo del Sistema (cmd.exe)
ma-proton cmd

# Abrir un shell interactivo con todas las variables de entorno de ma-proton
ma-proton shell

# Forzar el cierre de todos los procesos y el wineserver
ma-proton kill
```

---

## 🎮 Integración Directa con Steam

Puedes usar `ma-proton` directamente como lanzador para tus juegos de Steam en Mac:

1. Abre las **Propiedades** del juego en Steam.
2. En la sección **Parámetros de lanzamiento**, escribe:
   ```bash
   ma-proton run %command%
   ```
3. O con el HUD de rendimiento activado:
   ```bash
   ma-proton run %command% --hud
   ```

`ma-proton` detectará automáticamente el `SteamAppId` del juego y le asignará su propio prefijo aislado.

---

## 🧪 Pruebas Unitarias

Para ejecutar la suite de pruebas automatizadas:
```bash
python3 -m unittest discover tests
```

---

## 📚 Documentación Técnica Adicional

Para ver un análisis exhaustivo y en profundidad de cómo interactúan las capas de Metal, Mach semaphores, Rosetta 2 y el kernel Darwin, consulta [ARCHITECTURE.md](ARCHITECTURE.md).
