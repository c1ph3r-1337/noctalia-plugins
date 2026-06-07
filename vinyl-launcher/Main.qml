import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
    id: root
    property var pluginApi: null

    IpcHandler {
        target: "plugin:vinyl-launcher"

        function space() {
            Logger.d("Vinyl Launcher", "Opening space launcher through IPC...")
            if (pluginApi) {
                pluginApi.togglePanel(null, null)
            }
        }
    }
}
