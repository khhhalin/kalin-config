import QtQuick
import Quickshell

// Entry point — creates a Bar on every screen and a single dropdown controller.
ShellRoot {
  id: root

  // Global state: which screen owns the dropdown right now.
  property var activeScreen: null
  property bool dropdownOpen: false

  function toggleDropdown(screen) {
    if (dropdownOpen && activeScreen === screen) {
      dropdownOpen = false;
    } else {
      activeScreen = screen;
      dropdownOpen = true;
    }
  }

  // One bar per monitor
  Variants {
    model: Quickshell.screens

    Bar {
      id: bar
      required property var modelData
      screen: modelData
      shellRoot: root
    }
  }

  // Dropdown — only shown on the active screen
  Variants {
    model: Quickshell.screens

    DropdownPanel {
      id: dropdown
      required property var modelData
      screen: modelData
      visible: root.dropdownOpen && root.activeScreen === modelData
      shellRoot: root
    }
  }

  // Notification popup (single instance, follows active screen)
  NotificationPopup {}
}
