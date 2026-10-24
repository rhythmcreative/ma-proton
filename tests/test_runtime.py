import unittest
from ma_proton.runtime import RuntimeManager

class TestRuntime(unittest.TestCase):
    def test_find_runtimes(self):
        runtimes = RuntimeManager.find_all_runtimes()
        self.assertGreater(len(runtimes), 0, "Al menos un runtime de Wine debe ser detectado")

    def test_best_runtime(self):
        best = RuntimeManager.get_best_runtime()
        self.assertIsNotNone(best)
        self.assertTrue(best.wine_bin.exists())
        self.assertTrue(best.wineserver_bin.exists())

if __name__ == "__main__":
    unittest.main()
