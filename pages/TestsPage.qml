import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: page

    property var appWindow:
        ApplicationWindow.window

    readonly property bool compactLayout:
        appWindow ? appWindow.compactLayout : width < 760

    readonly property bool narrowLayout:
        appWindow ? appWindow.narrowLayout : width < 980

    readonly property color pageBackground:
        appWindow ? appWindow.pageBackground : "#F4F6FA"

    readonly property color surface:
        appWindow ? appWindow.surface : "#FFFFFF"

    readonly property color surfaceMuted:
        appWindow ? appWindow.surfaceMuted : "#F8F9FC"

    readonly property color borderColor:
        appWindow ? appWindow.borderColor : "#E4E8EF"

    readonly property color textPrimary:
        appWindow ? appWindow.textPrimary : "#263044"

    readonly property color textSecondary:
        appWindow ? appWindow.textSecondary : "#778196"

    readonly property color textMuted:
        appWindow ? appWindow.textMuted : "#A0A8B7"

    readonly property color accent:
        appWindow ? appWindow.accent : "#568FE8"

    readonly property color accentLight:
        appWindow ? appWindow.accentLight : "#EAF2FF"

    readonly property color success:
        appWindow ? appWindow.success : "#38B87C"

    readonly property color successLight:
        appWindow ? appWindow.successLight : "#E5F7EF"

    readonly property color warning:
        appWindow ? appWindow.warning : "#F2A93B"

    readonly property color warningLight:
        appWindow ? appWindow.warningLight : "#FFF4DC"

    readonly property color error:
        appWindow ? appWindow.error : "#ED6468"

    readonly property color errorLight:
        appWindow ? appWindow.errorLight : "#FDEBEC"

    readonly property int testColumnWidth: 260
    readonly property int statusColumnWidth: 110
    readonly property int durationColumnWidth: 100
    readonly property int arrowColumnWidth: 28

    background: Rectangle {
        color: page.pageBackground
    }

    ColumnLayout {
        anchors.fill: parent

        anchors.leftMargin:
            page.compactLayout ? 14 : 24

        anchors.rightMargin:
            page.compactLayout ? 14 : 24

        anchors.topMargin: 22
        anchors.bottomMargin: 24

        spacing: 18

        /*
            Page heading
        */

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: "Lifecycle Tests"

                    color: page.textPrimary

                    font.pixelSize:
                        page.compactLayout ? 23 : 28

                    font.bold: true
                }

                Label {
                    text:
                        apiClient.tests.length
                        + (
                                apiClient.tests.length === 1
                                ? " test available"
                                : " tests available"
                        )

                    color: page.textSecondary
                    font.pixelSize: 12
                }
            }

            Button {
                visible: !page.compactLayout

                text: "+ New Test"

                implicitWidth: 110
                implicitHeight: 42

                contentItem: Label {
                    text: parent.text
                    color: "white"

                    font.pixelSize: 12
                    font.bold: true

                    horizontalAlignment:
                        Text.AlignHCenter

                    verticalAlignment:
                        Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 14

                    color:
                        parent.pressed
                            ? Qt.darker(page.accent, 1.08)
                            : page.accent
                }

                onClicked: {
                    /*
                        Add your create-test page here:

                        stackView.push(newTestPageComponent)
                    */
                }
            }
        }

        /*
            Error message
        */

        Rectangle {
            Layout.fillWidth: true

            Layout.preferredHeight:
                errorLabel.implicitHeight + 28

            visible:
                apiClient.errorMessage.length > 0

            radius: 14
            color: page.errorLight

            border.width: 1
            border.color: page.error

            Label {
                id: errorLabel

                anchors.fill: parent
                anchors.margins: 14

                text: apiClient.errorMessage

                color: page.error
                wrapMode: Text.WordWrap
            }
        }

        /*
            Loading state
        */

        RowLayout {
            visible: apiClient.loading

            Layout.alignment:
                Qt.AlignHCenter

            spacing: 10

            BusyIndicator {
                running: apiClient.loading

                implicitWidth: 34
                implicitHeight: 34
            }

            Label {
                text: "Loading lifecycle tests..."

                color: page.textSecondary
                font.pixelSize: 12
            }
        }

        /*
            Tests container
        */

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: 20
            color: page.surface

            border.width: 1
            border.color: page.borderColor

            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: page.compactLayout ? 12 : 18

                spacing: 12

                /*
                    Column labels
                */

                RowLayout {
                    visible:
                        !page.compactLayout
                        && apiClient.tests.length > 0

                    Layout.fillWidth: true
                    Layout.rightMargin: 12

                    spacing: 14

                    Label {
                        Layout.preferredWidth: 235

                        text: "TEST"

                        color: page.textMuted

                        font.pixelSize: 10
                        font.bold: true
                    }

                    Label {
                        Layout.preferredWidth: 95

                        text: "STATUS"

                        color: page.textMuted

                        font.pixelSize: 10
                        font.bold: true
                    }

                    Label {
                        Layout.preferredWidth: 90

                        text: "DURATION"

                        color: page.textMuted

                        font.pixelSize: 10
                        font.bold: true
                    }

                    Label {
                        Layout.fillWidth: true

                        text: "CREATED"

                        color: page.textMuted

                        font.pixelSize: 10
                        font.bold: true
                    }

                    Item {
                        Layout.preferredWidth: 24
                    }
                }

                Rectangle {
                    visible:
                        !page.compactLayout
                        && apiClient.tests.length > 0

                    Layout.fillWidth: true

                    height: 1
                    color: page.borderColor
                }

                ListView {
                    id: testList

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    model: apiClient.tests

                    clip: true
                    spacing: 8

                    boundsBehavior:
                        Flickable.StopAtBounds

                    flickableDirection:
                        Flickable.VerticalFlick

                    ScrollBar.vertical: ScrollBar {
                        policy:
                                testList.contentHeight
                            > testList.height
                            ? ScrollBar.AsNeeded
                            : ScrollBar.AlwaysOff
                    }

                    delegate: Rectangle {
                        id: testRow

                        required property var modelData
                        required property int index

                        width: testList.width

                        height:
                            page.compactLayout ? 146 : 72

                        radius: 14

                        color:
                            testMouseArea.containsMouse
                                ? page.accentLight
                                : index % 2 === 0
                                    ? page.surfaceMuted
                                    : page.surface

                        border.width: 1

                        border.color:
                            testMouseArea.containsMouse
                                ? page.accent
                                : page.borderColor

                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
                        }

                        Behavior on border.color {
                            ColorAnimation {
                                duration: 100
                            }
                        }

                        /*
                            Desktop row
                        */

                        RowLayout {
                            visible: !page.compactLayout

                            anchors.fill: parent

                            anchors.leftMargin: 14
                            anchors.rightMargin: 14

                            spacing: 14

                            RowLayout {
                                Layout.preferredWidth: 235
                                spacing: 11

                                Rectangle {
                                    width: 38
                                    height: 38

                                    radius: 12

                                    color:
                                        page.statusBackground(
                                            modelData.status
                                        )

                                    Label {
                                        anchors.centerIn: parent

                                        text:
                                            page.statusSymbol(
                                                modelData.status
                                            )

                                        color:
                                            page.statusForeground(
                                                modelData.status
                                            )

                                        font.pixelSize: 15
                                        font.bold: true
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Label {
                                        Layout.fillWidth: true

                                        text:
                                            modelData.device_name
                                            || modelData.name
                                            || "Unnamed device"

                                        color: page.textPrimary

                                        font.pixelSize: 13
                                        font.bold: true

                                        elide: Text.ElideRight
                                    }

                                    Label {
                                        text:
                                            "Test ID "
                                            + Number(
                                                modelData.test_id || 0
                                            )

                                        color: page.textSecondary
                                        font.pixelSize: 10
                                    }
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 90
                                Layout.preferredHeight: 28

                                radius: 9

                                color:
                                    page.statusBackground(
                                        modelData.status
                                    )

                                Label {
                                    anchors.centerIn: parent

                                    text:
                                        page.formatStatus(
                                            modelData.status
                                        )

                                    color:
                                        page.statusForeground(
                                            modelData.status
                                        )

                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }

                            Label {
                                Layout.preferredWidth: 90

                                text:
                                    page.formatDuration(
                                        modelData.duration_seconds
                                    )

                                color: page.textPrimary

                                font.pixelSize: 11
                                font.bold: true
                            }

                            Label {
                                Layout.fillWidth: true

                                text:
                                    page.formatDate(
                                        modelData.created_at_utc
                                    )

                                color: page.textSecondary
                                font.pixelSize: 11

                                elide: Text.ElideRight
                            }

                            Label {
                                Layout.preferredWidth: 24

                                text: "›"

                                color: page.accent

                                font.pixelSize: 24
                                font.bold: true

                                horizontalAlignment:
                                    Text.AlignHCenter
                            }
                        }

                        /*
                            Compact row
                        */

                        ColumnLayout {
                            visible: page.compactLayout

                            anchors.fill: parent
                            anchors.margins: 14

                            spacing: 9

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Rectangle {
                                    width: 38
                                    height: 38

                                    radius: 12

                                    color:
                                        page.statusBackground(
                                            modelData.status
                                        )

                                    Label {
                                        anchors.centerIn: parent

                                        text:
                                            page.statusSymbol(
                                                modelData.status
                                            )

                                        color:
                                            page.statusForeground(
                                                modelData.status
                                            )

                                        font.pixelSize: 15
                                        font.bold: true
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Label {
                                        Layout.fillWidth: true

                                        text:
                                            modelData.device_name
                                            || modelData.name
                                            || "Unnamed device"

                                        color: page.textPrimary

                                        font.pixelSize: 14
                                        font.bold: true

                                        elide: Text.ElideRight
                                    }

                                    Label {
                                        text:
                                            "Test ID "
                                            + Number(
                                                modelData.test_id || 0
                                            )

                                        color: page.textSecondary
                                        font.pixelSize: 10
                                    }
                                }

                                Rectangle {
                                    implicitWidth:
                                        compactStatusLabel
                                            .implicitWidth
                                        + 18

                                    implicitHeight: 27
                                    radius: 9

                                    color:
                                        page.statusBackground(
                                            modelData.status
                                        )

                                    Label {
                                        id: compactStatusLabel

                                        anchors.centerIn: parent

                                        text:
                                            page.formatStatus(
                                                modelData.status
                                            )

                                        color:
                                            page.statusForeground(
                                                modelData.status
                                            )

                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true

                                height: 1
                                color: page.borderColor
                            }

                            GridLayout {
                                Layout.fillWidth: true

                                columns: 2

                                columnSpacing: 18
                                rowSpacing: 4

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Label {
                                        text: "DURATION"

                                        color: page.textMuted

                                        font.pixelSize: 9
                                        font.bold: true
                                    }

                                    Label {
                                        text:
                                            page.formatDuration(
                                                modelData.duration_seconds
                                            )

                                        color: page.textPrimary

                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Label {
                                        text: "CREATED"

                                        color: page.textMuted

                                        font.pixelSize: 9
                                        font.bold: true
                                    }

                                    Label {
                                        Layout.fillWidth: true

                                        text:
                                            page.formatDate(
                                                modelData.created_at_utc
                                            )

                                        color: page.textSecondary

                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: testMouseArea

                            anchors.fill: parent

                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                apiClient.loadTest(
                                    Number(
                                        modelData.test_id
                                    )
                                )
                            }
                        }
                    }
                }

                /*
                    Empty state
                */

                ColumnLayout {
                    visible:
                        !apiClient.loading
                        && apiClient.errorMessage.length === 0
                        && apiClient.tests.length === 0

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    spacing: 9

                    Item {
                        Layout.fillHeight: true
                    }

                    Rectangle {
                        Layout.alignment:
                            Qt.AlignHCenter

                        width: 54
                        height: 54

                        radius: 18
                        color: page.accentLight

                        Label {
                            anchors.centerIn: parent

                            text: "∿"
                            color: page.accent

                            font.pixelSize: 23
                            font.bold: true
                        }
                    }

                    Label {
                        Layout.alignment:
                            Qt.AlignHCenter

                        text: "No lifecycle tests found"

                        color: page.textPrimary

                        font.pixelSize: 14
                        font.bold: true
                    }

                    Label {
                        Layout.fillWidth: true

                        text:
                            "Tests created in the lifecycle system "
                            + "will appear here."

                        color: page.textMuted
                        font.pixelSize: 11

                        horizontalAlignment:
                            Text.AlignHCenter

                        wrapMode: Text.WordWrap
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }

    /*
        Status helpers
    */

    function normalizeStatus(status) {
        return String(status || "")
            .trim()
            .toLowerCase()
    }

    function formatStatus(status) {
        const value =
            normalizeStatus(status)

        switch (value) {
            case "created":
                return "Created"

            case "running":
            case "active":
            case "started":
            case "in progress":
            case "in_progress":
                return "Running"

            case "paused":
                return "Paused"

            case "completed":
            case "complete":
            case "finished":
                return "Completed"

            case "aborted":
                return "Aborted"

            case "failed":
            case "error":
                return "Failed"

            case "queued":
            case "pending":
                return "Queued"

            default:
                return value.length > 0
                    ? value.charAt(0).toUpperCase()
                    + value.slice(1)
                    : "Unknown"
        }
    }

    function statusForeground(status) {
        const value =
            normalizeStatus(status)

        switch (value) {
            case "running":
            case "active":
            case "started":
            case "in progress":
            case "in_progress":
                return page.accent

            case "paused":
            case "queued":
            case "pending":
                return page.warning

            case "completed":
            case "complete":
            case "finished":
                return page.success

            case "aborted":
            case "failed":
            case "error":
                return page.error

            default:
                return page.textSecondary
        }
    }

    function statusBackground(status) {
        const value =
            normalizeStatus(status)

        switch (value) {
            case "running":
            case "active":
            case "started":
            case "in progress":
            case "in_progress":
                return page.accentLight

            case "paused":
            case "queued":
            case "pending":
                return page.warningLight

            case "completed":
            case "complete":
            case "finished":
                return page.successLight

            case "aborted":
            case "failed":
            case "error":
                return page.errorLight

            default:
                return page.surfaceMuted
        }
    }

    function statusSymbol(status) {
        const value =
            normalizeStatus(status)

        switch (value) {
            case "running":
            case "active":
            case "started":
            case "in progress":
            case "in_progress":
                return "▶"

            case "paused":
                return "Ⅱ"

            case "completed":
            case "complete":
            case "finished":
                return "✓"

            case "aborted":
                return "×"

            case "failed":
            case "error":
                return "!"

            case "queued":
            case "pending":
                return "…"

            default:
                return "•"
        }
    }

    function formatDuration(totalSeconds) {
        const seconds =
            Number(totalSeconds)

        if (!Number.isFinite(seconds)) {
            return "0m"
        }

        const days =
            Math.floor(
                seconds / 86400
            )

        const hours =
            Math.floor(
                (seconds % 86400) / 3600
            )

        const minutes =
            Math.floor(
                (seconds % 3600) / 60
            )

        const parts = []

        if (days > 0) {
            parts.push(days + "d")
        }

        if (hours > 0 || days > 0) {
            parts.push(hours + "h")
        }

        if (
            minutes > 0
            || parts.length === 0
        ) {
            parts.push(minutes + "m")
        }

        return parts.join(" ")
    }

    function formatDate(value) {
        if (!value) {
            return "Unknown"
        }

        const date =
            new Date(value)

        if (isNaN(date.getTime())) {
            return String(value)
        }

        return date.toLocaleString()
    }
}