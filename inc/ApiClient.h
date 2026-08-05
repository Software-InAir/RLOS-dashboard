#ifndef APICLIENT_H
#define APICLIENT_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

class QNetworkReply;

class ApiClient : public QObject
{
    Q_OBJECT

    Q_PROPERTY(
        QVariantList tests
        READ tests
        NOTIFY testsChanged
    )

    Q_PROPERTY(
        QVariantList plotData
        READ plotData
        NOTIFY plotDataChanged
    )

    Q_PROPERTY(
        QVariantMap selectedTest
        READ selectedTest
        NOTIFY selectedTestChanged
    )

    Q_PROPERTY(
        bool loading
        READ loading
        NOTIFY loadingChanged
    )

    Q_PROPERTY(
        bool actionLoading
        READ actionLoading
        NOTIFY actionLoadingChanged
    )

    Q_PROPERTY(
        QString errorMessage
        READ errorMessage
        NOTIFY errorMessageChanged
    )

    Q_PROPERTY(
        QString actionMessage
        READ actionMessage
        NOTIFY actionMessageChanged
    )

    Q_PROPERTY(
        QString baseUrl
        READ baseUrl
        WRITE setBaseUrl
        NOTIFY baseUrlChanged
    )

public:
    explicit ApiClient(QObject *parent = nullptr);

    QVariantList tests() const;
    QVariantList plotData() const;
    QVariantMap selectedTest() const;

    bool loading() const;
    bool actionLoading() const;

    QString errorMessage() const;
    QString actionMessage() const;

    QString baseUrl() const;
    void setBaseUrl(const QString &baseUrl);

    Q_INVOKABLE void loadTests();
    Q_INVOKABLE void loadTest(int testId);
    Q_INVOKABLE void loadPlotData(
        int testId,
        int limit = 600
    );

    Q_INVOKABLE void startTest(int testId);
    Q_INVOKABLE void pauseTest(int testId);
    Q_INVOKABLE void completeTest(int testId);
    Q_INVOKABLE void abortTest(int testId);

    Q_INVOKABLE void clearSelectedTest();
    Q_INVOKABLE void clearActionMessage();

signals:
    void testsChanged();
    void plotDataChanged();
    void selectedTestChanged();

    void loadingChanged();
    void actionLoadingChanged();

    void errorMessageChanged();
    void actionMessageChanged();

    void baseUrlChanged();

    void testLoaded(int testId);

    void testActionCompleted(
        int testId,
        const QString &action
    );

private:
    void performTestAction(
        int testId,
        const QString &action
    );

    QVariantMap parseTestObject(
        const QByteArray &responseData,
        QString &errorMessage
    ) const;

    void setLoading(bool loading);
    void setActionLoading(bool loading);

    void setErrorMessage(
        const QString &message
    );

    void setActionMessage(
        const QString &message
    );

    QNetworkAccessManager m_networkManager;

    QVariantList m_tests;
    QVariantList m_plotData;
    QVariantMap m_selectedTest;

    bool m_loading = false;
    bool m_actionLoading = false;

    QString m_errorMessage;
    QString m_actionMessage;

    QString m_baseUrl =
        QStringLiteral(
            "http://100.103.122.51:8000"
        );
};

#endif/