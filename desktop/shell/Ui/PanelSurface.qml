import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

// Full-screen overlay panel with scrim and outside-click dismissal. Panels
// declare their centered card as a child; the scrim handles the rest.
PanelWindow {
  id: root

  property string panelNamespace: "archwarts-panel"
  property bool opened: false

  visible: opened
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: panelNamespace
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  Rectangle {
    anchors.fill: parent
    color: "black"
    opacity: root.opened ? 0.4 : 0
    Behavior on opacity { NumberAnimation { duration: 150 } }
    MouseArea {
      anchors.fill: parent
      onClicked: root.close()
    }
  }

  default property alias content: contentItem.data

  Item {
    id: contentItem
    anchors.fill: parent
  }

  function open() { root.opened = true }
  function close() { root.opened = false }
  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }
}