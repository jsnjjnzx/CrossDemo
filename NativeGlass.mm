#include "NativeGlass.h"
#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

void *addNativeGlass(QWidget *widget, qreal radius)
{
    NSView *host = (__bridge NSView *)(void *)widget->winId();
    // Keep Qt's view in place; a sibling glass background cannot cover Qt's foreground.
    NSGlassEffectView *glass = [[NSGlassEffectView alloc] initWithFrame:host.frame];
    glass.cornerRadius = radius;
    glass.contentView = [[NSView alloc] initWithFrame:glass.bounds];
    [host.superview addSubview:glass positioned:NSWindowBelow relativeTo:host];
    host.wantsLayer = YES;
    host.layer.opaque = NO;
    return (__bridge void *)glass;
}

void removeNativeGlass(void *object)
{
    [(__bridge NSGlassEffectView *)object removeFromSuperview];
}

void syncNativeGlass(void *object, QWidget *widget, const QRectF &bounds)
{
    NSGlassEffectView *glass = (__bridge NSGlassEffectView *)object;
    NSView *host = (__bridge NSView *)(void *)widget->winId();
    NSRect local = NSMakeRect(bounds.x(), bounds.y(), bounds.width(), bounds.height());
    if (!host.flipped)
        local.origin.y = NSHeight(host.bounds) - bounds.y() - bounds.height();
    glass.frame = [host convertRect:local toView:host.superview];
    glass.contentView.frame = glass.bounds;
}

void setNativeGlassStyle(void *object, bool clear, bool dark, bool solid)
{
    NSGlassEffectView *glass = (__bridge NSGlassEffectView *)object;
    glass.style = clear ? NSGlassEffectViewStyleClear : NSGlassEffectViewStyleRegular;
    glass.appearance = [NSAppearance appearanceNamed:dark ? NSAppearanceNameDarkAqua : NSAppearanceNameAqua];
    glass.tintColor = solid ? (dark ? NSColor.windowBackgroundColor : NSColor.whiteColor) : nil;
    glass.hidden = solid;
}

bool nativeGlassIsValid(void *object, QWidget *widget)
{
    NSGlassEffectView *glass = (__bridge NSGlassEffectView *)object;
    NSView *host = (__bridge NSView *)(void *)widget->winId();
    return [glass isKindOfClass:NSGlassEffectView.class] && glass.superview == host.superview
        && glass.contentView != nil && !NSIsEmptyRect(glass.frame);
}

QImage applicationIcon(const QString &bundleId)
{
    NSString *identifier = [NSString stringWithUTF8String:bundleId.toUtf8().constData()];
    NSURL *url = [NSWorkspace.sharedWorkspace URLForApplicationWithBundleIdentifier:identifier];
    if (!url) return {};
    NSImage *icon = [NSWorkspace.sharedWorkspace iconForFile:url.path];
    NSBitmapImageRep *bitmap = [NSBitmapImageRep imageRepWithData:icon.TIFFRepresentation];
    NSData *data = [bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    return QImage::fromData(static_cast<const uchar *>(data.bytes), int(data.length));
}

bool systemReducesMotion()
{
    return NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceMotion;
}

bool systemNeedsSolidSurfaces()
{
    return NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceTransparency
        || NSWorkspace.sharedWorkspace.accessibilityDisplayShouldIncreaseContrast;
}

void configureNativeWindow(QWidget *widget)
{
    NSView *host = (__bridge NSView *)(void *)widget->winId();
    host.window.opaque = NO;
    host.window.backgroundColor = NSColor.clearColor;
    host.window.hasShadow = NO;
    host.window.movableByWindowBackground = NO;
}
