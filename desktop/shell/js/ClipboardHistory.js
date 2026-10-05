// Archwarts clipboard history logic. Pure functions; no Qt/QML dependency so
// it can be exercised directly with node. QML consumers import this module.

// Normalize an entry into {type, text?, mime?, path?, capturedAt?}.
// Returns null when the entry cannot be represented.
function normalizeEntry(value) {
  if (!value || typeof value !== "object") return null
  var type = String(value.type || "")
  if (type === "text") {
    var text = String(value.text || "")
    if (text.length === 0) return null
    return {
      type: "text",
      text: text,
      capturedAt: value.capturedAt || timestamp()
    }
  }
  if (type === "image" || type === "file") {
    var path = String(value.path || "")
    if (path.length === 0) return null
    return {
      type: type,
      mime: String(value.mime || ""),
      path: path,
      capturedAt: value.capturedAt || timestamp()
    }
  }
  return null
}

function timestamp() {
  var d = new Date()
  return d.getHours() + ":" + ("0" + d.getMinutes()).slice(-2)
}

// Deterministic entry identity for deduplication.
function entryKey(entry) {
  if (!entry) return ""
  if (entry.type === "text") return "text:" + entry.text
  return entry.type + ":" + entry.path
}

// Parse a JSON document (may be empty or garbage) into a history array.
function parseHistory(raw) {
  var list = []
  if (!raw) return list
  var parsed = null
  try { parsed = JSON.parse(raw) } catch (e) { return list }
  if (!Array.isArray(parsed)) return list
  for (var i = 0; i < parsed.length; i++) {
    var entry = normalizeEntry(parsed[i])
    if (entry) list.push(entry)
  }
  return list
}

// Parse a single capture line: a JSON object describing one clipboard entry.
function parseEntryJson(line) {
  var value = String(line || "").trim()
  if (!value) return null
  var parsed = null
  try { parsed = JSON.parse(value) } catch (e) { return null }
  return normalizeEntry(parsed)
}

// Prepend a normalized entry, deduplicating by key and capping the list.
function addEntry(history, entry, limit) {
  var normalized = normalizeEntry(entry)
  if (!normalized) return history
  var key = entryKey(normalized)
  var next = []
  for (var i = 0; i < history.length; i++) {
    if (entryKey(history[i]) === key) continue
    next.push(history[i])
  }
  next.unshift(normalized)
  return next.slice(0, limit || 500)
}

function removeEntryAt(history, index) {
  if (index < 0 || index >= history.length) return history
  return history.slice(0, index).concat(history.slice(index + 1))
}

function clearHistory() {
  return []
}

function previewForText(text, max) {
  var firstLine = String(text || "").split("\n")[0]
  var limit = max || 80
  if (firstLine.length > limit) firstLine = firstLine.slice(0, limit - 1) + "…"
  return firstLine
}

// Build display rows for a list view, filtering text entries by query.
function displayRows(history, query, limit) {
  var q = String(query || "").trim().toLowerCase()
  var rows = []
  for (var i = 0; i < history.length; i++) {
    var entry = history[i]
    if (q && entry.type !== "text") continue
    if (entry.type === "text" && q && String(entry.text).toLowerCase().indexOf(q) === -1) continue
    rows.push({
      index: i,
      entryType: entry.type,
      fullText: entry.type === "text" ? entry.text : "",
      previewText: entry.type === "text" ? previewForText(entry.text, 80) : labelForEntry(entry),
      previewImage: entry.type === "image" ? entry.path : "",
      path: entry.path || "",
      mime: entry.mime || ""
    })
    if (limit && rows.length >= limit) break
  }
  return rows
}

function labelForEntry(entry) {
  if (!entry) return ""
  if (entry.type === "image") return "Image — " + String(entry.capturedAt || "")
  if (entry.type === "file") return String(entry.path || "")
  return ""
}

if (typeof module !== "undefined") module.exports = {
  normalizeEntry: normalizeEntry,
  entryKey: entryKey,
  parseHistory: parseHistory,
  parseEntryJson: parseEntryJson,
  addEntry: addEntry,
  removeEntryAt: removeEntryAt,
  clearHistory: clearHistory,
  displayRows: displayRows,
  previewForText: previewForText,
  labelForEntry: labelForEntry
}