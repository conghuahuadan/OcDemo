#import "WebViewController.h"
#import <WebKit/WebKit.h>
#import "ToastUtil.h"

@interface UIScrollView (Screenshot)
- (void)takeScreenshotOfFullContent:(void (^)(UIImage * _Nullable image))completion;
@end

@implementation UIScrollView (Screenshot)

- (void)takeScreenshotOfFullContent:(void (^)(UIImage * _Nullable image))completion {
    // 分页绘制内容到ImageContext
    CGPoint originalOffset = self.contentOffset;
    
    // 当contentSize.height<bounds.height时，保证至少有1页的内容绘制
    NSInteger pageNum = 1;
    if (self.contentSize.height > self.bounds.size.height) {
        pageNum = (NSInteger)floorf(self.contentSize.height / self.bounds.size.height);
    }
    
    UIColor *backgroundColor = self.backgroundColor ?: [UIColor whiteColor];
    
    UIGraphicsBeginImageContextWithOptions(self.contentSize, YES, 0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    CGContextSetStrokeColorWithColor(context, backgroundColor.CGColor);
    
    [self drawScreenshotOfPageContentAtIndex:0 maxIndex:pageNum originalOffset:originalOffset completion:^{
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        self.contentOffset = originalOffset;
        if (completion) {
            completion(image);
        }
    }];
}

- (void)drawScreenshotOfPageContentAtIndex:(NSInteger)index maxIndex:(NSInteger)maxIndex originalOffset:(CGPoint)originalOffset completion:(void (^)(void))completion {
    
    [self setContentOffset:CGPointMake(0, index * self.frame.size.height) animated:NO];
    CGRect pageFrame = CGRectMake(0, index * self.frame.size.height, self.bounds.size.width, self.bounds.size.height);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self drawViewHierarchyInRect:pageFrame afterScreenUpdates:YES];
        
        if (index < maxIndex) {
            [self drawScreenshotOfPageContentAtIndex:index + 1 maxIndex:maxIndex originalOffset:originalOffset completion:completion];
        } else {
            if (completion) {
                completion();
            }
        }
    });
}

@end

@interface WebViewController ()
@property (nonatomic, strong) WKWebView *webView;
@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.whiteColor;

    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.webView];

    UIButton *testButton = [UIButton buttonWithType:UIButtonTypeSystem];
    testButton.translatesAutoresizingMaskIntoConstraints = NO;
    [testButton setTitle:@"测试" forState:UIControlStateNormal];
    [testButton addTarget:self action:@selector(testButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:testButton];

    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.webView.topAnchor constraintEqualToAnchor:guide.topAnchor],
        [self.webView.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor],
        [self.webView.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor],
        [self.webView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor],
        [testButton.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:16.0],
        [testButton.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor constant:-16.0]
    ]];

    NSURL *url = [NSURL URLWithString:@"https://xnews.jin10.com/webapp/details.html?id=206437&type=news&data_type=0"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

- (void)handleFixedElements:(void (^)(void))completion {
    NSString *js = @"(function() {"
    "var saved = [];"
    "var all = document.querySelectorAll('*');"
    "for (var i = 0; i < all.length; i++) {"
    "  var el = all[i];"
    "  var style = window.getComputedStyle(el);"
    "  if (style.position === 'fixed') {"
    "    saved.push({el: el, css: el.style.cssText});"
    "    el.style.visibility = 'hidden';"
    "  }"
    "}"
    "window.__fixedElements = saved;"
    "})()";
    
    [self.webView evaluateJavaScript:js completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if (completion) {
            completion();
        }
    }];
}

- (void)restoreFixedElements {
    NSString *js = @"(function() {"
    "if (window.__fixedElements) {"
    "  window.__fixedElements.forEach(function(item) {"
    "    item.el.style.cssText = item.css;"
    "  });"
    "  delete window.__fixedElements;"
    "}"
    "})()";
    
    [self.webView evaluateJavaScript:js completionHandler:nil];
}

- (void)takeScrollScreenshot {
    [ToastUtil showToastWithMessage:@"开始截屏..."];
    
    [self handleFixedElements:^{
        [self.webView.scrollView takeScreenshotOfFullContent:^(UIImage * _Nullable image) {
            [self restoreFixedElements];
            
            if (image) {
                NSData *imageData = UIImagePNGRepresentation(image);
                if (!imageData) {
                    NSLog(@"图片转换失败");
                    [ToastUtil showToastWithMessage:@"图片保存失败"];
                    return;
                }
                
                NSString *fileName = [NSString stringWithFormat:@"screenshot_%@.png", @((long)[[NSDate date] timeIntervalSince1970])];
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [paths firstObject];
                NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
                
                NSError *error = nil;
                BOOL success = [imageData writeToFile:filePath options:NSDataWritingAtomic error:&error];
                
                if (success) {
                    NSLog(@"截图已保存到路径: %@", filePath);
                    [ToastUtil showToastWithMessage:@"已保存到应用沙盒"];
                } else {
                    NSLog(@"保存文件失败: %@", error.localizedDescription);
                    [ToastUtil showToastWithMessage:@"保存失败"];
                }
            } else {
                NSLog(@"截图失败");
                [ToastUtil showToastWithMessage:@"截图失败"];
            }
        }];
    }];
}

- (void)takeOfficialSnapshot {
    [ToastUtil showToastWithMessage:@"开始截屏(官方API)..."];
    
    WKSnapshotConfiguration *config = [[WKSnapshotConfiguration alloc] init];
    config.rect = CGRectNull; // 默认截取可视区域
    config.afterScreenUpdates = YES;
    
    [self.webView takeSnapshotWithConfiguration:config completionHandler:^(UIImage * _Nullable snapshotImage, NSError * _Nullable error) {
        if (snapshotImage) {
            NSData *imageData = UIImagePNGRepresentation(snapshotImage);
            if (!imageData) {
                NSLog(@"图片转换失败");
                [ToastUtil showToastWithMessage:@"图片保存失败"];
                return;
            }
            
            NSString *fileName = [NSString stringWithFormat:@"official_screenshot_%@.png", @((long)[[NSDate date] timeIntervalSince1970])];
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths firstObject];
            NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
            
            NSError *writeError = nil;
            BOOL success = [imageData writeToFile:filePath options:NSDataWritingAtomic error:&writeError];
            
            if (success) {
                NSLog(@"截图已保存到路径: %@", filePath);
                [ToastUtil showToastWithMessage:@"已保存到应用沙盒"];
            } else {
                NSLog(@"保存文件失败: %@", writeError.localizedDescription);
                [ToastUtil showToastWithMessage:@"保存失败"];
            }
        } else {
            NSLog(@"截图失败: %@", error.localizedDescription);
            [ToastUtil showToastWithMessage:@"截图失败"];
        }
    }];
}

- (void)testButtonTapped {
    // [self takeScrollScreenshot];
    [self takeOfficialSnapshot];
}

@end
