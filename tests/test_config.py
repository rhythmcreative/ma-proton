import unittest
import tempfile
import shutil
from pathlib import Path
from ma_proton.config import ConfigManager

class TestConfig(unittest.TestCase):
    def setUp(self):
        self.test_dir = Path(tempfile.mkdtemp())
        self.mgr = ConfigManager(config_dir=self.test_dir)

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    def test_default_config_generated(self):
        self.assertTrue(self.mgr.config_file.exists())
        self.assertEqual(self.mgr.get("graphics_backend"), "gptk")
        self.assertEqual(self.mgr.get("sync_mode"), "msync")

    def test_save_and_load_profile(self):
        self.mgr.save_profile("test_game", {"graphics_backend": "dxvk", "metal_hud": True})
        loaded = self.mgr.get_profile("test_game")
        self.assertEqual(loaded["graphics_backend"], "dxvk")
        self.assertTrue(loaded["metal_hud"])

if __name__ == "__main__":
    unittest.main()
