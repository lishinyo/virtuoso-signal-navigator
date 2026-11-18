; SPDX-License-Identifier: MIT
; COPY outside the public project as design.local.il and replace placeholders.
; Load runtime, then site profile, then lsnStart(); load this file LAST.
error("Template only: edit scope, scalar nets, instance paths and roles; remove this guard.\n")

; Optional: PADs are in a parent assembly. Exact core occurrence, not cell name.
; Delete this call if the PADs and core are in the currently bound layout.
; lsnPadUseScope("design_lib" "chip_top" "layout" list("WRAP" "CORE"))

; Source schematic scalar I/O -> exact PAD occurrence -> allowed core role.
; CORE_IN means input INTO THIS PAD, not necessarily a schematic input Pin.
lsnPadBind("DOUT<0>" list("PAD_RING" "U_IO0") "CORE_IN")
lsnPadBind("DIN<0>" list("PAD_RING" "U_IO0") "CORE_OUT")
lsnPadBind("OE<0>" list("PAD_RING" "U_IO0") "OUTPUT_ENABLE")

; Both power PADs are required; two bindings mean AND, not alternatives.
lsnPadBind("VDD" list("PAD_RING" "U_VDD0") "VDD_CORE")
lsnPadBind("VDD" list("PAD_RING" "U_VDD1") "VDD_CORE")

; The GUI can also create these assignments. Save to a NEW absolute path:
; lsnPadSaveConfig("/home/user/project/pad_targets_01.il")
; Saved files contain names/profiles/paths, not database IDs or windows.
; A different design/PDK needs review; do not reuse mappings by proximity.
