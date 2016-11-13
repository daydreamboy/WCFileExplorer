//
//  WCTextEditViewController.m
//  Pods
//
//  Created by wesley chen on 16/11/5.
//
//

#import "WCTextEditViewController.h"

#pragma mark > Configurable

typedef NS_ENUM(NSInteger, WCEditMode) {
    WCEditModeView,
    WCEditModeSearching,
    WCEditModeEditing,
};

typedef NS_ENUM(NSInteger, WCActionSheetType) {
    WCActionSheetTypeActions = 100,
    WCActionSheetTypeSimpleMatchActions,
    WCActionSheetTypeLetterCaseActions,
    WCActionSheetTypeSearchOrderActions,
};

typedef NS_ENUM(NSInteger, WCLetterCaseItemAction) {
    WCLetterCaseItemActionCaseInSensitive = 1,
    WCLetterCaseItemActionCaseSensitive,
};

static NSString* NSStringFromWCLetterCaseItemAction(WCLetterCaseItemAction action) {
    switch (action) {
        case WCLetterCaseItemActionCaseInSensitive: {
            return NSLocalizedString(@"忽略大小写", nil);
        }
        case WCLetterCaseItemActionCaseSensitive: {
            return NSLocalizedString(@"大小写敏感", nil);
        }
        default: {
            return @"";
        }
    }
}

typedef NS_ENUM(NSInteger, WCSimpleMatchItemAction) {
    WCSimpleMatchItemActionContaining = 1,
    WCSimpleMatchItemActionStartWith,
    WCSimpleMatchItemActionEndWith,
    WCSimpleMatchItemActionMatching,
};

static NSString* NSStringFromWCSimpleMatchItemAction(WCSimpleMatchItemAction action) {
    switch (action) {
        case WCSimpleMatchItemActionContaining: {
            return NSLocalizedString(@"包含", nil);
        }
        case WCSimpleMatchItemActionStartWith: {
            return NSLocalizedString(@"开头是", nil);
        }
        case WCSimpleMatchItemActionEndWith: {
            return NSLocalizedString(@"结尾是", nil);
        }
        case WCSimpleMatchItemActionMatching: {
            return NSLocalizedString(@"完全匹配", nil);
        }
        default: {
            return @"";
        }
    }
}

typedef NS_ENUM(NSUInteger, WCSearchOrderAction) {
    WCSearchOrderActionFrontToEnd = 1,
    WCSearchOrderActionEndToFront,
    WCSearchOrderActionLoop,
};

static NSString* NSStringFromWCSearchOrderAction(WCSearchOrderAction action) {
    switch (action) {
        case WCSearchOrderActionFrontToEnd: {
            return NSLocalizedString(@"从前到后查找", nil);
        }
        case WCSearchOrderActionEndToFront: {
            return NSLocalizedString(@"从后到前查找", nil);
        }
        case WCSearchOrderActionLoop: {
            return NSLocalizedString(@"循环查找", nil);
        }
        default: {
            return @"";
        }
    }
}

#pragma mark < Configurable

#define NAV_BAR_MAX_Y       64.0f

@interface WCTextEditViewController () <UIActionSheetDelegate, UISearchBarDelegate>

@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIBarButtonItem *actionsItem;
@property (nonatomic, strong) NSMutableAttributedString *attrTextM;

@property (nonatomic, strong) NSMutableDictionary *searchInventoryM;
@property (nonatomic, assign) NSInteger searchKeyCurrentIndex;

@property (nonatomic, assign) NSRange currentHighlightRange;

@property (nonatomic, strong) UIColor *colorForAll;
@property (nonatomic, strong) UIColor *colorForCurrent;

// Search Bar
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, copy) NSString *currentSearchKey;

// Search Tool Bar
@property (nonatomic, strong) UIToolbar *searchToolBar;
@property (nonatomic, strong) UIBarButtonItem *simpleMatchItem;
@property (nonatomic, strong) UIBarButtonItem *searchOrderItem;
@property (nonatomic, strong) UIBarButtonItem *letterCaseItem;
@property (nonatomic, strong) UIBarButtonItem *previousItem;
@property (nonatomic, strong) UIBarButtonItem *nextItem;

