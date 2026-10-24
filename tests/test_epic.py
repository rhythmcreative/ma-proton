import unittest
from pathlib import Path
from ma_proton.epic import EpicGamesIntegration

class TestEpic(unittest.TestCase):
    def test_epic_exe_path(self):
        pfx = Path("/tmp/test_prefix")
        exe_path = EpicGamesIntegration.get_epic_exe_path(pfx)
        expected = pfx / "drive_c" / "Program Files (x86)" / "Epic Games" / "Launcher" / "Portal" / "Binaries" / "Win64" / "EpicGamesLauncher.exe"
        self.assertEqual(exe_path, expected)

    def test_epic_not_installed_initially(self):
        pfx = Path("/tmp/nonexistent_epic_123")
        self.assertFalse(EpicGamesIntegration.is_epic_installed(pfx))

if __name__ == "__main__":
    unittest.main()
