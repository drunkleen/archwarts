import "../theme"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import "../Commons"
import "../Ui"
import "../js/AppSearch.js" as AppSearch

// Application launcher: searchable desktop-entry list with keyboard
// navigation. Launches through `archwarts launch-app` (gtk-launch resolver).
PanelSurface {
  id: root
  panelNamespace: "archwarts-launcher"

  Rectangle {
    width: Math.min(680, parent.width - Style.space(16))
    height: Math.min(560, root.entries.length * 44 + Style.space(9))
    anchors.centerIn: parent
    radius: Style.cornerRadius
    color: Theme.surface
    border.color: Theme.surfaceAlt
    border.width: 1

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.space(3)
      spacing: Style.space(2)

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Style.space(11)
        radius: Style.cornerRadius
        color: Theme.surfaceAlt

        TextInput {
          id: query
          anchors.fill: parent
          anchors.leftMargin: Style.space(3)
          anchors.rightMargin: Style.space(3)
          verticalAlignment: Text.AlignVCenter
          color: Theme.text
          font.family: Style.font.family
          font.pixelSize: Style.heading.pixelSize
          clip: true
        }
      }

      ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: root.entries
        currentIndex: root.currentIndex

        delegate: Rectangle {
          required property int index
          required property var modelData
          width: list.width
          height: 44
          radius: Style.cornerRadius
          color: index === root.currentIndex ? Theme.accent : "transparent"

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Style.space(3)
            anchors.rightMargin: Style.space(3)
            spacing: Style.space(2)

            Image {
              Layout.preferredWidth: Style.space(8)
              Layout.preferredHeight: Style.space(8)
              source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
              fillMode: Image.PreserveAspectFit
              asynchronous: true
            }

            Text {
              Layout.fillWidth: true
              text: AppSearch.entryName(modelData)
              elide: Text.ElideRight
              color: index === root.currentIndex ? Theme.background : Theme.text
              font.family: Style.font.family
              font.pixelSize: Style.title.pixelSize
            }

            Text {
              text: AppSearch.entrySubtext(modelData)
              elide: Text.ElideRight
              color: index === root.currentIndex ? Theme.background : Theme.textMuted
              font.family: Style.font.family
              font.pixelSize: Style.body.pixelSize
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
              root.currentIndex = index
              root.launchCurrent()
            }
          }
        }
      }
    }

    Keys.priority: Keys.BeforeItem
    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_Escape) { root.close(); event.accepted = true }
      else if (event.key === Qt.Key_Down) { root.move(1); event.accepted = true }
      else if (event.key === Qt.Key_Up) { root.move(-1); event.accepted = true }
      else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.launchCurrent(); event.accepted = true }
    }
  }

  property var entries: []
  property int currentIndex: 0
  readonly property int matchCount: root.entries.length

  Connections {
    target: query
    function onTextChanged() { root.refresh() }
  }

  Connections {
    target: DesktopEntries.applications
    function onValuesChanged() { if (root.opened) root.refresh() }
  }

  function refresh() {
    var queryText = query ? query.text : ""
    root.entries = AppSearch.sortedEntries(DesktopEntries.applications.values, queryText, null)
    if (root.currentIndex >= root.entries.length) root.currentIndex = 0
  }

  function move(delta) {
    if (root.entries.length === 0) return
    root.currentIndex = (root.currentIndex + delta + root.entries.length) % root.entries.length
  }

  function launchCurrent() {
    if (root.currentIndex < 0 || root.currentIndex >= root.entries.length) return
    var entry = root.entries[root.currentIndex]
    var id = String(entry.id || "")
    if (!id) return
    root.close()
    Util.execDetached("archwarts launch-app " + Util.shellQuote(id))
  }

  onOpenedChanged: {
    if (root.opened) {
      query.text = ""
      root.currentIndex = 0
      root.refresh()
      query.forceActiveFocus()
    }
  }
}