// UIActionSheet actions
@property (nonatomic, strong) NSArray *simpleMatchItemActions;
@property (nonatomic, strong) NSArray *letterCaseItemActions;
@property (nonatomic, strong) NSArray *searchOrderItemActions;
@property (nonatomic, assign) NSInteger simpleMatchItemActionsIndex;
@property (nonatomic, assign) NSInteger letterCaseItemActionsIndex;
@property (nonatomic, assign) NSInteger searchOrderItemActionsIndex;

@property (nonatomic, assign) BOOL statusBarHidden;
@property (nonatomic, assign) WCEditMode currentMode;
@property (nonatomic, assign) WCEditMode toMode;

@end

@implementation WCTextEditViewController

- (instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    if (self) {
        _filePath = filePath;
        _searchInventoryM = [NSMutableDictionary dictionary];
        _currentHighlightRange = NSMakeRange(0, 0);
        
        _colorForAll = [UIColor colorWithRed:0xFE / 255.0f green:0xD1 / 255.0f blue:0x52 / 255.0f alpha:1];
        _colorForCurrent = [UIColor colorWithRed:0xFF / 255.0f green:0x7A / 255.0f blue:0x38 / 255.0f alpha:1];
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

- (BOOL)prefersStatusBarHidden {
    // If self.statusBarHidden is TRUE, return YES. If FALSE, return NO.
    return (self.statusBarHidden) ? YES : NO;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

#pragma mark - Getters

- (UITextView *)textView {
    if (!_textView) {
        CGFloat startY = NAV_BAR_MAX_Y;
        
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, startY, screenSize.width, screenSize.height - startY)];
        textView.autocorrectionType = UITextAutocorrectionTypeNo;
        textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textView.editable = NO;
        
        _textView = textView;
    }
    
    return _textView;
}

- (UIBarButtonItem *)actionsItem {
    if (!_actionsItem) {
        UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionsItemClicked:)];
        
        _actionsItem = barItem;
    }
    
    return _actionsItem;
}

- (UISearchBar *)searchBar {
    if (!_searchBar) {
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
        searchBar.prompt = NSLocalizedString(@"搜索模式", nil);
        searchBar.showsCancelButton = YES;
        searchBar.placeholder = NSLocalizedString(@"请输入关键词", nil);
        searchBar.delegate = self;
        [searchBar sizeToFit];
        
        CGRect frame = searchBar.frame;
        frame.origin.y = -frame.size.height;
        searchBar.frame = frame;
        
        _searchBar = searchBar;
    }
    
    return _searchBar;
}

- (UIToolbar *)searchToolBar {
    if (!_searchToolBar) {
        
        [self setupToolBarItems];
        
        UIBarButtonItem *flexSpaceItem1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        UIBarButtonItem *flexSpaceItem2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *flexSpaceItem3 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *flexSpaceItem4 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *flexSpaceItem5 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        
        UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectZero];
        
        toolBar.items = @[
                          flexSpaceItem1,
                          self.simpleMatchItem,
                          flexSpaceItem2,
                          self.searchOrderItem,
                          flexSpaceItem1,
                          self.letterCaseItem,
                          flexSpaceItem3,
                          self.previousItem,
                          flexSpaceItem4,
                          self.nextItem,
                          flexSpaceItem5,
                          ];
        
        [toolBar sizeToFit];
        CGRect frame = toolBar.frame;
        frame.origin.y = screenSize.height;
        toolBar.frame = frame;
        
        _searchToolBar = toolBar;
    }
    
    return _searchToolBar;
}

#pragma mark

