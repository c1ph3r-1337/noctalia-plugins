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

    readonly property bool panelAnchorHorizontalCenter: true
    readonly property bool panelAnchorVerticalCenter: true
    readonly property color panelBackgroundColor: "transparent"

    property real contentPreferredWidth: Math.round(450 * Style.uiScaleRatio)
    property real contentPreferredHeight: contentPreferredWidth

    // Provide explicit implicit bounds so SmartPanel does not collapse it if it somehow attaches
    implicitWidth: contentPreferredWidth
    implicitHeight: contentPreferredHeight

    VinylCore {
        id: core
        anchors.fill: parent
        
        // Explicitly pass pluginApi to VinylCore so it can access settings and functions
        pluginApi: root.pluginApi
        
        isOpen: root.pluginApi ? (root.pluginApi.panelOpenScreen !== null) : false
    }
}
