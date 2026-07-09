#import "ACAppMirror.h"
#import "PrivateHeaders.h"
#import "ACTouchForwardingView.h"

static NSString *const kRequester = @"com.dan9.anycar";

@interface ACAppMirror ()
@property (nonatomic, copy, readwrite) NSString *bundleID;
@property (nonatomic, weak)   UIWindow *carWindow;
@property (nonatomic, strong) ACTouchForwardingView *hostView; // holds the remote layer
@property (nonatomic, strong) FBScene *scene;
@property (nonatomic, strong) NSTimer *keepAliveTimer;
@end

@implementation ACAppMirror

- (instancetype)initWithBundleID:(NSString *)bundleID carWindow:(UIWindow *)carWindow {
    if ((self = [super init])) {
        _bundleID = [bundleID copy];
        _carWindow = carWindow;
    }
    return self;
}

#pragma mark - Launch

- (void)launchIfNeeded {
    // Launch un-suspended so the app actually renders frames.
    SBSLaunchApplicationWithIdentifier((__bridge CFStringRef)self.bundleID, false);
}

- (FBScene *)findScene {
    FBSceneManager *mgr = [objc_getClass("FBSceneManager") sharedInstance];
    // VERSION: on iOS 14-16 the scene identifier is usually
    // "sceneID:<bundleID>-default"; on 17/18 it can be a UUID-based identity.
    // Fall back to scanning all scenes and matching the identity's bundle.
    for (FBScene *s in mgr.scenes) {
        @try {
            NSString *desc = [(id)s.identity description] ?: @"";
            if ([desc containsString:self.bundleID]) return s;
        } @catch (__unused NSException *e) {}
    }
    return nil;
}

#pragma mark - Start / Stop

- (void)start {
    [self launchIfNeeded];

    // The scene may take a beat to spin up after launch; poll briefly.
    [self attachWithRetries:20];
}

- (void)attachWithRetries:(int)retries {
    FBScene *scene = [self findScene];
    if (!scene && retries > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [self attachWithRetries:retries - 1];
        });
        return;
    }
    if (!scene) {
        NSLog(@"[AnyCar] could not find scene for %@", self.bundleID);
        return;
    }
    self.scene = scene;
    [self hostSceneLayer];
    [self resizeSceneToCarDisplay];
    [self keepForegrounded];
}

- (void)hostSceneLayer {
    FBSceneContextHostManager *host = self.scene.contextHostManager;
    if (!host) { NSLog(@"[AnyCar] no contextHostManager"); return; }

    [host enableHostingForRequester:kRequester priority:0];
    CALayer *remoteLayer = [host hostLayerForRequester:kRequester];
    if (!remoteLayer) { NSLog(@"[AnyCar] hostLayerForRequester returned nil"); return; }

    ACTouchForwardingView *view =
        [[ACTouchForwardingView alloc] initWithFrame:self.carWindow.bounds];
    view.scene = self.scene;
    view.bundleID = self.bundleID;
    remoteLayer.frame = view.bounds;
    [view.layer addSublayer:remoteLayer];

    [self.carWindow addSubview:view];
    self.hostView = view;
}

- (void)resizeSceneToCarDisplay {
    // VERSION: the settings class + geometry keys differ per OS.
    // The idea is to tell the app scene to lay out at the car display's size,
    // otherwise the hosted layer shows the phone-sized UI clipped/letterboxed.
    // Pseudocode against FBSceneSettings mutable settings:
    //
    //   id settings = [self.scene settings];              // FBSceneSettings
    //   id mutable  = [settings mutableCopy];             // FBMutableSceneSettings
    //   [mutable setFrame:self.carWindow.bounds];         // interfaceOrientation too
    //   [self.scene updateSettings:mutable withTransitionContext:nil completion:nil];
    //
    // TODO(device): wire the concrete FBMutableSceneSettings selectors for your OS.
    CGRect b = self.carWindow.bounds;
    self.hostView.frame = b;
    for (CALayer *l in self.hostView.layer.sublayers) l.frame = b;
}

- (void)keepForegrounded {
    // Backgrounded scenes stop rendering, so periodically reassert foreground.
    // VERSION: cleanest path is updating scene settings (foreground = YES,
    // deactivationReasons = 0). SBSLaunch again is a cheap, if blunt, fallback.
    [self.keepAliveTimer invalidate];
    self.keepAliveTimer =
        [NSTimer scheduledTimerWithTimeInterval:2.0 repeats:YES block:^(NSTimer *t) {
            if (!self.scene) { [t invalidate]; return; }
            // TODO(device): replace with a proper settings update instead of relaunch.
            SBSLaunchApplicationWithIdentifier((__bridge CFStringRef)self.bundleID, false);
        }];
}

- (void)stop {
    [self.keepAliveTimer invalidate];
    self.keepAliveTimer = nil;
    @try {
        [self.scene.contextHostManager disableHostingForRequester:kRequester];
    } @catch (__unused NSException *e) {}
    [self.hostView removeFromSuperview];
    self.hostView = nil;
    self.scene = nil;
}

@end
