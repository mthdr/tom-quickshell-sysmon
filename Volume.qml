// Volume.qml
//
// GPL-3.0 license
//
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets

Rectangle {
    id: root

    // ==================================================================
    // 1. User Tweakable Configurations & Variables
    // ==================================================================
    required property real containerWidth

    // STABILITY FIX: Lock to a solid static layout height. This guarantees 
    // that shell.qml can dynamically shrink-wrap your master sidebar.
    height: 46
    radius: rootWindow.widgetRadius
    color: rootWindow.widgetBGcolor
    border.color: rootWindow.widgetBorderColor
    border.width: 2

    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    }

    // ==================================================================
    // 2. Display Data on UI Layout (Standardized Positioner)
    // ==================================================================
    Column {
        id: mainColumn
        width: root.containerWidth
        spacing: 4
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter

        // -----------------------------------------------
        // --- 1. Volume Text Header Row Container ---
        // -----------------------------------------------
        Item {
            width: parent.width
            height: 16

            // Left Label
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: "#FFFFFF"
                font.pixelSize: 14
                text: "Volume"
            }

            // Interactive Mute/Unmute Text (Guaranteed Pixel-Perfect Centering)
            Text {
                id: muteText
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 14
                font.bold: true

                text: (Pipewire.defaultAudioSink?.audio.muted ?? false) ? "MUTED" : "MUTE"
                color: (Pipewire.defaultAudioSink?.audio.muted ?? false) ? "#FF0000" : "grey"

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        if (Pipewire.defaultAudioSink?.audio) {
                            let isMuted = Pipewire.defaultAudioSink.audio.muted;
                            Pipewire.defaultAudioSink.audio.muted = !isMuted;
                        }
                    }
                }
            }

            // Right Percentage Status Indicator
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: "#00FF00"
                font.pixelSize: 14
                text: Math.floor((Pipewire.defaultAudioSink?.audio.volume ?? 0) * 100) + "%"
            }
        }

        // -----------------------------------------------
        // --- 2. Interactive Audio Track Bar ---
        // -----------------------------------------------
        Rectangle {
            id: barContainer
            width: parent.width
            height: 12
            border.color: (Pipewire.defaultAudioSink?.audio.muted ?? false) ? "#339933" : "#55FF55"
            border.width: 1            
            color: "#66000000"

            Rectangle {
                id: barFill
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 1 
                width: Math.max(0, (parent.width - 2) * (Pipewire.defaultAudioSink?.audio.volume ?? 0))
                color: (Pipewire.defaultAudioSink?.audio.muted ?? false) ? "#339933" : "#55FF55"
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true 

                // Volume Slider Wheel Scroll Handler
                onWheel: wheel => {
                    const step = 0.05; 
                    let currentVol = Pipewire.defaultAudioSink?.audio.volume ?? 0;
                    if (wheel.angleDelta.y > 0) {
                        Pipewire.defaultAudioSink.audio.volume = Math.min(1.0, currentVol + step);
                    } else {
                        Pipewire.defaultAudioSink.audio.volume = Math.max(0.0, currentVol - step);
                    }
                }

                // Volume Slider Click Execution Handler
                onClicked: mouse => {
                    if (Pipewire.defaultAudioSink?.audio) {
                        let newVol = mouse.x / parent.width;
                        Pipewire.defaultAudioSink.audio.volume = Math.max(0.0, Math.min(1.0, newVol));
                    }
                }

                // Volume Slider Active Click Drag Handler
                onPositionChanged: mouse => {
                    if (mouse.pressed && Pipewire.defaultAudioSink?.audio) {
                        // ROBUSTNESS FIX: Bound your drag coordinates safely between 0 and 1
                        // to prevent desktop rendering glitches if the mouse exits the widget frame.
                        let newVol = mouse.x / parent.width;
                        Pipewire.defaultAudioSink.audio.volume = Math.max(0.0, Math.min(1.0, newVol));
                    }
                }
            }
        }
    }
}

