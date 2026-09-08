# Native Focusrite controls roadmap

Direction: grow from Solo quick controls into an Omarchy-native control surface
for the Focusrite families supported by Linux, reducing the need for a separate
application as coverage is verified. The maintainer owns a Scarlett Solo (3rd Gen.) (`1235:8211`);
help testing other interfaces is warmly welcome.

## Current scope and priorities

The current implementation targets Scarlett Solo (3rd Gen.) USB `1235:8211`. It provides
Air, 48V, Line/Inst and direct-monitor controls, plus the 48V startup preference
and device information. See [validation notes](VALIDATION.md) for the precise
test coverage; implemented does not mean fully hardware-validated.

| Priority | Milestone | Status |
| --- | --- | --- |
| Complete | Separate Device settings view with Back navigation; keep the main popup compact | Implemented and UI-tested |
| Next | Reusable device profiles, capability schema and read-only capture tool | Planned |
| Next | One additional small Scarlett model, with recorded data and hardware validation | Planned; model chosen with contributor input |
| Later | Broader small Scarlett 3rd/4th generation quick controls | Planned |
| Later | Larger native window for Scarlett/Clarett routing, mixing, meters and clock settings | Planned |
| Later | Model-specific features, including Vocaster DSP | Planned |
| Exploration | Presets, reset operations, firmware updates and recovery | Scope and feasibility not yet established |

The next engineering milestone is the reusable backend plus one additional
model. Hardware access and contributor requests will help determine sequencing.
There are no committed release dates. This roadmap describes direction, not
current compatibility or a promise of universal feature parity.

## Request features or help test

Use [GitHub Issues](https://github.com/davidkodar/omarchy-scarlett/issues/new/choose)
for feature requests, device-support requests and bugs. Read
[CONTRIBUTING.md](../CONTRIBUTING.md) for useful details to include, read-only
device information collection and pull-request guidance. Hardware testing and
documentation contributions are particularly valuable.

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

Only advertise features verified for a particular device. Broader family support
is the goal; the current implementation supports the Solo model listed above.
