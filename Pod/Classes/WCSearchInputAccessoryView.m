//
//  WCSearchInputAccessoryView.m
//  Pods
//
//  Created by wesley chen on 16/11/7.
//
//

#import "WCSearchInputAccessoryView.h"

#pragma mark - WCMomentarySegmentedControl

@class WCMomentarySegmentedControl;

@protocol WCMomentarySegmentedControlDelegate <NSObject>
- (void)WCMomentarySegmentedControl:(WCMomentarySegmentedControl *)segmentedControl clickedAtIndex:(NSInteger)index;
@end


@interface WCMomentarySegmentedControl : UISegmentedControl
@property (nonatomic, weak) id<WCMomentarySegmentedControlDelegate> delegate;
@end

@implementation WCMomentarySegmentedControl

- (instancetype)initWithItems:(NSArray *)items {
    self = [super initWithItems:items];
    if (self) {
        self.momentary = YES;
    }
    return self;
}

// @see http://stackoverflow.com/questions/19919120/uisegmentedcontrol-how-to-detect-click-on-current-segment
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    
    if ([self.delegate respondsToSelector:@selector(WCMomentarySegmentedControl:clickedAtIndex:)]) {
        NSInteger index = self.selectedSegmentIndex;
        [self.delegate WCMomentarySegmentedControl:self clickedAtIndex:index];
    }
}

@end

#pragma mark - WCSearchInputAccessoryView


#define SEARCH_TEXTFIELD_FONT   ([UIFont systemFontOfSize:11.0f])
#define MARGIN_H    10
#define SPACING_V    5
#define LABEL_H     ceil(SEARCH_TEXTFIELD_FONT.pointSize)
#define TEXTFIELD_SEGEMENT_H 30.0f

#define TOOLBAR_NONE_H  (SPACING_V + TEXTFIELD_SEGEMENT_H + SPACING_V)
#define TOOLBAR_TOP_H   (SPACING_V + LABEL_H + SPACING_V + TEXTFIELD_SEGEMENT_H + SPACING_V)
#define TOOLBAR_BOTTOM  80


NSString *WCSearchInputAccessoryViewTextDidChangedNotification = @"WCSearchInputAccessoryViewTextDidChangedNotification";

@interface WCSearchInputAccessoryView () <UIKeyInput, UITextInputTraits, UITextFieldDelegate, WCMomentarySegmentedControlDelegate>
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIView *inputAccessoryView; // You must override inputAccessoryView , since it's readonly by default

@property (nonatomic, assign) BOOL textFieldFocused;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *toolBar;
@property (nonatomic, strong) WCMomentarySegmentedControl *segmentedControl;
@property (nonatomic, strong) UILabel *searchTipLabel;
@property (nonatomic, strong) UITextField *searchTextField;

@property (nonatomic, assign) BOOL magnifierSelected;

@property (nonatomic, assign) BOOL expandToTop;
@property (nonatomic, assign) BOOL expandToBottom;

@property (nonatomic, copy) NSString *searchText;

@property (nonatomic, assign) WCSearchInputAccessoryViewExpandMode expandMode;

@end

@implementation WCSearchInputAccessoryView

#pragma mark -

- (instancetype)init {
    self = [super initWithFrame:CGRectMake(0, 0, 1, 1)];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        [self setup];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWCSearchInputAccessoryViewTextDidChangedNotification:) name:WCSearchInputAccessoryViewTextDidChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardDidShowNotification:) name:UIKeyboardDidShowNotification object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setup {
    
    // layout from top to bottom
    [self.toolBar addSubview:self.searchTipLabel];
    
    // layout from right to left
    [self.toolBar addSubview:self.segmentedControl];
    [self.toolBar addSubview:self.searchTextField];
    
    [self.containerView addSubview:self.toolBar];
    
    self.inputAccessoryView = self.containerView;
    self.inputAccessoryView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
}

#pragma mark - Public Methods

- (void)setSearchResultText:(NSString *)text animated:(BOOL)animated {
    self.searchTipLabel.text = text;
    if (self.expandMode == WCSearchInputAccessoryViewExpandModeNone) {
        [self setExpandMode:WCSearchInputAccessoryViewExpandModeTop animated:YES];
    }
}

- (void)setPreviousNavigateButtonEnabled:(BOOL)enabled {
    [self.segmentedControl setEnabled:enabled forSegmentAtIndex:0];
}

- (void)setNextNavigateButtonEnabled:(BOOL)enabled {
    [self.segmentedControl setEnabled:enabled forSegmentAtIndex:1];
}

