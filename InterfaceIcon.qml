import QtQuick

// Original vector icon: a compact interface enclosure with two input sockets.
// Geometry scales with Omarchy's icon canvas; color follows the bar foreground.
Item {
    id: root
    property color foreground: "white"
    readonly property real stroke: Math.max(1, Math.min(width, height) / 14)

    Rectangle {
        width: parent.width * 0.92
        height: parent.height * 0.64
        anchors.centerIn: parent
        radius: root.stroke * 1.1
        color: "transparent"
        border.width: root.stroke
        border.color: root.foreground
        Row {
            anchors.centerIn: parent
            spacing: root.width * 0.14
            Repeater {
                model: 2
                Rectangle {
                    width: root.width * 0.20
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: root.stroke
                    border.color: root.foreground
                }
            }
        }
    }
}
