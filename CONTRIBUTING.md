# Contributing

Feature requests, bug reports, device information, documentation improvements,
and pull requests are welcome. You do not need to write code to help.

The maintainer tests on a Scarlett Solo (3rd Gen.) (`1235:8211`). Reports and hardware
testing from owners of other Focusrite interfaces will help us expand support
with confidence. Thanks for helping make the plugin useful to more people.

## Requests and bugs

Check the [roadmap](docs/ROADMAP.md) and
[existing issues](https://github.com/davidkodar/omarchy-scarlett/issues) first.
Use [New issue](https://github.com/davidkodar/omarchy-scarlett/issues/new/choose)
to choose Feature request, Device support request, or Bug report. Add information
to an existing request when possible rather than opening a duplicate.

Describe the task you want to accomplish, not only the button you want added.
For device requests, provide the exact model and generation. Requests inform
priorities; they are not a commitment to implement a feature or meet a date.
Maintainers consider everyday usefulness, implementation complexity, and access
to hardware testing.

## Sharing device information

For the currently supported Solo, `./bin/scarlett-helper --once` reads state and
firmware information without writing settings. Unsupported models will not be
selected by the current helper.

For other models, these ALSA commands can help describe available controls:

```sh
cat /proc/asound/cards
amixer -c CARD_ID contents
```

Replace `CARD_ID` with the identifier from `/proc/asound/cards` for your interface.
`contents` reads controls; do not run `cset`, restore presets, or change firmware
just to file an issue. You may need Arch's `alsa-utils` package for `amixer`.
Review any output before posting, especially serial numbers and custom names.

A dedicated capture tool is planned. Recorded data helps with parsing and UI
layout, but validation on the actual device is required for write behavior.
When reporting tests, identify the commit, device, individual control, expected
result and observed result. List untested features explicitly.

## Code contributions

Discuss substantial changes in an issue before investing in a large pull request.
Keep quick controls compact and place less frequent options in Device settings;
complex routing and mixing belong in a larger native view.

- Keep ALSA transport, device mapping and UI concerns separate.
- Never apply saved settings on startup or infer write support from a name alone.
- Preserve control type/access checks, device identity and write readback.
- Add meaningful tests when changing behavior. Run `make check` for backend
  changes; inspect UI changes in Omarchy and report the version used.
- Explain what changed, how it was verified, and which hardware remains untested.
- Do not include compiled helpers, credentials, personal configuration or full
  desktop screenshots in commits.

Original contributions use the project's MIT license. Identify third-party
material and its license before adding it; upstream code and recorded demo
configurations must not be assumed to be MIT-compatible.
