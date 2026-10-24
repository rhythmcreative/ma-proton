"""
sync.py - Synchronization subsystem manager for ma-proton (MSync / ESync / WineServer).
Translates Linux Fsync paradigm to Darwin Mach Semaphores (MSync).
"""

from typing import Dict

class SynchronizationManager:
    """
    Manages low-latency NT kernel synchronization primitives.
    In Linux, Proton uses Fsync (futex_waitv).
    In macOS (Darwin), ma-proton uses MSync (Mach port semaphores & ulock).
    """

    SUPPORTED_MODES = ["msync", "esync", "server"]

    def __init__(self, mode: str = "msync"):
        self.mode = mode.lower() if mode.lower() in self.SUPPORTED_MODES else "msync"

    def get_env_variables(self) -> Dict[str, str]:
        env = {}
        if self.mode == "msync":
            # Darwin Mach Semaphore synchronization (Optimal for Apple Silicon)
            env["WINEMSYNC"] = "1"
            env["WINEESYNC"] = "0"
            env["PROTON_USE_MSYNC"] = "1"
        elif self.mode == "esync":
            # Event synchronization emulation
            env["WINEMSYNC"] = "0"
            env["WINEESYNC"] = "1"
            env["PROTON_USE_ESYNC"] = "1"
        else:
            # Fallback to standard wineserver IPC sync
            env["WINEMSYNC"] = "0"
            env["WINEESYNC"] = "0"

        return env

    @property
    def description(self) -> str:
        if self.mode == "msync":
            return "MSync (Darwin Mach Semaphores - Ultra Low Latency)"
        if self.mode == "esync":
            return "ESync (Darwin Event / Pipe synchronization)"
        return "WineServer IPC (Standard fallback)"
