import QtQuick
import Quickshell
import qs.Commons
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null
    property var screen: pluginApi ? pluginApi.panelOpenScreen : null

    readonly property var geometryPlaceholder: core
    readonly property bool allowAttach: false

    property real contentPreferredWidth: Math.round(450 * Style.uiScaleRatio)
    property real contentPreferredHeight: contentPreferredWidth

    anchors.fill: parent

    VinylCore {
        id: core
        anchors.fill: parent
        screen: root.screen
        isOpen: pluginApi ? (pluginApi.panelOpenScreen !== null) : false

        onRequestClose: {
            if (pluginApi && root.screen) {
                pluginApi.closePanel(root.screen)
            }
        }

        onRequestCloseImmediately: {
            if (pluginApi && root.screen) {
                pluginApi.closePanel(root.screen)
            }
        }
    }
}
