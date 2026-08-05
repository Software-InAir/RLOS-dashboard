import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property var plotData: ({})

    property color surfaceColor: "#FFFFFF"
    property color borderColor: "#E4E8EF"
    property color textPrimary: "#263044"
    property color textSecondary: "#778196"
    property color gridColor: "#E4E8EF"

    signal clicked(var plot)

    radius: 24
    color: root.cardBackgroundColor()

    border.width: 1
    border.color: root.cardBorderColor()

    clip: true

    /*
        Compact cards intentionally show five representative
        points, which creates four visible connected segments.

        The full-resolution dataset remains available in
        PlotDetailPage.
    */
    readonly property int previewPointCount: 5

    function plotTitle() {
        if (
            root.plotData
            && root.plotData.title
        ) {
            return String(
                root.plotData.title
            )
        }

        return "Measurement"
    }

    function seriesList() {
        if (
            !root.plotData
            || !root.plotData.series
        ) {
            return []
        }

        return root.plotData.series
    }

    /*
        Preview cards display one physical quantity.

        Multi-series configurations will be split into separate
        plot objects in the next ApiClient.cpp edit.
    */
    function primarySeries() {
        const series =
            root.seriesList()

        if (series.length === 0) {
            return ({})
        }

        return series[0]
    }

    function sourcePoints() {
        const series =
            root.primarySeries()

        if (
            !series
            || !series.points
        ) {
            return []
        }

        return series.points
    }

    function previewPoints() {
        const points =
            root.sourcePoints()

        const count =
            points.length

        if (
            count <= root.previewPointCount
        ) {
            return points
        }

        const result = []

        for (
            let index = 0;
            index < root.previewPointCount;
            ++index
        ) {
            const sourceIndex =
                Math.round(
                    index
                    * (count - 1)
                    / (
                        root.previewPointCount
                        - 1
                    )
                )

            result.push(
                points[sourceIndex]
            )
        }

        return result
    }

    function seriesLabel() {
        const series =
            root.primarySeries()

        return (
            series.label
            || series.channel
            || "Measurement"
        )
    }

    function seriesUnit() {
        const series =
            root.primarySeries()

        return series.unit
            ? String(series.unit)
            : ""
    }

    function seriesChannel() {
        const series =
            root.primarySeries()

        return String(
            series.channel || ""
        ).toLowerCase()
    }

    function latestPoint() {
        const points =
            root.sourcePoints()

        if (points.length === 0) {
            return null
        }

        return points[
            points.length - 1
            ]
    }

    function latestValue() {
        const point =
            root.latestPoint()

        if (!point) {
            return "--"
        }

        return root.formatValue(
            point.value
        )
    }

    function sampleCountText() {
        const count =
            root.sourcePoints().length

        if (count === 0) {
            return "No historical samples"
        }

        return (
            count
            + (
                    count === 1
                    ? " historical sample"
                    : " historical samples"
            )
        )
    }

    function accentColor() {
        const channel =
            root.seriesChannel()

        if (
            channel.includes("temperature")
        ) {
            return "#ED7A86"
        }

        if (
            channel.includes("voltage")
        ) {
            return "#568FE8"
        }

        if (
            channel.includes("current")
        ) {
            return "#8B78E6"
        }

        if (
            channel.includes("resistance")
        ) {
            return "#9A7BEF"
        }

        if (
            channel.includes("rpm")
            || channel.includes("speed")
        ) {
            return "#E8A542"
        }

        return "#568FE8"
    }

    function accentLightColor() {
        const channel =
            root.seriesChannel()

        if (
            channel.includes("temperature")
        ) {
            return "#FDEBED"
        }

        if (
            channel.includes("voltage")
        ) {
            return "#EAF2FF"
        }

        if (
            channel.includes("current")
        ) {
            return "#F0EDFF"
        }

        if (
            channel.includes("resistance")
        ) {
            return "#F0EAFF"
        }

        if (
            channel.includes("rpm")
            || channel.includes("speed")
        ) {
            return "#FFF3DF"
        }

        return "#EAF2FF"
    }

    function cardBackgroundColor() {
        /*
            Use a light quantity-specific tint instead of a
            plain white or gray graph card.
        */
        return root.accentLightColor()
    }

    function cardBorderColor() {
        return root.accentColor()
    }

    function xMinimum() {
        const points =
            root.previewPoints()

        if (points.length === 0) {
            return 0
        }

        let minimum =
            Number.POSITIVE_INFINITY

        for (
            let index = 0;
            index < points.length;
            ++index
        ) {
            const value =
                Number(
                    points[index]
                        .elapsed_seconds
                )

            if (
                Number.isFinite(value)
                && value < minimum
            ) {
                minimum = value
            }
        }

        return Number.isFinite(minimum)
            ? minimum
            : 0
    }

    function xMaximum() {
        const points =
            root.previewPoints()

        if (points.length === 0) {
            return 1
        }

        let maximum =
            Number.NEGATIVE_INFINITY

        for (
            let index = 0;
            index < points.length;
            ++index
        ) {
            const value =
                Number(
                    points[index]
                        .elapsed_seconds
                )

            if (
                Number.isFinite(value)
                && value > maximum
            ) {
                maximum = value
            }
        }

        return Number.isFinite(maximum)
            ? maximum
            : 1
    }

    function yMinimum() {
        const points =
            root.previewPoints()

        if (points.length === 0) {
            return 0
        }

        let minimum =
            Number.POSITIVE_INFINITY

        for (
            let index = 0;
            index < points.length;
            ++index
        ) {
            const value =
                Number(
                    points[index].value
                )

            if (
                Number.isFinite(value)
                && value < minimum
            ) {
                minimum = value
            }
        }

        return Number.isFinite(minimum)
            ? minimum
            : 0
    }

    function yMaximum() {
        const points =
            root.previewPoints()

        if (points.length === 0) {
            return 1
        }

        let maximum =
            Number.NEGATIVE_INFINITY

        for (
            let index = 0;
            index < points.length;
            ++index
        ) {
            const value =
                Number(
                    points[index].value
                )

            if (
                Number.isFinite(value)
                && value > maximum
            ) {
                maximum = value
            }
        }

        return Number.isFinite(maximum)
            ? maximum
            : 1
    }

    function formatElapsed(seconds) {
        if (
            String(
                root.plotData.plot_type || ""
            ).toLowerCase() === "xy"
        ) {
            return root.formatValue(seconds)
        }

        const total =
            Math.max(
                0,
                Math.round(
                    Number(seconds)
                )
            )

        const hours =
            Math.floor(
                total / 3600
            )

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
        const numeric =
            Number(value)

        if (
            !Number.isFinite(numeric)
        ) {
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

    function requestPaint() {
        chartCanvas.requestPaint()
    }

    onPlotDataChanged: {
        root.requestPaint()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18

        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Label {
                    Layout.fillWidth: true

                    text:
                        root.plotTitle()

                    color:
                        root.textPrimary

                    font.pixelSize: 16
                    font.bold: true

                    elide:
                        Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        width: 9
                        height: 9
                        radius: 4.5

                        color:
                            root.accentColor()
                    }

                    Label {
                        Layout.fillWidth: true

                        text:
                            root.seriesLabel()

                        color:
                            root.textSecondary

                        font.pixelSize: 11

                        elide:
                            Text.ElideRight
                    }
                }
            }

            Rectangle {
                implicitWidth:
                    openLabel.implicitWidth
                    + 22

                implicitHeight: 30
                radius: 15

                color:
                    root.surfaceColor

                border.width: 1
                border.color:
                    root.accentColor()

                Label {
                    id: openLabel

                    anchors.centerIn:
                        parent

                    text: "Open"

                    color:
                        root.accentColor()

                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text:
                    root.latestValue()

                color:
                    root.accentColor()

                font.pixelSize: 26
                font.bold: true
            }

            Label {
                text:
                    root.seriesUnit()

                visible:
                    text.length > 0

                color:
                    root.textSecondary

                font.pixelSize: 12

                Layout.alignment:
                    Qt.AlignBottom
            }

            Item {
                Layout.fillWidth: true
            }

            Label {
                text:
                    root.sampleCountText()

                color:
                    root.textSecondary

                font.pixelSize: 10
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 150

            radius: 18

            color:
                root.surfaceColor

            border.width: 1
            border.color:
                root.borderColor

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
                        root.previewPoints()

                    const isScatter =
                        String(
                            root.plotData.plot_type || ""
                        ).toLowerCase() === "xy"

                    const leftMargin = 46
                    const rightMargin = 16
                    const topMargin = 14
                    const bottomMargin = 28

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
                            root.textSecondary

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

                    const xMin =
                        root.xMinimum()

                    const xMax =
                        root.xMaximum()

                    let yMin =
                        root.yMinimum()

                    let yMax =
                        root.yMaximum()

                    let xRange =
                        xMax - xMin

                    let yRange =
                        yMax - yMin

                    if (
                        !Number.isFinite(xRange)
                        || xRange <= 0
                    ) {
                        xRange = 1
                    }

                    if (
                        !Number.isFinite(yRange)
                        || yRange <= 0
                    ) {
                        const center =
                            Number.isFinite(yMin)
                                ? yMin
                                : 0

                        yMin = center - 1
                        yMax = center + 1
                        yRange = 2
                    }

                    const yPadding =
                        Math.max(
                            yRange * 0.14,
                            0.05
                        )

                    yMin -= yPadding
                    yMax += yPadding
                    yRange = yMax - yMin

                    /*
                        Very soft grid: four divisions in each
                        direction, matching the five preview points.
                    */
                    context.strokeStyle =
                        root.gridColor

                    context.globalAlpha = 0.55
                    context.lineWidth = 1

                    context.fillStyle =
                        root.textSecondary

                    context.font =
                        "10px sans-serif"

                    context.textBaseline =
                        "middle"

                    const horizontalDivisions = 4

                    for (
                        let index = 0;
                        index <= horizontalDivisions;
                        ++index
                    ) {
                        const ratio =
                            index
                            / horizontalDivisions

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

                        context.globalAlpha = 0.8
                        context.textAlign = "right"

                        context.fillText(
                            root.formatValue(
                                value
                            ),
                            leftMargin - 8,
                            y
                        )

                        context.globalAlpha = 0.55
                    }

                    const verticalDivisions = 4

                    context.textBaseline = "top"

                    for (
                        let index = 0;
                        index <= verticalDivisions;
                        ++index
                    ) {
                        const ratio =
                            index
                            / verticalDivisions

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

                        context.globalAlpha = 0.8

                        context.textAlign =
                                index === 0
                            ? "left"
                            : index
                                === verticalDivisions
                                ? "right"
                                : "center"

                        context.fillText(
                            root.formatElapsed(
                                elapsed
                            ),
                            x,
                            topMargin
                            + plotHeight
                            + 8
                        )

                        context.globalAlpha = 0.55
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
                                points[index]
                                    .value
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
                                (
                                    elapsed - xMin
                                )
                                / xRange
                            )
                            * plotWidth

                        const y =
                            topMargin
                            + (
                                1
                                - (
                                    (
                                        value - yMin
                                    )
                                    / yRange
                                )
                            )
                            * plotHeight

                        screenPoints.push({
                            "x": x,
                            "y": y
                        })
                    }

                    if (
                        screenPoints.length === 0
                    ) {
                        return
                    }

                    if (!isScatter) {
                        /*
                            Soft area underneath the line.
                        */
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
                            root.accentColor()

                        context.globalAlpha = 0.12
                        context.fill()
                        context.globalAlpha = 1

                        /*
                            Rounded connected line.
                        */
                        context.beginPath()

                        context.lineCap = "round"
                        context.lineJoin = "round"
                        context.lineWidth = 4

                        context.strokeStyle =
                            root.accentColor()

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

                    /*
                        Five visible circular measurement points.
                    */
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
                            isScatter ? 4.5 : 6,
                            0,
                            Math.PI * 2
                        )

                        context.fillStyle =
                            root.surfaceColor

                        context.fill()

                        context.lineWidth = 3

                        context.strokeStyle =
                            root.accentColor()

                        context.stroke()
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent

        cursorShape:
            Qt.PointingHandCursor

        onClicked: {
            root.clicked(
                root.plotData
            )
        }
    }
}