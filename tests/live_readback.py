"""Explicit live integration test: write only the existing Air value unchanged."""
import json
import selectors
import subprocess
from pathlib import Path

helper = Path(__file__).resolve().parents[1] / 'bin/scarlett-helper'
p = subprocess.Popen([str(helper)], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
selector = selectors.DefaultSelector()
selector.register(p.stdout, selectors.EVENT_READ)
buffer = b''


def message():
    global buffer
    while b'\n' not in buffer:
        if not selector.select(5):
            raise TimeoutError('No helper response')
        chunk = p.stdout.read1(4096)
        if not chunk:
            raise RuntimeError('Helper exited')
        buffer += chunk
    line, buffer = buffer.split(b'\n', 1)
    return json.loads(line)


def send(data):
    p.stdin.write((json.dumps(data) + '\n').encode())
    p.stdin.flush()
    states = []
    for _ in range(100):
        row = message()
        if row['type'] == 'state':
            states.append(row)
        elif row.get('id') == data['id']:
            return row, states
    raise RuntimeError('Too many unrelated events')


try:
    state = message()
    assert state['connected'], state
    result, _ = send(dict(id=1, op='set', key='air', value=not state['controls']['air']['value'], generation=0))
    assert not result['ok'] and 'changed' in result['error'], result
    result, states = send(dict(id=2, op='set', key='air', value=state['controls']['air']['value'], generation=state['generation']))
    assert result['ok'], result
    assert states[-1]['controls']['air']['value'] == state['controls']['air']['value']
    print('PASS: stale request rejected; unchanged Air write acknowledged and read back.')
finally:
    p.stdin.close()
    try:
        p.wait(timeout=5)
    except subprocess.TimeoutExpired:
        p.kill()
        p.wait()
    selector.close()
