import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

// Notification popup — displays incoming notifications briefly.
Scope {
  id: root

  NotificationServer {
    id: notifServer
    bodySupported: true
    actionsSupported: true
    persistenceSupported: false
    imageSupported: true

    onNotification: notification => {
      notification.tracked = true;
      hideTimer.restart();
    }
  }

  Timer {
    id: hideTimer
    interval: 5000
    onTriggered: {
      // Dismiss all tracked notifications after timeout
      const notifs = notifServer.trackedNotifications;
      for (let i = notifs.count - 1; i >= 0; i--) {
        notifs.values[i].tracked = false;
      }
    }
  }

  // Show the latest notification as a floating popup
  LazyLoader {
    active: notifServer.trackedNotifications.count > 0

    PanelWindow {
      anchors {
        top: true
        right: true
      }

      margins {
        top: Theme.padding
        right: Theme.padding
      }

      implicitWidth: 340
      implicitHeight: notifContent.implicitHeight + Theme.padding * 2
      color: Theme.transparent
      exclusionMode: ExclusionMode.Ignore
      mask: Region {}

      Rectangle {
        anchors.fill: parent
        radius: Theme.dropdownRadius
        color: Theme.bgDropdown
        border.color: Theme.separator
        border.width: 1

        ColumnLayout {
          id: notifContent
          anchors {
            fill: parent
            margins: Theme.padding
          }
          spacing: Theme.spacing

          Repeater {
            model: notifServer.trackedNotifications

            Rectangle {
              required property var modelData
              Layout.fillWidth: true
              implicitHeight: notifCol.implicitHeight + Theme.padding
              radius: 4
              color: Theme.separator

              ColumnLayout {
                id: notifCol
                anchors {
                  left: parent.left; right: parent.right
                  top: parent.top
                  margins: Theme.spacing
                }
                spacing: 2

                Text {
                  text: modelData.summary ?? ""
                  color: Theme.fg
                  font.pixelSize: Theme.fontSizeNormal
                  font.bold: true
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }

                Text {
                  text: modelData.body ?? ""
                  color: Theme.fgDim
                  font.pixelSize: Theme.fontSizeSmall
                  Layout.fillWidth: true
                  wrapMode: Text.WordWrap
                  maximumLineCount: 3
                  elide: Text.ElideRight
                }
              }

              MouseArea {
                anchors.fill: parent
                onClicked: modelData.tracked = false
              }
            }
          }
        }
      }
    }
  }
}
