//
//  WCTextEditViewController.m
//  Pods
//
//  Created by wesley chen on 16/11/5.
//
//

#import "WCTextEditViewController.h"

#import "WCSearchInputAccessoryView.h"

@interface WCTextEditViewController () <UIActionSheetDelegate, WCSearchInputAccessoryViewDelegate>
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, assign) NSStringEncoding textEncoding;
@property (nonatomic, strong) NSMutableAttributedString *attrTextM;
@property (nonatomic, assign) BOOL focused;

@property (nonatomic, strong) UITextField *textField;

@property (nonatomic, strong) WCSearchInputAccessoryView *searchInputAccessoryView;

@property (nonatomic, strong) NSMutableDictionary *searchInventoryM;
@property (nonatomic, assign) NSInteger searchKeyCurrentIndex;

@end

@implementation WCTextEditViewController

- (instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    if (self) {
        _filePath = filePath;
        _searchInventoryM = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setup];
    [self registerNotifications];
    [self loadFile];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

#pragma mark - Getters

- (UITextView *)textView {
    if (!_textView) {
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
        textView.autocorrectionType = UITextAutocorrectionTypeNo;
        textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textView.editable = NO;
        
        _textView = textView;
    }
    
    return _textView;
}
                          
#pragma mark

- (void)setup {
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
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"⚙ ↺" style:UIBarButtonItemStylePlain target:self action:@selector(showOperationActionSheet:)];
    
    WCSearchInputAccessoryView *searchInputAccessoryView = [WCSearchInputAccessoryView new];
    searchInputAccessoryView.delegate = self;
    [self.view addSubview:searchInputAccessoryView];
    self.searchInputAccessoryView = searchInputAccessoryView;
}

