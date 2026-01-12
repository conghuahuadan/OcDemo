#import "WPScreenShotHelper.h"

@interface WPScreenShotHelper () <UIScreenshotServiceDelegate>
@property (nonatomic, weak) UIScrollView *scrollView;
@end

@implementation WPScreenShotHelper

+ (instancetype)sharedHelper {
    static WPScreenShotHelper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WPScreenShotHelper alloc] init];
    });
    return instance;
}

- (void)setupWithScrollView:(UIScrollView *)scrollView {
    self.scrollView = scrollView;
    if (@available(iOS 13.0, *)) {
        // Attempt to attach to the window scene's screenshot service
        // Note: scrollView.window might be nil if called too early (e.g. viewDidLoad).
        // It's recommended to call this in viewDidAppear or ensure window exists.
        UIWindowScene *scene = scrollView.window.windowScene;
        if (!scene) {
            scene = (UIWindowScene *)[UIApplication sharedApplication].connectedScenes.anyObject;
        }
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            scene.screenshotService.delegate = self;
        }
    }
}

- (NSData *)generatePDFData {
    if (!self.scrollView) {
        return nil;
    }
    
    // 1. Save current state
    CGRect originalFrame = self.scrollView.frame;
    CGPoint originalOffset = self.scrollView.contentOffset;
    UIEdgeInsets originalInset = self.scrollView.contentInset;
    
    // 2. Resize ScrollView to full content size
    CGRect tempFrame = originalFrame;
    tempFrame.size = self.scrollView.contentSize;
    
    // Avoid zero size issues
    if (tempFrame.size.width <= 0 || tempFrame.size.height <= 0) {
        return nil;
    }
    
    self.scrollView.frame = tempFrame;
    // self.scrollView.contentOffset = CGPointZero; // Optional: Reset offset to 0,0
    
    // 3. Render to PDF Context
    NSMutableData *pdfData = [NSMutableData data];
    UIGraphicsBeginPDFContextToData(pdfData, tempFrame, nil);
    UIGraphicsBeginPDFPage();
    CGContextRef pdfContext = UIGraphicsGetCurrentContext();
    
    // Render the layer
    [self.scrollView.layer renderInContext:pdfContext];
    
    UIGraphicsEndPDFContext();
    
    // 4. Restore state
    self.scrollView.frame = originalFrame;
    self.scrollView.contentOffset = originalOffset;
    self.scrollView.contentInset = originalInset;
    
    return pdfData;
}

- (void)captureScreenshotWithCompletion:(void(^)(NSData * _Nullable pdfData))completion {
    if (!completion) return;
    
    // Perform on main thread as UI changes are involved
    dispatch_async(dispatch_get_main_queue(), ^{
        NSData *data = [self generatePDFData];
        completion(data);
    });
}

#pragma mark - UIScreenshotServiceDelegate

- (void)screenshotService:(UIScreenshotService *)screenshotService generatePDFRepresentationWithCompletion:(void (^)(NSData * _Nullable, NSInteger, CGRect))completionHandler API_AVAILABLE(ios(13.0)) {
    
    NSData *data = [self generatePDFData];
    if (data) {
        completionHandler(data, 0, CGRectZero);
    } else {
        completionHandler(nil, 0, CGRectZero);
    }
}

@end