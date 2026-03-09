import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.private.mpris as Mpris
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Layout.minimumWidth: Kirigami.Units.gridUnit*25
    Layout.minimumHeight: Kirigami.Units.gridUnit*5

    Plasmoid.backgroundHints: "NoBackground"

    opacity: plasmoid.configuration.opacity/100

    Representation{
        anchors.fill: parent
    }


    Player{
        id: player
    }
}