- (void)setup {
    if ([self respondsToSelector:@selector(setAutomaticallyAdjustsScrollViewInsets:)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
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
    [self.view addSubview:self.searchBar];
    [self.view addSubview:self.searchToolBar];
    
    self.navigationItem.rightBarButtonItem = self.actionsItem;
}

- (void)setupToolBarItems {
    
    // titles for UIActionSheet
    self.simpleMatchItemActions = @[@(WCSimpleMatchItemActionContaining), @(WCSimpleMatchItemActionStartWith), @(WCSimpleMatchItemActionEndWith), @(WCSimpleMatchItemActionMatching)];
    self.letterCaseItemActions = @[@(WCLetterCaseItemActionCaseInSensitive), @(WCLetterCaseItemActionCaseSensitive)];
    self.searchOrderItemActions = @[@(WCSearchOrderActionFrontToEnd), @(WCSearchOrderActionEndToFront), @(WCSearchOrderActionLoop)];
    
    // indice for UIActionSheet
    self.simpleMatchItemActionsIndex = 1;
    self.letterCaseItemActionsIndex = 1;
    self.searchOrderItemActionsIndex = 1;
    
    // items for search tool bar
    self.simpleMatchItem = [[UIBarButtonItem alloc] initWithTitle:@"Reg" style:UIBarButtonItemStylePlain target:self action:@selector(simpleMatchItemClicked:)];
    self.searchOrderItem = [[UIBarButtonItem alloc] initWithTitle:@"⬇︎⬆︎" style:UIBarButtonItemStylePlain target:self action:@selector(searchOrderItemClicked:)];
    self.letterCaseItem = [[UIBarButtonItem alloc] initWithTitle:@"Aa" style:UIBarButtonItemStylePlain target:self action:@selector(letterCaseItemClicked:)];
    self.previousItem = [[UIBarButtonItem alloc] initWithTitle:@"◀︎" style:UIBarButtonItemStylePlain target:self action:@selector(previousItemClicked:)];
    self.nextItem = [[UIBarButtonItem alloc] initWithTitle:@"▶︎" style:UIBarButtonItemStylePlain target:self action:@selector(nextItemClicked:)];
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
        self.navigationItem.rightBarButtonItem = nil;
        
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
        NSData *data = [NSData dataWithContentsOfFile:filePath options:kNilOptions error:&errorL];
        if (data) {
            @try {
                id objectM = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:&format error:&errorL];
                content = [NSString stringWithFormat:@"%@", objectM];
            }
            @catch (NSException *exception) {
                NSLog(@"exception: %@", exception);
                NSString *reason = exception.reason ? exception.reason : @"文件读取异常";
                errorL = [NSError errorWithDomain:NSStringFromClass([self class]) code:-1 userInfo:@{ NSLocalizedDescriptionKey: reason }];
            }
        }
    }
    else {
        NSStringEncoding encoding = 0;
        // Treat as simple text file
        content = [NSString stringWithContentsOfFile:filePath usedEncoding:&encoding error:&errorL];
    }

    *error = errorL;
    
    return content;
}

- (void)highlightAllWithFirstRange:(NSRange)firstRange searchKey:(NSString *)searchKey {
    
    NSArray *ranges = self.searchInventoryM[searchKey];
    
    if (ranges.count) {
        NSMutableAttributedString *attrString = [self.attrTextM mutableCopy];
        
        for (NSUInteger i = 0; i < ranges.count; i++) {
            NSRange range = [ranges[i] rangeValue];
            
            if (range.location == firstRange.location && range.length == firstRange.length) {
                // highlight first range
                if (firstRange.location != NSNotFound && firstRange.length == searchKey.length) {
                    self.currentHighlightRange = firstRange;
                    
                    [attrString setAttributes:@{ NSBackgroundColorAttributeName: self.colorForCurrent } range:firstRange];
                }
            }
            else {
                // highlight other ranges
                if (range.location != NSNotFound && range.length == searchKey.length) {
                    [attrString setAttributes:@{ NSBackgroundColorAttributeName: self.colorForAll } range:range];
                }
            }
        }
        
        self.textView.attributedText = attrString;
    }
}

- (void)highlightWithRange:(NSRange)range searchKey:(NSString *)searchKey {
    if (range.location != NSNotFound && range.length == searchKey.length) {
        [self.textView.textStorage setAttributes:@{ NSBackgroundColorAttributeName: self.colorForCurrent } range:range];
        
        if (self.currentHighlightRange.location != NSNotFound && self.currentHighlightRange.length == searchKey.length) {
            [self.textView.textStorage setAttributes:@{ NSBackgroundColorAttributeName: self.colorForAll } range:self.currentHighlightRange];
        }
        self.currentHighlightRange = range;
    }
}

