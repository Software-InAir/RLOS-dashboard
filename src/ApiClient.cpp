#include "ApiClient.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QSharedPointer>
#include <QUrl>
#include <QUrlQuery>
#include <QVector>

ApiClient::ApiClient(QObject *parent)
    : QObject(parent)
{
}

QVariantList ApiClient::tests() const
{
    return m_tests;
}

QVariantList ApiClient::plotData() const
{
    return m_plotData;
}

QVariantMap ApiClient::selectedTest() const
{
    return m_selectedTest;
}

bool ApiClient::loading() const
{
    return m_loading;
}

bool ApiClient::actionLoading() const
{
    return m_actionLoading;
}

QString ApiClient::errorMessage() const
{
    return m_errorMessage;
}

QString ApiClient::actionMessage() const
{
    return m_actionMessage;
}

QString ApiClient::baseUrl() const
{
    return m_baseUrl;
}

void ApiClient::setBaseUrl(
    const QString &baseUrl
)
{
    QString cleanedUrl = baseUrl.trimmed();

    while (cleanedUrl.endsWith('/')) {
        cleanedUrl.chop(1);
    }

    if (
        cleanedUrl.isEmpty()
        || cleanedUrl == m_baseUrl
    ) {
        return;
    }

    m_baseUrl = cleanedUrl;
    emit baseUrlChanged();
}

void ApiClient::loadTests()
{
    if (m_loading) {
        return;
    }

    setLoading(true);
    setErrorMessage(QString());

    const QUrl url(
        m_baseUrl
        + QStringLiteral("/api/tests")
    );

    QNetworkRequest request(url);

    QNetworkReply *reply =
        m_networkManager.get(request);

    connect(
        reply,
        &QNetworkReply::finished,
        this,
        [this, reply]()
        {
            setLoading(false);

            const QByteArray responseData =
                reply->readAll();

            if (
                reply->error()
                != QNetworkReply::NoError
            ) {
                setErrorMessage(
                    QStringLiteral(
                        "Network error: %1"
                    ).arg(
                        reply->errorString()
                    )
                );

                reply->deleteLater();
                return;
            }

            QJsonParseError parseError;

            const QJsonDocument document =
                QJsonDocument::fromJson(
                    responseData,
                    &parseError
                );

            if (
                parseError.error
                != QJsonParseError::NoError
                || !document.isObject()
            ) {
                setErrorMessage(
                    QStringLiteral(
                        "The server returned "
                        "invalid JSON."
                    )
                );

                reply->deleteLater();
                return;
            }

            const QJsonObject root =
                document.object();

            if (!root.value("success").toBool()) {
                setErrorMessage(
                    root.value("message").toString(
                        QStringLiteral(
                            "The request failed."
                        )
                    )
                );

                reply->deleteLater();
                return;
            }

            const QJsonArray testsArray =
                root.value("tests").toArray();

            QVariantList loadedTests;

            loadedTests.reserve(
                testsArray.size()
            );

            for (
                const QJsonValue &value :
                testsArray
            ) {
                if (!value.isObject()) {
                    continue;
                }

                loadedTests.append(
                    value
                        .toObject()
                        .toVariantMap()
                );
            }

            m_tests = loadedTests;
            emit testsChanged();

            reply->deleteLater();
        }
    );
}

