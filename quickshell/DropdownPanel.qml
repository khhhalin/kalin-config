import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Quick-settings dropdown — appears above the bar on the active screen.
PanelWindow {
  id: dropdown

  property var shellRoot

  anchors {
    right: true
    bottom: true
  }

  margins {
    right: Theme.padding
    bottom: Theme.panelHeight + Theme.spacing
  }

  implicitWidth: Theme.dropdownWidth
  implicitHeight: content.implicitHeight + Theme.padding * 2
  color: Theme.transparent
  exclusionMode: ExclusionMode.Ignore

  // Close when clicking outside
  mask: Region {}

  // Track audio
  PwObjectTracker { objects: [ Pipewire.defaultAudioSink ] }

  Rectangle {
    anchors.fill: parent
    radius: Theme.dropdownRadius
    color: Theme.bgDropdown
    border.color: Theme.separator
    border.width: 1

    ColumnLayout {
      id: content
      anchors {
        fill: parent
        margins: Theme.padding
      }
      spacing: Theme.spacing

      // ── Header ──────────────────────────────────────────────────
      Text {
        text: "Quick Settings"
        color: Theme.fg
        font.pixelSize: Theme.fontSizeLarge
        font.bold: true
        Layout.bottomMargin: Theme.spacing
      }

      // ── Toggle row ──────────────────────────────────────────────
      RowLayout {
        spacing: Theme.spacing
        Layout.fillWidth: true

        // Wi-Fi toggle
        ToggleButton { label: "Wi-Fi";      icon: "network-wireless-symbolic";  cmd: "nmcli radio wifi" }
        ToggleButton { label: "Bluetooth";  icon: "bluetooth-symbolic";          cmd: "bluetoothctl show" }
        ToggleButton { label: "DND";        icon: "notifications-disabled-symbolic"; cmd: "" }
      }

      // ── Separator ──────────────────────────────────────────────
      Rectangle { Layout.fillWidth: true; height: 1; color: Theme.separator }

      // ── Volume ─────────────────────────────────────────────────
      RowLayout {
        spacing: Theme.spacing
        Layout.fillWidth: true

        Text {
          text: "Vol"
          color: Theme.fgDim
          font.pixelSize: Theme.fontSizeSmall
        }

        Slider {
          Layout.fillWidth: true
          from: 0; to: 1
          value: Pipewire.defaultAudioSink?.audio.volume ?? 0
          onMoved: {
            if (Pipewire.defaultAudioSink)
              Pipewire.defaultAudioSink.audio.volume = value;
          }
        }

        Text {
          text: `${Math.round((Pipewire.defaultAudioSink?.audio.volume ?? 0) * 100)}%`
          color: Theme.fg
          font.pixelSize: Theme.fontSizeSmall
          Layout.preferredWidth: 36
          horizontalAlignment: Text.AlignRight
        }
      }

      // ── Brightness (laptop, uses brightnessctl) ────────────────
      RowLayout {
        spacing: Theme.spacing
        Layout.fillWidth: true

        Text {
          text: "Bri"
          color: Theme.fgDim
          font.pixelSize: Theme.fontSizeSmall
        }

        Slider {
          id: brightnessSlider
          Layout.fillWidth: true
          from: 0; to: 100
          value: 50

          Component.onCompleted: brightnessProc.running = true

          onMoved: {
            brightnessSetProc.command = ["brightnessctl", "set", `${Math.round(value)}%`];
            brightnessSetProc.running = true;
          }
        }

        Text {
          text: `${Math.round(brightnessSlider.value)}%`
          color: Theme.fg
          font.pixelSize: Theme.fontSizeSmall
          Layout.preferredWidth: 36
          horizontalAlignment: Text.AlignRight
        }
      }

      // ── Separator ──────────────────────────────────────────────
      Rectangle { Layout.fillWidth: true; height: 1; color: Theme.separator }

      // ── Quick actions row ──────────────────────────────────────
      RowLayout {
        spacing: Theme.spacing
        Layout.fillWidth: true

        ActionButton { label: "Screenshot"; icon: "camera-photo-symbolic";  cmd: "grimblast copy area" }
        ActionButton { label: "Files";      icon: "system-file-manager-symbolic"; cmd: "thunar" }
        ActionButton { label: "Terminal";   icon: "utilities-terminal-symbolic";  cmd: "foot" }
        ActionButton { label: "Settings";   icon: "preferences-system-symbolic";  cmd: "xdg-open settings:" }
      }

      // ── Power row ─────────────────────────────────────────────
      RowLayout {
        spacing: Theme.spacing
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacing

        ActionButton { label: "Lock";     icon: "system-lock-screen-symbolic"; cmd: "loginctl lock-session" }
        ActionButton { label: "Suspend";  icon: "system-suspend-symbolic";     cmd: "systemctl suspend" }
        ActionButton { label: "Reboot";   icon: "system-reboot-symbolic";      cmd: "systemctl reboot" }
        ActionButton { label: "Shutdown"; icon: "system-shutdown-symbolic";     cmd: "systemctl poweroff" }
      }
    }
  }

  // ── Helper processes ───────────────────────────────────────────
  Process {
    id: brightnessProc
    command: ["brightnessctl", "get", "-P"]
    stdout: SplitParser {
      onRead: data => {
        const val = parseInt(data.trim());
        if (!isNaN(val)) brightnessSlider.value = val;
      }
    }
  }

  Process {
    id: brightnessSetProc
    running: false
  }

  // ── Inline components ──────────────────────────────────────────
  component ToggleButton: Rectangle {
    property string label
    property string icon
    property string cmd
    property bool active: false

    Layout.fillWidth: true
    implicitHeight: 56
    radius: Theme.dropdownRadius
    color: active ? Theme.accent : Theme.separator

    ColumnLayout {
      anchors.centerIn: parent
      spacing: 2

      Image {
        source: parent.parent.icon !== "" ? `image://icon/${parent.parent.icon}` : ""
        sourceSize.width: Theme.iconSize
        sourceSize.height: Theme.iconSize
        Layout.alignment: Qt.AlignHCenter
        visible: source != ""
      }

      Text {
        text: parent.parent.label
        color: Theme.fg
        font.pixelSize: Theme.fontSizeSmall
        Layout.alignment: Qt.AlignHCenter
      }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: parent.active = !parent.active
    }
  }

  component ActionButton: Rectangle {
    property string label
    property string icon
    property string cmd

    Layout.fillWidth: true
    implicitHeight: Theme.itemHeight
    radius: 4
    color: actionMa.containsMouse ? Theme.accentDim : Theme.separator

    RowLayout {
      anchors.centerIn: parent
      spacing: 4

      Image {
        source: parent.parent.icon !== "" ? `image://icon/${parent.parent.icon}` : ""
        sourceSize.width: 14
        sourceSize.height: 14
        visible: source != ""
      }

      Text {
        text: parent.parent.label
        color: Theme.fg
        font.pixelSize: Theme.fontSizeSmall
      }
    }

    MouseArea {
      id: actionMa
      anchors.fill: parent
      hoverEnabled: true
      onClicked: {
        actionProcess.command = ["sh", "-c", parent.cmd];
        actionProcess.startDetached();
      }
    }

    Process {
      id: actionProcess
    }
  }
}
