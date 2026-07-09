#import "ACLauncherViewController.h"
#import "ACPrefs.h"
#import "ACAppMirror.h"
#import "PrivateHeaders.h"

@interface ACLauncherCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *label;
@end

@implementation ACLauncherCell
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _iconView = [UIImageView new];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.layer.cornerRadius = 14;
        _iconView.layer.cornerCurve = kCACornerCurveContinuous;
        _iconView.clipsToBounds = YES;
        _iconView.tintColor = [UIColor labelColor];
        _iconView.translatesAutoresizingMaskIntoConstraints = NO;

        _label = [UILabel new];
        _label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.textColor = [UIColor labelColor];
        _label.translatesAutoresizingMaskIntoConstraints = NO;

        [self.contentView addSubview:_iconView];
        [self.contentView addSubview:_label];
        [NSLayoutConstraint activateConstraints:@[
            [_iconView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
            [_iconView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
            [_iconView.widthAnchor constraintEqualToConstant:64],
            [_iconView.heightAnchor constraintEqualToConstant:64],
            [_label.topAnchor constraintEqualToAnchor:_iconView.bottomAnchor constant:6],
            [_label.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [_label.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        ]];
    }
    return self;
}
@end

@interface ACLauncherViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, weak)   UIWindow *carWindow;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray<NSString *> *bundleIDs;
@property (nonatomic, strong) ACAppMirror *activeMirror;
@property (nonatomic, strong) UIButton *homeButton;
@end

@implementation ACLauncherViewController

- (instancetype)initWithCarWindow:(UIWindow *)carWindow {
    if ((self = [super init])) { _carWindow = carWindow; }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.view.overrideUserInterfaceStyle = UIUserInterfaceStyleDark; // car screens read better dark

    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.itemSize = CGSizeMake(96, 108);
    layout.minimumInteritemSpacing = 24;
    layout.minimumLineSpacing = 24;
    layout.sectionInset = UIEdgeInsetsMake(28, 28, 28, 28);

    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds
                                            collectionViewLayout:layout];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[ACLauncherCell class] forCellWithReuseIdentifier:@"cell"];
    [self.view addSubview:self.collectionView];

    // A persistent "home" affordance to leave a mirrored app (SF Symbol glyph).
    self.homeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.homeButton setImage:[UIImage systemImageNamed:@"house.fill"] forState:UIControlStateNormal];
    self.homeButton.tintColor = [UIColor labelColor];
    self.homeButton.frame = CGRectMake(16, 16, 44, 44);
    self.homeButton.hidden = YES;
    [self.homeButton addTarget:self action:@selector(returnToLauncher) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.homeButton];

    [self reloadApps];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadApps)
                                                 name:@"ACPrefsReloaded" object:nil];
}

- (void)reloadApps {
    self.bundleIDs = [ACPrefs shared].enabledBundleIDs ?: @[];
    [self.collectionView reloadData];
}

- (UIImage *)iconFor:(NSString *)bundleID {
    if (![UIImage respondsToSelector:@selector(_applicationIconImageForBundleIdentifier:format:scale:)]) {
        return nil;
    }
    UIImage *(*fn)(id, SEL, NSString *, int, CGFloat) =
        (UIImage *(*)(id, SEL, NSString *, int, CGFloat))objc_msgSend;
    @try {
        return fn([UIImage class],
                  @selector(_applicationIconImageForBundleIdentifier:format:scale:),
                  bundleID, 2, [UIScreen mainScreen].scale);
    } @catch (__unused NSException *e) { return nil; }
}

#pragma mark - Collection view

- (NSInteger)collectionView:(UICollectionView *)cv numberOfItemsInSection:(NSInteger)s {
    return self.bundleIDs.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv
                  cellForItemAtIndexPath:(NSIndexPath *)ip {
    ACLauncherCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:ip];
    NSString *bundleID = self.bundleIDs[ip.item];
    UIImage *icon = [self iconFor:bundleID];
    if (icon) {
        cell.iconView.image = icon;
    } else {
        cell.iconView.image = [UIImage systemImageNamed:@"app.dashed"];
    }
    cell.label.text = bundleID.lastPathComponent;
    return cell;
}

- (void)collectionView:(UICollectionView *)cv didSelectItemAtIndexPath:(NSIndexPath *)ip {
    NSString *bundleID = self.bundleIDs[ip.item];
    [self.activeMirror stop];
    self.activeMirror = [[ACAppMirror alloc] initWithBundleID:bundleID carWindow:self.carWindow];
    [self.activeMirror start];
    self.collectionView.hidden = YES;
    self.homeButton.hidden = NO;
    [self.carWindow bringSubviewToFront:self.homeButton]; // keep home reachable
    [self.view bringSubviewToFront:self.homeButton];
}

- (void)returnToLauncher {
    [self.activeMirror stop];
    self.activeMirror = nil;
    self.collectionView.hidden = NO;
    self.homeButton.hidden = YES;
}

@end
