"""
steam.py - Steam Windows Client integration and Steam Play bypass for macOS.
Solves the "Disponible solo para Windows" limitation on macOS.
"""

import os
import urllib.request
import subprocess
from pathlib import Path
from typing import Optional, Dict

STEAM_INSTALLER_URL = "https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe"

class SteamIntegration:
    """
    Manages Steam Windows client execution inside ma-proton, bypassing the
    macOS Steam client limitation where Windows games cannot be installed.
    """

    @staticmethod
    def is_steam_launch() -> bool:
        return "SteamAppId" in os.environ or "STEAM_COMPAT_DATA_PATH" in os.environ

    @staticmethod
    def get_app_id() -> Optional[str]:
        return os.environ.get("SteamAppId") or os.environ.get("SteamGameId")

    @staticmethod
    def get_compat_data_path() -> Optional[Path]:
        p = os.environ.get("STEAM_COMPAT_DATA_PATH")
        if p:
            return Path(p)
        return None

    @classmethod
    def get_steam_prefix(cls, fallback_prefix: Path) -> Path:
        compat_path = cls.get_compat_data_path()
        if compat_path:
            return compat_path / "pfx"
        
        app_id = cls.get_app_id()
        if app_id:
            return Path.home() / ".ma-proton" / "prefixes" / f"steam_{app_id}"

        return fallback_prefix

    @classmethod
    def get_env_variables(cls) -> Dict[str, str]:
        env = {}
        app_id = cls.get_app_id()
        if app_id:
            env["SteamAppId"] = app_id
            env["SteamGameId"] = app_id
        return env

    @classmethod
    def get_steam_exe_path(cls, prefix_path: Path) -> Path:
        """Returns the path to Steam.exe inside the prefix."""
        return (
            prefix_path
            / "drive_c"
            / "Program Files (x86)"
            / "Steam"
            / "Steam.exe"
        )

    @classmethod
    def is_steam_installed(cls, prefix_path: Path) -> bool:
        return cls.get_steam_exe_path(prefix_path).is_file()

    @classmethod
    def download_steam_installer(cls, target_dir: Path) -> Path:
        target_dir.mkdir(parents=True, exist_ok=True)
        dest_file = target_dir / "SteamSetup.exe"
        if not dest_file.is_file():
            print("[*] Descargando el instalador oficial de Steam para Windows...")
            urllib.request.urlretrieve(STEAM_INSTALLER_URL, dest_file)
            print(f"[+] Instalador guardado en: {dest_file}")
        return dest_file

    @classmethod
    def launch_steam(cls, prefix_path: Path, runtime_info, env: Dict[str, str], extra_args=None) -> int:
        """
        Launches Steam for Windows inside the ma-proton prefix with CEF sandbox flags.
        This completely bypasses the macOS 'Disponible solo para Windows' restriction.
        """
        steam_exe = cls.get_steam_exe_path(prefix_path)
        cache_dir = Path.home() / ".ma-proton" / "downloads"
        
        if not steam_exe.is_file():
            print("[!] Steam para Windows no está instalado en este prefijo.")
            installer = cls.download_steam_installer(cache_dir)
            print("[*] Ejecutando instalador de Steam en el prefijo...")
            subprocess.run([str(runtime_info.wine_bin), str(installer), "/S"], env=env)
            
            # Wait/verify if installed
            if not steam_exe.is_file():
                # Try non-silent in case installer needs UI
                subprocess.run([str(runtime_info.wine_bin), str(installer)], env=env)

        # Steam on Wine requires -no-cef-sandbox due to Windows security token handling
        steam_args = [
            "-no-cef-sandbox",
            "-cef-force-32bit",
            "-allwgmultigpu"
        ]
        if extra_args:
            steam_args.extend(extra_args)

        print("[+] Lanzando Steam para Windows con soporte completo Metal / MSync...")
        print("    (Todos los juegos de Windows aparecerán desbloqueados para instalar)")
        
        cmd = [str(runtime_info.wine_bin), str(steam_exe)] + steam_args
        res = subprocess.run(cmd, env=env)
        return res.returncode