- (void)setExpandMode:(WCSearchInputAccessoryViewExpandMode)mode animated:(BOOL)animated {
    
    self.expandMode = mode;
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    switch (mode) {
        case WCSearchInputAccessoryViewExpandModeNone:
        default: {
            
            self.containerView.frame = CGRectMake(0, 0, screenSize.width, TOOLBAR_NONE_H);
            [self.searchTextField reloadInputViews];
            
            self.toolBar.frame = CGRectMake(0, -(TOOLBAR_TOP_H - TOOLBAR_NONE_H), screenSize.width, TOOLBAR_TOP_H);
            
            CGRect frameSearchTextField = self.searchTextField.frame;
            frameSearchTextField.origin.y = SPACING_V;

            CGRect frameSegmentedControl = self.segmentedControl.frame;
            frameSegmentedControl.origin.y = SPACING_V;
            
            [UIView animateWithDuration:0.25 animations:^{
                self.toolBar.frame = CGRectMake(0, 0, screenSize.width, TOOLBAR_NONE_H);
                self.searchTextField.frame = frameSearchTextField;
                self.segmentedControl.frame = frameSegmentedControl;
            } completion:^(BOOL finished) {
            }];
            
            break;
        }
        case WCSearchInputAccessoryViewExpandModeTop: {
            
            self.containerView.frame = CGRectMake(0, 0, screenSize.width, TOOLBAR_TOP_H);
            [self.searchTextField reloadInputViews];
            
            self.toolBar.frame = CGRectMake(0, TOOLBAR_TOP_H - TOOLBAR_NONE_H, screenSize.width, TOOLBAR_NONE_H);
            
            CGRect frameSearchTextField = self.searchTextField.frame;
            frameSearchTextField.origin.y = SPACING_V + LABEL_H + SPACING_V;
            
            CGRect frameSegmentedControl = self.segmentedControl.frame;
            frameSegmentedControl.origin.y = SPACING_V + LABEL_H + SPACING_V;
            
            [UIView animateWithDuration:0.25 animations:^{
                self.toolBar.frame = CGRectMake(0, 0, screenSize.width, TOOLBAR_TOP_H);
                self.searchTextField.frame = frameSearchTextField;
                self.segmentedControl.frame = frameSegmentedControl;
            } completion:^(BOOL finished) {
            }];
            
            break;
        }
        case WCSearchInputAccessoryViewExpandModeBottom: {
            break;
        }
        case WCSearchInputAccessoryViewExpandModeTopBottom: {
            break;
        }
    }
}

#pragma mark - Getters

- (UIView *)containerView {
    if (!_containerView) {
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, TOOLBAR_NONE_H)];
        _containerView = view;
    }
    
    return _containerView;
}

- (UIView *)toolBar {
    if (!_toolBar) {
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, TOOLBAR_NONE_H)];
        view.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:1.0];
        view.layer.shadowColor = [UIColor darkGrayColor].CGColor;
        view.layer.shadowOpacity = 0.3f;
        view.layer.shadowOffset = CGSizeMake(0, -0.5);
        
        _toolBar = view;
    }
    
    return _toolBar;
}

- (WCMomentarySegmentedControl *)segmentedControl {
    if (!_segmentedControl) {
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        
        WCMomentarySegmentedControl *segmentedControl = [[WCMomentarySegmentedControl alloc] initWithItems:@[@" ＜ ", @" ＞ "]];
        segmentedControl.delegate = self;
        //        segmentedControl.backgroundColor = [UIColor greenColor];
        segmentedControl.frame = CGRectMake(CGRectGetMaxX(_searchTextField.frame) + 10, 0, 0, 0);
        [segmentedControl sizeToFit];
        [segmentedControl setEnabled:NO forSegmentAtIndex:0];
        [segmentedControl setEnabled:NO forSegmentAtIndex:1];
        
        CGRect frame = segmentedControl.frame;
        frame.size.height = TEXTFIELD_SEGEMENT_H;
        frame.origin.x = screenSize.width - segmentedControl.bounds.size.width - MARGIN_H;
        frame.origin.y = SPACING_V;
        
        segmentedControl.frame = frame;
        
        _segmentedControl = segmentedControl;
    }
    
    return _segmentedControl;
}

- (UITextField *)searchTextField {
    if (!_searchTextField) {
        
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        CGFloat width = screenSize.width - CGRectGetWidth(_segmentedControl.frame) - 3 * MARGIN_H;
        
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(MARGIN_H, SPACING_V, width, TEXTFIELD_SEGEMENT_H)];
        textField.backgroundColor = [UIColor whiteColor];
        textField.layer.cornerRadius = 2.0f;
        textField.layer.masksToBounds = YES;
        textField.layer.borderWidth = 1.0f;
        textField.layer.borderColor = [UIView new].tintColor.CGColor;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
//        textField.backgroundColor = [UIColor blueColor];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.returnKeyType = UIReturnKeySearch;
        textField.enablesReturnKeyAutomatically = YES;
        textField.delegate = self;
        
        // @see http://stackoverflow.com/questions/11811705/where-can-i-get-the-magnifying-glass-icon-used-in-uisearchbar
        UILabel *magnifier = [[UILabel alloc] init];
        magnifier.userInteractionEnabled = YES;
        [magnifier setText:[[NSString alloc] initWithUTF8String:" \xF0\x9F\x94\x8D⌄"]];
        [magnifier sizeToFit];
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(magnifierTapped:)];
        [magnifier addGestureRecognizer:tapRecognizer];
        self.magnifierSelected = NO;
        
        [textField setLeftView:magnifier];
        [textField setLeftViewMode:UITextFieldViewModeAlways];
        
        [textField addTarget:self action:@selector(searchTextFieldTextDidChanged:) forControlEvents:UIControlEventEditingChanged];
        
        _searchTextField = textField;
    }
    
    return _searchTextField;
}

