#import <UIKit/UIKit.h>
@class FBScene;

// Captures touches on the car display and forwards them to the mirrored app.
@interface ACTouchForwardingView : UIView
@property (nonatomic, weak)   FBScene *scene;
@property (nonatomic, copy)   NSString *bundleID;
@end
