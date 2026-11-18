; SPDX-License-Identifier: MIT
; 0.3.5 UI/statistics regression. Independent READ-ONLY layout session only.
; Uses controlled in-memory cached outcomes; never creates/traces/saves geometry.
procedure(lsnStatsAssert(condition description)
  unless(condition error("Statistics regression failed: %s\n" description))
  lsnStatsTestCount=lsnStatsTestCount+1
  printf("STATISTICS TEST OK: %s\n" description))

procedure(lsnStatsVisible(name)
  exists(row lsnState['form]->lsnSignals->choices car(row)==name))

procedure(lsnStatsTestEntry(tags)
  let((entry)
    entry=makeTable('lsnStatsTestEntry nil)
    entry['tags]=tags entry['column]=buildString(tags "; ") entry['counters]=lsncCounters()
    entry))

procedure(lsnRunStatisticsTests()
  let((keys old cache stamp search category selected cv pins nets stats before entry savedCounters)
    cv=lsnState['cv]
    unless(lsnValid() && cv~>mode=="r" && lsnVersion=="0.3.5"
      error("Bind an independent READ-ONLY layout with Signal Navigator 0.3.5.\n"))
    keys=list('records 'names 'record 'source 'sourcePorts 'sourceEndpoints 'indexedSource 'busy)
    old=foreach(mapcar key keys list(key lsnState[key]))
    cache=lsncState['cache] stamp=lsncState['stamp]
    search=lsnState['form]->lsnSearch->value category=lsnState['form]->lsnCategory->value
    lsnStatsTestCount=0
    unwindProtect(
      progn(
        lsnState['source]=nil lsnState['indexedSource]=nil
        lsnState['sourcePorts]=makeTable('lsnStatsTestPorts nil)
        lsnState['sourceEndpoints]=makeTable('lsnStatsTestSource nil)
        lsnState['records]=makeTable('lsnStatsTestRecords nil)
        pins=list("P_OPEN" "P_MIXED" "P_DONE" "P_NEW")
        nets=list("N_OPEN" "N_DONE" "N_UNVERIFIED" "N_STALE" "N_SINGLE" "LAYOUT_PORT")
        foreach(name append(pins list("P_BUS<1:0>"))
          lsnState['sourcePorts][name]=list(list(nil nil "input")))
        lsnState['names]=sort(append(append(pins nets) list("P_BUS<1:0>" "N_BUS<1:0>")) 'alphalessp)
        foreach(name lsnState['names]
          lsnState['records][name]=list(name
            cond((member(name list("P_BUS<1:0>" "N_BUS<1:0>")) "BUS")
              (name=="LAYOUT_PORT" || member(name pins) "PORT") (t "NET")) nil "Test"))
        lsncState['cache]=makeTable('lsnStatsTestCache nil) lsncState['stamp]=lsncStamp()
        foreach(name list("P_OPEN" "N_OPEN") lsncState['cache][name]=lsnStatsTestEntry(list("Open")))
        foreach(name list("P_DONE" "N_DONE" "N_STALE")
          lsncState['cache][name]=lsnStatsTestEntry(list("Connected")))
        lsncState['cache]["P_DONE"]['padRequired]=t
        lsncState['cache]["P_DONE"]['recordName]="P_DONE"
        lsncState['cache]["P_DONE"]['padSignature]=lsnpSignature("P_DONE")
        lsncState['cache]["P_MIXED"]=lsnStatsTestEntry(list("Open" "Unverified"))
        lsncState['cache]["N_UNVERIFIED"]=lsnStatsTestEntry(list("Unverified"))
        lsncState['cache]["N_SINGLE"]=lsnStatsTestEntry(list("Single location"))
        lsncState['cache]["N_STALE"]['counters]=list(list(cv cv~>modifiedCounter+1))
        lsnState['record]=lsnState['records]["N_OPEN"]
        selected=lsnState['record] before=lsncState['cache]
        entry=lsncState['cache]["N_OPEN"]
        lsnState['form]->lsnSearch->value=""
        lsnStatsAssert(equal(lsnState['form]->lsnCategory->choices
          list("All" "Pin" "Nets" "Pin Open" "Net Open" "Unverified"))
          "Show contains exactly the six requested choices")
        lsnState['form]->lsnCategory->value="Pin Open" lsnFilter()
        lsnStatsAssert(length(lsnState['form]->lsnSignals->choices)==2 &&
          lsnStatsVisible("P_OPEN") && lsnStatsVisible("P_MIXED") && !lsnStatsVisible("N_OPEN")
          "Pin Open selects only open schematic I/O, including mixed uncertainty")
        lsnState['form]->lsnCategory->value="Net Open" lsnFilter()
        lsnStatsAssert(length(lsnState['form]->lsnSignals->choices)==1 && lsnStatsVisible("N_OPEN")
          "Net Open excludes open schematic Pins")
        lsnState['form]->lsnCategory->value="Unverified" lsnFilter()
        lsnStatsAssert(length(lsnState['form]->lsnSignals->choices)==2 &&
          lsnStatsVisible("P_MIXED") && lsnStatsVisible("N_UNVERIFIED")
          "Unverified remains available for both Pins and Nets")
        lsnState['form]->lsnCategory->value="Pin" lsnFilter()
        lsnStatsAssert(length(lsnState['form]->lsnSignals->choices)==5 &&
          lsnStatsVisible("P_NEW") && lsnStatsVisible("P_BUS<1:0>") && !lsnStatsVisible("LAYOUT_PORT")
          "Pin classification is independent of status and layout-only port objects")
        lsnState['form]->lsnCategory->value="Nets" lsnFilter()
        lsnStatsAssert(length(lsnState['form]->lsnSignals->choices)==7 &&
          lsnStatsVisible("LAYOUT_PORT") && !lsnStatsVisible("P_DONE") "Nets remains the schematic Pin complement")
        stats=lsnStatistics() pins=stats['pins] nets=stats['nets]
        lsnStatsAssert(pins['total]==4 && pins['connected]==1 && pins['open]==2 &&
          pins['unverified]==1 && pins['pending]==1 "Pin totals handle mixed flags and unchecked results")
        lsnStatsAssert(nets['total]==6 && nets['connected]==1 && nets['open]==1 &&
          nets['unverified]==1 && nets['pending]==3
          "Net progress excludes stale completion and single-location-only outcomes")
        lsnStatsAssert(stats['buses]==2 "bus aggregates are excluded from scalar counts")
        lsnStatsAssert(index(lsnStatisticsText(pins) "25.0%") && index(lsnStatisticsText(nets) "16.7%")
          "completion rates use all scalar records, not only checked records")
        lsnStatsAssert(index(lsnStatisticsText(lsnStatisticsBucket()) "0.0%")
          "empty categories report zero percent without division by zero")
        lsnState['form]->lsnCategory->value="Pin Open" lsnState['form]->lsnSearch->value="P_OPEN" lsnFilter()
        lsnStatsAssert(length(lsnState['form]->lsnSignals->choices)==1 && lsnStatsVisible("P_OPEN")
          "name search combines with Pin Open")
        stats=lsnStatistics()
        lsnStatsAssert(stats['pins]['total]==4 && stats['nets]['total]==6 && stats['buses]==2
          "global totals do not change under search or Show filtering")
        lsnStatsAssert(lsnState['form]->lsnStatsPins->value==lsnStatisticsText(stats['pins]) &&
          index(lsnState['form]->lsnStatsTitle->value "Visible rows: 1")
          "native statistics fields show global progress plus visible row count")
        lsnStatsAssert(lsncState['cache]==before && lsncEntry("N_OPEN")==entry && lsnState['record]==selected
          "statistics/filter changes preserve selection and every cached result")
        savedCounters=lsncEntry("P_DONE")['counters]
        lsncEntry("P_DONE")['counters]=list(list(cv cv~>modifiedCounter+1))
        stats=lsnStatistics()
        lsnStatsAssert(stats['pins]['connected]==0 && stats['pins]['pending]==2
          "stale PAD-complete Pins do not inflate completion progress")
        lsncEntry("P_DONE")['counters]=savedCounters
        lsncState['cache]["P_OPEN"]=lsnStatsTestEntry(list("Connected"))
        lsnState['form]->lsnSearch->value="" lsnFilter()
        lsnStatsAssert(!lsnStatsVisible("P_OPEN") && lsnStatsVisible("P_MIXED") &&
          lsncEntry("N_OPEN")==entry && lsnState['record]==selected
          "one updated result leaves Open without changing another net or selection")
        stats=lsnStatistics()
        lsnStatsAssert(stats['pins]['connected]==2 && stats['pins]['open]==1
          "progress refreshes immediately after a single cached result changes")
        lsnState['form]->lsnCategory->value="All" lsnFilter()
        lsnStatsAssert(length(lsnState['form]->lsnSignals->choices)==12 "All retains unchecked records and bus rows")
        lsnStatsAssert(!boundp('lsnrState) "prediction remains unloaded")
        printf("STATISTICS/FILTER REGRESSION: %d passed.\n" lsnStatsTestCount))
      progn(
        foreach(pair old lsnState[car(pair)]=cadr(pair))
        lsncState['cache]=cache lsncState['stamp]=stamp
        lsnState['form]->lsnSearch->value=search lsnState['form]->lsnCategory->value=category lsnFilter()))
    lsnStatsTestCount))
