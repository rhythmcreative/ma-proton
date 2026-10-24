<h1 align="center">ma-proton</h1>

<div align="center">

<p><i>Proton-equivalent Windows compatibility and translation layer for modern macOS.</i></p>

[![macOS](https://img.shields.io/badge/macOS-27.2%2B%20%7C%20Sequoia%20%7C%20Sonoma-000000?style=for-the-badge&logo=apple&logoColor=white)](https://apple.com)
[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-M1--M4%20Native-grey?style=for-the-badge&logo=apple&logoColor=white)](https://apple.com)
[![Metal](https://img.shields.io/badge/Apple%20Metal-D3D11%20%2F%2012-orange?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/metal/)
[![MSync](https://img.shields.io/badge/Darwin-MSync%20Active-green?style=for-the-badge)](https://github.com/rhythmcreative/ma-proton)
[![Release](https://img.shields.io/badge/Release-v1.0.0-success?style=for-the-badge)](https://github.com/rhythmcreative/ma-proton/releases)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)

</div>

___

[![Typing SVG](https://readme-typing-svg.herokuapp.com?font=Fira+Code&size=23&pause=1000&color=F7F7F7&vCenter=true&width=435&height=30&lines=ABOUT)](https://git.io/typing-svg)

**ma-proton** is a complete Windows game compatibility and translation layer suite for macOS, inspired by the architecture of **Valve's Proton** but re-engineered from the ground up for the **Darwin XNU kernel** and the **Apple Metal API**.

It enables seamless execution of Windows (x86_64 and x86) titles and game stores (including **Steam** and **Epic Games Store**) on Apple Silicon (M1/M2/M3/M4) and Intel Macs by translating Win32/NT APIs, synchronization primitives, and DirectX calls directly into native macOS subsystems without OS-level restrictions.

___

[![Typing SVG](https://readme-typing-svg.herokuapp.com?font=Fira+Code&size=23&pause=1000&color=F7F7F7&vCenter=true&width=435&height=30&lines=FEATURES)](https://git.io/typing-svg)

- **DirectX to Metal Pipeline**: Translates Direct3D 11 and 12 directly into native Apple Metal commands via **Apple D3DMetal (GPTK)** and **DXMT**, with real-time HLSL/DXIL to MSL shader compilation. Includes **DXVK** (Vulkan over MoltenVK) for legacy DirectX 9/10 titles.
- **Darwin MSync Acceleration**: Darwin's true counterpart to Linux `Fsync`. Replaces `wineserver` bottlenecks with Mach port semaphores (`mach_semaphore`) and private `ulock` syscalls, providing sub-microsecond thread switching latency.
- **Steam & Epic Games Store Integration**: Bypasses the macOS Steam client restriction ("Available only on Windows") by providing automated deployment and launch of Windows Steam and Epic Games Store with CEF hardware acceleration.
- **Native macOS GUI Launcher**: Bundles **`ma-proton Launcher.app`**, a Swift/AppKit application providing one-click launch, store installation, and an `.exe` file picker.
- **Dynamic HiDPI Auto-Adaptation**: Automatically queries CoreGraphics to identify display resolution (1080p, 1440p QHD, 4K/5K Retina) and sets optimal DPI scaling in real-time, preventing microscopic UI rendering.
- **Apple Silicon & New WOW64 Support**: Fully optimized for Apple Silicon M-Series chips with automatic memory page granularity handling (4 KB Win32 emulated on 16 KB Darwin via Rosetta 2) and seamless 32-bit execution without native 32-bit Unix libraries.
- **Metal Performance HUD**: Real-time on-screen overlay monitoring FPS, frame times, GPU memory, and render resolution with `--hud`.

___

[![Typing SVG](https://readme-typing-svg.herokuapp.com?font=Fira+Code&size=23&pause=1000&color=F7F7F7&vCenter=true&width=435&height=30&lines=INSTALLATION)](https://git.io/typing-svg)

1. Download **`ma-proton-Launcher.zip`** from [Releases](https://github.com/rhythmcreative/ma-proton/releases).
2. Unzip and drag **`ma-proton Launcher.app`** to your `/Applications` folder.
3. If macOS displays a Gatekeeper notice, open Terminal and run:
   ```bash
   xattr -cr "/Applications/ma-proton Launcher.app"
   ```
4. (Optional) To enable the CLI tool globally from your terminal:
   ```bash
   git clone https://github.com/rhythmcreative/ma-proton.git
   cd ma-proton
   ./install.sh
   ```

___

[![Typing SVG](https://readme-typing-svg.herokuapp.com?font=Fira+Code&size=23&pause=1000&color=F7F7F7&vCenter=true&width=435&height=30&lines=USAGE)](https://git.io/typing-svg)

### Using the macOS Native App
1. Open **`ma-proton Launcher.app`** from Applications or Spotlight.
2. Click **Lanzar Steam** to open Windows Steam with all Windows games unlocked.
3. Click **Lanzar Epic Games** to open or install Epic Games Store.
4. Click **Seleccionar Archivo .EXE...** to run any standalone Windows game or installer directly.

### Using the CLI
```bash
# Launch Windows Steam (auto-scaled to your monitor)
ma-proton steam

# Launch Windows Steam with Metal HUD
ma-proton steam --hud

# Launch Epic Games Store
ma-proton epic

# Run any standalone Windows game or installer
ma-proton run "/path/to/game.exe"

# Open the GUI launcher
ma-proton app

# Check system diagnostics & Metal status
ma-proton status

# Stop all Wine processes
ma-proton kill
```

___

[![Typing SVG](https://readme-typing-svg.herokuapp.com?font=Fira+Code&size=23&pause=1000&color=F7F7F7&vCenter=true&width=435&height=30&lines=BUILD+FROM+SOURCE)](https://git.io/typing-svg)

```bash
# Clone repository
git clone https://github.com/rhythmcreative/ma-proton.git
cd ma-proton

# Run unit tests
python3 -m unittest discover tests

# Build Swift Native Launcher App
cd launcher_app
swiftc -O -target arm64-apple-macosx12.0 main.swift -o "ma-proton Launcher"

# Install locally
cd ..
./install.sh
```

___

<div align="center">

<p>Made with ❤️ from rhythmcreative.</p>

</div>
