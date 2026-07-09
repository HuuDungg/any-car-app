#import <UIKit/UIKit.h>
#import "ACInstalledApps.h"

@class ACAppCell;

@protocol ACAppCellDelegate <NSObject>
- (void)appCell:(ACAppCell *)cell didToggle:(BOOL)on;
@end

@interface ACAppCell : UITableViewCell
@property (nonatomic, weak) id<ACAppCellDelegate> delegate;
@property (nonatomic, strong, readonly) ACApp *app;
- (void)configureWithApp:(ACApp *)app enabled:(BOOL)enabled;
@end
