import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: page

    property var plotData: ({})
    property var appWindow: ApplicationWindow.window

    readonly property var selectedTestPayload:
        apiClient.selectedTest || ({})

    readonly property var selectedTest:
            selectedTestPayload.test
        && typeof selectedTestPayload.test === "object"
        ? selectedTestPayload.test
        : selectedTestPayload

    readonly property int testId:
        Number(selectedTest.test_id || 0)

    readonly property string testStatus:
        String(selectedTest.status || "")
            .toLowerCase()

    property string plotIdentity:
        page.makePlotIdentity(plotData)

    property bool viewInitialized: false
    property int previousPointCount: 0

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

    /*
        25, 100, 200, or 0 for the complete dataset.
        Clicking Minimum or Maximum temporarily uses five points.
    */
    property int selectedResolution: 100
    property int visibleStartIndex: 0
    property int visibleEndIndex: 0
    property int focusedPointIndex: -1

    property int dragStartIndex: 0

    property bool inspectionActive: false
    property int inspectionPointIndex: -1

    property real inspectionOverlayX: 0
    property real inspectionOverlayY: 0
    property real pendingInspectionX: 0

    readonly property var activeSeries: {
        const series = seriesList()

        if (series.length === 0) {
            return ({})
        }

        return series[0]
    }

    readonly property var activePoints: {
        if (
            !activeSeries
            || !activeSeries.points
        ) {
            return []
        }

        return activeSeries.points
    }

    readonly property int effectiveWindowSize: {
        if (activePoints.length === 0) {
            return 0
        }

        if (selectedResolution === 0) {
            return activePoints.length
        }

        return Math.min(
            selectedResolution,
            activePoints.length
        )
    }

    readonly property int maximumWindowStart:
        Math.max(
            0,
            activePoints.length - effectiveWindowSize
        )

    readonly property int visiblePointCount:
            activePoints.length === 0
        ? 0
        : Math.max(
            0,
            visibleEndIndex - visibleStartIndex + 1
        )

    background: Rectangle {
        color: page.pageBackground
    }

    function seriesList() {
        if (
            !plotData
            || !plotData.series
        ) {
            return []
        }

        return plotData.series
    }

    function makePlotIdentity(plot) {
        if (!plot) {
            return ""
        }

        const series =
                plot.series
            && plot.series.length > 0
            ? plot.series[0]
            : ({})

        return [
            String(plot.plot_id || plot.id || ""),
            String(plot.title || ""),
            String(series.source || ""),
            String(series.channel || ""),
            String(series.label || "")
        ].join("|")
    }

    function matchingPlotFromApi() {
        const plots = apiClient.plotData || []

        for (
            let index = 0;
            index < plots.length;
            ++index
        ) {
            if (
                page.makePlotIdentity(plots[index])
                === page.plotIdentity
            ) {
                return plots[index]
            }
        }

        /*
            Older responses may not provide a stable plot ID.
            Use the title as a conservative fallback.
        */
        for (
            let index = 0;
            index < plots.length;
            ++index
        ) {
            if (
                String(plots[index].title || "")
                === String(page.plotData.title || "")
            ) {
                return plots[index]
            }
        }

        return null
    }

    function applyRefreshedPlot() {
        const refreshedPlot =
            page.matchingPlotFromApi()

        if (!refreshedPlot) {
            return
        }

        /*
            Remember whether the user was viewing the newest available
            window. Auto-refresh follows new samples only in that case.
            Historical browsing and horizontal swipe position are preserved.
        */
        const wasFollowingLatest =
            page.visibleEndIndex
            >= Math.max(
                0,
                page.activePoints.length - 1
            )

        const savedStart =
            page.visibleStartIndex

        page.previousPointCount =
            page.activePoints.length

        page.plotData = refreshedPlot

        Qt.callLater(function() {
            if (!page.viewInitialized) {
                page.resetView()
                page.viewInitialized = true
                return
            }

            if (wasFollowingLatest) {
                page.applyWindowStart(
                    page.maximumWindowStart
                )
            } else {
                page.applyWindowStart(
                    savedStart
                )
            }
        })
    }

    Timer {
        id: plotDetailRefreshTimer

        interval: 5000
        repeat: true
        triggeredOnStart: false

        running:
            page.visible
            && page.testId > 0
            && (
                page.testStatus === "running"
                || page.testStatus === "active"
                || page.testStatus === "started"
                || page.testStatus === "in_progress"
                || page.testStatus === "in progress"
            )

        onTriggered: {
            if (
                !apiClient.loading
                && !apiClient.actionLoading
            ) {
                apiClient.loadPlotData(
                    page.testId,
                    600
                )
            }
        }
    }

    Connections {
        target: apiClient

        function onPlotDataChanged() {
            page.applyRefreshedPlot()
        }
    }

    function plotTitle() {
        if (
            plotData
            && plotData.title
        ) {
            return String(plotData.title)
        }

        return seriesLabel()
    }

    function seriesLabel() {
        return (
            activeSeries.label
            || activeSeries.channel
            || "Measurement"
        )
    }

    function seriesUnit() {
        return activeSeries.unit
            ? String(activeSeries.unit)
            : ""
    }

    function seriesChannel() {
        return String(
            activeSeries.channel || ""
        ).toLowerCase()
    }

    function quantityAccent() {
        const channel = seriesChannel()

        if (channel.includes("temperature")) {
            return "#ED7A86"
        }

        if (channel.includes("voltage")) {
            return "#568FE8"
        }

        if (channel.includes("current")) {
            return "#8B78E6"
        }

        if (channel.includes("resistance")) {
            return "#9A7BEF"
        }

        if (
            channel.includes("rpm")
            || channel.includes("speed")
        ) {
            return "#E8A542"
        }

        return page.accent
    }

    function quantityTint() {
        const channel = seriesChannel()

        if (channel.includes("temperature")) {
            return "#FDEBED"
        }

        if (channel.includes("voltage")) {
            return "#EAF2FF"
        }

        if (channel.includes("current")) {
            return "#F0EDFF"
        }

        if (channel.includes("resistance")) {
            return "#F0EAFF"
        }

        if (
            channel.includes("rpm")
            || channel.includes("speed")
        ) {
            return "#FFF3DF"
        }

        return page.accentLight
    }

    function clampWindowStart(index) {
        return Math.max(
            0,
            Math.min(
                maximumWindowStart,
                Math.round(index)
            )
        )
    }

    function applyWindowStart(index) {
        if (activePoints.length === 0) {
            visibleStartIndex = 0
            visibleEndIndex = 0
            chartCanvas.requestPaint()
            return
        }

        visibleStartIndex =
            clampWindowStart(index)

        visibleEndIndex =
            Math.min(
                activePoints.length - 1,
                visibleStartIndex
                + effectiveWindowSize
                - 1
            )

        chartCanvas.requestPaint()
    }

    function setResolution(resolution) {
        focusedPointIndex = -1

        const previousCenter =
                activePoints.length > 0
            ? Math.round(
                (
                    visibleStartIndex
                    + visibleEndIndex
                ) / 2
            )
            : 0

        selectedResolution = resolution
        clearInspection()

        if (selectedResolution === 0) {
            applyWindowStart(0)
            return
        }

        applyWindowStart(
            previousCenter
            - Math.floor(
                effectiveWindowSize / 2
            )
        )
    }

    function resetView() {
        selectedResolution = 100
        focusedPointIndex = -1

        /*
            Open at the most recent samples.
        */
        applyWindowStart(maximumWindowStart)
    }

    function clearInspection() {
        inspectionActive = false
        inspectionPointIndex = -1
    }

    function queueInspection(positionX) {
        pendingInspectionX = positionX

        if (!inspectionFrameTimer.running) {
            inspectionFrameTimer.start()
        }
    }

    function updateInspection(positionX) {
        if (
            selectedResolution !== 0
            || activePoints.length === 0
            || chartCanvas.width <= 0
            || chartCanvas.height <= 0
        ) {
            clearInspection()
            return
        }

        const leftMargin = 58
        const rightMargin = 18
        const topMargin = 18
        const bottomMargin = 34

        const plotWidth =
            Math.max(
                1,
                chartCanvas.width
                - leftMargin
                - rightMargin
            )

        const plotHeight =
            Math.max(
                1,
                chartCanvas.height
                - topMargin
                - bottomMargin
            )

        const canvasLocalX =
            Math.max(
                leftMargin,
                Math.min(
                    leftMargin + plotWidth,
                    positionX - chartCanvas.x
                )
            )

        const ratio =
            Math.max(
                0,
                Math.min(
                    1,
                    (canvasLocalX - leftMargin)
                    / plotWidth
                )
            )

        const pointIndex =
            Math.max(
                0,
                Math.min(
                    activePoints.length - 1,
                    Math.round(
                        ratio
                        * (
                            activePoints.length - 1
                        )
                    )
                )
            )

        const point =
            activePoints[pointIndex]

        if (!point) {
            clearInspection()
            return
        }

        let yMin =
            Number.POSITIVE_INFINITY

        let yMax =
            Number.NEGATIVE_INFINITY

        for (
            let index = 0;
            index < activePoints.length;
            ++index
        ) {
            const value =
                Number(activePoints[index].value)

            if (!Number.isFinite(value)) {
                continue
            }

            yMin = Math.min(yMin, value)
            yMax = Math.max(yMax, value)
        }

        if (
            !Number.isFinite(yMin)
            || !Number.isFinite(yMax)
        ) {
            clearInspection()
            return
        }

        let yRange = yMax - yMin

        if (yRange <= 0) {
            const center = yMin
            yMin = center - 1
            yMax = center + 1
            yRange = 2
        }

        const yPadding =
            Math.max(
                yRange * 0.12,
                0.05
            )

        yMin -= yPadding
        yMax += yPadding
        yRange = yMax - yMin

        const numericValue =
            Number(point.value)

        const canvasLocalY =
            topMargin
            + (
                1
                - (
                    (numericValue - yMin)
                    / yRange
                )
            )
            * plotHeight

        inspectionPointIndex = pointIndex
        inspectionOverlayX =
            chartCanvas.x + canvasLocalX
        inspectionOverlayY =
            chartCanvas.y + canvasLocalY
        inspectionActive = true
    }

    Timer {
        id: inspectionFrameTimer

        interval: 16
        repeat: false

        onTriggered: {
            page.updateInspection(
                page.pendingInspectionX
            )

            /*
                If another move arrived during this frame, schedule the
                newest coordinate for the next frame.
            */
            if (
                fullTestInspector.pressed
                && page.inspectionActive
            ) {
                restart()
            }
        }
    }

    function inspectedPoint() {
        if (
            inspectionPointIndex < 0
            || inspectionPointIndex
            >= activePoints.length
        ) {
            return null
        }

        return activePoints[
            inspectionPointIndex
            ]
    }

    function visiblePoints() {
        if (activePoints.length === 0) {
            return []
        }

        const result = []

        for (
            let index = visibleStartIndex;
            index <= visibleEndIndex;
            ++index
        ) {
            result.push(activePoints[index])
        }

        return result
    }

    function latestVisiblePoint() {
        if (visiblePointCount === 0) {
            return null
        }

        return activePoints[visibleEndIndex]
    }

    function fullStats() {
        if (activePoints.length === 0) {
            return {
                "minimum": NaN,
                "maximum": NaN,
                "average": NaN
            }
        }

        let minimum =
            Number.POSITIVE_INFINITY

        let maximum =
            Number.NEGATIVE_INFINITY

        let total = 0
        let count = 0

        for (
            let index = 0;
            index < activePoints.length;
            ++index
        ) {
            const value =
                Number(activePoints[index].value)

            if (!Number.isFinite(value)) {
                continue
            }

            minimum = Math.min(minimum, value)
            maximum = Math.max(maximum, value)
            total += value
            ++count
        }

        if (count === 0) {
            return {
                "minimum": NaN,
                "maximum": NaN,
                "average": NaN
            }
        }

        return {
            "minimum": minimum,
            "maximum": maximum,
            "average": total / count
        }
    }

    function extremeIndex(mode) {
        if (activePoints.length === 0) {
            return -1
        }

        let bestIndex = -1

        let bestValue =
                mode === "minimum"
            ? Number.POSITIVE_INFINITY
            : Number.NEGATIVE_INFINITY

        for (
            let index = 0;
            index < activePoints.length;
            ++index
        ) {
            const value =
                Number(activePoints[index].value)

            if (!Number.isFinite(value)) {
                continue
            }

            const better =
                    mode === "minimum"
                ? value < bestValue
                : value > bestValue

            if (better) {
                bestValue = value
                bestIndex = index
            }
        }

        return bestIndex
    }

    function focusExtreme(mode) {
        const centerIndex =
            extremeIndex(mode)

        if (centerIndex < 0) {
            return
        }

        /*
            Selected extreme plus the four nearest samples.
        */
        selectedResolution =
            Math.min(5, activePoints.length)

        focusedPointIndex =
            centerIndex

        applyWindowStart(
            centerIndex - 2
        )
    }

    function formatElapsed(seconds) {
        if (
            String(
                page.plotData.plot_type || ""
            ).toLowerCase() === "xy"
        ) {
            return page.formatValue(seconds)
        }

        const total = Math.max(
            0,
            Math.round(Number(seconds))
        )

        const hours =
            Math.floor(total / 3600)

        const minutes =
            Math.floor(
                (total % 3600) / 60
            )

        const remainingSeconds =
            total % 60

        if (hours > 0) {
            return (
                hours
                + ":"
                + String(minutes)
                    .padStart(2, "0")
                + ":"
                + String(
                    remainingSeconds
                ).padStart(2, "0")
            )
        }

        return (
            minutes
            + ":"
            + String(
                remainingSeconds
            ).padStart(2, "0")
        )
    }

    function formatValue(value) {
        const numeric = Number(value)

        if (!Number.isFinite(numeric)) {
            return "--"
        }

        const absolute =
            Math.abs(numeric)

        if (absolute >= 1000) {
            return numeric.toFixed(0)
        }

        if (absolute >= 100) {
            return numeric.toFixed(1)
        }

        if (absolute >= 10) {
            return numeric.toFixed(2)
        }

        return numeric.toFixed(3)
    }

    function valueWithUnit(value) {
        const formatted =
            formatValue(value)

        if (formatted === "--") {
            return formatted
        }

        return seriesUnit().length > 0
            ? formatted
            + " "
            + seriesUnit()
            : formatted
    }

    onPlotDataChanged: {
        chartCanvas.requestPaint()
    }

    onVisibleStartIndexChanged: {
        chartCanvas.requestPaint()
    }

    onVisibleEndIndexChanged: {
        chartCanvas.requestPaint()
    }

    Component.onCompleted: {
        Qt.callLater(function() {
            page.resetView()
            page.viewInitialized = true
            page.previousPointCount =
                page.activePoints.length
        })

        if (
            page.testId > 0
            && !apiClient.loading
            && !apiClient.actionLoading
        ) {
            apiClient.loadPlotData(
                page.testId,
                600
            )
        }
    }

    header: ToolBar {
        height: 68

        background: Rectangle {
            color: page.surface

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: page.borderColor
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 16
            spacing: 12

            ToolButton {
                implicitWidth: 42
                implicitHeight: 42

                contentItem: Label {
                    text: "‹"
                    color: page.textPrimary
                    font.pixelSize: 30

                    horizontalAlignment:
                        Text.AlignHCenter

                    verticalAlignment:
                        Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 15

                    color:
                        parent.down
                            ? page.surfaceMuted
                            : "transparent"
                }

                onClicked: {
                    if (page.StackView.view) {
                        page.StackView.view.pop()
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    Layout.fillWidth: true
                    text: page.plotTitle()
                    color: page.textPrimary
                    font.pixelSize: 18
                    font.bold: true
                    elide: Text.ElideRight
                }

                Label {
                    Layout.fillWidth: true

                    text:
                        page.visiblePointCount
                        + " of "
                        + page.activePoints.length
                        + " samples visible"

                    color: page.textSecondary
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                implicitWidth:
                    unitLabel.implicitWidth + 20

                implicitHeight: 32
                radius: 16
                color: page.quantityTint()

                visible:
                    page.seriesUnit().length > 0

                Label {
                    id: unitLabel

                    anchors.centerIn: parent
                    text: page.seriesUnit()
                    color: page.quantityAccent()
                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }
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

            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 18
            anchors.bottomMargin: 24

            spacing: 16

            GridLayout {
                Layout.fillWidth: true

                columns:
                        page.width < 720 ? 2 : 4

                columnSpacing: 10
                rowSpacing: 10

                MetricChip {
                    title: "Latest"

                    value: {
                        const point =
                            page.latestVisiblePoint()

                        return point
                            ? page.valueWithUnit(
                                point.value
                            )
                            : "--"
                    }

                    highlighted: true
                }

                MetricChip {
                    title: "Minimum"

                    value: page.valueWithUnit(
                        page.fullStats().minimum
                    )

                    clickable: true

                    onActivated: {
                        page.focusExtreme("minimum")
                    }
                }

                MetricChip {
                    title: "Average"

                    value: page.valueWithUnit(
                        page.fullStats().average
                    )
                }

                MetricChip {
                    title: "Maximum"

                    value: page.valueWithUnit(
                        page.fullStats().maximum
                    )

                    clickable: true

                    onActivated: {
                        page.focusExtreme("maximum")
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true

                Layout.preferredHeight:
                        page.width < 720 ? 430 : 530

                radius: 26
                color: page.quantityTint()

                border.width: 1
                border.color: page.quantityAccent()

                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                Layout.fillWidth: true
                                text: page.seriesLabel()
                                color: page.textPrimary
                                font.pixelSize: 15
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Label {
                                Layout.fillWidth: true

                                text:
                                        page.visiblePointCount > 0
                                    ? (
                                        page.formatElapsed(
                                            page.activePoints[
                                                page.visibleStartIndex
                                                ].elapsed_seconds
                                        )
                                        + " – "
                                        + page.formatElapsed(
                                            page.activePoints[
                                                page.visibleEndIndex
                                                ].elapsed_seconds
                                        )
                                    )
                                    : "No data range"

                                color: page.textSecondary
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            implicitWidth:
                                rangeLabel.implicitWidth + 20

                            implicitHeight: 30
                            radius: 15
                            color: page.surface

                            border.width: 1
                            border.color:
                                page.quantityAccent()

                            Label {
                                id: rangeLabel

                                anchors.centerIn: parent

                                text:
                                        page.selectedResolution === 0
                                    ? "All data"
                                    : (
                                        page.visiblePointCount
                                        + " points"
                                    )

                                color:
                                    page.quantityAccent()

                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }

                    Rectangle {
                        id: chartSurface

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        radius: 20
                        color: page.surface

                        border.width: 1
                        border.color: page.borderColor

                        clip: true

                        Canvas {
                            id: chartCanvas

                            anchors.fill: parent
                            anchors.margins: 10
                            antialiasing: true

                            onWidthChanged: {
                                requestPaint()
                            }

                            onHeightChanged: {
                                requestPaint()
                            }

                            onPaint: {
                                const context =
                                    getContext("2d")

                                context.reset()

                                const width =
                                    chartCanvas.width

                                const height =
                                    chartCanvas.height

                                if (
                                    width <= 0
                                    || height <= 0
                                ) {
                                    return
                                }

                                const points =
                                    page.visiblePoints()

                                const isScatter =
                                    String(
                                        page.plotData.plot_type || ""
                                    ).toLowerCase() === "xy"

                                const leftMargin = 58
                                const rightMargin = 18
                                const topMargin = 18
                                const bottomMargin = 34

                                const plotWidth =
                                    Math.max(
                                        1,
                                        width
                                        - leftMargin
                                        - rightMargin
                                    )

                                const plotHeight =
                                    Math.max(
                                        1,
                                        height
                                        - topMargin
                                        - bottomMargin
                                    )

                                if (points.length === 0) {
                                    context.fillStyle =
                                        page.textSecondary

                                    context.font =
                                        "13px sans-serif"

                                    context.textAlign =
                                        "center"

                                    context.textBaseline =
                                        "middle"

                                    context.fillText(
                                        "No historical data",
                                        width / 2,
                                        height / 2
                                    )

                                    return
                                }

                                let xMin =
                                    Number.POSITIVE_INFINITY

                                let xMax =
                                    Number.NEGATIVE_INFINITY

                                let yMin =
                                    Number.POSITIVE_INFINITY

                                let yMax =
                                    Number.NEGATIVE_INFINITY

                                for (
                                    let index = 0;
                                    index < points.length;
                                    ++index
                                ) {
                                    const elapsed =
                                        Number(
                                            points[index]
                                                .elapsed_seconds
                                        )

                                    const value =
                                        Number(
                                            points[index].value
                                        )

                                    if (
                                        Number.isFinite(elapsed)
                                        && Number.isFinite(value)
                                    ) {
                                        xMin = Math.min(
                                            xMin,
                                            elapsed
                                        )

                                        xMax = Math.max(
                                            xMax,
                                            elapsed
                                        )

                                        yMin = Math.min(
                                            yMin,
                                            value
                                        )

                                        yMax = Math.max(
                                            yMax,
                                            value
                                        )
                                    }
                                }

                                if (
                                    !Number.isFinite(xMin)
                                    || !Number.isFinite(xMax)
                                    || !Number.isFinite(yMin)
                                    || !Number.isFinite(yMax)
                                ) {
                                    return
                                }

                                let xRange = xMax - xMin
                                let yRange = yMax - yMin

                                if (xRange <= 0) {
                                    xRange = 1
                                }

                                if (yRange <= 0) {
                                    const center = yMin
                                    yMin = center - 1
                                    yMax = center + 1
                                    yRange = 2
                                }

                                const yPadding =
                                    Math.max(
                                        yRange * 0.12,
                                        0.05
                                    )

                                yMin -= yPadding
                                yMax += yPadding
                                yRange = yMax - yMin

                                context.strokeStyle =
                                    page.borderColor

                                context.fillStyle =
                                    page.textSecondary

                                context.lineWidth = 1
                                context.globalAlpha = 0.65
                                context.font =
                                    "10px sans-serif"

                                context.textBaseline =
                                    "middle"

                                const divisions = 4

                                for (
                                    let index = 0;
                                    index <= divisions;
                                    ++index
                                ) {
                                    const ratio =
                                        index / divisions

                                    const y =
                                        topMargin
                                        + ratio
                                        * plotHeight

                                    context.beginPath()
                                    context.moveTo(
                                        leftMargin,
                                        y
                                    )
                                    context.lineTo(
                                        leftMargin
                                        + plotWidth,
                                        y
                                    )
                                    context.stroke()

                                    const value =
                                        yMax
                                        - ratio
                                        * yRange

                                    context.globalAlpha = 0.9
                                    context.textAlign = "right"

                                    context.fillText(
                                        page.formatValue(value),
                                        leftMargin - 8,
                                        y
                                    )

                                    context.globalAlpha = 0.65
                                }

                                context.textBaseline = "top"

                                for (
                                    let index = 0;
                                    index <= divisions;
                                    ++index
                                ) {
                                    const ratio =
                                        index / divisions

                                    const x =
                                        leftMargin
                                        + ratio
                                        * plotWidth

                                    context.beginPath()
                                    context.moveTo(
                                        x,
                                        topMargin
                                    )
                                    context.lineTo(
                                        x,
                                        topMargin
                                        + plotHeight
                                    )
                                    context.stroke()

                                    const elapsed =
                                        xMin
                                        + ratio
                                        * xRange

                                    context.globalAlpha = 0.9

                                    context.textAlign =
                                            index === 0
                                        ? "left"
                                        : index === divisions
                                            ? "right"
                                            : "center"

                                    context.fillText(
                                        page.formatElapsed(
                                            elapsed
                                        ),
                                        x,
                                        topMargin
                                        + plotHeight
                                        + 9
                                    )

                                    context.globalAlpha = 0.65
                                }

                                context.globalAlpha = 1

                                const screenPoints = []

                                for (
                                    let index = 0;
                                    index < points.length;
                                    ++index
                                ) {
                                    const elapsed =
                                        Number(
                                            points[index]
                                                .elapsed_seconds
                                        )

                                    const value =
                                        Number(
                                            points[index].value
                                        )

                                    if (
                                        !Number.isFinite(elapsed)
                                        || !Number.isFinite(value)
                                    ) {
                                        continue
                                    }

                                    const x =
                                        leftMargin
                                        + (
                                            (elapsed - xMin)
                                            / xRange
                                        )
                                        * plotWidth

                                    const y =
                                        topMargin
                                        + (
                                            1
                                            - (
                                                (value - yMin)
                                                / yRange
                                            )
                                        )
                                        * plotHeight

                                    screenPoints.push({
                                        "x": x,
                                        "y": y
                                    })
                                }

                                if (screenPoints.length === 0) {
                                    return
                                }

                                if (!isScatter) {
                                    context.beginPath()

                                    context.moveTo(
                                        screenPoints[0].x,
                                        topMargin + plotHeight
                                    )

                                    for (
                                        let index = 0;
                                        index < screenPoints.length;
                                        ++index
                                    ) {
                                        context.lineTo(
                                            screenPoints[index].x,
                                            screenPoints[index].y
                                        )
                                    }

                                    context.lineTo(
                                        screenPoints[
                                            screenPoints.length - 1
                                            ].x,
                                        topMargin + plotHeight
                                    )

                                    context.closePath()

                                    context.fillStyle =
                                        page.quantityAccent()

                                    context.globalAlpha = 0.11
                                    context.fill()
                                    context.globalAlpha = 1

                                    context.beginPath()
                                    context.lineWidth = 3.5
                                    context.lineCap = "round"
                                    context.lineJoin = "round"

                                    context.strokeStyle =
                                        page.quantityAccent()

                                    context.moveTo(
                                        screenPoints[0].x,
                                        screenPoints[0].y
                                    )

                                    for (
                                        let index = 1;
                                        index < screenPoints.length;
                                        ++index
                                    ) {
                                        context.lineTo(
                                            screenPoints[index].x,
                                            screenPoints[index].y
                                        )
                                    }

                                    context.stroke()

                                }

                                if (
                                    isScatter
                                    || screenPoints.length <= 60
                                ) {
                                    for (
                                        let index = 0;
                                        index < screenPoints.length;
                                        ++index
                                    ) {
                                        const point =
                                            screenPoints[index]

                                        context.beginPath()

                                        context.arc(
                                            point.x,
                                            point.y,
                                            isScatter ? 3.5 : 4.5,
                                            0,
                                            Math.PI * 2
                                        )

                                        context.fillStyle =
                                            page.surface

                                        context.fill()

                                        context.lineWidth = 2.5

                                        context.strokeStyle =
                                            page.quantityAccent()

                                        context.stroke()
                                    }
                                }

                                if (
                                    page.focusedPointIndex >= 0
                                    && page.focusedPointIndex
                                    >= page.visibleStartIndex
                                    && page.focusedPointIndex
                                    <= page.visibleEndIndex
                                ) {
                                    const localIndex =
                                        page.focusedPointIndex
                                        - page.visibleStartIndex

                                    if (
                                        localIndex >= 0
                                        && localIndex
                                        < screenPoints.length
                                    ) {
                                        const focusPoint =
                                            screenPoints[localIndex]

                                        context.beginPath()

                                        context.arc(
                                            focusPoint.x,
                                            focusPoint.y,
                                            10,
                                            0,
                                            Math.PI * 2
                                        )

                                        context.fillStyle =
                                            page.quantityAccent()

                                        context.globalAlpha = 0.18
                                        context.fill()
                                        context.globalAlpha = 1

                                        context.beginPath()

                                        context.arc(
                                            focusPoint.x,
                                            focusPoint.y,
                                            5.5,
                                            0,
                                            Math.PI * 2
                                        )

                                        context.fillStyle =
                                            page.quantityAccent()

                                        context.fill()
                                    }
                                }

                            }
                        }

                        Item {
                            id: inspectionOverlay

                            anchors.fill: parent
                            z: 18

                            visible:
                                page.selectedResolution === 0
                                && page.inspectionActive

                            Rectangle {
                                x: page.inspectionOverlayX
                                y: chartCanvas.y + 18

                                width: 1
                                height:
                                    Math.max(
                                        0,
                                        chartCanvas.height
                                        - 18
                                        - 34
                                    )

                                color: page.quantityAccent()
                                opacity: 0.72
                            }

                            Rectangle {
                                x:
                                    page.inspectionOverlayX
                                    - width / 2

                                y:
                                    page.inspectionOverlayY
                                    - height / 2

                                width: 12
                                height: 12
                                radius: 6

                                color: page.quantityAccent()

                                border.width: 3
                                border.color: page.surface
                            }

                            Rectangle {
                                id: inspectionBubble

                                readonly property real desiredX:
                                    page.inspectionOverlayX
                                    - width / 2

                                readonly property real minimumX: 8
                                readonly property real maximumX:
                                    inspectionOverlay.width
                                    - width
                                    - 8

                                x:
                                    Math.max(
                                        minimumX,
                                        Math.min(
                                            maximumX,
                                            desiredX
                                        )
                                    )

                                /*
                                    Keep the value fixed near the top of the
                                    chart so it never falls behind the finger
                                    or outside the readable area.
                                */
                                y: 12

                                width: 150
                                height: 54
                                radius: 12

                                color: page.surface

                                border.width: 1.5
                                border.color:
                                    page.quantityAccent()

                                Column {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    anchors.topMargin: 8
                                    spacing: 2

                                    Label {
                                        width: parent.width

                                        text: {
                                            const point =
                                                page.inspectedPoint()

                                            return point
                                                ? page.valueWithUnit(
                                                    point.value
                                                )
                                                : "--"
                                        }

                                        color:
                                            page.quantityAccent()

                                        font.pixelSize: 13
                                        font.bold: true

                                        elide: Text.ElideRight
                                    }

                                    Label {
                                        width: parent.width

                                        text: {
                                            const point =
                                                page.inspectedPoint()

                                            return point
                                                ? page.formatElapsed(
                                                    point
                                                        .elapsed_seconds
                                                )
                                                : ""
                                        }

                                        color: page.textSecondary
                                        font.pixelSize: 10

                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: fullTestInspector

                            anchors.fill: parent
                            z: 20

                            enabled:
                                page.selectedResolution === 0
                                && page.activePoints.length > 0

                            hoverEnabled: false

                            /*
                                Keep this gesture attached to the graph. Without
                                this, the surrounding ScrollView can steal the
                                pointer after enough horizontal movement and the
                                inspection capsule appears to freeze.
                            */
                            preventStealing: true
                            pressAndHoldInterval: 300

                            onPressAndHold: function(mouse) {
                                page.updateInspection(
                                    mouse.x
                                )
                            }

                            onPositionChanged: function(mouse) {
                                if (
                                    pressed
                                    && page.inspectionActive
                                ) {
                                    page.queueInspection(
                                        mouse.x
                                    )
                                }
                            }

                            onReleased: function(mouse) {
                                if (page.inspectionActive) {
                                    page.updateInspection(
                                        mouse.x
                                    )
                                }

                                page.clearInspection()
                            }

                            onCanceled: {
                                page.clearInspection()
                            }
                        }

                        /*
                            This handler recognizes horizontal dragging only.
                            Vertical gestures remain available to the outer
                            ScrollView.
                        */
                        DragHandler {
                            id: timelineDrag

                            target: null

                            xAxis.enabled: true
                            yAxis.enabled: false

                            enabled:
                                page.selectedResolution !== 0
                                && page.maximumWindowStart > 0

                            onActiveChanged: {
                                if (active) {
                                    page.dragStartIndex =
                                        page.visibleStartIndex

                                    page.focusedPointIndex = -1
                                }
                            }

                            onActiveTranslationChanged: {
                                if (!active) {
                                    return
                                }

                                const usableWidth =
                                    Math.max(
                                        1,
                                        chartSurface.width
                                    )

                                /*
                                    Moving one graph-width travels roughly one
                                    complete resolution window.
                                */
                                const indexDelta =
                                    Math.round(
                                        activeTranslation.x
                                        * page.effectiveWindowSize
                                        / usableWidth
                                    )

                                page.applyWindowStart(
                                    page.dragStartIndex
                                    - indexDelta
                                )
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        ResolutionButton {
                            label: "Detailed"
                            resolution: 25
                        }

                        ResolutionButton {
                            label: "Standard"
                            resolution: 100
                        }

                        ResolutionButton {
                            label: "Wide View"
                            resolution: 200
                        }

                        ResolutionButton {
                            label: "Full Test"
                            resolution: 0
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            Layout.fillWidth: true

                            text:
                                    page.selectedResolution === 0
                                ? "Press and hold to inspect a value"
                                : "Swipe the graph horizontally"

                            color: page.textSecondary
                            font.pixelSize: 10
                        }

                        Label {
                            text:
                                    page.visiblePointCount > 0
                                ? (
                                    "Samples "
                                    + (
                                        page.visibleStartIndex
                                        + 1
                                    )
                                    + "–"
                                    + (
                                        page.visibleEndIndex
                                        + 1
                                    )
                                )
                                : ""

                            color: page.quantityAccent()
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }
                }
            }
        }
    }

    component ResolutionButton: Button {
        property string label: ""
        property int resolution: 25

        Layout.fillWidth: true
        implicitHeight: 40

        text: label
        checkable: true

        checked:
            page.selectedResolution
            === resolution

        contentItem: Label {
            text: parent.text

            color:
                parent.checked
                    ? "white"
                    : page.quantityAccent()

            font.pixelSize: 11
            font.bold: true

            horizontalAlignment:
                Text.AlignHCenter

            verticalAlignment:
                Text.AlignVCenter
        }

        background: Rectangle {
            radius: 14

            color:
                parent.checked
                    ? page.quantityAccent()
                    : page.quantityTint()

            border.width: 1

            border.color:
                page.quantityAccent()
        }

        onClicked: {
            page.setResolution(resolution)
        }
    }

    component MetricChip: AbstractButton {
        id: metricChip

        property string title: ""
        property string value: "--"
        property bool highlighted: false
        property bool clickable: false

        signal activated()

        Layout.fillWidth: true
        Layout.preferredHeight: 92

        hoverEnabled: true

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 4

            Label {
                Layout.fillWidth: true
                text: metricChip.title
                color: page.textSecondary
                font.pixelSize: 10
                font.bold: true
                elide: Text.ElideRight
            }

            Label {
                Layout.fillWidth: true
                text: metricChip.value

                color:
                        metricChip.highlighted
                    || metricChip.clickable
                    ? page.quantityAccent()
                    : page.textPrimary

                font.pixelSize: 16
                font.bold: true
                elide: Text.ElideRight
            }

            Label {
                Layout.fillWidth: true

                visible:
                    metricChip.clickable

                text: "Tap to locate"
                color: page.textMuted
                font.pixelSize: 9
                elide: Text.ElideRight
            }
        }

        background: Rectangle {
            radius: 20

            color:
                    metricChip.down
                && metricChip.clickable
                ? page.quantityTint()
                : metricChip.highlighted
                    ? page.quantityTint()
                    : page.surface

            border.width:
                    metricChip.highlighted
                || metricChip.clickable
                ? 1.5
                : 1

            border.color:
                    metricChip.highlighted
                || metricChip.clickable
                ? page.quantityAccent()
                : page.borderColor
        }

        onClicked: {
            if (metricChip.clickable) {
                metricChip.activated()
            }
        }
    }
}