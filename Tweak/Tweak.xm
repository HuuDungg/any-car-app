#import "PrivateHeaders.h"
#import "ACPrefs.h"
#import "ACLauncherViewController.h"

// ===========================================================================
//  AnyCar tweak entry point.
//
//  Strategy:
//   1. Watch for a car display appearing.
//   2. Create/adopt a UIWindow bound to that display.
//   3. Put ACLauncherViewController in it. The launcher lists the user's
//      enabled apps and mirrors the chosen one via ACAppMirror.
//
//  Detecting the car display is the version-sensitive bit:
//   - iOS 14-16: a CarPlay UIScreen often appears -> UIScreenDidConnect.
//   - iOS 17-18: CarPlay is more scene-driven; the reliable signal is scanning
//     CAWindowServer.displays for the CarPlay display and binding a window to
//     it. Both paths are wired below; the CAWindowServer scan is the fallback.
// ===========================================================================

static UIWindow *gCarWindow = nil;
static ACLauncherViewController *gLauncher = nil;

static BOOL screenLooksLikeCarPlay(UIScreen *screen) {
    if (screen == [UIScreen mainScreen]) return NO;
    // Heuristic: CarPlay screens are external and non-mirrored.
    // VERSION: on some builds you can check screen._name / traitCollection.
    return YES;
}

static void attachLauncherToScreen(UIScreen *screen) {
    if (gCarWindow) return; // already attached
    if (!screenLooksLikeCarPlay(screen)) return;

    UIWindow *window = [[UIWindow alloc] initWithFrame:screen.bounds];
    window.screen = screen;                 // bind window to the car display
    window.windowLevel = UIWindowLevelNormal + 1;

    gLauncher = [[ACLauncherViewController alloc] initWithCarWindow:window];
    window.rootViewController = gLauncher;
    [window makeKeyAndVisible];
    window.hidden = NO;

    gCarWindow = window;
    NSLog(@"[AnyCar] launcher attached to car display %@", screen);
}

static void detachLauncher(void) {
    gCarWindow.hidden = YES;
    gCarWindow = nil;
    gLauncher = nil;
    NSLog(@"[AnyCar] car display disconnected");
}

#pragma mark - CAWindowServer fallback scan

static void scanForCarDisplay(void) {
    // Fallback when no CarPlay UIScreen is exposed. Walk the display server and
    // bind a UIScreen/window to the CarPlay display.
    CAWindowServer *server = [objc_getClass("CAWindowServer") serverIfRunning];
    for (CADisplay *d in server.displays) {
        NSString *name = d.name ?: @"";
        if ([name.lowercaseString containsString:@"carplay"]) {
            // TODO(device): create a UIScreen bound to this CADisplay
            // (via the private _UIScreenForCADisplay / screen-for-display path)
            // then call attachLauncherToScreen(that screen). Left as a hook
            // because the display->UIScreen bridge selector varies per OS.
            NSLog(@"[AnyCar] found car display via CAWindowServer: %@", name);
        }
    }
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    [[ACPrefs shared] startObserving];

    // Path A: react to CarPlay UIScreen connect/disconnect.
    [[NSNotificationCenter defaultCenter] addObserverForName:UIScreenDidConnectNotification
        object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            attachLauncherToScreen(note.object);
        }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIScreenDidDisconnectNotification
        object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            if (note.object == gCarWindow.screen) detachLauncher();
        }];

    // In case the car is already connected at launch.
    for (UIScreen *s in [UIScreen screens]) {
        if (s != [UIScreen mainScreen]) attachLauncherToScreen(s);
    }
    // Path B fallback.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ if (!gCarWindow) scanForCarDisplay(); });
}

%end

%ctor {
    NSLog(@"[AnyCar] tweak loaded into %@", [NSProcessInfo processInfo].processName);
}
