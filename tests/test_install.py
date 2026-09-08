"""Run install/removal scripts against temporary configs and recorded CLI calls."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class Installation(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='scarlett-install-')
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.project = self.base / 'project with spaces'
        shutil.copytree(ROOT / 'scripts', self.project / 'scripts')
        self.config = self.base / 'config'
        self.shell = self.config / 'omarchy/shell.json'
        self.shell.parent.mkdir(parents=True)
        self.target = self.config / 'omarchy/plugins/davidkodar.scarlett'
        self.log = self.base / 'calls'
        mocks = self.base / 'commands'
        mocks.mkdir()
        commands = {
            'make': 'echo "build" >> "$TEST_CALLS"; exit "${BUILD_FAIL:-0}"',
            'cc': 'exit 0',
            'pkg-config': 'exit "${DEPS_FAIL:-0}"',
            'omarchy': 'echo "$*" >> "$TEST_CALLS"',
            'omarchy-shell': '''case "$*" in
              'shell ping') echo ok ;;
              'shell listPlugins') echo '[{"id":"davidkodar.scarlett"}]' ;;
              *) echo "$*" >> "$TEST_CALLS" ;;
            esac'''
        }
        for name, body in commands.items():
            p = mocks / name
            p.write_text('#!/bin/bash\n' + body + '\n')
            p.chmod(0o755)
        self.env = {**os.environ, 'PATH': str(mocks) + ':' + os.environ['PATH'],
                    'XDG_CONFIG_HOME': str(self.config), 'TEST_CALLS': str(self.log)}

    def layout(self, right=None, left=None):
        self.shell.write_text(json.dumps({'version': 1, 'bar': {'layout': {
            'right': right or [], 'left': left or [], 'center': []}}}))

    def run_script(self, name='install.sh'):
        return subprocess.run([str(self.project / 'scripts' / name)],
                              env=self.env, capture_output=True, text=True, timeout=10)

    def calls(self):
        return self.log.read_text() if self.log.exists() else ''

    def test_audio_neighbor_and_backup(self):
        self.layout(right=[{'id': 'omarchy.audio'}])
        original = self.shell.read_bytes()
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('--section right --after omarchy.audio', self.calls())
        self.assertEqual(self.target.resolve(), self.project)
        self.assertEqual(next(self.shell.parent.glob('shell.json.scarlett-backup.*')).read_bytes(), original)

    def test_absent_replaced_or_left_audio(self):
        for right, left in [([], []), ([{'id': 'custom.audio'}], []), ([], [{'id': 'omarchy.audio'}])]:
            with self.subTest(right=right, left=left):
                self.layout(right=right, left=left)
                self.log.write_text('')
                result = self.run_script()
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn('plugin enable davidkodar.scarlett --section right\n', self.calls())
                self.assertNotIn('--after', self.calls())

    def test_reinstall_preserves_position(self):
        self.layout(left=[{'id': 'davidkodar.scarlett'}])
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('plugin enable davidkodar.scarlett\n', self.calls())

    def test_build_and_dependency_failure_make_no_config_changes(self):
        self.layout()
        original = self.shell.read_bytes()
        for failure in ['BUILD_FAIL', 'DEPS_FAIL']:
            self.env[failure] = '1'
            self.assertNotEqual(self.run_script().returncode, 0)
            self.assertFalse(self.target.exists())
            self.assertEqual(self.shell.read_bytes(), original)
            self.assertFalse(list(self.shell.parent.glob('*.scarlett-backup.*')))
            del self.env[failure]

    def test_refuses_unrelated_installation(self):
        self.layout()
        self.target.mkdir(parents=True)
        sentinel = self.target / 'keep'
        sentinel.write_text('untouched')
        self.assertNotEqual(self.run_script().returncode, 0)
        self.assertNotEqual(self.run_script('uninstall.sh').returncode, 0)
        self.assertEqual(sentinel.read_text(), 'untouched')

    def test_uninstall_only_removes_owned_link(self):
        self.layout()
        self.assertEqual(self.run_script().returncode, 0)
        result = self.run_script('uninstall.sh')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.target.exists())
        self.assertTrue(self.project.is_dir())
        self.assertIn('plugin disable davidkodar.scarlett', self.calls())

    def test_in_place_checkout(self):
        self.layout()
        self.target.parent.mkdir(parents=True)
        shutil.move(str(self.project), self.target)
        self.project = self.target
        self.assertEqual(self.run_script().returncode, 0)
        self.assertEqual(self.run_script('uninstall.sh').returncode, 0)
        self.assertTrue(self.target.is_dir())


if __name__ == '__main__':
    unittest.main()
