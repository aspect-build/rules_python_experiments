import unittest
import platform

class TestPythonVersion(unittest.TestCase):
    def test_match_toolchain(self):
        self.assertEqual(platform.python_version(), "3.9.7")

if __name__ == '__main__':
    unittest.main()
