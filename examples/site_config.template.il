; SPDX-License-Identifier: MIT
; COPY outside the public project as site.local.il, edit, then load AFTER runtime.
; Templates never run automatically. Remove this guard only after adaptation.
error("Template only: edit real layers, PAD cells and roles; then remove this guard.\n")

; Physical trace LOWER/UPPER metal layer names, not GDS numbers or via names.
; Replace both endpoints with real technology names and verify native tracing.
lsncStackLayers=list("M1" "M6")
lsnConfigure('unitLabel "um") ; display text only; does not scale coordinates
lsnConfigure('localViewWidth 40.0)
lsnConfigure('labelLayerMap list(list("M2TXT" "M2")))

; Only libraries devoted to PAD cells. A mixed design library must not go here.
; Replace the defaults with your site's dedicated PAD libraries, or use nil.
lsnpDedicatedPadLibraries=list("my_pad_lib")

; Register only the exact cells/roles that were inspected at this site.
; A matching OA terminal's actual figures are preferred. If absent, "label"
; uses these exact label names and landing metal. This is NOT a net alias.
; Delete unused examples. Do not whitelist an external bond or supply as data.
lsnPadRegisterProfile("my_pad_lib" "MY_BUFFERED_IO"
  list(
    list("CORE_IN" "label" list("CORE_IN"))
    list("CORE_OUT" "label" list("CORE_OUT"))
    list("OUTPUT_ENABLE" "label" list("OUTPUT_ENABLE"))
  ))

; Power core terminal. Its intended domain must come from your schematic.
lsnPadRegisterProfile("my_pad_lib" "MY_VDD_PAD"
  list(list("VDD_CORE" "label" list("VDD_CORE"))))

; Optional PASSIVE, single equipotential bond contact only.
; "PAD_OPEN" must exist with purpose "drawing"; "M6" is the true metal.
; Not suitable for buffered GPIO or a master with unrelated bond domains.
lsnPadRegisterProfile("my_pad_lib" "MY_PASSIVE_PAD"
  list(list("IO" "bond" "PAD_OPEN" "M6")))

; If text is on actual metal layers, labelLayerMap may instead be nil.
; If needed, select the REAL source (does not create instance bindings):
; lsnConfigure('sourceOverride list("design_lib" "core_top" "schematic"))
; Before starting: lsnCheckEnvironment()
; Activate the intended layout; lsnStart()
