pragma Singleton
import QtQuick

// Central theme — edit these values to re-skin the entire shell.
QtObject {
  // Base palette
  readonly property color bg:          "#1a1a2e"
  readonly property color bgPanel:     "#16213e"
  readonly property color bgDropdown:  "#0f3460"
  readonly property color accent:      "#e94560"
  readonly property color accentDim:   "#a83279"
  readonly property color fg:          "#eaeaea"
  readonly property color fgDim:       "#8899aa"
  readonly property color separator:   "#2a2a4a"
  readonly property color transparent: "#00000000"

  // Sizing
  readonly property int panelHeight:     32
  readonly property int panelRadius:      0
  readonly property int dropdownWidth:  380
  readonly property int dropdownRadius:   8
  readonly property int itemHeight:      36
  readonly property int iconSize:        18
  readonly property int spacing:          6
  readonly property int padding:         10

  // Typography
  readonly property int fontSizeSmall:   11
  readonly property int fontSizeNormal:  13
  readonly property int fontSizeLarge:   15
}
