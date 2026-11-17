import QtQuick
import QtQuick.Window

Window {
    id: window
    width: 1180
    height: 820
    minimumWidth: 760
    minimumHeight: 600
    visible: true
    title: "Qt · Liquid Glass"
    color: "#377687"

    property real phase: 0
    property real strength: 1
    property real frost: 0.12
    property int scene: 0
    property bool paused: false
    property bool testMode: false
    property bool showContent: true
    property bool forceSolid: false
    property bool accessibilitySolid: false
    property bool accessibilityReduceMotion: false
    readonly property bool solid: testMode ? forceSolid : accessibilitySolid
    readonly property rect panelRect: Qt.rect(card.x, card.y, card.width, card.height)
    readonly property bool shaderFailed: backdrop.status === ShaderEffect.Error || lens.status === ShaderEffect.Error

    FrameAnimation {
        running: !window.testMode && !window.paused && !window.accessibilityReduceMotion
                 && window.visible && window.visibility !== Window.Minimized
        onTriggered: window.phase += Math.min(frameTime, 0.05)
    }

    Item {
        id: stage
        anchors.fill: parent

        ShaderEffect {
            id: backdrop
            anchors.fill: parent
            property size viewportSize: Qt.size(width, height)
            property real phase: window.phase
            property real scene: window.scene
            fragmentShader: "qrc:/shaders/background.frag.qsb"
            Accessible.ignored: true
        }

        ShaderEffectSource {
            id: backgroundTexture
            sourceItem: backdrop
            hideSource: false
            live: true
            visible: false
            smooth: true
        }

        HoverHandler { id: pointer }

        ShaderEffect {
            id: lens
            anchors.fill: parent
            property var background: backgroundTexture
            property size viewportSize: Qt.size(width, height)
            property rect panelRect: window.panelRect
            property point pointerPosition: pointer.point.position
            property real strength: window.strength
            property real frost: window.frost
            property real solid: window.solid ? 1 : 0
            fragmentShader: "qrc:/shaders/glass.frag.qsb"
            Accessible.ignored: true
        }

        Item {
            id: card
            objectName: "glassPanel"
            width: Math.min(600, stage.width - 130)
            height: Math.min(386, stage.height - 240)
            x: (stage.width - width) / 2
            y: (stage.height - height) / 2 - 25
            activeFocusOnTab: true
            focus: true
            Accessible.role: Accessible.Pane
            Accessible.name: "液态玻璃面板，拖动或使用方向键移动"

            DragHandler {
                id: drag
                xAxis.minimum: 28
                xAxis.maximum: stage.width - card.width - 28
                yAxis.minimum: 28
                yAxis.maximum: stage.height - card.height - 105
            }
            Keys.onPressed: function(event) {
                let dx = event.key === Qt.Key_Left ? -10 : event.key === Qt.Key_Right ? 10 : 0
                let dy = event.key === Qt.Key_Up ? -10 : event.key === Qt.Key_Down ? 10 : 0
                if (dx !== 0 || dy !== 0) {
                    card.x = Math.max(28, Math.min(stage.width - card.width - 28, card.x + dx))
                    card.y = Math.max(28, Math.min(stage.height - card.height - 105, card.y + dy))
                    event.accepted = true
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: 52
                color: "transparent"
                border.width: card.activeFocus && !window.testMode ? 1 : 0
                border.color: "#76ffffff"
            }

            Item {
                anchors.fill: parent
                visible: window.showContent

                Text {
                    x: 34; y: 28
                    text: "Liquid Glass"
                    color: "#f5fbff"
                    font.pixelSize: 18
                    font.weight: Font.Medium
                    style: Text.Raised
                    styleColor: "#200b2535"
                }
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 37
                    y: 37
                    spacing: 5
                    Repeater {
                        model: 3
                        Rectangle { width: 4; height: 4; radius: 2; color: "#c4f6fcff" }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -5
                    text: "09:41"
                    color: "#f6fbff"
                    font.pixelSize: Math.min(card.height * 0.26, 104)
                    font.weight: Font.Light
                    font.letterSpacing: -3
                    style: Text.Raised
                    styleColor: "#300b2535"
                    Accessible.name: "示例时间，九点四十一分"
                }
                Rectangle {
                    x: 34; y: parent.height - 85
                    width: parent.width - 68; height: 1
                    color: "#28ffffff"
                }
                Text {
                    x: 36; y: parent.height - 60
                    text: "☀  23°"
                    color: "#eefaff"
                    font.pixelSize: 19
                    Accessible.name: "示例天气，晴，二十三度"
                }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 36
                    y: parent.height - 56
                    text: "周二 · 11月17日"
                    color: "#e0f6fcff"
                    font.pixelSize: 15
                }
            }
        }

        component Tool: Rectangle {
            id: tool
            property string symbol
            property string label
            signal clicked()
            width: 52; height: 52; radius: 26
            color: hover.hovered || activeFocus ? "#40ffffff" : "#1fffffff"
            border.width: activeFocus ? 2 : 1
            border.color: activeFocus ? "#e0f8ffff" : "#55ffffff"
            activeFocusOnTab: true
            Accessible.role: Accessible.Button
            Accessible.name: label
            Accessible.onPressAction: clicked()
            Keys.onSpacePressed: clicked()
            Keys.onReturnPressed: clicked()
            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: tool.clicked() }
            Text {
                anchors.centerIn: parent
                text: tool.symbol
                color: "white"
                font.pixelSize: 22
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height + 9
                width: tooltip.width + 20; height: 27; radius: 8
                color: "#dd203440"
                visible: hover.hovered
                Text { id: tooltip; anchors.centerIn: parent; text: tool.label; color: "white"; font.pixelSize: 12 }
            }
        }

        Row {
            visible: window.showContent
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - 95
            spacing: 16
            Tool {
                symbol: window.paused || window.accessibilityReduceMotion ? "▶" : "Ⅱ"
                label: window.accessibilityReduceMotion ? "系统已减少动态效果" : window.paused ? "播放背景" : "暂停背景"
                onClicked: window.paused = !window.paused
            }
            Tool {
                symbol: "▧"
                label: window.scene === 0 ? "切换折射对照色带" : "切换流动背景"
                onClicked: window.scene = 1 - window.scene
            }
            Tool {
                symbol: "◒"
                label: window.frost < 0.5 ? "柔化玻璃" : "通透玻璃"
                onClicked: window.frost = window.frost < 0.5 ? 0.9 : 0.12
            }
        }
    }
    Shortcut { sequence: "Esc"; onActivated: window.close() }
    Shortcut { sequence: "Space"; onActivated: window.paused = !window.paused; enabled: card.activeFocus }
}
