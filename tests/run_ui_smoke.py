"""Isolated read-only UI test; requires a live Omarchy Wayland session."""
import json
import os
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
shell = Path(os.environ.get('OMARCHY_PATH', '/usr/share/omarchy')) / 'shell'
for missing in [False, True]:
    with tempfile.TemporaryDirectory(prefix='scarlett-ui-') as directory:
        folder = Path(directory)
        for module in ['Ui', 'Commons']:
            (folder / module).symlink_to(shell / module, target_is_directory=True)
        template = (root / 'tests/ui-smoke.qml.in').read_text()
        helper = str(root / 'bin/scarlett-helper')
        template = template.replace('@PLUGIN_URL@', json.dumps(root.as_uri()))
        template = template.replace('@HELPER_PATH@', json.dumps(str(folder / 'missing-helper') if missing else helper))
        template = template.replace('@REAL_HELPER_PATH@', json.dumps(helper))
        (folder / 'shell.qml').write_text(template)
        result = subprocess.run(['quickshell', '-p', str(folder), '--no-color'],
                                text=True, capture_output=True, timeout=20,
                                env={**os.environ, 'SCARLETT_TEST_MISSING': '1' if missing else '0'})
        output = result.stdout + result.stderr
        print(output)
        assert result.returncode == 0 and 'SCARLETT_UI_PASS' in output and 'SCARLETT_UI_FAIL' not in output