void ApiClient::loadPlotData(
    int testId,
    int limit
)
{
    if (testId <= 0) {
        return;
    }

    limit = qBound(10, limit, 5000);
    setErrorMessage(QString());

    const QVariantMap configuration =
        m_selectedTest.value(
            QStringLiteral("configuration")
        ).toMap();

    const QVariantList configuredPlots =
        configuration.value(
            QStringLiteral("analysis_plots")
        ).toList();

    const QVariantList measurementCatalog =
        configuration.value(
            QStringLiteral("measurement_catalog")
        ).toList();

    if (configuredPlots.isEmpty()) {
        m_plotData.clear();
        emit plotDataChanged();
        return;
    }

    auto catalogEntryForId =
        [&measurementCatalog](const QString &measurementId)
            -> QVariantMap
        {
            for (const QVariant &catalogValue : measurementCatalog) {
                const QVariantMap entry = catalogValue.toMap();

                if (
                    entry.value(
                        QStringLiteral("measurement_id")
                    ).toString()
                    == measurementId
                ) {
                    return entry;
                }
            }

            return {};
        };

    auto fallbackEntryForId =
        [](const QString &measurementId)
            -> QVariantMap
        {
            QVariantMap entry;

            const int separator =
                measurementId.lastIndexOf('.');

            if (
                separator <= 0
                || separator >= measurementId.size() - 1
            ) {
                return entry;
            }

            const QString source =
                measurementId.left(separator);

            const QString channel =
                measurementId.mid(separator + 1);

            entry.insert(
                QStringLiteral("measurement_id"),
                measurementId
            );
            entry.insert(
                QStringLiteral("source"),
                source
            );
            entry.insert(
                QStringLiteral("channel"),
                channel
            );
            entry.insert(
                QStringLiteral("label"),
                channel
            );

            return entry;
        };

    auto resolvedEntry =
        [&catalogEntryForId, &fallbackEntryForId](
            const QString &measurementId
        ) -> QVariantMap
        {
            QVariantMap entry =
                catalogEntryForId(measurementId);

            if (entry.isEmpty()) {
                entry =
                    fallbackEntryForId(measurementId);
            }

            return entry;
        };

    struct PlotLoadState
    {
        QVariantList plots;
        QVector<QVariantList> xHistories;
        QVector<QVariantList> yHistories;
        QVector<QString> plotTypes;
        int pendingRequests = 0;
    };

    struct HistoryRequest
    {
        int plotIndex = -1;
        bool isXAxis = false;
        QString source;
        QString channel;
    };

    const auto state =
        QSharedPointer<PlotLoadState>::create();

    QList<HistoryRequest> requests;

    for (const QVariant &plotValue : configuredPlots) {
        QVariantMap plot =
            plotValue.toMap();

        const QString plotType =
            plot.value(
                QStringLiteral("plot_type")
            ).toString().toLower();

        const int plotIndex =
            state->plots.size();

        state->plots.append(plot);
        state->xHistories.append(QVariantList());
        state->yHistories.append(QVariantList());
        state->plotTypes.append(plotType);

        QString xMeasurementId;
        QString yMeasurementId;

        if (plotType == QStringLiteral("xy")) {
            xMeasurementId =
                plot.value(
                    QStringLiteral("x_measurement_id")
                ).toString();

            yMeasurementId =
                plot.value(
                    QStringLiteral("y_measurement_id")
                ).toString();
        } else {
            yMeasurementId =
                plot.value(
                    QStringLiteral("measurement_id")
                ).toString();
        }

        const QVariantMap yEntry =
            resolvedEntry(yMeasurementId);

        QVariantMap seriesItem;

        seriesItem.insert(
            QStringLiteral("measurement_id"),
            yMeasurementId
        );
        seriesItem.insert(
            QStringLiteral("source"),
            yEntry.value(
                QStringLiteral("source")
            )
        );
        seriesItem.insert(
            QStringLiteral("channel"),
            yEntry.value(
                QStringLiteral("channel")
            )
        );
        seriesItem.insert(
            QStringLiteral("label"),
            yEntry.value(
                QStringLiteral("label")
            )
        );
        seriesItem.insert(
            QStringLiteral("unit"),
            yEntry.value(
                QStringLiteral("unit")
            )
        );
        seriesItem.insert(
            QStringLiteral("points"),
            QVariantList()
        );

        QVariantList series;
        series.append(seriesItem);

        plot.insert(
            QStringLiteral("series"),
            series
        );

        if (plotType == QStringLiteral("xy")) {
            const QVariantMap xEntry =
                resolvedEntry(xMeasurementId);

            plot.insert(
                QStringLiteral("x_source"),
                xEntry.value(
                    QStringLiteral("source")
                )
            );
            plot.insert(
                QStringLiteral("x_channel"),
                xEntry.value(
                    QStringLiteral("channel")
                )
            );
            plot.insert(
                QStringLiteral("x_label"),
                xEntry.value(
                    QStringLiteral("label")
                )
            );
            plot.insert(
                QStringLiteral("x_unit"),
                xEntry.value(
                    QStringLiteral("unit")
                )
            );

            if (
                !xEntry.value(
                    QStringLiteral("source")
                ).toString().isEmpty()
                && !xEntry.value(
                    QStringLiteral("channel")
                ).toString().isEmpty()
            ) {
                requests.append(
                    {
                        plotIndex,
                        true,
                        xEntry.value(
                            QStringLiteral("source")
                        ).toString(),
                        xEntry.value(
                            QStringLiteral("channel")
                        ).toString()
                    }
                );
            }
        }

        if (
            !yEntry.value(
                QStringLiteral("source")
            ).toString().isEmpty()
            && !yEntry.value(
                QStringLiteral("channel")
            ).toString().isEmpty()
        ) {
            requests.append(
                {
                    plotIndex,
                    false,
                    yEntry.value(
                        QStringLiteral("source")
                    ).toString(),
                    yEntry.value(
                        QStringLiteral("channel")
                    ).toString()
                }
            );
        }

        state->plots[plotIndex] = plot;
    }

    auto publishPlots =
        [this, state]()
        {
            for (
                int plotIndex = 0;
                plotIndex < state->plots.size();
                ++plotIndex
            ) {
                QVariantMap plot =
                    state->plots.at(plotIndex).toMap();

                QVariantList series =
                    plot.value(
                        QStringLiteral("series")
                    ).toList();

                if (series.isEmpty()) {
                    continue;
                }

                QVariantMap seriesItem =
                    series.first().toMap();

                QVariantList outputPoints;

                if (
                    state->plotTypes.at(plotIndex)
                    == QStringLiteral("xy")
                ) {
                    const QVariantList &xPoints =
                        state->xHistories.at(plotIndex);

                    const QVariantList &yPoints =
                        state->yHistories.at(plotIndex);

                    const int pointCount =
                        qMin(
                            xPoints.size(),
                            yPoints.size()
                        );

                    outputPoints.reserve(pointCount);

                    for (
                        int pointIndex = 0;
                        pointIndex < pointCount;
                        ++pointIndex
                    ) {
                        const QVariantMap xPoint =
                            xPoints.at(pointIndex).toMap();

                        const QVariantMap yPoint =
                            yPoints.at(pointIndex).toMap();

                        QVariantMap combinedPoint;

                        combinedPoint.insert(
                            QStringLiteral("elapsed_seconds"),
                            xPoint.value(
                                QStringLiteral("value")
                            )
                        );
                        combinedPoint.insert(
                            QStringLiteral("value"),
                            yPoint.value(
                                QStringLiteral("value")
                            )
                        );
                        combinedPoint.insert(
                            QStringLiteral("x_value"),
                            xPoint.value(
                                QStringLiteral("value")
                            )
                        );
                        combinedPoint.insert(
                            QStringLiteral("y_value"),
                            yPoint.value(
                                QStringLiteral("value")
                            )
                        );
                        combinedPoint.insert(
                            QStringLiteral("timestamp_utc"),
                            yPoint.value(
                                QStringLiteral("timestamp_utc")
                            )
                        );

                        outputPoints.append(combinedPoint);
                    }
                } else {
                    outputPoints =
                        state->yHistories.at(plotIndex);
                }

                seriesItem.insert(
                    QStringLiteral("points"),
                    outputPoints
                );

                series[0] = seriesItem;

                plot.insert(
                    QStringLiteral("series"),
                    series
                );

                state->plots[plotIndex] = plot;
            }

            m_plotData = state->plots;
            emit plotDataChanged();
        };

    if (requests.isEmpty()) {
        publishPlots();
        return;
    }

    state->pendingRequests = requests.size();

    for (const HistoryRequest &historyRequest : requests) {
        QUrl url(
            m_baseUrl
            + QStringLiteral(
                "/api/tests/%1/measurements"
            ).arg(testId)
        );

        QUrlQuery query;

        query.addQueryItem(
            QStringLiteral("source"),
            historyRequest.source
        );
        query.addQueryItem(
            QStringLiteral("channel"),
            historyRequest.channel
        );
        query.addQueryItem(
            QStringLiteral("limit"),
            QString::number(limit)
        );

        url.setQuery(query);

        QNetworkReply *reply =
            m_networkManager.get(
                QNetworkRequest(url)
            );

        connect(
            reply,
            &QNetworkReply::finished,
            this,
            [
                this,
                reply,
                state,
                historyRequest,
                publishPlots
            ]()
            {
                const QByteArray responseData =
                    reply->readAll();

                if (
                    reply->error()
                    == QNetworkReply::NoError
                ) {
                    QJsonParseError parseError;

                    const QJsonDocument document =
                        QJsonDocument::fromJson(
                            responseData,
                            &parseError
                        );

                    if (
                        parseError.error
                            == QJsonParseError::NoError
                        && document.isObject()
                    ) {
                        const QJsonObject root =
                            document.object();

                        if (
                            root.value(
                                QStringLiteral("success")
                            ).toBool()
                        ) {
                            const QJsonArray returnedPoints =
                                root.value(
                                    QStringLiteral("measurements")
                                ).toArray();

                            QVariantList chronologicalPoints;
                            chronologicalPoints.reserve(
                                returnedPoints.size()
                            );

                            for (
                                int index =
                                    returnedPoints.size() - 1;
                                index >= 0;
                                --index
                            ) {
                                const QJsonValue value =
                                    returnedPoints.at(index);

                                if (!value.isObject()) {
                                    continue;
                                }

                                chronologicalPoints.append(
                                    value
                                        .toObject()
                                        .toVariantMap()
                                );
                            }

                            if (historyRequest.isXAxis) {
                                state->xHistories[
                                    historyRequest.plotIndex
                                ] = chronologicalPoints;
                            } else {
                                state->yHistories[
                                    historyRequest.plotIndex
                                ] = chronologicalPoints;
                            }
                        }
                    }
                } else {
                    setErrorMessage(
                        QStringLiteral(
                            "Unable to load plot data: %1"
                        ).arg(
                            reply->errorString()
                        )
                    );
                }

                --state->pendingRequests;

                if (state->pendingRequests == 0) {
                    publishPlots();
                }

                reply->deleteLater();
            }
        );
    }
}


