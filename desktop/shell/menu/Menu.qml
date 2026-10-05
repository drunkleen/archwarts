import "../theme"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import "../Commons"
import "../Ui"

// Main Archwarts menu: quick actions for the approved defaults and session
// controls. Power actions are explicit and only invoked by click.
PanelSurface {
  id: root
  panelNamespace: "archwarts-menu"

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

      Repeater {
        model: root.actions

        Rectangle {
          required property var modelData
          Layout.fillWidth: true
          Layout.preferredHeight: 46
          radius: Style.cornerRadius
          color: hover.hovered ? Theme.accent : "transparent"

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Style.space(3)
            anchors.rightMargin: Style.space(3)
            spacing: Style.space(3)

            Text {
              text: modelData.glyph
              color: hover.hovered ? Theme.background : Theme.text
              font.family: Style.font.family
              font.pixelSize: Style.heading.pixelSize
            }

            Text {
              Layout.fillWidth: true
              text: modelData.label
              color: hover.hovered ? Theme.background : Theme.text
              font.family: Style.font.family
              font.pixelSize: Style.title.pixelSize
            }
          }

          MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.runAction(modelData)
          }
        }
      }
    }

    Keys.priority: Keys.BeforeItem
    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_Escape) { root.close(); event.accepted = true }
    }
  }

  property var actions: [
    { glyph: "\uF0AC", label: "Firefox", command: "archwarts launch-app firefox" },
    { glyph: "\uF07C", label: "Dolphin", command: "archwarts launch-app dolphin" },
    { glyph: "\uF023", label: "Bitwarden", command: "archwarts launch-app bitwarden" },
    { glyph: "\uF109", label: "Terminal", command: "foot" },
    { glyph: "\uF013", label: "System Settings", command: "archwarts launch-app systemsettings" },
    { glyph: "\uF09C", label: "Lock screen", command: "hyprlock" },
    { glyph: "\uF011", label: "Log out", command: "hyprctl dispatch exit" }
  ]

  function runAction(action) {
    if (!action || !action.command) return
    root.close()
    Util.execDetached(action.command)
  }
}