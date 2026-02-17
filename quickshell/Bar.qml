import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray

// Bottom bar — one instance per screen.
PanelWindow {
  id: bar

  property var shellRoot

  anchors {
    left: true
    right: true
    bottom: true
  }

  implicitHeight: Theme.panelHeight
  color: Theme.bgPanel

  // Track default audio sink for the volume indicator
  PwObjectTracker { objects: [ Pipewire.defaultAudioSink ] }

  // ── left: tray icons ──────────────────────────────────────────────
  RowLayout {
    id: leftSection
    anchors {
      left: parent.left
      verticalCenter: parent.verticalCenter
      leftMargin: Theme.padding
    }
    spacing: Theme.spacing

    // System tray icons
    Repeater {
      model: SystemTray.items

      Image {
        required property var modelData
        source: `image://icon/${modelData.icon}`
        sourceSize.width: Theme.iconSize
        sourceSize.height: Theme.iconSize

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
              modelData.display(bar, mouse.x, mouse.y);
            else
              modelData.activate();
          }
        }
      }
    }
  }

  // ── centre: workspace indicators (placeholder — niri IPC) ────────
  RowLayout {
    anchors.centerIn: parent
    spacing: 2

    Repeater {
      model: 5
      delegate: Rectangle {
        required property int index
        width: 20; height: 6
        radius: 3
        color: index === 0 ? Theme.accent : Theme.separator
      }
    }
  }

  // ── right: quick-info + clock ─────────────────────────────────────
  RowLayout {
    anchors {
      right: parent.right
      verticalCenter: parent.verticalCenter
      rightMargin: Theme.padding
    }
    spacing: Theme.spacing * 2

    // Volume percentage
    Text {
      text: {
        const vol = Pipewire.defaultAudioSink?.audio.volume ?? 0;
        return `${Math.round(vol * 100)}%`;
      }
      color: Theme.fgDim
      font.pixelSize: Theme.fontSizeSmall
    }

    // Clock
    SystemClock {
      id: clock
      precision: SystemClock.Minutes
    }

    Text {
      text: Qt.formatDateTime(clock.date, "HH:mm")
      color: Theme.fg
      font.pixelSize: Theme.fontSizeNormal
      font.bold: true
    }
  }

  // Click the bar to toggle the dropdown on this screen
  MouseArea {
    anchors.fill: parent
    z: -1 // below tray items
    onClicked: shellRoot.toggleDropdown(bar.screen)
  }
}
