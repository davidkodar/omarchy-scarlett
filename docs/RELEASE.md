# Solo preview release readiness

Repository stays private until the owner explicitly approves publication.
The first release is scoped to Scarlett Solo USB `1235:8211`, not all Focusrite
interfaces. See ROADMAP.md for planned expansion.

## Completed release preparation

- [x] Eight protocol tests and seven installer/removal tests pass.
- [x] Fresh source-only build and Omarchy manifest validation pass.
- [x] Installer checks dependencies, compiles locally and validates before configuration changes.
- [x] Placement works with no standard Audio widget and preserves an existing position.
- [x] Build failure leaves the installed executable intact; successful builds replace it atomically.
- [x] Installation/removal refuse unrelated checkouts and preserve source on script uninstall.
- [x] Device settings is a separate view with Back navigation.
- [x] Isolated read-only QML checks pass for navigation/focus, a light palette,
      increased spacing, vertical-bar configuration and missing-helper recovery.
- [x] Preview images contain only the plugin UI.
- [x] Marketplace publishing requirements checked; see PUBLISHING.md.
- [x] README distinguishes implemented scope from the multi-device roadmap.

## Hardware checks still requiring participation

The user reported successful switching reflected in ALSA Scarlett Control Panel.
The automated live write check verified Air's unchanged value and stale-request
rejection. These do not substitute for the remaining checks below.

- [ ] Record each control's real on/off changes and restoration to the intended state.
- [ ] Physical button changes appear promptly in the plugin.
- [ ] Unplug/replug while the panel is open disables and restores the controls.
- [ ] Confirm the 48V startup preference across a deliberate power cycle.
- [ ] Verify behavior with multiple supported interfaces and access denied.
- [ ] Complete real multi-monitor and system-theme-switch checks beyond the isolated UI test.

Follow HARDWARE_TESTING.md when audio interruption is convenient. Do not describe
unchecked items as passed. These are qualification tasks, not known reproduced
failures. Until they are resolved, this remains a development preview.

## Publication steps

- [ ] Owner approves making the repository public.
- [ ] Review the final source/history, release notes and submission text.
- [ ] Submit the public repository for listing with manual setup disclosed.

Do not publish or file the marketplace submission as a side effect of tests.
