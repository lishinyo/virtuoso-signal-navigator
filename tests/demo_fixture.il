; SPDX-License-Identifier: MIT
; OPTIONAL, EXPLICITLY WRITE-ENABLED TEST HELPER -- not part of the runtime.
; Run in a fresh, disposable Virtuoso working directory with its own cds.lib.
; Requires a NEW library name beginning LSN_DEMO_ and a NEW absolute path.
; Refuses an existing library or directory. No automatic deletion is performed.

procedure(lsnDemoPin(cv name bb)
  let((net term fig)
    net=dbCreateNet(cv name)
    term=dbCreateTerm(net name "inputOutput")
    fig=dbCreateRect(cv list("M1" "drawing") bb)
    unless(fig error("Demo M1 layer is unavailable.\n"))
    dbCreatePin(net fig name term)
    term
  )
)

procedure(lsnCreateDemo(libName libPath)
  let((lib tf analog digital top a d net term fig win cg oldGroup)
    unless(stringp(libName) && substring(libName 1 9)=="LSN_DEMO_"
      error("Use a NEW library name beginning LSN_DEMO_.\n"))
    unless(stringp(libPath) && substring(libPath 1 1)=="/"
      error("Use an absolute Linux path for the NEW demo library.\n"))
    when(ddGetObj(libName) || isDir(libPath) || isFile(libPath)
      error("Demo target already exists; no files were replaced.\n"))
    lib=ddCreateLib(libName libPath)
    unless(lib error("Could not create the new demo library.\n"))
    ; A new, unattached library only: never append to another technology.
    tf=techOpenTechFile(libName "tech" "a")
    unless(tf && tf~>libName==libName
      error("Demo technology ownership is not the new library; stopping.\n"))
    unless(techGetPurposeNum(tf "drawing") techCreatePurpose(tf 0 "drawing"))
    foreach(pair list(list(1 "M1") list(2 "M2") list(3 "M2TXT"))
      techCreateLayer(tf car(pair) cadr(pair)))
    foreach(layer list("M1" "M2" "M2TXT")
      unless(techCreateLP(tf list(layer "drawing") layer)
        error("Could not define demo layer-purpose %s/drawing.\n" layer)))
    techSetMfgGridResolution(tf 0.001)
    cg=cstCreateConstraintGroupIn(tf "virtuosoDefaultExtractorSetUp" "userDefined")
    unless(cg && cstCreateConstraint(cg "validLayers" nil list("M1" "M2"))
      error("Could not define demo connectivity layers.\n"))
    techSaveTechFile(tf)
    analog=dbOpenCellViewByType(libName "analog" "layout" "maskLayout" "a")
    lsnDemoPin(analog "P0" list(0:0 1:1))
    lsnDemoPin(analog "P1" list(0:4 1:5))
    dbSave(analog)
    digital=dbOpenCellViewByType(libName "digital_geometry" "layout" "maskLayout" "a")
    dbCreateRect(digital list("M2" "drawing") list(9.5:4.5 10.5:5.5))
    dbCreateLabel(digital list("M2" "drawing") 10:5 "CTRL[0]" "lowerLeft" "R0" "stick" 1.0)
    dbCreateRect(digital list("M2" "drawing") list(9.5:14.5 10.5:15.5))
    dbCreateLabel(digital list("M2TXT" "drawing") 10:15 "CTRL[1]" "lowerLeft" "R0" "stick" 1.0)
    dbCreateRect(digital list("M2" "drawing") list(0:0 30:30))
    dbSave(digital)
    top=dbOpenCellViewByType(libName "demo_top" "layout" "maskLayout" "a")
    a=dbCreateInst(top analog "A0" 20:20 "R90")
    d=dbCreateInst(top digital "D0" 100:40 "MY")
    foreach(pair list(list("CTRL<0>" "P0") list("CTRL<1>" "P1"))
      net=dbCreateNet(top car(pair))
      term=dbFindTermByName(analog cadr(pair))
      dbCreateInstTerm(net a term))
    net=dbFindNetByName(top "CTRL<0>")
    term=dbCreateTerm(net "OUT" "inputOutput")
    fig=dbCreateRect(top list("M1" "drawing") list(0:20 1:21))
    dbCreatePin(net fig "OUT" term)
    dbSave(top)
    dbClose(top) dbClose(analog) dbClose(digital)
    oldGroup=envGetVal("layout" "setupConstraintGroup")
    unwindProtect(
      progn(
        envSetVal("layout" "setupConstraintGroup" 'string "virtuosoDefaultExtractorSetUp")
        win=deOpenCellView(libName "demo_top" "layout" "maskLayout" list(0:0 1200:950) "r"))
      when(stringp(oldGroup) envSetVal("layout" "setupConstraintGroup" 'string oldGroup)))
    printf("Created original synthetic demo %s at %s. Opened read-only in %L.\n" libName libPath win)
    win
  )
)

procedure(lsnRunDemoTests(win)
  let((cv inst r p record savedMap results)
    lsnStart(win)
    cv=lsnState['cv]
    unless(cv~>cellName=="demo_top" && substring(cv~>libName 1 9)=="LSN_DEMO_"
      error("Run only on a synthetic demo created by lsnCreateDemo.\n"))
    lsnTestResults=nil
    lsnChoose("CTRL<0>" nil)
    lsnTestEqual("layout-only locations" length(lsnState['points]) 2)
    lsnTestEqual("formal port first" nth(4 car(lsnState['points])) "PORT")
    p=cadr(cadr(lsnState['points]))
    lsnTestEqual("rotation X" abs(xCoord(p)-19.5)<0.000001 t)
    lsnTestEqual("rotation Y" abs(yCoord(p)-20.5)<0.000001 t)
    lsnGo(1) lsnNext(1)
    lsnTestEqual("manual forward wrap" lsnState['index] 0)
    lsnNext(-1)
    lsnTestEqual("manual reverse wrap" lsnState['index] 1)
    ; Direct engine checks isolate imported-geometry behavior from optional
    ; schematic binder/license availability. They do not create a binding.
    inst=dbFindAnyInstByName(cv "D0")
    savedMap=lsnCfg('labelLayerMap)
    unwindProtect(
      progn(
        lsnConfig['labelLayerMap]=nil
        lsnState['points]=nil
        lsnAddInstanceHint(inst "CTRL[0]" "D0/CTRL[0]")
        record=car(lsnState['points])
        lsnTestEqual("label status" nth(5 record) "Label + metal")
        lsnTestEqual("mirror X" abs(xCoord(cadr(record))-90.0)<0.000001 t)
        lsnTestEqual("mirror Y" abs(yCoord(cadr(record))-45.0)<0.000001 t)
        lsnState['points]=nil
        lsnAddInstanceHint(inst "CTRL[1]" "D0/CTRL[1]")
        lsnTestEqual("unmapped text layer" nth(5 car(lsnState['points])) "Label anchor")
        lsnState['points]=nil
        lsnState['seen]=makeTable('lsnDemoSeen nil)
        lsnConfig['labelLayerMap]=list(list("M2TXT" "M2"))
        lsnAddInstanceHint(inst "CTRL[1]" "D0/CTRL[1]")
        lsnTestEqual("mapped text layer" nth(5 car(lsnState['points])) "Label + metal")
        lsnState['points]=nil
        lsnAddInstanceHint(inst "NO_SUCH_LABEL" "D0/NO_SUCH_LABEL")
        lsnTestEqual("module hint remains coarse" nth(4 car(lsnState['points])) "INSTANCE")
        results=reverse(lsnTestResults))
      lsnConfig['labelLayerMap]=savedMap)
    lsnChoose("CTRL<0>" nil)
    lsnOverview()
    printf("PASS: %d synthetic layout/geometry checks.\n" length(results))
    results
  )
)
