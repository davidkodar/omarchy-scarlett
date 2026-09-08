# Scarlett for Omarchy

Native bar controls for **Air**, **48V**, **Line / Inst**, and **direct monitoring**.
A distinct audio-interface icon opens a panel grouped by Input 1, Input 2,
and Monitoring, with explicit Line / Inst buttons. Hover shows 48V and direct
monitor status. The panel uses Omarchy's shared components and theme palette. Hardware state
comes directly from ALSA, including updates from the interface's buttons or
ALSA Scarlett Control Panel.

**Private development preview — not a public release.** Initially supports the
Scarlett Solo USB product `1235:8211`. Other models are intentionally not selected.
Multiple matching devices at startup are refused rather than chosen arbitrarily.

## Requirements

- Omarchy with its Quickshell plugin system (developed against 4.0.2).
- Runtime: `alsa-lib`, `json-c`; Omarchy supplies Quickshell and its QML components.
- Build: a C compiler, `make`, and `pkgconf` (Arch's `base-devel` provides these).
- Tests: Python 3.
- Optional: `alsa-scarlett-gui` from Arch Extra for **Advanced settings**.
  This button opens the app or focuses its existing window. If the app is
  absent, the button is hidden; all four native controls still work.

No new kernel driver, root service, PipeWire filter, or GUI fork is involved.

## Build and install

While this repository is private, GitHub authentication with repository access
is required to clone it.

```sh
git clone https://github.com/davidkodar/omarchy-scarlett.git
cd omarchy-scarlett
make
make check
./bin/scarlett-helper --once
./scripts/install-dev.sh
```

The development installer links this checkout into the user plugin directory,
backs up `shell.json`, and enables the widget beside Audio. Keep the checkout
at the same location. It refuses to replace an unrelated existing installation.
It does not install system packages or use sudo.

The helper must be compiled **before** enabling the plugin. Omarchy's normal
plugin installer only clones files; it does not run builds. After updating the
source, run `make` and `omarchy-shell shell rescanPlugins`. If the shell still
shows the previous layout, use `omarchy restart shell` to clear cached QML. Public distribution
packaging remains a release task.

To disable without deleting the source:

```sh
omarchy plugin disable davidkodar.scarlett
```

To unlink the development installation after disabling, remove only the
`~/.config/omarchy/plugins/davidkodar.scarlett` symlink. Do not remove your checkout.

## Behavior

- Opening the panel reads settings; it never restores a preset or enables 48V.
- A click requests an explicit value. The switch follows confirmed ALSA state.
- Unsupported or read-only controls are disabled.
- Unplugging disables controls. The helper retries discovery while disconnected.
- Each connection has a generation number; stale requests are rejected.
- Helper failures disable the UI. Reopening the popup retries the helper.
- 48V is controlled only through its labeled row, never through the bar icon.
- No firmware updates or phantom-power persistence controls are exposed.

The small helper uses `alsa-lib` plus `json-c`, with newline-delimited JSON over
stdin/stdout. ALSA events drive updates while connected; discovery retries every
1.5 seconds only when disconnected. Each bar instance owns its helper process.

## Validation

`make check` exercises the real process with hardware access disabled: malformed
requests, oversized lines, read-only writes, disconnected writes, and recovery
after bad input. `--once` always opens ALSA read-only.

The optional live test writes **Air's current value back unchanged** to verify
write acknowledgement and readback. It also verifies stale-generation rejection.
It does not write 48V, instrument mode, or direct monitoring:

```sh
python3 tests/live_readback.py
```

See [the release checklist](docs/RELEASE.md) for checks still required before
publication. Current API usage follows the installed Omarchy shell, whose shared
components may evolve between versions.

## License and attribution

Original plugin and helper code: MIT. No source from `alsa-scarlett-gui` or the
kernel driver is copied into this repository. Omarchy's shared QML components
are imported from the installed system, not bundled. `alsa-lib` is dynamically
linked under its LGPL terms; `json-c` uses MIT. These system dependencies retain
their respective licenses.

Thanks to Geoffrey Bennett and contributors for Linux Focusrite driver support
and [ALSA Scarlett Control Panel](https://github.com/geoffreybennett/alsa-scarlett-gui),
and to [Omarchy](https://github.com/basecamp/omarchy) for the shell infrastructure.
This is an independent community project, unaffiliated with Focusrite.
