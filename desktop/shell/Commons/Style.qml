pragma Singleton
import QtQuick

// Archwarts style metrics. Font family follows fontconfig "monospace".
QtObject {
  id: root

  readonly property FontLoader fontLoader: FontLoader {
    source: "/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf"
  }

  readonly property font font: Qt.font({ family: fontLoader.name || "monospace" })

  property int spacingBase: 4
  function space(n) { return n * spacingBase }

  readonly property int cornerRadius: 10
  readonly property int barSize: 28
  readonly property int panelPadding: space(5)

  readonly property font body: Qt.font({ family: font.family, pixelSize: 13 })
  readonly property font title: Qt.font({ family: font.family, pixelSize: 14 })
  readonly property font heading: Qt.font({ family: font.family, pixelSize: 17 })
}