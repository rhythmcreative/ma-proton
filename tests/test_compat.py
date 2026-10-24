import unittest
from ma_proton.compat import SystemCompatibility

class TestCompat(unittest.TestCase):
    def test_macos_detection(self):
        self.assertTrue(SystemCompatibility.is_macos())

    def test_architecture(self):
        arch = SystemCompatibility.get_architecture()
        self.assertIn(arch, ["arm64", "x86_64"])

    def test_full_diagnostics(self):
        diag = SystemCompatibility.get_full_diagnostics()
        self.assertEqual(diag["os"], "macOS")
        self.assertIn("gpu", diag)
        self.assertIn("rosetta_ready", diag)

if __name__ == "__main__":
    unittest.main()
