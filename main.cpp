#include "NativeGlass.h"
#include <QAbstractButton>
#include <QApplication>
#include <QCommandLineParser>
#include <QKeyEvent>
#include <QMouseEvent>
#include <QPainter>
#include <QPainterPath>
#include <QScreen>
#include <QSet>
#include <QTimer>
#include <QVariantAnimation>
#include <QDebug>
#include <cmath>

struct AppTile {
    QString key, name, bundle, symbol;
    QColor color;
};

static const QList<AppTile> apps = {
    {"Q", "Finder", "com.apple.finder", "⌘", "#4999ed"},
    {"W", "Safari", "com.apple.Safari", "↗", "#1ba6e8"},
    {"E", "邮件", "com.apple.mail", "✉", "#268aef"},
    {"R", "备忘录", "com.apple.Notes", "≡", "#e7bd4a"},
    {"T", "提醒事项", "com.apple.reminders", "☷", "#ec805e"},
    {"Y", "照片", "com.apple.Photos", "✿", "#d888d5"},
    {"U", "音乐", "com.apple.Music", "♫", "#ef5475"},
    {"I", "App Store", "com.apple.AppStore", "A", "#319dec"},
    {"O", "系统设置", "com.apple.systempreferences", "⚙", "#8a94a0"},
    {"P", "终端", "com.apple.Terminal", ">_", "#39475d"},
    {"A", "信息", "com.apple.MobileSMS", "●", "#69c75b"},
    {"S", "日历", "com.apple.iCal", "17", "#ec6575"},
    {"D", "地图", "com.apple.Maps", "↗", "#79ba96"},
    {"F", "预览", "com.apple.Preview", "▧", "#49a9d3"},
    {"G", "计算器", "com.apple.calculator", "=", "#e8a456"},
    {"H", "家庭", "com.apple.Home", "⌂", "#efad4b"},
    {"J", "无边记", "com.apple.freeform", "∿", "#e9e5e0"},
    {"K", "Keynote", "com.apple.iWork.Keynote", "▣", "#5c98da"},
    {"L", "图书", "com.apple.iBooksX", "◫", "#ed9858"},
    {"Z", "快捷指令", "com.apple.shortcuts", "◇", "#9f69d7"},
    {"X", "TextEdit", "com.apple.TextEdit", "≡", "#c3d7e8"},
    {"C", "通讯录", "com.apple.AddressBook", "☷", "#c69c7d"},
    {"V", "FaceTime", "com.apple.FaceTime", "▰", "#68bf68"},
    {"B", "时钟", "com.apple.clock", "◷", "#34415b"},
    {"N", "天气", "com.apple.weather", "☀", "#58a2db"},
    {"M", "词典", "com.apple.Dictionary", "Aa", "#c66c68"}
};

class GlassKey final : public QAbstractButton {
public:
    QString legend, caption, symbol;
    QImage icon;
    QColor iconColor;
    bool clearGlass = true, dark = true, solid = false, compact = false;
    bool reduceMotion = false;
    qreal glow = 0;
    QPointF pointer;
    QRect home;
    QVariantAnimation feedback;
    void *glass = nullptr;

    explicit GlassKey(QWidget *parent) : QAbstractButton(parent)
    {
        setAttribute(Qt::WA_NativeWindow);
        setAttribute(Qt::WA_TranslucentBackground);
        setAttribute(Qt::WA_NoSystemBackground);
        setMouseTracking(true);
        setFocusPolicy(Qt::StrongFocus);
        setCursor(Qt::PointingHandCursor);
        feedback.setDuration(230);
        feedback.setEasingCurve(QEasingCurve::OutBack);
        connect(&feedback, &QVariantAnimation::valueChanged, this, [this](const QVariant &value) {
            glow = value.toReal();
            applyPose();
        });
        connect(this, &QAbstractButton::pressed, this, [this] { animate(-0.52); });
        connect(this, &QAbstractButton::released, this, [this] { animate(underMouse() ? 1 : 0); });
    }

    ~GlassKey() override { if (glass) removeNativeGlass(glass); }

