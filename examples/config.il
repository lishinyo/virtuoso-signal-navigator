; SPDX-License-Identifier: MIT
; Optional configuration example. Load the runtime script first.
; Values below are illustrative; use the actual units/layer names at your site.
; For physical stack/PAD adaptation, also see site_config.template.il and
; design_targets.template.il. Navigation reset does not reset PAD profiles.

lsnConfigure('localViewWidth 40.0)
lsnConfigure('unitLabel "um") ; text only, not a coordinate conversion
lsnConfigure('labelHints t)
lsnConfigure('blockHints t)
lsnConfigure('normalizeBusBrackets t)
lsnConfigure('maxMetalExtents 1000)
lsnConfigure('chainLimit 300)
lsnConfigure('annotationLimit 40)
lsnConfigure('dockByDefault nil)

; Uncomment and adapt if text and routing use different layer names:
; lsnConfigure('labelLayerMap list(list("M2TXT" "M2")))

; Explicit source selection does not create missing instance bindings:
; lsnConfigure('sourceOverride list("demo_lib" "logic_top" "schematic"))

; To require native net bindings for source nets:
; lsnConfigure('sameNameNetFallback nil)

; To use an existing writable directory for palette initialization:
; lsnConfigure('tempDir "/path/to/writable/temp")

; Open the panel only after activating the intended layout:
; lsnStart()
