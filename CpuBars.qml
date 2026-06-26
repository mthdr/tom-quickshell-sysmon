// CpuBars.qml
//
// GPL-3.0 license
//
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // ==================================================================
    // 1. User Tweakable Configurations & Variables
    // ==================================================================
    required property real containerWidth
    property int barSpacing: 1
    property color barColor: "white"
    
    // Core Sizing Rule: Ensure bounds match children geometries perfectly
    width: containerWidth
    height: mainColumn.height

    property var coreUsages: []
    property var lastCoreTotal: []
    property var lastCoreIdle: []

    // ==================================================================
    // 2. Display Data on UI Layout (Standardized Positioner)
    // ==================================================================
    Column {
        id: mainColumn
        width: parent.width
        spacing: 1

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
                    if (totalCores === 0) return 1;
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
                            height: Math.max(0, Math.min(parent.height, parent.height * (modelData / 100.0)))
                            color: root.barColor
                        }
                    }
                }
            }
        }
    }

    // ==================================================================
    // 3. High Performance, Zero-Fork Data Gathering Subsystems
    // ==================================================================
    FileView {
        id: statReader
        path: "/proc/stat"
        
        onLoaded: {
            let content = (typeof text === "function") ? text() : text;
            if (!content) return;
            
            let lines = content.split("\n");
            let newCoreTotal = [];
            let newCoreIdle = [];
            let newCoreUsage = [];

            // 1. First pass: Determine max core index safely
            let maxIndex = -1;
            for (let i = 0; i < lines.length; i++) {
                let line = lines[i].trim();
                let parts = line.split(/\s+/);
                if (parts[0].startsWith("cpu") && parts[0].length > 3) {
                    let coreNumStr = parts[0].substring(3);
                    let idx = parseInt(coreNumStr);
                    if (!isNaN(idx)) {
                        maxIndex = Math.max(maxIndex, idx);
                    }
                }
            }

            if (maxIndex === -1) return; // No per-core metrics parsed

            // Initialize data vectors
            for (let i = 0; i <= maxIndex; i++) {
                newCoreUsage.push(0);
                newCoreTotal.push(0);
                newCoreIdle.push(0);
            }

            // 2. Second pass: Calculate differential core delta loads
            for (let i = 0; i < lines.length; i++) {
                let line = lines[i].trim();
                let parts = line.split(/\s+/);
                
                // Matches individual lines (cpu0, cpu1, cpu12, etc.) but skips aggregate total "cpu " line
                if (parts[0].startsWith("cpu") && parts[0].length > 3 && !isNaN(parseInt(parts[0].charAt(3)))) {
                    let coreIndex = parseInt(parts[0].substring(3));
                    let idle = parseInt(parts[4]) || 0; // Index 4 matches core idle state cycles
                    
                    let total = 0;
                    for (let j = 1; j < parts.length; j++) {
                        total += parseInt(parts[j]) || 0;
                    }

                    if (root.lastCoreTotal[coreIndex] !== undefined) {
                        let dTotal = total - root.lastCoreTotal[coreIndex];
                        let dIdle = idle - root.lastCoreIdle[coreIndex];
                        
                        let usage = 0;
                        if (dTotal > 0) {
                            //usage = 100 * (1 - (dIdle / dTotal));
                            usage = 100 * (1 - (dIdle / dTotal));
                        }
                        newCoreUsage[coreIndex] = usage;
                    }
                    
                    newCoreTotal[coreIndex] = total;
                    newCoreIdle[coreIndex] = idle;
                }
            }

            // Atomically update data properties to avoid layout micro-stuttering
            root.coreUsages = newCoreUsage;
            root.lastCoreTotal = newCoreTotal;
            root.lastCoreIdle = newCoreIdle;
        }
    }

    // ==================================================================
    // Unified Control Loops
    // ==================================================================
    Timer {
        interval: 600
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statReader.reload();
        }
    }
}