    QRectF lens() const { return QRectF(0, 0, width(), compact ? height() : height() - 28); }

    void setHome(const QRect &frame)
    {
        home = frame;
        applyPose();
    }

    void applyPose()
    {
        const int lift = compact || reduceMotion ? 0 : qRound(glow * 5);
        const int spread = compact || reduceMotion ? 0 : qRound(glow * 1.6);
        setGeometry(home.adjusted(-spread, -lift - spread, spread, -lift + spread));
        if (glass) syncNativeGlass(glass, this, lens());
        update();
    }

    void updateMaterial()
    {
        if (glass) setNativeGlassStyle(glass, clearGlass, dark, solid);
        update();
    }

    void animate(qreal destination)
    {
        feedback.stop();
        if (reduceMotion) {
            glow = destination;
            applyPose();
        } else {
            feedback.setStartValue(glow);
            feedback.setEndValue(destination);
            feedback.start();
        }
    }

protected:
    void showEvent(QShowEvent *event) override
    {
        QAbstractButton::showEvent(event);
        if (!glass) glass = addNativeGlass(this, compact ? height() / 2.0 : 23);
        syncNativeGlass(glass, this, lens());
        updateMaterial();
    }

    void moveEvent(QMoveEvent *event) override
    {
        QAbstractButton::moveEvent(event);
        if (glass) syncNativeGlass(glass, this, lens());
    }

    void resizeEvent(QResizeEvent *event) override
    {
        QAbstractButton::resizeEvent(event);
        if (glass) syncNativeGlass(glass, this, lens());
    }

    void enterEvent(QEnterEvent *event) override
    {
        QAbstractButton::enterEvent(event);
        animate(1);
    }

    void leaveEvent(QEvent *event) override
    {
        QAbstractButton::leaveEvent(event);
        animate(0);
    }

    void mouseMoveEvent(QMouseEvent *event) override
    {
        pointer = event->position();
        update();
        QAbstractButton::mouseMoveEvent(event);
    }

    void focusInEvent(QFocusEvent *event) override { QAbstractButton::focusInEvent(event); update(); }
    void focusOutEvent(QFocusEvent *event) override { QAbstractButton::focusOutEvent(event); update(); }

    void paintEvent(QPaintEvent *) override
    {
        QPainter p(this);
        p.setRenderHint(QPainter::Antialiasing);
        p.setRenderHint(QPainter::SmoothPixmapTransform);
        const QRectF face = lens();
        const QColor text = dark ? QColor("#f7f8fc") : QColor("#202936");
        const qreal radius = compact ? height() / 2.0 : 23;
        if (solid) {
            p.setPen(QPen(dark ? QColor("#7e8795") : QColor("#8b939e"), 1));
            p.setBrush(dark ? QColor("#26303e") : QColor("#f1f4f8"));
            p.drawRoundedRect(face.adjusted(1, 1, -1, -1), radius, radius);
        }
        if (glow > 0 && !solid) {
            p.save();
            QPainterPath clip;
            clip.addRoundedRect(face, radius, radius);
            p.setClipPath(clip);
            QRadialGradient light(pointer, width() * 1.25);
            light.setColorAt(0, QColor(255, 255, 255, qRound(26 * qMin(glow, 1.0))));
            light.setColorAt(1, Qt::transparent);
            p.fillRect(face, light);
            p.restore();
        }
        if (hasFocus()) {
            p.setBrush(Qt::NoBrush);
            p.setPen(QPen(dark ? QColor("#bbdcff") : QColor("#2468be"), 2));
            p.drawRoundedRect(face.adjusted(2, 2, -2, -2), radius - 2, radius - 2);
        }
        if (compact) {
            p.setPen(text);
            p.setFont(QFont(".AppleSystemUIFont", width() > 100 ? 13 : 17));
            p.drawText(face, Qt::AlignCenter, symbol);
            return;
        }
        const qreal scale = face.height() / 82.0;
        if (!icon.isNull() || !symbol.isEmpty()) {
            const qreal size = 49 * scale;
            QRectF iconRect((width() - size) / 2, (face.height() - size) / 2 + 4 * scale, size, size);
            if (!icon.isNull()) {
                p.drawImage(iconRect, icon);
            } else {
                p.setPen(Qt::NoPen);
                p.setBrush(iconColor);
                p.drawRoundedRect(iconRect.adjusted(3, 3, -3, -3), 9, 9);
                p.setPen(Qt::white);
                p.setFont(QFont(".AppleSystemUIFont", qRound(23 * scale), QFont::DemiBold));
                p.drawText(iconRect, Qt::AlignCenter, symbol);
            }
            p.setFont(QFont(".AppleSystemUIFont", qRound(9 * scale), QFont::DemiBold));
            p.setPen(dark ? QColor(255, 255, 255, 195) : QColor(25, 35, 50, 195));
            p.drawText(face.adjusted(9, 5, -9, -5), Qt::AlignTop | Qt::AlignLeft, legend);
        } else {
            p.setPen(text);
            p.setFont(QFont(".AppleSystemUIFont", qRound(19 * scale), QFont::Medium));
            p.drawText(face, Qt::AlignCenter, legend);
        }
        if (!caption.isEmpty()) {
            QFont font(".AppleSystemUIFont", qRound(10 * scale), QFont::Medium);
            p.setFont(font);
            const QRectF label(0, face.bottom() + 8, width(), 18);
            p.setPen(dark ? QColor(0, 0, 0, 100) : QColor(255, 255, 255, 150));
            p.drawText(label.translated(0, 1), Qt::AlignCenter, fontMetrics().elidedText(caption, Qt::ElideRight, width()));
            p.setPen(text);
            p.drawText(label, Qt::AlignCenter, fontMetrics().elidedText(caption, Qt::ElideRight, width()));
        }
    }
};

