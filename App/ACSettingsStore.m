#import "ACSettingsStore.h"

@implementation ACSettingsStore

+ (NSMutableSet<NSString *> *)enabledBundleIDs {
    CFPreferencesAppSynchronize(AC_PREFS_APPID);
    CFPropertyListRef value = CFPreferencesCopyAppValue(AC_PREFS_ENABLED, AC_PREFS_APPID);
    NSMutableSet *set = [NSMutableSet set];
    if (value) {
        if (CFGetTypeID(value) == CFArrayGetTypeID()) {
            [set addObjectsFromArray:(__bridge NSArray *)value];
        }
        CFRelease(value);
    }
    return set;
}

+ (BOOL)isEnabled:(NSString *)bundleID {
    if (!bundleID) return NO;
    return [[self enabledBundleIDs] containsObject:bundleID];
}

+ (void)setEnabled:(BOOL)enabled forBundleID:(NSString *)bundleID {
    if (!bundleID) return;
    NSMutableSet *set = [self enabledBundleIDs];
    if (enabled) {
        [set addObject:bundleID];
    } else {
        [set removeObject:bundleID];
    }
    NSArray *array = set.allObjects;
    CFPreferencesSetAppValue(AC_PREFS_ENABLED, (__bridge CFArrayRef)array, AC_PREFS_APPID);
    CFPreferencesAppSynchronize(AC_PREFS_APPID);

    // Tell the tweak (inside SpringBoard) to reload live.
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         CFSTR(AC_NOTIFY_CHANGED), NULL, NULL, YES);
}

@end
