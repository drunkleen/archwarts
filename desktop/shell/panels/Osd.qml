import "../theme"
import "../Commons"
import Quickshell
import Quickshell.Wayland
import QtQuick

// OSD overlay: a transient centered pill showing icon + message. Shown via the
// shell IPC `osd` target with a { icon, message, duration } payload.
PanelWindow {
  id: root

  property bool visibleOsd: false
  property string iconText: ""
  property string messageText: ""

  visible: root.visibleOsd
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "archwarts-osd"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  anchors { top: true; bottom: true; left: true; right: true }

  Rectangle {
    anchors.centerIn: parent
    width: pill.implicitWidth + Style.space(6)
    height: pill.implicitHeight + Style.space(4)
    radius: Style.cornerRadius
    color: Theme.surface
    border.color: Theme.surfaceAlt
    border.width: 1
    opacity: root.visibleOsd ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 120 } }

    Row {
      id: pill
      anchors.centerIn: parent
      spacing: Style.space(2)

      Text {
        text: root.iconText
        color: Theme.accent
        font.family: Style.font.family
        font.pixelSize: Style.heading.pixelSize
        verticalAlignment: Text.AlignVCenter
      }

      Text {
        text: root.messageText
        color: Theme.text
        font.family: Style.font.family
        font.pixelSize: Style.heading.pixelSize
        verticalAlignment: Text.AlignVCenter
      }
    }
  }

  Timer {
    id: hideTimer
    interval: 1500
    onTriggered: root.visibleOsd = false
  }

  function show(payload) {
    root.iconText = String((payload && payload.icon) || "\uF05A")
    root.messageText = String((payload && payload.message) || "")
    root.visibleOsd = true
    hideTimer.restart()
  }
}