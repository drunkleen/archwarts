import "../theme"
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

import "../Commons"
import "../Ui"

// Media panel: active MPRIS player controls and track info.
PanelSurface {
  id: root
  panelNamespace: "archwarts-media"

  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var active: root.players.length > 0 ? root.players[0] : null

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
        text: root.active ? (root.active.identity || "Media") : "No player"
        color: Theme.textMuted
        font.family: Style.font.family
        font.pixelSize: Style.body.pixelSize
      }

      Text {
        Layout.fillWidth: true
        text: root.active ? (root.active.trackTitle || "Nothing playing") : ""
        elide: Text.ElideRight
        color: Theme.text
        font.family: Style.font.family
        font.pixelSize: Style.heading.pixelSize
      }

      Text {
        Layout.fillWidth: true
        text: root.active && root.active.trackArtist ? root.active.trackArtist : ""
        elide: Text.ElideRight
        color: Theme.textMuted
        font.family: Style.font.family
        font.pixelSize: Style.body.pixelSize
      }

      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: Style.space(9)
        spacing: Style.space(2)

        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: Style.cornerRadius
          color: prevHover.hovered ? Theme.surfaceAlt : "transparent"
          Text {
            anchors.centerIn: parent
            text: "\uF048"
            color: Theme.text
            font.family: Style.font.family
          }
          MouseArea {
            id: prevHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: if (root.active) root.active.previous()
          }
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: Style.cornerRadius
          color: playHover.hovered ? Theme.accent : Theme.surfaceAlt
          Text {
            anchors.centerIn: parent
            text: root.active && root.active.playbackStatus === 1 ? "\uF04C" : "\uF04B"
            color: playHover.hovered ? Theme.background : Theme.text
            font.family: Style.font.family
          }
          MouseArea {
            id: playHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: if (root.active) root.active.playPause()
          }
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: Style.cornerRadius
          color: nextHover.hovered ? Theme.surfaceAlt : "transparent"
          Text {
            anchors.centerIn: parent
            text: "\uF051"
            color: Theme.text
            font.family: Style.font.family
          }
          MouseArea {
            id: nextHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: if (root.active) root.active.next()
          }
        }
      }
    }
  }
}