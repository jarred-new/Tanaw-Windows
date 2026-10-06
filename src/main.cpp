#include "tanawcontroller.h"

#include <QGuiApplication>
#include <QQuickWindow> // Required for setting the graphics API
#include <QQmlContext>
#include <QQmlApplicationEngine>
#include <QIcon>

int main(int argc, char *argv[])
{
    // Force the RHI backend to Direct3D 11 for optimal DXVK translation in Winlator.
    // This MUST be called before QGuiApplication is initialized.
    QQuickWindow::setGraphicsApi(QSGRendererInterface::Direct3D11);

    // If users report issues with D3D11, you can swap the line above with:
    // QQuickWindow::setGraphicsApi(QSGRendererInterface::Vulkan);

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
