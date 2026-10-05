// Archwarts application search and ranking. Pure functions; testable with node.
// QML consumers import this module with `import "js/AppSearch.js" as AppSearch`.

function entryName(entry) {
  return String((entry && entry.name) || (entry && entry.desktopNames && entry.desktopNames[0]) || "")
}

function entrySubtext(entry) {
  var comment = String((entry && entry.comment) || "")
  var generic = String((entry && entry.genericName) || "")
  if (generic && comment.toLowerCase().indexOf(generic.toLowerCase()) === -1) {
    return generic ? generic + " — " + comment : comment
  }
  return comment
}

function entryExec(entry) {
  return String((entry && entry.exec) || "")
}

function searchableText(entry) {
  var parts = []
  parts.push(entryName(entry))
  parts.push(String((entry && entry.genericName) || ""))
  parts.push(String((entry && entry.comment) || ""))
  if (entry && entry.keywords) parts.push(entry.keywords.join(" "))
  return parts.join("\n").toLowerCase()
}

function isHiddenEntry(entry, hiddenIds, isDesktopHidden) {
  var id = String((entry && entry.id) || "")
  if (!id) return false
  if (hiddenIds && hiddenIds[id] === true) return true
  if (typeof isDesktopHidden === "function" && isDesktopHidden(id)) return true
  return false
}

// Score 0..1. Higher is better. Prefix and word matches rank above substring.
function score(entry, query) {
  var q = String(query || "").trim().toLowerCase()
  if (!q) return 0.4
  var name = entryName(entry).toLowerCase()
  if (name === q) return 1.0
  if (name.indexOf(q) === 0) return 0.9
  var haystack = searchableText(entry)
  var wordBoundary = new RegExp("(^|[^a-z0-9])" + escapeRegExp(q))
  if (wordBoundary.test(haystack)) return 0.7
  if (haystack.indexOf(q) !== -1) return 0.5
  return 0
}

function escapeRegExp(value) {
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
}

// Sort desktop-entry values by relevance to query, applying hidden filtering.
function sortedEntries(values, query, isHidden) {
  var entries = Array.isArray(values) ? values.slice() : []
  var out = []
  for (var i = 0; i < entries.length; i++) {
    var entry = entries[i]
    if (!entry || entry.noDisplay === true) continue
    if (typeof isHidden === "function" && isHidden(entry)) continue
    var s = score(entry, query)
    if (String(query || "").trim() && s <= 0) continue
    out.push({ entry: entry, score: s })
  }
  out.sort(function(a, b) {
    if (b.score !== a.score) return b.score - a.score
    return entryName(a.entry).localeCompare(entryName(b.entry))
  })
  var result = []
  for (var j = 0; j < out.length; j++) result.push(out[j].entry)
  return result
}

if (typeof module !== "undefined") module.exports = {
  entryName: entryName,
  entrySubtext: entrySubtext,
  entryExec: entryExec,
  isHiddenEntry: isHiddenEntry,
  score: score,
  sortedEntries: sortedEntries,
  searchableText: searchableText
}