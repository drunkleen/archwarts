import "../../Commons"
import "../../theme"
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

// Status indicators: volume, battery, and notification bell. Clicking opens
// the corresponding panel through the injected shell owner.
Item {
  id: root

  property var shell: null

  implicitWidth: row.implicitWidth
  implicitHeight: Style.barSize

  readonly property var sink: Pipewire.defaultAudioSink

  function glyphForSink(sink) {
    if (!sink) return "\uF028"
    if (sink.volume >= 0.66) return "\uF028"
    if (sink.volume >= 0.33) return "\uF027"
    if (sink.volume > 0) return "\uF026"
    return "\uF026"
  }

  RowLayout {
    id: row
    anchors.fill: parent
    spacing: Style.space(2)

    Rectangle {
      Layout.preferredWidth: Style.barSize + Style.space(4)
      Layout.preferredHeight: Style.barSize - Style.space(4)
      radius: Style.cornerRadius
      color: hover1.hovered ? Theme.surfaceAlt : "transparent"

      Text {
        anchors.centerIn: parent
        text: root.sink && root.sink.muted ? "\uF031" : root.glyphForSink(root.sink)
        color: Theme.text
        font.family: Style.font.family
        font.pixelSize: Style.title.pixelSize
      }

      MouseArea {
        id: hover1
        anchors.fill: parent
        hoverEnabled: true
        onClicked: if (root.shell && root.shell.audio) root.shell.audio.toggle()
      }
    }

    Rectangle {
      Layout.preferredWidth: Style.barSize
      Layout.preferredHeight: Style.barSize - Style.space(4)
      radius: Style.cornerRadius
      color: hover2.hovered ? Theme.surfaceAlt : "transparent"

      Text {
        anchors.centerIn: parent
        text: {
          var b = UPower.battery
          if (!b) return "\uF240"
          var icon = "\uF240"
          if (b.percent >= 90) icon = "\uF240"
          else if (b.percent >= 70) icon = "\uF241"
          else if (b.percent >= 40) icon = "\uF242"
          else if (b.percent >= 20) icon = "\uF243"
          else icon = "\uF244"
          return b.charging ? "\uF0E7" : icon
        }
        color: Theme.text
        font.family: Style.font.family
        font.pixelSize: Style.title.pixelSize
      }

      MouseArea {
        id: hover2
        anchors.fill: parent
        hoverEnabled: true
        onClicked: if (root.shell && root.shell.menu) root.shell.menu.toggle()
      }
    }

    Rectangle {
      Layout.preferredWidth: Style.barSize
      Layout.preferredHeight: Style.barSize - Style.space(4)
      radius: Style.cornerRadius
      color: hover3.hovered ? Theme.surfaceAlt : "transparent"

      Text {
        anchors.centerIn: parent
        text: "\uF0F3"
        color: Theme.text
        font.family: Style.font.family
        font.pixelSize: Style.title.pixelSize
      }

      MouseArea {
        id: hover3
        anchors.fill: parent
        hoverEnabled: true
        onClicked: if (root.shell && root.shell.notifications) root.shell.notifications.toggle()
      }
    }
  }
}