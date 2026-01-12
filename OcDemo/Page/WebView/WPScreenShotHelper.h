#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WPScreenShotHelper : NSObject

+ (instancetype)sharedHelper;
- (void)setupWithScrollView:(UIScrollView *)scrollView;

// Manually trigger a screenshot generation (returns PDF data)
- (void)captureScreenshotWithCompletion:(void (^)(NSData *_Nullable pdfData))completion;

@end

NS_ASSUME_NONNULL_END