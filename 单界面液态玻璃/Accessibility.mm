#import <AppKit/AppKit.h>

bool reducesMotion() { return NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceMotion; }
bool needsSolidSurface()
{
    return NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceTransparency
        || NSWorkspace.sharedWorkspace.accessibilityDisplayShouldIncreaseContrast;
}
