import QtQml 2.15
import QtQuick 2.0
import QtQuick.Layouts 1.0
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root
    
    
    // setting background as transparent with a drop shadow
    Plasmoid.backgroundHints: PlasmaCore.Types.ShadowBackground | PlasmaCore.Types.ConfigurableBackground
    
    // loading fonts
    FontLoader {
        id: font_anurati
        source: "../fonts/Anurati.otf"
    }
    FontLoader {
        id: font_poppins
        source: "../fonts/Poppins.ttf"
    }
    

    // setting preferred size
    preferredRepresentation: fullRepresentation
    fullRepresentation: Item {

        // applet default size
        Layout.minimumWidth: container.implicitWidth
        Layout.minimumHeight: container.implicitHeight
        Layout.preferredWidth: Layout.minimumWidth
        Layout.preferredHeight: Layout.minimumHeight

        // Updating time every minute
        Plasma5Support.DataSource {
            id: dataSource
            engine: "time"
            connectedSources: ["Local"]
            intervalAlignment: Plasma5Support.Types.AlignToMinute
            interval: 60000

            property bool use24HourFormat: plasmoid.configuration.use_24_hour_format
            property string timeCharacter: plasmoid.configuration.time_character
            property string dateFormat: plasmoid.configuration.date_format
            
            onUse24HourFormatChanged: dataChanged()
            onTimeCharacterChanged: dataChanged()
            onDateFormatChanged: dataChanged()

            onDataChanged: {
                var time_format = use24HourFormat ? "hh:mm" : "hh:mm AP"
                var curDate = dataSource.data["Local"]["DateTime"]
                display_day.text = Qt.formatDate(curDate, "dddd").toUpperCase()
                display_date.text = Qt.formatDate(curDate, dateFormat).toUpperCase()
                display_time.text = timeCharacter + " " + Qt.formatTime(curDate, time_format) + " " + timeCharacter
            }

            
        }

        // Main Content
        Column {
            id: container

            // Column settings
            anchors.centerIn: parent
            spacing: 5

            // The day ("Tuesday", "Wednesday" etc..)
            PlasmaComponents.Label {
                id: display_day
                
                // visible
                visible: plasmoid.configuration.show_day

                // font settings
                font.pixelSize: plasmoid.configuration.day_font_size
                font.letterSpacing: plasmoid.configuration.day_letter_spacing
                font.family: font_anurati.name
                color: plasmoid.configuration.day_font_color
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter 
            }

            // The Date
            PlasmaComponents.Label {
                id: display_date

                // visibility
                visible: plasmoid.configuration.show_date

                // font settings
                font.pixelSize: plasmoid.configuration.date_font_size
                font.letterSpacing: plasmoid.configuration.date_letter_spacing
                font.family: font_poppins.name
                color: plasmoid.configuration.date_font_color
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // The Time
            PlasmaComponents.Label {
                id: display_time

                // visibility
                visible: plasmoid.configuration.show_time

                // font settings
                font.pixelSize: plasmoid.configuration.time_font_size
                font.family: font_poppins.name
                color: plasmoid.configuration.time_font_color
                font.letterSpacing: plasmoid.configuration.time_letter_spacing
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
