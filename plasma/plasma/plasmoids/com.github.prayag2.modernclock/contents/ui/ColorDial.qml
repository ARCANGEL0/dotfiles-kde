import QtQuick 2.15
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.15
import QtQuick.Dialogs
import org.kde.kirigami 2.4 as Kirigami
import org.kde.kquickcontrols 2.0 as KQControls

RowLayout {
    id: root
    property var color;

    Label {
        text: i18n("Font Color")
    }             
    KQControls.ColorButton {
      id: colorbutton
      color: root.color
      showAlphaChannel: false

      onAccepted: {
        root.color = color
      }
    }
}

