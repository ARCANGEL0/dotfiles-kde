import QtQuick 2.15
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0
import org.kde.plasma.extras 2.0 as PlasmaExtras

ColumnLayout {
    id: mainGroup
    property alias title: groupLabel.text 

    Item {
        height: 10
    }
    PlasmaExtras.Heading {
        id: groupLabel
    }
}
