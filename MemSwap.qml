// MemSwap.qml
//
// GPL-3.0 license
//
import QtQuick
import Quickshell
import Quickshell.Io

Rectangle {
    id: root

    // ==================================================================
    // 1. User Tweakable Configurations & Variables
    // ==================================================================
    required property real containerWidth

    height: mainColumn.height + 8
    radius: rootWindow.widgetRadius
    color: rootWindow.widgetBGcolor
    border.color: rootWindow.widgetBorderColor
    border.width: 2

    property real memTotal: 0
    property real memUsed: 0
    property real memPerUsed: 0
    property real swapTotal: 0
    property real swapUsed: 0
    property real swapPerUsed: 0

    property var memHistory: []
    property int maxHistoryPoints: Math.floor(containerWidth) - 2

    // ==================================================================
    // 2. Display Data on UI Layout (Standardized Positioner)
    // ==================================================================
    Column {
        id: mainColumn
        width: root.containerWidth
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 2

        // ---------------------------
        // --- 1. Title Header Bar ---
        // ---------------------------
        Row {
            width: parent.width
            height: 18 // Tightened height bounds to sit safely inside your 116px container limit
            spacing: 4

            Text {
                text: "Mem: " + root.formatSize(root.memTotal) + " / "
                color: "white"
                font.pixelSize: 13
            }
            Text {
                text: "Swap: " + root.formatSize(root.swapTotal)
                color: "white"
                font.pixelSize: 13
            }
        }

        // ---------------------------
        // --- 2. Memory Graph (Normal Upward) ---
        // ---------------------------
        Rectangle {
            id: memGraphRect
            width: parent.width
            height: 40 // Standardized graph frame heights
            color: "#66000000"
            border.color: "#AA000000"
            border.width: 1

            Canvas {
                id: memGraphCanvas
                anchors.fill: parent
                anchors.margins: 1

                Connections {
                    target: root
                    function onMemHistoryChanged() { memGraphCanvas.requestPaint() }
                }

                onPaint: {
                    let ctx = getContext("2d");
                    ctx.reset();

                    // 1. PERFORMANCE: Cache properties to prevent C++/JS cross-boundary overhead
                    let data = root.memHistory;
                    let len = data.length;
                    let totalMem = root.memTotal;
                    let limit = root.maxHistoryPoints;

                    // 2. ROBUSTNESS: Prevent crashes, NaN layout bugs, and division-by-zero
                    if (len < 2 || totalMem <= 0 || limit <= 1) return;

                    ctx.fillStyle = "#00FF00";
                    ctx.strokeStyle = "#00FF00";
                    ctx.lineWidth = 1;
                    ctx.beginPath();

                    // Baseline for Normal Upward graph is Y = height (bottom)
                    ctx.moveTo(width, height);

                    let step = width / (limit - 1);

                    for (let i = 0; i < len; i++) {
                        let idx = len - 1 - i;
                        let x = width - (i * step);

                        // Normal Upward Math simplified via cached local variables:
                        // 0 value results in y = height (physical bottom)
                        // Max value (memTotal) results in y = 0 (physical top)
                        let y = height - ((data[idx] / totalMem) * height);

                        ctx.lineTo(x, y);
                    }

                    // Close the path clean along the bottom baseline (Y = height)
                    let lastX = width - ((len - 1) * step);
                    ctx.lineTo(lastX, height);
                    ctx.closePath();

                    ctx.fill();
                    ctx.stroke();
                }
            }
        }

        // ---------------------------
        // --- 3. Memory Text Readout ---
        // ---------------------------
        Item {
            width: parent.width
            height: 14

            Text {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.topMargin: -2 // Shuts padding gaps tightly
                // ROBUSTNESS: Ensure the percent readout degrades gracefully if undefined early on
                text: "Mem used:  " + formatSize(root.memUsed) + "    (" + (typeof root.memPerUsed === "number" ? root.memPerUsed.toFixed(1) : "0.0") + "%)"
                color: "#00FF00"
                font.pixelSize: 12
            }
        }

        // ---------------------------
        // --- 4. Swap Status Bar Track ---
        // ---------------------------
        Item {
            width: parent.width
            height: 12

            Rectangle {
                width: parent.width
                height: 8
                anchors.centerIn: parent
                color: "#66000000"
                border.color: "#FF3333"
                border.width: 1

                Rectangle {
                    id: swapBarFill
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 1
                    // ROBUSTNESS: Cached boundaries ensure that width calculation loops never feed bad data into the animation engine
                    width: {
                        let total = root.swapTotal;
                        let used = root.swapUsed;
                        if (total <= 0 || used <= 0) return 0;
                        return Math.min(parent.width - 2, (parent.width - 2) * (used / total));
                    }
                    color: "#FF3333"

                    Behavior on width { NumberAnimation { duration: 250 } }
                }
            }
        }

        // ---------------------------
        // --- 5. Swap Text Readout ---
        // ---------------------------
        Item {
            width: parent.width
            height: 14

            Text {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.topMargin: -2
                text: "Swap used:  " + formatSize(root.swapUsed) + "    (" + (typeof root.swapPerUsed === "number" ? root.swapPerUsed.toFixed(1) : "0.0") + "%)"
                color: "#FF3333"
                font.pixelSize: 12
            }
        }
    }

    // Helper formatting function to convert bytes to readable metrics (KB, MB, GB)
    function formatSize(value) {
        // PERFORMANCE: Check the absolute number size instead of evaluating multiple multiplications inline
        if (value >= 1073741824) return (value / 1073741824).toFixed(1) + " GB"
        if (value >= 1048576) return (value / 1048576).toFixed(1) + " MB"
        if (value >= 1024) return (value / 1024).toFixed(1) + " KB"
        return (typeof value === "number" ? value.toFixed(1) : "0.0") + " B"
    }

    // ==================================================================
    //  Data Gathering Subsystems
    // ==================================================================
    FileView {
        id: memInfoReader
        path: "/proc/meminfo"

        onLoaded: {
            // 1. PERFORMANCE: Direct call alignment replaces heavy type checking lookups
            let content = text().trim();
            if (!content) return;

            let lines = content.split("\n");
            let data = { memTotal: 0, memAvailable: 0, swapTotal: 0, swapFree: 0 };

            // 2. RADIX SAFETY & SPEED: Local inline loop parser handles tokens cleanly
            function parseBytes(line) {
                let parts = line.split(":");
                if (parts.length < 2) return 0;
                let valStr = parts[1].trim().split(/\s+/)[0];
                let kb = parseInt(valStr, 10);

                return isNaN(kb) ? 0 : kb * 1024;   // returns clean Bytes
            }

            for (let i = 0; i < lines.length; i++) {
                let line = lines[i].trim();
                if (line.startsWith("MemTotal:")) data.memTotal = parseBytes(line);
                else if (line.startsWith("MemAvailable:")) data.memAvailable = parseBytes(line);
                else if (line.startsWith("SwapTotal:")) data.swapTotal = parseBytes(line);
                else if (line.startsWith("SwapFree:")) data.swapFree = parseBytes(line);
            }

            root.memTotal = data.memTotal;
            root.memUsed = data.memTotal - data.memAvailable;
            root.memPerUsed = data.memTotal > 0 ? (root.memUsed / data.memTotal * 100) : 0;

            root.swapTotal = data.swapTotal;
            root.swapUsed = data.swapTotal - data.swapFree;
            root.swapPerUsed = data.swapTotal > 0 ? (root.swapUsed / data.swapTotal * 100) : 0;

            // 3. STORAGE OPTIMIZATION: Swapped array spread engine for memory efficient slice shifting
            let hist = root.memHistory.slice();
            hist.push(root.memUsed);

            if (hist.length > root.maxHistoryPoints) {
                hist.shift();
            }
            root.memHistory = hist;
        }
    }

    // High performance tracking loop execution cycle
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: memInfoReader.reload()
    }
}
