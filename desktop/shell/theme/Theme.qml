pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Archwarts theme. Loads palette.conf from the Archwarts config home and
// exposes named colors with safe defaults. Writes from `archwarts theme apply`
// are reflected live via the FileView watcher.
QtObject {
  id: root

  readonly property string configHome: Quickshell.env("ARCHWARTS_CONFIG_HOME") ||
    Quickshell.env("HOME") + "/.config/archwarts"
  readonly property string palettePath: configHome + "/theme/palette.conf"

  property var palette: ({})
  property var defaults: ({
    "background": "#11111b",
    "surface": "#181825",
    "surface-alt": "#313244",
    "text": "#cdd6f4",
    "text-muted": "#a6adc8",
    "accent": "#89b4fa",
    "accent-alt": "#f5c2e7",
    "positive": "#a6e3a1",
    "warning": "#f9e2af",
    "negative": "#f38ba8",
    "bar.background": "#11111b",
    "bar.text": "#cdd6f4",
    "bar.active": "#89b4fa",
    "menu.background": "#181825",
    "menu.text": "#cdd6f4",
    "menu.border": "#313244",
    "menu.selected-background": "#45475a",
    "menu.selected-text": "#cdd6f4",
    "notification.background": "#181825",
    "notification.border": "#313244",
    "notification.text": "#cdd6f4"
  })

  function color(key) {
    var value = root.palette[key] || root.defaults[key]
    if (!value) return "#000000"
    try { return value } catch (e) { return "#000000" }
  }

  // Palette reload: parse key=value lines into the palette map.
  function parse(raw) {
    var next = {}
    var lines = String(raw || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (!line || line.charAt(0) === "#") continue
      var eq = line.indexOf("=")
      if (eq <= 0) continue
      next[line.slice(0, eq).trim()] = line.slice(eq + 1).trim()
    }
    root.palette = next
  }

  readonly property color background: color("background")
  readonly property color surface: color("surface")
  readonly property color surfaceAlt: color("surface-alt")
  readonly property color text: color("text")
  readonly property color textMuted: color("text-muted")
  readonly property color accent: color("accent")
  readonly property color accentAlt: color("accent-alt")
  readonly property color positive: color("positive")
  readonly property color warning: color("warning")
  readonly property color negative: color("negative")

  property FileView paletteWatcher: FileView {
    path: root.palettePath
    watchChanges: true
    printErrors: false
    onLoaded: root.parse(text())
    onFileChanged: reload()
    onLoadFailed: root.parse("")
  }
}