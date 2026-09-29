#include "tanawcontroller.h"

#include <QGuiApplication>
#include <QQmlContext>
#include <QQmlApplicationEngine>
#include <QIcon>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName(QStringLiteral("Tanaw"));
    app.setApplicationName(QStringLiteral("Tanaw"));
    app.setApplicationDisplayName(QStringLiteral("Tanaw"));
    app.setWindowIcon(QIcon(QStringLiteral(":/qt/qml/Tanaw/qml/favicon.ico")));

    TanawController controller;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("tanawController"), &controller);
    const QUrl mainQml(QStringLiteral("qrc:/qt/qml/Tanaw/qml/main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(mainQml);

    return app.exec();
}