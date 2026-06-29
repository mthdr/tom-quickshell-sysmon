// Clock.qml
//
// GPL-3.0 license
//
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Io

Rectangle {
    id: root

    // ==================================================================
    // 1. User Tweakable Configurations & Variables
    // ==================================================================
    required property real containerWidth

    // SCALABLE LAYOUT FEATURE: Dynamically calculates card bounding height 
    // based on your global panel width setting.
    height: Math.floor(0.420 * rootWindow.mywidth + 42)
    radius: rootWindow.widgetRadius
    color: rootWindow.widgetBGcolor
    border.color: rootWindow.widgetBorderColor
    border.width: 2

    // --- Dynamic Time & Performance States ---
    property var currentTime: new Date()
    property int currentSecond: currentTime.getSeconds()
    property string uptimeText: "Uptime: ..."

    // ==================================================================
    // 2. Display Data on UI Layout (Standardized Positioner)
    // ==================================================================
    Column {
        id: mainColumn
        width: root.containerWidth - 16
        spacing: 4

        // Visual Adjustment: Anchored directly relative to the top border frame
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter

        // -----------------------------------------------
        // --- 1. Time Display Block ---
        // -----------------------------------------------
        Rectangle {
            id: targetText
            width: timeText.implicitWidth
            height: Math.max(1, timeText.implicitHeight - 6) // Preserved padding layout preference safely
            color: "transparent"
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                id: timeText
                text: Qt.formatTime(root.currentTime, "hh:mm AP")
                // DYNAMIC SCALING FEATURE: Font thickness tracks panel width modifications
                font.pixelSize: (root.width / 10) * 2
                color: "white"
                anchors.centerIn: parent
            }

            HoverHandler {
                id: textHover
            }

            Tooltip {
                id: clockTooltip
                target: targetText
                show: textHover.hovered
                text: {
                    let d = root.currentTime;
                    let hh = String(d.getUTCHours()).padStart(2, '0');
                    let mm = String(d.getUTCMinutes()).padStart(2, '0');
                    let ss = String(d.getUTCSeconds()).padStart(2, '0');
                    return `UTC: ${hh}:${mm}:${ss}`;
                }
                fontPixelSize: 18
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
                width: parent.width * (Math.max(0, Math.min(59, root.currentSecond)) / 59)
                color: "white"
            }
        }

        // -----------------------------------------------
        // --- 3. Date Text Array (ddd + dd-MMM-yyyy) ---
        // -----------------------------------------------
        Row {
            id: clockDate
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0 

            Text {
                text: Qt.formatDate(root.currentTime, "ddd ")
                font.pixelSize: (root.width / 10)
                color: "#FF3333"
                style: Text.Outline
                styleColor: "#22000000"
            }
            Text {
                text: Qt.formatDate(root.currentTime, "  dd-MMM-yyyy")
                font.pixelSize: (root.width / 10)
                color: "#00BBFF"
                style: Text.Outline
                styleColor: "#22000000"
            }
        }

        // -------------------------------------------------
        // --- 4. Accent Separation Rule Bar ---
        // -------------------------------------------------
        Rectangle {
            id: dateBar
            width: parent.width - 20
            height: 1
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#00FF77"
        }

        // -------------------------------------------------
        // --- 5. System Uptime Label Display ---
        // -------------------------------------------------
        Text {
            id: clockUptime
            text: root.uptimeText
            font.pixelSize: 16
            color: "yellow"
            style: Text.Outline
            styleColor: "#22000000"
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // ==================================================================
    // 3. Data Gathering & File System Processing Channels
    // ==================================================================
    FileView {
        id: uptimeFile
        path: "/proc/uptime"
    }

    // ==================================================================
    // 4. Automation & Driving Loops
    // ==================================================================
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            // Kick the core clock pulse binding chain
            let d = new Date();
            root.currentTime = d;
            root.currentSecond = d.getSeconds();

            // High-performance, zero-fork Uptime Parsing Pass
            uptimeFile.reload();
            let rawData = uptimeFile.text().trim();
            if (rawData) {
                let uptimeSeconds = parseInt(rawData.split(' '), 10);
                if (!isNaN(uptimeSeconds)) {
                    let days = Math.floor(uptimeSeconds / 86400);
                    let hours = Math.floor((uptimeSeconds % 86400) / 3600);
                    let minutes = Math.floor((uptimeSeconds % 3600) / 60);

                    let uptimeStr = "";
                    if (days > 0) uptimeStr += `${days}d `;
                    uptimeStr += `${hours}h ${minutes}m`;

                    root.uptimeText = "Uptime: " + uptimeStr;
                }
            }
        }
    }
}

