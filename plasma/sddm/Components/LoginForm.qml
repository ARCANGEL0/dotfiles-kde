// arcangel0


import QtQuick 2.15
import QtQuick.Layouts 1.15
import SddmComponents 2.0 as SDDM

ColumnLayout {
    id: formContainer
    SDDM.TextConstants { id: textConstants }

    property int p: config.ScreenPadding == "" ? 0 : config.ScreenPadding
    property string a: config.FormPosition

    Clock {
        id: clock

        Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
        // important
        Layout.preferredHeight: root.height / 3
        Layout.leftMargin: p != "0" ? a == "left" ? -p : a == "right" ? p : 0 : 0
    }

    Input {
        id: input

        Layout.alignment: Qt.AlignVCenter
        Layout.preferredHeight: root.height / 10
        Layout.leftMargin: p != "0" ? a == "left" ? -p : a == "right" ? p : 0 : 0
        Layout.topMargin:  0
    }

    SystemButtons {
        id: systemButtons

        Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
        Layout.preferredHeight: root.height / 5
        Layout.maximumHeight: root.height / 5
        Layout.leftMargin: p != "0" ? a == "left" ? -p : a == "right" ? p : 0 : 0
        
        exposedSession: input.exposeSession
    }
    
    SessionButton {
        id: sessionSelect

        Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
        Layout.preferredHeight: root.height / 54
        Layout.maximumHeight: root.height / 54
        Layout.leftMargin: p != "0" ? a == "left" ? -p : a == "right" ? p : 0 : 0
    }

    VirtualKeyboardButton {
        id: virtualKeyboardButton

        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
        Layout.preferredHeight: root.height / 27
        Layout.maximumHeight: root.height / 27
        Layout.leftMargin: p != "0" ? a == "left" ? -p : a == "right" ? p : 0 : 0
    }
}
