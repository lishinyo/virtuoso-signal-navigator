# Virtuoso Signal Navigator

[中文说明](README.zh-CN.md) · Version 0.3.5 · [MIT](LICENSE)

**0.3.5: progress statistics and separate open filters.** Global scalar Pin/Net totals, current completion rates, Open, Unverified and Pending counts update from existing cached results. Bus aggregates are counted separately. Show now contains only All, Pin, Nets, Pin Open, Net Open and Unverified. The frozen 0.3.4 archive and installation are preserved. See [Release](RELEASE.md).

Different PDKs and PAD cells are configured through exact library/cell profiles and separate per-design instance/terminal assignments, without editing the core. Start with the guarded [site template](examples/site_config.template.il), [design template](examples/design_targets.template.il), and [PAD porting guide](docs/PAD_PORTING.md). Built-in profiles are site-specific references, not generic definitions of PAD behavior. Unsupported geometry remains unverified. Keep local configurations outside the public tree.

Top-level schematic Pin completion now requires actual PAD access as well as internal connectivity. PAD discovery, explicit/source-bound terminal assignment, physical metal/via checks, required multi-target handling, parent assembly scope, navigation and portable mapping configuration are included. No PAD is placed and no design geometry is written. See [PAD connection guide](docs/PAD_CONNECTION.md).

Show has one **Pin** category: top-level schematic I/O intended for later PAD connection, including bus members/aggregates, regardless of placement, cached checks or connectivity. Ports, Pin not placed and Physical pin are no longer separate Show choices. Nets contains other internal nets. Placement and location details remain visible in the tables.

Check selected updates only the selected net. Pin Open includes schematic I/O awaiting PAD connection; Net Open covers other internal nets. Real revision changes retain the last result with a needs-recheck marker, but stale results do not increase completion statistics. Open/Unverified counts may overlap. Filters combine with name search and never start a physical trace.

Navigation-only continuation: schematic bus-bit membership, hierarchical label landings, schematic I/O direction, and physical connectivity status are included in the single runtime file. Unplaced schematic I/O remains distinct from unresolved physical geometry. Route prediction is not loaded. The original 0.3.0 archive remains unchanged.

A single-file SKILL extension for finding connections in large Cadence Virtuoso layouts. Browse nets and ports by name, visit existing locations one click at a time, or display a sparse logical connection overview.

It distinguishes **physical pins**, **label anchors with or without nearby metal**, and **block-only hints**. When existing connectivity or source bindings identify the owning layout instance, imported geometry can remain navigable even when its formal terminal objects are absent.

## Quick start

Copy [src/signal_navigator.il](src/signal_navigator.il) to the Linux machine running Virtuoso. In its CIW, replace the example path with your actual file path:

```lisp
load("/path/to/signal_navigator.il")
lsnStart()
```

Activate the intended layout before running `lsnStart()`. To select a window explicitly, use `lsnStart(window(n))`, replacing `n` with its window number. The script refuses to choose arbitrarily when multiple layouts are available and none is current.

Select a signal, then use **Next pin >**, **< Previous**, or **Overview**. **Dock / Float** changes the panel position. `lsnClose()` closes its UI and removes its overlays.

## Runtime and scope

- Tested with **Virtuoso IC25.1 on Linux**. Other releases require capability and acceptance checks; see [Compatibility](docs/COMPATIBILITY.md).
- No Python, Virtuoso Bridge, WSL, network service, external `.drf`, or bundled PDK is needed to run the script. You still need your installed Virtuoso, its applicable licenses, and your own design environment.
- Source discovery and source-to-layout mapping use existing Virtuoso connectivity APIs when available. Layout-only browsing remains possible. A manually selected schematic does not create missing bindings.
- The core reads design data and changes view/overlay state. It never creates or saves design objects. Custom palette initialization briefly writes and removes one file in a writable temporary directory.
- Scope is the current edit level and its direct instance pins/labels. There is no full-chip recursive endpoint search, mosaic expansion, routing, pin repair, or LVS verification.

**Connection lines express logical membership, not completed metal routing.** Orange hints retain their uncertainty in the UI.

## Documentation

The detailed guides are currently in Chinese; the source and UI use English.

| Guide | Contents |
|---|---|
| [Installation](docs/INSTALL.md) | One-file installation, optional startup loading, upgrades and removal |
| [User guide](docs/USER_GUIDE.md) | Buttons, signal types, pin/label/block states and worked examples |
| [Porting](docs/PORTING.md) | Units, layer names, source references, mapping, configuration reference |
| [PAD porting](docs/PAD_PORTING.md) | Different PAD core roles, access strategies, per-site/per-design templates and acceptance |
| [PAD connection](docs/PAD_CONNECTION.md) | PAD setup UI, physical completion and parent assembly scope |
| [Maintenance handoff](docs/MAINTAINER_HANDOFF.md) | Requirements, implemented behavior, frozen baseline and recovery |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | Missing pins, hidden geometry, wrong source, colors and performance |
| [Compatibility](docs/COMPATIBILITY.md) | Verified environment and required/optional capabilities |
| [Architecture](docs/ARCHITECTURE.md) | Data flow, transformations, caches and extension points |
| [Testing](docs/TESTING.md) | Configuration checks, synthetic fixtures and release validation |
| [Contributing](CONTRIBUTING.md) | How to submit a reproducible change without private design data |

## Configuration

Configure after loading the source and before starting the panel:

```lisp
lsnConfigure('localViewWidth 40.0)
lsnConfigure('unitLabel "um") ; descriptive only; does not convert coordinates
lsnConfigure('labelLayerMap list(list("M2TXT" "M2")))
lsnStart()
```

See [examples/config.il](examples/config.il) and the complete [configuration reference](docs/PORTING.md). All dimensions are in the design's user-coordinate units, except panel sizes and line widths, which are display settings.

## Distribution

The runtime file contains its own MIT notice and palette definitions. It can be distributed alone with its notice intact. The complete project adds documentation, optional tests and a release packager; see [Testing](docs/TESTING.md). No private layout, foundry documentation, commercial tool binaries, authentication files or real-design screenshots are included.

Cadence, Virtuoso and SKILL are product names of their respective owners. This independent extension does not include or license Cadence software or any PDK.
