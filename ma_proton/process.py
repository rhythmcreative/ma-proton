"""
process.py - Process lifecycle, signal handling, and WineServer cleanup.
"""

import os
import signal
import subprocess
from pathlib import Path
from typing import List, Dict, Optional

class WineProcessRunner:
    """Manages execution and teardown of the translated Windows application."""

    def __init__(self, wine_bin: Path, wineserver_bin: Path, env: Dict[str, str]):
        self.wine_bin = wine_bin
        self.wineserver_bin = wineserver_bin
        self.env = env
        self.current_process: Optional[subprocess.Popen] = None

    def execute(self, target_exe: Path, args: List[str]) -> int:
        cmd = [str(self.wine_bin), str(target_exe)] + args

        print(f"[*] ma-proton iniciando: {target_exe.name}")
        print(f"[*] Prefijo activo: {self.env.get('WINEPREFIX')}")
        print(f"[*] Backend gráfico: {self.env.get('MA_PROTON_GRAPHICS_BACKEND', 'gptk')}")

        def handle_signal(sig, frame):
            print(f"\n[*] Señal recibida ({sig}). Cerrando proceso y wineserver...")
            self.terminate_all()
            sys_exit(130)

        # Register signal handlers
        signal.signal(signal.SIGINT, handle_signal)
        signal.signal(signal.SIGTERM, handle_signal)

        try:
            self.current_process = subprocess.Popen(cmd, env=self.env)
            return_code = self.current_process.wait()
            return return_code
        except Exception as e:
            print(f"[-] Error de ejecución: {e}")
            return 1
        finally:
            self.cleanup()

    def terminate_all(self):
        """Kills wineserver and all associated Windows processes."""
        if self.current_process and self.current_process.poll() is None:
            try:
                self.current_process.terminate()
            except Exception:
                pass

        try:
            subprocess.run(
                [str(self.wineserver_bin), "-k"],
                env=self.env,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=5
            )
        except Exception:
            pass

    def cleanup(self):
        self.current_process = None

def sys_exit(code: int):
    os._exit(code)
