#import <Foundation/Foundation.h>

// These constants MUST stay identical to the copy the tweak uses (Tweak/ACPrefs.h).
// Stored under /var/mobile/Library/Preferences so both the app (mobile) and the
// tweak (running inside SpringBoard, also mobile) can read/write it.
#define AC_PREFS_APPID   CFSTR("com.dan9.anycar")
#define AC_PREFS_ENABLED CFSTR("enabledBundleIDs")
#define AC_NOTIFY_CHANGED "com.dan9.anycar/prefschanged"

@interface ACSettingsStore : NSObject

// Set of enabled bundle identifiers.
+ (NSMutableSet<NSString *> *)enabledBundleIDs;
+ (BOOL)isEnabled:(NSString *)bundleID;
+ (void)setEnabled:(BOOL)enabled forBundleID:(NSString *)bundleID;

@end
