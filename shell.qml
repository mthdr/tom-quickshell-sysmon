// shell.qml
//
// GPL-3.0 license
//
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
    PanelWindow {
        id: rootWindow
        visible: true

        // ==================================================================
        // 1. Core Global Controls & Sizing Metrics
        // ==================================================================
        // Define your global scale multiplier here (0.86 to 1.20 is a good range)
        property real globalScale: 1.00

        // Main panel size
        property int mywidth: 220
        property int containerWidth: mywidth - 20
        property int widgetRadius: 8

        // Set Network device
        property string netDev: "enp9s0"

        // Position on screen and Visibility Boundaries
        color: "#00000000"
        anchors.top: true
        anchors.right: true
        margins.right: 4 
        margins.top: 4

        property string widgetBGcolor: "#DD323232"          // #AARRGGBB
        property string widgetBorderColor: "#CC000000"
        property int widgetSpacing: 5

        // ==================================================================
        // Hardware Thermal Configuration Controls
        // ==================================================================
        // Quickshell will look for CPU temp in the /sys/class/hwmon/* with these strings.
        // AMD Defaults:  "k10temp-pci-00c3" and "Tctl"
        // Intel Options: "coretemp" and "Package id 0"
        //property string cpuTempSensorChip:   "coretemp"
        //property string cpuTempSensorKey:    "Package id 0"
        property string cpuTempSensorChip:   "k10temp"
        property string cpuTempSensorKey:    "Tctl"

        // Window size bounding boxes must track raw variables if child handles transform scaling
        implicitWidth: Math.floor(mywidth * globalScale) +2
        implicitHeight: Math.floor(widgetColumn.implicitHeight * globalScale)

        // ==================================================================
        // Window Layer Stacking & Behavior Mode
        // ==================================================================
        // --- CHOOSE ONE MODE BELOW ---

        // MODE A: Always on Top (Standard Sidebar)
        // Maximize windows will flush up against it; regular apps cannot cover it.
        aboveWindows: true
        exclusionMode: ExclusionMode.Auto

        // MODE B: Wallpaper Mode (Background Widgets)
        // Normal applications will maximize and slide completely OVER the meters.
        // [To enable, uncomment the two lines below and comment out MODE A above]
        //aboveWindows: false
        //exclusionMode: ExclusionMode.Ignore

        // ==================================================================
        // 2. Compositor Mask Layer
        // ==================================================================
        mask: Region { 
            item: widgetColumn
            Region { item: clockWidget }
            Region { item: clockUTCWidget }     // uncomment when adding UTC
            Region { item: cpuWidget }
            Region { item: memoryWidget }
            Region { item: networkWidget }
            Region { item: diskWidget1 }
            Region { item: diskWidget2 }
            Region { item: diskWidget3 }
            Region { item: volumeWidget }
        }

        // ==================================================================
        // 3. Main Master Column Layout (Positioner System)
        // ==================================================================
        Column {
            id: widgetColumn
            width: rootWindow.mywidth
            height: implicitHeight
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 1
            spacing: rootWindow.widgetSpacing

            // Scaler matrix applies uniformly to the complete sub-layout hierarchy
            transform: Scale {
                origin.x: 0
                origin.y: 0
                xScale: rootWindow.globalScale
                yScale: rootWindow.globalScale
            }

            // ----------------------------------
            // Clock Widget
            // ----------------------------------
            Clock {
                id: clockWidget
                containerWidth: rootWindow.containerWidth
                width: parent.width
            }

            // ----------------------------------
            // Clock UTC widget  (uncomment to add UTC clock)
            // ----------------------------------
            ClockUTC {
                id: clockUTCWidget
                containerWidth: rootWindow.containerWidth
                width: parent.width
            }

            // ----------------------------------
            // CPU Widget
            // ----------------------------------
            CpuGraph {
                id: cpuWidget

                containerWidth: rootWindow.containerWidth
                sensorChipName: rootWindow.cpuTempSensorChip
                sensorKeyName:  rootWindow.cpuTempSensorKey

                width: parent.width
            }


            // ----------------------------------
            // MemSwap Widget
            // ----------------------------------
            MemSwap {
                id: memoryWidget
                containerWidth: rootWindow.containerWidth
                width: parent.width
            }

            // ----------------------------------
            // Network Widget
            // ----------------------------------
            Network {
                id: networkWidget
                containerWidth: rootWindow.containerWidth
                width: parent.width
            }


            // ----------------------------------
            // Disk widget 1
            // ----------------------------------
            Disk {
                id: diskWidget1                    // CHANGE THIS  *****

                modelSize: "SSD M.2 4.0T"          // CHANGE THIS  *****
                mountPoint: "/home"                // CHANGE THIS  *****
                mountDev: ""                       // leave this blank, unless needed *****
                containerWidth: rootWindow.containerWidth

                width: parent.width
            }

            // ----------------------------------
            // Disk widget 2
            // ----------------------------------
            Disk {
                id: diskWidget2                    // CHANGE THIS  *****

                modelSize: "Disk USB 4.0T"         // CHANGE THIS  *****
                mountPoint: "/backups"             // CHANGE THIS  *****
                mountDev: ""                       // leave this blank, unless needed *****
                containerWidth: rootWindow.containerWidth

                width: parent.width
            }

            // ----------------------------------
            // Disk widget 3
            // ----------------------------------
            Disk {
                id: diskWidget3                    // CHANGE THIS  *****

                modelSize: "SSD PCIe 1.6T"         // CHANGE THIS  *****
                mountPoint: "/timeshift"           // CHANGE THIS  *****
                mountDev: ""                       // leave this blank, unless needed *****
                containerWidth: rootWindow.containerWidth

                width: parent.width
            }

            // ----------------------------------
            // Volume widget
            // ----------------------------------
            Volume {
                id: volumeWidget
                containerWidth: rootWindow.containerWidth
                width: parent.width
            }

        } // End of master widgetColumn
    }
}