- (UILabel *)searchTipLabel {
    if (!_searchTipLabel) {
        
        CGFloat marginT = 5.0f;
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(MARGIN_H, marginT, screenSize.width - 2 * MARGIN_H, LABEL_H)];
        label.text = @"找到1个匹配";
        label.font = SEARCH_TEXTFIELD_FONT;
        label.backgroundColor = [UIColor clearColor];
        
        _searchTipLabel = label;
    }
    
    return _searchTipLabel;
}

#pragma mark - UIKeyInput

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)hasText {
    return [self.text length];
}

- (void)insertText:(NSString *)text {
    NSString *selfText = self.text ? self.text : @"";
    self.text = [selfText stringByAppendingString:text];
    [[NSNotificationCenter defaultCenter] postNotificationName:WCSearchInputAccessoryViewTextDidChangedNotification object:self];
}

- (void)deleteBackward {
    if ([self.text length] > 0) {
        self.text = [self.text substringToIndex:([self.text length] - 1)];
    }
    else {
        self.text = nil;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:WCSearchInputAccessoryViewTextDidChangedNotification object:self];
}

#pragma mark - UITextInputTraits

- (UITextAutocapitalizationType)autocapitalizationType {
    return UITextAutocapitalizationTypeNone;
}

- (UITextAutocorrectionType)autocorrectionType {
    return UITextAutocorrectionTypeNo;
}

- (UIReturnKeyType)returnKeyType {
    return UIReturnKeySearch;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([self.delegate respondsToSelector:@selector(WCSearchInputAccessoryView:didSearchKey:)]) {
        self.searchText = [self.searchTextField.text copy];
        [self.delegate WCSearchInputAccessoryView:self didSearchKey:self.searchText];
    }
    
    return YES;
}

#pragma mark - WCMomentarySegmentedControlDelegate

- (void)WCMomentarySegmentedControl:(WCMomentarySegmentedControl *)segmentedControl clickedAtIndex:(NSInteger)index {
    NSLog(@"clicked at index %ld", (long)index);
    
    NSString *searchKey = [self.searchText copy];
    
    switch (index) {
        case 0: {
            // Previous
            if ([self.delegate respondsToSelector:@selector(WCSearchInputAccessoryView:navigateToPreviousKey:)]) {
                [self.delegate WCSearchInputAccessoryView:self navigateToPreviousKey:searchKey];
            }
            break;
        }
        case 1: {
            // Next
            if ([self.delegate respondsToSelector:@selector(WCSearchInputAccessoryView:navigateToNextKey:)]) {
                [self.delegate WCSearchInputAccessoryView:self navigateToNextKey:searchKey];
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark - NSNotification

- (void)handleWCSearchInputAccessoryViewTextDidChangedNotification:(NSNotification *)notification {
    // Just set the text here. notification.object is actually your inputObject.
    self.searchTextField.text = ((WCSearchInputAccessoryView *)(notification.object)).text;
}

- (void)handleKeyboardDidShowNotification:(NSNotification *)notification {
    
    // WARNING: UIKeyboardDidShowNotification maybe receive many times
    if (![self.searchTextField isFirstResponder] && [self isFirstResponder] && !self.textFieldFocused) {
        
        // Let textField show cursor when keyboard show up
        BOOL focused = [self.searchTextField becomeFirstResponder];
        if (focused) {
            self.textFieldFocused = YES;
        }
        NSLog(@"becomeFirstResponder");
    }
}

#pragma mark - Actions

- (void)magnifierTapped:(UITapGestureRecognizer *)recognizer {
    self.magnifierSelected = !self.magnifierSelected;
    
    UILabel *label = (UILabel *)recognizer.view;
    label.text = self.magnifierSelected ? @" \xF0\x9F\x94\x8D⌃" : @" \xF0\x9F\x94\x8D⌄";
    
    if (self.magnifierSelected) {
        
    }
    else {
        
    }
}

- (void)searchTextFieldTextDidChanged:(UITextField *)textField {
    if (textField.text.length == 0) {
        
    }
}

@end
