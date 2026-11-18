# Contributing

Please start with a small, reproducible case and identify the affected Virtuoso release. Runtime changes should be checked against that installation's own Cadence documentation.

## A useful report

- Signal Navigator version and Virtuoso version.
- Relevant `lsnCheckEnvironment()` results.
- Whether the design has a source reference and existing instance bindings.
- Reproduction steps and expected versus actual Status/position.
- An original synthetic example, or a textual description with names and coordinates replaced by generic values.

Do not submit private chip databases, PDK files, commercial documentation or binaries, license files, credentials, personal host paths, or real-design screenshots without the necessary permission.

## Development

Version 0.3.4 remains a frozen historical artifact. The working project is 0.3.5; [RELEASE.md](RELEASE.md) pins the current normalized source checksum. Prefer separate site PAD profiles and per-design assignments for PDK differences. Runtime behavior changes require a new version and explicit validation; do not silently replace a historical artifact. Review [PAD porting](docs/PAD_PORTING.md) before assuming another PAD's terminal roles or geometry match an existing profile.

Keep the runtime standalone. Avoid adding Python, a network service or a framework to solve an in-process SKILL operation. Optional development tools may use the Python standard library, but runtime users should not need them.

Keep lsn-prefixed names, explicit target windows and the separation between physical pins and heuristic locations. Never introduce automatic saves, source updates, pin creation or global probe deletion into the navigation path.

For a change, explain the triggering case, resulting behavior and validation. Use the tests and acceptance guide in [docs/TESTING.md](docs/TESTING.md); report untested releases and license-dependent cases accurately. Include documentation updates for new configuration and status meanings.

Code contributions to this project are provided under the [MIT License](LICENSE). Cadence APIs and external PDKs retain their own terms; this repository contains only the extension and original examples.
