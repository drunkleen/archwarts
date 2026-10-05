import "../theme"
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import "../Commons"
import "../Ui"
import "../js/NotificationHistory.js" as NotifHistory

// Archwarts notification service. Renders transient popups in the top-right,
// persists history under the Archwarts state home, and exposes a DND toggle.
// The DBus daemon is the Quickshell.Notifications singleton referenced here.
Item {
  id: root

  readonly property string stateHome: Quickshell.env("ARCHWARTS_STATE_HOME") ||
    (Quickshell.env("HOME") + "/.local/state/archwarts")
  readonly property string historyPath: stateHome + "/notifications-history.json"

  property bool doNotDisturb: false
  property bool opened: false
  property var history: []
  readonly property var liveNotifications: NotificationServer.trackedNotifications ? NotificationServer.trackedNotifications : null

  function toggle() { root.opened ? root.close() : root.open() }
  function open() {
    root.opened = true
    root.history = NotifHistory.parseHistory(historyFile.text())
    if (historyPanel) historyPanel.open()
  }
  function close() {
    root.opened = false
    if (historyPanel) historyPanel.close()
  }

  function recordNotification(n) {
    if (root.doNotDisturb) {
      n.dismiss()
      return
    }
    root.history = NotifHistory.addNotification(root.history, {
      id: n.id,
      appName: n.appName,
      appIcon: n.appIcon,
      summary: n.summary,
      body: n.body,
      urgency: String(n.urgency),
      actions: Array.isArray(n.actions) ? n.actions.slice() : [],
      timestamp: Date.now()
    }, 200)
    historyFile.setText(JSON.stringify(root.history) + "\n")
  }



  Connections {
    target: NotificationServer
    function onNotification(notification) { root.recordNotification(notification) }
  }

  // Popup stack: a top-right layer surface showing live notifications.
  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        required property var modelData

        anchors {
          top: true
          right: true
        }
        margins { top: Style.barSize + Style.space(2); right: Style.space(2) }
        color: "transparent"
        WlrLayershell.namespace: "archwarts-notifications"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        visible: root.liveNotifications && root.liveNotifications.count > 0

        ColumnLayout {
          spacing: Style.space(2)

          Repeater {
            model: root.liveNotifications || 0

            Rectangle {
              required property var modelData
              Layout.preferredWidth: 360
              Layout.preferredHeight: 96
              radius: Style.cornerRadius
              color: Theme.surface
              border.color: Theme.surfaceAlt
              border.width: 1

              ColumnLayout {
                anchors.fill: parent
                anchors.margins: Style.space(3)
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
                    text: modelData.appName
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

              MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: function(mouse) {
                  if (mouse.button === Qt.RightButton) modelData.dismiss()
                  else modelData.defaultAction()
                }
              }
            }
          }
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
    onLoaded: root.history = NotifHistory.parseHistory(text())
    onLoadFailed: root.history = []
    Component.onCompleted: root.history = NotifHistory.parseHistory(text())
  }

  HistoryPanel {
    id: historyPanel
  }
}