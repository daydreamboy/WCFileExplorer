//
//  WCInteractiveLabel.m
//  Pods
//
//  Created by wesley chen on 16/11/3.
//
//

#import "WCInteractiveLabel.h"

@interface WCInteractiveLabel ()
@property (nonatomic, assign) BOOL viewMenuEnabled;
@end

@implementation WCInteractiveLabel

#pragma mark - Public Methods

- (UIMenuItem *)viewMenuItem {
    self.viewMenuEnabled = YES;
    
    UIMenuItem *item = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"View", nil) action:@selector(view:)];
    
    return item;
}

#pragma mark

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        
        // @see http://stackoverflow.com/questions/6591044/uilabel-with-uimenucontroller-not-resigning-first-responder-with-touch-outside
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editMenuHidden) name:UIMenuControllerDidHideMenuNotification object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIMenuControllerDidHideMenuNotification object:nil];
}

// @see http://stackoverflow.com/questions/1246198/show-iphone-cut-copy-paste-menu-on-uilabel
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    
    if (action == @selector(copy:) && self.copyMenuEnabled) {
        return YES;
    }
    else if (action == @selector(view:) && self.viewMenuEnabled) {
        return YES;
    }
    
    return NO;
}


#pragma mark - NSNotification

- (void)editMenuHidden {
    [self resignFirstResponder];
}

#pragma mark - Actions (UIResponderStandardEditActions)

- (void)copy:(id)sender {
    [UIPasteboard generalPasteboard].string = self.text;
}

- (void)view:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:self.text delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
    [alert show];
}

@end
