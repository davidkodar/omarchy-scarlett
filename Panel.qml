import QtQuick
import QtQuick.Controls as QQC
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

Panel {
    id: root
    moduleName: "davidkodar.scarlett"
    ipcTarget: "davidkodar.scarlett"
    property var state: ({ connected: false, controls: {}, generation: 0 })
    property string error: ""
    property int sequence: 0
    property int pending: 0
    property bool preview: false
    property bool receivedState: false
    property string helperPath: decodeURIComponent(Qt.resolvedUrl("bin/scarlett-helper").toString().replace(/^file:\/\//, ""))
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    function receive(line) {
        try {
            const message = JSON.parse(line)
            if (message.type === "state") { state = message; receivedState = true }
            else if (message.type === "result" && message.id === pending) {
                pending = 0
                timeout.stop()
                error = message.ok ? "" : message.error
            }
        } catch (e) { error = "Could not read Scarlett state" }
    }
    function setControl(key, value) {
        if (pending || !state.connected || !state.controls[key]?.writable) return
        pending = ++sequence
        error = ""
        helper.write(JSON.stringify({id: pending, op: "set", key: key,
            value: value, generation: state.generation}) + "\n")
        timeout.restart()
    }
    Process {
        id: helper
        command: root.preview ? [root.helperPath, "--read-only"] : [root.helperPath]
        stdinEnabled: true
        running: true
        stdout: SplitParser { onRead: data => root.receive(data) }
        stderr: SplitParser { onRead: data => console.warn("Scarlett helper:", data) }
        onExited: {
            root.state = {connected: false, controls: {}, generation: 0}
            root.pending = 0
            root.error = "Scarlett helper stopped. Check the build, then retry."
        }
    }
    Timer {
        id: startupTimeout
        interval: 3000
        running: true
        onTriggered: {
            if (!root.receivedState) {
                root.error = "Helper unavailable. Run make in the plugin directory, then reopen."
                helper.running = false
            }
        }
    }
    Timer {
        id: timeout
        interval: 4000
        onTriggered: {
            root.error = "Device did not respond. Reopen the panel to retry."
            helper.running = false
        }
    }
    Process {
        id: advancedCheck
        command: ["/usr/bin/test", "-x", "/usr/bin/alsa-scarlett-gui"]
        running: true
        onExited: (exitCode, exitStatus) => advanced.visible = exitCode === 0
    }
    BarIconButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: "󰋎"
        opacity: root.state.connected ? 1 : 0.45
        tooltipText: root.state.connected ? "Scarlett Solo · " + (root.state.controls.phantom?.value ? "48V on" : "48V off") : "Scarlett disconnected"
        onPressed: b => { if (b === Qt.LeftButton) root.toggle() }
    }
    onOpenedChanged: {
        if (opened && !helper.running) {
            error = ""; receivedState = false; helper.running = true; startupTimeout.restart()
        }
    }
    KeyboardPanel {
        id: popup
        anchorItem: button
        owner: root
        bar: root.bar
        open: root.opened
        focusTarget: body
        contentWidth: popup.fittedContentWidth(Style.space(340))
        contentHeight: popup.fittedContentHeight(column.implicitHeight)
        FocusScope {
            id: body
            anchors.fill: parent
            Keys.onEscapePressed: root.close()
            QQC.ScrollView {
                anchors.fill: parent
                contentWidth: availableWidth
                clip: true
                Column {
                    id: column
                    width: parent.width
                    spacing: Style.spacing.md
                    Text {
                        text: "SCARLETT SOLO"
                        color: Color.foreground
                        font.family: Style.font.family
                        font.pixelSize: Style.font.title
                        font.bold: true
                    }
                    Text {
                        width: parent.width
                        text: root.error || root.state.message || "Input controls"
                        textFormat: Text.PlainText
                        wrapMode: Text.WordWrap
                        color: root.error ? Color.urgent : Color.muted
                        font.family: Style.font.family
                        font.pixelSize: Style.font.caption
                    }
                    Repeater {
                        model: [
                            {key: "air", label: "Air", description: "Input 1 · presence"},
                            {key: "phantom", label: "48V", description: "Input 1 · phantom power"},
                            {key: "inst", label: "Instrument", description: "Input 2 · Line / Inst"},
                            {key: "monitor", label: "Direct monitor", description: "Listen to inputs directly"}
                        ]
                        Toggle {
                            required property var modelData
                            readonly property var control: root.state.controls[modelData.key]
                            width: column.width
                            label: modelData.label
                            description: control ? (modelData.key === "inst" ? "Input 2 · " + (control.value ? "Inst" : "Line") : modelData.description) : "Unavailable"
                            checked: control ? control.value : false
                            enabled: !!control && control.writable && !root.pending
                            opacity: control ? 1 : 0.45
                            onClicked: root.setControl(modelData.key, !checked)
                            Accessible.name: label + ", " + description
                        }
                    }
                    Button {
                        id: advanced
                        visible: false
                        width: parent.width
                        text: "Advanced settings  ↗"
                        onClicked: { Quickshell.execDetached(["alsa-scarlett-gui"]); root.close() }
                    }
                }
            }
        }
    }
}
