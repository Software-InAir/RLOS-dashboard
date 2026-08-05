import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root

    width: 1180
    height: 760

    minimumWidth: 390
    minimumHeight: 600

    visible: true
    title: "RLOS Lifecycle Dashboard"

    color: pageBackground

    property bool compactLayout: width < 760
    property bool narrowLayout: width < 980

    property string selectedTheme: "Soft Blue"

    /*
        Dashboard values

        These remain zero until real information is assigned from apiClient.
        For example:

        root.activeTests = apiClient.activeTestCount
        root.temperature = apiClient.temperature
    */

    property int activeTests: 0
    property int completedTests: 0
    property int devicesOnline: 0
    property int activeAlerts: 0

    property int averageProgress: 0
    property int inProgressTests: 0
    property int queuedTests: 0
    property int failedTests: 0

    property real temperature: 0.0
    property real humidity: 0.0
    property real pressure: 0.0
    property real airFlow: 0.0

    property bool daqOnline: false
    property bool databaseOnline: false
    property bool instrumentationOnline: false
    property bool networkOnline: false

    property bool testsLoaded: false

    readonly property bool backendAvailable:
        testsLoaded
        && apiClient.errorMessage.length === 0

    readonly property int activityTestWidth: 150
    readonly property int activityDeviceWidth: 185
    readonly property int activityStatusWidth: 115
    readonly property int activityProgressWidth: 130

    readonly property bool allSystemsOperational:
        daqOnline
        && databaseOnline
        && instrumentationOnline
        && networkOnline
        && apiClient.errorMessage.length === 0

    readonly property color accent: {
        switch (selectedTheme) {
            case "Mint":
                return "#48C9A0"

            case "Lavender":
                return "#9A7BEF"

            case "Peach":
                return "#FF9878"

            case "Butter Yellow":
                return "#F2B93B"

            case "Blush Coral":
                return "#FF7276"

            default:
                return "#568FE8"
        }
    }

    readonly property color accentLight: {
        switch (selectedTheme) {
            case "Mint":
                return "#E5F8F2"

            case "Lavender":
                return "#F0EAFF"

            case "Peach":
                return "#FFF0EA"

            case "Butter Yellow":
                return "#FFF6D9"

            case "Blush Coral":
                return "#FFE9EA"

            default:
                return "#EAF2FF"
        }
    }

    readonly property color accentMedium: {
        switch (selectedTheme) {
            case "Mint":
                return "#BCEBDD"

            case "Lavender":
                return "#DCCFFF"

            case "Peach":
                return "#FFD1C2"

            case "Butter Yellow":
                return "#FFE6A0"

            case "Blush Coral":
                return "#FFC6C8"

            default:
                return "#C8DCFA"
        }
    }

    readonly property color pageBackground: "#F4F6FA"
    readonly property color surface: "#FFFFFF"
    readonly property color surfaceMuted: "#F8F9FC"
    readonly property color borderColor: "#E4E8EF"

    readonly property color textPrimary: "#263044"
    readonly property color textSecondary: "#778196"
    readonly property color textMuted: "#A0A8B7"

    readonly property color success: "#38B87C"
    readonly property color successLight: "#E5F7EF"

    readonly property color warning: "#F2A93B"
    readonly property color warningLight: "#FFF4DC"

    readonly property color error: "#ED6468"
    readonly property color errorLight: "#FDEBEC"

    readonly property color info: "#568FE8"
    readonly property color infoLight: "#EAF2FF"

    /*
        Leave this model empty until real test information is received.

        Expected roles for each item:

        testId
        testName
        deviceName
        statusText
        progressValue
        updatedText
    */
    ListModel {
        id: recentTestsModel
    }

    ListModel {
        id: themeModel

        ListElement {
            themeName: "Soft Blue"
            previewColor: "#568FE8"
        }

        ListElement {
            themeName: "Mint"
            previewColor: "#48C9A0"
        }

        ListElement {
            themeName: "Lavender"
            previewColor: "#9A7BEF"
        }

        ListElement {
            themeName: "Peach"
            previewColor: "#FF9878"
        }

        ListElement {
            themeName: "Butter Yellow"
            previewColor: "#F2B93B"
        }

        ListElement {
            themeName: "Blush Coral"
            previewColor: "#FF7276"
        }
    }

    function clearRecentTests() {
        recentTestsModel.clear()
    }

    function addRecentTest(
        testId,
        testName,
        deviceName,
        statusText,
        progressValue,
        updatedText
    ) {
        recentTestsModel.append({
            "testId": testId,
            "testName": testName || "",
            "deviceName": deviceName || "",
            "statusText": statusText || "",
            "progressValue": progressValue || 0,
            "updatedText": updatedText || ""
        })
    }

    function formatStatus(status) {
        switch (status) {
            case "running":
            case "active":
            case "in progress":
            case "in_progress":
                return "Running"

            case "completed":
                return "Completed"

            case "queued":
                return "Queued"

            case "failed":
            case "error":
                return "Error"

            case "warning":
                return "Warning"

            default:
                return status.length > 0
                    ? status.charAt(0).toUpperCase()
                    + status.slice(1)
                    : "Unknown"
        }
    }

    function populateTests(tests) {
        recentTestsModel.clear()

        root.activeTests = 0
        root.completedTests = 0
        root.inProgressTests = 0
        root.queuedTests = 0
        root.failedTests = 0
        root.averageProgress = 0

        if (!tests || tests.length === 0)
            return

        let totalProgress = 0

        for (let i = 0; i < tests.length; i++) {
            const test = tests[i]

            const status = String(
                test.status || ""
            ).toLowerCase()

            let progress = Number(
                test.progress || 0
            )

            if (status === "completed")
                progress = 100

            progress = Math.max(
                0,
                Math.min(100, progress)
            )

            totalProgress += progress

            if (
                status === "running"
                || status === "active"
                || status === "in progress"
                || status === "in_progress"
            ) {
                root.activeTests++
                root.inProgressTests++
            } else if (status === "completed") {
                root.completedTests++
            } else if (status === "queued") {
                root.queuedTests++
            } else if (
                status === "failed"
                || status === "error"
            ) {
                root.failedTests++
            }

            recentTestsModel.append({
                "testId": test.test_id,
                "testName": test.name
                    || test.test_name
                    || "Unnamed Test",
                "deviceName": test.device_name
                    || test.device
                    || "",
                "statusText": root.formatStatus(status),
                "progressValue": progress,
                "updatedText": test.updated_at
                    || test.completed_at
                    || test.started_at
                    || ""
            })
        }

        root.averageProgress = Math.round(
            totalProgress / tests.length
        )
    }

    header: ToolBar {
        id: topBar

        height: 68

        background: Rectangle {
            color: root.surface

            Rectangle {
                anchors.bottom: parent.bottom

                width: parent.width
                height: 1

                color: root.borderColor
            }
        }

        RowLayout {
            anchors.fill: parent

            anchors.leftMargin: root.compactLayout ? 14 : 24
            anchors.rightMargin: root.compactLayout ? 14 : 24

            spacing: 12

            ToolButton {
                visible: stackView.depth > 1

                text: "‹ Back"

                contentItem: Label {
                    text: parent.text
                    color: root.textPrimary

                    font.pixelSize: 14
                    font.bold: true

                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }

                background: Rectangle {
                    radius: 10

                    color: parent.hovered
                        ? root.accentLight
                        : "transparent"
                }

                onClicked: {
                    apiClient.clearActionMessage()
                    stackView.pop()
                }
            }

            Rectangle {
                width: 38
                height: 38

                radius: 13
                color: root.accent

                Label {
                    anchors.centerIn: parent

                    text: "R"
                    color: "white"

                    font.pixelSize: 18
                    font.bold: true
                }
            }

            ColumnLayout {
                spacing: 0

                Label {
                    text: "RLOS"
                    color: root.textPrimary

                    font.pixelSize: 19
                    font.bold: true
                }

                Label {
                    visible: !root.compactLayout

                    text: "Lifecycle Test System"
                    color: root.textSecondary

                    font.pixelSize: 11
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                visible: !root.compactLayout

                implicitWidth: connectionRow.implicitWidth + 22
                implicitHeight: 34

                radius: 12

                color: apiClient.errorMessage.length > 0
                    ? root.errorLight
                    : apiClient.loading
                        ? root.warningLight
                        : root.successLight

                RowLayout {
                    id: connectionRow

                    anchors.centerIn: parent
                    spacing: 7

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4

                        color: apiClient.errorMessage.length > 0
                            ? root.error
                            : apiClient.loading
                                ? root.warning
                                : root.success
                    }

                    Label {
                        text: apiClient.loading
                            ? "Connecting"
                            : apiClient.errorMessage.length > 0
                                ? "Connection Error"
                                : "Connected"

                        color: apiClient.errorMessage.length > 0
                            ? root.error
                            : apiClient.loading
                                ? root.warning
                                : root.success

                        font.pixelSize: 12
                        font.bold: true
                    }
                }
            }

            RowLayout {
                spacing: 7

                Repeater {
                    model: themeModel

                    delegate: Rectangle {
                        required property string themeName
                        required property color previewColor

                        width: root.selectedTheme === themeName ? 16 : 12
                        height: width
                        radius: width / 2

                        color: previewColor

                        border.width:
                                root.selectedTheme === themeName ? 2 : 0

                        border.color: root.surface

                        Behavior on width {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -5

                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onEntered: {
                                if (root.selectedTheme !== themeName)
                                    parent.width = 16
                            }

                            onExited: {
                                if (root.selectedTheme !== themeName)
                                    parent.width = 12
                            }

                            onClicked: {
                                root.selectedTheme = themeName
                            }
                        }
                    }
                }
            }
        }
    }

    StackView {
        id: stackView

        anchors.fill: parent

        initialItem: dashboardPageComponent
    }

    Timer {
        id: dashboardRefreshTimer

        interval: 5000
        repeat: true
        triggeredOnStart: false

        running:
            root.visible
            && stackView.depth === 1

        onTriggered: {
            if (
                !apiClient.loading
                && !apiClient.actionLoading
            ) {
                apiClient.loadTests()
            }
        }
    }

    Component {
        id: dashboardPageComponent

        ScrollView {
            id: dashboardScrollView

            clip: true
            contentWidth: availableWidth

            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            background: Rectangle {
                color: root.pageBackground
            }

            ColumnLayout {
                width: dashboardScrollView.availableWidth

                spacing: 16

                anchors.leftMargin: root.compactLayout ? 14 : 24
                anchors.rightMargin: root.compactLayout ? 14 : 24
                anchors.topMargin: 22
                anchors.bottomMargin: 26

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Label {
                            text: "Lifecycle Dashboard"
                            color: root.textPrimary

                            font.pixelSize:
                                root.compactLayout ? 22 : 27

                            font.bold: true
                        }

                        Label {
                            Layout.fillWidth: true

                            text:
                                "Current tests, connected instrumentation, and system health."

                            color: root.textSecondary
                            font.pixelSize: 13
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight:
                        root.compactLayout ? 206 : 104

                    radius: 18
                    color: root.surface
                    border.width: 1
                    border.color: root.borderColor

                    GridLayout {
                        anchors.fill: parent
                        anchors.margins: 16

                        columns: root.compactLayout ? 2 : 4
                        columnSpacing: 12
                        rowSpacing: 12

                        Repeater {
                            model: [
                                {
                                    "title": "Active Tests",
                                    "detail": "Currently running",
                                    "value": root.activeTests,
                                    "symbol": "∿",
                                    "colorValue": root.accent,
                                    "backgroundValue": root.accentLight
                                },
                                {
                                    "title": "Completed Tests",
                                    "detail": "Finished lifecycle runs",
                                    "value": root.completedTests,
                                    "symbol": "✓",
                                    "colorValue": root.success,
                                    "backgroundValue": root.successLight
                                },
                                {
                                    "title": "Connected Devices",
                                    "detail": "Available instrumentation",
                                    "value": root.devicesOnline,
                                    "symbol": "▣",
                                    "colorValue": "#9A7BEF",
                                    "backgroundValue": "#F0EAFF"
                                },
                                {
                                    "title": "Active Alerts",
                                    "detail":
                                            root.activeAlerts > 0
                                        ? "Require attention"
                                        : "No issues reported",
                                    "value": root.activeAlerts,
                                    "symbol": "!",
                                    "colorValue":
                                            root.activeAlerts > 0
                                        ? root.error
                                        : root.textMuted,
                                    "backgroundValue":
                                            root.activeAlerts > 0
                                        ? root.errorLight
                                        : root.surfaceMuted
                                }
                            ]

                            delegate: RowLayout {
                                required property var modelData

                                Layout.fillWidth: true
                                spacing: 11

                                Rectangle {
                                    width: 42
                                    height: 42
                                    radius: 14

                                    color:
                                        modelData.backgroundValue

                                    Label {
                                        anchors.centerIn: parent

                                        text: modelData.symbol
                                        color:
                                            modelData.colorValue

                                        font.pixelSize: 17
                                        font.bold: true
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    RowLayout {
                                        spacing: 7

                                        Label {
                                            text: modelData.value
                                            color: root.textPrimary

                                            font.pixelSize: 23
                                            font.bold: true
                                        }

                                        Label {
                                            text: modelData.title
                                            color: root.textPrimary

                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }

                                    Label {
                                        Layout.fillWidth: true

                                        text: modelData.detail
                                        color: root.textSecondary

                                        font.pixelSize: 9
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true

                    columns: root.narrowLayout ? 1 : 3
                    columnSpacing: 14
                    rowSpacing: 14

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.columnSpan:
                            root.narrowLayout ? 1 : 2

                        Layout.preferredHeight: 470
                        Layout.minimumHeight: 390

                        radius: 20
                        color: root.surface

                        border.width: 1
                        border.color: root.borderColor

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 12

                            RowLayout {
                                Layout.fillWidth: true

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Label {
                                        text: "Tests"
                                        color: root.textPrimary

                                        font.pixelSize: 17
                                        font.bold: true
                                    }

                                    Label {
                                        text:
                                                recentTestsModel.count === 0
                                            ? "No tests have been created."
                                            : recentTestsModel.count
                                            + (
                                                    recentTestsModel.count === 1
                                                    ? " test"
                                                    : " tests"
                                            )

                                        color: root.textSecondary
                                        font.pixelSize: 11
                                    }
                                }

                                Rectangle {
                                    visible: root.activeTests > 0

                                    implicitWidth:
                                        activeTestCountLabel.implicitWidth
                                        + 18

                                    implicitHeight: 28
                                    radius: 10
                                    color: root.accentLight

                                    Label {
                                        id: activeTestCountLabel

                                        anchors.centerIn: parent

                                        text:
                                            root.activeTests
                                            + (
                                                    root.activeTests === 1
                                                    ? " active"
                                                    : " active"
                                            )

                                        color: root.accent

                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                            }

                            Rectangle {
                                visible:
                                    !root.compactLayout
                                    && recentTestsModel.count > 0

                                Layout.fillWidth: true
                                Layout.preferredHeight: 30

                                radius: 10
                                color: root.surfaceMuted

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 10

                                    Label {
                                        Layout.preferredWidth:
                                            root.activityTestWidth

                                        text: "TEST"
                                        color: root.textMuted

                                        font.pixelSize: 10
                                        font.bold: true
                                    }

                                    Label {
                                        Layout.preferredWidth:
                                            root.activityDeviceWidth

                                        text: "DEVICE"
                                        color: root.textMuted

                                        font.pixelSize: 10
                                        font.bold: true
                                    }

                                    Label {
                                        Layout.preferredWidth:
                                            root.activityStatusWidth

                                        text: "STATUS"
                                        color: root.textMuted

                                        font.pixelSize: 10
                                        font.bold: true

                                        horizontalAlignment:
                                            Text.AlignHCenter
                                    }

                                    Label {
                                        Layout.preferredWidth:
                                            root.activityProgressWidth

                                        text: "PROGRESS"
                                        color: root.textMuted

                                        font.pixelSize: 10
                                        font.bold: true
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            ListView {
                                id: testsList

                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                model: recentTestsModel
                                visible: recentTestsModel.count > 0

                                clip: true
                                spacing: 4

                                boundsBehavior:
                                    Flickable.StopAtBounds

                                ScrollBar.vertical: ScrollBar {
                                    policy:
                                            testsList.contentHeight
                                        > testsList.height
                                        ? ScrollBar.AsNeeded
                                        : ScrollBar.AlwaysOff
                                }

                                delegate: Rectangle {
                                    id: testRow

                                    required property var testId
                                    required property string testName
                                    required property string deviceName
                                    required property string statusText
                                    required property int progressValue
                                    required property string updatedText

                                    width: testsList.width
                                    height:
                                        root.compactLayout ? 88 : 58

                                    radius: 12

                                    color:
                                        testMouseArea.containsMouse
                                            ? root.surfaceMuted
                                            : "transparent"

                                    property color statusColor: {
                                        if (statusText === "Completed")
                                            return root.success

                                        if (
                                            statusText === "Warning"
                                        )
                                            return root.warning

                                        if (statusText === "Error")
                                            return root.error

                                        if (statusText === "Queued")
                                            return root.textSecondary

                                        return root.accent
                                    }

                                    property color statusBackground: {
                                        if (statusText === "Completed")
                                            return root.successLight

                                        if (
                                            statusText === "Warning"
                                        )
                                            return root.warningLight

                                        if (statusText === "Error")
                                            return root.errorLight

                                        if (statusText === "Queued")
                                            return root.surfaceMuted

                                        return root.accentLight
                                    }

                                    MouseArea {
                                        id: testMouseArea

                                        anchors.fill: parent
                                        hoverEnabled: true

                                        cursorShape:
                                            Qt.PointingHandCursor

                                        onClicked: {
                                            apiClient.loadTest(
                                                testRow.testId
                                            )
                                        }
                                    }

                                    RowLayout {
                                        visible: !root.compactLayout

                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 10

                                        Label {
                                            Layout.preferredWidth:
                                                root.activityTestWidth

                                            text: testRow.testName
                                            color: root.textPrimary

                                            elide: Text.ElideRight

                                            font.pixelSize: 12
                                            font.bold: true
                                        }

                                        Label {
                                            Layout.preferredWidth:
                                                root.activityDeviceWidth

                                            text: testRow.deviceName
                                            color: root.textSecondary

                                            elide: Text.ElideRight
                                            font.pixelSize: 11
                                        }

                                        Rectangle {
                                            Layout.preferredWidth:
                                                root.activityStatusWidth

                                            Layout.preferredHeight: 30
                                            radius: 10

                                            color:
                                                testRow.statusBackground

                                            Label {
                                                anchors.centerIn: parent

                                                text:
                                                    testRow.statusText

                                                color:
                                                    testRow.statusColor

                                                font.pixelSize: 10
                                                font.bold: true
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.preferredWidth:
                                                root.activityProgressWidth

                                            spacing: 4

                                            Label {
                                                text:
                                                    testRow.progressValue
                                                    + "%"

                                                color: root.textPrimary

                                                font.pixelSize: 10
                                                font.bold: true
                                            }

                                            ProgressBar {
                                                Layout.fillWidth: true

                                                from: 0
                                                to: 100
                                                value:
                                                    testRow.progressValue

                                                background: Rectangle {
                                                    implicitHeight: 6
                                                    radius: 3

                                                    color:
                                                        root.borderColor
                                                }

                                                contentItem: Item {
                                                    implicitHeight: 6

                                                    Rectangle {
                                                        width:
                                                            parent.width
                                                            * Math.max(
                                                                0,
                                                                Math.min(
                                                                    100,
                                                                    testRow
                                                                        .progressValue
                                                                )
                                                            )
                                                            / 100

                                                        height:
                                                            parent.height

                                                        radius: 3

                                                        color:
                                                            testRow
                                                                .statusColor
                                                    }
                                                }
                                            }
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                        }
                                    }

                                    ColumnLayout {
                                        visible: root.compactLayout

                                        anchors.fill: parent
                                        anchors.margins: 9
                                        spacing: 5

                                        RowLayout {
                                            Layout.fillWidth: true

                                            Label {
                                                Layout.fillWidth: true

                                                text:
                                                    testRow.testName

                                                color:
                                                    root.textPrimary

                                                elide:
                                                    Text.ElideRight

                                                font.pixelSize: 12
                                                font.bold: true
                                            }

                                            Label {
                                                text:
                                                    testRow.progressValue
                                                    + "%"

                                                color:
                                                    testRow.statusColor

                                                font.pixelSize: 11
                                                font.bold: true
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true

                                            Label {
                                                Layout.fillWidth: true

                                                text:
                                                    testRow.deviceName

                                                color:
                                                    root.textSecondary

                                                elide:
                                                    Text.ElideRight

                                                font.pixelSize: 11
                                            }

                                            Rectangle {
                                                implicitWidth:
                                                    compactStatus
                                                        .implicitWidth
                                                    + 16

                                                implicitHeight: 23
                                                radius: 8

                                                color:
                                                    testRow
                                                        .statusBackground

                                                Label {
                                                    id: compactStatus

                                                    anchors.centerIn:
                                                        parent

                                                    text:
                                                        testRow
                                                            .statusText

                                                    color:
                                                        testRow
                                                            .statusColor

                                                    font.pixelSize: 10
                                                    font.bold: true
                                                }
                                            }
                                        }

                                        ProgressBar {
                                            Layout.fillWidth: true

                                            from: 0
                                            to: 100
                                            value:
                                                testRow.progressValue

                                            background: Rectangle {
                                                implicitHeight: 5
                                                radius: 3
                                                color: root.borderColor
                                            }

                                            contentItem: Item {
                                                implicitHeight: 5

                                                Rectangle {
                                                    width:
                                                        parent.width
                                                        * testRow
                                                            .progressValue
                                                        / 100

                                                    height: parent.height
                                                    radius: 3

                                                    color:
                                                        testRow
                                                            .statusColor
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                visible:
                                    recentTestsModel.count === 0

                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                spacing: 8

                                Item {
                                    Layout.fillHeight: true
                                }

                                Rectangle {
                                    Layout.alignment:
                                        Qt.AlignHCenter

                                    width: 50
                                    height: 50
                                    radius: 16
                                    color: root.accentLight

                                    Label {
                                        anchors.centerIn: parent

                                        text: "∿"
                                        color: root.accent

                                        font.pixelSize: 21
                                        font.bold: true
                                    }
                                }

                                Label {
                                    Layout.alignment:
                                        Qt.AlignHCenter

                                    text: "No test activity"
                                    color: root.textPrimary

                                    font.pixelSize: 13
                                    font.bold: true
                                }

                                Label {
                                    Layout.alignment:
                                        Qt.AlignHCenter

                                    text:
                                        "Created tests will appear here."

                                    color: root.textMuted
                                    font.pixelSize: 11
                                }

                                Item {
                                    Layout.fillHeight: true
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 14

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 206

                            radius: 20
                            color: root.surface

                            border.width: 1
                            border.color: root.borderColor

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 20
                                spacing: 12

                                RowLayout {
                                    Layout.fillWidth: true

                                    Label {
                                        Layout.fillWidth: true

                                        text: "Environment"
                                        color: root.textPrimary

                                        font.pixelSize: 16
                                        font.bold: true
                                    }

                                    Label {
                                        text: "Live"
                                        color: root.textMuted

                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    columns: 2
                                    columnSpacing: 10
                                    rowSpacing: 10

                                    Repeater {
                                        model: [
                                            {
                                                "label": "Temperature",
                                                "value":
                                                    root.temperature
                                                        .toFixed(1)
                                                    + " °C"
                                            },
                                            {
                                                "label": "Humidity",
                                                "value":
                                                    root.humidity
                                                        .toFixed(1)
                                                    + "%"
                                            },
                                            {
                                                "label": "Pressure",
                                                "value":
                                                    root.pressure
                                                        .toFixed(1)
                                                    + " kPa"
                                            },
                                            {
                                                "label": "Air Flow",
                                                "value":
                                                    root.airFlow
                                                        .toFixed(1)
                                                    + " m/s"
                                            }
                                        ]

                                        delegate: Rectangle {
                                            required property var modelData

                                            Layout.fillWidth: true
                                            Layout.fillHeight: true

                                            radius: 12
                                            color: root.surfaceMuted

                                            Column {
                                                anchors.centerIn: parent
                                                spacing: 2

                                                Label {
                                                    anchors.horizontalCenter:
                                                        parent
                                                            .horizontalCenter

                                                    text:
                                                        modelData.value

                                                    color:
                                                        root.textPrimary

                                                    font.pixelSize: 12
                                                    font.bold: true
                                                }

                                                Label {
                                                    anchors.horizontalCenter:
                                                        parent
                                                            .horizontalCenter

                                                    text:
                                                        modelData.label

                                                    color:
                                                        root.textSecondary

                                                    font.pixelSize: 9
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight:
                        root.compactLayout ? 236 : 108

                    radius: 20
                    color: root.surface

                    border.width: 1
                    border.color: root.borderColor

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                Layout.fillWidth: true

                                text: "System Health"
                                color: root.textPrimary

                                font.pixelSize: 15
                                font.bold: true
                            }

                            Label {
                                text:
                                    root.backendAvailable
                                        ? "Connected"
                                        : apiClient.loading
                                            ? "Checking"
                                            : "Unavailable"

                                color:
                                    root.backendAvailable
                                        ? root.success
                                        : apiClient.loading
                                            ? root.warning
                                            : root.textMuted

                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            columns: root.compactLayout ? 2 : 4
                            columnSpacing: 10
                            rowSpacing: 10

                            Repeater {
                                model: [
                                    {
                                        "label": "DAQ Controller",
                                        "online":
                                            root.daqOnline
                                            || root.activeTests > 0
                                    },
                                    {
                                        "label": "Database",
                                        "online":
                                            root.databaseOnline
                                            || root.backendAvailable
                                    },
                                    {
                                        "label": "Instrumentation",
                                        "online":
                                            root.instrumentationOnline
                                            || root.devicesOnline > 0
                                            || root.activeTests > 0
                                    },
                                    {
                                        "label": "Network",
                                        "online":
                                            root.networkOnline
                                            || root.backendAvailable
                                    }
                                ]

                                delegate: Rectangle {
                                    required property var modelData

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    radius: 12
                                    color: root.surfaceMuted

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        spacing: 8

                                        Rectangle {
                                            width: 8
                                            height: 8
                                            radius: 4

                                            color:
                                                modelData.online
                                                    ? root.success
                                                    : root.textMuted
                                        }

                                        Label {
                                            Layout.fillWidth: true

                                            text: modelData.label
                                            color: root.textPrimary

                                            font.pixelSize: 10
                                            font.bold: true
                                        }

                                        Label {
                                            text:
                                                modelData.online
                                                    ? "Online"
                                                    : "No status"

                                            color:
                                                modelData.online
                                                    ? root.success
                                                    : root.textMuted

                                            font.pixelSize: 9
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    visible:
                        root.activeAlerts > 0
                        || apiClient.errorMessage.length > 0

                    Layout.fillWidth: true
                    Layout.preferredHeight: 74

                    radius: 18
                    color: root.errorLight

                    border.width: 1
                    border.color: root.error

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        Rectangle {
                            width: 34
                            height: 34
                            radius: 11
                            color: root.error

                            Label {
                                anchors.centerIn: parent

                                text: "!"
                                color: "white"

                                font.pixelSize: 17
                                font.bold: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: "System attention required"
                                color: root.error

                                font.pixelSize: 12
                                font.bold: true
                            }

                            Label {
                                Layout.fillWidth: true

                                text:
                                        apiClient.errorMessage.length > 0
                                    ? apiClient.errorMessage
                                    : root.activeAlerts
                                    + (
                                            root.activeAlerts === 1
                                            ? " active alert"
                                            : " active alerts"
                                    )

                                color: root.textPrimary

                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: themePopup

        width: Math.min(root.width - 28, 430)
        height: Math.min(root.height - 60, 510)

        anchors.centerIn: Overlay.overlay

        modal: true
        focus: true

        closePolicy:
            Popup.CloseOnEscape
            | Popup.CloseOnPressOutside

        background: Rectangle {
            radius: 24

            color: root.surface

            border.width: 1
            border.color: root.borderColor
        }

        Overlay.modal: Rectangle {
            color: "#66000000"
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22

            spacing: 16

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Label {
                        text: "Appearance"
                        color: root.textPrimary

                        font.pixelSize: 21
                        font.bold: true
                    }

                    Label {
                        text: "Choose a dashboard accent theme."
                        color: root.textSecondary

                        font.pixelSize: 12
                    }
                }

                ToolButton {
                    text: "×"

                    contentItem: Label {
                        text: parent.text
                        color: root.textSecondary

                        font.pixelSize: 24

                        horizontalAlignment:
                            Text.AlignHCenter

                        verticalAlignment:
                            Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 12

                        color:
                            parent.hovered
                                ? root.surfaceMuted
                                : "transparent"
                    }

                    onClicked: {
                        themePopup.close()
                    }
                }
            }

            GridView {
                id: themeGrid

                Layout.fillWidth: true
                Layout.fillHeight: true

                model: themeModel

                cellWidth: width / 2
                cellHeight: 126

                clip: true

                boundsBehavior:
                    Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                delegate: Item {
                    required property string themeName
                    required property color previewColor

                    width: themeGrid.cellWidth
                    height: themeGrid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 6

                        radius: 18

                        color:
                                root.selectedTheme === themeName
                            ? Qt.lighter(previewColor, 1.75)
                            : root.surfaceMuted

                        border.width:
                                root.selectedTheme === themeName
                            ? 2
                            : 1

                        border.color:
                                root.selectedTheme === themeName
                            ? previewColor
                            : root.borderColor

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                root.selectedTheme = themeName
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14

                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true

                                Label {
                                    Layout.fillWidth: true

                                    text: themeName
                                    color: root.textPrimary

                                    font.pixelSize: 12
                                    font.bold: true
                                }

                                Label {
                                    visible:
                                        root.selectedTheme
                                        === themeName

                                    text: "✓"
                                    color: previewColor

                                    font.pixelSize: 15
                                    font.bold: true
                                }
                            }

                            RowLayout {
                                spacing: 6

                                Repeater {
                                    model: 5

                                    Rectangle {
                                        required property int index

                                        width: 18
                                        height: 18

                                        radius: 9

                                        color:
                                            Qt.lighter(
                                                previewColor,
                                                1 + index * 0.18
                                            )
                                    }
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                            }

                            Rectangle {
                                Layout.fillWidth: true

                                height: 10
                                radius: 5

                                color: previewColor
                            }
                        }
                    }
                }
            }

            Button {
                Layout.fillWidth: true

                implicitHeight: 42

                text: "Done"

                contentItem: Label {
                    text: parent.text
                    color: "white"

                    font.pixelSize: 13
                    font.bold: true

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 14
                    color: root.accent
                }

                onClicked: {
                    themePopup.close()
                }
            }
        }
    }

    Connections {
        target: apiClient

        function onTestsChanged() {
            root.testsLoaded = true

            console.log(
                "testsChanged fired. Test count:",
                apiClient.tests.length
            )

            console.log(
                "Tests received:",
                JSON.stringify(apiClient.tests)
            )

            Qt.callLater(function() {
                root.populateTests(apiClient.tests)
            })
        }

        function onTestLoaded(testId) {
            if (stackView.depth === 1) {
                stackView.push(detailsPageComponent)
            }
        }
    }

    Component {
        id: detailsPageComponent

        TestDetailsPage {}
    }

    Component.onCompleted: {
        /*
            Populate immediately if ApiClient already contains tests,
            then request the latest database state.
        */
        root.populateTests(apiClient.tests)
        apiClient.loadTests()
    }
}