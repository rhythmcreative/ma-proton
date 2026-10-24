import unittest
from pathlib import Path
from ma_proton.steam import SteamIntegration

class TestSteam(unittest.TestCase):
    def test_steam_exe_path(self):
        pfx = Path("/tmp/test_prefix")
        exe_path = SteamIntegration.get_steam_exe_path(pfx)
        expected = pfx / "drive_c" / "Program Files (x86)" / "Steam" / "Steam.exe"
        self.assertEqual(exe_path, expected)

    def test_steam_not_installed_initially(self):
        pfx = Path("/tmp/nonexistent_prefix_123")
        self.assertFalse(SteamIntegration.is_steam_installed(pfx))

if __name__ == "__main__":
    unittest.main()
