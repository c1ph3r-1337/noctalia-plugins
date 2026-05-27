import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets

import qs.Commons
import qs.Modules.Panels.Launcher.Providers
import qs.Services.Keyboard
import qs.Services.UI
import qs.Widgets

// Noctalia Plugin Version of Vinyl Launcher
Rectangle {
  id: root
  anchors.fill: parent
  color: "transparent"

  // Plugin API property (automatically injected by Noctalia)
  property var pluginApi: null
  
  // Shortcuts to settings
  readonly property var cfg: pluginApi?.pluginSettings || ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  
  readonly property real diskScale: cfg.diskScale ?? defaults.diskScale ?? 0.7
  readonly property int iconSize: cfg.iconSize ?? defaults.iconSize ?? 64

  // State
  property string searchText: ""
  property var results: []
  property int selectedIndex: 0

  // Use Noctalia's native apps provider for best results
  ApplicationsProvider {
    id: appsProvider
    onEntriesChanged: root.updateResults()
  }

  function updateResults() {
    results = appsProvider.getResults(searchText);
    selectedIndex = 0;
  }

  onSearchTextChanged: updateResults()

  function activate() {
    const idx = diskView.currentIndex;
    if (results && results.length > 0 && idx >= 0 && idx < results.length) {
      const item = results[idx];
      if (item && item.onActivate) {
        item.onActivate();
      }
      // Note: item.onActivate in Noctalia already handles closing panels
    }
  }

  function handleKeyPress(event) {
    if (Keybinds.checkKey(event, 'escape', Settings)) {
      pluginApi.togglePanel("VinylLauncher");
      event.accepted = true;
      return;
    }

    if (Keybinds.checkKey(event, 'enter', Settings) || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      activate();
      event.accepted = true;
      return;
    }

    if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
      inertiaTimer.stop();
      offsetAnim.stop();
      offsetAnim.to = Math.round(diskView.offset) - 1;
      offsetAnim.start();
      event.accepted = true;
    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
      inertiaTimer.stop();
      offsetAnim.stop();
      offsetAnim.to = Math.round(diskView.offset) + 1;
      offsetAnim.start();
      event.accepted = true;
    }
  }

  // Search Input (Hidden)
  NTextInput {
    id: searchInput
    width: 0; height: 0; opacity: 0
    text: root.searchText
    onTextChanged: root.searchText = text
    
    Component.onCompleted: {
      if (inputItem) {
        inputItem.forceActiveFocus();
        inputItem.Keys.onPressed.connect((event) => root.handleKeyPress(event));
      }
    }
  }

  // Visuals
  Rectangle {
    id: outerRing
    anchors.centerIn: parent
    width: Math.min(parent.width, parent.height) * root.diskScale
    height: width
    radius: width / 2
    color: Qt.alpha(Color.mSurface, 0.4)
    border.color: Qt.alpha(Color.mOutline, 0.3)
    border.width: 1
    
    // Sub-ring for depth
    Rectangle {
      anchors.fill: parent
      anchors.margins: 2
      radius: width / 2
      color: "transparent"
      border.color: Qt.alpha("#ffffff", 0.05)
      border.width: 1
    }

    Rectangle {
      id: innerCircle
      anchors.centerIn: parent
      width: parent.width * 0.55
      height: width
      radius: width / 2
      color: Qt.alpha(Color.mSurface, 0.8)
      z: 5
      border.color: Color.mPrimary
      border.width: 2

      ColumnLayout {
        anchors.centerIn: parent
        spacing: Style.marginS
        width: parent.width * 0.8

        Item {
          Layout.preferredWidth: parent.width * 0.55
          Layout.preferredHeight: width
          Layout.alignment: Qt.AlignHCenter
          IconImage {
            anchors.fill: parent
            source: diskView.currentItemData ? ThemeIcons.iconFromName(diskView.currentItemData.icon, "application-x-executable") : ""
            asynchronous: true
          }
        }

        NText {
          Layout.fillWidth: true
          text: diskView.currentItemData ? diskView.currentItemData.name : "Loading..."
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideRight
          font.weight: Style.fontWeightBold
          pointSize: Style.fontSizeL
          color: Color.mOnSurface
        }
      }
    }

    PathView {
      id: diskView
      anchors.fill: parent
      model: root.results
      z: 10
      interactive: false
      
      property var currentItemData: model && model.length > 0 ? model[currentIndex] : null

      NumberAnimation {
        id: offsetAnim
        target: diskView
        property: "offset"
        duration: cfg.animationDuration ?? 350
        easing.type: Easing.OutQuart
      }

      property real velocity: 0
      Timer {
        id: inertiaTimer
        interval: 16; repeat: true
        onTriggered: {
          diskView.offset += diskView.velocity
          diskView.velocity *= 0.96
          if (Math.abs(diskView.velocity) < 0.01) {
            diskView.velocity = 0; diskView.offset = Math.round(diskView.offset); stop()
          }
        }
      }

      pathItemCount: Math.min(model.length, 12)
      preferredHighlightBegin: 0.5; preferredHighlightEnd: 0.5
      highlightRangeMode: PathView.StrictlyEnforceRange

      path: Path {
        startX: outerRing.width / 2; startY: outerRing.height * 0.1
        PathAngleArc {
          centerX: outerRing.width / 2; centerY: outerRing.height / 2
          radiusX: outerRing.width * 0.4; radiusY: outerRing.height * 0.4
          startAngle: -90; sweepAngle: 360
        }
      }

      delegate: Item {
        width: root.iconSize * Style.uiScaleRatio
        height: width
        scale: PathView.isCurrentItem ? 1.3 : 0.8
        opacity: PathView.isCurrentItem ? 0.0 : 1.0
        Behavior on opacity { NumberAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 150 } }

        IconImage {
          anchors.fill: parent
          source: modelData.icon ? ThemeIcons.iconFromName(modelData.icon, "application-x-executable") : ""
        }
      }
    }
  }

  // Search Bar
  NBox {
    anchors.top: outerRing.bottom
    anchors.topMargin: Style.marginL
    anchors.horizontalCenter: parent.horizontalCenter
    width: 280 * Style.uiScaleRatio; height: 40 * Style.uiScaleRatio
    radius: Style.radiusM
    color: Qt.alpha(Color.mSurface, 0.8)
    visible: root.searchText !== ""
    border.color: Qt.alpha(Color.mOutline, 0.5)
    border.width: 1

    NText {
      anchors.centerIn: parent
      text: "Search: " + root.searchText
      color: Color.mOnSurface
      font.italic: true
      pointSize: Style.fontSizeS
    }
  }
}