void ApiClient::loadTest(int testId)
{
    if (
        testId <= 0
        || m_loading
    ) {
        return;
    }

    setLoading(true);
    setErrorMessage(QString());
    setActionMessage(QString());

    const QUrl url(
        m_baseUrl
        + QStringLiteral(
            "/api/tests/%1"
        ).arg(testId)
    );

    QNetworkRequest request(url);

    QNetworkReply *reply =
        m_networkManager.get(request);

    connect(
        reply,
        &QNetworkReply::finished,
        this,
        [this, reply, testId]()
        {
            setLoading(false);

            const QByteArray responseData =
                reply->readAll();

            if (
                reply->error()
                != QNetworkReply::NoError
            ) {
                setErrorMessage(
                    QStringLiteral(
                        "Unable to load test %1: %2"
                    ).arg(
                        QString::number(testId),
                        reply->errorString()
                    )
                );

                reply->deleteLater();
                return;
            }

            QString parseError;

            const QVariantMap loadedTest =
                parseTestObject(
                    responseData,
                    parseError
                );

            if (!parseError.isEmpty()) {
                setErrorMessage(parseError);

                reply->deleteLater();
                return;
            }

            m_selectedTest = loadedTest;

            emit selectedTestChanged();
            emit testLoaded(testId);

            reply->deleteLater();
        }
    );
}

