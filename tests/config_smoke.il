; SPDX-License-Identifier: MIT
; Load the runtime first, then load this file and call lsnRunConfigTests().
; No design objects or test libraries are created by this suite.

procedure(lsnTestEqual(name actual expected)
  unless(equal(actual expected)
    error("FAIL %s: actual=%L expected=%L\n" name actual expected))
  lsnTestResults=cons(name lsnTestResults)
  t
)

procedure(lsnRunConfigTests()
  let((savedConfig savedDirty result)
    savedConfig=lsnConfig
    savedDirty=lsnState['configDirty]
    lsnTestResults=nil
    unwindProtect(
      progn(
        lsnConfig=makeTable('lsnConfigSmoke 'lsnUnset)
        lsnApplyDefaults()
        lsnTestEqual("default width" lsnCfg('localViewWidth) 30.0)
        lsnConfigure('labelHints nil)
        lsnApplyDefaults()
        lsnTestEqual("false survives defaults" lsnCfg('labelHints) nil)
        lsnTestEqual("bus angle/square" lsnBusLabelKey("CTRL<0>") lsnBusLabelKey("CTRL[0]"))
        lsnTestEqual("case is preserved" equal(lsnBusLabelKey("Ctrl[0]") lsnBusLabelKey("CTRL[0]")) nil)
        lsnConfigure('normalizeBusBrackets nil)
        lsnTestEqual("normalization can be disabled" lsnBusLabelKey("CTRL[0]") "CTRL[0]")
        lsnConfigure('localViewWidth 0.25)
        lsnTestEqual("small user-unit width" lsnCfg('localViewWidth) 0.25)
        lsnConfigure('labelProbeRadius 0.002)
        lsnTestEqual("explicit probe radius" lsnCfg('labelProbeRadius) 0.002)
        lsnConfigure('sourceOverride list("demo_lib" "logic_top" "schematic"))
        lsnTestEqual("explicit source" lsnCfg('sourceOverride) list("demo_lib" "logic_top" "schematic"))
        lsnConfigure('labelLayerMap list(list("M2TXT" "M2")))
        lsnTestEqual("layer map" lsnCfg('labelLayerMap) list(list("M2TXT" "M2")))
        lsnTestEqual("reject unknown option" errset(lsnConfigure('notAnOption t) nil) nil)
        lsnTestEqual("reject negative width" errset(lsnConfigure('localViewWidth -1) nil) nil)
        lsnTestEqual("reject fractional limit" errset(lsnConfigure('chainLimit 2.5) nil) nil)
        lsnTestEqual("reject nonboolean" errset(lsnConfigure('labelHints "yes") nil) nil)
        lsnTestEqual("reject malformed map" errset(lsnConfigure('labelLayerMap list("M2TXT")) nil) nil)
        lsnTestEqual("reject malformed source" errset(lsnConfigure('sourceOverride list("only" "two")) nil) nil)
        result=reverse(lsnTestResults)
        printf("PASS: %d configuration checks.\n" length(result))
        result)
      progn(lsnConfig=savedConfig lsnState['configDirty]=savedDirty))
  )
)
