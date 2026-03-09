/**
Credits: https://github.com/ccatterina/plasmusic-toolbar

looked handy, ty
*/


import QtQuick 2.15
import QtQml.Models 2.3
import org.kde.plasma.private.mpris as Mpris

QtObject {
    id: root

    property var mpris2Model: Mpris.Mpris2Model {
        onRowsInserted: (_, rowIndex) => {
            const CONTAINER_ROLE = Qt.UserRole + 1
            const player = this.data(this.index(rowIndex, 0), CONTAINER_ROLE)
            if (player.desktopEntry === root.sourceName) {
                this.currentIndex = rowIndex;
            }
        }
    }

    property string sourceName: "any"

    readonly property bool ready: {
        if (!mpris2Model.currentPlayer) {
            return false
        }
        return mpris2Model.currentPlayer.desktopEntry === sourceName || sourceName === "any";
    }

    readonly property string artists: ready ? mpris2Model.currentPlayer.artist : ""
    readonly property string title: ready ? mpris2Model.currentPlayer.track : ""
    readonly property int playbackStatus: ready ? mpris2Model.currentPlayer.playbackStatus : Mpris.PlaybackStatus.Unknown
    readonly property int shuffle: ready ? mpris2Model.currentPlayer.shuffle : Mpris.ShuffleStatus.Unknown
    readonly property string artUrl: ready ? mpris2Model.currentPlayer.artUrl : ""
    readonly property int loopStatus: ready ? mpris2Model.currentPlayer.loopStatus : Mpris.LoopStatus.Unknown
    readonly property double songPosition: ready ? mpris2Model.currentPlayer.position : 0
    readonly property double songLength: ready ? mpris2Model.currentPlayer.length : 0
    readonly property real volume: ready ? mpris2Model.currentPlayer.volume : 0
    readonly property string identity: ready ? mpris2Model.currentPlayer.identity : ""

    readonly property bool canGoNext: ready ? mpris2Model.currentPlayer.canGoNext : false
    readonly property bool canGoPrevious: ready ? mpris2Model.currentPlayer.canGoPrevious : false
    readonly property bool canPlay: ready ? mpris2Model.currentPlayer.canPlay : false
    readonly property bool canPause: ready ? mpris2Model.currentPlayer.canPause : false
    readonly property bool canSeek: ready ? mpris2Model.currentPlayer.canSeek : false
    readonly property bool canRaise: ready ? mpris2Model.currentPlayer.canRaise : false

    // To know whether Shuffle and Loop can be changed we have to check if the property is defined,
    // unlike the other commands, LoopStatus and Shuffle hasn't a specific propety such as
    // CanPause, CanSeek, etc.
    readonly property bool canChangeShuffle: ready ? mpris2Model.currentPlayer.shuffle != undefined : false
    readonly property bool canChangeLoopStatus: ready ? mpris2Model.currentPlayer.loopStatus != undefined : false

    function togglePlayPause() {
        mpris2Model.currentPlayer?.PlayPause();
    }

    function setPosition(position) {
        mpris2Model.currentPlayer.position = position;
    }

    function next() {
        mpris2Model.currentPlayer?.Next();
    }

    function previous() {
        mpris2Model.currentPlayer?.Previous();
    }

    function updatePosition() {
        mpris2Model.currentPlayer?.updatePosition();
    }

    function setVolume(volume) {
        mpris2Model.currentPlayer.volume = volume
    }

    function changeVolume(delta, showOSD) {
        mpris2Model.currentPlayer.changeVolume(delta, showOSD);
    }

    function setShuffle(shuffle) {
        mpris2Model.currentPlayer.shuffle = shuffle
    }

    function setLoopStatus(loopStatus) {
        mpris2Model.currentPlayer.loopStatus = loopStatus
    }

    function raise() {
        mpris2Model.currentPlayer.Raise();
    }

    function formatTrackTime(s) {
        var hours = Math.floor(s / 3600)
        var minutes = Math.floor((s - (hours * 3600)) / 60)
        var seconds = Math.ceil(s - (hours * 3600) - (minutes * 60))
        minutes = (minutes < 10) ? "0" + minutes : minutes
        seconds = (seconds < 10) ? "0" + seconds : seconds
        var time = minutes + ":" + seconds
        return time
    }
}
