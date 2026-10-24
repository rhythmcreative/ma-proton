"""
cli.py - Main Command Line Interface for ma-proton.
Implements the full Proton command contract plus native macOS utilities.
"""

import sys
import argparse
import os
from pathlib import Path

from ma_proton.compat import SystemCompatibility
from ma_proton.config import ConfigManager
from ma_proton.runtime import RuntimeManager
from ma_proton.prefix import PrefixManager
from ma_proton.graphics import GraphicsManager
from ma_proton.sync import SynchronizationManager
from ma_proton.audio import AudioManager
from ma_proton.steam import SteamIntegration
from ma_proton.process import WineProcessRunner

def build_full_env(cfg: dict, runtime_info, prefix_path: Path, backend: str, sync_mode: str, hud: bool) -> dict:
    env = os.environ.copy()
    
    # 1. Base Wine environment
    env["WINEPREFIX"] = str(prefix_path)
    env["WINEDEBUG"] = cfg.get("wine_debug", "-all")
    
    # 2. Graphics translation (DirectX -> Metal)
    gfx_mgr = GraphicsManager(
        backend=backend,
        enable_metal_hud=hud,
        enable_dxvk_hud=cfg.get("dxvk_hud", False),
        retina_mode=cfg.get("retina_mode", True)
    )
    env.update(gfx_mgr.get_env_variables())
    
    # 3. Darwin Synchronization (MSync / Mach Semaphores)
    sync_mgr = SynchronizationManager(mode=sync_mode)
    env.update(sync_mgr.get_env_variables())
    
    # 4. Audio CoreAudio
    audio_mgr = AudioManager(driver=cfg.get("audio_driver", "coreaudio"))
    env.update(audio_mgr.get_env_variables())
    
    # 5. Steam compatibility
    env.update(SteamIntegration.get_env_variables())
    
    # 6. Library fallbacks for Darwin dynamic loader
    if runtime_info.lib_dir and runtime_info.lib_dir.exists():
        existing_dyld = env.get("DYLD_FALLBACK_LIBRARY_PATH", "")
        env["DYLD_FALLBACK_LIBRARY_PATH"] = f"{runtime_info.lib_dir}:{existing_dyld}"
        
    return env

def handle_run(args, unknown_args):
    # Determine target executable
    target_exe = Path(args.exe).resolve()
    if not target_exe.is_file():
        sys.exit(f"[-] Error: Archivo ejecutable no encontrado: {target_exe}")

    config_mgr = ConfigManager()
    cfg = config_mgr.get_profile(args.profile) if args.profile else config_mgr.config

    # Parameter overrides
    backend = args.backend or cfg.get("graphics_backend", "gptk")
    sync_mode = args.sync or cfg.get("sync_mode", "msync")
    hud = args.hud or cfg.get("metal_hud", False)

    # Determine prefix
    if args.prefix:
        prefix_path = Path(args.prefix).resolve()
    else:
        prefix_path = SteamIntegration.get_steam_prefix(Path(cfg.get("default_prefix")))

    # Locate Wine Darwin runtime
    runtime_info = RuntimeManager.get_best_runtime(cfg.get("runtime"))

    # Build environment
    env = build_full_env(cfg, runtime_info, prefix_path, backend, sync_mode, hud)

    # Initialize / update prefix
    prefix_mgr = PrefixManager(prefix_path, runtime_info, env)
    prefix_mgr.initialize()

    # Install graphics translation DLLs if needed
    gfx_mgr = GraphicsManager(backend=backend)
    gfx_mgr.install_backend_dlls(prefix_mgr.system32_dir, runtime_info)

    # Execute process
    runner = WineProcessRunner(runtime_info.wine_bin, runtime_info.wineserver_bin, env)
    ret_code = runner.execute(target_exe, unknown_args)
    sys.exit(ret_code)

def handle_status(args):
    print("==================================================================")
    print("                    ma-proton Diagnósticos del Sistema           ")
    print("==================================================================")
    diag = SystemCompatibility.get_full_diagnostics()
    for k, v in diag.items():
        print(f"  {k.ljust(18)}: {v}")
    print("------------------------------------------------------------------")
    print("  Motores Wine Darwin detectados:")
    runtimes = RuntimeManager.find_all_runtimes()
    if not runtimes:
        print("  [!] Ningún motor Wine detectado en rutas estándar.")
    else:
        for idx, r in enumerate(runtimes, 1):
            print(f"  [{idx}] {r.name} ({r.version})")
            print(f"      Ruta: {r.root_path}")
            print(f"      Soporte GPTK (Metal): {'Sí' if r.has_gptk() else 'No'}")
            print(f"      Soporte DXMT (D3D11): {'Sí' if r.has_dxmt() else 'No'}")
            print(f"      Soporte DXVK (Vulkan): {'Sí' if r.has_dxvk() else 'No'}")
    print("==================================================================")

