"""Exercise the real helper process without access to hardware."""
import json
import subprocess
import unittest
from pathlib import Path

HELPER = Path(__file__).resolve().parents[1] / "bin/scarlett-helper"


def run(data, *args):
    p = subprocess.run([str(HELPER), "--no-device", *args], input=data,
                       capture_output=True, timeout=5)
    assert p.returncode == 0, p.stderr
    return [json.loads(line) for line in p.stdout.splitlines()]


class Protocol(unittest.TestCase):
    def test_disconnected_snapshot_and_get(self):
        rows = run(b'{"id":1,"op":"get"}\n')
        self.assertFalse(rows[0]["connected"])
        self.assertEqual(rows[0]["controls"], {})
        self.assertEqual(rows[-1], {"type": "result", "id": 1, "ok": True})

    def test_invalid_messages_do_not_crash_or_write(self):
        cases = [b"", b"null", b"[]", b"false", b"{", b'{} trailing',
                 b'{"id":1,"op":"set","key":"phantom","value":1,"generation":0}',
                 b'{"id":1,"op":"restore"}', b'x'*5000, b'{}\x00']
        for case in cases:
            with self.subTest(case=case[:80]):
                rows = run(case + b'\n{"id":2,"op":"get"}\n')
                self.assertFalse(rows[1]["ok"])
                self.assertTrue(rows[-1]["ok"])

    def test_no_device_rejects_valid_set(self):
        rows = run(b'{"id":1,"op":"set","key":"phantom","value":true,"generation":0}\n')
        self.assertFalse(rows[-1]["ok"])
        self.assertIn("disconnected", rows[-1]["error"])

    def test_readonly_rejects_set(self):
        rows = run(b'{"id":1,"op":"set","key":"air","value":true,"generation":0}\n', '--read-only')
        self.assertEqual(rows[-1]["error"], "Read-only mode")

    def test_unknown_control(self):
        rows = run(b'{"id":1,"op":"set","key":"firmware","value":true,"generation":0}\n')
        self.assertEqual(rows[-1]["error"], "Unknown control")

    def test_once_is_readonly_snapshot(self):
        self.assertEqual(len(run(b'', '--once')), 1)


if __name__ == '__main__':
    unittest.main()
