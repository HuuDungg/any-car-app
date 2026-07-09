#import "ACPrefs.h"

static void prefsChangedCallback(CFNotificationCenterRef center, void *observer,
                                 CFStringRef name, const void *object,
                                 CFDictionaryRef userInfo) {
    [[ACPrefs shared] reload];
    // Broadcast internally so the launcher grid can refresh its icons.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ACPrefsReloaded" object:nil];
}

@interface ACPrefs ()
@property (nonatomic, strong) NSArray<NSString *> *enabledBundleIDs;
@end

@implementation ACPrefs

+ (instancetype)shared {
    static ACPrefs *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [ACPrefs new]; [s reload]; });
    return s;
}

- (void)reload {
    CFPreferencesAppSynchronize(AC_PREFS_APPID);
    CFPropertyListRef v = CFPreferencesCopyAppValue(AC_PREFS_ENABLED, AC_PREFS_APPID);
    NSArray *arr = @[];
    if (v) {
        if (CFGetTypeID(v) == CFArrayGetTypeID()) arr = (__bridge NSArray *)v;
        CFRelease(v);
    }
    self.enabledBundleIDs = [arr copy];
}

- (void)startObserving {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)self,
                                    prefsChangedCallback,
                                    CFSTR(AC_NOTIFY_CHANGED),
                                    NULL,
                                    CFNotificationSuspensionBehaviorCoalesce);
}

@end