- (void)refreshPeviousItemAndNextItem {
    NSArray *ranges = self.searchInventoryM[self.currentSearchKey];
    
    if (self.searchOrderItemActionsIndex == WCSearchOrderActionLoop) {
        self.previousItem.enabled = YES;
        self.nextItem.enabled = YES;
    }
    else {
        if (0 < self.searchKeyCurrentIndex && self.searchKeyCurrentIndex + 1 < ranges.count) {
            self.previousItem.enabled = YES;
            self.nextItem.enabled = YES;
        }
        else if (self.searchKeyCurrentIndex == 0) {
            self.previousItem.enabled = NO;
            self.nextItem.enabled = YES;
        }
        else if (self.searchKeyCurrentIndex + 1 == ranges.count) {
            self.previousItem.enabled = YES;
            self.nextItem.enabled = NO;
        }
    }
}

- (UIActionSheet *)createActionSheetWithWCActionSheetType:(WCActionSheetType)type title:(NSString *)title {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:NSLocalizedString(@"取消", nil) destructiveButtonTitle:nil otherButtonTitles:nil];
    actionSheet.tag = type;
    
    NSArray *arr = [NSArray array];
    NSInteger selectedIndex = 0;
    NSString *(^block)(NSInteger index) = nil;
    
    if (type == WCActionSheetTypeSimpleMatchActions) {
        arr = self.simpleMatchItemActions;
        selectedIndex = self.simpleMatchItemActionsIndex;
        
        block = ^NSString *(NSInteger index) {
            return NSStringFromWCSimpleMatchItemAction(index);
        };
    }
    else if (type == WCActionSheetTypeLetterCaseActions) {
        arr = self.letterCaseItemActions;
        selectedIndex = self.letterCaseItemActionsIndex;
        
        block = ^NSString *(NSInteger index) {
            return NSStringFromWCLetterCaseItemAction(index);
        };
    }
    else if (type == WCActionSheetTypeSearchOrderActions) {
        arr = self.searchOrderItemActions;
        selectedIndex = self.searchOrderItemActionsIndex;
        
        block = ^NSString *(NSInteger index) {
            return NSStringFromWCSearchOrderAction(index);
        };
    }
    
    for (NSInteger i = 0; i < [arr count]; i++) {
        NSNumber *numInt = arr[i];
        NSInteger action = [numInt integerValue];
        
        NSString *buttonTitle = @"";
        
        if (block) {
            buttonTitle = block(action);
        }
        
        if (i == selectedIndex - 1) {
            buttonTitle = [NSString stringWithFormat:@"✓ %@", buttonTitle];
        }
        
        [actionSheet addButtonWithTitle:buttonTitle];
    }
    
    return actionSheet;
}

#pragma mark - Actions

- (void)actionsItemClicked:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"常用操作", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"取消", nil) destructiveButtonTitle:nil otherButtonTitles:nil];
    actionSheet.tag = WCActionSheetTypeActions;
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"查找", nil)];
    [actionSheet showInView:self.view];
}

- (void)simpleMatchItemClicked:(UIBarButtonItem *)barItem {
    UIActionSheet *actionSheet = [self createActionSheetWithWCActionSheetType:WCActionSheetTypeSimpleMatchActions title:NSLocalizedString(@"查找规则", nil)];
    [actionSheet showInView:self.view];
}

- (void)searchOrderItemClicked:(UIBarButtonItem *)barItem {
    UIActionSheet *actionSheet = [self createActionSheetWithWCActionSheetType:WCActionSheetTypeSearchOrderActions title:NSLocalizedString(@"查找顺序", nil)];
    [actionSheet showInView:self.view];
}

- (void)letterCaseItemClicked:(UIBarButtonItem *)barItem {
    UIActionSheet *actionSheet = [self createActionSheetWithWCActionSheetType:WCActionSheetTypeLetterCaseActions title:NSLocalizedString(@"查找规则", nil)];
    [actionSheet showInView:self.view];
}

- (void)previousItemClicked:(UIBarButtonItem *)barItem {
    NSArray *ranges = self.searchInventoryM[self.currentSearchKey];
    if (self.searchKeyCurrentIndex - 1 == -1 && self.searchOrderItemActionsIndex == WCSearchOrderActionLoop) {
        self.searchKeyCurrentIndex = ranges.count;
    }

    if (self.searchKeyCurrentIndex - 1 >= 0) {
        self.searchKeyCurrentIndex--;
        NSRange range = [ranges[self.searchKeyCurrentIndex] rangeValue];
        [self highlightWithRange:range searchKey:self.currentSearchKey];
        [self.textView scrollRangeToVisible:range];
    }

    [self refreshPeviousItemAndNextItem];
}