void ApiClient::startTest(int testId)
{
    performTestAction(
        testId,
        QStringLiteral("start")
    );
}

void ApiClient::pauseTest(int testId)
{
    performTestAction(
        testId,
        QStringLiteral("pause")
    );
}

void ApiClient::completeTest(int testId)
{
    performTestAction(
        testId,
        QStringLiteral("complete")
    );
}

void ApiClient::abortTest(int testId)
{
    performTestAction(
        testId,
        QStringLiteral("abort")
    );
}

void ApiClient::performTestAction(
    int testId,
    const QString &action
)
{
    if (
        testId <= 0
        || action.isEmpty()
        || m_actionLoading
    ) {
        return;
    }

    setActionLoading(true);
    setActionMessage(QString());
    setErrorMessage(QString());

    const QUrl url(
        m_baseUrl
        + QStringLiteral(
            "/api/tests/%1/%2"
        ).arg(
            QString::number(testId),
            action
        )
    );

    QNetworkRequest request(url);

    request.setHeader(
        QNetworkRequest::ContentTypeHeader,
        QStringLiteral("application/json")
    );

    QNetworkReply *reply =
        m_networkManager.post(
            request,
            QByteArray()
        );

    connect(
        reply,
        &QNetworkReply::finished,
        this,
        [this, reply, testId, action]()
        {
            setActionLoading(false);

            const QByteArray responseData =
                reply->readAll();

            QJsonParseError jsonError;

            const QJsonDocument document =
                QJsonDocument::fromJson(
                    responseData,
                    &jsonError
                );

            if (
                jsonError.error
                != QJsonParseError::NoError
                || !document.isObject()
            ) {
                setErrorMessage(
                    QStringLiteral(
                        "The server returned an "
                        "invalid response."
                    )
                );

                reply->deleteLater();
                return;
            }

            const QJsonObject root =
                document.object();

            if (
                reply->error()
                    != QNetworkReply::NoError
                || !root.value(
                    QStringLiteral("success")
                ).toBool()
            ) {
                setErrorMessage(
                    root.value(
                        QStringLiteral("message")
                    ).toString(
                        reply->errorString()
                    )
                );

                reply->deleteLater();
                return;
            }

            if (
                root.value(
                    QStringLiteral("test")
                ).isObject()
            ) {
                m_selectedTest =
                    root.value(
                        QStringLiteral("test")
                    )
                        .toObject()
                        .toVariantMap();

                emit selectedTestChanged();
            }

            setActionMessage(
                root.value(
                    QStringLiteral("message")
                ).toString(
                    QStringLiteral(
                        "Test updated."
                    )
                )
            );

            emit testActionCompleted(
                testId,
                action
            );

            loadTests();

            reply->deleteLater();
        }
    );
}

