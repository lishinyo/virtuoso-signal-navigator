; SPDX-License-Identifier: MIT
; HISTORICAL 0.3.4 AND EARLIER UI CONTRACT; not a 0.3.5 entry point.
; Current six-choice UI/statistics checks: statistics_filters.il / lsnRunStatisticsTests().
; Focused UI/cache regression for an explicitly chosen read-only test window.
; Opens only the passed existing auxiliary view, never creates/saves geometry.
procedure(lsnStatusAssert(condition message)
  unless(condition error("Status regression failed: %s\n" message))
  lsnStatusTestCount=lsnStatusTestCount+1
  printf("STATUS TEST OK: %s\n" message))

procedure(lsnStatusVisible(name)
  exists(row lsnState['form]->lsnSignals->choices car(row)==name))

procedure(lsnRunStatusCacheTests(openA openB connectedName pinName uncheckedName busName auxiliary)
  when(lsnVersion=="0.3.5"
    error("Historical menu test: use statistics_filters.il / lsnRunStatisticsTests() for 0.3.5.\n"))
  let((cv a b bColumn cache stamp viewCount extra values changed points mixed complete unplaced
       selected search kind only connectedEntry pinEntry originalA)
    cv=lsnState['cv]
    unless(cv && cv~>mode=="r" && lsnValid()
      error("Bind an independent READ-ONLY test layout before running.\n"))
    lsnStatusTestCount=0
    selected=when(lsnState['record] car(lsnState['record]))
    search=lsnState['form]->lsnSearch->value kind=lsnState['form]->lsnCategory->value
    only=lsnState['form]->lsnUnconnectedOnly->value
    unwindProtect(
      progn(
        lsnState['form]->lsnSearch->value="" lsnState['form]->lsnCategory->value="All"
        lsnChoose(openA nil) a=lsncEntry(openA)
        lsnChoose(openB nil) b=lsncEntry(openB) bColumn=b['column]
        lsnStatusAssert(lsncEntry(openA)==a && member("Open" a['tags])
          "checking a second open net keeps the first result")
        lsnChoose(openA nil)
        for(i 1 3 lsncCheckCurrent())
        lsnStatusAssert(lsncEntry(openB)==b && b['column]==bColumn && lsncEntryCurrent(b)
          "repeated Check selected preserves the other net and its freshness")
        cache=lsncState['cache] stamp=lsncStamp() viewCount=length(dbGetOpenCellViews())
        extra=dbOpenCellViewByType(car(auxiliary) cadr(auxiliary) caddr(auxiliary) "" "r")
        lsnStatusAssert(dbIsId(extra) && length(dbGetOpenCellViews())>viewCount
          "an unrelated existing cellview is actually opened read-only")
        lsncEnsureContext() lsnFilter()
        lsnStatusAssert(lsncState['cache]==cache && lsncStamp()==stamp && lsncEntry(openB)==b
          "opening another view does not clear cached net statuses")
        lsncCheckCurrent()
        lsnStatusAssert(lsncEntry(openB)==b && lsncEntryCurrent(b) && lsncColumn(b)==bColumn
          "Check selected after a new view still leaves the other result unchanged")
        a=lsncEntry(openA) values=lsncCounterMap() changed=lsncCounterMap()
        changed[cv]=list(cv~>modifiedCounter+1)
        lsnStatusAssert(lsncEntryCurrent(a values) && !lsncEntryCurrent(a changed)
          "a simulated real revision change marks the old result stale")
        lsnStatusAssert(lsncColumn(a changed)==strcat(a['column] " [needs recheck]") &&
          lsncEntry(openA)==a && lsncMatchesFilter(lsnState['records][openA] "Needs recheck" a changed)
          "stale results retain their status and enter Needs recheck")
        lsnChoose(connectedName nil) lsnChoose(pinName nil)
        connectedEntry=lsncEntry(connectedName) pinEntry=lsncEntry(pinName)
        lsnStatusAssert(member("Connected" connectedEntry['tags]) &&
          pinEntry['padRequired] && member(pinEntry['padStatus] list("pending" "unconnected"))
          "PAD-complete and PAD-pending schematic Pins have separate outcomes")
        lsnState['form]->lsnCategory->value="Open" lsnFilter()
        lsnStatusAssert(lsnStatusVisible(openA) && lsnStatusVisible(openB) &&
          !lsnStatusVisible(connectedName) && lsnStatusVisible(pinName) "Open also includes a Pin awaiting PAD connection")
        lsnState['form]->lsnCategory->value="Connected" lsnFilter()
        lsnStatusAssert(lsnStatusVisible(connectedName) && !lsnStatusVisible(openA) "Connected filter")
        lsnState['form]->lsnCategory->value="Pin" lsnFilter()
        lsnStatusAssert(lsnStatusVisible(pinName) && lsnStatusVisible(connectedName) &&
          !lsnStatusVisible(openA) "Pin includes both placed/connected and unplaced schematic I/O")
        lsnState['form]->lsnCategory->value="Not checked" lsnFilter()
        lsnStatusAssert(lsnStatusVisible(uncheckedName) && !lsnStatusVisible(openA) "Not checked filter")
        lsnStatusAssert(member("Pin" lsnState['form]->lsnCategory->choices) &&
          !member("Pin not placed" lsnState['form]->lsnCategory->choices) &&
          !member("Physical pin" lsnState['form]->lsnCategory->choices) &&
          !member("Ports" lsnState['form]->lsnCategory->choices)
          "Show has a single schematic Pin category")
        lsnState['form]->lsnCategory->value="Single location" lsnFilter()
        lsnStatusAssert(lsnStatusVisible(pinName) && !lsnStatusVisible(openA) "Single location filter")
        unwindProtect(
          progn(
            lsncState['cache][pinName]=nil
            lsnState['form]->lsnCategory->value="Pin" lsnFilter()
            lsnStatusAssert(lsnStatusVisible(pinName) && !lsnStatusVisible(openA)
              "Pin also includes unchecked external I/O and excludes internal device pins"))
          lsncState['cache][pinName]=pinEntry)
        lsnState['form]->lsnCategory->value="Nets" lsnFilter()
        lsnStatusAssert(lsnStatusVisible(openA) && !lsnStatusVisible(connectedName) "existing Nets filter")
        lsnState['form]->lsnCategory->value="Bus" lsnFilter()
        lsnStatusAssert(lsnStatusVisible(busName) && !lsnStatusVisible(openA) "Bus filter also includes unchecked bus records")
        lsnState['form]->lsnCategory->value="Open" lsnState['form]->lsnSearch->value=openB lsnFilter()
        lsnStatusAssert(length(lsnState['form]->lsnSignals->choices)==1 && lsnStatusVisible(openB)
          "name search combines with status filtering")
        lsnStatusAssert(car(lsnState['record])==pinName "filtering never silently selects another net")
        ; Controlled cached outcomes verify overlapping categories without
        ; drawing routes or modifying the database to manufacture a short/open.
        points=list(list("A" 0:0 list(0:0 1:1) "MET1" "PIN" "Physical pin" "A")
          list("B" 2:0 list(2:0 3:1) "MET1" "PIN" "Physical pin" "B")
          list("C" 4:0 list(4:0 5:1) "MET1" "LABEL" "Label anchor" "C"))
        mixed=lsncClassify(points nil list(1 2 nil) list("" "" "no landing"))
        complete=lsncClassify(list(car(points) cadr(points)) nil list(1 1) list("" ""))
        unplaced=lsncClassify(list(car(points)) list(list("PORT/IO" "not placed" "UNPLACED_IO" "input")) list(1) list(""))
        lsnStatusAssert(member("Open" mixed['tags]) && member("Unverified" mixed['tags]) &&
          !member("Connected" mixed['tags]) "mixed open/unverified net matches both categories")
        lsnStatusAssert(member("Pin not placed" unplaced['tags]) && !member("Unverified" unplaced['tags])
          "unplaced schematic I/O is not mislabeled as unknown physical geometry")
        lsnChoose(openA nil) originalA=lsncEntry(openA)
        unwindProtect(
          progn(
            mixed['counters]=lsncCounters() complete['counters]=lsncCounters()
            lsncState['cache][openA]=mixed
            lsnState['form]->lsnSearch->value="" lsnState['form]->lsnCategory->value="Unverified" lsnFilter()
            lsnStatusAssert(lsnStatusVisible(openA) "Unverified UI filter uses flags rather than a display prefix")
            lsnState['form]->lsnCategory->value="Open" lsnFilter()
            lsncState['cache][openA]=complete lsnFilter()
            lsnStatusAssert(!lsnStatusVisible(openA) && car(lsnState['record])==openA && lsncEntry(openB)==b
              "a net leaving its active status filter does not change selection or other results"))
          lsncState['cache][openA]=originalA)
        lsnStatusAssert(!boundp('lsnrState) "no prediction state/worker is loaded")
        printf("STATUS CACHE/FILTER REGRESSION: %d passed.\n" lsnStatusTestCount))
      progn(
        lsnState['form]->lsnSearch->value=search lsnState['form]->lsnCategory->value=kind
        lsnState['form]->lsnUnconnectedOnly->value=only
        when(selected lsnChoose(selected nil)) lsnFilter()))
    lsnStatusTestCount))
