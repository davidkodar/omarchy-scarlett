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
    property bool deviceSettingsOpen: false
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
    function controlStatus(key, label) {
        const control = state.controls[key]
        return label + (control ? (control.value ? " on" : " off") : " unavailable")
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
    // Let the popup release its keyboard grab before focusing another window.
    Timer {
        id: advancedLaunch
        interval: 180
        onTriggered: Quickshell.execDetached([
            "omarchy", "launch", "or-focus", "^vu[.]b4[.]alsa-scarlett-gui$",
            "uwsm-app -- alsa-scarlett-gui"
        ])
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
        iconComponent: Component {
            InterfaceIcon { foreground: button.foreground }
        }
        opacity: root.state.connected ? 1 : 0.45
        tooltipText: root.state.connected
            ? "Scarlett Solo\n" + root.controlStatus("phantom", "48V") + " · " + root.controlStatus("monitor", "Direct monitor")
            : "Scarlett Solo\nDisconnected"
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
                    spacing: Style.spacing.lg
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
                    Column {
                        width: parent.width
                        spacing: Style.spacing.md
                        PanelSectionHeader { text: "INPUT 1" }
                        Repeater {
                            model: [
                                {key: "air", label: "Air", description: "Presence"},
                                {key: "phantom", label: "48V", description: "Phantom power"}
                            ]
                            Toggle {
                                required property var modelData
                                readonly property var control: root.state.controls[modelData.key]
                                width: column.width
                                label: modelData.label
                                description: control ? modelData.description : "Unavailable"
                                checked: control ? control.value : false
                                enabled: !!control && control.writable && !root.pending
                                opacity: control ? 1 : 0.45
                                onClicked: root.setControl(modelData.key, !checked)
                                Accessible.name: "Input 1, " + label + ", " + description
                            }
                        }
                    }
                    Column {
                        width: parent.width
                        spacing: Style.spacing.md
                        PanelSectionHeader { text: "INPUT 2" }
                        Row {
                            width: parent.width
                            spacing: Style.spacing.md
                            Repeater {
                                model: ["Line", "Inst"]
                                Button {
                                    required property string modelData
                                    readonly property var control: root.state.controls.inst
                                    width: (column.width - Style.spacing.md) / 2
                                    text: modelData
                                    bordered: true
                                    focusable: true
                                    selected: !!control && (control.value === (modelData === "Inst"))
                                    enabled: !!control && control.writable && !root.pending
                                    opacity: control ? 1 : 0.45
                                    onClicked: if (!selected) root.setControl("inst", modelData === "Inst")
                                    Accessible.role: Accessible.RadioButton
                                    Accessible.name: "Input 2, " + modelData
                                    Accessible.checkable: true
                                    Accessible.checked: selected
                                }
                            }
                        }
                        Text {
                            visible: !root.state.controls.inst
                            text: "Unavailable"
                            color: Color.muted
                            font.family: Style.font.family
                            font.pixelSize: Style.font.caption
                        }
                    }
                    Column {
                        width: parent.width
                        spacing: Style.spacing.md
                        PanelSectionHeader { text: "MONITORING" }
                        Toggle {
                            readonly property var control: root.state.controls.monitor
                            width: parent.width
                            label: "Direct monitor"
                            description: control ? "Listen to inputs directly" : "Unavailable"
                            checked: control ? control.value : false
                            enabled: !!control && control.writable && !root.pending
                            opacity: control ? 1 : 0.45
                            onClicked: root.setControl("monitor", !checked)
                            Accessible.name: label
                        }
                    }
                    Button {
                        width: parent.width
                        text: "Device settings  " + (root.deviceSettingsOpen ? "−" : "+")
                        leftAlign: true
                        focusable: true
                        onClicked: root.deviceSettingsOpen = !root.deviceSettingsOpen
                        Accessible.name: "Device settings"
                        Accessible.description: root.deviceSettingsOpen ? "Hide device settings" : "Show device settings"
                    }
                    Column {
                        visible: root.deviceSettingsOpen
                        width: parent.width
                        spacing: Style.spacing.md
                        Text {
                            width: parent.width
                            text: root.state.connected
                                ? (root.state.info?.model || "Scarlett Solo") + " · USB " + (root.state.info?.usb_id || "Unknown")
                                  + "\nFirmware " + (root.state.info?.firmware ?? "unavailable")
                                : "Connect your Scarlett to view device information."
                            textFormat: Text.PlainText
                            wrapMode: Text.WordWrap
                            color: Color.muted
                            font.family: Style.font.family
                            font.pixelSize: Style.font.caption
                        }
                        Toggle {
                            readonly property var control: root.state.controls.phantom_persistence
                            width: parent.width
                            label: "Remember 48V"
                            description: control
                                ? "Remember the 48V state when powered on. Does not switch 48V now."
                                : "Startup preference unavailable"
                            checked: control ? control.value : false
                            enabled: !!control && control.writable && !root.pending
                            opacity: control ? 1 : 0.45
                            onClicked: root.setControl("phantom_persistence", !checked)
                            Accessible.name: "Remember 48V state at power-on"
                        }
                    }
                    Button {
                        id: advanced
                        visible: false
                        width: parent.width
                        text: "Open ALSA Scarlett Control Panel"
                        focusable: true
                        onClicked: { root.close(); advancedLaunch.restart() }
                    }
                }
            }
        }
    }
}
