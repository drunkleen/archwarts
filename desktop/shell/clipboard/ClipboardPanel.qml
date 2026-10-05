import "../theme"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import "../Commons"
import "../Ui"
import "../js/ClipboardHistory.js" as ClipboardHistory

// Clipboard history panel. Watches wl-paste for text and image changes,
// persists history under the Archwarts state home, and re-copies an entry on
// activation. The capture script enforces the sensitive-content boundary.
PanelSurface {
  id: root
  panelNamespace: "archwarts-clipboard"

  readonly property string configHome: Quickshell.env("ARCHWARTS_CONFIG_HOME") ||
    (Quickshell.env("HOME") + "/.config/archwarts")
  readonly property string stateHome: Quickshell.env("ARCHWARTS_STATE_HOME") ||
    (Quickshell.env("HOME") + "/.local/state/archwarts")
  readonly property string historyPath: stateHome + "/clipboard-history.json"
  readonly property string captureScript: configHome + "/shell/clipboard/capture.sh"

  property var history: []
  property var rows: []
  property int currentIndex: 0

  function refresh() {
    root.rows = ClipboardHistory.displayRows(root.history, filter ? filter.text : "", 50)
    if (root.currentIndex >= root.rows.length) root.currentIndex = 0
  }

  function addEntry(entry) {
    var normalized = ClipboardHistory.normalizeEntry(entry)
    if (!normalized) return
    root.history = ClipboardHistory.addEntry(root.history, normalized, 500)
    historyFile.setText(JSON.stringify(root.history) + "\n")
    if (root.opened) root.refresh()
  }

  function copySelected(index) {
    if (index < 0 || index >= root.rows.length) return
    var row = root.rows[index]
    if (row.entryType === "image") {
      Util.execDetached("wl-copy --type image/png < " + Util.shellQuote(row.path))
    } else if (row.fullText) {
      Util.execDetached("printf %s " + Util.shellQuote(row.fullText) + " | wl-copy")
    }
    root.close()
  }

  function move(delta) {
    if (root.rows.length === 0) return
    root.currentIndex = (root.currentIndex + delta + root.rows.length) % root.rows.length
  }

  function clearHistory() {
    historyFile.setText("[]\n")
    root.history = []
    root.refresh()
  }

  Rectangle {
    width: Math.min(760, parent.width - Style.space(16))
    height: Math.min(560, root.rows.length * 44 + Style.space(9))
    anchors.centerIn: parent
    radius: Style.cornerRadius
    color: Theme.surface
    border.color: Theme.surfaceAlt
    border.width: 1

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.space(3)
      spacing: Style.space(2)

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Style.space(10)
        radius: Style.cornerRadius
        color: Theme.surfaceAlt

        TextInput {
          id: filter
          anchors.fill: parent
          anchors.leftMargin: Style.space(3)
          anchors.rightMargin: Style.space(3)
          verticalAlignment: Text.AlignVCenter
          color: Theme.text
          font.family: Style.font.family
          font.pixelSize: Style.heading.pixelSize
          clip: true
        }
      }

      ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: root.rows
        currentIndex: root.currentIndex

        delegate: Rectangle {
          required property int index
          required property var modelData
          width: list.width
          height: 44
          radius: Style.cornerRadius
          color: index === root.currentIndex ? Theme.accent : "transparent"

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Style.space(3)
            anchors.rightMargin: Style.space(3)
            spacing: Style.space(2)

            Image {
              Layout.preferredWidth: modelData.previewImage ? Style.space(8) : 0
              Layout.preferredHeight: Style.space(8)
              source: modelData.previewImage ? ("file://" + modelData.previewImage) : ""
              fillMode: Image.PreserveAspectFit
              asynchronous: true
            }

            Text {
              Layout.fillWidth: true
              text: modelData.previewText
              elide: Text.ElideRight
              color: index === root.currentIndex ? Theme.background : Theme.text
              font.family: Style.font.family
              font.pixelSize: Style.title.pixelSize
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
              root.currentIndex = index
              root.copySelected(index)
            }
          }
        }
      }

      Keys.priority: Keys.BeforeItem
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) { root.close(); event.accepted = true }
        else if (event.key === Qt.Key_Down) { root.move(1); event.accepted = true }
        else if (event.key === Qt.Key_Up) { root.move(-1); event.accepted = true }
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.copySelected(root.currentIndex); event.accepted = true }
        else if (event.key === Qt.Key_Delete && event.modifiers & Qt.ShiftModifier) { root.clearHistory(); event.accepted = true }
      }
    }
  }

  Connections {
    target: filter
    function onTextChanged() { root.refresh() }
  }

  FileView {
    id: historyFile
    path: root.historyPath
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: { root.history = ClipboardHistory.parseHistory(text()); root.refresh() }
    onLoadFailed: { root.history = []; root.refresh() }
  }

  onOpenedChanged: {
    if (root.opened) {
      filter.text = ""
      root.currentIndex = 0
      root.refresh()
      filter.forceActiveFocus()
    }
  }

  // Capture watchers. Reap stale watchers from a previous shell instance, then
  // watch text and image clipboard types. Each change emits a JSON entry that
  // is added to history. The capture script skips sensitive content.
  Process {
    id: initProc
    command: ["bash", "-c", "pkill -f 'wl-paste .*--watch .*clipboard/capture\\.sh' 2>/dev/null || true"]
    onExited: {
      textWatch.running = true
      imageWatch.running = true
    }
  }

  Process {
    id: textWatch
    command: ["bash", "-c", "exec wl-paste --type text --watch " + Util.shellQuote(root.captureScript) + " text"]
    onExited: restartTimer.restart()
    stdout: SplitParser {
      onRead: function(data) { root.addEntry(ClipboardHistory.parseEntryJson(data)) }
    }
  }

  Process {
    id: imageWatch
    command: ["bash", "-c", "exec wl-paste --type image/png --watch " + Util.shellQuote(root.captureScript) + " image/png"]
    onExited: restartTimer.restart()
    stdout: SplitParser {
      onRead: function(data) { root.addEntry(ClipboardHistory.parseEntryJson(data)) }
    }
  }

  Timer {
    id: restartTimer
    interval: 1000
    repeat: false
    onTriggered: {
      if (!textWatch.running) textWatch.running = true
      if (!imageWatch.running) imageWatch.running = true
    }
  }

  Component.onCompleted: initProc.running = true
}