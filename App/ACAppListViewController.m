#import "ACAppListViewController.h"
#import "ACAppCell.h"
#import "ACInstalledApps.h"
#import "ACSettingsStore.h"

static NSString *const kCellID = @"ACAppCell";

@interface ACAppListViewController () <UISearchResultsUpdating, ACAppCellDelegate>
@property (nonatomic, strong) NSArray<ACApp *> *allApps;
@property (nonatomic, strong) NSArray<ACApp *> *shownApps;
@property (nonatomic, strong) NSMutableSet<NSString *> *enabled;
@property (nonatomic, strong) UISearchController *search;
@property (nonatomic, assign) NSInteger filterMode; // 0 = all, 1 = enabled only
@end

@implementation ACAppListViewController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"AnyCar";
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 64.0;
    [self.tableView registerClass:[ACAppCell class] forCellReuseIdentifier:kCellID];

    // Refresh button (SF Symbol, no emoji).
    UIBarButtonItem *refresh =
        [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrow.clockwise"]
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(reload)];
    self.navigationItem.rightBarButtonItem = refresh;

    // All / Enabled filter.
    UISegmentedControl *seg = [[UISegmentedControl alloc]
        initWithItems:@[@"All apps", @"Enabled"]];
    seg.selectedSegmentIndex = 0;
    [seg addTarget:self action:@selector(filterChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = seg;

    // Search.
    self.search = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.search.searchResultsUpdater = self;
    self.search.obscuresBackgroundDuringPresentation = NO;
    self.search.searchBar.placeholder = @"Search apps";
    self.navigationItem.searchController = self.search;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;

    [self reload];
}

- (void)reload {
    self.enabled = [ACSettingsStore enabledBundleIDs];
    self.allApps = [ACInstalledApps userApps];
    [self applyFilter];
}

- (void)filterChanged:(UISegmentedControl *)seg {
    self.filterMode = seg.selectedSegmentIndex;
    [self applyFilter];
}

- (void)applyFilter {
    NSString *q = self.search.searchBar.text ?: @"";
    NSMutableArray<ACApp *> *out = [NSMutableArray array];
    for (ACApp *app in self.allApps) {
        if (self.filterMode == 1 && ![self.enabled containsObject:app.bundleID]) continue;
        if (q.length) {
            BOOL nameHit = [app.name rangeOfString:q
                                           options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch].location != NSNotFound;
            BOOL idHit = [app.bundleID rangeOfString:q options:NSCaseInsensitiveSearch].location != NSNotFound;
            if (!nameHit && !idHit) continue;
        }
        [out addObject:app];
    }
    self.shownApps = out;
    [self.tableView reloadData];
}

#pragma mark - Search

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [self applyFilter];
}

#pragma mark - Table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.shownApps.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [NSString stringWithFormat:@"%lu enabled of %lu apps",
            (unsigned long)self.enabled.count, (unsigned long)self.allApps.count];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"Enabled apps appear in the AnyCar launcher on the car screen. "
           @"Use while parked or as a passenger.";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ACAppCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID forIndexPath:indexPath];
    ACApp *app = self.shownApps[indexPath.row];
    cell.delegate = self;
    [cell configureWithApp:app enabled:[self.enabled containsObject:app.bundleID]];
    return cell;
}

#pragma mark - Toggle

- (void)appCell:(ACAppCell *)cell didToggle:(BOOL)on {
    NSString *bundleID = cell.app.bundleID;
    if (!bundleID) return;
    [ACSettingsStore setEnabled:on forBundleID:bundleID];
    if (on) [self.enabled addObject:bundleID];
    else    [self.enabled removeObject:bundleID];

    // Refresh header count without a full reload.
    [self.tableView performBatchUpdates:^{
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                      withRowAnimation:UITableViewRowAnimationNone];
    } completion:nil];
}

@end
