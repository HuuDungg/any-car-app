#import <UIKit/UIKit.h>

// ---- LSApplicationWorkspace / LSApplicationProxy (private) ----
// Used to enumerate installed apps and read their metadata.
@interface LSApplicationProxy : NSObject
@property (nonatomic, readonly) NSString *applicationIdentifier;   // bundle id
@property (nonatomic, readonly) NSString *localizedName;
@property (nonatomic, readonly) NSString *applicationType;         // "User" / "System" / "Internal"
@property (nonatomic, readonly) NSString *bundleVersion;
@property (nonatomic, readonly) NSString *shortVersionString;
@end

@interface LSApplicationWorkspace : NSObject
+ (instancetype)defaultWorkspace;
- (NSArray<LSApplicationProxy *> *)allApplications;
- (NSArray<LSApplicationProxy *> *)allInstalledApplications;
@end

// ---- Private icon accessor (UIKit) ----
// format: 0=small, 1=default, 2=home-screen sized. Falls back gracefully if unavailable.
@interface UIImage (AnyCarPrivate)
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleID
                                               format:(int)format
                                                scale:(CGFloat)scale;
@end
