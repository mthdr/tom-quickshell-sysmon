// shell.qml
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
        property int myheight: 1440 // You can safely set this to your screen height
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

        // ==================================================================
        // Hardware Thermal Configuration Controls
        // ==================================================================
        // run "sensors -j" to see all sensor data to choose your temp sensor
        // AMD Defaults:  "k10temp-pci-00c3" and "Tctl" and "temp1_input"
        // Intel Options: "coretemp-isa-0000" and "Package id 0" and "temp1_input"
        property string cpuTempSensorChip:   "k10temp-pci-00c3"
        property string cpuTempSensorKey:    "Tctl"
        property string cpuTempSensorSubKey: "temp1_input"

        // Window size bounding boxes must track raw variables if child handles transform scaling
        implicitWidth: Math.floor(mywidth * globalScale) +2
        implicitHeight: Math.floor(myheight * globalScale)

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
            item: clockWidget
            Region { item: clockWidget }
//            Region { item: clockUTCWidget }     // uncomment when adding UTC
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
            height: rootWindow.myheight
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 1
            spacing: 5
            
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
            Rectangle {
                id: clockWidget
                width: parent.width
                height: Math.floor(0.283 * rootWindow.mywidth + 61.8)
                radius: rootWindow.widgetRadius
                color: "#CC323232"
                border.color: "#CC000000"
                border.width: 2

                Clock {
                    width: parent.width
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // ----------------------------------
            // Clock UTC widget  (uncomment to add UTC clock)
            // ----------------------------------
//            Rectangle {
//                id: clockUTCWidget
//                width: parent.width
//                height: Math.floor(0.233 * rootWindow.mywidth + 49.8)
//                radius: rootWindow.widgetRadius
//                color: "#CC323232"
//                border.color: "#CC000000"
//                border.width: 2
//
//                ClockUTC {
//                    width: parent.width
//                    anchors.top: parent.top
//                    anchors.horizontalCenter: parent.horizontalCenter
//                }
//            }

            // ----------------------------------
            // CPU Widget
            // ----------------------------------
            Rectangle {
                id: cpuWidget
                width: parent.width
                height: 142
                radius: rootWindow.widgetRadius
                color: "#CC323232"
                border.color: "#CC000000"
                border.width: 2

                Column {
                    id: cpuColumn
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 3
                    spacing: 5

                    CpuGraph {
                        containerWidth: rootWindow.containerWidth
                        sensorChipName: rootWindow.cpuTempSensorChip
                        sensorKeyName:  rootWindow.cpuTempSensorKey
                        sensorSubKey:   rootWindow.cpuTempSensorSubKey
                    }

                    CpuBars {
                        containerWidth: rootWindow.containerWidth
                    }
                }
            }

            // ----------------------------------
            // MemSwap Widget
            // ----------------------------------
            Rectangle {
                id: memoryWidget
                width: parent.width
                height: 116
                radius: rootWindow.widgetRadius
                color: "#CC323232"
                border.color: "#CC000000"
                border.width: 2

                MemSwap {
                    containerWidth: rootWindow.containerWidth
                    anchors.top: parent.top
                    anchors.topMargin: 3
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // ----------------------------------
            // Network Widget
            // ----------------------------------
            Rectangle {
                id: networkWidget
                width: parent.width
                height: 134
                radius: rootWindow.widgetRadius
                color: "#CC323232"
                border.color: "#CC000000"
                border.width: 2

                Network {
                    containerWidth: rootWindow.containerWidth
                    anchors.top: parent.top
                    anchors.topMargin: 3
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }


            // ----------------------------------
            // Disk widget 1
            // ----------------------------------
            Rectangle {
                id: diskWidget1                      // CHANGE THIS  *****
                width: parent.width
                height: 142
                radius: rootWindow.widgetRadius
                color: "#CC323232"
                border.color: "#CC000000"
                border.width: 2

                // Standardized Header Container (Left & Right text)
                Item {
                    id: disk1Header
                    width: rootWindow.containerWidth
                    height: 18
                    anchors.top: parent.top
                    anchors.topMargin: 1
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        anchors.left: parent.left
                        color: "white"
                        font.pixelSize: 14
                        text: "SSD M.2 4.0T"         // CHANGE THIS  *****
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom // Aligns base fonts cleanly
                        anchors.bottomMargin: 2
                        color: "white"
                        font.pixelSize: 10
                        text: "(/home)"              // CHANGE THIS  *****
                    }
                }

                Disk {
                    containerWidth: rootWindow.containerWidth
                    mountPoint: "/home"                // CHANGE THIS  *****
                    mountDev: ""                       // or THIS, normally not needed *****
                    anchors.top: disk1Header.bottom
                    anchors.topMargin: 0
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // ----------------------------------
            // Disk widget 2
            // ----------------------------------
            Rectangle {
                id: diskWidget2                      // CHANGE THIS  *****
                width: parent.width
                height: 142
                radius: rootWindow.widgetRadius
                color: "#CC323232"
                border.color: "#CC000000"
                border.width: 2

                Item {
                    id: disk2Header
                    width: rootWindow.containerWidth
                    height: 18
                    anchors.top: parent.top
                    anchors.topMargin: 1
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        anchors.left: parent.left
                        color: "white"
                        font.pixelSize: 14
                        text: "Disk USB 4.0T"        // CHANGE THIS  *****
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        color: "white"
                        font.pixelSize: 10
                        text: "(/backups)"           // CHANGE THIS  *****
                    }
                }

                Disk {
                    containerWidth: rootWindow.containerWidth
                    mountPoint: "/backups"             // CHANGE THIS  *****
                    mountDev: ""                       // or THIS, normally not needed *****
                    anchors.top: disk2Header.bottom
                    anchors.topMargin: 0
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // ----------------------------------
            // Disk widget 3
            // ----------------------------------
            Rectangle {
                id: diskWidget3                      // CHANGE THIS  *****
                width: parent.width
                height: 142
                radius: rootWindow.widgetRadius
                color: "#CC323232"
                border.color: "#CC000000"
                border.width: 2

                Item {
                    id: disk3Header
                    width: rootWindow.containerWidth
                    height: 18
                    anchors.top: parent.top
                    anchors.topMargin: 1
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        anchors.left: parent.left
                        color: "white"
                        font.pixelSize: 14
                        text: "SSD PCIe 1.6T"        // CHANGE THIS  *****
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        color: "white"
                        font.pixelSize: 10
                        text: "(/timeshift)"         // CHANGE THIS  *****
                    }
                }

                Disk {
                    containerWidth: rootWindow.containerWidth
                    mountPoint: "/timeshift"           // CHANGE THIS  *****
                    mountDev: ""                       // or THIS, normally not needed *****
                    anchors.top: disk3Header.bottom
                    anchors.topMargin: 0
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // ----------------------------------
            // Volume widget
            // ----------------------------------
            Rectangle {
                id: volumeWidget
                width: parent.width
                height: 50
                radius: rootWindow.widgetRadius
                color: "#CC323232"
                border.color: "#CC000000"
                border.width: 2

                Volume {
                    containerWidth: rootWindow.containerWidth
                    anchors.top: parent.top
                    anchors.topMargin: 5
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

        } // End of master widgetColumn
    }
}

