"""
compat.py - System and architecture compatibility checker for macOS.
"""

import os
import platform
import subprocess
from typing import Dict, Any

class SystemCompatibility:
    """Detects and validates host macOS environment, architecture, and Rosetta 2."""

    @staticmethod
    def is_macos() -> bool:
        return sys_platform() == "Darwin"

    @staticmethod
    def get_macos_version() -> str:
        try:
            res = subprocess.check_output(["sw_vers", "-productVersion"], text=True).strip()
            return res
        except Exception:
            return platform.mac_ver()[0] or "Unknown"

    @staticmethod
    def get_architecture() -> str:
        return platform.machine()

    @staticmethod
    def is_apple_silicon() -> bool:
        return platform.machine() == "arm64"

    @staticmethod
    def check_rosetta_installed() -> bool:
        """Verifies if Rosetta 2 x86_64 translation engine is available."""
        if not SystemCompatibility.is_apple_silicon():
            return True
        
        # Method 1: Check Rosetta runtime library
        rosetta_lib = "/Library/Apple/usr/libexec/oah/libRosettaRuntime"
        if os.path.exists(rosetta_lib):
            return True

        # Method 2: Test executing x86_64 true
        try:
            res = subprocess.run(
                ["arch", "-x86_64", "/usr/bin/true"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            return res.returncode == 0
        except Exception:
            return False

    @staticmethod
    def get_metal_gpu_info() -> str:
        """Returns the primary GPU name supporting Metal."""
        try:
            output = subprocess.check_output(
                ["system_profiler", "SPDisplaysDataType"],
                text=True,
                stderr=subprocess.DEVNULL
            )
            for line in output.splitlines():
                if "Chipset Model:" in line:
                    return line.split(":", 1)[1].strip()
                if "Metal Support:" in line:
                    return line.split(":", 1)[1].strip()
        except Exception:
            pass
        return "Apple Metal GPU"

    @staticmethod
    def get_display_resolution_and_scale() -> tuple:
        """
        Dynamically detects main display resolution and calculates the
        optimal scale factor and DPI to adapt Windows apps/Steam to the screen.
        Returns: (width, height, scale_factor, dpi)
        """
        w, h = 1920, 1080
        try:
            import ctypes
            cg = ctypes.cdll.LoadLibrary("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics")
            main_display = cg.CGMainDisplayID()
            cg.CGDisplayPixelsWide.restype = ctypes.c_size_t
            cg.CGDisplayPixelsHigh.restype = ctypes.c_size_t
            w = int(cg.CGDisplayPixelsWide(main_display))
            h = int(cg.CGDisplayPixelsHigh(main_display))
        except Exception:
            pass

        if w >= 3840:
            scale = 2.0
            dpi = 192
        elif w >= 2560:
            # 1440p (QHD / 2K) optimal readability
            scale = 1.35
            dpi = 130
        elif w >= 1920:
            scale = 1.15
            dpi = 110
        else:
            scale = 1.0
            dpi = 96

        return w, h, scale, dpi

    @classmethod
    def get_full_diagnostics(cls) -> Dict[str, Any]:
        return {
            "os": "macOS",
            "version": cls.get_macos_version(),
            "kernel": platform.release(),
            "arch": cls.get_architecture(),
            "apple_silicon": cls.is_apple_silicon(),
            "rosetta_ready": cls.check_rosetta_installed(),
            "gpu": cls.get_metal_gpu_info(),
            "page_size_kb": 16 if cls.is_apple_silicon() else 4
        }

def sys_platform() -> str:
    return platform.system()