class Keyboard final : public QWidget {
public:
    QList<GlassKey *> keys, controls;
    GlassKey *search = nullptr;
    QImage wallpaper{":/wallpaper.png"};
    QImage backdrop;
    bool desktop = false, dark = true, clearGlass = true;
    bool forceSolid = false, forceStill = false;
    QPoint dragStart;
    bool dragging = false;
    QTimer accessibility;

    Keyboard()
    {
        setWindowTitle("Qt · 液态玻璃键盘");
        setWindowFlags(Qt::Window | Qt::FramelessWindowHint);
        setAttribute(Qt::WA_TranslucentBackground);
        setMinimumSize(900, 650);
        setFocusPolicy(Qt::StrongFocus);
        const QStringList rows{"1234567890-=", "QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"};
        for (const QString &row : rows) {
            for (const QChar character : row) {
                auto *key = new GlassKey(this);
                key->legend = character;
                for (const auto &app : apps) {
                    if (app.key != key->legend) continue;
                    key->caption = app.name;
                    key->icon = applicationIcon(app.bundle);
                    key->symbol = app.symbol;
                    key->iconColor = app.color;
                }
                key->setAccessibleName(key->legend + (key->caption.isEmpty() ? " 空键位" : " " + key->caption));
                key->setToolTip(key->caption.isEmpty() ? key->legend : key->legend + " · " + key->caption);
                keys << key;
            }
        }
        auto tool = [this](const QString &symbol, const QString &name) {
            auto *button = new GlassKey(this);
            button->compact = true;
            button->symbol = symbol;
            button->setAccessibleName(name);
            button->setToolTip(name);
            controls << button;
            return button;
        };
        auto *background = tool("▧", "切换示例背景／真实桌面");
        connect(background, &QAbstractButton::clicked, this, [this] { desktop = !desktop; update(); });
        auto *style = tool("◒", "切换 Clear／Regular 玻璃");
        connect(style, &QAbstractButton::clicked, this, [this] { clearGlass = !clearGlass; updateMaterials(); });
        auto *theme = tool("☼", "切换明暗外观");
        connect(theme, &QAbstractButton::clicked, this, [this] { dark = !dark; updateMaterials(); });
        auto *close = tool("×", "关闭（Esc）");
        connect(close, &QAbstractButton::clicked, this, &QWidget::close);
        search = tool("⌕    搜索应用", "搜索外观展示，不执行搜索");
        search->setCursor(Qt::ArrowCursor);
        connect(&accessibility, &QTimer::timeout, this, [this] { updateMaterials(); });
        accessibility.start(1000);
        const QSize available = QGuiApplication::primaryScreen()->availableGeometry().size();
        resize(qMin(1280, available.width() - 100), qMin(840, available.height() - 100));
        move(QGuiApplication::primaryScreen()->availableGeometry().center() - rect().center());
        updateMaterials();
    }

