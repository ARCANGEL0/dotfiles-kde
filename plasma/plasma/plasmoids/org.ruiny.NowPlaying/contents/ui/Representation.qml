import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

MouseArea {
    id: mediaControlsMouseArea
    focus: true
    Keys.onPressed: {
        if (!event.modifiers) {
            event.accepted = true
            if (event.key === Qt.Key_Space || event.key === Qt.Key_K) {
                player.togglePlayPause()
            } else if (event.key === Qt.Key_P) {
                player.previous()
            } else if (event.key === Qt.Key_N) {
                player.next()
            } else {
                event.accepted = false
            }
        }
    }
    hoverEnabled: true

    readonly property double buttonSize: 16

    RowLayout {
        ColumnLayout {
            Layout.fillHeight: true
            id: leftColumn

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

            ColumnLayout {
                id: nowPlayingLabels
                Layout.alignment: Qt.AlignRight
                spacing: 0

                Label {
                   Layout.alignment: Qt.AlignRight
                    text: "NOW"
                    lineHeight: 0.8
                    font.pixelSize: 16
                    font.bold: true
                    font.family: plasmoid.configuration.fontFamily
                }
                Label {
                    id: nowPlayingLabel2
                    Layout.alignment: Qt.AlignRight
                    text: "PLAYING"
                    lineHeight: 0.8
                    font.bold: true
                    font.pixelSize: 16
                    font.family: plasmoid.configuration.fontFamily
                }
            }

            RowLayout {
                id: mediaControls
                Layout.alignment: Qt.AlignHCenter
                opacity: mediaControlsMouseArea.containsMouse ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    PropertyAnimation {
                        easing.type: Easing.InOutQuad
                        duration: 250
                    }
                }

                Button {
                    Layout.preferredWidth: buttonSize
                    Layout.preferredHeight: buttonSize
                    contentItem: Kirigami.Icon {
                        source: "media-skip-backward"
                    }
                    padding: 0
                    background: null
                    onClicked: {
                        player.previous()
                        console.log("prev clicked")
                    }
                }
                Button {
                    Layout.preferredWidth: buttonSize
                    Layout.preferredHeight: buttonSize
                    id: playButton
                    contentItem: Kirigami.Icon {
                        source: player.playbackStatus === 2 ? "media-playback-pause" : "media-playback-start"
                    }
                    padding: 0
                    background: null
                    onClicked: {
                        player.togglePlayPause()
                        console.log("pause clicked")
                    }
                }
                Button {
                    Layout.preferredWidth: buttonSize
                    Layout.preferredHeight: buttonSize
                    contentItem: Kirigami.Icon {
                        source: "media-skip-forward"
                    }
                    onClicked: {
                        player.next()
                    }
                    padding: 0
                    background: null
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

            states: [
                State {
                    name: "buttonsVisible"
                    when: mediaControlsMouseArea.containsMouse
                    PropertyChanges {
                        target: nowPlayingLabels
                        Layout.bottomMargin: 10
                    }
                },
                State {
                    name: "buttonsHidden"
                    when: !mediaControlsMouseArea.containsMouse
                    PropertyChanges {
                        target: nowPlayingLabels
                        Layout.bottomMargin: 0
                    }
                }
            ]

            transitions: Transition {
                NumberAnimation {
                    properties: "Layout.bottomMargin"
                    duration: 250
                    easing.type: Easing.InOutQuad
                }
            }
        }

        Rectangle {
            id: separator
            width: 1
            Layout.fillHeight: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            id: infoColumn
            PlasmaComponents.Label {
                font.family: plasmoid.configuration.fontFamily
                text: player.title
                Layout.fillWidth: true
                font.pixelSize: 28
                lineHeight: 0.8
                font.bold: true
                elide: Text.ElideRight
            }
            PlasmaComponents.Label {
                font.family: plasmoid.configuration.fontFamily
                elide: Text.ElideRight
                Layout.maximumWidth: 300
                Layout.fillWidth: true
                text: player.artists
                font.pixelSize: 26
                lineHeight: 0.8
            }
        }
    }
}
