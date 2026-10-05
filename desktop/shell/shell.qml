import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

import "Commons"
import "theme"

import "bar"
import "launcher"
import "menu"
import "clipboard"
import "notifications"
import "panels"
import "lock"

// Archwarts independent desktop shell. Owns the IPC trigger loop, the bar,
// and every panel. No inherited runtime, path, or command is referenced.
ShellRoot {
  id: root

  readonly property string configHome: Quickshell.env("ARCHWARTS_CONFIG_HOME") ||
    Quickshell.env("HOME") + "/.config/archwarts"
  readonly property string runtimeHome: Quickshell.env("ARCHWARTS_RUNTIME_HOME") ||
    (Quickshell.env("XDG_RUNTIME_DIR") || ("/run/user/" + Quickshell.env("UID"))) + "/archwarts"
  readonly property string ipcDir: runtimeHome + "/ipc"

  readonly property string home: Quickshell.env("HOME")

  // Owned subsystems. The bar spans every screen via Variants.
  Bar { id: bar }
  Launcher { id: launcher }
  Menu { id: menu }
  ClipboardPanel { id: clipboard }
  NotificationService { id: notifications }
  AudioPanel { id: audio }
  NetworkPanel { id: network }
  BluetoothPanel { id: bluetooth }
  MediaPanel { id: media }
  Osd { id: osd }
  LockScreen { id: lockScreen }

  function route(target, action, payload) {
    switch (target) {
      case "launcher": launcher.toggle(); break
      case "menu": menu.toggle(); break
      case "clipboard": clipboard.toggle(); break
      case "notifications": notifications.toggle(); break
      case "audio": audio.toggle(); break
      case "network": network.toggle(); break
      case "bluetooth": bluetooth.toggle(); break
      case "media": media.toggle(); break
      case "osd": osd.show(payload || {}); break
      case "lock": lockScreen.lock(); break
      case "capture":
        Util.execDetached("archwarts capture " + Util.shellQuote(String((payload && payload.mode) || "region")))
        break
      default:
        console.warn("Archwarts shell: unknown ipc target " + target)
    }
  }

  function dispatchFromFile(file, payload) {
    var base = String(file || "")
    var slash = base.lastIndexOf("/")
    if (slash >= 0) base = base.slice(slash + 1)
    if (base.slice(-5) !== ".json") return
    base = base.slice(0, -5)
    var parts = base.split("-")
    // <seq>-<target>-<action>.json
    if (parts.length < 3) return
    var target = parts[1]
    var action = parts[2]
    if (action === "toggle") root.route(target, action, payload || {})
  }

  function handleDrain(text) {
    var chunks = String(text || "").split("@@")
    for (var i = 0; i < chunks.length; i++) {
      var chunk = chunks[i]
      if (!String(chunk).trim()) continue
      var lines = chunk.split("\n")
      var file = lines.shift().trim()
      var body = lines.join("\n")
      var payload = {}
      try { payload = JSON.parse(body) } catch (e) { payload = {} }
      root.dispatchFromFile(file, payload)
    }
  }

  FileView {
    path: root.ipcDir
    watchChanges: true
    printErrors: false
    onFileChanged: drainProc.running = true
    onLoadFailed: { /* ipc dir may not exist until a trigger is written */ }
  }

  Process {
    id: drainProc
    property string ipcDir: root.ipcDir
    command: ["bash", "-c",
      'for f in "$1"/*.json; do [[ -e $f ]] || continue; echo "@@$f"; cat "$f"; echo; rm -f "$f"; done',
      "bash", root.ipcDir]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.handleDrain(text)
    }
  }

  Component.onCompleted: {
    drainProc.running = true
  }
}