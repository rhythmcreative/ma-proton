"""
config.py - Persistent configuration and per-game profile management for ma-proton.
"""

import json
import os
from pathlib import Path
from typing import Dict, Any, Optional

DEFAULT_CONFIG: Dict[str, Any] = {
    "version": "1.0.0",
    "default_prefix": str(Path.home() / ".ma-proton" / "prefixes" / "default"),
    "runtime": "auto",
    "graphics_backend": "gptk",      # 'gptk', 'dxmt', 'dxvk', 'wined3d'
    "sync_mode": "msync",            # 'msync', 'esync', 'server'
    "metal_hud": False,              # Metal Performance HUD
    "dxvk_hud": False,               # DXVK onscreen statistics
    "retina_mode": True,             # HiDPI rendering in winemac.drv
    "wine_debug": "-all",            # Disable slow wine trace logging
    "windows_version": "win10",      # 'win10', 'win11', 'win7'
    "audio_driver": "coreaudio",     # Native macOS low-latency CoreAudio
    "custom_env": {}                 # Optional custom environment variables
}

class ConfigManager:
    def __init__(self, config_dir: Optional[Path] = None):
        self.config_dir = config_dir or (Path.home() / ".config" / "ma-proton")
        self.config_file = self.config_dir / "config.json"
        self.profiles_dir = self.config_dir / "profiles"
        self._ensure_directories()
        self.config = self.load_config()

    def _ensure_directories(self):
        self.config_dir.mkdir(parents=True, exist_ok=True)
        self.profiles_dir.mkdir(parents=True, exist_ok=True)

    def load_config(self) -> Dict[str, Any]:
        if not self.config_file.exists():
            self.save_config(DEFAULT_CONFIG)
            return DEFAULT_CONFIG.copy()
        try:
            with open(self.config_file, "r", encoding="utf-8") as f:
                data = json.load(f)
                # Merge with defaults in case new fields were added
                merged = DEFAULT_CONFIG.copy()
                merged.update(data)
                return merged
        except Exception:
            return DEFAULT_CONFIG.copy()

    def save_config(self, cfg: Dict[str, Any]):
        with open(self.config_file, "w", encoding="utf-8") as f:
            json.dump(cfg, f, indent=4)
        self.config = cfg

    def get(self, key: str, default: Any = None) -> Any:
        return self.config.get(key, default)

    def set(self, key: str, value: Any):
        self.config[key] = value
        self.save_config(self.config)

    def get_profile(self, profile_name: str) -> Dict[str, Any]:
        """Loads a specific game profile or falls back to base config."""
        prof_file = self.profiles_dir / f"{profile_name}.json"
        if prof_file.exists():
            try:
                with open(prof_file, "r", encoding="utf-8") as f:
                    prof_data = json.load(f)
                    merged = self.config.copy()
                    merged.update(prof_data)
                    return merged
            except Exception:
                pass
        return self.config.copy()

    def save_profile(self, profile_name: str, profile_data: Dict[str, Any]):
        prof_file = self.profiles_dir / f"{profile_name}.json"
        with open(prof_file, "w", encoding="utf-8") as f:
            json.dump(profile_data, f, indent=4)

    def list_profiles(self) -> list:
        return [p.stem for p in self.profiles_dir.glob("*.json")]
