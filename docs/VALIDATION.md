# Validation record — 2026-09-08

Environment: Omarchy 4.0.2, Quickshell 0.3.1, ALSA 1.2.16.1;
Scarlett Solo (3rd Gen.) USB product 1235:8211.

## Current status

The current build passes all 16 hardware-free tests. The read-only UI checks
pass, and the full Scarlett Solo (3rd Gen.) name is shown in the interface and
documentation. The owner confirmed direct monitoring, 48V, Line / Inst, reconnect
detection, and persistence-on with the local ALSA restore exception. The owner
also confirmed completion of Air on/off, physical-button synchronization, and
reconnect testing with Remember 48V disabled.
See [RELEASE.md](RELEASE.md) for checks still outstanding.

The entries below record development in order; later results supersede earlier
limitations and describe changes to the interface.

## Initial checks

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

No 48V write was performed during these initial checks. Later owner-confirmed
hardware tests are recorded below.

## Interface refinement

- User reported switching controls successfully and observing matching changes
  in ALSA Scarlett Control Panel. Individual controls were not specified.
- Added an original vector interface icon, device/status tooltip, input groups,
  and explicit Line / Inst buttons using Omarchy's themed components.
- Fresh read-only preview loaded without plugin QML errors and was visually
  inspected. The live shell retained cached QML after a rescan, requiring a
  shell restart for the new layout.

## Earlier advanced-settings launcher (since removed)

An earlier version opened an external control panel. The owner confirmed that
action worked. This launcher was subsequently removed in favor of native Device
settings; the current plugin uses ALSA directly and requires no separate app.

## Device settings

- Seven hardware-free protocol tests pass, including persistence requests in
  disconnected/read-only modes and firmware write rejection.
- Live read-only metadata: firmware 1605, USB 1235:8211; phantom-power
  persistence is enabled. No persistence or 48V write was performed.
- Expanded read-only QML preview loaded successfully after using the Qt
  version's supported accessibility properties.

## Standalone UI

Removed the external control-panel launcher, installation check and launch timer.
The native controls have no dependency on that application. This does not imply
feature parity: firmware maintenance, configuration files, simulation and other
interface models remain outside the current plugin.

## Release hardening

- Eight protocol and seven installer/removal tests passed, including rejection
  of embedded-NUL command/control aliases, missing/replaced Audio widgets,
  existing-position preservation, build/dependency failures, in-place installs
  and refusal to touch unrelated checkouts.
- A clean source-only copy built successfully and passed the same tests and
  Omarchy's manifest validation.
- Isolated read-only QML smoke tests passed for separate settings navigation,
  Back focus, reopen behavior, palette/spacing updates, vertical-bar configuration,
  missing-helper feedback and recovery. Screenshot exports were visually checked.
- The new installer ran against the actual development installation and preserved
  its position. The shell was restarted to apply the updated QML and helper.
- Physical-button, power-cycle and reconnect qualification are still pending;
  no hardware setting was changed as part of this hardening pass.

- Atomic rebuild test passed: an intentional compiler failure preserved the
  existing binary; a subsequent successful rebuild left the original process
  responsive while replacing its executable on disk.

## User-confirmed Solo control tests

The owner explicitly confirmed testing direct monitoring, phantom power (48V),
and Line / Inst on the connected Solo. These three controls are now recorded as
user-confirmed working. The report did not specify physical-button initiation,
unplug/replug, power-cycle behavior, or restoration of initial settings; those
checks remain separate. Air's real on/off behavior and Remember 48V persistence
across power cycles are not established by this report.

## Reconnect report and local ALSA restore exception

The owner confirmed the widget showed the device as unavailable after USB
disconnection and detected it again after reconnecting. They also reported 48V
was on before unplugging but off afterward. A read-only snapshot showed 48V off
and persistence on. The system's saved ALSA state contained the same combination;
the installed hotplug rule and boot service both restored saved mixer state.

A separately authorized local system exception now skips only USB 1235:8211 in
the hotplug restore rule and boot/shutdown restore/store service. Other cards
remain selected. Root ownership/modes, rule syntax, effective service commands,
and dry-run selection were verified. Existing configuration was backed up under
/var/backups/omarchy-scarlett-restore-20260908-234011. No mixer state was written.
Post-fix read-only values matched the pre-fix snapshot. The subsequent physical reconnect test
is recorded below.

## Owner confirmation after restore fix

The owner confirmed the requested post-fix test worked: with 48V on and Remember
48V enabled, disconnecting and reconnecting USB restored the expected on state
on the physical interface and in the plugin. This validates persistence-on
behavior on the maintainer's Solo with the local restore exception installed.
Persistence-off behavior and other devices remain untested by this report.

## Owner confirmation of remaining Solo hardware checks

When presented with the three remaining checks, the owner clarified that they
were already complete: Air on/off, physical-button synchronization, and reconnect
behavior with Remember 48V disabled. These are recorded as owner-confirmed
hardware results. They do not establish coverage for additional interfaces or
untested desktop configurations.
