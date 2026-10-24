"""
prefix.py - Wine prefix management, initialization, and Windows registry optimization.
"""

import os
import subprocess
from pathlib import Path
from typing import Dict, Any, Optional

class PrefixManager:
    """Manages creation, maintenance, and registry configuration of ma-proton prefixes."""

    def __init__(self, prefix_path: Path, runtime_info, env: Dict[str, str]):
        self.prefix_path = prefix_path.resolve()
        self.runtime = runtime_info
        self.env = env.copy()
        self.env["WINEPREFIX"] = str(self.prefix_path)

    @property
    def system32_dir(self) -> Path:
        return self.prefix_path / "drive_c" / "windows" / "system32"

    @property
    def syswow64_dir(self) -> Path:
        return self.prefix_path / "drive_c" / "windows" / "syswow64"

    def is_initialized(self) -> bool:
        return (self.prefix_path / "system.reg").is_file() and self.system32_dir.is_dir()

    def initialize(self, force: bool = False) -> bool:
        """Runs wineboot to generate or update the prefix."""
        if self.is_initialized() and not force:
            return True

        print(f"[*] Inicializando prefijo de compatibilidad en: {self.prefix_path}")
        self.prefix_path.mkdir(parents=True, exist_ok=True)

        # Call wineboot with wine_bin
        cmd = [str(self.runtime.wine_bin), "wineboot", "-u"]
        try:
            subprocess.run(cmd, env=self.env, timeout=120)
        except Exception as e:
            print(f"[!] Aviso durante wineboot: {e}")

        self.apply_retina_tweak()
        self.apply_windows_version("win10")
        return self.is_initialized()

    def apply_retina_tweak(self):
        """Configures Mac Driver Retina mode in Wine registry for high-DPI displays."""
        reg_file = self.prefix_path / "retina_mode.reg"
        reg_content = (
            "Windows Registry Editor Version 5.00\n\n"
            "[HKEY_CURRENT_USER\\Software\\Wine\\Mac Driver]\n"
            '"RetinaMode"="Y"\n'
        )
        try:
            with open(reg_file, "w", encoding="utf-8") as f:
                f.write(reg_content)
            self._import_reg(reg_file)
            reg_file.unlink(missing_ok=True)
        except Exception:
            pass

    def apply_windows_version(self, version: str = "win10"):
        """Configures Windows version emulation (win10, win11, win7)."""
        reg_file = self.prefix_path / "win_version.reg"
        reg_content = (
            "Windows Registry Editor Version 5.00\n\n"
            "[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows NT\\CurrentVersion]\n"
            '"ProductName"="Windows 10 Pro"\n'
            '"CurrentBuildNumber"="19045"\n'
            '"CurrentVersion"="6.3"\n'
        )
        try:
            with open(reg_file, "w", encoding="utf-8") as f:
                f.write(reg_content)
            self._import_reg(reg_file)
            reg_file.unlink(missing_ok=True)
        except Exception:
            pass

    def _import_reg(self, reg_file_path: Path):
        try:
            subprocess.run(
                [str(self.runtime.wine_bin), "regedit", str(reg_file_path)],
                env=self.env,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=15
            )
        except Exception:
            pass
