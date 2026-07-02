// Disk.qml
//
// GPL-3.0 license
//
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import "FormatHelpers.js" as Utils

Rectangle {
    id: root

    // ==================================================================
    // User Tweakable Configurations & Variables
    // ==================================================================
    required property int containerWidth
    required property string mountPoint
    required property string mountDev
    required property string modelSize
    required property int widgetRadius
    required property string widgetBGcolor
    required property string widgetBorderColor
    required property int widgetBorderWidth
    required property int graphHeight
    required property bool isToolbox

    height: mainColumn.height + 8
    radius: root.widgetRadius
    color: widgetBGcolor
    border.color: widgetBorderColor
    border.width: widgetBorderWidth

    // Dynamic Sizing Metrics
    property int historyLimit: containerWidth - 2

    property string devicePath: ""            // Will become "/dev/nvme1n1p3" dynamically
    property string deviceName: ""            // Will become "nvme1n1p3" dynamically
    property string ssdModel: ""              // Will become "SSD Model number" dynamically
    property string diskstatsDev: ""
    property string tooltipDev: ""
    property string luksPath: ""
    property string dmDevice: ""

    // --- Output Performance & Graph Metrics ---
    readonly property real diskReadBytesSec: _diskReadBytesSec
    readonly property real diskWriteBytesSec: _diskWriteBytesSec
    readonly property real diskReadMax: _diskReadMax
    readonly property real diskWriteMax: _diskWriteMax
    readonly property real diskPercentUsed: _diskPercentUsed

    property real _diskReadBytesSec: 0
    property real _diskWriteBytesSec: 0
    property real _diskReadMax: 1             // 1 B minimum default scaling boundary
    property real _diskWriteMax: 1
    property real _diskPercentUsed: 0

    property var historyRead: []
    property var historyWrite: []

    // Cache object to bypass persistent binding drops
    property var _diskState: ({ lastSectorsRead: 0, lastSectorsWritten: 0, initialized: false })

    // ==================================================================
    // Display Data on UI Layout
    // ==================================================================
    Column {
        id: mainColumn
        spacing: 0 // Controlled with explicit margins now to close layout gaps
        width: root.containerWidth
        anchors.horizontalCenter: parent.horizontalCenter

        // Standardized Header Container (Left & Right text)
        Item {
            id: diskHeader
            width: parent.width
            height: 18
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                id: diskMainLabel
                anchors.left: parent.left
                color: "white"
                font.pixelSize: 14
                text: modelSize

                HoverHandler {
                    id: textHover2
                }
                Tooltip {
                    id: ssdModTooltip
                    target: diskMainLabel
                    show: textHover2.hovered
                    text: root.ssdModel
                    fontPixelSize: 14
                }
            }
            Text {
                id: diskMountLabel
                anchors.right: parent.right
                anchors.baseline: diskMainLabel.baseline
                anchors.baselineOffset: 0
                color: "white"
                font.pixelSize: 10
                text: "(" + root.mountPoint + ")" 

                HoverHandler {
                    id: textHover3
                }
                Tooltip {
                    id: ssdDevTooltip
                    target: diskMountLabel
                    show: textHover3.hovered
                    text: root.tooltipDev
                    fontPixelSize: 14
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor // Changes cursor to a hand icon on hover

                    // opens Filemanager when clicked
                    onClicked: {
                        // Use the clean property passed from the shell instantly!
                        if (root.isToolbox) {
                            fmLauncher.command = ["host-spawn", "xdg-open", root.mountPoint];
                        } else {
                            fmLauncher.command = ["xdg-open", root.mountPoint];
                        }
                        fmLauncher.running = true;
                    }
                }
            }
        }

        // -------------------------------------------
        // --- 1. Read Metrics Text Layout (Left & Right alignment)
        // -------------------------------------------
        Item {
            width: parent.width
            height: 16 // Tight structural boundary

            Text {
                anchors.left: parent.left
                color: "#00BBFF" // Bluish tone
                font.pixelSize: 12
                text: "Read: " + Utils.formatUnits(root.diskReadBytesSec, 3) + "B/s"
            }
            Text {
                anchors.right: parent.right
                color: "#00BBFF" // Bluish tone
                font.pixelSize: 12
                text: "(Max: " + Utils.formatUnits(root.diskReadMax, 3) + "B/s)"
            }
        }

        // -------------------------------------------
        // --- Read Graph (Normal Upward)
        // -------------------------------------------
        Rectangle {
            id: readGraphBox
            width: parent.width
            height: root.graphHeight
            color: "#66000000"
            border.color: "#AA000000"
            border.width: 1

            // Shifted upper graph up 1px by applying a small negative top margin
            anchors.topMargin: -1

            Canvas {
                id: readCanvas
                anchors.fill: parent
                anchors.margins: 1

                Connections { 
                    target: root
                    function onHistoryReadChanged() { readCanvas.requestPaint() } 
                }

                onPaint: {
                    let ctx = getContext("2d")
                    ctx.reset()

                    // PERFORMANCE: Cache properties to prevent C++/JS cross-boundary overhead
                    let data = root.historyRead
                    let len = data.length
                    let maxVal = root.diskReadMax
                    let limit = root.historyLimit

                    // ROBUSTNESS: Prevent crashes, NaN layout bugs, and division-by-zero
                    if (len < 2 || maxVal <= 0 || limit <= 1) return

                    ctx.fillStyle = "#00BBFF"
                    ctx.strokeStyle = "#00BBFF"
                    ctx.lineWidth = 1
                    ctx.beginPath()

                    // Baseline for Normal Upward graph is Y = height (bottom)
                    ctx.moveTo(width, height)

                    let step = width / (limit - 1)

                    for (let i = 0; i < len; i++) {
                        let idx = len - 1 - i
                        let x = width - (i * step)

                        // Normal Upward Math: 
                        // 0 value results in y = height (physical bottom)
                        // max value results in y = 0 (physical top)
                        let y = height - ((data[idx] / maxVal) * height)

                        ctx.lineTo(x, y)
                    }

                    // Close the path clean along the bottom baseline (Y = height)
                    let lastX = width - ((len - 1) * step)
                    ctx.lineTo(lastX, height)
                    ctx.closePath()

                    ctx.fill()
                    ctx.stroke()
                }
            }
        }

        // -------------------------------------------
        // --- 3. Space Used Horizontal Bar (Orange)
        // -------------------------------------------
        Item {
            width: parent.width
            height: 10 // Increased container bounds slightly to pad layout transitions

            // Background Track Bar
            Rectangle {
                id: barTrack
                width: parent.width
                height: 8
                anchors.centerIn: parent
                color: "#66000000"
                border.color: "orange"
                border.width: 1

                // Active space usage fill bar
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.max(0, (parent.width - 2) * (root.diskPercentUsed / 100))
                    color: "orange"
                }

                HoverHandler {
                    id: textHover
                }

                Tooltip {
                    id: cpuTooltip 
                    target: barTrack
                    show: textHover.hovered
                    text: root.diskPercentUsed + "%"
                    fontPixelSize: 16
                }
            }
        }

        // -------------------------------------------
        // --- Write Graph (Flipped Vertically, 0 at Top)
        // -------------------------------------------
        Rectangle {
            width: parent.width
            height: root.graphHeight
            color: "#66000000"
            border.color: "#AA000000"
            border.width: 1

            Canvas {
                id: writeCanvas
                anchors.fill: parent
                anchors.margins: 1

                Connections { 
                    target: root 
                    function onHistoryWriteChanged() { writeCanvas.requestPaint() } 
                }

                onPaint: {
                    let ctx = getContext("2d")
                    ctx.reset()

                    // PERFORMANCE & ROBUSTNESS: Cache properties locally
                    let data = root.historyWrite
                    let len = data.length
                    let maxVal = root.diskWriteMax
                    let limit = root.historyLimit

                    if (len < 2 || maxVal <= 0 || limit <= 1) return

                    ctx.fillStyle = "#ff3333"
                    ctx.strokeStyle = "#ff3333"
                    ctx.lineWidth = 1
                    ctx.beginPath()

                    // 0 is at the top, so our fill baseline is Y = 0
                    ctx.moveTo(width, 0)

                    let step = width / (limit - 1)

                    for (let i = 0; i < len; i++) {
                        let idx = len - 1 - i
                        let x = width - (i * step)

                        // EFFICIENT MATH FLIP: 
                        // 0 value results in y = 0 (physical top)
                        // max value results in y = height (physical bottom)
                        let y = (data[idx] / maxVal) * height

                        ctx.lineTo(x, y)
                    }

                    // Close the path clean along the top baseline (Y = 0)
                    let lastX = width - ((len - 1) * step)
                    ctx.lineTo(lastX, 0)
                    ctx.closePath()

                    ctx.fill()
                    ctx.stroke()
                }
            }
        }

        // -------------------------------------------
        // --- 5. Write Metrics Text Layout (Left & Right alignment)
        // -------------------------------------------
        Item {
            width: parent.width 
            height: 10

            Text {
                anchors.left: parent.left
                y: -2
                color: "#FF3333" // Reddish tone
                font.pixelSize: 12
                text: "Write: " + Utils.formatUnits(root.diskWriteBytesSec, 3) + "B/s"
            }
            Text {
                anchors.right: parent.right
                y: -2
                color: "#FF3333" // Reddish tone
                font.pixelSize: 12
                text: "(Max: " + Utils.formatUnits(root.diskWriteMax, 3) + "B/s)"
            }
        }
    } // End of mainColumn

    // ==================================================================
    //  Data Gathering & Shell Resolution Systems
    // ==================================================================

    // Takes the deviceName and sets the drive model into ssdModel.
    // Fires only once at start.
    FileView {
        id: modelFile

        property string clean: deviceName ? deviceName.replace(/^\/dev\//, "") : ""

        property string base: {
            if (!clean) return "";

            // Structural verification constraints using high-efficiency test calls
            if (/p\d+$/.test(clean))          return clean.replace(/p\d+$/, "");
            if (/^nvme\d+n\d+$/.test(clean))  return clean;
            if (/^mmcblk\d+$/.test(clean))    return clean;
            if (/^dm-\d+$/.test(clean))       return clean;

            return clean.replace(/\d+$/, "");
        }

        path: base ? `/sys/block/${base}/device/model` : ""
        blockLoading: false

        onLoaded: {
            let model = text().trim();
            root.ssdModel = model.length > 0 ? model : "Unknown";
        }
    }

    Process {
        id: fmLauncher
    }

    FileView {
        id: diskStatsFile
        path: "/proc/diskstats"
    }

    // If mountDev is provided, use it and ignore the deviceResolver below.
    Component.onCompleted: {
        if (root.mountDev && root.mountDev !== "") {
            // If the user supplied an explicit device name, assign the 3 vars 
            // immediately at boot and leave the deviceResolver Process dormant!
            root.diskstatsDev = root.mountDev;
            root.tooltipDev = root.mountDev;
            root.deviceName = root.mountDev;
        }
    }

    Process {
        id: deviceResolver

        // If mountDev is not provided, follow the process below to find it.
        // One-shot line that runs df to find the dev name
        command: ["df", "--output=source", root.mountPoint]
        running: !root.mountDev || root.mountDev === "" // Runs once on startup if empty

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text ? text.trim().split("\n") : [];
                if (lines.length >= 2) {
                    let cleanPath = lines[lines.length - 1].trim(); // "/dev/mapper/luks-..." or "/dev/sda3"
                    let baseName = cleanPath.split("/").pop();      // "luks-8ee685..." or "sda3"

                    // CHECK FOR ENCRYPTION NATIVELY IN JAVASCRIPT
                    if (baseName.indexOf("luks-") !== -1) {
                        // IF IT IS ENCRYPTED:
                        root.luksPath = cleanPath;
                        luks2dmResolver.running = true;
                    } else {
                        // IF IT IS A STANDARD NATIVE DRIVE:
                        root.diskstatsDev = baseName;
                        root.tooltipDev = baseName;
                        root.deviceName = baseName;
                    }
                }
            }
        }
    }

    Process {
        id: luks2dmResolver
        running: false // Sits dormant until Process 1 turns it on

        // use enctryped luks device and find intermidiate dev
        command: ["readlink", "-f", root.luksPath]

        stdout: StdioCollector {
            onStreamFinished: {
                let rawText = text ? text.trim() : "";
                if (rawText.length > 0) {
                    // Extracts the short token (e.g., "/dev/dm-0" -> "dm-0")
                    root.dmDevice = rawText.split("/").pop();
                    dm2phyResolver.running = true;
                }
            }
        }
    }

    Process {
        id: dm2phyResolver
        running: false // Sits dormant until Process 2 turns it on

        // find the real physical device name
        command: ["sh", "-c", "basename " + "/sys/class/block/" + root.dmDevice + "/slaves/*"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.diskstatsDev = text ? text.trim() : "";
                root.tooltipDev = root.diskstatsDev;
                root.deviceName = root.diskstatsDev;
            }
        }
    }

    // Takes the mount point and finds and sets diskPercentUsed.
    // This should fire once every 5 seconds.
    Process {
        id: spaceLookup
        command: ["df", "--output=pcent", root.mountPoint]
        running: true 

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 2) {
                    let dataLine = lines[lines.length - 1].trim();
                    let value = parseInt(dataLine.replace("%", ""), 10);

                    if (!isNaN(value)) {
                        root._diskPercentUsed = value;
                    }
                }
            }
        }
    }

    // ==================================================================
    // Recurring capacity polling timer engine loop
    // ==================================================================
    Timer {
        id: diskUsedTimer
        interval: 5000     // 5 seconds
        repeat: true
        running: root.mountPoint !== ""

        onTriggered: {
            spaceLookup.running = true
        }
    }

    // Core high performance block I/O statistics calculator counter
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: false

        onTriggered: {
            diskStatsFile.reload()

            let rawData = diskStatsFile.text().trim();
            if (!rawData) return;

            let lines = rawData.split("\n")
            let currentReadSectors = 0
            let currentWriteSectors = 0
            let targetDev = root.diskstatsDev
            let found = false;

            for (let i = 0; i < lines.length; i++) {
                let line = lines[i].trim()
                if (line === "") continue

                if (line.indexOf(targetDev) === -1) continue;

                let tokens = line.split(/\s+/)
                if (tokens.length >= 10 && tokens[2] === targetDev) {
                    currentReadSectors = parseInt(tokens[5], 10) || 0;
                    currentWriteSectors = parseInt(tokens[9], 10) || 0;
                    found = true;
                    break;
                }
            }
            if (!found) return; 

            let state = root._diskState
            if (!state.initialized) {
                state.lastSectorsRead = currentReadSectors;
                state.lastSectorsWritten = currentWriteSectors;
                state.initialized = true;
                root._diskState = state;
                return;
            }

            let deltaReadSectors = currentReadSectors - state.lastSectorsRead;
            let deltaWriteSectors = currentWriteSectors - state.lastSectorsWritten;

            if (deltaReadSectors < 0) deltaReadSectors = 0;
            if (deltaWriteSectors < 0) deltaWriteSectors = 0;

            let readBytes = deltaReadSectors * 512;
            let writeBytes = deltaWriteSectors * 512;

            root._diskReadBytesSec = readBytes;
            root._diskWriteBytesSec = writeBytes;

            let rHist = root.historyRead.slice();
            let wHist = root.historyWrite.slice();

            rHist.push(readBytes);
            wHist.push(writeBytes);

            if (rHist.length > root.historyLimit) rHist.shift()
            if (wHist.length > root.historyLimit) wHist.shift()

            root.historyRead = rHist;
            root.historyWrite = wHist;

            // STABILITY FIX: Use safe manual loops instead of spread operator to prevent call-stack overflows
            let maxR = 1;
            for (let r = 0; r < rHist.length; r++) { if (rHist[r] > maxR) maxR = rHist[r]; }
            root._diskReadMax = maxR;

            let maxW = 1;
            for (let w = 0; w < wHist.length; w++) { if (wHist[w] > maxW) maxW = wHist[w]; }
            root._diskWriteMax = maxW;

            state.lastSectorsRead = currentReadSectors
            state.lastSectorsWritten = currentWriteSectors
            root._diskState = state
        }
    }
}
