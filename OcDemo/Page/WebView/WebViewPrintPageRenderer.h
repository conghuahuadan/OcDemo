#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WebViewPrintPageRenderer : UIPrintPageRenderer

- (instancetype)initWithFormatter:(UIPrintFormatter *)formatter contentSize:(CGSize)contentSize;
- (UIImage * _Nullable)printContentToImage;

@end

NS_ASSUME_NONNULL_END
