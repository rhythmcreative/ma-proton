import unittest
from ma_proton.graphics import GraphicsManager

class TestGraphics(unittest.TestCase):
    def test_gptk_overrides(self):
        mgr = GraphicsManager(backend="gptk", enable_metal_hud=True)
        overrides = mgr.get_dll_overrides()
        self.assertIn("d3d11=n,b", overrides)
        self.assertIn("d3d12=n,b", overrides)
        
        env = mgr.get_env_variables()
        self.assertEqual(env["MTL_HUD_ENABLED"], "1")
        self.assertEqual(env["MA_PROTON_GRAPHICS_BACKEND"], "gptk")

    def test_dxmt_overrides(self):
        mgr = GraphicsManager(backend="dxmt")
        overrides = mgr.get_dll_overrides()
        self.assertIn("winemetal=n,b", overrides)
        self.assertIn("d3d11=n,b", overrides)

    def test_dxvk_overrides(self):
        mgr = GraphicsManager(backend="dxvk", enable_dxvk_hud=True)
        overrides = mgr.get_dll_overrides()
        self.assertIn("d3d9=n,b", overrides)
        env = mgr.get_env_variables()
        self.assertIn("DXVK_HUD", env)

if __name__ == "__main__":
    unittest.main()
