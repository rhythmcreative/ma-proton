"""
graphics.py - DirectX to Apple Metal translation subsystem manager for ma-proton.
Handles GPTK (D3DMetal), DXMT, DXVK, WineD3D, and Metal Performance HUD.
"""

from pathlib import Path
from typing import Dict, Optional
import shutil

class GraphicsManager:
    """
    Orchestrates DirectX to Metal translation layers and DLL overrides.
    """

    BACKENDS = ["gptk", "dxmt", "dxvk", "wined3d"]

    def __init__(
        self,
        backend: str = "gptk",
        enable_metal_hud: bool = False,
        enable_dxvk_hud: bool = False,
        retina_mode: bool = True
    ):
        self.backend = backend.lower() if backend.lower() in self.BACKENDS else "gptk"
        self.enable_metal_hud = enable_metal_hud
        self.enable_dxvk_hud = enable_dxvk_hud
        self.retina_mode = retina_mode

    def get_dll_overrides(self) -> str:
        """
        Builds the WINEDLLOVERRIDES string for Wine.
        'n' = native (our Metal translation DLLs)
        'b' = builtin (wine default fallback)
        """
        if self.backend == "gptk":
            # D3D11 and D3D12 mapped directly to Metal via Apple D3DMetal
            return "d3d11=n,b;d3d12=n,b;dxgi=n,b;d3d9=n,b;d3d10core=n,b"
        elif self.backend == "dxmt":
            # Direct3D 11 to Metal via open source DXMT
            return "d3d11=n,b;dxgi=n,b;winemetal=n,b;d3d10core=n,b"
        elif self.backend == "dxvk":
            # Direct3D 9/10/11 via DXVK (Vulkan over MoltenVK)
            return "d3d9=n,b;d3d10core=n,b;d3d11=n,b;dxgi=n,b"
        else:
            # Built-in WineD3D
            return "d3d11=b;d3d12=b;dxgi=b;d3d9=b"

    def get_env_variables(self) -> Dict[str, str]:
        env = {
            "WINEDLLOVERRIDES": self.get_dll_overrides(),
            "MA_PROTON_GRAPHICS_BACKEND": self.backend
        }

        # Metal Performance HUD (Apple Metal diagnostic overlay)
        if self.enable_metal_hud:
            env["MTL_HUD_ENABLED"] = "1"
        else:
            env["MTL_HUD_ENABLED"] = "0"

        # DXVK HUD
        if self.enable_dxvk_hud:
            env["DXVK_HUD"] = "fps,frametimes,gputemp,devinfo"

        # MoltenVK optimization flags for Vulkan-to-Metal translation
        env["MVK_CONFIG_RESILIENT_FAILURES"] = "1"
        env["MVK_CONFIG_FAST_MATH_ENABLED"] = "1"
        env["MVK_CONFIG_SYNCHRONOUS_QUEUE_SUBMITS"] = "0"

        return env

    def install_backend_dlls(self, prefix_system32: Path, runtime_info) -> bool:
        """
        Injects the corresponding translation DLLs into the prefix's Windows/system32 folder.
        """
        if not prefix_system32.exists():
            return False

        source_dir: Optional[Path] = None
        if self.backend == "gptk" and runtime_info.has_gptk():
            source_dir = runtime_info.gptk_dir / "wine" / "x86_64-windows"
        elif self.backend == "dxmt" and runtime_info.has_dxmt():
            source_dir = runtime_info.dxmt_dir / "x86_64-windows"
        elif self.backend == "dxvk" and runtime_info.has_dxvk():
            source_dir = runtime_info.dxvk_dir / "x86_64-windows"

        if source_dir and source_dir.exists():
            for dll_file in source_dir.glob("*.dll"):
                dest = prefix_system32 / dll_file.name
                shutil.copy2(dll_file, dest)
            return True
        return False
