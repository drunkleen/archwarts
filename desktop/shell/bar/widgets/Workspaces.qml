import "../../Commons"
import "../../theme"
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// Hyprland workspace pager. Renders one button per known workspace; active
// and occupied states are highlighted. Clicking switches workspace.
Item {
  id: root

  readonly property color text: Theme.text
  readonly property color activeText: Theme.background
  readonly property color activeBackground: Theme.accent
  readonly property color occupiedText: Theme.accent

  implicitWidth: row.implicitWidth
  implicitHeight: Style.barSize

  RowLayout {
    id: row
    anchors.fill: parent
    spacing: Style.space(2)

    Repeater {
      model: Hyprland.workspaces.values

      Rectangle {
        required property var modelData
        Layout.preferredWidth: 26
        Layout.preferredHeight: Style.barSize - Style.space(4)
        radius: Style.cornerRadius
        color: modelData.active ? root.activeBackground : "transparent"

        Text {
          anchors.centerIn: parent
          text: String(modelData.id)
          color: modelData.active ? root.activeText : (modelData.toplevels.values.length > 0 ? root.occupiedText : root.text)
          font.family: Style.font.family
          font.pixelSize: Style.body.pixelSize
        }

        MouseArea {
          anchors.fill: parent
          onClicked: Hyprland.dispatch("workspace", String(modelData.id))
        }
      }
    }
  }
}