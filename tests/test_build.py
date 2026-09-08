"""Verify failed/repeated builds cannot damage a running installed helper."""
import hashlib
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class AtomicBuild(unittest.TestCase):
    def test_failed_build_preserves_binary_and_success_replaces_it(self):
        with tempfile.TemporaryDirectory(prefix='scarlett-build-') as directory:
            folder = Path(directory)
            shutil.copy2(ROOT / 'Makefile', folder / 'Makefile')
            shutil.copytree(ROOT / 'src', folder / 'src')
            def build():
                return subprocess.run(['make', 'all'], cwd=folder, capture_output=True, timeout=30)
            self.assertEqual(build().returncode, 0)
            binary = folder / 'bin/scarlett-helper'
            source = folder / 'src/scarlett-helper.c'
            original_source = source.read_text()
            original_hash = hashlib.sha256(binary.read_bytes()).digest()
            process = subprocess.Popen([str(binary), '--no-device'], stdin=subprocess.PIPE,
                                       stdout=subprocess.PIPE, text=True)
            try:
                process.stdout.readline()
                source.write_text(original_source + '\n#error Intentional build failure\n')
                self.assertNotEqual(build().returncode, 0)
                self.assertEqual(hashlib.sha256(binary.read_bytes()).digest(), original_hash)
                source.write_text(original_source + '\n/* Rebuild while original process is alive. */\n')
                self.assertEqual(build().returncode, 0)
                self.assertIsNone(process.poll())
                process.stdin.write('{"id":1,"op":"get"}\n')
                process.stdin.flush()
                self.assertIn('"type":"state"', process.stdout.readline())
                self.assertIn('"ok":true', process.stdout.readline())
            finally:
                process.stdin.close()
                process.wait(timeout=5)
                process.stdout.close()


if __name__ == '__main__':
    unittest.main()
