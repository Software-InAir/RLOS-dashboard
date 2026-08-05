#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "ApiClient.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QGuiApplication::setOrganizationName(
        QStringLiteral("RLOS")
    );

    QGuiApplication::setApplicationName(
        QStringLiteral("RLOS Dashboard")
    );

    ApiClient apiClient;

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty(
        QStringLiteral("apiClient"),
        &apiClient
    );

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []()
        {
            QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection
    );

    engine.load(
    QUrl(
        QStringLiteral(
            "qrc:/RLOS/Dashboard/Main.qml"
        )
    )
    );

    return app.exec();
}