def handle_init(args):
    config_mgr = ConfigManager()
    cfg = config_mgr.config
    prefix_path = Path(args.prefix).resolve() if args.prefix else Path(cfg.get("default_prefix"))
    backend = args.backend or cfg.get("graphics_backend", "gptk")
    sync_mode = cfg.get("sync_mode", "msync")

    runtime_info = RuntimeManager.get_best_runtime(cfg.get("runtime"))
    env = build_full_env(cfg, runtime_info, prefix_path, backend, sync_mode, False)

    prefix_mgr = PrefixManager(prefix_path, runtime_info, env)
    print(f"[*] Inicializando prefijo ma-proton en: {prefix_path}")
    prefix_mgr.initialize(force=True)

    gfx_mgr = GraphicsManager(backend=backend)
    gfx_mgr.install_backend_dlls(prefix_mgr.system32_dir, runtime_info)
    print("[+] Prefijo inicializado y configurado con éxito.")

def handle_kill(args):
    config_mgr = ConfigManager()
    cfg = config_mgr.config
    prefix_path = Path(args.prefix).resolve() if args.prefix else Path(cfg.get("default_prefix"))
    runtime_info = RuntimeManager.get_best_runtime(cfg.get("runtime"))
    
    env = os.environ.copy()
    env["WINEPREFIX"] = str(prefix_path)
    print(f"[*] Deteniendo todos los procesos de Wine en {prefix_path}...")
    import subprocess
    subprocess.run([str(runtime_info.wineserver_bin), "-k"], env=env)
    print("[+] Procesos finalizados.")

def handle_wine_utility(utility_name: str, args):
    config_mgr = ConfigManager()
    cfg = config_mgr.config
    prefix_path = Path(args.prefix).resolve() if args.prefix else Path(cfg.get("default_prefix"))
    runtime_info = RuntimeManager.get_best_runtime(cfg.get("runtime"))
    env = build_full_env(cfg, runtime_info, prefix_path, "gptk", "msync", False)
    
    import subprocess
    cmd = [str(runtime_info.wine_bin), utility_name]
    subprocess.run(cmd, env=env)

def handle_steam(args, unknown_args):
    config_mgr = ConfigManager()
    cfg = config_mgr.config
    prefix_path = Path(args.prefix).resolve() if args.prefix else Path(cfg.get("default_prefix"))
    backend = args.backend or cfg.get("graphics_backend", "gptk")
    sync_mode = args.sync or cfg.get("sync_mode", "msync")
    hud = args.hud or cfg.get("metal_hud", False)

    runtime_info = RuntimeManager.get_best_runtime(cfg.get("runtime"))
    env = build_full_env(cfg, runtime_info, prefix_path, backend, sync_mode, hud)

    # Auto-detect display resolution and adapt scale automatically
    scale_arg = getattr(args, "scale", "auto")
    w, h, auto_scale, auto_dpi = SystemCompatibility.get_display_resolution_and_scale()
    if scale_arg == "auto":
        chosen_scale = auto_scale
        chosen_dpi = auto_dpi
        print(f"[*] Pantalla detectada: {w}x{h} -> Adaptando automáticamente a: {chosen_scale}x (DPI: {chosen_dpi})")
    else:
        try:
            chosen_scale = float(scale_arg)
            chosen_dpi = int(chosen_scale * 96)
        except ValueError:
            chosen_scale = auto_scale
            chosen_dpi = auto_dpi
        print(f"[*] Escala seleccionada: {chosen_scale}x (DPI: {chosen_dpi})")

    env["MA_PROTON_SCALE"] = str(chosen_scale)

    prefix_mgr = PrefixManager(prefix_path, runtime_info, env)
    prefix_mgr.initialize()
    prefix_mgr.apply_retina_tweak(dpi=chosen_dpi)

    gfx_mgr = GraphicsManager(backend=backend)
    gfx_mgr.install_backend_dlls(prefix_mgr.system32_dir, runtime_info)

    ret = SteamIntegration.launch_steam(prefix_path, runtime_info, env, extra_args=unknown_args)
    sys.exit(ret)

