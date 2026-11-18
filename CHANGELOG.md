# Changelog

## 0.3.5 — 2026-11-18

- Add whole-layout scalar Pin/Net statistics: totals, current completed count/rate, Open, Unverified and Pending. Count bus aggregates separately; do not count stale or unproven single-location outcomes as completed.
- Split Open into Pin Open and Net Open. Reduce Show to All, Pin, Nets, Pin Open, Net Open and Unverified. Keep detailed connection states in the table and retain the existing check controls.
- Update statistics after single-net checks and list processing without initiating extra checks or changing selection/other cache entries. Add focused in-memory UI/statistics regressions and adapt the PAD regression's filter assertion.
- Preserve the frozen 0.3.4 distribution, backup and installation; publish changes under a new version.

## 0.3.4 — 2026-11-18

- Freeze the validated runtime without algorithm changes. Add guarded per-site PAD/technology and per-design target templates, detailed cross-PDK porting and maintenance guides, a pinned runtime checksum, and standalone release verification. Public packaging rejects private local configurations and existing output archives. These distribution updates do not imply new native EDA regression runs or additional PDK certification.

- Split internal connectivity from mandatory PAD access for schematic Pins. Internal completion without a PAD no longer appears in Connected.
- Discover whitelisted real PAD occurrences, read physical core access from terminal figures, hierarchical labels or verified bond-metal contacts, and prove actual metal/via continuity.
- Add native PAD setup with explicit multi-target binding, logical-assignment conflict protection, source/layout intent lookup, target navigation and save/load of local mapping configuration.
- Support PADs in a parent assembly with explicit core occurrence paths, rotations/mirroring, correctly targeted windows and overview/back navigation.
- Treat multiple access shapes as alternatives for one required terminal, rather than demanding every shape be separately routed.
- Add 41 PAD integration checks against independent disposable fixtures referencing the installed analog/GPIO PAD masters. Explicit targets supplement existing logical obligations, and identical profile reloads preserve other results. No production geometry or prediction worker is modified.

## 0.3.3 — 2026-11-17

- Clarify Pin as top-level schematic I/O intended for PAD connection; derive it from source terminals, including bus members/aggregate records, independently of cached checks or layout pin placement.
- Replace Ports, Pin not placed and Physical pin Show categories with one Pin choice. Nets is the complementary internal-net category; placement/connection details remain in the tables.
- Keep the 0.3.2 per-net cache and connection-status filters.

## 0.3.2 — 2026-11-17

- Check selected replaces only the selected cached result. A newly opened cellview or trace-loaded master no longer resets the entire signal table.
- Separate stable layout/configuration identity from each result's revision snapshot. Retain stale conclusions with a needs-recheck marker and recheck the selected net before reuse.
- Add structured, overlapping outcome flags and Show filters for Open, Connected, Pin not placed, Unverified, Not checked, Needs recheck, Physical pin, Single location and Bus.
- Keep name search, Ports/Nets filters, current selection and visible-list checking behavior.
- Add 24 focused read-only cache/UI regressions, including the previously reproduced cache-reset trigger. Prediction remains unloaded.

## 0.3.1 — 2026-11-17

Navigation-only continuation of 0.3.0; no prediction modules are loaded.

- Index schematic terminal and instance-terminal memberships, expanding buses in their declared order before matching individual bits. Aggregate-only EEPROM pins are no longer omitted from scalar nets.
- Resolve label landing metal through ordinary instance hierarchy, preserving coordinate transforms and rejecting unsupported array paths.
- Read schematic IN/OUT/INOUT directions, show them beside locations, and distinguish unplaced schematic I/O from unresolved physical geometry.
- Add top-level I/O label fallback when formal layout terminals are absent; label locations remain explicitly marked as hints.
- Omit basic/noConn markers as physical endpoints.
- Keep physical connectivity status, per-location groups, manual pending-only stepping, and a cancellable per-net check queue in the standalone single-file navigator.
- Preserve the original 0.3.0 release ZIP and archive the 0.4 prediction branch without loading it.

## 0.3.0 — 2026-11-16

First portable public-project release.

- Single runtime file with embedded MIT notice and original display definitions.
- Removed workstation paths, preferred design names and external palette dependency.
- Added validated configuration, unit labels, layer-name mapping and source override.
- Added critical API capability reporting and optional connectivity/palette degradation.
- Refused ambiguous layout-window selection; added close/reset entry points.
- Kept physical-pin, label and block-only statuses distinct.
- Added installation, porting, user, troubleshooting, compatibility and architecture guides, plus optional tests and release packaging.

## Prototype lineage

The earlier local prototypes established named navigation, manual cyclic stepping and logical overview. The second prototype added navigation to label anchors and bound module ranges when formal terminal shapes were absent. Those prototypes contained site-specific examples and are not included in this public project.
