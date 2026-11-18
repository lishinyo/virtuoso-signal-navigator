; Signal Navigator 0.3.5 -- standalone navigation; no route prediction.
; SPDX-License-Identifier: MIT
; Copyright (c) 2026 Signal Navigator contributors
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;
; Load this file with load("/your/location/signal_navigator.il").
; Then run lsnStart() from a layout, or lsnStart(window(n)).
; No Python, Bridge, WSL, external .drf, or foundry files are required by this
; script. Virtuoso and the capabilities listed in lsnCheckEnvironment() are.
; Design databases are read only. Palette setup briefly writes one temporary
; file, loads its original display definitions, and deletes that exact file.
; Scope: current edit level. Logical lines do not establish continuity.

unless(boundp('lsnState) lsnState=makeTable('lsnState nil))
unless(boundp('lsnConfig) lsnConfig=makeTable('lsnConfig 'lsnUnset))
lsnVersion="0.3.5"
lsnOptionKeys=list('localViewWidth 'minViewSpan 'unitLabel 'labelProbeRadius
  'labelHints 'blockHints 'normalizeBusBrackets 'labelLayerMap
  'sameNameNetFallback 'sourceOverride 'maxMetalExtents 'chainLimit
  'annotationLimit 'dockByDefault 'useCustomPalette 'tempDir)

procedure(lsnDefault(key value)
  when(lsnConfig[key]=='lsnUnset lsnConfig[key]=value)
)

procedure(lsnApplyDefaults()
  lsnDefault('localViewWidth 30.0)
  lsnDefault('minViewSpan 20.0)
  lsnDefault('unitLabel "user units")
  lsnDefault('labelProbeRadius nil)
  lsnDefault('labelHints t)
  lsnDefault('blockHints t)
  lsnDefault('normalizeBusBrackets t)
  lsnDefault('labelLayerMap nil)
  lsnDefault('sameNameNetFallback t)
  lsnDefault('sourceOverride nil)
  lsnDefault('maxMetalExtents 2000)
  lsnDefault('chainLimit 500)
  lsnDefault('annotationLimit 50)
  lsnDefault('dockByDefault nil)
  lsnDefault('useCustomPalette t)
  lsnDefault('tempDir nil)
)
lsnApplyDefaults()

procedure(lsnCfg(key) lsnConfig[key])

procedure(lsnConfigure(key value)
  let((valid)
    unless(member(key lsnOptionKeys) error("Signal Navigator: unknown option %L\n" key))
    valid=cond(
      (member(key list('labelHints 'blockHints 'normalizeBusBrackets
        'sameNameNetFallback 'dockByDefault 'useCustomPalette)) value==t || value==nil)
      (member(key list('localViewWidth 'minViewSpan)) numberp(value) && value>0)
      (key=='labelProbeRadius value==nil || (numberp(value) && value>0))
      (member(key list('maxMetalExtents 'chainLimit 'annotationLimit)) fixp(value) && value>0)
      (key=='unitLabel stringp(value))
      (key=='tempDir value==nil || (stringp(value) && isDir(value)))
      (key=='sourceOverride value==nil || (listp(value) && length(value)==3 &&
        !setof(item value !stringp(item))))
      (key=='labelLayerMap value==nil || (listp(value) &&
        !setof(item value !listp(item) || length(item)!=2 ||
          !stringp(car(item)) || !stringp(cadr(item)))))
      (t nil))
    unless(valid error("Signal Navigator: invalid value %L for option %L\n" value key))
    lsnConfig[key]=value
    lsnState['configDirty]=t
    value
  )
)

procedure(lsnCheckEnvironment()
  let((missing optional)
    foreach(fn list('geGetEditCellView 'geGetWindowCellView 'hiGetWindowList
      'hiCreateLayoutForm 'hiCreateReportField 'hiCreateVerticalBoxLayout
      'hiCreateHorizontalBoxLayout 'hiCreateDockWindow 'hiDockWindow
      'hiGetSessionWindow 'hiReportSelectItem 'hiGetViewBBox 'hiPan 'hiZoomIn
      'geCreateWindowHilightSet 'geAddHilightLine 'geAddHilightDot
      'geAddHilightRectangle 'geAddHilightLabel 'geDeleteHilightSet
      'geEditToWindowPoint 'dbFindNetByName 'dbFindTermByName 'dbTransformBBox
      'dbTransformPoint 'dbGetOverlaps 'dbGetTrueOverlaps 'dbConcatTransform 'dbProduceMemName)
      unless(isCallable(fn) missing=cons(fn missing)))
    foreach(fn list('lxGetSchematic 'bndGetBoundObjects 'drLoadDrf 'makeTempFileName)
      optional=cons(list(fn isCallable(fn)) optional))
    printf("Signal Navigator %s | missing required: %L | optional: %L\n"
      lsnVersion reverse(missing) reverse(optional))
    list(list('version lsnVersion) list('missingRequired reverse(missing))
      list('optional reverse(optional)))
  )
)

procedure(lsnEnsurePalette()
  let((path port result directory)
    lsnState['palette]=nil
    when(lsnCfg('useCustomPalette) && isCallable('drLoadDrf) && isCallable('makeTempFileName)
      directory=lsnCfg('tempDir) || getShellEnvVar("TMPDIR") || "/tmp"
      result=errset(
        unwindProtect(
          progn(
            path=makeTempFileName(strcat(directory "/lsn_palette_"))
            port=outfile(path)
            unless(port error("Cannot write navigator temporary palette.\n"))
            fprintf(port "drDefineColor( (display lsnCyan 80 255 255) (display lsnYellow 255 245 40) (display lsnMagenta 255 90 225) (display lsnOrange 255 155 45) )\n")
            fprintf(port "drDefineLineStyle( (display lsnSolid 3 (1 1 1)) (display lsnDashed 2 (1 1 1 1 0 0 0)) )\n")
            fprintf(port "drDefinePacket( (display lsnLocation solid lsnSolid lsnYellow lsnYellow) (display lsnConnection solid lsnSolid lsnCyan lsnCyan) (display lsnMetal blank solid lsnMagenta lsnMagenta) (display lsnCandidate solid lsnSolid lsnOrange lsnOrange) (display lsnCandidateLine solid lsnDashed lsnOrange lsnOrange) )\n")
            close(port) port=nil
            drLoadDrf(path nil))
          progn(
            when(port close(port))
            when(path && isFile(path) deleteFile(path))))
        t)
      lsnState['palette]=result && car(result))
    unless(lsnState['palette]
      printf("Signal Navigator: using existing y0/y1/y2 highlight layers. Colors depend on your display setup.\n"))
    lsnState['palette]
  )
)

procedure(lsnResolveSource(cv)
  let((override result source)
    override=lsnCfg('sourceOverride)
    if(override then
      result=errset(dbOpenCellViewByType(car(override) cadr(override) caddr(override) "" "r") nil)
      when(result source=car(result))
      unless(source printf("Signal Navigator: explicit schematic could not be opened: %L\n" override))
      else
      when(isCallable('lxGetSchematic)
        result=errset(lxGetSchematic(cv) nil)
        when(result source=car(result))))
    source
  )
)

procedure(lsnMessage(text)
  when(lsnState['form] lsnState['form]->lsnStatus->value=text)
  text
)

procedure(lsnDbObjects(value)
  let((out)
    cond(
      (dbIsId(value) out=list(value))
      (listp(value)
        foreach(item value out=append(out lsnDbObjects(item))))
    )
    out
  )
)

procedure(lsnBound(object cv)
  let((r)
    when(isCallable('bndGetBoundObjects) r=errset(bndGetBoundObjects(object cv) nil))
    when(r lsnDbObjects(car(r)))
  )
)

procedure(lsnValid()
  let((r)
    r=errset(geGetEditCellView(lsnState['window]) nil)
    if(r && car(r)==lsnState['cv] then t
      else lsnMessage("Layout context changed. Use Bind current layout.") nil)
  )
)

procedure(lsnFindWindow()
  let((candidate r cv candidates)
    r=errset(geGetEditCellView(hiGetCurrentWindow()) nil)
    when(r && car(r) && car(r)~>cellViewType=="maskLayout"
      candidate=hiGetCurrentWindow())
    unless(candidate
    foreach(w hiGetWindowList()
      r=errset(geGetEditCellView(w) nil)
      when(r
        cv=car(r)
        when(cv && cv~>cellViewType=="maskLayout"
          candidates=cons(w candidates)
        )
      )
    )
    when(length(candidates)==1 candidate=car(candidates))
    when(!candidate && length(candidates)>1
      printf("Signal Navigator: several layout windows are open. Activate one, or call lsnStart(window(n)). Candidates: %L\n" candidates))
    )
    candidate
  )
)

procedure(lsnScalars(net)
  if(net && net~>numBits>1 then net~>signals else list(net))
)

procedure(lsnLayoutNets(sourceNet name)
  let((nets n)
    when(sourceNet
      foreach(obj lsnBound(sourceNet lsnState['cv])
        when(obj~>objType=="net" && obj~>cellView==lsnState['cv]
          unless(member(obj nets) nets=cons(obj nets)))
      )
    )
    when(!nets && (!sourceNet || lsnCfg('sameNameNetFallback))
      n=dbFindNetByName(lsnState['cv] name)
      when(n nets=list(n))
    )
    nets
  )
)

procedure(lsnWindowBBox(bb)
  let((p q)
    p=geEditToWindowPoint(lsnState['window] car(bb))
    q=geEditToWindowPoint(lsnState['window] cadr(bb))
    list(list(min(xCoord(p) xCoord(q)) min(yCoord(p) yCoord(q)))
         list(max(xCoord(p) xCoord(q)) max(yCoord(p) yCoord(q))))
  )
)

procedure(lsnCenter(bb)
  list((xCoord(car(bb))+xCoord(cadr(bb)))/2.0
       (yCoord(car(bb))+yCoord(cadr(bb)))/2.0)
)

procedure(lsnAddPinTerm(term transform prefix kind)
  let((count figs bb key label layer)
    count=0
    lsnSetEndpointInfo(prefix term~>direction "layout" nil)
    foreach(pin term~>pins
      figs=pin~>figs
      unless(figs when(pin~>fig figs=list(pin~>fig)))
      foreach(fig figs
        when(fig~>bBox
          count=count+1
          bb=fig~>bBox
          when(transform bb=dbTransformBBox(bb transform))
          bb=lsnWindowBBox(bb)
          label=sprintf(nil "%s#%d" prefix count)
          key=sprintf(nil "%s:%L" prefix bb)
          unless(lsnState['seen][key]
            lsnState['seen][key]=t
            layer=sprintf(nil "%s" fig~>layerName)
            lsnState['points]=cons(list(label lsnCenter(bb) bb layer kind "Physical pin" prefix) lsnState['points])
          )
        )
      )
    )
    when(count>0 lsnState['pinPrefixes][prefix]=t)
    count
  )
)

procedure(lsnBusLabelKey(name)
  ; Match square/angle bus spelling only after trying an exact label name.
  ; Keep case, index order, hierarchy separators and signal suffixes intact.
  if(lsnCfg('normalizeBusBrackets) then buildString(parseString(name "<[]>") "|") else name)
)

procedure(lsnFindLabels(master name)
  let((cached exact canonical labels key)
    unless(lsnState['labelCache] lsnState['labelCache]=makeTable('lsnLabelCache nil))
    cached=lsnState['labelCache][master]
    unless(cached
      exact=makeTable('lsnExactLabels nil)
      canonical=makeTable('lsnCanonicalLabels nil)
      foreach(fig master~>shapes
        when(fig~>objType=="label" && stringp(fig~>theLabel)
          key=fig~>theLabel
          exact[key]=cons(fig exact[key])
          key=lsnBusLabelKey(key)
          canonical[key]=cons(fig canonical[key])))
      cached=list(exact canonical)
      lsnState['labelCache][master]=cached)
    exact=car(cached) canonical=cadr(cached)
    labels=exact[name]
    unless(labels labels=canonical[lsnBusLabelKey(name)])
    labels=setof(fig labels dbIsId(fig) &&
      (fig~>theLabel==name || lsnBusLabelKey(fig~>theLabel)==lsnBusLabelKey(name)))
    labels
  )
)

procedure(lsnAddInstanceHint(inst termName prefix)
  let((count bb key)
    count=if(lsnState['pinPrefixes][prefix] then 1 else lsnAddLabelHint(inst~>master termName inst~>transform prefix))
    when(count==0 && lsnCfg('blockHints) && inst~>bBox
      count=1 bb=lsnWindowBBox(inst~>bBox) key=strcat("owner:" prefix)
      unless(lsnState['seen][key]
        lsnState['seen][key]=t
        lsnState['points]=cons(list(strcat(prefix " @block") lsnCenter(bb) bb
          "-" "INSTANCE" "Block only" prefix) lsnState['points])))
    count))

procedure(lsnRecordMissing(label reason @optional category direction)
  let((key)
    when(category=="UNPLACED_IO" lsnState['missing]=setof(m lsnState['missing] car(m)!=label))
    key=strcat(label ":" reason)
    unless(lsnState['missingSeen][key]
      lsnState['missingSeen][key]=t
      lsnState['missing]=cons(list(label reason category direction) lsnState['missing])
    )
  )
)

procedure(lsnCollect(record)
  let((name kind snets lnets term count boundIts layoutInsts iterms prefix)
    name=car(record)
    kind=cadr(record)
    snets=if(caddr(record) then lsnScalars(caddr(record)) else nil)
    lsnEnsureSourceIndex()
    lsnState['endpointInfo]=makeTable('lsnEndpointInfo nil)
    lsnState['points]=nil
    lsnState['missing]=nil
    lsnState['seen]=makeTable('lsnSeen nil)
    lsnState['pinPrefixes]=makeTable('lsnPinPrefixes nil)
    lsnState['labelPrefixes]=makeTable('lsnLabelPrefixes nil)
    lsnState['missingSeen]=makeTable('lsnMissingSeen nil)
    lnets=nil
    if(snets then
      foreach(sn snets
        foreach(ln lsnLayoutNets(sn sn~>name)
          unless(member(ln lnets) lnets=cons(ln lnets))))
      else lnets=lsnLayoutNets(nil name)
    )
    lsnState['layoutNets]=lnets
    ; Physical database membership is the primary endpoint source.
    foreach(ln lnets
      foreach(tm ln~>terms
        count=lsnAddPinTerm(tm nil strcat("PORT/" tm~>name) "PORT")
        when(count==0 lsnRecordMissing(strcat("PORT/" tm~>name) "No physical pin"))
      )
      progn(
        foreach(it ln~>instTerms
          prefix=strcat(it~>inst~>name "/" it~>name)
          count=lsnAddPinTerm(it~>term it~>inst~>transform prefix "PIN")
          when(count==0 count=lsnAddInstanceHint(it~>inst it~>name prefix))
          when(count==0 lsnRecordMissing(prefix "No physical pin"))
        )
      )
    )
    ; Scan ordered schematic bus memberships, including aggregate-only instTerms.
    foreach(sn snets
      foreach(item lsnState['sourcePorts][sn~>name] lsnCollectSourcePort(item sn~>name))
      foreach(item lsnState['sourceEndpoints][sn~>name] lsnCollectSourceEndpoint(item sn~>name)))
    ; A subsequently resolved physical pin supersedes a coarse hint.
    lsnState['points]=setof(ep lsnState['points]
      (member(nth(4 ep) list("PIN" "PORT")) || !lsnState['pinPrefixes][nth(6 ep)]) &&
      (nth(4 ep)!="INSTANCE" || !lsnState['labelPrefixes][nth(6 ep)]))
    lsnState['points]=foreach(mapcar ep lsnState['points]
      append(ep lsnState['endpointInfo][nth(6 ep)] || list(nil nil nil)))
    lsnState['missing]=setof(m lsnState['missing]
      !exists(ep lsnState['points] nth(6 ep)==car(m)))
    lsnState['points]=sort(lsnState['points] lambda((a b)
      cond((rexMatchp("^PORT/" nth(6 a)) && !rexMatchp("^PORT/" nth(6 b)) t)
           (!rexMatchp("^PORT/" nth(6 a)) && rexMatchp("^PORT/" nth(6 b)) nil)
           (t alphalessp(car(a) car(b))))))
    lsnState['missing]=sort(lsnState['missing] lambda((a b) alphalessp(car(a) car(b))))
    when(isCallable('lsnpAppendNavigation)
      lsnState['points]=lsnpAppendNavigation(record lsnState['points]))
    lsnState['points]
  )
)

procedure(lsnClear()
  foreach(hs lsnState['hilights] errset(geDeleteHilightSet(hs) nil))
  lsnState['hilights]=nil
  when(lsnState['window] errset(hiRedraw(lsnState['window]) nil))
  t
)

procedure(lsnNewHilight(color @optional win)
  let((hs style)
    style=if(lsnState['palette] then
      cond((color=="y0" "lsnLocation") (color=="y1" "lsnConnection")
           (color=="candidate" "lsnCandidate") (color=="candidateLine" "lsnCandidateLine")
           (t "lsnMetal"))
      else list(if(member(color list("candidate" "candidateLine")) then "y2" else color) "drawing"))
    unless(win win=lsnState['window])
    hs=geCreateWindowHilightSet(win style)
    when(hs hs~>enable=t lsnState['hilights]=cons(hs lsnState['hilights]))
    hs
  )
)

procedure(lsnDrawPoint(hs entry size labelOn @optional win)
  let((p x y bb justify labelX)
    unless(win win=lsnState['window])
    p=cadr(entry) x=xCoord(p) y=yCoord(p)
    ; Dot dimensions are user units. Scale with the view to stay visible
    ; without covering a tiny physical pin when locally zoomed in.
    geAddHilightDot(hs p size*0.55 size*0.55)
    geAddHilightLine(hs list(list(x-size y) list(x+size y)))
    geAddHilightLine(hs list(list(x y-size) list(x y+size)))
    when(labelOn
      bb=hiGetViewBBox(win)
      justify="lowerLeft" labelX=x+size
      when(x>xCoord(lsnCenter(bb)) justify="lowerRight" labelX=x-size)
      geAddHilightLabel(hs list(labelX y+size) car(entry)
        justify "R0" "stick" size*0.7 t))
  )
)

procedure(lsnSaveView(@optional win)
  unless(win win=lsnState['window])
  lsnState['backWindow]=win
  lsnState['backBBox]=hiGetViewBBox(win)
)

procedure(lsnBack()
  when(lsnValid() && lsnState['backBBox]
    let((old win)
      win=lsnState['backWindow] || lsnState['window]
      when(windowp(win)
        old=hiGetViewBBox(win)
        hiZoomIn(win lsnState['backBBox])
        lsnState['backBBox]=old)
    )
  )
)

procedure(lsnFillEndpoints()
  let((rows i pins labels blocks)
    i=0
    foreach(ep lsnState['points]
      i=i+1
      rows=cons(list(i car(ep) nth(3 ep) nth(5 ep) || "Physical pin") rows))
    foreach(m lsnState['missing]
      rows=cons(list(0 car(m) "-" cadr(m)) rows))
    lsnState['busy]=t
    lsnState['form]->lsnEndpoints->choices=reverse(rows)
    lsnState['busy]=nil
    pins=length(setof(ep lsnState['points] member(nth(4 ep) list("PIN" "PORT"))))
    labels=length(setof(ep lsnState['points] nth(4 ep)=="LABEL"))
    blocks=length(setof(ep lsnState['points] nth(4 ep)=="INSTANCE"))
    lsnState['form]->lsnCurrent->value=sprintf(nil "%s | %d pin, %d label, %d block; %d missing"
      car(lsnState['record]) pins labels blocks length(lsnState['missing]))
  )
)

procedure(lsnGo(index @optional (saveView t))
  when(lsnValid() && lsnState['record]
    lsnCollect(lsnState['record])
    lsnFillEndpoints()
    if(lsnState['points] then
      let((n ep p bb radius hs width win)
        n=length(lsnState['points])
        index=mod(index n)
        when(index<0 index=index+n)
        lsnState['index]=index
        ep=nth(index lsnState['points])
        p=cadr(ep) win=lsnpEndpointWindow(ep)
        when(saveView lsnSaveView(win))
        if(nth(4 ep)=="INSTANCE" then
          bb=caddr(ep)
          radius=max(lsnCfg('minViewSpan)/2.0 (xCoord(cadr(bb))-xCoord(car(bb)))*0.10
                        (yCoord(cadr(bb))-yCoord(car(bb)))*0.10)
          hiZoomIn(win
            list(list(xCoord(car(bb))-radius yCoord(car(bb))-radius)
                 list(xCoord(cadr(bb))+radius yCoord(cadr(bb))+radius)))
          else
        if(lsnState['form]->lsnKeepZoom->value then
          hiPan(win p)
          else
          radius=lsnState['form]->lsnLocalWidth->value/2.0
          hiZoomIn(win
            list(list(xCoord(p)-radius yCoord(p)-radius)
                 list(xCoord(p)+radius yCoord(p)+radius)))
        )
        )
        lsnClear()
        bb=hiGetViewBBox(win)
        width=yCoord(cadr(bb))-yCoord(car(bb))
        hs=lsnNewHilight(if(member(nth(4 ep) list("LABEL" "INSTANCE" "PAD")) then "candidate" else "y0") win)
        lsnDrawPoint(hs ep width/55.0 t win)
        geAddHilightRectangle(hs caddr(ep))
        hiReportSelectItem(lsnState['form]->lsnEndpoints index nil)
        lsnMessage(sprintf(nil "%d/%d %s (%g, %g) | %s"
          index+1 n car(ep) xCoord(p) yCoord(p) nth(5 ep) || "Physical pin"))
        hiRedraw(win)
      )
      else lsnMessage("No physical pin location for this signal. See unavailable entries.")
    )
  )
)

procedure(lsnNext(delta)
  when(lsnState['record]
    lsnGo(if(lsnState['index]<0 then if(delta>0 then 0 else -1)
      else lsnState['index]+delta)))
)

procedure(lsnOverview()
  when(lsnValid() && lsnState['record]
    lsnCollect(lsnState['record])
    lsnFillEndpoints()
    if(lsnState['points] then
      let((pts lo hi p bb margin scale hs lineSet hintSet hintLines prev best bestD dist remain tree edgeCount useHint)
        lsnSaveView()
        pts=lsnState['points]
        lo=copy(cadr(car(pts))) hi=copy(lo)
        foreach(ep pts
          p=cadr(ep)
          lo=list(min(xCoord(lo) xCoord(p)) min(yCoord(lo) yCoord(p)))
          hi=list(max(xCoord(hi) xCoord(p)) max(yCoord(hi) yCoord(p))))
        scale=max(lsnCfg('minViewSpan) xCoord(hi)-xCoord(lo) yCoord(hi)-yCoord(lo))
        margin=scale*0.10
        bb=list(list(xCoord(lo)-margin yCoord(lo)-margin)
                list(xCoord(hi)+margin yCoord(hi)+margin))
        hiZoomIn(lsnState['window] bb)
        lsnClear()
        hs=lsnNewHilight("y0")
        lineSet=lsnNewHilight("y1")
        useHint=exists(ep pts member(nth(4 ep) list("LABEL" "INSTANCE")))
        when(useHint hintSet=lsnNewHilight("candidate") hintLines=lsnNewHilight("candidateLine"))
        bb=hiGetViewBBox(lsnState['window])
        scale=(yCoord(cadr(bb))-yCoord(car(bb)))/55.0
        foreach(ep pts
          lsnDrawPoint(if(member(nth(4 ep) list("LABEL" "INSTANCE")) then hintSet else hs)
            ep scale length(pts)<=lsnCfg('annotationLimit)))
        ; A sparse nearest-neighbor spanning tree: at most N-1 logical lines.
        ; Cap quadratic work; large nets use a linear-time star.
        prev=car(pts) remain=cdr(pts) edgeCount=0
        while(remain
          best=car(remain) bestD=nil
          when(length(pts)<=lsnCfg('chainLimit)
            foreach(ep remain
              dist=expt(xCoord(cadr(ep))-xCoord(cadr(prev)) 2)
                  +expt(yCoord(cadr(ep))-yCoord(cadr(prev)) 2)
              when(bestD==nil || dist<bestD bestD=dist best=ep)))
          geAddHilightLine(
            if(member(nth(4 prev) list("LABEL" "INSTANCE")) || member(nth(4 best) list("LABEL" "INSTANCE"))
              then hintLines else lineSet)
            list(cadr(prev) cadr(best)))
          edgeCount=edgeCount+1
          remain=remove(best remain)
          when(length(pts)<=lsnCfg('chainLimit) prev=best)
        )
        lsnState['edgeCount]=edgeCount
        when(lsnState['form]->lsnShowMetal->value
          let((metal shown)
            metal=lsnNewHilight("y2") shown=0
            foreach(net lsnState['layoutNets]
              foreach(fig net~>figs
                when(shown<lsnCfg('maxMetalExtents) && fig~>bBox
                  geAddHilightRectangle(metal lsnWindowBBox(fig~>bBox))
                  shown=shown+1)))
          ))
        lsnMessage(sprintf(nil "%d locations, %d logical lines. Lines do not prove routing continuity."
          length(pts) edgeCount))
        hiRedraw(lsnState['window])
      )
      else lsnMessage("No physical pin location for this signal. See unavailable entries.")
    )
  )
)

procedure(lsnChoose(name @optional (navigate t))
  let((record)
    record=lsnState['records][name]
    when(record
      lsnState['record]=record
      lsnState['index]=-1
      lsnClear()
      lsnCollect(record)
      lsnFillEndpoints()
      if(navigate then
        if(cadr(record)=="PORT" then
          if(lsnState['points] && rexMatchp("^PORT/" nth(6 car(lsnState['points]))) then lsnGo(0)
            else lsnMessage("Top-level port has no physical pin. Next pin visits attached instances."))
          else
          if(lsnState['form]->lsnMode->value=="Overview" then lsnOverview()
            else lsnMessage("Press Next pin to visit the first placed connection.")))
        else lsnMessage("Signal selected."))
    )
    when(record && isCallable('lsncSelect) lsncSelect())
    record
  )
)

procedure(lsnSignalCB(field rows)
  unless(lsnState['busy]
    when(rows
      lsnChoose(car(nth(car(rows) lsnState['form]->lsnSignals->choices)))
    )
  )
)

procedure(lsnEndpointCB(field rows)
  unless(lsnState['busy]
    when(rows
      let((row)
        row=nth(car(rows) lsnState['form]->lsnEndpoints->choices)
        if(car(row)>0 then lsnGo(car(row)-1)
          else lsnMessage(strcat(cadr(row) ": " nth(3 row))))
      )
    )
  )
)

procedure(lsnFilter()
  let((rows text kind record)
    text=lowerCase(lsnState['form]->lsnSearch->value)
    kind=lsnState['form]->lsnCategory->value
    foreach(name lsnState['names]
      record=lsnState['records][name]
      when((text=="" || index(lowerCase(name) text)) &&
           (kind=="All" || (kind=="Ports" && cadr(record)=="PORT") ||
            (kind=="Nets" && cadr(record)!="PORT"))
        rows=cons(list(name cadr(record) nth(3 record)) rows)))
    lsnState['busy]=t
    lsnState['form]->lsnSignals->choices=reverse(rows)
    lsnState['busy]=nil
    lsnMessage(sprintf(nil "%d signals shown. Select a name to navigate." length(rows)))
    rows
  )
)

procedure(lsnRefresh()
  when(lsnValid()
    let((cv source records names kind bound)
      cv=lsnState['cv]
      source=lsnResolveSource(cv)
      lsnState['source]=source lsnSourceIndex()
      when(isCallable('lsncInvalidate) lsncInvalidate())
      records=makeTable('lsnRecords nil)
      names=nil
      when(source
        foreach(net source~>nets
          kind=cond((net~>numBits>1 "BUS") (lsnState['sourcePorts][net~>name] || net~>term "PORT") (t "NET"))
          records[net~>name]=list(net~>name kind net "Source")
          names=cons(net~>name names)))
      foreach(net cv~>nets
        unless(records[net~>name]
          kind=if(net~>term then "PORT" else "NET")
          records[net~>name]=list(net~>name kind nil "Layout only")
          names=cons(net~>name names)))
      lsnState['source]=source
      lsnState['labelCache]=makeTable('lsnLabelCache nil)
      lsnState['records]=records
      lsnState['names]=sort(names 'alphalessp)
      lsnState['record]=nil
      lsnState['index]=-1
      lsnClear()
      lsnState['form]->lsnContext->value=sprintf(nil "Layout: %s / %s" cv~>libName cv~>cellName)
      lsnState['form]->lsnSource->value=if(source
        then sprintf(nil "Schematic: %s / %s" source~>libName source~>cellName)
        else "Schematic unavailable; using layout connectivity.")
      lsnState['form]->lsnEndpoints->choices=nil
      lsnState['form]->lsnCurrent->value="Select a signal"
      lsnFilter()
    )
  )
)

procedure(lsnBindCurrent()
  let((win)
    win=lsnFindWindow()
    if(win then
      lsnStart(win)
      else lsnMessage("Open a layout window first."))
  )
)

procedure(lsnFloat()
  let((screen x y)
    hiUndockWindow(lsnState['dock])
    screen=hiGetMaxScreenCoords()
    x=max(580 xCoord(screen)-15)
    y=max(650 yCoord(screen)-45)
    hiResizeWindow(lsnState['dock]
      list(list(max(0 x-800) max(0 y-960)) list(x y)))
    lsnState['floating]=t
  )
)

procedure(lsnToggleDock()
  if(lsnState['floating] then
    hiDockWindow(?window lsnState['dock]
      ?session hiGetSessionWindow(lsnState['window]) ?side 'right)
    lsnState['floating]=nil
    else lsnFloat())
)

procedure(lsnCreateForm()
  let((context source search category signals endpoints current status top controls viewControls buttons root widthRow connection details statistics)
    context=hiCreateLabel(?name 'lsnContext ?labelText "Layout")
    source=hiCreateLabel(?name 'lsnSource ?labelText "Schematic")
    search=hiCreateStringField(?name 'lsnSearch ?prompt "Find" ?value "" ?callback "lsnFilter()")
    category=hiCreateCyclicField(?name 'lsnCategory ?prompt "Show"
      ?choices list("All" "Pin" "Nets" "Pin Open" "Net Open" "Unverified")
      ?callback "lsnFilter()")
    statistics=hiCreateVerticalBoxLayout('lsnStatistics ?spacing 2 ?items list(
      hiCreateLabel(?name 'lsnStatsTitle ?labelText "STATISTICS -- all scalar signals")
      hiCreateStringField(?name 'lsnStatsPins ?prompt "Pin" ?value "" ?editable nil)
      hiCreateStringField(?name 'lsnStatsNets ?prompt "Nets" ?value "" ?editable nil)))
    signals=hiCreateReportField(?name 'lsnSignals ?title "SIGNALS -- click a column to sort"
      ?headers list(list("Name" 180 'left 'string t) list("Type" 55 'left 'string t)
                    list("Origin" 85 'left 'string t) list("Schematic I/O" 90 'left 'string t)
                    list("Connectivity / pending locations" 330 'left 'string t))
      ?choices nil ?selectMode 'single ?callback 'lsnSignalCB ?altRowHilight t)
    current=hiCreateLabel(?name 'lsnCurrent ?labelText "Select a signal")
    endpoints=hiCreateReportField(?name 'lsnEndpoints ?title "LOCATIONS -- core pins / labels / PAD targets"
      ?headers list(list("#" 30 'left 'int t) list("Connection" 180 'left 'string t)
                    list("Layer" 55 'left 'string t) list("Position basis" 170 'left 'string t)
                    list("I/O direction" 100 'left 'string t) list("Physical connection" 190 'left 'string t))
      ?choices nil ?selectMode 'single ?callback 'lsnEndpointCB ?altRowHilight t)
    status=hiCreateStringField(?name 'lsnStatus ?value "Ready" ?editable nil)
    top=hiCreateHorizontalBoxLayout('lsnFilterRow ?items list(list(search 'stretch 1) category
      hiCreateButton(?name 'lsnSearchButton ?buttonText "Filter" ?callback "lsnFilter()")))
    controls=hiCreateHorizontalBoxLayout('lsnStepRow ?items list(
      hiCreateButton(?name 'lsnPrev ?buttonText "< Previous" ?callback "lsnNext(-1)")
      hiCreateButton(?name 'lsnNext ?buttonText "Next pin >" ?callback "lsnNext(1)")
      hiCreateButton(?name 'lsnAll ?buttonText "Overview" ?callback "lsnOverview()")))
    details=hiCreateStringField(?name 'lsncDetails ?prompt "Connection" ?value "Select a signal" ?editable nil)
    connection=hiCreateHorizontalBoxLayout('lsncControls ?items list(
      hiCreateBooleanButton(?name 'lsnUnconnectedOnly ?buttonText "Unconnected / pending only" ?value nil ?callback "lsncToggle()")
      hiCreateButton(?name 'lsncCheck ?buttonText "Check selected" ?callback "lsncCheckCurrent()")
      hiCreateButton(?name 'lsncScan ?buttonText "Check list" ?callback "lsncScanList()")
      hiCreateButton(?name 'lsncStop ?buttonText "Stop" ?callback "lsncStopScan()")))
    viewControls=hiCreateHorizontalBoxLayout('lsnViewRow ?items list(
      hiCreateBooleanButton(?name 'lsnKeepZoom ?buttonText "Keep zoom" ?value nil)
      hiCreateCyclicField(?name 'lsnMode ?prompt "Net click" ?choices list("Step" "Overview"))))
    widthRow=hiCreateFloatField(?name 'lsnLocalWidth
      ?prompt sprintf(nil "Local width (%s)" lsnCfg('unitLabel))
      ?value lsnCfg('localViewWidth) ?range list(0.000001 1000000000.0))
    buttons=hiCreateHorizontalBoxLayout('lsnActionRow ?items list(
      hiCreateButton(?name 'lsnRefresh ?buttonText "Refresh" ?callback "lsnRefresh()")
      hiCreateButton(?name 'lsnBack ?buttonText "Back view" ?callback "lsnBack()")
      hiCreateButton(?name 'lsnClear ?buttonText "Clear" ?callback "lsnClear()")))
    root=hiCreateVerticalBoxLayout('lsnRoot ?margins list(8 8 8 8) ?spacing 5 ?items list(
      context source statistics top list(signals 'stretch 3) current details connection controls viewControls widthRow
      list(endpoints 'stretch 2)
      hiCreateBooleanButton(?name 'lsnShowMetal ?buttonText "Include metal extents in overview" ?value nil)
      hiCreateButton(?name 'lsnPadSetup ?buttonText "PAD setup / connection targets" ?callback "lsnPadSetup()")
      buttons
      hiCreateButton(?name 'lsnDockButton ?buttonText "Dock / Float" ?callback "lsnToggleDock()")
      hiCreateButton(?name 'lsnRebind ?buttonText "Bind current layout" ?callback "lsnBindCurrent()")
      status))
    hiCreateLayoutForm('lsnForm strcat("Signal Navigator " lsnVersion) root
      ?buttonLayout 'Empty ?initialSize list(800 930) ?minSize list(700 650))
    lsnState['form]=lsnForm
    lsnState['uiVersion]=lsnVersion
    lsnState['configDirty]=nil
    lsnForm
  )
)

procedure(lsnStart(@optional win (dock lsnCfg('dockByDefault)))
  let((session check cv)
    check=lsnCheckEnvironment()
    when(cadr(assoc('missingRequired check))
      error("Signal Navigator: required APIs are missing. See the compatibility guide.\n"))
    unless(win win=lsnFindWindow())
    when(win
      cv=car(errset(geGetEditCellView(win) nil))
      unless(cv && cv~>cellViewType=="maskLayout"
        error("Signal Navigator: the requested window is not a mask layout.\n")))
    if(win then
      when(isCallable('lsnpCloseSetup) && (lsnState['cv]!=cv || lsnState['window]!=win) lsnpCloseSetup())
      when(lsnState['form] && (lsnState['uiVersion]!=lsnVersion || lsnState['configDirty])
        lsnClear()
        when(windowp(lsnState['dock]) hiCloseWindow(lsnState['dock]))
        lsnState['dock]=nil lsnState['form]=nil)
      unless(lsnState['form] lsnCreateForm())
      lsnEnsurePalette()
      lsnClear()
      lsnState['window]=win
      lsnState['cv]=geGetEditCellView(win)
      lsnState['backBBox]=nil
      session=hiGetSessionWindow(win)
      when(lsnState['dock] && !windowp(lsnState['dock]) lsnState['dock]=nil)
      when(lsnState['dock] && hiGetSessionWindow(lsnState['dock])!=session
        hiCloseWindow(lsnState['dock])
        lsnState['dock]=nil)
      unless(lsnState['dock]
        lsnState['dock]=hiCreateDockWindow(?appType "LSNSignalNavigator"
          ?widgetType "form" ?handle 'lsnDock ?form lsnState['form]
          ?dockSizeHint list(800 930) ?minimumSizeHint list(700 650)
          ?title "Signal Navigator"))
      hiDockWindow(?window lsnState['dock] ?session session ?side 'right)
      lsnState['floating]=nil
      unless(dock lsnFloat())
      lsnRefresh()
      lsnState['dock]
      else
      printf("Signal Navigator: open a layout, then call lsnStart().\n")
      nil
    )
  )
)

procedure(lsnClose()
  when(isCallable('lsnpCloseSetup) lsnpCloseSetup())
  when(isCallable('lsncStopScan) lsncStopScan())
  lsnClear()
  when(windowp(lsnState['dock]) hiCloseWindow(lsnState['dock]))
  lsnState['dock]=nil lsnState['form]=nil
  lsnState['record]=nil lsnState['points]=nil lsnState['missing]=nil
  lsnState['window]=nil lsnState['cv]=nil
  lsnState['source]=nil lsnState['records]=nil lsnState['names]=nil
  lsnState['labelCache]=nil lsnState['layoutNets]=nil lsnState['backBBox]=nil
  t
)

procedure(lsnResetConfig()
  lsnClose()
  lsnConfig=makeTable('lsnConfig 'lsnUnset)
  lsnApplyDefaults()
  t
)

; Embedded schematic support.
; SPDX-License-Identifier: MIT
; Ordered source bus expansion and read-only hierarchical label landing lookup.
unless(boundp('lsnHintDepth) lsnHintDepth=32)

procedure(lsnNameMembers(name)
  let((result)
    when(isCallable('dbProduceMemName) result=errset(dbProduceMemName(name) nil))
    if(result && listp(car(result)) then car(result) else list(name))))

procedure(lsnSourceIndex()
  let((src nets terms direction count index name item)
    src=lsnState['source]
    lsnState['sourceEndpoints]=makeTable('lsnSourceEndpoints nil)
    lsnState['sourcePorts]=makeTable('lsnSourcePorts nil)
    lsnState['sourceNC]=makeTable('lsnSourceNC nil)
    when(src
      foreach(inst src~>instances
        foreach(sit inst~>instTerms
          nets=lsnNameMembers(sit~>net~>name)
          terms=lsnNameMembers(sit~>name)
          direction=sit~>term~>direction
          index=0
          foreach(name nets
            if(inst~>master~>libName=="basic" && inst~>master~>cellName=="noConn" then
              lsnState['sourceNC][name]=t
              else
              item=list(inst if(length(nets)==length(terms) then nth(index terms) else sit~>name)
                direction sit length(nets)==length(terms))
              lsnState['sourceEndpoints][name]=cons(item lsnState['sourceEndpoints][name]))
            index=index+1)))
      foreach(st src~>terminals
        nets=lsnNameMembers(st~>net~>name) terms=lsnNameMembers(st~>name) index=0
        foreach(name nets
          item=list(st if(length(nets)==length(terms) then nth(index terms) else st~>name)
            st~>direction length(nets)==length(terms))
          lsnState['sourcePorts][name]=cons(item lsnState['sourcePorts][name])
          index=index+1)))
    lsnState['indexedSource]=src))

procedure(lsnEnsureSourceIndex()
  unless(lsnState['sourceEndpoints] && lsnState['indexedSource]==lsnState['source] lsnSourceIndex()))

procedure(lsnDirectionLabel(direction)
  cond((direction=="input" "IN") (direction=="output" "OUT")
    (direction=="inputOutput" "INOUT") (t "?")))

procedure(lsnIoSummary(name)
  let((parts)
    lsnEnsureSourceIndex()
    foreach(item lsnState['sourcePorts][name]
      unless(member(lsnDirectionLabel(nth(2 item)) parts)
        parts=cons(lsnDirectionLabel(nth(2 item)) parts)))
    if(parts then buildString(reverse(parts) "/") else "Internal")))

procedure(lsnIsSchematicPin(record)
  ; Pin means top-level schematic I/O intended for later PAD connection.
  ; Include declared bus members/aggregates, independently of layout placement,
  ; physical pin figures, cached checks, or an instance terminal's direction.
  lsnEnsureSourceIndex()
  lsnState['sourcePorts][car(record)] ||
    exists(net lsnScalars(caddr(record)) net && lsnState['sourcePorts][net~>name]))

procedure(lsnEndpointIo(ep)
  if(nth(7 ep) then strcat(lsnDirectionLabel(nth(7 ep))
    if(nth(8 ep)=="schematic" then " (sch)" else " (layout)")) else "-"))

procedure(lsnSetEndpointInfo(prefix direction origin name)
  unless(lsnState['endpointInfo] lsnState['endpointInfo]=makeTable('lsnEndpointInfo nil))
  when(!lsnState['endpointInfo][prefix] || origin=="schematic"
    lsnState['endpointInfo][prefix]=list(direction origin name)))

procedure(lsnFindNamedTerm(cv name)
  let((term matches)
    term=dbFindTermByName(cv name)
    unless(term
      matches=setof(tm cv~>terminals lsnBusLabelKey(tm~>name)==lsnBusLabelKey(name))
      when(length(matches)==1 term=car(matches)))
    term))

; Return actual leaf figure and its transform into the queried master's frame.
; Unknown mosaic/array paths are refused rather than treated as element zero.
procedure(lsnHitGeometry(hit)
  let((cursor obj transform valid)
    cursor=hit transform=list(0:0 "R0" 1.0) valid=t
    while(listp(cursor) && valid
      obj=car(cursor)
      cond(
        (dbIsId(obj) && obj~>objType=="inst" && obj~>transform
          transform=dbConcatTransform(obj~>transform transform)
          cursor=car(last(cursor)))
        (dbIsId(obj) && member(obj~>objType list("stdVia" "customVia"))
          transform=dbConcatTransform(list(obj~>origin obj~>orient 1.0) transform)
          cursor=car(last(cursor)))
        (t valid=nil)))
    when(valid && dbIsId(cursor) &&
      member(cursor~>objType list("rect" "polygon" "path" "pathSeg"))
      list(cursor transform))))

procedure(lsnFindLanding(master point layer)
  let((radius queryLayer box result shape bb area best bestArea)
    radius=lsnCfg('labelProbeRadius)
    unless(radius radius=if(numberp(master~>DBUPerUU) && master~>DBUPerUU>0
      then 1.0/master~>DBUPerUU else 0.001))
    queryLayer=layer
    foreach(pair lsnCfg('labelLayerMap) when(car(pair)==queryLayer queryLayer=cadr(pair)))
    box=list(list(xCoord(point)-radius yCoord(point)-radius)
      list(xCoord(point)+radius yCoord(point)+radius))
    foreach(hit dbGetTrueOverlaps(master box list(queryLayer) lsnHintDepth t)
      result=lsnHitGeometry(hit)
      when(result
        shape=car(result)
        when(member(shape~>purpose list("drawing" "pin" "drawing2" "fill" "gapFill" "fillOPC"))
          bb=dbTransformBBox(shape~>bBox cadr(result))
          area=abs((xCoord(cadr(bb))-xCoord(car(bb)))*(yCoord(cadr(bb))-yCoord(car(bb))))
          when(bestArea==nil || area<bestArea
            bestArea=area best=list(queryLayer bb listp(hit) shape cadr(result))))))
    best))

procedure(lsnAddLabelHint(master termName transform prefix)
  let((count p bb landing localBox key label layer status)
    count=0
    when(lsnCfg('labelHints)
      foreach(fig lsnFindLabels(master termName)
        when(dbIsId(fig) && fig~>xy
          p=fig~>xy landing=lsnFindLanding(master p fig~>layerName)
          localBox=list(list(xCoord(p)-0.001 yCoord(p)-0.001) list(xCoord(p)+0.001 yCoord(p)+0.001))
          bb=if(landing then cadr(landing) else localBox)
          layer=if(landing then car(landing) else fig~>layerName)
          status=if(landing then if(caddr(landing) then "Label + hierarchical metal" else "Label + metal") else "Label anchor")
          when(transform bb=dbTransformBBox(bb transform) p=dbTransformPoint(p transform))
          bb=lsnWindowBBox(bb) p=geEditToWindowPoint(lsnState['window] p)
          count=count+1 key=sprintf(nil "hint:%s:%L" prefix p)
          unless(lsnState['seen][key]
            lsnState['seen][key]=t label=sprintf(nil "%s @label%d" prefix count)
            lsnState['points]=cons(list(label p bb layer "LABEL" status prefix) lsnState['points]))))
      when(count>0 lsnState['labelPrefixes][prefix]=t))
    count))

procedure(lsnCollectSourcePort(item netName)
  let((st name direction prefix count boundTerms term)
    st=car(item) name=cadr(item) direction=nth(2 item) prefix=strcat("PORT/" name) count=0
    lsnSetEndpointInfo(prefix direction "schematic" netName)
    if(!nth(3 item) then lsnRecordMissing(prefix "Source port/net width mismatch" "SOURCE_PORT" direction)
      else
      boundTerms=setof(bt lsnBound(st lsnState['cv]) bt~>objType=="term" && bt~>cellView==lsnState['cv] &&
        (lsnBusLabelKey(bt~>name)==lsnBusLabelKey(name) || length(lsnNameMembers(st~>name))==1))
      foreach(bt boundTerms count=count+lsnAddPinTerm(bt nil prefix "PORT"))
      unless(count>0
        term=lsnFindNamedTerm(lsnState['cv] name)
        when(term count=lsnAddPinTerm(term nil prefix "PORT")))
      unless(count>0 count=lsnAddLabelHint(lsnState['cv] name nil prefix))
      when(count==0
        lsnRecordMissing(prefix sprintf(nil "Schematic %s; layout I/O pin not placed" lsnDirectionLabel(direction)) "UNPLACED_IO" direction)))
    count))

procedure(lsnCollectSourceEndpoint(item netName)
  let((inst name direction sit prefix count iterms layoutInsts term)
    inst=car(item) name=cadr(item) direction=nth(2 item) sit=nth(3 item) count=0
    prefix=strcat(inst~>name "/" name)
    if(!nth(4 item) then lsnRecordMissing(prefix "Source bus pin/net width mismatch" "SOURCE_PIN" direction)
      else
      iterms=setof(o lsnBound(sit lsnState['cv]) o~>objType=="instTerm" && o~>cellView==lsnState['cv] &&
        lsnBusLabelKey(o~>name)==lsnBusLabelKey(name))
      foreach(it iterms
        prefix=strcat(it~>inst~>name "/" name)
        lsnSetEndpointInfo(prefix direction "schematic" netName)
        count=count+lsnAddPinTerm(it~>term it~>inst~>transform prefix "PIN"))
      unless(count>0
        layoutInsts=setof(o lsnBound(inst lsnState['cv]) o~>objType=="inst" && o~>cellView==lsnState['cv])
        foreach(it iterms unless(member(it~>inst layoutInsts) layoutInsts=cons(it~>inst layoutInsts)))
        foreach(li layoutInsts
          prefix=strcat(li~>name "/" name)
          lsnSetEndpointInfo(prefix direction "schematic" netName)
          term=lsnFindNamedTerm(li~>master name)
          when(term count=count+lsnAddPinTerm(term li~>transform prefix "PIN")))
        when(count==0
          foreach(li layoutInsts
            count=count+lsnAddInstanceHint(li name strcat(li~>name "/" name)))))
      when(count==0
        prefix=strcat(inst~>name "/" name)
        lsnRecordMissing(prefix if(layoutInsts || iterms then "No physical pin or label" else "No bound layout instance") "SOURCE_PIN" direction)))
    count))

printf("Schematic endpoint indexing and hierarchical landing support loaded.\n")

; Embedded navigation connectivity only; no prediction modules.
; SPDX-License-Identifier: MIT
; Physical navigation status only. Does not invoke routing/prediction workers.
; Native physical traces are temporary; only this module's trace IDs are removed.
unless(boundp('lsncState) lsncState=makeTable('lsncState nil))
lsncVersion="0.3.0"
unless(boundp('lsncStackLayers) lsncStackLayers=list("MET1" "MET6"))
unless(boundp('lsncStopLevel) lsncStopLevel=64)
unless(boundp('lsncMaxLocations) lsncMaxLocations=256)
unless(boundp('lsncMaxComponents) lsncMaxComponents=64)

procedure(lsncInvalidate()
  lsncState['cache]=makeTable('lsncCache nil)
  lsncState['stamp]=nil
  lsncState['generation]=if(lsncState['generation] then lsncState['generation]+1 else 1)
  lsncState['queue]=nil)

procedure(lsncStamp()
  ; Cache ownership depends on the bound design/configuration, not the changing
  ; inventory of open masters. Physical tracing may open many additional views.
  sprintf(nil "%L:%L:%L:%L:%L:%L:%L:%L" lsnState['window] lsnState['cv]
    lsnState['source] lsncStackLayers lsncStopLevel lsncMaxLocations
    lsncMaxComponents lsnHintDepth))

procedure(lsncCounters()
  let((pairs)
    foreach(cv dbGetOpenCellViews()
      when(cv==lsnState['cv] || (cv~>mode!="s" && cv~>mode!="S")
        pairs=cons(list(cv cv~>modifiedCounter) pairs)))
    pairs))

procedure(lsncUnchanged(pairs)
  !exists(pair pairs !dbIsId(car(pair)) || car(pair)~>modifiedCounter!=cadr(pair)))

procedure(lsncCounterMap()
  let((values)
    values=makeTable('lsncCounterValues nil)
    foreach(pair lsncCounters() values[car(pair)]=list(cadr(pair)))
    values))

procedure(lsncEntryCurrent(entry @optional values)
  when(entry && entry['counters] &&
    (!entry['padRequired] || entry['padSignature]==lsnpSignature(entry['recordName]))
    unless(values values=lsncCounterMap())
    !exists(pair entry['counters] !equal(values[car(pair)] list(cadr(pair))))))

procedure(lsncColumn(entry @optional values)
  if(!entry then "Not checked" else
    strcat(entry['column] if(lsncEntryCurrent(entry values) then "" else " [needs recheck]"))))

procedure(lsncMatchesFilter(record kind entry @optional values)
  cond(
    (kind=="All" t)
    (kind=="Pin" lsnIsSchematicPin(record))
    (kind=="Nets" !lsnIsSchematicPin(record))
    (kind=="Pin Open" lsncScalar(record) && lsnIsSchematicPin(record) && entry && member("Open" entry['tags]))
    (kind=="Net Open" lsncScalar(record) && !lsnIsSchematicPin(record) && entry && member("Open" entry['tags]))
    (kind=="Unverified" entry && member("Unverified" entry['tags]))
    (t nil)))

procedure(lsnStatisticsBucket()
  let((bucket)
    bucket=makeTable('lsnStatisticsBucket 0)
    foreach(key list('total 'connected 'open 'unverified 'pending) bucket[key]=0)
    bucket))

; Whole-layout scalar records only. Cached mixed Open/Unverified flags overlap.
; Stale, unchecked or single-location-only outcomes cannot count as completed.
; This path never starts a trace, changes selection or writes cache records.
procedure(lsnStatistics(@optional values)
  let((stats bucket record entry known)
    unless(values values=lsncCounterMap())
    stats=makeTable('lsnStatistics nil)
    stats['pins]=lsnStatisticsBucket() stats['nets]=lsnStatisticsBucket() stats['buses]=0
    foreach(name lsnState['names]
      record=lsnState['records][name]
      if(!lsncScalar(record) then stats['buses]=stats['buses]+1
        else
        bucket=if(lsnIsSchematicPin(record) then stats['pins] else stats['nets])
        bucket['total]=bucket['total]+1 entry=lsncEntry(name) known=nil
        when(lsncEntryCurrent(entry values)
          foreach(key list("Connected" "Open" "Unverified")
            when(member(key entry['tags])
              known=t
              cond(
                (key=="Connected" bucket['connected]=bucket['connected]+1)
                (key=="Open" bucket['open]=bucket['open]+1)
                (key=="Unverified" bucket['unverified]=bucket['unverified]+1)))))
        unless(known bucket['pending]=bucket['pending]+1)))
    stats))

procedure(lsnStatisticsText(bucket)
  sprintf(nil "Total %d | Connected %d (%.1f%%) | Open %d | Unverified %d | Pending %d"
    bucket['total] bucket['connected]
    if(bucket['total]>0 then 100.0*bucket['connected]/bucket['total] else 0.0)
    bucket['open] bucket['unverified] bucket['pending]))

procedure(lsnUpdateStatistics(@optional values)
  let((stats)
    stats=lsnStatistics(values)
    when(lsnState['form]
      lsnState['form]->lsnStatsPins->value=lsnStatisticsText(stats['pins])
      lsnState['form]->lsnStatsNets->value=lsnStatisticsText(stats['nets])
      lsnState['form]->lsnStatsTitle->value=sprintf(nil
        "STATISTICS -- all scalar signals | Bus groups: %d | Visible rows: %d"
        stats['buses] length(lsnState['form]->lsnSignals->choices)))
    stats))

procedure(lsncEnsureContext()
  let((stamp)
    stamp=lsncStamp()
    unless(lsncState['cache] && lsncState['stamp]==stamp
      when(lsncState['stamp] && lsncState['stamp]!=stamp
        lsncState['generation]=lsncState['generation]+1 lsncState['queue]=nil)
      lsncState['cache]=makeTable('lsncCache nil)
      lsncState['stamp]=stamp)
    stamp))

procedure(lsncEntry(@optional name)
  unless(name name=when(lsnState['record] car(lsnState['record])))
  when(name && lsncState['cache] lsncState['cache][name]))

procedure(lsncScalar(record)
  !(cadr(record)=="BUS" || (caddr(record) && caddr(record)~>numBits>1)))

procedure(lsncTraceCV(info)
  let((cv)
    foreach(item info when(dbIsId(item) && item~>objType=="cellView" cv=item))
    cv))

procedure(lsncHits(cv ep)
  when(cv && member(nth(4 ep) list("PIN" "PORT" "LABEL" "PAD")) && nth(3 ep)!="-"
    dbGetTrueOverlaps(cv list(cadr(ep) cadr(ep)) list(nth(3 ep)) 0 t)))

procedure(lsncSeed(ep)
  let((chosen h item path fig cursor valid)
    when(member(nth(4 ep) list("PIN" "PORT" "LABEL" "PAD"))
      foreach(hit dbGetTrueOverlaps(lsnState['cv] list(cadr(ep) cadr(ep)) list(nth(3 ep)) lsncStopLevel t)
        unless(chosen
          cursor=hit path=nil valid=t fig=nil
          while(listp(cursor) && valid && !fig
            item=car(cursor)
            cond(
              (dbIsId(item) && member(item~>objType list("stdVia" "customVia")) fig=item)
              (dbIsId(item) && item~>objType=="inst"
                path=cons(list(item 0 0 0) path) cursor=car(last(cursor)))
              (t valid=nil)))
          unless(fig when(dbIsId(cursor) fig=cursor))
          when(valid && fig && member(fig~>objType list("rect" "polygon" "path" "pathSeg" "ellipse" "donut" "arc" "stdVia" "customVia")) &&
            (member(fig~>objType list("stdVia" "customVia")) || member(fig~>purpose list("drawing" "pin" "drawing2" "fill" "gapFill" "fillOPC")))
            chosen=list(fig reverse(path))))))
    chosen))

procedure(lsncExistingAt(before ep)
  let((found info cv)
    foreach(id before
      info=lntGetTraceInfo(id) cv=lsncTraceCV(info)
      when(cv && lsncHits(cv ep) found=t))
    found))

procedure(lsncTraceGroup(seed ep points)
  let((before id result info cv hitIndices index beforeInfo)
    before=lntGetAllTraces(lsnState['cv])
    ; Native tracing reuses an existing trace at a point. Do not recolor or
    ; repurpose a user's possibly partial/stale trace as our own proof.
    when(lsncExistingAt(before ep) error("Existing user trace at endpoint; keep it unchanged.\n"))
    beforeInfo=foreach(mapcar tid before list(tid lntGetTraceInfo(tid)))
    unwindProtect(
      progn(
        id=lntAddTrace(lsnState['window] car(seed) ?mode "physical" ?hierPath cadr(seed)
          ?startLevel 0 ?stopLevel lsncStopLevel ?maxCutShapes "Full" ?hilightIncrementally nil
          ?retainColornStateInfo t ?hilightColor "blue" ?stackLayers lsncStackLayers)
        unless(id error("Physical trace could not be created.\n"))
        when(member(id before) error("Native tracer reused an existing trace; result left unverified.\n"))
        lntSetTraceVisibility(id 0 lsnState['window])
        info=lntGetTraceInfo(id) cv=lsncTraceCV(info)
        unless(cv error("Trace has no readable physical container.\n"))
        unless(lsncHits(cv ep) error("Trace did not cover its source location.\n"))
        index=0
        foreach(p points
          when(lsncHits(cv p) hitIndices=cons(index hitIndices))
          index=index+1)
        reverse(hitIndices))
      progn(
        when(id && !member(id before) errset(lntRemoveTrace(id lsnState['window]) nil))
        when(id && member(id before)
          info=cadr(assoc(id beforeInfo))
          ; Preserve the documented display properties if an unexpected reuse
          ; occurs after a source edit. No pre-existing trace is ever deleted.
          when(length(info)>=7 && fixp(car(info))
            errset(lntSetTraceColor(id nth(3 info) lsnState['window]) nil)
            errset(lntSetTraceVisibility(id if(nth(4 info) then 1 else 0) lsnState['window]) nil)))))))

; Pure classification also handles equally sized islands without arbitrarily
; declaring one of them complete. Entries are location rows, not bus bits.
procedure(lsncClassify(points missing groups reasons)
  let((entry sizes distinct maxSize main ties known i group states attention openNames unknownNames
       summary text unplaced otherMissing portNames complete)
    entry=makeTable('lsncEntry nil) sizes=makeTable('lsncSizes 0)
    unplaced=setof(m missing nth(2 m)=="UNPLACED_IO")
    otherMissing=setof(m missing nth(2 m)!="UNPLACED_IO")
    foreach(m unplaced
      portNames=cons(sprintf(nil "%s [%s; no layout coordinates]" car(m) lsnDirectionLabel(nth(3 m))) portNames))
    distinct=nil maxSize=0 known=0
    foreach(g groups
      when(g
        unless(member(g distinct) distinct=cons(g distinct))
        sizes[g]=sizes[g]+1 known=known+1 maxSize=max(maxSize sizes[g])))
    complete=length(distinct)==1 && known==length(points) && !otherMissing && known>=2
    ties=setof(g distinct sizes[g]==maxSize)
    when(length(ties)==1 && maxSize>=2 main=car(ties))
    states=nil attention=nil i=0 openNames=nil unknownNames=nil
    foreach(ep points
      group=nth(i groups)
      text=cond(
        (!group strcat("Unverified: " nth(i reasons) || "no physical trace"))
        (complete if(unplaced then "Connected internally" else "Connected"))
        (main && group==main sprintf(nil "Main island C%d" group))
        (length(distinct)>=2 && !main sprintf(nil "Bridge needed C%d" group))
        (length(distinct)>=2 sprintf(nil "Unconnected C%d" group))
        (t sprintf(nil "Reference C%d" group)))
      states=cons(text states)
      when(!group || (length(distinct)>=2 && (!main || group!=main)) || length(points)==1
        attention=cons(i attention)
        text=sprintf(nil "%s@(%.3f,%.3f)" car(ep) xCoord(cadr(ep))*1.0 yCoord(cadr(ep))*1.0)
        if(group then openNames=cons(text openNames) else unknownNames=cons(text unknownNames)))
      i=i+1)
    foreach(m otherMissing unknownNames=cons(strcat(car(m) " (no location)") unknownNames))
    summary=cond(
      (!points && unplaced && !otherMissing "I/O pin not placed")
      (!points "Unverified: no resolved locations")
      (complete && unplaced "Internal connected; I/O unplaced")
      (complete if(exists(ep points nth(4 ep)=="LABEL") then "Connected* (label endpoint)" else "Connected"))
      (length(distinct)>=2 sprintf(nil "Open: %d islands%s%s" length(distinct)
        if(unknownNames then " + unverified" else "") if(unplaced then " + I/O unplaced" else "")))
      (length(points)==1 && known==1 && unplaced && !otherMissing "One internal location; I/O unplaced")
      (length(points)==1 && !missing "Single location; no peer to check")
      (t "Unverified: unresolved physical endpoints"))
    entry['summary]=summary entry['states]=reverse(states) entry['attention]=reverse(attention)
    entry['groups]=groups entry['points]=points entry['missing]=missing entry['unplacedIO]=unplaced
    entry['reasons]=reasons
    ; Independent flags preserve mixed states: a net may be open AND contain
    ; an unverified endpoint or an unplaced I/O. The display text is not parsed.
    entry['tags]=nil
    when(length(distinct)>=2 entry['tags]=cons("Open" entry['tags]))
    when(complete && !unplaced entry['tags]=cons("Connected" entry['tags]))
    when(unplaced entry['tags]=cons("Pin not placed" entry['tags]))
    when(unknownNames || known<length(points) || (!points && !unplaced)
      entry['tags]=cons("Unverified" entry['tags]))
    when(exists(ep points member(nth(4 ep) list("PIN" "PORT")))
      entry['tags]=cons("Physical pin" entry['tags]))
    when(length(points)==1 entry['tags]=cons("Single location" entry['tags]))
    entry['details]=strcat(summary
      if(openNames then strcat(" | Pending: " buildString(reverse(openNames) "; ")) else "")
      if(portNames then strcat(" | Unplaced schematic I/O: " buildString(reverse(portNames) "; ")) else "")
      if(unknownNames then strcat(" | Unverified: " buildString(reverse(unknownNames) "; ")) else ""))
    entry['column]=entry['details]
    entry))

procedure(lsncAnalyze(record points missing)
  let((groups reasons entry i result seed group attempts n bus)
    n=length(points) groups=nil reasons=nil group=0 attempts=0
    when(n>0 for(k 1 n groups=cons(nil groups) reasons=cons("not checked" reasons)))
    bus=!lsncScalar(record)
    cond(
      (n==0 nil)
      (bus reasons=foreach(mapcar ep points "bus: choose an individual bit"))
      (n>lsncMaxLocations reasons=foreach(mapcar ep points "location limit; check a smaller net"))
      (geGetEditCellView(lsnState['window])!=geGetWindowCellView(lsnState['window])
        reasons=foreach(mapcar ep points "exit edit-in-place to check"))
      (!isCallable('lntAddTrace) || !isCallable('lntGetTraceInfo) || !isCallable('lntRemoveTrace)
        reasons=foreach(mapcar ep points "native physical tracer unavailable"))
      (t
        for(index 0 n-1
          unless(nth(index groups)
            cond(
              (attempts>=lsncMaxComponents rplaca(nthcdr(index reasons) "component limit"))
              (nth(4 nth(index points))=="INSTANCE" rplaca(nthcdr(index reasons) "block location only"))
              (t
                result=errset(lsncSeed(nth(index points)) nil)
                seed=when(result car(result))
                if(!seed then rplaca(nthcdr(index reasons) "no conductor at anchor")
                  else
                  attempts=attempts+1
                  result=errset(lsncTraceGroup(seed nth(index points) points) nil)
                  if(result && car(result) then
                    group=group+1
                    foreach(j car(result)
                      rplaca(nthcdr(j groups) group)
                      rplaca(nthcdr(j reasons) ""))
                    else rplaca(nthcdr(index reasons) "trace unavailable / existing user trace")))))))))
    entry=lsncClassify(points missing groups reasons)
    when(bus entry['summary]="Bus: check individual bits" entry['column]=entry['summary]
      entry['details]=entry['summary] entry['attention]=nil entry['tags]=list("Bus"))
    entry))

procedure(lsncCheckRecord(record @optional force)
  let((old keys result entry name before after points missing counters)
    name=car(record) lsncEnsureContext() entry=lsncEntry(name)
    unless(entry && !force && lsncEntryCurrent(entry)
      keys=list('record 'points 'missing 'seen 'pinPrefixes 'labelPrefixes 'missingSeen 'layoutNets 'index 'endpointInfo)
      old=foreach(mapcar key keys list(key lsnState[key]))
      lsncState['checking]=t
      unwindProtect(
        progn(
          lsnCollect(record) points=lsnState['points] missing=lsnState['missing]
          before=lsncStamp() counters=lsncCounters()
          lsnMessage(strcat("Checking physical metal/via connectivity: " name))
          result=errset(lsnpApplyPad(record lsncAnalyze(record points missing)) t)
          entry=if(result then car(result) else lsnpFailure(record points missing "native/PAD check failed"))
          unless(lsncUnchanged(counters)
            entry=lsnpFailure(record points missing "layout changed during check; recheck"))
          after=lsncStamp()
          if(before==after then
            ; Refresh only the requested record. Other checked results remain
            ; available even when their revision snapshots need a new check.
            entry['counters]=lsncCounters()
            lsncState['cache][name]=entry
            else
            entry=lsnpFailure(record points missing "layout context changed; recheck")
            lsncEnsureContext()))
        progn(foreach(pair old lsnState[car(pair)]=cadr(pair)) lsncState['checking]=nil)))
    entry))

procedure(lsncSelect()
  let((entry)
    when(lsnState['record] && !lsncState['checking]
      entry=lsncCheckRecord(lsnState['record])
      lsnCollect(lsnState['record]) lsnFillEndpoints() lsnFilter()
      lsnMessage(entry['summary]))))

procedure(lsncCheckCurrent()
  let((entry)
    if(lsnState['record] then
      entry=lsncCheckRecord(lsnState['record] t) lsnCollect(lsnState['record]) lsnFillEndpoints() lsnFilter()
      lsnMessage(entry['details])
      else lsnMessage("Select a signal first."))))

procedure(lsncToggle()
  when(lsnState['record]
    lsncCheckRecord(lsnState['record]) lsnFillEndpoints()
    lsnMessage(if(lsnState['form]->lsnUnconnectedOnly->value then
      "Next/Previous will visit only unconnected or unverified locations."
      else "Next/Previous will visit all locations."))))

procedure(lsnFilter()
  let((rows text kind record entry selected index values)
    lsncEnsureContext()
    values=lsncCounterMap()
    text=lowerCase(lsnState['form]->lsnSearch->value) kind=lsnState['form]->lsnCategory->value
    selected=when(lsnState['record] car(lsnState['record]))
    foreach(name lsnState['names]
      record=lsnState['records][name] entry=lsncEntry(name)
      when((text=="" || index(lowerCase(name) text)) &&
        lsncMatchesFilter(record kind entry values)
        rows=cons(list(name cadr(record) nth(3 record) lsnIoSummary(name) lsncColumn(entry values)) rows)))
    rows=reverse(rows) lsnState['busy]=t
    lsnState['form]->lsnSignals->choices=rows index=0
    foreach(row rows when(car(row)==selected hiReportSelectItem(lsnState['form]->lsnSignals index nil)) index=index+1)
    lsnState['busy]=nil lsnUpdateStatistics(values) rows))

procedure(lsnFillEndpoints()
  let((rows i entry status pins labels blocks values current pads unavailable)
    lsncEnsureContext()
    values=lsncCounterMap() entry=lsncEntry() current=lsncEntryCurrent(entry values) i=0
    foreach(ep lsnState['points]
      status=if(entry && equal(entry['points] lsnState['points]) then nth(i entry['states]) else "Not checked")
      when(entry && !current && status!="Not checked" status=strcat(status " [needs recheck]"))
      i=i+1 rows=cons(list(i car(ep) nth(3 ep) nth(5 ep) || "Physical pin" lsnEndpointIo(ep) status) rows))
    unavailable=0
    foreach(m lsnState['missing]
      unless(entry && entry['padRequired] && (nth(2 m)=="UNPLACED_IO" || lsnpPadPrefix(car(m)))
        rows=cons(list(0 car(m) "-" cadr(m) lsnDirectionLabel(nth(3 m)) "Unverified: no location") rows)
        unavailable=unavailable+1))
    when(entry && entry['padRequired]
      foreach(row entry['padRows] rows=cons(row rows) unavailable=unavailable+1))
    lsnState['busy]=t lsnState['form]->lsnEndpoints->choices=reverse(rows) lsnState['busy]=nil
    pins=length(setof(ep lsnState['points] member(nth(4 ep) list("PIN" "PORT"))))
    labels=length(setof(ep lsnState['points] nth(4 ep)=="LABEL"))
    blocks=length(setof(ep lsnState['points] nth(4 ep)=="INSTANCE"))
    pads=length(setof(ep lsnState['points] nth(4 ep)=="PAD"))
    lsnState['form]->lsnCurrent->value=sprintf(nil "%s | %d pin, %d label, %d block, %d PAD targets; %d unavailable"
      car(lsnState['record]) pins labels blocks pads unavailable)
    lsnState['form]->lsncDetails->value=lsncColumn(entry values)))

lsncBaseNext=getd('lsnNext)
procedure(lsnNext(delta)
  let((entry eligible chosen current)
    when(lsnState['record]
      entry=lsncCheckRecord(lsnState['record])
      lsnCollect(lsnState['record]) lsnFillEndpoints() lsnFilter()
      if(!lsnState['form]->lsnUnconnectedOnly->value then apply(lsncBaseNext list(delta))
        else
        eligible=entry['attention] current=lsnState['index]
        if(!eligible then lsnMessage("No unconnected locations to visit. See connection status / unavailable rows.")
          else
          if(delta>0 then
            chosen=car(setof(i eligible i>current))
            unless(chosen chosen=car(eligible))
            else
            chosen=car(last(setof(i eligible i<current)))
            unless(chosen chosen=car(last(eligible))))
          lsnGo(chosen))))))

procedure(lsncStopScan()
  lsncState['generation]=if(lsncState['generation] then lsncState['generation]+1 else 1)
  lsncState['queue]=nil
  lsnMessage("Connection-check queue stopped; completed statuses retained."))

procedure(lsncScanList()
  lsncStopScan()
  lsncState['queue]=foreach(mapcar row lsnState['form]->lsnSignals->choices car(row))
  hiRegTimer(sprintf(nil "lsncScanStep(%d)" lsncState['generation]) 1))

procedure(lsncScanStep(generation)
  let((name record)
    when(generation==lsncState['generation] && lsncState['queue] && lsnState['form] && lsnValid()
      name=car(lsncState['queue]) lsncState['queue]=cdr(lsncState['queue])
      record=lsnState['records][name]
      when(record lsncCheckRecord(record))
      when(lsnState['record] lsnFillEndpoints())
      lsnFilter()
      if(lsncState['queue] then
        lsnMessage(sprintf(nil "Physical check: %s; %d signals remaining." name length(lsncState['queue])))
        hiRegTimer(sprintf(nil "lsncScanStep(%d)" generation) 1)
        else lsnMessage("Visible signal list checked. Unverified results remain explicitly marked.")))))

; BEGIN PAD SUPPORT 0.3.4 -- read-only discovery, explicit binding and proof.
unless(boundp('lsnpState) lsnpState=makeTable('lsnpState nil))
unless(lsnpState['profiles] lsnpState['profiles]=makeTable('lsnpProfiles nil))
unless(lsnpState['bindings] lsnpState['bindings]=makeTable('lsnpBindings nil))
unless(lsnpState['revision] lsnpState['revision]=0)
lsnpState['inventory]=nil
unless(boundp('lsnpDedicatedPadLibraries)
  lsnpDedicatedPadLibraries=list("DBH_ANALOG_PAD" "DBH_1830AN18BA_AN18GPIO5V_ISO_MINI_75U"))
unless(boundp('lsnpMaxMasters) lsnpMaxMasters=20000)
unless(boundp('lsnpMaxEdges) lsnpMaxEdges=500000)
unless(boundp('lsnpMaxOccurrences) lsnpMaxOccurrences=10000)

procedure(lsnpProfile(cv)
  when(cv lsnpState['profiles][strcat(cv~>libName "/" cv~>cellName)]))

procedure(lsnPadRegisterProfile(lib cell roles)
  unless(stringp(lib) && stringp(cell) && roles &&
    !exists(role roles !listp(role) || length(role)<3 || !stringp(car(role)) ||
      !member(cadr(role) list("label" "bond")))
    error("PAD profile needs a library, cell and explicit terminal descriptors.\n"))
  unless(equal(lsnpState['profiles][strcat(lib "/" cell)] list(lib cell roles))
    lsnpState['profiles][strcat(lib "/" cell)]=list(lib cell roles)
    lsnpState['revision]=lsnpState['revision]+1 lsnpState['inventory]=nil)
  t)

unless(lsnpState['defaultsInstalled]
  lsnPadRegisterProfile("DBH_ANALOG_PAD" "IOPAD" list(list("IO" "bond" "BOND" "MET6")))
  lsnPadRegisterProfile("DBH_ANALOG_PAD" "VDDPAD" list(list("VDD" "bond" "BOND" "MET6")))
  lsnPadRegisterProfile("DBH_ANALOG_PAD" "GNDPAD" list(list("GND" "bond" "BOND" "MET6")))
  lsnPadRegisterProfile("DBH_1830AN18BA_AN18GPIO5V_ISO_MINI_75U" "PH18C0810_ISO_75"
    foreach(mapcar name list("I" "Z" "OEN" "IE" "DS") list(name "label" list(name))))
  lsnpState['defaultsInstalled]=t)

procedure(lsnpKnownPadLibrary(lib)
  member(lib lsnpDedicatedPadLibraries))

procedure(lsnpResolvePath(cv path)
  let((current transform inst valid)
    current=cv transform=list(0:0 "R0" 1.0) valid=t
    foreach(name path
      when(valid
        inst=dbFindAnyInstByName(current name)
        if(inst && inst~>objType=="inst" && inst~>master && inst~>transform then
          transform=dbConcatTransform(inst~>transform transform) current=inst~>master
          else valid=nil)))
    when(valid list(current transform inst))))

procedure(lsnpScope()
  let((win cv path result scope)
    scope=makeTable('lsnpScope nil)
    if(lsnpState['scope] && car(lsnpState['scope])==lsnState['cv] then
      win=cadr(lsnpState['scope]) path=caddr(lsnpState['scope])
      else win=lsnState['window] path=nil)
    scope['window]=win scope['path]=path
    when(windowp(win)
      result=errset(geGetEditCellView(win) nil) when(result cv=car(result)))
    if(!cv || geGetWindowCellView(win)!=cv then scope['error]="PAD scope window unavailable or edit-in-place"
      else
      result=lsnpResolvePath(cv path)
      if(!result || car(result)!=lsnState['cv] then scope['error]="PAD scope core occurrence does not match bound layout"
        else scope['cv]=cv scope['transform]=cadr(result)))
    scope))

procedure(lsnpScopeKey(@optional scope)
  unless(scope scope=lsnpScope())
  sprintf(nil "%L:%L:%L:%L:%L" lsnState['cv] scope['cv] scope['window] scope['path] scope['error]))

procedure(lsnpBindingKey(name @optional scope)
  strcat(lsnpScopeKey(scope) "::" name))

procedure(lsnpStartsWith(text prefix)
  stringp(text) && strlen(text)>=strlen(prefix) && substring(text 1 strlen(prefix))==prefix)

procedure(lsnpSignature(name)
  let((scope)
    scope=lsnpScope()
    sprintf(nil "%s:%d:%L" lsnpScopeKey(scope) lsnpState['revision]
      lsnpState['bindings][lsnpBindingKey(name scope)])))

procedure(lsnPadSetScope(win corePath)
  let((cv result)
    unless(windowp(win) && listp(corePath) && !exists(name corePath !stringp(name))
      error("Pass a layout window and an explicit list of core instance names.\n"))
    cv=geGetEditCellView(win) result=lsnpResolvePath(cv corePath)
    unless(cv==geGetWindowCellView(win) && result && car(result)==lsnState['cv]
      error("The scope must be a top-level layout window containing this exact core occurrence.\n"))
    lsnpState['scope]=if(cv==lsnState['cv] && !corePath then nil else list(lsnState['cv] win corePath))
    lsnpState['inventory]=nil
    t))

procedure(lsnPadUseScope(lib cell view corePath)
  let((win cv)
    foreach(w hiGetWindowList()
      cv=car(errset(geGetEditCellView(w) nil))
      when(cv && cv~>libName==lib && cv~>cellName==cell && cv~>viewName==view win=w))
    unless(win win=deOpenCellView(lib cell view "maskLayout" list(0:0 1500:1000) "r"))
    lsnPadSetScope(win corePath)))

procedure(lsnpInventory()
  let((scope key cached result root queue seen parents masters contains seeds arrays total cv profile
       child jobs job path transform inst items unknown complete counterPairs visits name)
    scope=lsnpScope() key=lsnpScopeKey(scope) cached=lsnpState['inventory]
    if(cached && cached['key]==key && lsncUnchanged(cached['counters]) then cached
      else
      result=makeTable('lsnpInventory nil) result['key]=key result['scope]=scope
      complete=t total=0 visits=0
      if(scope['error] then complete=nil unknown=list(scope['error])
        else
        root=scope['cv] queue=list(root) seen=makeTable('lsnpSeen nil)
        parents=makeTable('lsnpParents nil) contains=makeTable('lsnpContains nil)
        arrays=makeTable('lsnpArrays nil)
        while(queue && complete
          cv=car(queue) queue=cdr(queue)
          unless(seen[cv]
            seen[cv]=t masters=cons(cv masters) profile=lsnpProfile(cv)
            counterPairs=cons(list(cv cv~>modifiedCounter) counterPairs)
            cond(
              (length(masters)>lsnpMaxMasters complete=nil unknown=cons("PAD master scan limit" unknown))
              (profile || lsnpKnownPadLibrary(cv~>libName)
                contains[cv]=t seeds=cons(cv seeds))
              (t
                foreach(i cv~>instances
                  total=total+1 child=i~>master
                  if(total>lsnpMaxEdges || !child then
                    complete=nil unknown=cons("Unresolved hierarchy or PAD scan limit" unknown)
                    else
                    unless(member(cv parents[child]) parents[child]=cons(cv parents[child]))
                    unless(seen[child] queue=cons(child queue))))
                foreach(m cv~>mosaics
                  child=m~>master
                  if(dbIsId(child) then
                    arrays[cv]=cons(child arrays[cv])
                    unless(member(cv parents[child]) parents[child]=cons(cv parents[child]))
                    unless(seen[child] queue=cons(child queue))
                    else complete=nil unknown=cons("Unreadable array master in PAD scope" unknown)))))))
        ; Reverse propagation avoids expanding every standard-cell occurrence.
        while(seeds
          cv=car(seeds) seeds=cdr(seeds)
          foreach(parent parents[cv]
            unless(contains[parent] contains[parent]=t seeds=cons(parent seeds))))
        jobs=list(list(root list(0:0 "R0" 1.0) nil 0))
        while(jobs
          job=car(jobs) jobs=cdr(jobs) cv=car(job) transform=cadr(job) path=caddr(job)
          foreach(mc arrays[cv]
            when(contains[mc] complete=nil unknown=cons("PAD array occurrence requires explicit supported geometry" unknown)))
          foreach(i cv~>instances
            child=i~>master
            when(child && contains[child]
              visits=visits+1
              if(visits>lsnpMaxOccurrences || nth(3 job)>=32 || !i~>transform then
                complete=nil unknown=cons("PAD occurrence limit or unsupported transform" unknown)
                else
                name=append(path list(i~>name)) profile=lsnpProfile(child)
                if(profile then
                  items=cons(list(name child dbConcatTransform(i~>transform transform) i profile) items)
                  else
                  if(lsnpKnownPadLibrary(child~>libName) then
                    complete=nil unknown=cons(strcat("Unsupported PAD cell: " child~>libName "/" child~>cellName) unknown)
                    else jobs=cons(list(child dbConcatTransform(i~>transform transform) name nth(3 job)+1) jobs))))))))
      result['items]=sort(items lambda((a b) alphalessp(buildString(car(a) "/") buildString(car(b) "/"))))
      result['complete]=complete result['unknown]=unknown result['counters]=counterPairs
      result['masters]=length(masters) result['edges]=total
      lsnpState['inventory]=result
      result)))

procedure(lsnpPadPrefix(prefix)
  let((name inst source)
    name=car(parseString(prefix "/"))
    inst=when(name dbFindAnyInstByName(lsnState['cv] name))
    source=lsnState['source]
    unless(inst when(source && name inst=dbFindAnyInstByName(source name)))
    inst && (lsnpProfile(inst~>master) || lsnpKnownPadLibrary(inst~>master~>libName))))

procedure(lsnpCorePoints(points)
  setof(ep points nth(4 ep)!="PAD" && !lsnpPadPrefix(nth(6 ep))))

procedure(lsnpCoreMissing(missing)
  setof(m missing nth(2 m)!="UNPLACED_IO" && !lsnpPadPrefix(car(m))))

procedure(lsnpPadPoint(name point box layer status win)
  list(name geEditToWindowPoint(win point)
    list(geEditToWindowPoint(win car(box)) geEditToWindowPoint(win cadr(box)))
    layer "PAD" status name nil "pad" nil win))

procedure(lsnpInteriorPoint(master landing fallback)
  let((point valid hit)
    point=lsnCenter(cadr(landing))
    foreach(raw dbGetTrueOverlaps(master list(point point) list(car(landing)) lsnHintDepth t)
      hit=lsnHitGeometry(raw)
      when(hit && car(hit)==nth(3 landing) valid=t))
    if(valid then point else fallback)))

procedure(lsnpTarget(spec inventory)
  let((target scope resolved master transform profile role descriptor term points name localPoint box landing hitInfo)
    target=makeTable('lsnpTarget nil) scope=inventory['scope]
    target['spec]=spec target['path]=car(spec) target['role]=cadr(spec)
    name=strcat("PAD/" buildString(car(spec) "/") "/" cadr(spec)) target['name]=name
    resolved=when(scope['cv] lsnpResolvePath(scope['cv] car(spec)))
    if(!resolved || !car(spec) then target['error]="PAD instance path not found in this scope"
      else
      master=car(resolved) transform=cadr(resolved) profile=lsnpProfile(master)
      descriptor=when(profile assoc(cadr(spec) nth(2 profile)))
      if(!descriptor then target['error]="Unrecognized PAD or forbidden core terminal"
        else
        term=lsnFindNamedTerm(master cadr(spec))
        when(term
          foreach(pin term~>pins
            foreach(f pin~>figs
              when(f~>bBox && member(f~>objType list("rect" "polygon" "path" "pathSeg"))
                box=dbTransformBBox(f~>bBox transform) localPoint=lsnCenter(box)
                points=cons(lsnpPadPoint(name localPoint box f~>layerName "PAD terminal figure" scope['window]) points)))))
        unless(points
          if(cadr(descriptor)=="label" then
            foreach(labelName nth(2 descriptor)
              foreach(f lsnFindLabels(master labelName)
                when(f~>xy
                  landing=lsnFindLanding(master f~>xy f~>layerName)
                  when(landing
                    box=dbTransformBBox(cadr(landing) transform)
                    localPoint=dbTransformPoint(lsnpInteriorPoint(master landing f~>xy) transform)
                    points=cons(lsnpPadPoint(name localPoint box car(landing) "PAD core label + metal" scope['window]) points)))))
            else
            foreach(hit dbGetTrueOverlaps(master master~>bBox list(nth(2 descriptor) "drawing") lsnHintDepth t)
              hitInfo=lsnHitGeometry(hit)
              when(hitInfo
                box=dbTransformBBox(car(hitInfo)~>bBox cadr(hitInfo)) localPoint=lsnCenter(box)
                landing=lsnFindLanding(master localPoint nth(3 descriptor))
                when(landing
                  box=dbTransformBBox(cadr(landing) transform) localPoint=dbTransformPoint(localPoint transform)
                  points=cons(lsnpPadPoint(name localPoint box car(landing) "PAD bond metal contact" scope['window]) points))))))
        target['points]=reverse(points)
        unless(points target['error]="PAD core terminal has no supported physical landing")))
    target))

procedure(lsnPadBind(netName path role)
  let((scope inventory target specs key)
    unless(lsnState['records][netName] && lsnIsSchematicPin(lsnState['records][netName]) &&
      lsncScalar(lsnState['records][netName]) && path && listp(path) &&
      !exists(name path !stringp(name)) && stringp(role)
      error("Bind one scalar schematic Pin to an explicit PAD instance path and core terminal.\n"))
    inventory=lsnpInventory() scope=inventory['scope]
    target=lsnpTarget(list(path role) inventory)
    when(target['error] error("%s: %s\n" target['name] target['error]))
    key=lsnpBindingKey(netName scope)
    foreach(other lsnpState['bindings]
      when(other!=key && lsnpStartsWith(other strcat(lsnpScopeKey(scope) "::")) &&
        member(list(path role) lsnpState['bindings][other])
        error("This PAD core terminal is already explicitly assigned to another net.\n")))
    foreach(otherName lsnState['names]
      when(otherName!=netName && lsnIsSchematicPin(lsnState['records][otherName]) &&
        lsncScalar(lsnState['records][otherName]) &&
        member(list(path role) lsnpAutomaticSpecs(lsnState['records][otherName] inventory))
        error("This PAD core terminal is logically bound to another schematic Pin.\n")))
    specs=lsnpState['bindings][key]
    unless(member(list(path role) specs) lsnpState['bindings][key]=append(specs list(list(path role))))
    t))

procedure(lsnPadUnbind(netName path role)
  let((key)
    key=lsnpBindingKey(netName)
    lsnpState['bindings][key]=setof(spec lsnpState['bindings][key] !equal(spec list(path role)))
    t))

procedure(lsnpAutomaticSpecs(record inventory)
  let((scope specs name role profile sit resolved inst transformed nets lnets)
    scope=inventory['scope] name=car(record)
    lnets=lsnLayoutNets(caddr(record) name)
    foreach(item inventory['items]
      profile=nth(4 item) inst=nth(3 item)
      ; Actual layout net IDs are accepted, never merely a matching label name.
      foreach(it inst~>instTerms
        when(assoc(it~>name nth(2 profile)) && member(it~>net lnets) &&
          scope['cv]==lsnState['cv]
          unless(member(list(car(item) it~>name) specs) specs=cons(list(car(item) it~>name) specs)))))
    ; Source binding supplies intent for imported PADs without layout terms.
    foreach(item lsnState['sourceEndpoints][name]
      sit=nth(3 item) role=cadr(item) profile=lsnpProfile(car(item)~>master)
      when(profile && assoc(role nth(2 profile)) && nth(4 item)
        foreach(li lsnBound(car(item) lsnState['cv])
          when(li~>objType=="inst" && lsnpProfile(li~>master)
            foreach(pad inventory['items]
              when(nth(3 pad)==li
                unless(member(list(car(pad) role) specs) specs=cons(list(car(pad) role) specs))))))))
    reverse(specs)))

procedure(lsnpCoreToScope(ep scope)
  let((point box)
    point=dbTransformPoint(cadr(ep) scope['transform]) box=dbTransformBBox(nth(2 ep) scope['transform])
    append(list(car(ep) geEditToWindowPoint(scope['window] point)
      list(geEditToWindowPoint(scope['window] car(box)) geEditToWindowPoint(scope['window] cadr(box)))) nthcdr(3 ep))))

procedure(lsnpFailure(record points missing reason)
  let((entry)
    entry=lsncClassify(points missing foreach(mapcar ep points nil) foreach(mapcar ep points reason))
    when(lsnIsSchematicPin(record)
      entry['padRequired]=t entry['recordName]=car(record) entry['padSignature]=lsnpSignature(car(record))
      entry['corePoints]=points entry['padNavigation]=nil entry['padTargets]=nil
      entry['padStatus]="unverified" entry['padReason]=reason
      entry['padRows]=list(list(0 strcat("PAD/" car(record)) "-" reason "-" "PAD unverified"))
      entry['summary]=strcat("Internal unverified | PAD unverified: " reason)
      entry['column]=entry['summary] entry['details]=entry['summary])
    entry))

procedure(lsnpApplyPad(record internal)
  let((entry inventory scope specs explicit automatic targets combined joint oldWindow oldCV result
       corePoints coreMissing groups coreGroups known distinct coreComplete coreUnknown internalSummary
       n offset i target indices group connected unknown representative nav navStates padAll padUnknown
       padReason padStatus reasons attention missingRows labelAssumption)
    entry=internal
    when(lsnIsSchematicPin(record) && lsncScalar(record)
      corePoints=lsnpCorePoints(internal['points]) coreMissing=lsnpCoreMissing(internal['missing])
      inventory=lsnpInventory() scope=inventory['scope]
      specs=lsnpState['bindings][lsnpBindingKey(car(record) scope)] explicit=specs!=nil
      automatic=lsnpAutomaticSpecs(record inventory)
      foreach(spec automatic unless(member(spec specs) specs=append(specs list(spec))))
      targets=foreach(mapcar spec specs lsnpTarget(spec inventory))
      n=length(corePoints) offset=n
      combined=if(scope['cv] then foreach(mapcar ep corePoints lsnpCoreToScope(ep scope)) else nil)
      foreach(target targets
        indices=nil
        foreach(ep target['points] indices=cons(offset indices) offset=offset+1)
        target['indices]=reverse(indices) combined=append(combined target['points]))
      groups=internal['groups] reasons=internal['reasons]
      when(targets && scope['cv] && combined
        oldWindow=lsnState['window] oldCV=lsnState['cv]
        unwindProtect(
          progn(
            lsnState['window]=scope['window] lsnState['cv]=scope['cv]
            result=errset(lsncAnalyze(list(car(record) "NET" nil "PAD scope") combined nil) t))
          progn(lsnState['window]=oldWindow lsnState['cv]=oldCV))
        joint=when(result car(result))
        if(joint then groups=joint['groups] reasons=joint['reasons]
          else groups=foreach(mapcar ep combined nil) reasons=foreach(mapcar ep combined "PAD scope trace failed")))
      coreGroups=nil known=0 distinct=nil
      when(n>0
        for(k 0 n-1
          group=nth(k groups) coreGroups=cons(group coreGroups)
          when(group known=known+1 unless(member(group distinct) distinct=cons(group distinct)))))
      coreGroups=reverse(coreGroups)
      coreComplete=n>0 && known==n && length(distinct)==1 && !coreMissing
      coreUnknown=known<n || coreMissing || n==0
      internalSummary=cond((coreUnknown "Internal unverified") (coreComplete "Internal connected")
        (t sprintf(nil "Internal open: %d islands" length(distinct))))
      entry=lsncClassify(corePoints coreMissing coreGroups
        foreach(mapcar ep corePoints "physical endpoint unverified"))
      nav=nil navStates=nil attention=entry['attention] padAll=targets!=nil padUnknown=nil missingRows=nil
      foreach(target targets
        connected=nil unknown=nil representative=nil
        target['proofGroups]=foreach(mapcar index target['indices] nth(index groups))
        target['proofReasons]=foreach(mapcar index target['indices] nth(index reasons))
        foreach(index target['indices]
          group=nth(index groups)
          when(!group unknown=t)
          when(group && member(group distinct) connected=t representative=nth(index combined)))
        unless(representative representative=car(target['points]))
        target['connected]=connected
        target['status]=cond((connected "connected") (target['error] || unknown "unverified") (t "unconnected"))
        when(!connected && unknown && !target['error]
          target['error]=buildString(setof(why target['proofReasons] stringp(why) && why!="") "; "))
        unless(connected padAll=nil)
        when(target['status]=="unverified" padUnknown=t)
        if(representative then
          unless(connected attention=append(attention list(n+length(nav))))
          nav=append(nav list(representative))
          navStates=append(navStates list(strcat("PAD " target['status] ": " target['role])))
          else missingRows=cons(list(0 target['name] "-" target['error] "-" "PAD unverified") missingRows)))
      when(!explicit && !inventory['complete] padAll=nil padUnknown=t)
      padStatus=cond(
        (scope['error] "unverified")
        (!targets && !inventory['complete] "unverified")
        (!targets && !inventory['items] "pending")
        (!targets "unassigned")
        (padAll "connected")
        (padUnknown "unverified")
        (t "unconnected"))
      padReason=cond(
        (scope['error] scope['error])
        (!inventory['complete] && !explicit buildString(inventory['unknown] "; "))
        (padStatus=="pending" "no supported PAD in this scope")
        (padStatus=="unassigned" "select the correct PAD core terminal in PAD setup")
        (targets buildString(foreach(mapcar target targets
          strcat(buildString(target['path] "/") "/" target['role] ": " target['status]
            if(target['error] then strcat(" (" target['error] ")") else ""))) "; "))
        (t "PAD mapping or physical proof unavailable"))
      unless(targets missingRows=list(list(0 strcat("PAD/" car(record)) "-" padReason "-" strcat("PAD " padStatus))))
      unless(padAll
        when(corePoints
          i=0 representative=nil
          foreach(ep corePoints when(rexMatchp("^PORT/" nth(6 ep)) && !representative representative=i) i=i+1)
          representative=representative || 0
          unless(member(representative attention) attention=cons(representative attention))))
      attention=sort(attention 'lessp)
      when(coreComplete && padAll attention=nil)
      entry['padRequired]=t entry['recordName]=car(record) entry['padSignature]=lsnpSignature(car(record))
      entry['corePoints]=corePoints entry['coreGroups]=coreGroups entry['internalComplete]=coreComplete
      entry['internalSummary]=internalSummary entry['padTargets]=targets entry['padNavigation]=nav
      entry['padRows]=reverse(missingRows) entry['padStatus]=padStatus entry['padReason]=padReason
      entry['padBindingMode]=if(explicit then
        if(automatic then "explicit + source/layout binding" else "explicit") else "source/layout binding")
      entry['points]=append(corePoints nav)
      entry['states]=append(foreach(mapcar state entry['states]
        if(state=="Connected" then "Internal connected" else state)) navStates)
      entry['attention]=attention entry['groups]=coreGroups
      entry['tags]=remove("Connected" remove("Pin not placed" remove("Single location" entry['tags])))
      when(padStatus=="pending" || padStatus=="unconnected" unless(member("Open" entry['tags]) entry['tags]=cons("Open" entry['tags])))
      when(member(padStatus list("unassigned" "unverified")) unless(member("Unverified" entry['tags]) entry['tags]=cons("Unverified" entry['tags])))
      when(length(entry['points])==1 entry['tags]=cons("Single location" entry['tags]))
      labelAssumption=exists(ep corePoints nth(4 ep)=="LABEL") || exists(ep nav nth(5 ep)!="PAD terminal figure")
      entry['summary]=if(coreComplete && padAll then
        entry['tags]=remove("Open" remove("Unverified" entry['tags]))
        entry['tags]=cons("Connected" entry['tags])
        if(labelAssumption then "Connected* (including PAD; inferred landing)" else "Connected (including PAD)")
        else strcat(internalSummary " | PAD " padStatus))
      entry['details]=strcat(entry['summary] " | " padReason)
      entry['column]=entry['details])
    entry))

procedure(lsnpAppendNavigation(record points)
  let((core entry)
    core=lsnpCorePoints(points)
    entry=when(isCallable('lsncEntry) lsncEntry(car(record)))
    if(!lsncState['checking] && entry && entry['padRequired] && equal(core entry['corePoints])
      then append(core entry['padNavigation]) else core)))

procedure(lsnpEndpointWindow(ep)
  if(nth(4 ep)=="PAD" && windowp(nth(10 ep)) then nth(10 ep) else lsnState['window]))

procedure(lsnPadSaveConfig(path)
  let((out scope cv key prefix)
    unless(stringp(path) && substring(path 1 1)=="/" && !isFile(path)
      error("Use a NEW absolute Linux filename for the PAD configuration.\n"))
    scope=lsnpScope() cv=scope['cv]
    when(scope['error] error("Fix the PAD scope before saving configuration.\n"))
    out=outfile(path)
    unless(out error("Cannot write PAD configuration.\n"))
    unwindProtect(
      progn(
        fprintf(out "; Signal Navigator PAD configuration. Load after binding the intended core.\n")
        fprintf(out "lsnpDedicatedPadLibraries='%L\n" lsnpDedicatedPadLibraries)
        foreach(key lsnpState['profiles]
          fprintf(out "lsnPadRegisterProfile(%L %L '%L)\n" car(lsnpState['profiles][key])
            cadr(lsnpState['profiles][key]) nth(2 lsnpState['profiles][key])))
        fprintf(out "lsnPadUseScope(%L %L %L '%L)\n" cv~>libName cv~>cellName cv~>viewName scope['path])
        prefix=strcat(lsnpScopeKey(scope) "::")
        foreach(key lsnpState['bindings]
          when(lsnpStartsWith(key prefix)
            foreach(spec lsnpState['bindings][key]
              fprintf(out "lsnPadBind(%L '%L %L)\n" substring(key strlen(prefix)+1) car(spec) cadr(spec))))))
      close(out))
    t))

procedure(lsnpUiMessage(text)
  when(lsnpState['form] lsnpState['form]->lsnpStatus->value=text)
  lsnMessage(text))

procedure(lsnpUiRefresh()
  let((inventory scope cv items rows bindings specs manual)
    inventory=lsnpInventory() scope=inventory['scope] cv=scope['cv]
    lsnpState['selectedPad]=nil lsnpState['selectedBinding]=nil
    items=inventory['items] lsnpState['uiItems]=items
    foreach(item items
      rows=cons(list(buildString(car(item) "/") strcat(cadr(item)~>libName "/" cadr(item)~>cellName)
        buildString(foreach(mapcar role nth(2 nth(4 item)) car(role)) ", ")) rows))
    lsnpState['uiBusy]=t
    lsnpState['form]->lsnpPads->choices=reverse(rows)
    lsnpState['form]->lsnpRole->choices=list("-- select PAD --")
    manual=lsnpState['bindings][lsnpBindingKey(lsnpState['mappingNet] scope)] specs=manual
    foreach(spec lsnpAutomaticSpecs(lsnState['records][lsnpState['mappingNet]] inventory)
      unless(member(spec specs) specs=append(specs list(spec))))
    foreach(spec specs bindings=cons(list(buildString(car(spec) "/") cadr(spec)
      if(member(spec manual) then "Explicit" else "Source/layout binding")) bindings))
    lsnpState['form]->lsnpBindings->choices=reverse(bindings)
    lsnpState['uiBusy]=nil
    lsnpUiMessage(sprintf(nil "%d supported PAD instances; scan %s. %s" length(items)
      if(inventory['complete] then "complete" else "incomplete")
      if(inventory['unknown] then buildString(inventory['unknown] "; ") else "Assign the correct core terminal; external digital PAD is not a core terminal.")))))

procedure(lsnpPadCB(field rows)
  let((row item roles)
    when(rows && !lsnpState['uiBusy]
      row=nth(car(rows) field->choices)
      item=car(setof(p lsnpState['uiItems] buildString(car(p) "/")==car(row)))
      when(item
        lsnpState['selectedPad]=car(item)
        roles=foreach(mapcar role nth(2 nth(4 item)) car(role))
        lsnpState['form]->lsnpRole->choices=roles lsnpState['form]->lsnpRole->value=car(roles)))))

procedure(lsnpBindingCB(field rows)
  let((row specs)
    when(rows && !lsnpState['uiBusy]
      row=nth(car(rows) field->choices)
      specs=lsnpState['bindings][lsnpBindingKey(lsnpState['mappingNet])]
      lsnpState['selectedBinding]=car(setof(spec specs buildString(car(spec) "/")==car(row) && cadr(spec)==cadr(row))))))

procedure(lsnpUiRecheck()
  when(lsnState['records] && lsnState['records][lsnpState['mappingNet]]
    if(lsnState['record] && car(lsnState['record])==lsnpState['mappingNet] then lsncCheckCurrent()
      else lsnChoose(lsnpState['mappingNet] nil))))

procedure(lsnpCloseSetup()
  when(lsnpState['form] hiFormCancel(lsnpState['form]))
  lsnpState['form]=nil lsnpState['selectedPad]=nil lsnpState['selectedBinding]=nil)

procedure(lsnpUiAdd()
  let((result)
    if(!lsnpState['selectedPad] then lsnpUiMessage("Select a PAD instance first.")
      else
      result=errset(lsnPadBind(lsnpState['mappingNet] lsnpState['selectedPad] lsnpState['form]->lsnpRole->value) t)
      if(result then lsnpUiRefresh() lsnpUiRecheck()
        else lsnpUiMessage("PAD assignment failed: check terminal choice and conflicting assignments (details in CIW).")))))

procedure(lsnpUiRemove()
  let((spec)
    spec=lsnpState['selectedBinding]
    if(spec then
      lsnPadUnbind(lsnpState['mappingNet] car(spec) cadr(spec)) lsnpUiRefresh() lsnpUiRecheck()
      else lsnpUiMessage("Select an explicit mapping row to remove."))))

procedure(lsnpUiScope()
  let((result)
    result=errset(lsnPadUseScope(lsnpState['form]->lsnpLib->value lsnpState['form]->lsnpCell->value
      lsnpState['form]->lsnpView->value parseString(lsnpState['form]->lsnpCorePath->value "/")) t)
    if(result then lsnpUiRefresh() lsnpUiRecheck()
      else lsnpUiMessage("Scope must contain the currently bound core at the exact instance path."))))

procedure(lsnpUiLocate()
  let((target ep win hs span)
    when(lsnpState['selectedPad]
      target=lsnpTarget(list(lsnpState['selectedPad] lsnpState['form]->lsnpRole->value) lsnpInventory())
      ep=car(target['points])
      if(!ep then lsnpUiMessage(target['error])
        else
        win=lsnpEndpointWindow(ep) span=lsnState['form]->lsnLocalWidth->value/2.0
        lsnSaveView(win) lsnClear()
        hiZoomIn(win list(list(xCoord(cadr(ep))-span yCoord(cadr(ep))-span)
          list(xCoord(cadr(ep))+span yCoord(cadr(ep))+span)))
        hs=lsnNewHilight("candidate" win)
        lsnDrawPoint(hs ep span/25.0 t win) geAddHilightRectangle(hs nth(2 ep)) hiRedraw(win)))))

procedure(lsnpUiSave()
  if(errset(lsnPadSaveConfig(lsnpState['form]->lsnpFile->value) t)
    then lsnpUiMessage("PAD configuration saved. It does not save the layout.")
    else lsnpUiMessage("Could not save. Use a new absolute Linux filename; existing files are not overwritten.")))

procedure(lsnpUiLoad()
  if(errset(load(lsnpState['form]->lsnpFile->value) t)
    then lsnpUiRefresh() lsnpUiRecheck()
    else lsnpUiMessage("Could not load the local PAD configuration; see CIW.")))

procedure(lsnPadSetup()
  let((scope cv fields header scopeBox lists roleRow fileRow buttons root)
    if(!lsnState['record] || !lsnIsSchematicPin(lsnState['record]) || !lsncScalar(lsnState['record]) then
      lsnMessage("Select one scalar schematic Pin first (not a bus aggregate).")
      else
      lsnpState['mappingNet]=car(lsnState['record]) scope=lsnpScope() cv=scope['cv] || lsnState['cv]
      unless(lsnpState['form]
        header=hiCreateStringField(?name 'lsnpNet ?prompt "Schematic Pin" ?editable nil ?value "")
        scopeBox=hiCreateVerticalBoxLayout('lsnpScopeBox ?items list(
          hiCreateStringField(?name 'lsnpLib ?prompt "PAD scope library" ?value "")
          hiCreateStringField(?name 'lsnpCell ?prompt "PAD scope cell" ?value "")
          hiCreateStringField(?name 'lsnpView ?prompt "PAD scope view" ?value "layout")
          hiCreateStringField(?name 'lsnpCorePath ?prompt "Core instance path" ?value "")
          hiCreateButton(?name 'lsnpApplyScope ?buttonText "Apply scope (read-only)" ?callback "lsnpUiScope()")))
        lists=hiCreateReportField(?name 'lsnpPads ?title "Recognized PAD instances"
          ?headers list(list("Instance path" 240 'left 'string t) list("Library / cell" 480 'left 'string t)
            list("Allowed core terminals" 180 'left 'string t))
          ?choices nil ?selectMode 'single ?callback 'lsnpPadCB)
        roleRow=hiCreateHorizontalBoxLayout('lsnpRoleRow ?items list(
          hiCreateCyclicField(?name 'lsnpRole ?prompt "Core terminal" ?choices list("-- select PAD --"))
          hiCreateButton(?name 'lsnpLocate ?buttonText "Locate terminal" ?callback "lsnpUiLocate()")
          hiCreateButton(?name 'lsnpAdd ?buttonText "Add required target" ?callback "lsnpUiAdd()")))
        buttons=hiCreateHorizontalBoxLayout('lsnpMappingButtons ?items list(
          hiCreateButton(?name 'lsnpRemove ?buttonText "Remove explicit target" ?callback "lsnpUiRemove()")
          hiCreateButton(?name 'lsnpRescan ?buttonText "Rescan PADs" ?callback "lsnpState['inventory]=nil lsnpUiRefresh()")
          hiCreateButton(?name 'lsnpCheck ?buttonText "Check this Pin" ?callback "lsnpUiRecheck()")))
        fileRow=hiCreateHorizontalBoxLayout('lsnpFileRow ?items list(
          list(hiCreateStringField(?name 'lsnpFile ?prompt "Config" ?value strcat(getWorkingDir() "/lsn_pad_config.il")) 'stretch 1)
          hiCreateButton(?name 'lsnpSave ?buttonText "Save config" ?callback "lsnpUiSave()")
          hiCreateButton(?name 'lsnpLoad ?buttonText "Load config" ?callback "lsnpUiLoad()")))
        root=hiCreateVerticalBoxLayout('lsnpRoot ?margins list(10 10 10 10) ?spacing 6 ?items list(
          header scopeBox list(lists 'stretch 2) roleRow
          list(hiCreateReportField(?name 'lsnpBindings ?title "Required PAD targets for this Pin (all must connect)"
            ?headers list(list("Instance path" 300 'left 'string t) list("Core terminal" 160 'left 'string t)
              list("Intent source" 240 'left 'string t)) ?choices nil ?selectMode 'single ?callback 'lsnpBindingCB) 'stretch 1)
          buttons fileRow hiCreateStringField(?name 'lsnpStatus ?value "" ?editable nil)))
        lsnpState['form]=hiCreateLayoutForm('lsnpForm "PAD connection setup" root
          ?buttonLayout 'OKCancel ?initialSize list(1000 860)))
      lsnpState['form]->lsnpNet->value=lsnpState['mappingNet]
      lsnpState['form]->lsnpLib->value=cv~>libName lsnpState['form]->lsnpCell->value=cv~>cellName
      lsnpState['form]->lsnpView->value=cv~>viewName lsnpState['form]->lsnpCorePath->value=buildString(scope['path] "/")
      lsnpUiRefresh() hiDisplayForm(lsnpState['form]))))

procedure(lsnpScopeOverview()
  let((scope win points lo hi span margin hs prev)
    scope=lsnpScope() win=scope['window]
    if(scope['error] then lsnMessage(scope['error])
      else
      lsnCollect(lsnState['record])
      points=foreach(mapcar ep lsnState['points]
        if(nth(4 ep)=="PAD" then ep else lsnpCoreToScope(ep scope)))
      when(points
        lo=copy(cadr(car(points))) hi=copy(lo)
        foreach(ep points
          lo=list(min(xCoord(lo) xCoord(cadr(ep))) min(yCoord(lo) yCoord(cadr(ep))))
          hi=list(max(xCoord(hi) xCoord(cadr(ep))) max(yCoord(hi) yCoord(cadr(ep)))))
        span=max(lsnCfg('minViewSpan) xCoord(hi)-xCoord(lo) yCoord(hi)-yCoord(lo)) margin=span*0.1
        lsnSaveView(win) lsnClear()
        hiZoomIn(win list(list(xCoord(lo)-margin yCoord(lo)-margin) list(xCoord(hi)+margin yCoord(hi)+margin)))
        hs=lsnNewHilight("candidate" win)
        foreach(ep points
          lsnDrawPoint(hs ep span/55.0 length(points)<=lsnCfg('annotationLimit) win)
          when(prev geAddHilightLine(hs list(cadr(prev) cadr(ep)))) prev=ep)
        hiRedraw(win) lsnMessage("PAD-scope overview: logical links do not prove routing.")))))

lsnpBaseOverview=getd('lsnOverview)
procedure(lsnOverview()
  let((scope)
    scope=lsnpScope()
    if(lsnState['record] && lsnIsSchematicPin(lsnState['record]) && !scope['error] &&
      scope['window]!=lsnState['window] then lsnpScopeOverview()
      else apply(lsnpBaseOverview nil))))

; END PAD CORE SUPPORT

lsncInvalidate()
printf("Navigation physical connectivity %s loaded. Prediction is not invoked.\n" lsncVersion)

printf("Signal Navigator %s loaded. Activate a layout and run lsnStart().\n" lsnVersion)
