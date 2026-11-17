#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QQuickItem>
#include <QSGRendererInterface>
#include <QCommandLineParser>
#include <QDir>
#include <QImage>
#include <QTimer>
#include <QDebug>
#include <cmath>

bool reducesMotion();
bool needsSolidSurface();

static double difference(const QImage &a, const QImage &b, const QRect &region)
{
    if (a.size() != b.size() || a.isNull()) return -1;
    const QRect area = region.intersected(a.rect());
    if (area.isEmpty()) return -1;
    double sum = 0;
    for (int y = area.top(); y <= area.bottom(); ++y) {
        for (int x = area.left(); x <= area.right(); ++x) {
            const QRgb p = a.pixel(x, y), q = b.pixel(x, y);
            sum += std::abs(qRed(p) - qRed(q)) + std::abs(qGreen(p) - qGreen(q))
                + std::abs(qBlue(p) - qBlue(q));
        }
    }
    return sum / (area.width() * area.height() * 3.0);
}

class PixelCheck final : public QObject {
    QQuickWindow *window;
    QString output;
    QImage baseline, refracted, moving, frosted, opaque;
    int step = 0, checks = 0;
    bool passed = true;

    void check(bool success, const char *name)
    {
        ++checks;
        if (!success) { passed = false; qCritical() << "FAIL:" << name; }
    }

    QRect pixels(const QRectF &region, const QImage &image) const
    {
        const qreal scale = image.width() / qreal(window->width());
        return QRectF(region.x() * scale, region.y() * scale,
            region.width() * scale, region.height() * scale).toAlignedRect();
    }

    QImage grab(const QString &name)
    {
        QImage image = window->grabWindow().convertToFormat(QImage::Format_RGB32);
        check(!image.isNull(), "GPU readback of own Qt window");
        if (!output.isEmpty()) check(image.save(output + "/" + name + ".png"), "save GPU evidence");
        return image;
    }

    void next()
    {
        const QRectF panel = window->property("panelRect").toRectF();
        switch (step++) {
        case 0:
            check(!window->property("shaderFailed").toBool(), "shader compilation status");
            check(window->rendererInterface()->graphicsApi() != QSGRendererInterface::Software,
                  "RHI shader renderer (including Direct3D WARP)");
            qInfo() << "Graphics API:" << window->rendererInterface()->graphicsApi();
            baseline = grab("01-no-refraction");
            window->setProperty("strength", 1.0);
            break;
        case 1: {
            refracted = grab("02-refraction");
            QRectF edge(panel.left() + 4, panel.top() + 65, 22, panel.height() - 130);
            const double bend = difference(baseline, refracted, pixels(edge, refracted));
            const double exterior = difference(baseline, refracted, pixels(QRectF(12, 12, 130, 90), refracted));
            qInfo() << "edge refraction delta:" << bend << "; exterior delta:" << exterior;
            check(bend > 3, "refraction visibly changes background samples along bevel");
            check(exterior >= 0 && exterior < 0.2, "refraction does not change pixels outside the panel");
            window->setProperty("phase", 1.8);
            break;
        }
        case 2: {
            moving = grab("03-background-moved");
            const double motion = difference(refracted, moving, pixels(panel.adjusted(70, 70, -70, -70), moving));
            qInfo() << "moving background through glass delta:" << motion;
            check(motion > 5, "moving background updates through the glass texture");
            window->setProperty("frost", 0.9);
            break;
        }
        case 3: {
            frosted = grab("04-frosted");
            const double blur = difference(moving, frosted, pixels(panel.adjusted(30, 30, -30, -30), frosted));
            qInfo() << "frost delta:" << blur;
            check(blur > 0.5, "material blur changes the sampled background");
            window->setProperty("forceSolid", true);
            break;
        }
        case 4:
            opaque = grab("05-accessibility-solid");
            window->setProperty("phase", 3.6);
            break;
        case 5: {
            const QImage solidMoved = grab("06-solid-background-moved");
            check(difference(opaque, solidMoved, pixels(panel.adjusted(10, 10, -10, -10), opaque)) < 0.2,
                  "solid accessibility surface hides moving background");
            check(difference(opaque, solidMoved, pixels(QRectF(12, 12, 130, 90), opaque)) > 5,
                  "background still moves outside the solid fallback");
            window->setProperty("forceSolid", false);
            window->setProperty("frost", 0.12);
            window->setProperty("scene", 0);
            window->setProperty("showContent", true);
            auto *card = window->findChild<QQuickItem *>("glassPanel");
            check(card != nullptr, "draggable foreground exists");
            if (card) card->setPosition(card->position() + QPointF(34, -20));
            check(window->property("panelRect").toRectF().x() == panel.x() + 34,
                  "foreground movement updates optical geometry");
            break;
        }
        default:
            grab("07-interface");
            qInfo() << (passed ? "PASS" : "FAIL") << checks << "GPU checks; actual visual acceptance remains manual";
            QGuiApplication::exit(passed ? 0 : 1);
            return;
        }
        window->update();
        QTimer::singleShot(220, this, [this] { next(); });
    }

public:
    PixelCheck(QQuickWindow *target, const QString &directory) : QObject(target), window(target), output(directory)
    {
        if (!output.isEmpty()) check(QDir().mkpath(output), "create evidence folder");
        window->setProperty("testMode", true);
        window->setProperty("showContent", false);
        window->setProperty("phase", 0.0);
        window->setProperty("scene", 1);
        window->setProperty("strength", 0.0);
        QTimer::singleShot(650, this, [this] { next(); });
    }
};

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("Qt Liquid Surface");
    app.setOrganizationName("FaunaBox Demo");
    QCommandLineParser parser;
    parser.addHelpOption();
    parser.addOption({"self-test", "Run GPU pixel comparisons on this window and exit."});
    parser.addOption({"render-dir", "Save only this Demo's GPU render evidence.", "directory"});
    parser.process(app);
    QQmlApplicationEngine engine;
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    engine.load(QUrl("qrc:/Main.qml"));
    if (engine.rootObjects().isEmpty()) return 1;
    auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
    if (!window) return 1;
    auto refreshAccessibility = [window] {
        window->setProperty("accessibilitySolid", needsSolidSurface());
        window->setProperty("accessibilityReduceMotion", reducesMotion());
    };
    refreshAccessibility();
    QTimer accessibility;
    QObject::connect(&accessibility, &QTimer::timeout, &app, refreshAccessibility);
    accessibility.start(1000);
    if (parser.isSet("self-test")) new PixelCheck(window, parser.value("render-dir"));
    return app.exec();
}
