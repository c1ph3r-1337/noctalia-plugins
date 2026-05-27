import QtQuick
import Quickshell
import qs.Commons

// Noctalia Plugin Main Entry
Item {
  id: root

  // Reference to the plugin API provided by Noctalia
  property var pluginApi: null

  // Plugin state
  property bool isOpen: false

  function init() {
    Logger.i("VinylLauncher", "Plugin initialized");
  }

  // Handle IPC calls for toggle
  function toggle() {
    pluginApi.togglePanel("VinylLauncher");
  }

  // Setup the panel on the current screen
  Component.onCompleted: {
    // Note: Panels in plugins are usually managed via manifest/Noctalia internal
    // but we can register handlers here.
  }
}
