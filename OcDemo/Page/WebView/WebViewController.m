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
@property (nonatomic, strong) NSLayoutConstraint *webViewBottomConstraint;
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
    
    self.webViewBottomConstraint = [self.webView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor];
    self.webViewBottomConstraint.active = YES;
    
    [NSLayoutConstraint activateConstraints:@[
         [self.webView.topAnchor constraintEqualToAnchor:guide.topAnchor],
         [self.webView.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor],
         [self.webView.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor],
         // [self.webView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor],

//        [self.webView.topAnchor constraintEqualToAnchor:guide.topAnchor],
//        [self.webView.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor],
//        [self.webView.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor],
//        [self.webView.heightAnchor constraintEqualToConstant:5000],
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
    [ToastUtil showToastWithMessage:@"开始截屏(长图)..."];
    
    UIScrollView *scrollView = self.webView.scrollView;
    CGSize contentSize = scrollView.contentSize;
    
    if (contentSize.width <= 0 || contentSize.height <= 0) {
        NSLog(@"内容尺寸无效: %@", NSStringFromCGSize(contentSize));
        [ToastUtil showToastWithMessage:@"内容还没加载完，稍后再试"];
        return;
    }
    
    // 记录原始 frame 和 contentOffset，方便还原
    CGRect oldFrame = self.webView.frame;
    CGPoint oldOffset = scrollView.contentOffset;
    
    // 以内容高度为主，宽度优先用当前 frame 宽度
    CGFloat snapshotWidth = CGRectGetWidth(oldFrame);
    if (snapshotWidth <= 0) {
        snapshotWidth = contentSize.width;
    }
    CGFloat snapshotHeight = contentSize.height;
    
    // 临时把 webView 拉到整页高度，类似 mainWeb.frame = contentSize.height 的做法
    self.webViewBottomConstraint.active = NO;
    NSLayoutConstraint *heightConstraint = [self.webView.heightAnchor constraintEqualToConstant:snapshotHeight];
    heightConstraint.active = YES;
    [self.view layoutIfNeeded];

    
    // 处理掉 position:fixed 元素，避免长图里多次重复
    [self handleFixedElements:^{
        // 略微延迟一下，确保布局和隐藏操作都生效
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(snapshotWidth, snapshotHeight), YES, 0);
            CGContextRef ctx = UIGraphicsGetCurrentContext();
            if (!ctx) {
                NSLog(@"创建图片上下文失败");
                [ToastUtil showToastWithMessage:@"截图失败"];
                
                // 还原
                heightConstraint.active = NO;
                self.webViewBottomConstraint.active = YES;
                [self.view layoutIfNeeded];

                scrollView.contentOffset = oldOffset;
                [self restoreFixedElements];
                return;
            }
            
            // 核心：直接把整个 webView 的 layer 渲染到位图中，类似 yhViewTurnToImage
            [self.webView.layer renderInContext:ctx];
            UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            // 还原 frame 和滚动位置、fixed 元素
            heightConstraint.active = NO;
            self.webViewBottomConstraint.active = YES;
            [self.view layoutIfNeeded];

            scrollView.contentOffset = oldOffset;
            [self restoreFixedElements];
            
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
                NSLog(@"截图失败：生成图片为空");
                [ToastUtil showToastWithMessage:@"截图失败"];
            }
        });
    }];
}

- (void)testButtonTapped {
    // [self takeScrollScreenshot];
    [self takeOfficialSnapshot];
}

@end
