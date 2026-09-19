# Scarlett for Omarchy

**Your Focusrite controls, one click away in the Omarchy bar.**

Scarlett for Omarchy is a compact panel for switching **Air**, **48V phantom
power**, **Line / Inst**, and **direct monitoring** without opening a separate
control app. Switch from a microphone to an instrument, change your monitoring,
or check 48V while staying in the app you're working in.

It follows your Omarchy theme and the device's reported settings. Everyday
controls stay in the main popup; **Device settings** holds the less frequent
options, including **Remember 48V** and restart troubleshooting.

**Currently supported: Focusrite Scarlett Solo (3rd Gen.), USB `1235:8211`.**
Other Scarlett generations, Clarett, and Vocaster are on the roadmap and are not
yet supported. This is a hardware control panel; it does not replace your normal
system volume widget or provide an audio mixer or recorder.

**Setup:** one terminal step is required after adding the plugin to compile its
small helper. See [Install and update](#install-and-update). No separate
control-panel app or additional driver is required.

![Scarlett quick controls](docs/images/quick-controls.png)

## Built on my Solo, with room for the family

I own a **Scarlett Solo (3rd Gen.)**, USB product **`1235:8211`**, and that's the interface I'm
building and testing with. It's the model this plugin currently supports.

**Have another Focusrite Scarlett?** I'd love to support it. Currently, only the
Scarlett Solo (3rd Gen.) is enabled and tested. Other models need device mappings
and hardware testing—please [open a device-support request](https://github.com/davidkodar/omarchy-scarlett/issues/new?template=device_support.md)
to help expand compatibility.

The longer-term goal includes the wider Focusrite family: Scarlett, Clarett,
and Vocaster. I don't have all those interfaces on my desk, so help from people
who do would make a real difference. You can share which controls matter to you,
provide read-only device information, or help test a future build. You don't
need to write code to contribute.

Support will grow model by model, with a clear distinction between features
we've implemented and behavior someone has verified on real hardware. The
current Solo implementation doesn't yet select other models or multiple matching
interfaces at once.

## Help shape what comes next

The **[roadmap](docs/ROADMAP.md)** covers broader device support and future native
routing and mixer tools. It's a direction we're working toward, not a promise
that every device or feature is already supported.

Have an idea, a different interface, or something that isn't working as expected?
**[Open a feature request, device-support request, or bug report](https://github.com/davidkodar/omarchy-scarlett/issues/new/choose).**
Testing, documentation, design feedback, and code contributions are all welcome.
See [CONTRIBUTING.md](CONTRIBUTING.md) for a few simple ways to get involved.

## Requirements

- Omarchy with its Quickshell plugin system (developed against 4.0.2).
- Runtime: `alsa-lib`, `json-c`; Omarchy supplies Quickshell and its QML components.
- Build: a C compiler, `make`, and `pkgconf` (Arch's `base-devel` provides these).
- Tests: Python 3.

The plugin uses the existing Linux driver and system ALSA library. It does not
install another driver, a privileged background service, or an audio filter.

## Install and update

### First-time setup — required

Complete both steps before using the controls. Omarchy's plugin manager adds the
plugin source; the included installer builds the small hardware helper it needs.

**1. Add the plugin.** If prompted to enable it now, choose No until step 2 is
complete. If you already added it from the marketplace, go straight to step 2.

```sh
omarchy plugin add https://github.com/davidkodar/omarchy-scarlett.git
```

**2. Build the helper and enable the widget.** Open a terminal and run:

```sh
cd ~/.config/omarchy/plugins/davidkodar.scarlett
./scripts/install.sh
```

The installer checks dependencies, builds locally, validates the plugin, backs
up shell.json, and enables the widget. It never downloads binaries or installs
system packages. You do not need to repeat this setup after each restart.

If dependencies are missing, the installer stops before changing the shell.
On Omarchy, install
`base-devel`, `alsa-lib` and `json-c` using your package manager, then rerun it.

Scarlett is placed after the normal `omarchy.audio` volume widget when that
widget is in the right-hand section. Otherwise it is added to the right-hand
section. Reinstalling preserves Scarlett's existing position. A standard Audio
widget is **not** a dependency.

### Updating

After pulling an update:

```sh
cd ~/.config/omarchy/plugins/davidkodar.scarlett
./scripts/install.sh
omarchy restart shell
```

The helper is replaced atomically after a successful build, so rebuilding does
not truncate a running executable. Restarting loads the new helper and clears
cached QML. No audio settings are restored by the plugin.

For development, clone into any directory and run `./scripts/install.sh` there.
It links the checkout into the plugin directory and refuses to replace another
installation. Keep that checkout in place. `install-dev.sh` is a compatibility
alias for the same installer.

## Disable and remove

To hide Scarlett without deleting anything:

```sh
omarchy plugin disable davidkodar.scarlett
```

To undo a development link, run `./scripts/uninstall.sh` from its checkout. This
backs up shell.json, disables the plugin and removes only the link it owns. It
retains the source code. For a checkout installed directly inside the plugin
directory, the script disables the plugin and retains that directory as well.

For complete removal of a plugin-manager installation, use Omarchy's normal
`omarchy plugin remove davidkodar.scarlett` command after saving any local edits.
This removes the installed checkout. No ALSA package needs to be uninstalled.

## Behavior

- Opening the panel reads settings; it never restores a preset or enables 48V.
- A click requests an explicit value. The switch follows confirmed ALSA state.
- Unsupported or read-only controls are disabled.
- Unplugging disables controls. The helper retries discovery while disconnected.
- Each connection has a generation number; stale requests are rejected.
- Helper failures disable the UI. Reopening the popup retries the helper.
- 48V is controlled only through its labeled row, never through the bar icon.
- **Device settings** opens a separate view with Back navigation. It shows model, USB identity and firmware version, plus a
  **Remember 48V** startup preference. This is separate from the current 48V
  switch and is never applied automatically by the plugin.
- Firmware updates and factory resets remain outside the plugin.

The small helper uses `alsa-lib` plus `json-c`, with newline-delimited JSON over
stdin/stdout. ALSA events drive updates while connected; discovery retries every
1.5 seconds only when disconnected. Each bar instance owns its helper process.

## 48V after restart or reconnect — troubleshooting only

This is separate from the required first-time setup above. The plugin installer
does not change your system's ALSA restore configuration.

The plugin reads the interface's settings when it reconnects. If those settings
change unexpectedly, a saved system ALSA configuration may be overriding the
hardware. See [the Scarlett-specific restore investigation and fix](support/alsa-restore/README.md).
The same guide is available through **Device settings → 48V restart help**.
Extra setup is only needed if a system restore conflict is confirmed. That system
adjustment is separate from normal plugin installation.

## Validation

`make check` runs eight hardware-free protocol tests and seven installer/removal
tests, plus an atomic-build test against a running helper. They cover malformed requests, read-only/disconnected writes, recovery
after bad input, missing/replaced Audio widgets, preservation of placement,
dependency/build failures and protection of unrelated installations. `--once` always opens ALSA read-only.

The optional live test writes **Air's current value back unchanged** to verify
write acknowledgement and readback. It also verifies stale-generation rejection.
It does not write 48V, instrument mode, or direct monitoring:

```sh
python3 tests/live_readback.py
```

`python3 tests/run_ui_smoke.py` runs a separate read-only Quickshell instance in
a live Wayland session. It checks page navigation, keyboard focus, palette and
spacing updates, vertical-bar settings, and missing-helper recovery. It does not
change the system theme or write audio settings. Avoid interacting with other
windows during this brief focus-sensitive test.

Read-only previews of the two native views:

![Quick controls](docs/images/quick-controls.png)
![Device settings](docs/images/device-settings.png)

See [the release checklist](docs/RELEASE.md) for checks still required before
publication. Current API usage follows the installed Omarchy shell, whose shared
components may evolve between versions.

## License and attribution

Original plugin and helper code: MIT. The hardware integration is independently
implemented against ALSA; no kernel driver source is bundled. Omarchy's shared QML components
are imported from the installed system, not bundled. `alsa-lib` is dynamically
linked under its LGPL terms; `json-c` uses MIT. These system dependencies retain
their respective licenses.

Thanks to Geoffrey Bennett and the Linux audio contributors for Focusrite driver
support, and to [Omarchy](https://github.com/basecamp/omarchy) for the shell infrastructure.
This is an independent community project, unaffiliated with Focusrite.
