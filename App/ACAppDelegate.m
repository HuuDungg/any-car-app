#import "ACAppDelegate.h"
#import "ACAppListViewController.h"

@implementation ACAppDelegate

- (BOOL)application:(UIApplication *)application
        didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    ACAppListViewController *list = [ACAppListViewController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
