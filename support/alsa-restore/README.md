# Scarlett Solo (3rd Gen.) settings restored by the system

## If 48V changes after a restart or reconnect

1. In **Device settings**, enable **Remember 48V**. This remembers the power
   state; it does not turn phantom power on by itself.
2. Return to the main panel and set **48V** to the state you want remembered.
3. When an audio interruption is convenient, restart or reconnect the interface
   and compare the hardware's 48V light with the plugin.
4. If the state is correct, no extra setup is needed. If it changes unexpectedly,
   your system may be restoring an older audio configuration. Re-running the
   plugin installer does not fix that conflict.

The plugin's help message is general guidance, not an automatic diagnosis.
System changes should follow a check of the affected machine. The example below
records the fix tested on the maintainer's Solo; it is not a universal installer.
If you need help, [open a support issue](https://github.com/davidkodar/omarchy-scarlett/issues/new?template=bug_report.md)
with your device model, Omarchy version, whether this happens after a restart or
USB reconnect, and what the hardware light and plugin show. Do not include
passwords or other private information.

## Why this can happen

On the maintainer's machine, `/var/lib/alsa/asound.state` held an older Solo
configuration with phantom power off and phantom-power persistence on. The
installed ALSA udev rule restored that file on USB connection. The boot/shutdown
`alsa-restore.service` also restored/stored mixer state for all cards.

That explains why a hardware startup preference can appear ineffective: system
restore can overwrite the device's remembered state. The plugin should continue
to display the actual state rather than silently turn phantom power back on.

## Scoped local fix

The local adjustment excludes only Focusrite USB product `1235:8211`:

- `/etc/udev/rules.d/90-alsa-restore.rules` shadows the distribution's same-named
  rule file. It retains the packaged rules and prepends an exact USB-match jump
  to the file's end label for this Solo.
- `/etc/systemd/system/alsa-restore.service.d/10-scarlett-exception.conf` replaces
  the service's global restore/store commands with a root-owned wrapper that
  enumerates connected cards, skips this USB product, and handles all others.
- `/usr/local/libexec/alsa-state-except-scarlett` is the installed copy of the
  original helper in this directory. `restore --dry-run` or `store --dry-run`
  prints its selection without changing sound-card settings.

The existing ALSA state file is retained. No phantom-power value is forced, and
no service is restarted to apply mixer state. Reloading the udev rules and systemd
unit definitions makes the exception apply at future connections and boots.

This fix targets the standard `alsa-restore.service` mode on this machine;
`alsa-state.service` is inactive. It must be reviewed if ALSA daemon mode is
enabled later. Other distribution-specific restore mechanisms may also need
investigation.

## Installation and maintenance

This is **not** part of the normal plugin installer. It changes root-owned system
configuration and requires a separately reviewed, administrator-authorized
installation. Do not copy a rule file from another distribution or version.
Generate the local override from that machine's installed rule and validate it
with `udevadm verify` before installing.

Because the local rule shadows the packaged file, compare it against
`/usr/lib/udev/rules.d/90-alsa-restore.rules` after alsa-utils updates and refresh
the override if upstream rules change. Keep the exact Solo exception while
preserving the updated rules for other cards.

Before installation, back up any existing overrides and record which files did
not exist. To undo the adjustment, restore the prior files (or remove only the
three files introduced by this fix if they were absent), then run
`udevadm control --reload-rules` and `systemctl daemon-reload`. Do not restart the
restore service unless you intend to apply the saved mixer state immediately.

A reconnect test is needed to confirm the result on physical hardware. First
choose the intended 48V state and startup preference, then reconnect when audio
interruption is convenient. Check the physical indicator and plugin agree.
