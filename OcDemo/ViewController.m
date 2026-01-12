//
//  ViewController.m
//  OcDemo
//
//  Created by cwq on 2026/1/12.
//

#import "ViewController.h"

@interface ModuleItem : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) void (^action)(void);
@end

@implementation ModuleItem
@end

@interface ViewController ()
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray<ModuleItem *> *items;
@end

@implementation ViewController

- (ModuleItem *)itemWithTitle:(NSString *)title action:(void (^)(void))action {
    ModuleItem *item = [ModuleItem new];
    item.title = title;
    item.action = action;
    return item;
}

- (void)showToastWithMessage:(NSString *)message {
    UILabel *label = [[UILabel alloc] init];
    label.text = message;
    label.textColor = UIColor.whiteColor;
    label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:14];
    label.numberOfLines = 0;
    label.layer.cornerRadius = 8.0;
    label.layer.masksToBounds = YES;

    CGFloat horizontalPadding = 16.0;
    CGFloat verticalPadding = 10.0;
    CGSize maxSize = CGSizeMake(self.view.bounds.size.width - 40.0, CGFLOAT_MAX);
    CGSize textSize = [label sizeThatFits:maxSize];
    CGFloat width = textSize.width + horizontalPadding * 2;
    CGFloat height = textSize.height + verticalPadding * 2;

    label.frame = CGRectMake(0, 0, width, height);
    label.center = CGPointMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height - 120.0);
    label.alpha = 0.0;

    [self.view addSubview:label];

    [UIView animateWithDuration:0.25 animations:^{
        label.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25 delay:1.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            label.alpha = 0.0;
        } completion:^(BOOL finishedInner) {
            [label removeFromSuperview];
        }];
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    __weak typeof(self) weakSelf = self;
    self.items = @[
        [self itemWithTitle:@"WebView" action:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            NSLog(@"点击WebView");
        }],
        [self itemWithTitle:@"ListView" action:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            [strongSelf showToastWithMessage:@"点击ListView"];
        }],
    ];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = UIColor.clearColor;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:@"ButtonCell"];

    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.collectionView];

    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.collectionView.topAnchor constraintEqualToAnchor:guide.topAnchor constant:16],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:16],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-16],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor constant:-16]
    ]];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ButtonCell" forIndexPath:indexPath];
    for (UIView *v in cell.contentView.subviews) { [v removeFromSuperview]; }

    ModuleItem *item = self.items[indexPath.item];
    NSString *title = item.title;
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.backgroundColor = UIColor.systemBlueColor;
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.layer.cornerRadius = 8.0;
    button.contentEdgeInsets = UIEdgeInsetsMake(8, 12, 8, 12);
    button.frame = cell.contentView.bounds;
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    button.userInteractionEnabled = false;
    [cell.contentView addSubview:button];

    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    ModuleItem *item = self.items[indexPath.item];
    NSString *title = item.title;
    NSDictionary *attrs = @{NSFontAttributeName: [UIFont systemFontOfSize:17]};
    CGFloat textW = [title sizeWithAttributes:attrs].width;
    CGFloat w = textW + 12*2; // 左右内边距
    CGFloat h = 40.0;         // 高度固定

    CGFloat maxW = collectionView.bounds.size.width - 16*2; // 预留左右间距
    w = MIN(w, maxW);
    return CGSizeMake(w, h);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(8, 0, 8, 0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 8.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 8.0;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    ModuleItem *item = self.items[indexPath.item];
    if (item.action) {
        item.action();
    }
}


@end
