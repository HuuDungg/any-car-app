#import <UIKit/UIKit.h>

// Hosts a running app's rendered layer on the car display and keeps it alive.
@interface ACAppMirror : NSObject

@property (nonatomic, copy, readonly) NSString *bundleID;

// carWindow: a UIWindow already bound to the car display (see Tweak.xm).
- (instancetype)initWithBundleID:(NSString *)bundleID carWindow:(UIWindow *)carWindow;

// Launch (if needed), grab the scene's remote layer, add it to the car window,
// resize the scene to the car display and keep it foregrounded.
- (void)start;

// Remove the hosted layer and let the app return to normal lifecycle.
- (void)stop;

@end
