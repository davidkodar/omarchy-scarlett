# Development validation — 2026-09-08

Environment: Omarchy 4.0.2, Quickshell 0.3.1, ALSA 1.2.16.1;
Scarlett Solo USB product 1235:8211.

Passed:

- C build with `-Wall -Wextra -Wpedantic -Werror`.
- Six hardware-free process/protocol tests (`make check`).
- Live read-only snapshot of all four controls, matching `amixer`.
- Live stale-generation rejection and write/readback of Air's unchanged value.
- Isolated read-only QML preview loaded and visually inspected.
- Development installer backed up shell.json, linked the checkout, and enabled
  the widget next to Audio.
- Installed popup opened through IPC and visually inspected; live values matched
  the existing control panel. No plugin QML errors in the shell log.

No 48V write was performed during these checks. Full state-change, hardware
button, reconnect and theme-switch tests remain in RELEASE.md. The widget is a
usable development preview, not yet a validated public release.

## Interface refinement

- User reported switching controls successfully and observing matching changes
  in ALSA Scarlett Control Panel. Individual controls were not specified.
- Added an original vector interface icon, device/status tooltip, input groups,
  and explicit Line / Inst buttons using Omarchy's themed components.
- Fresh read-only preview loaded without plugin QML errors and was visually
  inspected. The live shell retained cached QML after a rescan, requiring a
  shell restart for the new layout.

## Advanced settings

The button now closes the popup before using Omarchy's launch-or-focus action
for ALSA Scarlett Control Panel. The user confirmed the action works. This
application remains optional; the native controls use ALSA directly.
