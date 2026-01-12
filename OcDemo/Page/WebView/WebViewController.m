#import "WebViewController.h"
#import <WebKit/WebKit.h>

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

- (void)testButtonTapped {
    
}

@end
