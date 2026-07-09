#import <Foundation/Foundation.h>

// Keep identical to App/ACSettingsStore.h
#define AC_PREFS_APPID   CFSTR("com.dan9.anycar")
#define AC_PREFS_ENABLED CFSTR("enabledBundleIDs")
#define AC_NOTIFY_CHANGED "com.dan9.anycar/prefschanged"

@interface ACPrefs : NSObject
+ (instancetype)shared;
@property (nonatomic, readonly) NSArray<NSString *> *enabledBundleIDs;
- (void)reload;                 // re-read from disk
- (void)startObserving;         // live-reload on Darwin notification from the app
@end
