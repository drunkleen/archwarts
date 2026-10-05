import Quickshell
import Quickshell.Io
import QtQuick

import "../Commons"

// Lock screen integration. The Archwarts lock target invokes hyprlock, the
// standard Wayland lock screen, rather than embedding a bespoke screen.
Item {
  id: root

  function lock() {
    Util.execDetached("hyprlock")
  }
}