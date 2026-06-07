import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Services.Control

Item {
    id: root
    property var pluginApi: null

    // FIX: Put these in Main.qml as well to defeat the QML race condition
    readonly property bool allowAttach: false
    readonly property bool panelAnchorHorizontalCenter: true
    readonly property bool panelAnchorVerticalCenter: true
    readonly property color panelBackgroundColor: "transparent"

    IpcHandler {
        target: "plugin:vinyl-launcher"

        function space() {
            Logger.d("Vinyl Launcher", "Opening space launcher through IPC...")
            if (pluginApi) {
                IPCService.screenDetector.withCurrentScreen(screen => {
                    pluginApi.togglePanel(screen, null)
                }, false)
            }
        }
    }
}
