//
//  WCTextEditViewController.m
//  Pods
//
//  Created by wesley chen on 16/11/5.
//
//

#import "WCTextEditViewController.h"

@interface WCTextEditViewController ()
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, assign) NSStringEncoding textEncoding;
@end

@implementation WCTextEditViewController

- (instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    if (self) {
        _filePath = filePath;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableParagraphStyle *defaultStyle = self.navigationController.navigationBar.titleTextAttributes[NSParagraphStyleAttributeName];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingHead;
    
    NSDictionary *attrs = @{
                            NSFontAttributeName: [UIFont boldSystemFontOfSize:15.0f],
                            NSForegroundColorAttributeName: [UIColor darkTextColor],
//                            NSParagraphStyleAttributeName: paragraphStyle
                            };
    
    self.title = [self.filePath lastPathComponent];
    self.navigationController.navigationBar.titleTextAttributes = attrs;
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.textView];
    
    [self loadFile];
}

#pragma mark - Getters

- (UITextView *)textView {
    if (!_textView) {
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
        textView.editable = NO;
        
        _textView = textView;
    }
    
    return _textView;
}
                          
#pragma mark

- (void)loadFile {
    NSError *error;
    NSString *text = [self readFileAtPath:self.filePath error:&error];
    if (!error) {
        self.textView.text = text;
    }
    else {
        NSLog(@"Error: %@", error);
        NSString *title = [NSString stringWithFormat:@"不能读取文件%@", [self.filePath lastPathComponent]];
        NSString *msg = [NSString stringWithFormat:@"code: %ld, %@", (long)error.code, error.localizedDescription];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil];
        [alert show];
    }
}

- (NSString *)readFileAtPath:(NSString *)filePath error:(NSError **)error {
    NSString *fileName = [filePath lastPathComponent];
    NSString *fileExt = [[fileName pathExtension] lowercaseString];
    
    NSString *content;
    NSStringEncoding encoding = 0;
    NSError *errorL;
    
    if ([fileExt isEqualToString:@"plist"]) {
        
        NSPropertyListFormat format = 0;
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        id objectM = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:&format error:&errorL];
        content = [NSString stringWithFormat:@"%@", objectM];
    }
    else {
        NSStringEncoding encoding = 0;
        // Treat as simple text file
        content = [NSString stringWithContentsOfFile:filePath usedEncoding:&encoding error:&errorL];
        self.textEncoding = encoding;
    }

    *error = errorL;
    
    return content;
}

@end
