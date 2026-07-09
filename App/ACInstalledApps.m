#import "ACInstalledApps.h"
#import "ACPrivateAPI.h"

@implementation ACApp
@end

@implementation ACInstalledApps

+ (UIImage *)iconForBundleID:(NSString *)bundleID {
    if (![UIImage respondsToSelector:@selector(_applicationIconImageForBundleIdentifier:format:scale:)]) {
        return nil;
    }
    @try {
        return [UIImage _applicationIconImageForBundleIdentifier:bundleID
                                                          format:2
                                                           scale:[UIScreen mainScreen].scale];
    } @catch (__unused NSException *e) {
        return nil;
    }
}

+ (NSArray<ACApp *> *)userApps {
    NSString *selfBundle = [NSBundle mainBundle].bundleIdentifier ?: @"com.dan9.anycar";
    LSApplicationWorkspace *ws = [LSApplicationWorkspace defaultWorkspace];

    NSArray<LSApplicationProxy *> *proxies = nil;
    if ([ws respondsToSelector:@selector(allApplications)]) {
        proxies = [ws allApplications];
    } else {
        proxies = [ws allInstalledApplications];
    }

    NSMutableArray<ACApp *> *result = [NSMutableArray array];
    for (LSApplicationProxy *proxy in proxies) {
        NSString *type = proxy.applicationType ?: @"";
        // Only show real user apps (skip System/Internal daemons and empty entries).
        if (![type isEqualToString:@"User"]) continue;

        NSString *bundleID = proxy.applicationIdentifier;
        if (bundleID.length == 0) continue;
        if ([bundleID isEqualToString:selfBundle]) continue;

        ACApp *app = [ACApp new];
        app.bundleID = bundleID;
        app.name = proxy.localizedName.length ? proxy.localizedName : bundleID;
        app.icon = [self iconForBundleID:bundleID];
        [result addObject:app];
    }

    [result sortUsingComparator:^NSComparisonResult(ACApp *a, ACApp *b) {
        return [a.name compare:b.name
                       options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];
    }];
    return result;
}

@end
