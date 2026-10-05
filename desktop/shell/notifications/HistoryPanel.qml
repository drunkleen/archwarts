import "../theme"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import "../Commons"
import "../Ui"
import "../js/NotificationHistory.js" as NotifHistory

// Notification history panel. Reads the persisted history file and renders a
// dismissible list. Opened and closed by the notification service.
PanelSurface {
  id: root
  panelNamespace: "archwarts-notification-history"

  readonly property string stateHome: Quickshell.env("ARCHWARTS_STATE_HOME") ||
    (Quickshell.env("HOME") + "/.local/state/archwarts")
  readonly property string historyPath: stateHome + "/notifications-history.json"

  property var history: []
  property var rows: []
  property int currentIndex: 0

  function refresh() {
    var parsed = NotifHistory.parseHistory(historyFile.text())
    root.history = parsed
    root.rows = NotifHistory.displayRows(parsed, "", 100)
  }

  function clearHistory() {
    historyFile.setText("[]\n")
    root.refresh()
  }

  Rectangle {
    width: Math.min(520, parent.width - Style.space(16))
    height: Math.min(600, root.rows.length * 72 + 56)
    anchors.centerIn: parent
    radius: Style.cornerRadius
    color: Theme.surface
    border.color: Theme.surfaceAlt
    border.width: 1

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.space(3)
      spacing: Style.space(2)

      RowLayout {
        Layout.fillWidth: true
        Text {
          Layout.fillWidth: true
          text: "Notifications"
          color: Theme.text
          font.family: Style.font.family
          font.pixelSize: Style.heading.pixelSize
        }
        Rectangle {
          Layout.preferredWidth: Style.space(9)
          Layout.preferredHeight: Style.space(9)
          radius: Style.cornerRadius
          color: clearHover.hovered ? Theme.negative : Theme.surfaceAlt
          Text {
            anchors.centerIn: parent
            text: "\uF00D"
            color: Theme.text
            font.family: Style.font.family
          }
          MouseArea {
            id: clearHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.clearHistory()
          }
        }
      }

      ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: root.rows

        delegate: Rectangle {
          required property int index
          required property var modelData
          width: list.width
          height: 68
          radius: Style.cornerRadius
          color: index === root.currentIndex ? Theme.surfaceAlt : "transparent"

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.space(2)
            spacing: Style.space(1)

            RowLayout {
              Layout.fillWidth: true
              Text {
                Layout.fillWidth: true
                text: modelData.summary
                elide: Text.ElideRight
                color: Theme.text
                font.family: Style.font.family
                font.pixelSize: Style.title.pixelSize
              }
              Text {
                text: modelData.timeLabel
                color: Theme.textMuted
                font.family: Style.font.family
                font.pixelSize: Style.body.pixelSize
              }
            }
            Text {
              Layout.fillWidth: true
              text: modelData.body
              elide: Text.ElideRight
              wrapMode: Text.Wrap
              color: Theme.textMuted
              font.family: Style.font.family
              font.pixelSize: Style.body.pixelSize
            }
          }
        }

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) { root.close(); event.accepted = true }
          else if (event.key === Qt.Key_Delete && event.modifiers & Qt.ShiftModifier) { root.clearHistory(); event.accepted = true }
        }
      }
    }
  }

  FileView {
    id: historyFile
    path: root.historyPath
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.refresh()
    onLoadFailed: root.rows = []
  }

  onOpenedChanged: {
    if (root.opened) root.refresh()
  }
}