import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import "."

PlasmoidItem {
    id: root
    width: 400
    height: 300
    
    Plasmoid.title: "Visualizer V2"
    Plasmoid.icon: "audio-x-generic"

    AudioEngine {
        id: audioEngine
        Component.onCompleted: {
            setGain(0.1)
            setFalloff(0.5)
            setBarHeight(0.1)
            // Start capture on the 5th device (index 4)
            startCapture(-1)
        }
    }

    fullRepresentation: Item {
        Layout.minimumWidth: 400
        Layout.minimumHeight: 300

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            // Visualizer Area
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                Row {
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    spacing: 1

                    Repeater {
                        model: audioEngine.magnitudes.length
                        
                        Rectangle {
                            width: Math.max(1, (parent.width / (audioEngine.magnitudes.length || 1)) - 1)
                            height: audioEngine.magnitudes[index] * parent.height
                            color: "cyan"
                            anchors.bottom: parent.bottom
                            
                            Behavior on height {
                                NumberAnimation { duration: 50 }
                            }
                        }
                    }
                }
            }

            // Controls
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                
                PlasmaComponents.ComboBox {
                    id: deviceCombo
                    model: audioEngine.getCaptureDevices()
                    currentIndex: 0
                    onActivated: audioEngine.startCapture(currentIndex)
                    Layout.preferredWidth: 150
                }

                Button {
                    text: "Refresh"
                    onClicked: deviceCombo.model = audioEngine.getCaptureDevices()
                }
            }
        }
    }
}
