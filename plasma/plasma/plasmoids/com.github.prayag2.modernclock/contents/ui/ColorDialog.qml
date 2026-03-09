RowLayout {
        Label {
            text: i18n("Font Color")
        }             
        Rectangle {
            id: colorbutton
            height: PlasmaCore.Units.gridUnit * 1.3; width: height
            border.width: 1
            border.color: "gray"
            color: cfg_font_color
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    colordialog.visible=true
                }
            }
        }
    }
    ColorDialog {
        id: colordialog
        title: i18n("Select a color")
        onAccepted: {
            cfg_font_color=color
        }
    }
