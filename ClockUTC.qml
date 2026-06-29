// ClockUTC.qml
//
// GPL-3.0 license
//
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Io

Rectangle {
    id: utcRoot

    // ==================================================================
    // 1. User Tweakable Configurations & Variables
    // ==================================================================
    required property real containerWidth

    // SCALABLE LAYOUT MATH: This exact ratio preserves a clean, locked 
    // visual bottom gap beneath your UTC date text row regardless of 
    // whether your sidebar is narrow or ultra-wide.
    height: Math.floor(0.40 * rootWindow.mywidth + 12)
    radius: rootWindow.widgetRadius
    color: rootWindow.widgetBGcolor
    border.color: rootWindow.widgetBorderColor
    border.width: 2

    // --- Dynamic Time Tracking States ---
    property var currentTime: new Date()
    property int currentSecond: currentTime.getUTCSeconds()

    // ==================================================================
    // 2. Display Data on UI Layout (Standardized Positioner)
    // ==================================================================
    Column {
        id: mainColumn
        width: utcRoot.containerWidth - 16 // Safety padding layout frame bounds
        spacing: 4

        // Visual Adjustment: Anchored directly relative to the top border frame
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter

        // -----------------------------------------------
        // --- 1. UTC Time Display Block ---
        // -----------------------------------------------
        Rectangle {
            id: targetText
            width: timeText.implicitWidth
            height: Math.max(1, timeText.implicitHeight - 6) // Matches padding configurations exactly
            color: "transparent"
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                id: timeText
                text: {
                    let h = String(utcRoot.currentTime.getUTCHours()).padStart(2, '0');
                    let m = String(utcRoot.currentTime.getUTCMinutes()).padStart(2, '0');
                    let s = String(utcRoot.currentTime.getUTCSeconds()).padStart(2, '0');
                    return `${h}:${m}:${s}`;
                }
                font.pixelSize: (utcRoot.width / 10) * 2
                color: "white"
                anchors.centerIn: parent
            }
        }

        // ------------------------------------------------------
        // --- 2. Seconds Progress Bar Track ---
        // ------------------------------------------------------
        Rectangle {
            id: container
            width: parent.width
            height: 2
            color: "black"
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                // Safeguarded bounds ensure width scaling calculation never hits division anomalies
                width: parent.width * (Math.max(0, Math.min(59, utcRoot.currentSecond)) / 59)
                color: "white"
            }
        }

        // -----------------------------------------------
        // --- 3. UTC Date Text Array ---
        // -----------------------------------------------
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0 

            Text {
                text: {
                    let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
                    return days[utcRoot.currentTime.getUTCDay()] + " ";
                }
                font.pixelSize: (utcRoot.width / 10)
                color: "#FF3333"
                style: Text.Outline
                styleColor: "#22000000"

                // Fine adjustments to line text geometry
                y: -1
            }
            Text {
                text: {
                    let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                    let day = String(utcRoot.currentTime.getUTCDate()).padStart(2, '0');
                    let mon = months[utcRoot.currentTime.getUTCMonth()];
                    let yr = utcRoot.currentTime.getUTCFullYear();
                    return `  ${day}-${mon}-${yr}`;
                }
                font.pixelSize: (utcRoot.width / 10)
                color: "#00BBFF"
                style: Text.Outline
                styleColor: "#22000000"

                y: -1
            }
        }
    }

    // ==================================================================
    // 3. Automation & Driving Loops
    // ==================================================================
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            // Kick the layout loop to evaluate all UTC binding elements simultaneously
            utcRoot.currentTime = new Date();
            utcRoot.currentSecond = utcRoot.currentTime.getUTCSeconds();
        }
    }
}

