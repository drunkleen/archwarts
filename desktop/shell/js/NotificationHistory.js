// Archwarts notification history logic. Pure functions; testable with node.
// QML consumers import this module with `import "js/NotificationHistory.js" as NotifHistory`.

function normalizeNotification(n) {
  if (!n || typeof n !== "object") return null
  return {
    id: n.id !== undefined ? n.id : 0,
    appName: String(n.appName || ""),
    appIcon: String(n.appIcon || ""),
    summary: String(n.summary || ""),
    body: String(n.body || ""),
    urgency: String(n.urgency || "normal"),
    actions: Array.isArray(n.actions) ? n.actions.slice() : [],
    timestamp: n.timestamp || new Date().getTime()
  }
}

function addNotification(list, n, limit) {
  var normalized = normalizeNotification(n)
  if (!normalized) return list
  var next = []
  for (var i = 0; i < list.length; i++) {
    if (list[i] && list[i].id === normalized.id && list[i].appName === normalized.appName) continue
    next.push(list[i])
  }
  next.unshift(normalized)
  return next.slice(0, limit || 200)
}

function removeNotification(list, id, appName) {
  var next = []
  for (var i = 0; i < list.length; i++) {
    var n = list[i]
    if (n && n.id === id && (!appName || n.appName === appName)) continue
    next.push(n)
  }
  return next
}

function clearNotifications() {
  return []
}

function parseHistory(raw) {
  var list = []
  if (!raw) return list
  var parsed = null
  try { parsed = JSON.parse(raw) } catch (e) { return list }
  if (!Array.isArray(parsed)) return list
  for (var i = 0; i < parsed.length; i++) {
    var n = normalizeNotification(parsed[i])
    if (n) list.push(n)
  }
  return list
}

function displayRows(history, query, limit) {
  var q = String(query || "").trim().toLowerCase()
  var rows = []
  for (var i = 0; i < history.length; i++) {
    var n = history[i]
    if (!n) continue
    if (q && n.summary.toLowerCase().indexOf(q) === -1 && n.body.toLowerCase().indexOf(q) === -1) continue
    rows.push({
      index: i,
      id: n.id,
      appName: n.appName,
      appIcon: n.appIcon,
      summary: n.summary,
      body: n.body,
      urgency: n.urgency,
      actions: n.actions,
      timestamp: n.timestamp,
      timeLabel: timeLabel(n.timestamp)
    })
    if (limit && rows.length >= limit) break
  }
  return rows
}

function timeLabel(ts) {
  var d = ts ? new Date(ts) : new Date()
  var today = new Date()
  var sameDay = d.getFullYear() === today.getFullYear() && d.getMonth() === today.getMonth() && d.getDate() === today.getDate()
  var h = d.getHours()
  var m = ("0" + d.getMinutes()).slice(-2)
  if (sameDay) return h + ":" + m
  return (d.getMonth() + 1) + "/" + d.getDate() + " " + h + ":" + m
}

if (typeof module !== "undefined") module.exports = {
  normalizeNotification: normalizeNotification,
  addNotification: addNotification,
  removeNotification: removeNotification,
  clearNotifications: clearNotifications,
  parseHistory: parseHistory,
  displayRows: displayRows,
  timeLabel: timeLabel
}