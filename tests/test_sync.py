import unittest
from ma_proton.sync import SynchronizationManager

class TestSync(unittest.TestCase):
    def test_msync_mode(self):
        mgr = SynchronizationManager(mode="msync")
        env = mgr.get_env_variables()
        self.assertEqual(env["WINEMSYNC"], "1")
        self.assertEqual(env["WINEESYNC"], "0")

    def test_esync_mode(self):
        mgr = SynchronizationManager(mode="esync")
        env = mgr.get_env_variables()
        self.assertEqual(env["WINEMSYNC"], "0")
        self.assertEqual(env["WINEESYNC"], "1")

if __name__ == "__main__":
    unittest.main()
