// CpuGraph.qml
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
    required property string sensorChipName
    required property string sensorKeyName

    height: mainColumn.height + 8
    radius: rootWindow.widgetRadius
    color: rootWindow.widgetBGcolor
    border.color: rootWindow.widgetBorderColor
    border.width: 2
    property int barSpacing: 1 
    property color barColor: "white"

    // This will hold the exact path discovered on startup (e.g. "/sys/class/hwmon/hwmon5/temp1_input")
    property string resolvedTempPath: ""

    // Dynamic Sizing Metrics
    property int maxHistoryPoints: Math.floor(containerWidth) - 2
    property var cpuHistory: []

    // --- Properties for Data ---
    property int lastTotal: 0
    property int lastIdle: 0
    property string cpuTemp: "--°C"
    property string cpuFreq: "-- GHz"
    property real currentCpuUsage: 0
    property string _buf: ""
    property string cpuModel: "Loading..."
    property var coreUsages: []
    property var lastCoreTotal: []
    property var lastCoreIdle: []


    // ==================================================================
    // 2. Display Data on UI Layout (Standardized Positioner)
    // ==================================================================
    Column {
        id: mainColumn
        width: root.containerWidth
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 1

        // ------------------------------
        // --- 1. Header: Temp & Clock ---
        // ------------------------------
        Item {
            width: parent.width
            height: 16

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Clock: " + root.cpuFreq
                color: "white"
                font.pixelSize: 12
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "Temp: " + root.cpuTemp
                color: "orange"
                font.pixelSize: 12
            }
        }

        // ------------------------------
        // --- 2. CPU Usage Graph ---
        // ------------------------------
        Rectangle {
            id: cpuGraphRect
            width: parent.width
            height: 50
            color: "#66000000"
            border.color: "#AA000000"
            border.width: 1

            Canvas {
                id: cpuGraphCanvas
                anchors.fill: parent
                anchors.margins: 1

                Connections {
                    target: root
                    function onCpuHistoryChanged() { cpuGraphCanvas.requestPaint() }
                }

                onPaint: {
                    let ctx = getContext("2d");
                    ctx.reset();

                    // 1. PERFORMANCE: Cache properties to eliminate engine cross-boundary lag
                    let data = root.cpuHistory;
                    let len = data.length;
                    let limit = root.maxHistoryPoints;

                    // 2. ROBUSTNESS: Ensure safe boundaries to avoid NaN errors and crashes
                    if (len < 2 || limit <= 1) return;

                    ctx.fillStyle = "#00FFFF";
                    ctx.strokeStyle = "cyan";
                    ctx.lineWidth = 1;
                    ctx.beginPath();

                    // Baseline for Normal Upward graph is Y = height (bottom)
                    ctx.moveTo(width, height);

                    let step = width / (limit - 1);

                    for (let i = 0; i < len; i++) {
                        let idx = len - 1 - i;
                        let x = width - (i * step);

                        // Normal Upward Math (CPU usage values are inherently percentages 0-100)
                        let y = height - ((data[idx] / 100) * height);

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

            HoverHandler {
                id: textHover
            }

            Tooltip {
                id: cpuTooltip
                target: cpuGraphRect
                show: textHover.hovered
                text: root.cpuModel
                fontPixelSize: 14
            }
        }

        // ------------------------------
        // --- 3. Current Usage Text Readout ---
        // ------------------------------
        Item {
            width: parent.width
            // CLEAN FIX: Increased container height slightly to build an automatic, 
            // rock-solid layout gap beneath the text without needing an empty spacer.
            height: 19

            Text {
                // ROBUSTNESS: Always use horizontalCenter inside a Column, but REMOVED anchors.top
                anchors.horizontalCenter: parent.horizontalCenter
                y: -1
                text: "CPU Usage: " + (root.currentCpuUsage < 10 ? root.currentCpuUsage.toFixed(1) : Math.round(root.currentCpuUsage)) + "%"
                color: "cyan"
                font.pixelSize: 14
            }
        }

        // -----------------------------------------------
        // Core Usage Container Vertical Bars
        // -----------------------------------------------
        Rectangle {
            width: parent.width
            height: 40
            color: "transparent"

            // Standardized Row Positioner handles bar grid spacing with 0% layout overhead
            Row {
                id: coreRow
                anchors.centerIn: parent
                height: parent.height
                spacing: root.barSpacing

                // Computes pixel-perfect uniform bar widths on the fly
                readonly property real optimalBarWidth: {
                    let totalCores = root.coreUsages ? root.coreUsages.length : 1;
                    if (totalCores <= 0) return 1;
                    let totalSpacing = root.barSpacing * (totalCores - 1);
                    return Math.max(1, Math.floor((root.containerWidth - totalSpacing) / totalCores));
                }

                Repeater {
                    model: root.coreUsages
                    delegate: Item {
                        width: coreRow.optimalBarWidth
                        height: coreRow.height

                        // 1. Static Background Track
                        Rectangle {
                            anchors.fill: parent
                            color: "#66000000" // Black 50% transparent background
                        }

                        // 2. Dynamic Usage Bar (Grows Upward from Bottom Boundary)
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            // PERFORMANCE: Simplified the bounding constraints to allow rapid UI rendering ticks
                            height: {
                                let pct = parseFloat(modelData);
                                if (isNaN(pct) || pct <= 0) return 0;
                                if (pct >= 100) return parent.height;
                                return parent.height * (pct / 100.0);
                            }
                            color: root.barColor
                        }
                    }
                }
            }
        }
    }

    // ==================================================================
    // Data Gathering Section
    // ==================================================================

    // -----------------------------------------
    // One-shot CPU Model Reader
    FileView {
        id: cpuInfoReader
        path: "/proc/cpuinfo"
        onLoaded: {
            let content = text().trim();
            if (!content) return;

            let lines = content.split("\n");
            for (let i = 0; i < lines.length; i++) {
                if (lines[i].startsWith("model name")) {
                    let parts = lines[i].split(":");
                    if (parts.length >= 2) {
                        root.cpuModel = parts[1].trim();
                    }
                    break;
                }
            }
        }
    }

    // -----------------------------------------
    // Dynamic Clock Speed Frequency Reader
    FileView {      
        id: freqReader 
        path: "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq"

        onLoaded: { 
            // 1. PERFORMANCE: Direct functional lookup removes heavy engine overhead layers
            let content = text().trim();
            if (!content) return;

            // 2. RADIX SAFETY: Forcing a base-10 conversion ensures bulletproof arithmetic parsing
            let khz = parseInt(content, 10);
            if (!isNaN(khz)) {
                root.cpuFreq = (khz / 1000000).toFixed(2) + " GHz";
            }       
        }           
    }

    // -----------------------------------------
    // SHARED BACKEND PARSER 
    // Reads /proc/stat once and handles whichever dataset is requested
    // -----------------------------------------
    FileView {
        id: unifiedStatReader
        path: "/proc/stat"

        // Hidden tracking properties to let the timers talk to the parser safely
        property bool _parseGraphData: false
        property bool _parseBarData: false

        onLoaded: {
            let content = text().trim();
            if (!content) return;

            let lines = content.split("\n");
            let parseGraph = unifiedStatReader._parseGraphData;
            let parseBars = unifiedStatReader._parseBarData;

            // Temporary arrays for core tracking
            let newCoreTotal = [];
            let newCoreIdle = [];
            let newCoreUsage = [];
            let maxIndex = -1;

            // Pre-scan core boundaries only if we are actively updating the high-speed bars
            if (parseBars) {
                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim();
                    let parts = line.split(/\s+/);
                    if (parts[0].startsWith("cpu") && parts[0].length > 3) {
                        let coreIdx = parseInt(parts[0].substring(3), 10);
                        if (!isNaN(coreIdx)) maxIndex = Math.max(maxIndex, coreIdx);
                    }
                }
                if (maxIndex !== -1) {
                    for (let i = 0; i <= maxIndex; i++) {
                        newCoreUsage.push(0);
                        newCoreTotal.push(0);
                        newCoreIdle.push(0);
                    }
                }
            }

            // --- SINGLE SCAN PASS ---
            for (let i = 0; i < lines.length; i++) {
                let line = lines[i].trim();
                if (line === "") continue;

                let parts = line.split(/\s+/);
                let firstToken = parts[0];

                // Graph Trigger: Runs exactly every 1000ms with fresh, non-cached values
                if (parseGraph && firstToken === "cpu") {
                    let aggIdle = (parseInt(parts[4], 10) || 0) + (parseInt(parts[5], 10) || 0);
                    let aggTotal = 0;
                    for (let j = 1; j < 8; j++) {
                        aggTotal += parseInt(parts[j], 10) || 0;
                    }

                    if (root.lastTotal > 0) {
                        let dTotal = aggTotal - root.lastTotal;
                        let dIdle = aggIdle - root.lastIdle;
                        let aggUsage = dTotal > 0 ? 100 * (1 - dIdle / dTotal) : 0;

                        let hist = root.cpuHistory.slice();
                        hist.push(aggUsage);
                        if (hist.length > root.maxHistoryPoints) hist.shift();

                        root.cpuHistory = hist;
                        root.currentCpuUsage = aggUsage;
                    }
                    root.lastTotal = aggTotal;
                    root.lastIdle = aggIdle;

                    if (!parseBars) break; // If we aren't tracking bars on this tick, we can stop scanning early!
                }

                // Vertical Bars Trigger: Runs exactly every 600ms
                else if (parseBars && firstToken.startsWith("cpu") && firstToken.length > 3 && maxIndex !== -1) {
                    let coreIndex = parseInt(firstToken.substring(3), 10);
                    if (isNaN(coreIndex) || coreIndex > maxIndex) continue;

                    let idle = parseInt(parts[4], 10) || 0;
                    let total = 0;
                    for (let j = 1; j < parts.length; j++) {
                        total += parseInt(parts[j], 10) || 0;
                    }

                    if (root.lastCoreTotal[coreIndex] !== undefined) {
                        let dTotal = total - root.lastCoreTotal[coreIndex];
                        let dIdle = idle - root.lastCoreIdle[coreIndex];
                        newCoreUsage[coreIndex] = dTotal > 0 ? 100 * (1 - dIdle / dTotal) : 0;
                    }

                    newCoreTotal[coreIndex] = total;
                    newCoreIdle[coreIndex] = idle;
                }
            }

            // Commit visual bar changes to the UI layer
            if (parseBars && maxIndex !== -1) {
                root.coreUsages = newCoreUsage;
                root.lastCoreTotal = newCoreTotal;
                root.lastCoreIdle = newCoreIdle;
            }

            // Reset request flags for the next incoming timer tick
            unifiedStatReader._parseGraphData = false;
            unifiedStatReader._parseBarData = false;
        }
    }


    // Vars to help with CPU temp discovery
    property int _hIdx: 0
    property int _lIdx: 1
    property string _baseDir: ""
    property bool pathVarIsReady: false

    // -----------------------------------------
    // SECTION 1: One-Shot Discovery for CPU temp path/file
    // -----------------------------------------
    FileView {
        id: discoveryReader
        printErrors: false

        onLoaded: {
            // PERFORMANCE: Direct functional lookup removes heavy type-checking layers
            let txt = text().trim();
            if (!txt) return;

            if (_baseDir === "" && txt === root.sensorChipName) {
                _baseDir = "/sys/class/hwmon/hwmon" + (_hIdx - 1);
            } else if (_baseDir !== "" && txt === root.sensorKeyName) {
                resolvedTempPath = _baseDir + "/temp" + (_lIdx - 1) + "_input";
                pathVarIsReady = true;      // 🏁 MASTER SWITCH: Stops scan, starts polling
            }
        }
    }

    // -----------------------------------------
    // SECTION 2: Pure Runtime Reader (Timer polling every 2 Seconds)
    // -----------------------------------------
    FileView {
        id: cpuTempReader
        path: root.resolvedTempPath
        printErrors: false

        onLoaded: {
            let txt = text().trim();
            if (!txt) return;

            // RADIX SAFETY: Forcing a base-10 conversion guarantees clean numeric layouts
            let rawTemp = parseInt(txt, 10);
            if (!isNaN(rawTemp) && rawTemp > 0) {
                root.cpuTemp = Math.round(rawTemp / 1000) + "°C";
            }
        }
    }

    // ==================================================================
    // Runtime Control Timer Loops
    // ==================================================================

    // Timer to find CPU temp file path, runs once.
    Timer {
        id: discoveryDiscoveryTimer
        interval: 25
        running: !root.pathVarIsReady     // Runs only while cpu temp path is NOT ready
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            if (_baseDir === "") {
                if (_hIdx < 16) {
                    discoveryReader.path = "/sys/class/hwmon/hwmon" + _hIdx++ + "/name";
                } else {
                    resolvedTempPath = "/dev/null";   // could not find a cpu temp path
                    pathVarIsReady = true;
                }
            } else {
                if (_lIdx <= 8) {
                    discoveryReader.path = _baseDir + "/temp" + _lIdx++ + "_label";
                } else {
                    resolvedTempPath = _baseDir + "/temp1_input";
                    pathVarIsReady = true;
                }
            }
        }
    }

    // Timer for CPU temp at 2000 ms
    Timer {
        interval: 2000
        running: root.pathVarIsReady // Wakes up the exact moment the master switch flips
        repeat: true
        triggeredOnStart: true
        onTriggered: cpuTempReader.reload()
    }

    // Timer for the CPU graph update and CPU frequency speed at 1000 ms
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            freqReader.reload();
            unifiedStatReader._parseGraphData = true;
            unifiedStatReader.reload();
        }
    }

    // Timer for the CPU vertical bars at 600 ms
    Timer {
        interval: 600
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            unifiedStatReader._parseBarData = true;
            unifiedStatReader.reload();
        }
    }
}
