// Disk.qml
//
// GPL-3.0 license
//
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    // ==================================================================
    // 1. User Tweakable Configurations & Variables
    // ==================================================================
    required property int containerWidth
    required property string mountPoint
    required property string mountDev
    required property string modelSize
    
    // Core Sizing Rule: Ensure the root object bounds trace the Column children perfectly
    width: containerWidth
    height: mainColumn.height

    // Dynamic Sizing Metrics
    property int historyLimit: containerWidth - 2

    property string devicePath: ""            // Will become "/dev/nvme1n1p3" dynamically
    property string deviceName: ""            // Will become "nvme1n1p3" dynamically
    property string ssdModel: ""              // Will become "SSD Model number" dynamically
    
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

    // Helper formatting function to convert Bytes/sec to readable metrics (KB/s, MB/s)
    function formatSpeed(bytes) {
        if (bytes >= 1024 * 1024 * 1024) return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GB/s"
        if (bytes >= 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + " MB/s"
        if (bytes >= 1024) return (bytes / 1024).toFixed(1) + " KB/s"
        return bytes.toFixed(0) + " B/s"
    }

    // ==================================================================
    // 2. Display Data on UI Layout
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
//            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                anchors.left: parent.left
                color: "white"
                font.pixelSize: 14
                text: modelSize
            }
            Text {
                anchors.right: parent.right
                anchors.bottom: parent.bottom // Aligns base fonts cleanly
                anchors.bottomMargin: 2
                color: "white"
                font.pixelSize: 10
                text: "(" + root.mountPoint + ")" 
            }

            HoverHandler {
                id: textHover2
            }

            Tooltip {
                id: ssdModTooltip
                target: diskHeader
                show: textHover2.hovered
                text: root.ssdModel
                fontPixelSize: 18
            }
        }

        // -------------------------------------------
        // --- 1. Read Metrics Text Layout (Left & Right alignment)
        // -------------------------------------------
        Item {
            width: parent.width
            height: 14 // Tight structural boundary

            Text {
                anchors.left: parent.left
                anchors.top: diskHeader.bottom
                anchors.topMargin: -2 // Shifts read text slightly upwards
                color: "#00BBFF" // Bluish tone
                font.pixelSize: 12
                text: "Read: " + root.formatSpeed(root.diskReadBytesSec)
            }
            Text {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: -2
                color: "#00BBFF" // Bluish tone
                font.pixelSize: 12
                text: "(Max: " + root.formatSpeed(root.diskReadMax) + ")"
            }
        }

        // -------------------------------------------
        // --- 2. Read Graph (Normal Upward)
        // -------------------------------------------
        Rectangle {
            id: readGraphBox
            width: parent.width
            height: 40
            color: "#66000000"
            border.color: "#AA000000"
            border.width: 1
            
            // Shifted upper graph up 1px by applying a small negative top margin
            anchors.topMargin: -1 

            Canvas {
                id: readCanvas
                anchors.fill: parent
                anchors.margins: 1
                Connections { target: root; function onHistoryReadChanged() { readCanvas.requestPaint() } }

                onPaint: {
                    let ctx = getContext("2d")
                    ctx.reset()
                    if (root.historyRead.length < 2) return

                    ctx.fillStyle = "#00BBFF"
                    ctx.strokeStyle = "#00BBFF"
                    ctx.lineWidth = 1
                    ctx.beginPath()
                    ctx.moveTo(width, height)

                    let step = width / (root.historyLimit - 1)
                    for (let i = 0; i < root.historyRead.length; i++) {
                        let idx = root.historyRead.length - 1 - i
                        let x = width - (i * step)
                        let y = height - ((root.historyRead[idx] / root.diskReadMax) * height)
                        ctx.lineTo(x, y)
                    }
                    let lastX = width - ((root.historyRead.length - 1) * step)
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
            height: 12 // Increased container bounds slightly to pad layout transitions

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
                    anchors.margins: 1
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
                    fontPixelSize: 18
                }
            }
        }

        // -------------------------------------------
        // --- 4. Write Graph (Flipped Vertically, 0 at Top)
        // -------------------------------------------
        Rectangle {
            width: parent.width
            height: 40
            color: "#66000000"
            border.color: "#AA000000"
            border.width: 1

            Canvas {
                id: writeCanvas
                anchors.fill: parent
                anchors.margins: 1
                
                transform: [
                    Scale { yScale: -1 },
                    Translate { y: writeCanvas.height }
                ]

                Connections { target: root; function onHistoryWriteChanged() { writeCanvas.requestPaint() } }

                onPaint: {
                    let ctx = getContext("2d")
                    ctx.reset()
                    if (root.historyWrite.length < 2) return

                    ctx.fillStyle = "#ff3333"
                    ctx.strokeStyle = "#ff3333"
                    ctx.lineWidth = 1
                    ctx.beginPath()
                    ctx.moveTo(width, height)

                    let step = width / (root.historyLimit - 1)
                    for (let i = 0; i < root.historyWrite.length; i++) {
                        let idx = root.historyWrite.length - 1 - i
                        let x = width - (i * step)
                        let y = height - ((root.historyWrite[idx] / root.diskWriteMax) * height)
                        ctx.lineTo(x, y)
                    }
                    let lastX = width - ((root.historyWrite.length - 1) * step)
                    ctx.lineTo(lastX, height)
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
            width: parent.width // Standardized to fill layout cleanly
            height: 14

            Text {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.topMargin: -2 // Replaced hardcoded 'y: -2' with top margin anchors
                color: "#FF3333" // Reddish tone
                font.pixelSize: 12
                text: "Write: " + root.formatSpeed(root.diskWriteBytesSec)
            }
            Text {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: -2
                color: "#FF3333" // Reddish tone
                font.pixelSize: 12
                text: "(Max: " + root.formatSpeed(root.diskWriteMax) + ")"
            }
        }
    } // End of mainColumn

    // ==================================================================
    //  Data Gathering & Shell Resolution Systems
    // ==================================================================
    FileView {
        id: modelFile
        property string clean: deviceName.replace(/^\/dev\//, "")
        
        // Logic:
        // 1. If NVMe: Remove 'n' + digits + optional 'p' + digits. Keep 'nvmeX'.
        // 2. If SD: Remove trailing digits. Keep 'sdX'.
        property string base: {
            if (clean.startsWith("nvme"))
                return clean.replace(/n\d+(p\d+)?$/, ""); // Handles nvme0n1 AND nvme0n1p3
            else if (clean.startsWith("sd"))
                return clean.replace(/\d+$/, ""); // Handles sdd1 -> sdd
            return "";
        }

        path: {
            if (!base) return "";
            if (base.startsWith("nvme"))
                return `/sys/class/nvme/${base}/model`;
            else
                return `/sys/class/block/${base}/device/model`;
        }

        blockLoading: true
        onLoaded: {
            root.ssdModel = text().trim();
        }
    }

    FileView {
        id: diskStatsFile
        path: "/proc/diskstats"
    }

    // Resolves real storage target block partition dynamically via mount path point string
    Process {
        id: deviceResolver
        command: ["df", root.mountPoint, "--output=source"]
        running: true 

        stdout: SplitParser {
            onRead: data => {
                let cleanPath = data ? data.trim() : ""
                if (cleanPath.length > 0 && cleanPath !== "Filesystem") {
                    root.devicePath = cleanPath
                    root.deviceName = root.mountDev || cleanPath.split("/").pop()
                    
                    // Trigger immediate capacity parsing execution loop pass
                    spaceLookup.running = true
                }
            }
        }
    }

    // Parses active filesystem payload occupancy percentage strings
    Process {
       id: spaceLookup
       command: ["df", root.devicePath]
       running: false // Managed manually by initializer trigger and periodic timers

       stdout: SplitParser {
           onRead: data => {
              let cleanText = data ? data.trim() : ""
              
              // Filter out kernel tracking line labels
              if (cleanText.length > 0 && !cleanText.startsWith("Filesystem")) {
                  let parts = cleanText.split(/\s+/)
                  
                  // Extract raw usage integer from Column 5 (Index 4)
                  if (parts.length >= 5) {
                      let percentStr = parts[4].replace("%", "")
                      let value = parseInt(percentStr)
                      
                      if (!isNaN(value)) {
                          root._diskPercentUsed = value
                      }
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
       interval: 5000 // 5 seconds matches your tracking preferences perfectly
       running: true
       repeat: true
       onTriggered: {
          // Guard rule skips invocation updates if node name strings are unset
          if (root.devicePath !== "") {
              spaceLookup.running = true
          }
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
            let rawData = (typeof diskStatsFile.text === "function") ? diskStatsFile.text() : diskStatsFile.text
            if (!rawData) return

            let lines = rawData.split("\n")
            let currentReadSectors = 0
            let currentWriteSectors = 0
            let targetDev = root.deviceName

            // Parse diskstats token sequences via index allocations
            for (let i = 0; i < lines.length; i++) {
                let line = lines[i].trim()
                if (line === "") continue
                
                let tokens = line.split(/\s+/)
                if (tokens.length >= 10 && tokens[2] === targetDev) {
                    currentReadSectors = parseInt(tokens[5]) || 0    // Index 5 matches standard block reads
                    currentWriteSectors = parseInt(tokens[9]) || 0   // Index 9 matches standard block writes
                    break
                }
            }

            let state = root._diskState
            if (!state.initialized) {
                if (currentReadSectors > 0 || currentWriteSectors > 0) {
                    state.lastSectorsRead = currentReadSectors
                    state.lastSectorsWritten = currentWriteSectors
                    state.initialized = true
                    root._diskState = state
                }
                return
            }
            
            let deltaReadSectors = currentReadSectors - state.lastSectorsRead
            let deltaWriteSectors = currentWriteSectors - state.lastSectorsWritten
            if (deltaReadSectors < 0) deltaReadSectors = 0
            if (deltaWriteSectors < 0) deltaWriteSectors = 0

            // Linux sector sizes inside /proc/diskstats are universally fixed at 512 Bytes
            root._diskReadBytesSec = deltaReadSectors * 512
            root._diskWriteBytesSec = deltaWriteSectors * 512
            
            let rHist = [...root.historyRead]
            let wHist = [...root.historyWrite]
            rHist.push(root._diskReadBytesSec)
            wHist.push(root._diskWriteBytesSec)

            if (rHist.length > root.historyLimit) rHist.shift()
            if (wHist.length > root.historyLimit) wHist.shift()
            root.historyRead = rHist
            root.historyWrite = wHist

            // Dynamic graph vertical canvas scaling boundary checks
            root._diskReadMax = Math.max(...rHist, 1)
            root._diskWriteMax = Math.max(...wHist, 1)

            state.lastSectorsRead = currentReadSectors
            state.lastSectorsWritten = currentWriteSectors
            root._diskState = state
        }
    }
}