QVariantMap ApiClient::parseTestObject(
    const QByteArray &responseData,
    QString &errorMessage
) const
{
    QJsonParseError parseError;

    const QJsonDocument document =
        QJsonDocument::fromJson(
            responseData,
            &parseError
        );

    if (
        parseError.error
        != QJsonParseError::NoError
    ) {
        errorMessage =
            QStringLiteral(
                "Invalid JSON: %1"
            ).arg(
                parseError.errorString()
            );

        return {};
    }

    if (!document.isObject()) {
        errorMessage =
            QStringLiteral(
                "The server response was not "
                "a JSON object."
            );

        return {};
    }

    const QJsonObject root =
        document.object();

    if (
        !root.value(
            QStringLiteral("success")
        ).toBool()
    ) {
        errorMessage =
            root.value(
                QStringLiteral("message")
            ).toString(
                QStringLiteral(
                    "The request failed."
                )
            );

        return {};
    }

    if (
        !root.value(
            QStringLiteral("test")
        ).isObject()
    ) {
        errorMessage =
            QStringLiteral(
                "The response did not contain "
                "a lifecycle test."
            );

        return {};
    }

    QVariantMap test =
        root.value(
            QStringLiteral("test")
        )
            .toObject()
            .toVariantMap();

    const QJsonValue latestMeasurementsValue =
        root.value(
            QStringLiteral("latest_measurements")
        );

    if (
        latestMeasurementsValue.isObject()
        && !test.contains(
            QStringLiteral("latest_measurements")
        )
    ) {
        test.insert(
            QStringLiteral("latest_measurements"),
            latestMeasurementsValue
                .toObject()
                .toVariantMap()
        );
    }

    const QJsonValue samplesValue =
        root.value(
            QStringLiteral("samples")
        );

    if (
        samplesValue.isArray()
        && !test.contains(
            QStringLiteral("samples")
        )
    ) {
        test.insert(
            QStringLiteral("samples"),
            samplesValue
                .toArray()
                .toVariantList()
        );
    }

    const QJsonValue eventsValue =
        root.value(
            QStringLiteral("events")
        );

    if (
        eventsValue.isArray()
        && !test.contains(
            QStringLiteral("events")
        )
    ) {
        test.insert(
            QStringLiteral("events"),
            eventsValue
                .toArray()
                .toVariantList()
        );
    }

    const QJsonValue instrumentHealthValue =
        root.value(
            QStringLiteral("instrument_health")
        );

    if (
        instrumentHealthValue.isArray()
        && !test.contains(
            QStringLiteral("instrument_health")
        )
    ) {
        test.insert(
            QStringLiteral("instrument_health"),
            instrumentHealthValue
                .toArray()
                .toVariantList()
        );
    }

    return test;
}

void ApiClient::clearSelectedTest()
{
    if (m_selectedTest.isEmpty()) {
        return;
    }

    m_selectedTest.clear();
    emit selectedTestChanged();
}

void ApiClient::clearActionMessage()
{
    setActionMessage(QString());
}

void ApiClient::setLoading(bool loading)
{
    if (m_loading == loading) {
        return;
    }

    m_loading = loading;
    emit loadingChanged();
}

void ApiClient::setActionLoading(
    bool loading
)
{
    if (m_actionLoading == loading) {
        return;
    }

    m_actionLoading = loading;
    emit actionLoadingChanged();
}

void ApiClient::setErrorMessage(
    const QString &message
)
{
    if (m_errorMessage == message) {
        return;
    }

    m_errorMessage = message;
    emit errorMessageChanged();
}

void ApiClient::setActionMessage(
    const QString &message
)
{
    if (m_actionMessage == message) {
        return;
    }

    m_actionMessage = message;
    emit actionMessageChanged();
}