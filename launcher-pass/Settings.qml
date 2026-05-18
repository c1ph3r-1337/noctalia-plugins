import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property string editStorePath: cfg.storePath ?? defaults.storePath ?? ""

  spacing: Style.marginL

  NTextInput {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.storePath.label") || "Password Store Path"
    description: pluginApi?.tr("settings.storePath.desc") || "Custom path to the password store (default: ~/.password-store)"
    text: root.editStorePath
    onTextChanged: root.editStorePath = text
  }

  function saveSettings() {
    if (!pluginApi) return;
    pluginApi.pluginSettings.storePath = root.editStorePath;
    pluginApi.saveSettings();
  }
}