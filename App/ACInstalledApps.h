#import <UIKit/UIKit.h>

@interface ACApp : NSObject
@property (nonatomic, copy)   NSString *bundleID;
@property (nonatomic, copy)   NSString *name;
@property (nonatomic, strong) UIImage  *icon;   // may be nil; view supplies a placeholder
@end

@interface ACInstalledApps : NSObject
// User-installed apps, sorted by localized name (case/diacritic insensitive).
// Our own bundle id is excluded.
+ (NSArray<ACApp *> *)userApps;
@end