    void updateMaterials()
    {
        const bool solid = forceSolid || systemNeedsSolidSurfaces();
        const bool still = forceStill || systemReducesMotion();
        bool changed = false;
        for (GlassKey *key : keys + controls) {
            if (key->clearGlass == clearGlass && key->dark == dark && key->solid == solid
                && key->reduceMotion == still) continue;
            key->clearGlass = clearGlass;
            key->dark = dark;
            key->solid = solid;
            key->reduceMotion = still;
            changed = true;
            if (still) { key->feedback.stop(); key->applyPose(); }
            key->updateMaterial();
        }
        if (changed) update();
    }

protected:
    void showEvent(QShowEvent *event) override
    {
        QWidget::showEvent(event);
        configureNativeWindow(this);
    }

    void resizeEvent(QResizeEvent *event) override
    {
        QWidget::resizeEvent(event);
        backdrop = wallpaper.scaled(size() * devicePixelRatioF(), Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);
        const qreal scale = qMin(width() / 1280.0, height() / 840.0);
        const qreal keyWidth = 74 * scale, keyHeight = 110 * scale;
        const qreal gap = 22 * scale, rowPitch = 126 * scale;
        int index = 0;
        for (int count : {12, 10, 9, 7}) {
            const qreal left = (width() - (count * keyWidth + (count - 1) * gap)) / 2;
            const int row = index == 0 ? 0 : index == 12 ? 1 : index == 22 ? 2 : 3;
            for (int col = 0; col < count; ++col) {
                keys[index++]->setHome(QRect(qRound(left + col * (keyWidth + gap)),
                    qRound(230 * scale + row * rowPitch), qRound(keyWidth), qRound(keyHeight)));
            }
        }
        for (int i = 0; i < 4; ++i)
            controls[i]->setHome(QRect(width() - qRound((238 - i * 52) * scale), qRound(42 * scale),
                qRound(40 * scale), qRound(40 * scale)));
        search->setHome(QRect(width() / 2 - qRound(160 * scale), qRound(127 * scale),
            qRound(320 * scale), qRound(46 * scale)));
    }

    void paintEvent(QPaintEvent *) override
    {
        QPainter p(this);
        p.setRenderHint(QPainter::Antialiasing);
        if (!desktop) {
            QPainterPath clip;
            clip.addRoundedRect(QRectF(rect()), 30, 30);
            p.setClipPath(clip);
            p.drawImage(QRectF(rect()), backdrop, QRectF((backdrop.width() - width() * devicePixelRatioF()) / 2,
                (backdrop.height() - height() * devicePixelRatioF()) / 2,
                width() * devicePixelRatioF(), height() * devicePixelRatioF()));
            p.fillRect(rect(), dark ? QColor(12, 22, 45, 40) : QColor(235, 245, 255, 65));
        }
        const qreal scale = qMin(width() / 1280.0, height() / 840.0);
        p.setPen(dark ? QColor("#f4f7ff") : QColor("#1e2d44"));
        p.setFont(QFont(".AppleSystemUIFont", qRound(20 * scale), QFont::DemiBold));
        p.drawText(QRectF(54 * scale, 42 * scale, 300 * scale, 40 * scale), Qt::AlignVCenter, "键盘启动台");
        p.setFont(QFont(".AppleSystemUIFont", qRound(10 * scale), QFont::Medium));
        p.setPen(dark ? QColor(235, 244, 255, 165) : QColor(30, 45, 65, 180));
        const QString mode = QString("Qt 6  ·  %1  ·  %2").arg(clearGlass ? "Clear" : "Regular",
            desktop ? "桌面" : "示例背景");
        p.drawText(QRectF(0, height() - 65 * scale, width(), 24 * scale), Qt::AlignCenter, mode);
    }

