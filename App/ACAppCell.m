#import "ACAppCell.h"

@interface ACAppCell ()
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *bundleLabel;
@property (nonatomic, strong) UISwitch *toggle;
@property (nonatomic, strong, readwrite) ACApp *app;
@end

@implementation ACAppCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (!self) return nil;

    self.selectionStyle = UITableViewCellSelectionStyleNone;

    _iconView = [UIImageView new];
    _iconView.contentMode = UIViewContentModeScaleAspectFit;
    _iconView.layer.cornerRadius = 9.0;
    _iconView.layer.cornerCurve = kCACornerCurveContinuous;
    _iconView.clipsToBounds = YES;
    _iconView.tintColor = [UIColor secondaryLabelColor];
    _iconView.translatesAutoresizingMaskIntoConstraints = NO;

    _nameLabel = [UILabel new];
    _nameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _nameLabel.adjustsFontForContentSizeCategory = YES;
    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;

    _bundleLabel = [UILabel new];
    _bundleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    _bundleLabel.adjustsFontForContentSizeCategory = YES;
    _bundleLabel.textColor = [UIColor secondaryLabelColor];
    _bundleLabel.translatesAutoresizingMaskIntoConstraints = NO;

    _toggle = [UISwitch new];
    _toggle.translatesAutoresizingMaskIntoConstraints = NO;
    [_toggle addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];

    [self.contentView addSubview:_iconView];
    [self.contentView addSubview:_nameLabel];
    [self.contentView addSubview:_bundleLabel];
    [self.contentView addSubview:_toggle];

    UILayoutGuide *m = self.contentView.layoutMarginsGuide;
    [NSLayoutConstraint activateConstraints:@[
        [_iconView.leadingAnchor constraintEqualToAnchor:m.leadingAnchor],
        [_iconView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [_iconView.widthAnchor constraintEqualToConstant:40.0],
        [_iconView.heightAnchor constraintEqualToConstant:40.0],

        [_nameLabel.leadingAnchor constraintEqualToAnchor:_iconView.trailingAnchor constant:12.0],
        [_nameLabel.topAnchor constraintEqualToAnchor:m.topAnchor constant:2.0],
        [_nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_toggle.leadingAnchor constant:-12.0],

        [_bundleLabel.leadingAnchor constraintEqualToAnchor:_nameLabel.leadingAnchor],
        [_bundleLabel.topAnchor constraintEqualToAnchor:_nameLabel.bottomAnchor constant:2.0],
        [_bundleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_toggle.leadingAnchor constant:-12.0],
        [_bundleLabel.bottomAnchor constraintEqualToAnchor:m.bottomAnchor constant:-2.0],

        [_toggle.trailingAnchor constraintEqualToAnchor:m.trailingAnchor],
        [_toggle.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    ]];

    return self;
}

- (void)configureWithApp:(ACApp *)app enabled:(BOOL)enabled {
    self.app = app;
    self.nameLabel.text = app.name;
    self.bundleLabel.text = app.bundleID;
    if (app.icon) {
        self.iconView.image = app.icon;
    } else {
        // No emoji anywhere: fall back to an SF Symbol glyph.
        self.iconView.image = [UIImage systemImageNamed:@"app.dashed"];
    }
    self.toggle.on = enabled;
}

- (void)switchChanged:(UISwitch *)sw {
    if ([self.delegate respondsToSelector:@selector(appCell:didToggle:)]) {
        [self.delegate appCell:self didToggle:sw.on];
    }
}

@end
