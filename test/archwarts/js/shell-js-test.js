#!/usr/bin/env node
"use strict"
const assert = require("assert")
const ClipboardHistory = require("../../../desktop/shell/js/ClipboardHistory.js")
const AppSearch = require("../../../desktop/shell/js/AppSearch.js")
const NotifHistory = require("../../../desktop/shell/js/NotificationHistory.js")

// --- Clipboard history ---
let h = []
const text = { type: "text", text: "hello world" }
h = ClipboardHistory.addEntry(h, text, 500)
assert.strictEqual(h.length, 1, "add first text entry")
assert.strictEqual(ClipboardHistory.entryKey(h[0]), "text:hello world")

h = ClipboardHistory.addEntry(h, { type: "text", text: "hello world" }, 500)
assert.strictEqual(h.length, 1, "identical text deduplicated")

h = ClipboardHistory.addEntry(h, { type: "text", text: "second" }, 500)
assert.strictEqual(h.length, 2, "distinct text appended")
assert.strictEqual(h[0].text, "second", "newest first")

h = ClipboardHistory.addEntry(h, { type: "image", mime: "image/png", path: "/tmp/a.png" }, 500)
assert.strictEqual(h.length, 3, "image entry appended")
assert.strictEqual(h[0].type, "image", "image newest")

h = ClipboardHistory.addEntry(h, { type: "text" }, 500)
assert.strictEqual(h.length, 3, "empty text entry rejected")

const capped = ClipboardHistory.addEntry(h, { type: "text", text: "third" }, 2)
assert.strictEqual(capped.length, 2, "history capped at limit")
assert.strictEqual(capped[0].text, "third")

const removed = ClipboardHistory.removeEntryAt(h, 1)
assert.strictEqual(removed.length, 2, "entry removed by index")

const rows = ClipboardHistory.displayRows(h, "second", 50)
assert.strictEqual(rows.length, 1, "text filter matches query")
assert.strictEqual(rows[0].entryType, "text")
assert.strictEqual(rows[0].previewText, "second")

const allRows = ClipboardHistory.displayRows(h, "", 50)
assert.strictEqual(allRows.length, 3, "empty query returns all rows")

const parsed = ClipboardHistory.parseHistory(JSON.stringify(h))
assert.strictEqual(parsed.length, 3, "history serializes and parses")
assert.strictEqual(ClipboardHistory.parseHistory("not json").length, 0)
assert.strictEqual(ClipboardHistory.parseHistory("").length, 0)

const fromLine = ClipboardHistory.parseEntryJson('{"type":"text","text":"line"}')
assert.strictEqual(fromLine.text, "line")
assert.strictEqual(ClipboardHistory.parseEntryJson("garbage"), null)

assert.strictEqual(ClipboardHistory.previewForText("a\nb", 80), "a")
assert.strictEqual(ClipboardHistory.previewForText("x".repeat(100), 10).length, 10)

// --- App search ---
const apps = [
  { id: "firefox.desktop", name: "Firefox", genericName: "Web Browser", comment: "Browse the web", keywords: ["browser"] },
  { id: "dolphin.desktop", name: "Dolphin", genericName: "File Manager", comment: "Manage files", keywords: ["files", "manager"] },
  { id: "org.gimp.GIMP.desktop", name: "GNU Image Manipulation Program", genericName: "Image Editor", comment: "Create and edit images", keywords: ["gimp"] },
  { id: "org.kde.ark.desktop", name: "Ark", genericName: "Archiving Tool", comment: "Archive manager", keywords: [] },
  { id: "hidden.desktop", name: "Hidden App", genericName: "", comment: "", keywords: [] }
]
const hiddenIds = { "hidden.desktop": true }

let sorted = AppSearch.sortedEntries(apps, "fire", function(e) {
  return AppSearch.isHiddenEntry(e, hiddenIds)
})
assert.strictEqual(sorted.length, 1)
assert.strictEqual(AppSearch.entryName(sorted[0]), "Firefox")

sorted = AppSearch.sortedEntries(apps, "file", function(e) {
  return AppSearch.isHiddenEntry(e, hiddenIds)
})
assert.strictEqual(sorted[0].id, "dolphin.desktop", "prefix match ranks above substring")

sorted = AppSearch.sortedEntries(apps, "", function(e) {
  return AppSearch.isHiddenEntry(e, hiddenIds)
})
assert.strictEqual(sorted.length, 4, "hidden entry filtered from empty query")
assert.strictEqual(AppSearch.score(apps[0], "firefox"), 1.0, "exact name top score")

// --- Notification history ---
let nlist = []
nlist = NotifHistory.addNotification(nlist, { id: 1, appName: "app", summary: "S", body: "B" }, 200)
assert.strictEqual(nlist.length, 1)
nlist = NotifHistory.addNotification(nlist, { id: 1, appName: "app", summary: "S2", body: "B2" }, 200)
assert.strictEqual(nlist.length, 1, "same app+id replaces")
nlist = NotifHistory.addNotification(nlist, { id: 2, appName: "other", summary: "T", body: "X" }, 200)
assert.strictEqual(nlist.length, 2)

const nrows = NotifHistory.displayRows(nlist, "S2", 50)
assert.strictEqual(nrows.length, 1)
assert.strictEqual(nrows[0].summary, "S2")
assert.ok(nrows[0].timeLabel.length > 0, "time label present")

const ncap = NotifHistory.addNotification(nlist, { id: 3, appName: "a", summary: "1" }, 1)
assert.strictEqual(ncap.length, 1)

const removedN = NotifHistory.removeNotification(nlist, 2, "other")
assert.strictEqual(removedN.length, 1)
assert.strictEqual(NotifHistory.parseHistory("{}").length, 0)

console.log("PASS: Archwarts shell JS logic")