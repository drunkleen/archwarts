import "../../Commons"
import "../../theme"
import Quickshell
import QtQuick

// Date and time. Refreshes every second.
Item {
  id: root

  readonly property string text: clockText.text

  implicitWidth: clockText.implicitWidth
  implicitHeight: Style.barSize

  Text {
    id: clockText
    anchors.centerIn: parent
    color: Theme.text
    font.family: Style.font.family
    font.pixelSize: Style.body.pixelSize

    Timer {
      interval: 1000
      running: true
      repeat: true
      onTriggered: parent.text = root.format()
    }
  }

  Component.onCompleted: clockText.text = root.format()

  function format() {
    var d = new Date()
    return d.toLocaleString(Qt.locale(), "ddd d MMM HH:mm")
  }
}