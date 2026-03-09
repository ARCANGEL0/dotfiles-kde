import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: configRoot

    signal configurationChanged

    property alias cfg_opacity: opacitySpinBox.value

	property string cfg_fontFamily

    ColumnLayout {
        spacing: Kirigami.Units.mediumSpacing

        RowLayout{
            Label {
                text: i18n("Opacity percent")
            }
            SpinBox {
                id: opacitySpinBox
                from: 0
                to: 100
            }
        }

        RowLayout{
            Label {
                text: i18n("Font")
            }
            ComboBox{
                id: fontFamilyComboBox
                model: Qt.fontFamilies()
                onCurrentIndexChanged: {
                    var current = Qt.fontFamilies()[currentIndex]
                    cfg_fontFamily=current
                    configRoot.configurationChanged()
                }
            }
        }

    }
}
