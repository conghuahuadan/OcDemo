#import "ToastUtil.h"

@implementation ToastUtil

+ (void)showToastWithMessage:(NSString *)message {
    if (message.length == 0) {
        return;
    }
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window) {
        window = [[UIApplication sharedApplication].windows firstObject];
    }
    if (!window) {
        return;
    }

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
    CGSize maxSize = CGSizeMake(window.bounds.size.width - 40.0, CGFLOAT_MAX);
    CGSize textSize = [label sizeThatFits:maxSize];
    CGFloat width = textSize.width + horizontalPadding * 2;
    CGFloat height = textSize.height + verticalPadding * 2;

    label.frame = CGRectMake(0, 0, width, height);
    label.center = CGPointMake(window.bounds.size.width / 2.0,
                               window.bounds.size.height - 120.0);
    label.alpha = 0.0;

    [window addSubview:label];

    [UIView animateWithDuration:0.25 animations:^{
        label.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25
                              delay:1.5
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            label.alpha = 0.0;
        } completion:^(BOOL finishedInner) {
            [label removeFromSuperview];
        }];
    }];
}

@end
