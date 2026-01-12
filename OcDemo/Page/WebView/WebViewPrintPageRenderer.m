#import "WebViewPrintPageRenderer.h"

@interface WebViewPrintPageRenderer ()
@property (nonatomic, strong) UIPrintFormatter *formatter;
@property (nonatomic, assign) CGSize contentSize;
@end

@implementation WebViewPrintPageRenderer

- (instancetype)initWithFormatter:(UIPrintFormatter *)formatter contentSize:(CGSize)contentSize {
    self = [super init];
    if (self) {
        _formatter = formatter;
        _contentSize = contentSize;
        [self addPrintFormatter:formatter startingAtPageAtIndex:0];
    }
    return self;
}

- (CGRect)paperRect {
    return CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
}

- (CGRect)printableRect {
    return CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
}

- (NSData *)printContentToPDFData {
    NSMutableData *data = [NSMutableData data];
    UIGraphicsBeginPDFContextToData(data, self.paperRect, nil);
    [self prepareForDrawingPages:NSMakeRange(0, 1)];
    CGRect bounds = UIGraphicsGetPDFContextBounds();
    UIGraphicsBeginPDFPage();
    [self drawPageAtIndex:0 inRect:bounds];
    UIGraphicsEndPDFContext();
    return data;
}

- (UIImage *)printContentToImage {
    NSData *pdfData = [self printContentToPDFData];
    if (!pdfData) {
        return nil;
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)pdfData);
    if (!provider) {
        return nil;
    }
    
    CGPDFDocumentRef pdfDocument = CGPDFDocumentCreateWithProvider(provider);
    CGDataProviderRelease(provider);
    
    if (!pdfDocument) {
        return nil;
    }
    
    CGPDFPageRef pdfPage = CGPDFDocumentGetPage(pdfDocument, 1);
    if (!pdfPage) {
        CGPDFDocumentRelease(pdfDocument);
        return nil;
    }
    
    CGRect pageRect = CGPDFPageGetBoxRect(pdfPage, kCGPDFTrimBox);
    CGSize contentSize = CGSizeMake(floor(pageRect.size.width), floor(pageRect.size.height));
    
    UIGraphicsBeginImageContextWithOptions(contentSize, YES, 2.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        CGPDFDocumentRelease(pdfDocument);
        return nil;
    }
    
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context, pageRect);
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0, contentSize.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextSetInterpolationQuality(context, kCGInterpolationLow);
    CGContextSetRenderingIntent(context, kCGRenderingIntentDefault);
    CGContextDrawPDFPage(context, pdfPage);
    CGContextRestoreGState(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGPDFDocumentRelease(pdfDocument);
    
    return image;
}

@end
