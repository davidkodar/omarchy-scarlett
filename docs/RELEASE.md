# Release checklist

Repository stays private until the owner explicitly approves public release.

## Implemented

- Native Omarchy bar widget and themed panel.
- ALSA event subscription and reconnect discovery.
- Four allowlisted controls, type/access validation and write readback.
- Stale device generation rejection and bounded JSON input.
- Read-only diagnostic mode; hardware-free protocol tests.
- Development installation with shell configuration backup.

## Required before public release

- Test real value changes for Air, Inst, direct monitor and 48V deliberately.
- Test physical buttons and concurrent changes in ALSA Scarlett Control Panel.
- Test USB unplug/replug while idle, with the popup open, and during a request.
- Check multiple devices and access-denied behavior.
- Check theme switching, light/dark themes, large fonts, vertical bars and multiple monitors.
- Check keyboard-only navigation and screen-reader labels.
- Check helper failure, missing binary, update/rebuild and disable/uninstall.
- Decide distribution of the compiled helper (package/build instructions).
- Add screenshots containing only the plugin, no private desktop content.
- Verify Omarchy plugin directory submission requirements.
- Review code, dependency notices, repository history, and private metadata.
- Obtain explicit owner approval before changing visibility or submitting a listing.
