#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <objc/message.h>

// ====================================================================
//  NOTE ON VERSIONS
//  The exact class/selector names below are the ones used on iOS 14-17.
//  iOS 18 renamed / reshuffled a few scene-lifecycle selectors. Anything
//  version-sensitive is flagged with  // VERSION:  near its use in the .m
//  files. Verify against a headers dump for the OS you actually target.
// ====================================================================

#pragma mark - CoreAnimation layer remoting

// A live layer whose contents are rendered by another process. This is the
// primitive that lets us show an app's UI on the car display without redrawing.
@interface CALayerHost : CALayer
@property (assign) uint32_t contextId;
@end

@interface CAContext : NSObject
@property (readonly) uint32_t contextId;
@end

// Server-side display list. Used to locate the CarPlay display.
@interface CADisplay : NSObject
@property (readonly) NSString *name;
@property (readonly) NSString *uniqueId;
@property (readonly) CGRect bounds;
@end

@interface CAWindowServer : NSObject
+ (instancetype)serverIfRunning;
@property (readonly) NSArray<CADisplay *> *displays;
@end

#pragma mark - FrontBoard scene management (SpringBoard side)

@class FBScene, FBSceneContextHostManager, FBSSceneIdentity;

@interface FBSceneContextHostManager : NSObject
// Returns a CALayer already wired to the scene's remote context. Add it to
// your own view hierarchy on the car display to mirror the app.
- (CALayer *)hostLayerForRequester:(NSString *)requester;
- (void)enableHostingForRequester:(NSString *)requester priority:(NSInteger)priority;
- (void)disableHostingForRequester:(NSString *)requester;
@end

@interface FBScene : NSObject
@property (readonly) FBSceneContextHostManager *contextHostManager;
@property (readonly) FBSSceneIdentity *identity;
- (id)settings;
- (void)updateSettings:(id)settings
    withTransitionContext:(id)ctx
               completion:(void (^)(BOOL))completion;
@end

@interface FBSceneManager : NSObject
+ (instancetype)sharedInstance;
@property (readonly) NSArray<FBScene *> *scenes;
- (FBScene *)sceneWithIdentifier:(NSString *)identifier;
@end

#pragma mark - SpringBoard application / launch

@interface SBApplication : NSObject
@property (readonly) NSString *bundleIdentifier;
@end

@interface SBApplicationController : NSObject
+ (instancetype)sharedInstance;
- (SBApplication *)applicationWithBundleIdentifier:(NSString *)bundleIdentifier;
@end

// SpringBoardServices launch helper.
extern int SBSLaunchApplicationWithIdentifier(CFStringRef identifier, Boolean suspended);

#pragma mark - CarPlay

// CarPlay external scene notification names differ across versions; we mostly
// rely on UIScreen connect/disconnect plus CAWindowServer display scanning.
