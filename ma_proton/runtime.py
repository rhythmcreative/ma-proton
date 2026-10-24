"""
runtime.py - Wine Darwin runtime detection, validation, and component discovery.
"""

import os
import subprocess
from pathlib import Path
from typing import Optional, Dict, Any, List

class RuntimeInfo:
    def __init__(
        self,
        name: str,
        root_path: Path,
        wine_bin: Path,
        wineserver_bin: Path,
        wineboot_bin: Optional[Path] = None,
        winecfg_bin: Optional[Path] = None,
        regedit_bin: Optional[Path] = None,
        lib_dir: Optional[Path] = None,
        gptk_dir: Optional[Path] = None,
        dxmt_dir: Optional[Path] = None,
        dxvk_dir: Optional[Path] = None,
        version: str = "Unknown"
    ):
        self.name = name
        self.root_path = root_path
        self.wine_bin = wine_bin
        self.wineserver_bin = wineserver_bin
        self.wineboot_bin = wineboot_bin or wine_bin
        self.winecfg_bin = winecfg_bin or wine_bin
        self.regedit_bin = regedit_bin or wine_bin
        self.lib_dir = lib_dir
        self.gptk_dir = gptk_dir
        self.dxmt_dir = dxmt_dir
        self.dxvk_dir = dxvk_dir
        self.version = version

    def has_gptk(self) -> bool:
        return self.gptk_dir is not None and self.gptk_dir.exists()

    def has_dxmt(self) -> bool:
        return self.dxmt_dir is not None and self.dxmt_dir.exists()

    def has_dxvk(self) -> bool:
        return self.dxvk_dir is not None and self.dxvk_dir.exists()

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "version": self.version,
            "root": str(self.root_path),
            "wine": str(self.wine_bin),
            "wineserver": str(self.wineserver_bin),
            "has_gptk": self.has_gptk(),
            "has_dxmt": self.has_dxmt(),
            "has_dxvk": self.has_dxvk()
        }

class RuntimeManager:
    """Discovers, validates, and manages Wine runtime installations on macOS."""

    KNOWN_SEARCH_PATHS = [
        # 1. Custom / Standalone ma-proton runtime
        Path.home() / ".ma-proton" / "runtime",
        # 2. CrossOver macOS runtime
        Path("/Applications/CrossOver.app/Contents/SharedSupport/CrossOver"),
        # 3. Whisky runtime
        Path.home() / "Library" / "Application Support" / "com.isaacmarovitz.Whisky" / "Libraries" / "Wine",
        # 4. Apple GPTK default installation path
        Path("/usr/local/opt/game-porting-toolkit"),
        # 5. Homebrew wine
        Path("/opt/homebrew")
    ]

    @classmethod
    def probe_runtime(cls, base_path: Path) -> Optional[RuntimeInfo]:
        if not base_path.exists():
            return None

        # CrossOver specific layout
        cx_bin = base_path / "CrossOver-Hosted Application"
        if cx_bin.exists():
            wine = cx_bin / "wineloader"
            if not wine.exists():
                wine = cx_bin / "wine"
            wineserver = cx_bin / "wineserver"
            wineboot = cx_bin / "wine" # cx uses wine --bottle
            
            # Lib paths
            gptk_dir = base_path / "lib64" / "apple_gptk"
            dxmt_dir = base_path / "lib" / "dxmt"
            dxvk_dir = base_path / "lib" / "dxvk"
            lib_dir = base_path / "lib64"

            version = cls._get_wine_version(wine)
            return RuntimeInfo(
                name="CrossOver Wine Darwin Engine",
                root_path=base_path,
                wine_bin=wine,
                wineserver_bin=wineserver,
                wineboot_bin=wine,
                winecfg_bin=wine,
                regedit_bin=wine,
                lib_dir=lib_dir,
                gptk_dir=gptk_dir if gptk_dir.exists() else None,
                dxmt_dir=dxmt_dir if dxmt_dir.exists() else None,
                dxvk_dir=dxvk_dir if dxvk_dir.exists() else None,
                version=version
            )

        # Standard Unix/Wine hierarchy: bin/wine64, bin/wineserver
        bin_dir = base_path / "bin"
        if not bin_dir.exists():
            bin_dir = base_path

        wine = bin_dir / "wine64"
        if not wine.exists():
            wine = bin_dir / "wine"
        wineserver = bin_dir / "wineserver"

        if wine.exists() and wineserver.exists():
            version = cls._get_wine_version(wine)
            gptk_dir = base_path / "lib" / "apple_gptk"
            dxmt_dir = base_path / "lib" / "dxmt"
            dxvk_dir = base_path / "lib" / "dxvk"
            return RuntimeInfo(
                name="Standalone Wine Darwin Runtime",
                root_path=base_path,
                wine_bin=wine,
                wineserver_bin=wineserver,
                wineboot_bin=bin_dir / "wineboot",
                winecfg_bin=bin_dir / "winecfg",
                regedit_bin=bin_dir / "regedit",
                lib_dir=base_path / "lib",
                gptk_dir=gptk_dir if gptk_dir.exists() else None,
                dxmt_dir=dxmt_dir if dxmt_dir.exists() else None,
                dxvk_dir=dxvk_dir if dxvk_dir.exists() else None,
                version=version
            )

        return None

    @classmethod
    def _get_wine_version(cls, wine_bin: Path) -> str:
        try:
            res = subprocess.run(
                [str(wine_bin), "--version"],
                capture_output=True,
                text=True,
                timeout=5
            )
            out = res.stdout.strip() or res.stderr.strip()
            # If multiple lines, take first
            return out.splitlines()[0] if out else "Unknown"
        except Exception:
            return "Unknown"

    @classmethod
    def find_all_runtimes(cls) -> List[RuntimeInfo]:
        runtimes = []
        for path in cls.KNOWN_SEARCH_PATHS:
            info = cls.probe_runtime(path)
            if info:
                runtimes.append(info)
        return runtimes

    @classmethod
    def get_best_runtime(cls, preferred_path: Optional[str] = None) -> RuntimeInfo:
        if preferred_path and preferred_path != "auto":
            custom_info = cls.probe_runtime(Path(preferred_path))
            if custom_info:
                return custom_info

        all_runtimes = cls.find_all_runtimes()
        if not all_runtimes:
            raise RuntimeError(
                "No se encontró ningún motor Wine/Darwin compatible en el sistema.\n"
                "Instala CrossOver, Whisky o el Apple Game Porting Toolkit para proveer el runtime."
            )

        # Prioritize runtimes with GPTK/Metal support
        for r in all_runtimes:
            if r.has_gptk():
                return r
        return all_runtimes[0]