- (void)registerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)loadFile {
    NSError *error;
    NSString *text = [self readFileAtPath:self.filePath error:&error];
    if (!error) {
        self.attrTextM = [[NSMutableAttributedString alloc] initWithString:text];
        self.textView.attributedText = [self.attrTextM copy];
        self.textView.contentOffset = CGPointZero;
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

- (void)refreshSegmentedControlWithSearchKey:(NSString *)searchKey {
    NSArray *ranges = self.searchInventoryM[searchKey];
    
    if (0 < self.searchKeyCurrentIndex && self.searchKeyCurrentIndex + 1 < ranges.count) {
        [self.searchInputAccessoryView setPreviousNavigateButtonEnabled:YES];
        [self.searchInputAccessoryView setNextNavigateButtonEnabled:YES];
    }
    else if (self.searchKeyCurrentIndex == 0) {
        [self.searchInputAccessoryView setPreviousNavigateButtonEnabled:NO];
        [self.searchInputAccessoryView setNextNavigateButtonEnabled:YES];
    }
    else if (self.searchKeyCurrentIndex + 1 == ranges.count) {
        [self.searchInputAccessoryView setPreviousNavigateButtonEnabled:YES];
        [self.searchInputAccessoryView setNextNavigateButtonEnabled:NO];
    }
}


- (void)highlightWithRange:(NSRange)currentRange searchKey:(NSString *)searchKey {
    
    NSArray *ranges = self.searchInventoryM[searchKey];
    
    if (ranges.count) {
        UIColor *colorForAll = [UIColor colorWithRed:0xFE / 255.0f green:0xD1 / 255.0f blue:0x52 / 255.0f alpha:1];
        UIColor *colorForCurrent = [UIColor colorWithRed:0xFF / 255.0f green:0x7A / 255.0f blue:0x38 / 255.0f alpha:1];
        
        NSMutableAttributedString *attrString = [self.attrTextM mutableCopy];
        
        for (NSValue *value in ranges) {
            NSRange range = [value rangeValue];
            if (range.location != NSNotFound && range.length == searchKey.length) {
                
                if (NSEqualRanges(range, currentRange)) {
                    [attrString setAttributes:@{ NSBackgroundColorAttributeName: colorForCurrent } range:range];
                }
                else {
                    [attrString setAttributes:@{ NSBackgroundColorAttributeName: colorForAll } range:range];
                }
            }
        }
        
        self.textView.attributedText = attrString;
    }
}

#pragma mark - Actions

- (void)showOperationActionSheet:(id)sender {
    
    if (!self.focused) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"Find", nil];
        [actionSheet showInView:self.view];
    }
    else {
        self.focused = NO;
        [self.searchInputAccessoryView resignFirstResponder];
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0: {
            NSLog(@"Show search bar");
            if (!self.focused) {
                self.focused = YES;
                [self.searchInputAccessoryView becomeFirstResponder];
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark - NSNotification

- (void)handleKeyboardWillShowNotification:(NSNotification *)notification {
    if (self.isViewLoaded && self.view.window) {
        CGFloat keyboardHeight = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
        
        CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
        CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
        CGFloat topInset = statusBarHeight + navBarHeight;
        
        self.textView.contentInset = UIEdgeInsetsMake(topInset, 0, keyboardHeight, 0);
        self.textView.scrollIndicatorInsets = UIEdgeInsetsMake(topInset, 0, keyboardHeight, 0);
    }
}

- (void)handleKeyboardWillHideNotification:(NSNotification *)notification {
    if (self.isViewLoaded && self.view.window) {
        
        CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
        CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
        CGFloat topInset = statusBarHeight + navBarHeight;
        
        self.textView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
        self.textView.scrollIndicatorInsets = UIEdgeInsetsMake(topInset, 0, 0, 0);
    }
}

#pragma mark - WCSearchInputAccessoryViewDelegate

- (void)WCSearchInputAccessoryView:(WCSearchInputAccessoryView *)view navigateToPreviousKey:(NSString *)searchKey {
    NSArray *ranges = self.searchInventoryM[searchKey];
    if (self.searchKeyCurrentIndex - 1 >= 0) {
        self.searchKeyCurrentIndex--;
        NSRange range = [ranges[self.searchKeyCurrentIndex] rangeValue];
        [self highlightWithRange:range searchKey:searchKey];
    }
    
    [self refreshSegmentedControlWithSearchKey:searchKey];
}

- (void)WCSearchInputAccessoryView:(WCSearchInputAccessoryView *)view navigateToNextKey:(NSString *)searchKey {
    NSArray *ranges = self.searchInventoryM[searchKey];
    if (self.searchKeyCurrentIndex + 1 < ranges.count) {
        self.searchKeyCurrentIndex++;
        NSRange range = [ranges[self.searchKeyCurrentIndex] rangeValue];
        [self highlightWithRange:range searchKey:searchKey];
    }
    
    [self refreshSegmentedControlWithSearchKey:searchKey];
}

- (void)WCSearchInputAccessoryView:(WCSearchInputAccessoryView *)view didSearchKey:(NSString *)searchKey {
    
    if (searchKey.length) {
        NSArray *ranges = [self.searchInventoryM[searchKey] count] ? self.searchInventoryM[searchKey] : [self rangesOfSubstring:searchKey inString:self.textView.text];
        
        self.searchInventoryM[searchKey] = ranges;
        self.searchKeyCurrentIndex = 0;
        
        NSString *string = [NSString stringWithFormat:@"找到%ld个匹配", (long)ranges.count];
        [view setSearchResultText:string animated:YES];
        
        if (ranges.count) {
            [self.searchInputAccessoryView setPreviousNavigateButtonEnabled:NO];
            [self.searchInputAccessoryView setNextNavigateButtonEnabled:YES];
            
            NSRange firstRange = [[ranges firstObject] rangeValue];
            [self highlightWithRange:firstRange searchKey:searchKey];
            
            if (firstRange.location != NSNotFound && firstRange.length == searchKey.length) {
                [self.textView scrollRangeToVisible:firstRange];
                
                /*
                // @see http://stackoverflow.com/questions/28468187/find-cgpoint-location-of-substring-in-textview/28469139
                [self.textView.layoutManager ensureLayoutForTextContainer:self.textView.textContainer];
                
                UITextPosition *start = [self.textView positionFromPosition:self.textView.beginningOfDocument offset:range.location];
                UITextPosition *end = [self.textView positionFromPosition:start offset:range.location];
                UITextRange *textRange = [self.textView textRangeFromPosition:start toPosition:end];
                
                CGRect rect = [self.textView firstRectForRange:textRange];
                rect.origin.y += CGRectGetHeight(self.textView.bounds) - self.textView.contentInset.top - rect.size.height;
                
                [self.textView scrollRectToVisible:rect animated:YES];
                 */
            }
        }
        else {
            NSMutableAttributedString *attrString = [self.attrTextM mutableCopy];
            self.textView.attributedText = attrString;
            
            [self.searchInputAccessoryView setPreviousNavigateButtonEnabled:NO];
            [self.searchInputAccessoryView setNextNavigateButtonEnabled:NO];
        }
    }
}

#pragma mark - Utility

- (NSArray *)rangesOfSubstring:(NSString *)substring inString:(NSString *)string {
    NSRange searchRange = NSMakeRange(0, string.length);
    NSRange foundRange;
    
    NSMutableArray *arrM = [NSMutableArray array];
    
    while (searchRange.location < string.length) {
        searchRange.length = string.length - searchRange.location;
        foundRange = [string rangeOfString:substring options:kNilOptions range:searchRange];
        
        if (foundRange.location != NSNotFound) {
            // found an occurrence of the substring, and add its range to NSArray
            [arrM addObject:[NSValue valueWithRange:foundRange]];
            
            // move forward
            searchRange.location = foundRange.location + foundRange.length;
        }
        else {
            // no more substring to find
            break;
        }
    }
    
    return arrM;
}

@end