- (void)nextItemClicked:(UIBarButtonItem *)barItem {
    NSArray *ranges = self.searchInventoryM[self.currentSearchKey];
    
    if (self.searchKeyCurrentIndex + 1 == ranges.count && self.searchOrderItemActionsIndex == WCSearchOrderActionLoop) {
        self.searchKeyCurrentIndex = -1;
    }
    
    if (self.searchKeyCurrentIndex + 1 < ranges.count) {
        self.searchKeyCurrentIndex++;
        NSRange range = [ranges[self.searchKeyCurrentIndex] rangeValue];
        [self highlightWithRange:range searchKey:self.currentSearchKey];
        [self.textView scrollRangeToVisible:range];
    }
    [self refreshPeviousItemAndNextItem];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    if (actionSheet.tag == WCActionSheetTypeActions) {
        switch (buttonIndex) {
            case 1: {
                self.currentMode = WCEditModeView;
                self.toMode = WCEditModeSearching;
                [self.searchBar becomeFirstResponder];
            }
            default:
                break;
        }
    }
    else if (actionSheet.tag == WCActionSheetTypeSimpleMatchActions) {
        if (buttonIndex != actionSheet.cancelButtonIndex) {
            self.simpleMatchItemActionsIndex = buttonIndex;
        }
    }
    else if (actionSheet.tag == WCActionSheetTypeLetterCaseActions) {
        if (buttonIndex != actionSheet.cancelButtonIndex) {
            self.letterCaseItemActionsIndex = buttonIndex;
        }
    }
    else if (actionSheet.tag == WCActionSheetTypeSearchOrderActions) {
        if (buttonIndex != actionSheet.cancelButtonIndex) {
            self.searchOrderItemActionsIndex = buttonIndex;
            
            [self refreshPeviousItemAndNextItem];
        }
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.textView.attributedText = [self.attrTextM mutableCopy];
    
    self.currentMode = WCEditModeSearching;
    self.toMode = WCEditModeView;
    [self.searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    self.currentMode = WCEditModeSearching;
    self.toMode = WCEditModeSearching;
    [self.searchBar resignFirstResponder];
    
    NSString *searchKey = [self.searchBar.text copy];
    
    if (searchKey.length) {
        self.currentSearchKey = searchKey;
        
        NSArray *ranges = [self rangesOfSubstring:searchKey inString:self.textView.text];
        
        // Disable retreiving ranges from self.searchInventoryM
        //NSArray *ranges = [self.searchInventoryM[searchKey] count] ? self.searchInventoryM[searchKey] : [self rangesOfSubstring:searchKey inString:self.textView.text];
        
        self.searchInventoryM[searchKey] = ranges;
        
        self.searchBar.prompt = [NSString stringWithFormat:@"找到%ld个匹配", (long)ranges.count];
        
        if (ranges.count) {
            NSRange firstRange = NSMakeRange(0, 0);
            
            if (self.searchOrderItemActionsIndex == WCSearchOrderActionFrontToEnd) {
                self.searchKeyCurrentIndex = 0;
                
                self.previousItem.enabled = NO;
                self.nextItem.enabled = YES;
                
                firstRange = [[ranges firstObject] rangeValue];
            }
            else if (self.searchOrderItemActionsIndex == WCSearchOrderActionEndToFront) {
                self.searchKeyCurrentIndex = ranges.count - 1;
                
                self.previousItem.enabled = YES;
                self.nextItem.enabled = NO;
                
                firstRange = [[ranges lastObject] rangeValue];
            }
            else if (self.searchOrderItemActionsIndex == WCSearchOrderActionLoop) {
                self.searchKeyCurrentIndex = 0;
                
                self.previousItem.enabled = YES;
                self.nextItem.enabled = YES;
                
                firstRange = [[ranges firstObject] rangeValue];
            }
            
            if (firstRange.length) {
                [self highlightAllWithFirstRange:firstRange searchKey:searchKey];
                
                [self.textView scrollRangeToVisible:firstRange];
            }
        }
        else {
            self.previousItem.enabled = NO;
            self.nextItem.enabled = NO;
            
            self.textView.attributedText = [self.attrTextM mutableCopy];
        }
    }
}

#pragma mark - NSNotification

- (void)handleKeyboardWillShowNotification:(NSNotification *)notification {
    if (self.isViewLoaded && self.view.window) {
        
        if (self.currentMode == WCEditModeView && self.toMode == WCEditModeSearching) {
            CGSize screenSize = [[UIScreen mainScreen] bounds].size;
            
            CGRect toRectForSearchBar = CGRectMake(0, 0, self.searchBar.frame.size.width, self.searchBar.frame.size.height);
            CGRect toRectForSerachToolBar = CGRectMake(0, screenSize.height - self.searchToolBar.frame.size.height, self.searchToolBar.frame.size.width, self.searchToolBar.frame.size.height);
            CGRect toRectForTextView = CGRectMake(0, CGRectGetHeight(self.searchBar.frame), self.textView.frame.size.width, screenSize.height - CGRectGetHeight(self.searchBar.frame) - CGRectGetHeight(self.searchToolBar.frame));
            
            self.navigationController.navigationBar.alpha = 1;
            
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
            
            self.statusBarHidden = (self.statusBarHidden) ? NO : YES;
            
            [UIView beginAnimations:nil context:NULL];
            
            // Fix Bug on iOS 8: When keyboard shown and another UITextField get focused, both duration and curve is 0
            NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] ? : 0.25;
            [UIView setAnimationDuration:duration];
            NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue] ? : 7;
            [UIView setAnimationCurve:curve];
            [UIView setAnimationBeginsFromCurrentState:YES];
            
            // first status bar
            // @see http://stackoverflow.com/questions/13624695/proper-way-to-hide-status-bar-on-ios-with-animation-and-resizing-root-view
            [self setNeedsStatusBarAppearanceUpdate];
            
            self.searchBar.frame = toRectForSearchBar;
            self.textView.frame = toRectForTextView;
            self.searchToolBar.frame = toRectForSerachToolBar;
            self.navigationController.navigationBar.alpha = 0;
            
            [UIView commitAnimations];
        }
    }
}

