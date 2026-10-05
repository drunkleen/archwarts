import "../theme"
import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

import "../Commons"
import "../Ui"

// Bluetooth panel: adapter power toggle and paired device list.
PanelSurface {
  id: root
  panelNamespace: "archwarts-bluetooth"

  Rectangle {
    width: Math.min(440, parent.width - Style.space(16))
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

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Style.space(8)
        radius: Style.cornerRadius
        color: hover.hovered ? Theme.surfaceAlt : "transparent"

        Text {
          anchors.centerIn: parent
          text: "Bluetooth: " + (root.adapterPowered ? "on" : "off")
          color: Theme.text
          font.family: Style.font.family
          font.pixelSize: Style.title.pixelSize
        }

        MouseArea {
          id: hover
          anchors.fill: parent
          hoverEnabled: true
          onClicked: {
            if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.powered = !Bluetooth.defaultAdapter.powered
          }
        }
      }

      Text {
        text: "Devices"
        color: Theme.textMuted
        font.family: Style.font.family
        font.pixelSize: Style.body.pixelSize
      }

      Repeater {
        model: Bluetooth.devices.values

        Rectangle {
          required property var modelData
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
              text: modelData.name || modelData.id || "Device"
              elide: Text.ElideRight
              color: Theme.text
              font.family: Style.font.family
              font.pixelSize: Style.title.pixelSize
            }

            Text {
              text: modelData.connected ? "connected" : (modelData.paired ? "paired" : "")
              color: modelData.connected ? Theme.positive : Theme.textMuted
              font.family: Style.font.family
              font.pixelSize: Style.body.pixelSize
            }
          }

          MouseArea {
            anchors.fill: parent
            onClicked: modelData.connect()
          }
        }
      }
    }
  }

  readonly property bool adapterPowered: Bluetooth.defaultAdapter ? (Bluetooth.defaultAdapter.powered === true) : false
}