def main():
    # Valve Proton contract compatibility:
    # Steam often executes: `proton run <game.exe>` or `proton waitforexitandrun <game.exe>`
    # or directly: `proton <game.exe>`
    if len(sys.argv) > 1 and sys.argv[1] in ["waitforexitandrun"]:
        sys.argv[1] = "run"
    elif len(sys.argv) > 1 and (sys.argv[1].endswith(".exe") or sys.argv[1].endswith(".bat")):
        sys.argv.insert(1, "run")

    parser = argparse.ArgumentParser(
        prog="ma-proton",
        description="ma-proton: Traductor y motor de compatibilidad Windows para macOS (Proton para Darwin/Metal)"
    )
    subparsers = parser.add_subparsers(dest="subcommand", help="Comandos disponibles")

    # Command: run
    run_parser = subparsers.add_parser("run", help="Ejecutar un juego o ejecutable de Windows")
    run_parser.add_argument("exe", help="Ruta al archivo .exe de Windows")
    run_parser.add_argument("--prefix", "-p", help="Ruta personalizada del prefijo")
    run_parser.add_argument("--backend", "-b", choices=["gptk", "dxmt", "dxvk", "wined3d"], help="Motor de traducción gráfica")
    run_parser.add_argument("--sync", "-s", choices=["msync", "esync", "server"], help="Modo de sincronización (MSync recomendado)")
    run_parser.add_argument("--hud", action="store_true", help="Activar Metal Performance HUD")
    run_parser.add_argument("--profile", help="Cargar perfil de juego específico")

    # Command: status
    subparsers.add_parser("status", help="Mostrar estado del sistema, GPU Metal y runtimes Wine")

    # Command: init
    init_parser = subparsers.add_parser("init", help="Crear o actualizar un prefijo de compatibilidad")
    init_parser.add_argument("--prefix", "-p", help="Ruta del prefijo")
    init_parser.add_argument("--backend", "-b", choices=["gptk", "dxmt", "dxvk", "wined3d"], help="Backend gráfico por defecto")

    # Command: kill
    kill_parser = subparsers.add_parser("kill", help="Matar instancias colgadas de Wine y wineserver")
    kill_parser.add_argument("--prefix", "-p", help="Ruta del prefijo")

    # Command: winecfg
    cfg_parser = subparsers.add_parser("winecfg", help="Abrir panel de configuración de Wine")
    cfg_parser.add_argument("--prefix", "-p", help="Ruta del prefijo")

    # Command: regedit
    reg_parser = subparsers.add_parser("regedit", help="Abrir Editor de Registro de Windows")
    reg_parser.add_argument("--prefix", "-p", help="Ruta del prefijo")

    # Command: taskmgr
    task_parser = subparsers.add_parser("taskmgr", help="Abrir Administrador de Tareas de Windows")
    task_parser.add_argument("--prefix", "-p", help="Ruta del prefijo")

    # Command: cmd
    cmd_parser = subparsers.add_parser("cmd", help="Abrir consola de comandos Windows (cmd.exe)")
    cmd_parser.add_argument("--prefix", "-p", help="Ruta del prefijo")

    # Command: shell
    shell_parser = subparsers.add_parser("shell", help="Abrir subshell con entorno ma-proton exportado")
    shell_parser.add_argument("--prefix", "-p", help="Ruta del prefijo")

    # Command: steam
    steam_parser = subparsers.add_parser("steam", help="Lanzar Steam para Windows (desbloquea e instala cualquier juego en Mac)")
    steam_parser.add_argument("--prefix", "-p", help="Ruta personalizada del prefijo")
    steam_parser.add_argument("--backend", "-b", choices=["gptk", "dxmt", "dxvk", "wined3d"], help="Motor de traducción gráfica")
    steam_parser.add_argument("--sync", "-s", choices=["msync", "esync", "server"], help="Modo de sincronización (MSync)")
    steam_parser.add_argument("--hud", action="store_true", help="Activar Metal Performance HUD")
    steam_parser.add_argument("--scale", default="auto", help="Factor de escala para la pantalla (auto, 1.25, 1.5, 2.0)")

    parsed, unknown = parser.parse_known_args()

    if not parsed.subcommand:
        parser.print_help()
        sys.exit(0)

    if parsed.subcommand == "run":
        handle_run(parsed, unknown)
    elif parsed.subcommand == "steam":
        handle_steam(parsed, unknown)
    elif parsed.subcommand == "status":
        handle_status(parsed)
    elif parsed.subcommand == "init":
        handle_init(parsed)
    elif parsed.subcommand == "kill":
        handle_kill(parsed)
    elif parsed.subcommand in ["winecfg", "regedit", "taskmgr", "cmd"]:
        handle_wine_utility(parsed.subcommand, parsed)
    elif parsed.subcommand == "shell":
        config_mgr = ConfigManager()
        cfg = config_mgr.config
        prefix_path = Path(parsed.prefix).resolve() if parsed.prefix else Path(cfg.get("default_prefix"))
        runtime_info = RuntimeManager.get_best_runtime(cfg.get("runtime"))
        env = build_full_env(cfg, runtime_info, prefix_path, "gptk", "msync", False)
        print(f"[*] Iniciando shell interactivo ma-proton (Prefijo: {prefix_path})...")
        shell = os.environ.get("SHELL", "/bin/zsh")
        import subprocess
        subprocess.run([shell], env=env)

if __name__ == "__main__":
    main()