- (void)handleKeyboardWillHideNotification:(NSNotification *)notification {
    if (self.isViewLoaded && self.view.window) {
        if (self.currentMode == WCEditModeSearching && self.toMode == WCEditModeView) {
            CGSize screenSize = [[UIScreen mainScreen] bounds].size;
            CGFloat startY = NAV_BAR_MAX_Y;
            
            CGRect toRectForSearchBar = CGRectMake(0, -self.searchBar.frame.size.height, self.searchBar.frame.size.width, self.searchBar.frame.size.height);
            CGRect toRectForSerachToolBar = CGRectMake(0, screenSize.height, self.searchToolBar.frame.size.width, self.searchToolBar.frame.size.height);
            CGRect toRectForTextView = CGRectMake(0, startY, self.textView.frame.size.width, screenSize.height - startY);
            
            self.navigationController.navigationBar.alpha = 0;
            
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
            self.statusBarHidden = (self.statusBarHidden) ? NO : YES;
            
            [UIView beginAnimations:nil context:NULL];
            
            // Fix Bug on iOS 8: When keyboard shown and another UITextField get focused, both duration and curve is 0
            NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] ? : 0.25;
            [UIView setAnimationDuration:duration];
            NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue] ? : 7;
            [UIView setAnimationCurve:curve];
            [UIView setAnimationBeginsFromCurrentState:YES];
            
            [self setNeedsStatusBarAppearanceUpdate];
            
            self.searchBar.frame = toRectForSearchBar;
            self.searchToolBar.frame = toRectForSerachToolBar;
            self.textView.frame = toRectForTextView;
            
            self.navigationController.navigationBar.alpha = 1;
            
            [UIView commitAnimations];
        }
    }
}

#pragma mark - Utility

- (NSArray *)rangesOfSubstring:(NSString *)substring inString:(NSString *)string {
    
    NSStringCompareOptions options = NSCaseInsensitiveSearch;
    
    if (self.letterCaseItemActionsIndex == WCLetterCaseItemActionCaseSensitive) {
        options = kNilOptions;
    }
    
    NSRange searchRange = NSMakeRange(0, string.length);
    NSRange foundRange;
    
    NSMutableArray *arrM = [NSMutableArray array];
    
    while (searchRange.location < string.length) {
        searchRange.length = string.length - searchRange.location;
        foundRange = [string rangeOfString:substring options:options range:searchRange];
        
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
