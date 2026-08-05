import QtQuick
import QtQuick.Controls
import QtQuick.Layouts


Page {
    id: page

    property var appWindow:
        ApplicationWindow.window

    /*
        ApiClient may expose either the test object directly:

            selectedTest = { test_id: 13, ... }

        or the complete API response:

            selectedTest = { success: true, test: { ... } }

        Accept both shapes so the page always resolves the actual test.
    */
    property var selectedTestPayload:
        apiClient.selectedTest || ({})

    property var testData:
            selectedTestPayload.test
        && typeof selectedTestPayload.test === "object"
        ? selectedTestPayload.test
        : selectedTestPayload

    property string status:
        String(testData.status || "unknown")
            .toLowerCase()

    property int testId:
        Number(testData.test_id || 0)

    property var monitoringOptions:
            testData.configuration
        && testData.configuration.monitoring_options
        ? testData.configuration.monitoring_options
        : []

    /*
        These remain empty unless the API later supplies them.
        Supported future fields:

        testData.latest_measurements
        testData.samples
        testData.events
        testData.instrument_health
    */

    property var latestMeasurements:
        testData.latest_measurements || ({})

    property var samples:
        testData.samples || []

    property var events:
        testData.events || []

    property var instrumentHealth:
        testData.instrument_health || []

    /*
        Refresh the selected test while it is running. The single-test API
        response now includes latest_measurements, so every refresh updates
        the measurement cards through the bindings above.
    */
    Timer {
        id: liveMeasurementTimer

        interval: 2000
        repeat: true

        running:
            page.visible
            && page.testId > 0
            && page.status === "running"

        onTriggered: {
            if (
                !apiClient.loading
                && !apiClient.actionLoading
            ) {
                apiClient.loadTest(
                    page.testId
                )
            }
        }
    }

    Timer {
        id: plotRefreshTimer

        interval: 5000
        repeat: true

        running:
            page.visible
            && page.testId > 0
            && page.status === "running"

        onTriggered: {
            apiClient.loadPlotData(
                page.testId,
                600
            )
        }
    }

    property int loadedPlotTestId: 0

    function ensurePlotDataLoaded() {
        if (
            page.testId <= 0
            || page.loadedPlotTestId === page.testId
        ) {
            return
        }

        page.loadedPlotTestId = page.testId

        apiClient.loadPlotData(
            page.testId,
            600
        )
    }

    onTestIdChanged: {
        page.ensurePlotDataLoaded()
    }

    Component.onCompleted: {
        page.ensurePlotDataLoaded()
    }

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

    readonly property color info:
        appWindow ? appWindow.info : "#568FE8"

    readonly property color infoLight:
        appWindow ? appWindow.infoLight : "#EAF2FF"

    background: Rectangle {
        color: page.pageBackground
    }

    ScrollView {
        id: pageScroll

        anchors.fill: parent
        clip: true
        contentWidth: availableWidth

        ScrollBar.horizontal.policy:
            ScrollBar.AlwaysOff

        ScrollBar.vertical.policy:
            ScrollBar.AsNeeded

        ColumnLayout {
            width: pageScroll.availableWidth

            anchors.leftMargin:
                page.compactLayout ? 14 : 24

            anchors.rightMargin:
                page.compactLayout ? 14 : 24

            anchors.topMargin: 20
            anchors.bottomMargin: 28

            spacing: 16

            /*
                Header and primary actions
            */

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight:
                    page.compactLayout ? 188 : 112

                radius: 22
                color: page.surface

                border.width: 1
                border.color: page.borderColor

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18

                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        Rectangle {
                            width: 46
                            height: 46
                            radius: 15

                            color:
                                page.statusBackground(
                                    page.status
                                )

                            Label {
                                anchors.centerIn: parent

                                text:
                                        page.status === "running"
                                    ? "▶"
                                    : page.status === "completed"
                                        ? "✓"
                                        : page.status === "paused"
                                            ? "Ⅱ"
                                            : "•"

                                color:
                                    page.statusForeground(
                                        page.status
                                    )

                                font.pixelSize: 19
                                font.bold: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Label {
                                Layout.fillWidth: true

                                text:
                                    testData.name
                                    || testData.device_name
                                    || "Lifecycle Test"

                                color: page.textPrimary

                                font.pixelSize:
                                    page.compactLayout ? 21 : 25

                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Label {
                                Layout.fillWidth: true

                                text:
                                    (testData.device_name
                                        || "No device")
                                    + "  •  Test "
                                    + page.testId
                                    + (
                                        testData.serial_number
                                            ? "  •  Serial "
                                            + testData.serial_number
                                            : ""
                                    )

                                color: page.textSecondary
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            visible: !page.compactLayout

                            implicitWidth:
                                headerStatusLabel.implicitWidth
                                + 22

                            implicitHeight: 32
                            radius: 11

                            color:
                                page.statusBackground(
                                    page.status
                                )

                            Label {
                                id: headerStatusLabel
                                anchors.centerIn: parent

                                text:
                                    page.formatStatus(
                                        page.status
                                    )

                                color:
                                    page.statusForeground(
                                        page.status
                                    )

                                font.pixelSize: 11
                                font.bold: true
                            }
                        }
                    }

                    Flow {
                        id: primaryActionFlow

                        Layout.fillWidth: true
                        spacing: 9

                        Button {
                            text:
                                    page.status === "paused"
                                ? "Resume"
                                : "Start"

                            visible:
                                page.status === "created"
                                || page.status === "paused"

                            enabled:
                                !apiClient.actionLoading
                                && page.testId > 0

                            implicitHeight: 38

                            contentItem: Label {
                                text: parent.text
                                color: "white"

                                font.pixelSize: 11
                                font.bold: true

                                horizontalAlignment:
                                    Text.AlignHCenter

                                verticalAlignment:
                                    Text.AlignVCenter
                            }

                            background: Rectangle {
                                radius: 12

                                color:
                                    parent.enabled
                                        ? page.accent
                                        : page.borderColor
                            }

                            onClicked: {
                                apiClient.startTest(
                                    page.testId
                                )
                            }
                        }

                        Button {
                            text: "Pause"

                            visible:
                                page.status === "running"

                            enabled:
                                !apiClient.actionLoading

                            implicitHeight: 38

                            contentItem: Label {
                                text: parent.text
                                color: page.warning

                                font.pixelSize: 11
                                font.bold: true

                                horizontalAlignment:
                                    Text.AlignHCenter

                                verticalAlignment:
                                    Text.AlignVCenter
                            }

                            background: Rectangle {
                                radius: 12
                                color: page.warningLight

                                border.width: 1
                                border.color: page.warning
                            }

                            onClicked: {
                                apiClient.pauseTest(
                                    page.testId
                                )
                            }
                        }

                        Button {
                            text: "Complete"

                            visible:
                                page.status === "running"
                                || page.status === "paused"

                            enabled:
                                !apiClient.actionLoading

                            implicitHeight: 38

                            contentItem: Label {
                                text: parent.text
                                color: page.success

                                font.pixelSize: 11
                                font.bold: true

                                horizontalAlignment:
                                    Text.AlignHCenter

                                verticalAlignment:
                                    Text.AlignVCenter
                            }

                            background: Rectangle {
                                radius: 12
                                color: page.successLight

                                border.width: 1
                                border.color: page.success
                            }

                            onClicked: {
                                apiClient.completeTest(
                                    page.testId
                                )
                            }
                        }

                        Button {
                            text: "Abort"

                            visible:
                                page.status === "created"
                                || page.status === "running"
                                || page.status === "paused"

                            enabled:
                                !apiClient.actionLoading

                            implicitHeight: 38

                            contentItem: Label {
                                text: parent.text
                                color: page.error

                                font.pixelSize: 11
                                font.bold: true

                                horizontalAlignment:
                                    Text.AlignHCenter

                                verticalAlignment:
                                    Text.AlignVCenter
                            }

                            background: Rectangle {
                                radius: 12
                                color: page.errorLight

                                border.width: 1
                                border.color: page.error
                            }

                            onClicked: {
                                abortDialog.open()
                            }
                        }

                        BusyIndicator {
                            running: apiClient.actionLoading
                            visible: apiClient.actionLoading

                            width: 36
                            height: 36
                        }
                    }
                }
            }

            Rectangle {
                visible:
                    apiClient.actionMessage.length > 0
                    || apiClient.errorMessage.length > 0

                Layout.fillWidth: true

                Layout.preferredHeight:
                    notificationLabel.implicitHeight
                    + 26

                radius: 14

                color:
                        apiClient.errorMessage.length > 0
                    ? page.errorLight
                    : page.successLight

                border.width: 1

                border.color:
                        apiClient.errorMessage.length > 0
                    ? page.error
                    : page.success

                Label {
                    id: notificationLabel

                    anchors.fill: parent
                    anchors.margins: 13

                    text:
                            apiClient.errorMessage.length > 0
                        ? apiClient.errorMessage
                        : apiClient.actionMessage

                    color:
                            apiClient.errorMessage.length > 0
                        ? page.error
                        : page.success

                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
            }

            /*
                Live measurements
            */

            RowLayout {
                Layout.fillWidth: true

                Label {
                    Layout.fillWidth: true

                    text: "Live Measurements"
                    color: page.textPrimary

                    font.pixelSize: 17
                    font.bold: true
                }

                RowLayout {
                    spacing: 6

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4

                        color:
                                Object.keys(
                                    page.latestMeasurements
                                ).length > 0
                            ? page.success
                            : page.textMuted
                    }

                    Label {
                        text:
                                Object.keys(
                                    page.latestMeasurements
                                ).length > 0
                            ? "Live"
                            : "Waiting for data"

                        color:
                                Object.keys(
                                    page.latestMeasurements
                                ).length > 0
                            ? page.success
                            : page.textMuted

                        font.pixelSize: 10
                        font.bold: true
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true

                columns:
                    page.compactLayout
                        ? 2
                        : page.narrowLayout
                            ? 3
                            : 5

                columnSpacing: 10
                rowSpacing: 10

                MeasurementCard {
                    title: "Voltage"
                    unit: "V"

                    value:
                        page.measurementValue(
                            "voltage"
                        )

                    symbol: "V"
                    symbolColor: page.info
                    symbolBackground: page.infoLight
                }

                MeasurementCard {
                    title: "Current"
                    unit: "A"

                    value:
                        page.measurementValue(
                            "current"
                        )

                    symbol: "A"
                    symbolColor: page.accent
                    symbolBackground: page.accentLight
                }

                MeasurementCard {
                    title: "Resistance"
                    unit: "Ω"

                    value:
                        page.measurementValue(
                            "resistance"
                        )

                    symbol: "Ω"
                    symbolColor: "#9A7BEF"
                    symbolBackground: "#F0EAFF"
                }

                MeasurementCard {
                    title: "RPM"
                    unit: "rpm"

                    value:
                        page.measurementValue(
                            "rpm"
                        )

                    symbol: "↻"
                    symbolColor: page.warning
                    symbolBackground: page.warningLight
                }

                MeasurementCard {
                    title: "Temperature"
                    unit: "°C"

                    value:
                        page.measurementValue(
                            "temperature"
                        )

                    symbol: "°"
                    symbolColor: page.error
                    symbolBackground: page.errorLight
                }
            }

            /*
                Analysis first: this is the primary working area.
            */

            Rectangle {
                Layout.fillWidth: true
                readonly property int plotColumnCount:
                    page.narrowLayout ? 1 : 2

                readonly property int plotRowCount:
                    Math.max(
                        1,
                        Math.ceil(
                            apiClient.plotData.length
                            / plotColumnCount
                        )
                    )

                Layout.preferredHeight:
                        apiClient.plotData.length > 0
                    ? 92
                    + plotRowCount * 292
                    + Math.max(
                        0,
                        plotRowCount - 1
                    ) * 12
                    : 170

                Layout.minimumHeight:
                    Layout.preferredHeight

                radius: 20
                color: page.surface

                border.width: 1
                border.color: page.borderColor

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: "Analysis"
                                color: page.textPrimary

                                font.pixelSize: 17
                                font.bold: true
                            }

                            Label {
                                text:
                                    "Configured plots for this test"

                                color: page.textSecondary
                                font.pixelSize: 10
                            }
                        }

                    }

                    GridLayout {
                        visible:
                            apiClient.plotData.length > 0

                        Layout.fillWidth: true
                        Layout.preferredHeight:
                            parent.parent.plotRowCount
                            * 280
                            + Math.max(
                                0,
                                parent.parent.plotRowCount - 1
                            ) * rowSpacing

                        columns:
                            parent.parent.plotColumnCount

                        columnSpacing: 12
                        rowSpacing: 12

                        Repeater {
                            model: apiClient.plotData

                            delegate: PlotCard {
                                required property var modelData

                                Layout.fillWidth: true
                                Layout.preferredHeight: 280
                                Layout.minimumHeight: 280
                                Layout.maximumHeight: 280

                                plotData: modelData
                                surfaceColor: page.surface
                                borderColor: page.borderColor
                                textPrimary: page.textPrimary
                                textSecondary: page.textSecondary
                                gridColor: page.borderColor

                                onClicked: function(plot) {
                                    if (page.StackView.view) {
                                        page.StackView.view.push(
                                            plotDetailPageComponent,
                                            {
                                                "plotData": plot
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }

                    EmptyState {
                        visible:
                            apiClient.plotData.length === 0

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        symbol: "∿"
                        title: "No analysis plots"
                        description:
                            "Configured graphs will appear here when plot data is available."
                    }
                }
            }

            /*
                Test overview and configuration
            */

            GridLayout {
                Layout.fillWidth: true

                columns:
                    page.narrowLayout ? 1 : 3

                columnSpacing: 14
                rowSpacing: 14

                Rectangle {
                    Layout.fillWidth: true
                    Layout.columnSpan:
                        page.narrowLayout ? 1 : 2

                    Layout.preferredHeight: 310

                    radius: 20
                    color: page.surface

                    border.width: 1
                    border.color: page.borderColor

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                Layout.fillWidth: true

                                text:
                                    "Monitoring Configuration"

                                color: page.textPrimary

                                font.pixelSize: 15
                                font.bold: true
                            }

                            Label {
                                text:
                                    page.monitoringOptions.length
                                    + (
                                            page.monitoringOptions.length
                                            === 1
                                            ? " channel"
                                            : " channels"
                                    )

                                color: page.textSecondary
                                font.pixelSize: 10
                            }
                        }

                        ListView {
                            id: monitoringList

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            model:
                                page.monitoringOptions

                            visible:
                                page.monitoringOptions.length > 0

                            clip: true
                            spacing: 7

                            boundsBehavior:
                                Flickable.StopAtBounds

                            ScrollBar.vertical:
                                ScrollBar {
                                    policy:
                                        ScrollBar.AsNeeded
                                }

                            delegate: Rectangle {
                                required property var modelData
                                required property int index

                                width:
                                    monitoringList.width

                                height:
                                    monitoringOptionLayout
                                        .implicitHeight
                                    + 20

                                radius: 12
                                color: page.surfaceMuted

                                RowLayout {
                                    id: monitoringOptionLayout

                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12

                                    spacing: 10

                                    Rectangle {
                                        width: 28
                                        height: 28

                                        radius: 9
                                        color: page.accentLight

                                        Label {
                                            anchors.centerIn: parent

                                            text: index + 1
                                            color: page.accent

                                            font.pixelSize: 10
                                            font.bold: true
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Label {
                                            Layout.fillWidth: true

                                            text:
                                                modelData.type
                                                || "Monitoring"

                                            color: page.textPrimary

                                            font.pixelSize: 12
                                            font.bold: true

                                            elide:
                                                Text.ElideRight
                                        }

                                        Label {
                                            Layout.fillWidth: true

                                            text:
                                                page.settingsText(
                                                    modelData.settings
                                                )

                                            color:
                                                page.textSecondary

                                            font.pixelSize: 10

                                            wrapMode:
                                                Text.WordWrap
                                        }
                                    }
                                }
                            }
                        }

                        EmptyState {
                            visible:
                                page.monitoringOptions.length === 0

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            symbol: "◌"
                            title: "No monitoring configured"
                            description:
                                "Monitoring channels will appear here when included in the test."
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 310

                    radius: 20
                    color: page.surface

                    border.width: 1
                    border.color: page.borderColor

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 12

                        Label {
                            text: "Test Overview"
                            color: page.textPrimary

                            font.pixelSize: 15
                            font.bold: true
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            clip: true

                            ScrollBar.horizontal.policy:
                                ScrollBar.AlwaysOff

                            ColumnLayout {
                                width: parent.width
                                spacing: 12

                                DetailRow {
                                    label: "Duration"

                                    value:
                                        page.formatDuration(
                                            testData.duration_seconds
                                        )
                                }

                                DetailRow {
                                    label: "Created"

                                    value:
                                        page.formatDate(
                                            testData.created_at_utc
                                        )
                                }

                                DetailRow {
                                    label: "Started"

                                    value:
                                        page.formatDate(
                                            testData.started_at_utc
                                        )
                                }

                                DetailRow {
                                    label: "Completed"

                                    value:
                                        page.formatDate(
                                            testData.completed_at_utc
                                        )
                                }

                                DetailRow {
                                    label: "Notes"

                                    value:
                                        testData.notes
                                        || "No notes"
                                }
                            }
                        }
                    }
                }
            }

            /*
                Timeline information is conditional instead of permanently empty.
            */

            GridLayout {
                visible:
                    page.events.length > 0
                    || page.samples.length > 0

                Layout.fillWidth: true

                columns:
                    page.narrowLayout ? 1 : 2

                columnSpacing: 14
                rowSpacing: 14

                Rectangle {
                    visible: page.samples.length > 0

                    Layout.fillWidth: true
                    Layout.preferredHeight: 280

                    radius: 20
                    color: page.surface

                    border.width: 1
                    border.color: page.borderColor

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 10

                        Label {
                            text: "Recent Samples"
                            color: page.textPrimary

                            font.pixelSize: 15
                            font.bold: true
                        }

                        ListView {
                            id: sampleList

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            model: page.samples
                            clip: true
                            spacing: 4

                            delegate: Rectangle {
                                required property var modelData
                                required property int index

                                width: sampleList.width
                                height: 42

                                radius: 10

                                color:
                                        index % 2 === 0
                                    ? page.surfaceMuted
                                    : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10

                                    spacing: 10

                                    Label {
                                        Layout.preferredWidth: 82

                                        text:
                                            modelData.timestamp
                                            || modelData.created_at
                                            || ""

                                        color: page.textSecondary
                                        font.pixelSize: 9

                                        elide:
                                            Text.ElideRight
                                    }

                                    Label {
                                        Layout.fillWidth: true

                                        text:
                                            page.sampleText(
                                                modelData
                                            )

                                        color: page.textPrimary
                                        font.pixelSize: 10

                                        elide:
                                            Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    visible: page.events.length > 0

                    Layout.fillWidth: true
                    Layout.preferredHeight: 280

                    radius: 20
                    color: page.surface

                    border.width: 1
                    border.color: page.borderColor

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 10

                        Label {
                            text: "Event Log"
                            color: page.textPrimary

                            font.pixelSize: 15
                            font.bold: true
                        }

                        ListView {
                            id: eventList

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            model: page.events
                            clip: true
                            spacing: 6

                            delegate: Rectangle {
                                required property var modelData

                                width: eventList.width

                                height:
                                    eventRow.implicitHeight
                                    + 16

                                radius: 11
                                color: page.surfaceMuted

                                RowLayout {
                                    id: eventRow

                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    anchors.leftMargin: 11
                                    anchors.rightMargin: 11

                                    spacing: 9

                                    Rectangle {
                                        width: 8
                                        height: 8
                                        radius: 4

                                        color:
                                            page.eventColor(
                                                modelData
                                            )
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Label {
                                            Layout.fillWidth: true

                                            text:
                                                modelData.message
                                                || modelData.event
                                                || "Test event"

                                            color: page.textPrimary

                                            font.pixelSize: 10
                                            font.bold: true

                                            wrapMode:
                                                Text.WordWrap
                                        }

                                        Label {
                                            text:
                                                page.formatDate(
                                                    modelData.timestamp
                                                    || modelData.created_at
                                                )

                                            color: page.textSecondary
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
    }

    Component {
        id: plotDetailPageComponent

        PlotDetailPage {}
    }

    Dialog {
        id: abortDialog

        anchors.centerIn: parent

        modal: true
        focus: true

        title: "Abort lifecycle test?"

        standardButtons:
            Dialog.Yes | Dialog.No

        onAccepted: {
            apiClient.abortTest(
                page.testId
            )
        }

        background: Rectangle {
            radius: 18
            color: page.surface

            border.width: 1
            border.color: page.borderColor
        }

        contentItem: ColumnLayout {
            spacing: 12

            Label {
                Layout.preferredWidth: 300

                text:
                    "This will permanently mark "
                    + "the test as aborted."

                color: page.textPrimary
                wrapMode: Text.WordWrap
            }

            Label {
                Layout.preferredWidth: 300

                text:
                    "Existing test records will remain "
                    + "in the database."

                color: page.textSecondary
                font.pixelSize: 11

                wrapMode: Text.WordWrap
            }
        }
    }

    /*
        Reusable components
    */

    component DetailCard: Rectangle {
        property string title: ""
        property string value: ""
        property string helper: ""
        property string symbol: ""

        property color symbolColor:
            page.accent

        property color symbolBackground:
            page.accentLight

        Layout.fillWidth: true
        Layout.preferredHeight: 132

        radius: 20
        color: page.surface

        border.width: 1
        border.color: page.borderColor

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 17

            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                Label {
                    Layout.fillWidth: true

                    text: parent.parent.parent.title
                    color: page.textSecondary

                    font.pixelSize: 12
                    font.bold: true
                }

                Rectangle {
                    width: 34
                    height: 34

                    radius: 11

                    color:
                        parent.parent.parent
                            .symbolBackground

                    Label {
                        anchors.centerIn: parent

                        text:
                            parent.parent.parent.parent
                                .symbol

                        color:
                            parent.parent.parent.parent
                                .symbolColor

                        font.pixelSize: 15
                        font.bold: true
                    }
                }
            }

            Label {
                Layout.fillWidth: true

                text: parent.parent.parent.value
                color: page.textPrimary

                font.pixelSize: 17
                font.bold: true

                elide: Text.ElideRight
            }

            Label {
                Layout.fillWidth: true

                text: parent.parent.helper
                color: page.textMuted

                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }
    }

    component MeasurementCard: Rectangle {
        property string title: ""
        property string value: "0"
        property string unit: ""
        property string symbol: ""

        property color symbolColor:
            page.accent

        property color symbolBackground:
            page.accentLight

        Layout.fillWidth: true
        Layout.preferredHeight: 116

        radius: 18
        color: page.surface

        border.width: 1
        border.color: page.borderColor

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14

            spacing: 7

            RowLayout {
                Layout.fillWidth: true

                Label {
                    Layout.fillWidth: true

                    text: parent.parent.parent.title
                    color: page.textSecondary

                    font.pixelSize: 11
                    font.bold: true
                }

                Rectangle {
                    width: 30
                    height: 30

                    radius: 10

                    color:
                        parent.parent.parent
                            .symbolBackground

                    Label {
                        anchors.centerIn: parent

                        text:
                            parent.parent.parent.parent
                                .symbol

                        color:
                            parent.parent.parent.parent
                                .symbolColor

                        font.pixelSize: 12
                        font.bold: true
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 5

                Label {
                    text: parent.parent.parent.value
                    color: page.textPrimary

                    font.pixelSize: 21
                    font.bold: true
                }

                Label {
                    text: parent.parent.parent.unit
                    color: page.textSecondary

                    font.pixelSize: 10
                }
            }
        }
    }

    component DetailRow: ColumnLayout {
        property string label: ""
        property string value: ""

        Layout.fillWidth: true
        spacing: 4

        Label {
            text: parent.label
            color: page.textMuted

            font.pixelSize: 10
            font.bold: true
        }

        Label {
            Layout.fillWidth: true

            text: parent.value
            color: page.textPrimary

            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        Rectangle {
            Layout.fillWidth: true

            height: 1
            color: page.borderColor
        }
    }

    component EmptyState: ColumnLayout {
        property string symbol: ""
        property string title: ""
        property string description: ""

        spacing: 8

        Item {
            Layout.fillHeight: true
        }

        Rectangle {
            Layout.alignment:
                Qt.AlignHCenter

            width: 48
            height: 48

            radius: 16
            color: page.accentLight

            Label {
                anchors.centerIn: parent

                text: parent.parent.symbol
                color: page.accent

                font.pixelSize: 20
                font.bold: true
            }
        }

        Label {
            Layout.alignment:
                Qt.AlignHCenter

            text: parent.title
            color: page.textPrimary

            font.pixelSize: 13
            font.bold: true
        }

        Label {
            Layout.fillWidth: true

            text: parent.description
            color: page.textMuted

            font.pixelSize: 10

            horizontalAlignment:
                Text.AlignHCenter

            wrapMode: Text.WordWrap
        }

        Item {
            Layout.fillHeight: true
        }
    }

    /*
        Formatting helpers
    */

    function measurementValue(key) {
        const value =
            page.latestMeasurements[key]

        if (
            value === undefined
            || value === null
            || value === ""
        ) {
            return "0"
        }

        const numericValue =
            Number(value)

        if (Number.isFinite(numericValue)) {
            return numericValue.toFixed(2)
        }

        return String(value)
    }

    function formatStatus(value) {
        const normalized =
            String(value || "")
                .toLowerCase()

        switch (normalized) {
            case "created":
                return "Created"

            case "running":
            case "active":
            case "started":
            case "in_progress":
            case "in progress":
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

            default:
                return normalized.length > 0
                    ? normalized.charAt(0)
                        .toUpperCase()
                    + normalized.slice(1)
                    : "Unknown"
        }
    }

    function statusForeground(value) {
        switch (
            String(value || "")
                .toLowerCase()
            ) {
            case "running":
            case "active":
            case "started":
            case "in_progress":
            case "in progress":
                return page.accent

            case "paused":
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

    function statusBackground(value) {
        switch (
            String(value || "")
                .toLowerCase()
            ) {
            case "running":
            case "active":
            case "started":
            case "in_progress":
            case "in progress":
                return page.accentLight

            case "paused":
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
            return "Not yet"
        }

        const date =
            new Date(value)

        if (isNaN(date.getTime())) {
            return String(value)
        }

        return date.toLocaleString()
    }

    function settingsText(settings) {
        if (!settings) {
            return "No settings provided."
        }

        const keys =
            Object.keys(settings)

        if (keys.length === 0) {
            return "No settings provided."
        }

        const values = []

        for (const key of keys) {
            let title =
                key.replaceAll("_", " ")

            title =
                title.charAt(0).toUpperCase()
                + title.slice(1)

            values.push(
                title
                + ": "
                + settings[key]
            )
        }

        return values.join(" • ")
    }

    function sampleText(sample) {
        if (!sample) {
            return ""
        }

        const parts = []

        if (
            sample.voltage !== undefined
        ) {
            parts.push(
                "Voltage: "
                + sample.voltage
                + " V"
            )
        }

        if (
            sample.current !== undefined
        ) {
            parts.push(
                "Current: "
                + sample.current
                + " A"
            )
        }

        if (
            sample.resistance !== undefined
        ) {
            parts.push(
                "Resistance: "
                + sample.resistance
                + " Ω"
            )
        }

        if (
            sample.rpm !== undefined
        ) {
            parts.push(
                "RPM: "
                + sample.rpm
            )
        }

        if (
            sample.temperature !== undefined
        ) {
            parts.push(
                "Temperature: "
                + sample.temperature
                + " °C"
            )
        }

        if (parts.length === 0) {
            return sample.value !== undefined
                ? String(sample.value)
                : "Sample"
        }

        return parts.join(" • ")
    }

    function eventColor(eventData) {
        const level =
            String(
                eventData.level
                || eventData.severity
                || eventData.type
                || ""
            ).toLowerCase()

        if (
            level === "error"
            || level === "failed"
            || level === "abort"
            || level === "aborted"
        ) {
            return page.error
        }

        if (
            level === "warning"
            || level === "paused"
        ) {
            return page.warning
        }

        if (
            level === "success"
            || level === "completed"
        ) {
            return page.success
        }

        return page.accent
    }
}