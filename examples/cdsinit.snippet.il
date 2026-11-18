; SPDX-License-Identifier: MIT
; Append an adapted snippet to YOUR startup file only after manual validation.
; These are placeholder paths; replace them before use.
load("/path/to/signal_navigator.il")
; load("/path/to/config.local.il")
; For another PDK, load your EDITED site.local.il here, before lsnStart().
; Do not load per-design PAD bindings until the intended core is bound.
; Activate a layout and run lsnStart() manually after startup.
