# Native Focusrite controls roadmap

Direction: grow from Solo quick controls into an Omarchy-native control surface
for the Focusrite families supported by Linux, reducing the need for a separate
control panel as coverage is verified. The repository remains private.

## Architecture

- Keep the bar popup for everyday controls; use a larger native window for
  routing, mixing and device configuration.
- Separate generic ALSA transport, validated device profiles and presentation.
- Discover controls, types, ranges, channel counts and access rights. Map these
  into semantic capabilities per verified model instead of guessing from names.
- Preserve explicit device selection, connection identity and event-driven state.
- Track discovery support separately from tested feature parity.

## Incremental delivery

1. Extract the existing Solo mapping into a device profile; add a capability
   schema and a read-only capture tool for contributors.
2. Add fixture-backed profiles for small Scarlett 3rd/4th generation models,
   then validate writes and physical-button synchronization on each device.
3. Add a native full panel for larger Scarlett and Clarett interfaces: routing,
   mixers, meters, clocking and available input/output controls.
4. Add Vocaster-specific capabilities and DSP, with appropriate native editors.
5. Assess presets, startup/reset operations and firmware handling independently;
   parity is not complete merely because a device is detected.

## Validation and licensing

Record a per-model/per-feature matrix: implemented, fixture-tested,
hardware-tested, unsupported. Fixtures can validate parsing and layout, but
cannot establish hardware write behavior. Obtain hardware-owner validation
before advertising supported control operations.

Use independently implemented ALSA integration and documented control metadata.
Before importing upstream demo configurations or code, review their specific
license and retain attribution; do not assume they can enter the MIT project
without conditions. Firmware packages and update protocols need separate review.

The full ALSA Scarlett Control Panel remains an optional fallback until feature
coverage for a particular device is established. No claim of universal support
is made by the current Solo release.
