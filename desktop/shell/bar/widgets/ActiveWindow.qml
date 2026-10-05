import "../../Commons"
import "../../theme"
import Quickshell
import Quickshell.Hyprland
import QtQuick

// Title of the currently focused window.
Item {
  id: root

  implicitWidth: Math.min(360, titleText.implicitWidth)
  implicitHeight: Style.barSize

  Text {
    id: titleText
    anchors.centerIn: parent
    text: Hyprland.activeWindow ? Hyprland.activeWindow.title : ""
    color: Theme.text
    font.family: Style.font.family
    font.pixelSize: Style.body.pixelSize
    elide: Text.ElideRight
    maximumLineCount: 1
  }
}