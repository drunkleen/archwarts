import "../theme"
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

import "../Commons"
import "../Ui"

// Audio panel: default sink/source control and per-node volume. Uses the
// standard Quickshell Pipewire service.
PanelSurface {
  id: root
  panelNamespace: "archwarts-audio"

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource

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

      Text {
        text: "Output"
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
            text: root.sink ? root.sink.description : "No sink"
            elide: Text.ElideRight
            color: Theme.text
            font.family: Style.font.family
            font.pixelSize: Style.title.pixelSize
          }

          Text {
            text: root.sink ? Math.round(root.sink.volume * 100) + "%" : ""
            color: Theme.textMuted
            font.family: Style.font.family
            font.pixelSize: Style.body.pixelSize
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Style.space(10)
        radius: Style.cornerRadius
        color: Theme.surfaceAlt

        Text {
          anchors.centerIn: parent
          text: "Volume"
          color: Theme.text
          font.family: Style.font.family
          font.pixelSize: Style.body.pixelSize
        }

        MouseArea {
          anchors.fill: parent
          onWheel: function(wheel) {
            if (!root.sink) return
            var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
            root.sink.volume = Math.max(0, Math.min(1, root.sink.volume + delta))
            root.sink.muted = false
          }
          onClicked: if (root.sink) root.sink.muted = !root.sink.muted
        }
      }

      Item { Layout.preferredHeight: Style.space(1) }

      Text {
        text: "Input"
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
            text: root.source ? root.source.description : "No source"
            elide: Text.ElideRight
            color: Theme.text
            font.family: Style.font.family
            font.pixelSize: Style.title.pixelSize
          }
        }
      }
    }
  }
}