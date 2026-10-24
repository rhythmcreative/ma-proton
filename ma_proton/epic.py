"""
epic.py - Epic Games Store integration and runner for ma-proton on macOS.
Handles downloading, silent MSI installation, and optimized Metal execution.
"""

import os
import subprocess
import urllib.request
from pathlib import Path
from typing import Optional, Dict

EPIC_INSTALLER_URL = "https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.msi"

class EpicGamesIntegration:
    """Manages Epic Games Launcher lifecycle inside ma-proton."""

    @classmethod
    def get_epic_exe_path(cls, prefix_path: Path) -> Path:
        """Returns the path to EpicGamesLauncher.exe inside the prefix."""
        # Check standard Win64 binary path
        p1 = (
            prefix_path
            / "drive_c"
            / "Program Files (x86)"
            / "Epic Games"
            / "Launcher"
            / "Portal"
            / "Binaries"
            / "Win64"
            / "EpicGamesLauncher.exe"
        )
        p2 = (
            prefix_path
            / "drive_c"
            / "Program Files"
            / "Epic Games"
            / "Launcher"
            / "Portal"
            / "Binaries"
            / "Win64"
            / "EpicGamesLauncher.exe"
        )
        if p1.is_file():
            return p1
        if p2.is_file():
            return p2
        return p1

    @classmethod
    def is_epic_installed(cls, prefix_path: Path) -> bool:
        return cls.get_epic_exe_path(prefix_path).is_file()

    @classmethod
    def download_epic_installer(cls, target_dir: Path) -> Path:
        target_dir.mkdir(parents=True, exist_ok=True)
        dest_file = target_dir / "EpicGamesLauncherInstaller.msi"
        if not dest_file.is_file():
            print("[*] Descargando el instalador oficial de Epic Games Store...")
            # User agent required for Epic servers
            req = urllib.request.Request(
                EPIC_INSTALLER_URL,
                headers={"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"}
            )
            with urllib.request.urlopen(req) as response, open(dest_file, "wb") as out_file:
                out_file.write(response.read())
            print(f"[+] Instalador guardado en: {dest_file}")
        return dest_file

    @classmethod
    def launch_epic(cls, prefix_path: Path, runtime_info, env: Dict[str, str], extra_args=None) -> int:
        """
        Launches or installs Epic Games Store inside ma-proton prefix.
        """
        epic_exe = cls.get_epic_exe_path(prefix_path)
        cache_dir = Path.home() / ".ma-proton" / "downloads"

        if not epic_exe.is_file():
            print("[!] Epic Games Store no está instalado en este prefijo.")
            installer = cls.download_epic_installer(cache_dir)
            print("[*] Ejecutando instalación de Epic Games Store...")
            # msiexec /i installer.msi /qn
            subprocess.run([str(runtime_info.wine_bin), "msiexec", "/i", str(installer), "/qn"], env=env)
            
            epic_exe = cls.get_epic_exe_path(prefix_path)
            if not epic_exe.is_file():
                # Try non-silent if unattended didn't finish
                subprocess.run([str(runtime_info.wine_bin), "msiexec", "/i", str(installer)], env=env)
                epic_exe = cls.get_epic_exe_path(prefix_path)

        if not epic_exe.is_file():
            print("[-] Error: No se pudo localizar EpicGamesLauncher.exe tras la instalación.")
            return 1

        epic_args = [
            "-SkipBuildPatchPrereq",
            "-OpenGL"
        ]
        if extra_args:
            epic_args.extend(extra_args)

        print("[+] Lanzando Epic Games Store con soporte Metal / MSync...")
        cmd = [str(runtime_info.wine_bin), str(epic_exe)] + epic_args
        res = subprocess.run(cmd, env=env)
        return res.returncode
