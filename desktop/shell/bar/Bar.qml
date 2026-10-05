import "../theme"
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

import "../Commons"

import "widgets"

// Per-monitor bar: workspaces + active window on the left, clock in the
// center, tray and status indicators on the right.
Item {
  id: root

  property var shell: null

  Variants {
    model: Quickshell.screens

    delegate: Component {
      BarPanel {
        required property var modelData
        screen: modelData
        shell: root.shell
      }
    }
  }

  component BarPanel: PanelWindow {
    id: panel

    property var shell: null
    required property var screen

    anchors {
      top: true
      left: true
      right: true
    }
    implicitHeight: Style.barSize
    color: Theme.background
    surfaceFormat.opaque: false
    WlrLayershell.namespace: "archwarts-bar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Style.space(3)
      anchors.rightMargin: Style.space(3)
      spacing: Style.space(2)

      Workspaces {
        Layout.fillHeight: true
      }

      ActiveWindow {
        Layout.leftMargin: Style.space(3)
        Layout.fillHeight: true
      }

      Item { Layout.fillWidth: true }

      Clock {
        Layout.fillHeight: true
      }

      Item { Layout.fillWidth: true }

      Tray {
        Layout.fillHeight: true
      }

      StatusIndicators {
        shell: panel.shell
        Layout.fillHeight: true
      }
    }
  }
}