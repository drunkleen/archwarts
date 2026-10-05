import "../../Commons"
import "../../theme"
import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts

// System tray. Renders all tray icons and opens their menus on left click.
Item {
  id: root

  implicitWidth: row.implicitWidth
  implicitHeight: Style.barSize

  RowLayout {
    id: row
    anchors.fill: parent
    spacing: Style.space(1)

    Repeater {
      model: SystemTray.items.values

      Rectangle {
        required property var modelData
        Layout.preferredWidth: Style.barSize - Style.space(6)
        Layout.preferredHeight: Style.barSize - Style.space(6)
        radius: Style.cornerRadius
        color: hover.hovered ? Theme.surfaceAlt : "transparent"

        Image {
          anchors.fill: parent
          anchors.margins: Style.space(1)
          source: modelData.icon ?? ""
          fillMode: Image.PreserveAspectFit
          asynchronous: true
        }

        MouseArea {
          id: hover
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) modelData.openMenu()
            else modelData.activate()
          }
        }
      }
    }
  }
}