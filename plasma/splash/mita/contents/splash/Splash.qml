import QtQuick 2.15

Rectangle {
    width: 800
    height: 600
    color: "#121212"

    AnimatedImage {
        anchors.fill: parent
        source: "/usr/share/plasma/look-and-feel/mita/contents/splash/images/mita.gif"
        playing: true
        fillMode: Image.PreserveAspectCrop
    }
}
