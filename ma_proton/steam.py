"""
steam.py - Steam Proton compatibility layer and AppID integration.
Allows ma-proton to be used directly as a custom Steam Compatibility Tool.
"""

import os
from pathlib import Path
from typing import Optional, Dict

class SteamIntegration:
    """
    Handles Steam-specific environment variables and Proton execution contracts.
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
        """
        If launched from Steam, the prefix is located inside STEAM_COMPAT_DATA_PATH/pfx.
        """
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