    void mousePressEvent(QMouseEvent *event) override
    {
        if (event->button() == Qt::LeftButton) {
            dragging = true;
            dragStart = event->globalPosition().toPoint() - frameGeometry().topLeft();
        }
    }
    void mouseMoveEvent(QMouseEvent *event) override
    {
        if (dragging) move(event->globalPosition().toPoint() - dragStart);
    }
    void mouseReleaseEvent(QMouseEvent *) override { dragging = false; }
    void keyPressEvent(QKeyEvent *event) override
    {
        if (event->key() == Qt::Key_Escape) { close(); return; }
        if (!event->isAutoRepeat()) {
            for (GlassKey *key : keys) {
                if (key->legend == event->text().toUpper()) {
                    key->animate(-0.52);
                    QTimer::singleShot(130, key, [key] { key->animate(0); });
                    return;
                }
            }
        }
        QWidget::keyPressEvent(event);
    }
};

static int selfTest(Keyboard &window)
{
    int checks = 0;
    auto check = [&checks](bool value, const char *message) {
        if (!value) qCritical() << "FAIL:" << message;
        else ++checks;
        return value;
    };
    bool ok = check(window.keys.size() == 38, "38 key layout");
    ok &= check(!window.wallpaper.isNull(), "background resource");
    QSet<QString> names;
    int icons = 0;
    for (GlassKey *key : window.keys) {
        names.insert(key->legend);
        if (!key->icon.isNull()) ++icons;
        ok &= check(nativeGlassIsValid(key->glass, key), "native glass sibling and content view");
        ok &= check(window.rect().contains(key->geometry()), "key within window");
        ok &= check(!key->accessibleName().isEmpty(), "accessible key name");
        for (GlassKey *other : window.keys)
            if (other != key) ok &= check(!key->home.intersects(other->home), "keys do not overlap");
    }
    ok &= check(names.size() == 38, "unique keys");
    ok &= check(icons > 10, "system application icon loading");
    for (GlassKey *control : window.controls)
        ok &= check(nativeGlassIsValid(control->glass, control), "native control lens");
    GlassKey *key = window.keys[12];
    const QImage foreground = key->grab().toImage();
    ok &= check(foreground.hasAlphaChannel() && qAlpha(foreground.pixel(foreground.width() / 2, 3)) < 40,
        "Qt foreground leaves the native lens visible");
    key->feedback.stop();
    key->glow = 1;
    key->applyPose();
    ok &= check(key->geometry().center().y() < key->home.center().y() || key->reduceMotion, "hover lift");
    window.forceSolid = true;
    window.forceStill = true;
    window.updateMaterials();
    ok &= check(key->solid && key->reduceMotion && key->geometry() == key->home, "accessibility fallback");
    window.forceSolid = false;
    window.forceStill = false;
    window.clearGlass = false;
    window.dark = false;
    window.updateMaterials();
    ok &= check(!key->dark && !key->clearGlass, "material and appearance propagation");
    window.resize(900, 650);
    for (GlassKey *tile : window.keys)
        ok &= check(window.rect().contains(tile->geometry()), "small window containment");
    window.desktop = true;
    window.update();
    qInfo() << (ok ? "PASS" : "FAIL") << checks << "checks;" << icons << "local application icons; native visual acceptance remains manual";
    return ok ? 0 : 1;
}

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    QApplication::setApplicationName("Qt Glass Keyboard");
    QApplication::setOrganizationName("FaunaBox Demo");
    QApplication::setQuitOnLastWindowClosed(true);
    QCommandLineParser parser;
    parser.addHelpOption();
    parser.addOption({"self-test", "Check the isolated Qt/native view integration and exit."});
    parser.process(app);
    Keyboard window;
    window.show();
    if (parser.isSet("self-test"))
        QTimer::singleShot(650, &window, [&] { app.exit(selfTest(window)); });
    return app.exec();
}
