// Tooltip.qml
//
// GPL-3.0 license
//
import QtQuick
import Quickshell
import Quickshell.Widgets

PopupWindow {
    id: root

    // ==================================================================
    // 1. Configuration & Input Variables
    // ==================================================================
    property int fontPixelSize: 14
    property Item target: null // Initializing to null safeguards tracking states at early boot
    property string text: ""
    property bool show: false

    // ROBUSTNESS FIX: Force the overlay to remain completely dormant if the 
    // target handle hasn't registered in the parent tree workspace yet.
    visible: show && target !== null

    color: "transparent"

    // Standardized Sizing Rule: Compute window bounds directly from text metrics
    implicitWidth: tooltipText.implicitWidth + 10 // Plus 10 for clean internal horizontal padding
    implicitHeight: tooltipText.implicitHeight + 6

    // Structural Window Placement Anchors
    anchor.item: target
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Left

    // ==================================================================
    // 2. Display Container Layout (Pipeline Alignment)
    // ==================================================================
    Rectangle {
        id: tooltipBox
        anchors.fill: parent // Automatically syncs with window dimensions
        color: "#FFFFCC"     // Light cream yellow background
        border.color: "#88000000" // Subtle translucent black border for crisp separation
        border.width: 1
        radius: 3

        Text {
            id: tooltipText
            
            // PERFORMANCE: Direct symmetrical padding mapping renders significantly 
            // cleaner and matches your exact sizing offsets perfectly.
            x: 5
            y: 3
            text: root.text
            color: "black"
            font.pixelSize: root.fontPixelSize
        }
    }
}

