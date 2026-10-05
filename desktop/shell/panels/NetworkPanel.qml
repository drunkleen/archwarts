import "../theme"
import Quickshell
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts

import "../Commons"
import "../Ui"

// Network panel: primary connection info and Wi-Fi radio toggle. Display state
// comes from the standard Quickshell Networking service.
PanelSurface {
  id: root
  panelNamespace: "archwarts-network"

  readonly property var primary: Networking.primaryConnection

  Rectangle {
    width: Math.min(420, parent.width - Style.space(16))
    height: col.implicitHeight + Style.space(6)
    anchors.centerIn: parent
    radius: Style.cornerRadius
    color: Theme.surface
    border.color: Theme.surfaceAlt
    border.width: 1

    ColumnLayout {
      id: col
      anchors.fill: parent
      anchors.margins: Style.space(3)
      spacing: Style.space(2)

      Text {
        text: "Network"
        color: Theme.textMuted
        font.family: Style.font.family
        font.pixelSize: Style.body.pixelSize
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Style.space(8)
        radius: Style.cornerRadius
        color: Theme.surfaceAlt

        RowLayout {
          anchors.fill: parent
          anchors.margins: Style.space(2)
          spacing: Style.space(2)

          Text {
            Layout.fillWidth: true
            text: root.primary ? root.primary.connectionId : "Disconnected"
            elide: Text.ElideRight
            color: Theme.text
            font.family: Style.font.family
            font.pixelSize: Style.title.pixelSize
          }

          Text {
            text: root.primary ? String(root.primary.type || "").toUpperCase() : ""
            color: Theme.textMuted
            font.family: Style.font.family
            font.pixelSize: Style.body.pixelSize
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Style.space(8)
        radius: Style.cornerRadius
        color: hover.hovered ? Theme.surfaceAlt : "transparent"

        Text {
          anchors.centerIn: parent
          text: "Wi-Fi: " + (Networking.wifiEnabled ? "on" : "off")
          color: Theme.text
          font.family: Style.font.family
          font.pixelSize: Style.title.pixelSize
        }

        MouseArea {
          id: hover
          anchors.fill: parent
          hoverEnabled: true
          onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
        }
      }
    }
  }
}