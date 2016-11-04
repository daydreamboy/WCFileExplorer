//
//  WCInteractiveLabel.m
//  Pods
//
//  Created by wesley chen on 16/11/3.
//
//

#import "WCInteractiveLabel.h"

@interface WCInteractiveLabel ()
@end

@implementation WCInteractiveLabel


#pragma mark

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        
        // @see http://stackoverflow.com/questions/6591044/uilabel-with-uimenucontroller-not-resigning-first-responder-with-touch-outside
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMenuControllerDidHideMenuNotification:) name:UIMenuControllerDidHideMenuNotification object:nil];
        
        UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(labelLongPressed:)];
        [self addGestureRecognizer:longPressRecognizer];
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

#pragma mark - Configure Custom Menu Items

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    
    if (action == @selector(viewText:) && (self.contextMenuItems & WCContextMenuItemView)) {
        return YES;
    }
    else if (action == @selector(copyText:) && (self.contextMenuItems & WCContextMenuItemCopy)) {
        return YES;
    }
    
    return NO;
}

- (NSArray *)customMenuItems {
    NSMutableArray *items = [NSMutableArray array];
    
    // Define menu item order here
    if (self.contextMenuItems & WCContextMenuItemView) {
        [items addObject:[[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"View", nil) action:@selector(viewText:)]];
    }
    
    if (self.contextMenuItems & WCContextMenuItemCopy) {
        [items addObject:[[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy", nil) action:@selector(copyText:)]];
    }
    
    return items;
}

#pragma mark > Menu Item Actions (without UIResponderStandardEditActions)

- (void)viewText:(id)sender {
    if (self.allowCustomActionContextMenuItems & WCContextMenuItemView) {
        if ([self.delegate respondsToSelector:@selector(contextMenuItemClicked:withSender:)]) {
            [self.delegate contextMenuItemClicked:WCContextMenuItemView withSender:self];
        }
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:self.text delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
        [alert show];
    }
}

- (void)copyText:(id)sender {
    if (self.allowCustomActionContextMenuItems & WCContextMenuItemCopy) {
        if ([self.delegate respondsToSelector:@selector(contextMenuItemClicked:withSender:)]) {
            [self.delegate contextMenuItemClicked:WCContextMenuItemCopy withSender:self];
        }
    }
    else {
        [UIPasteboard generalPasteboard].string = self.text;
    }
}

#pragma mark - NSNotification

- (void)handleMenuControllerDidHideMenuNotification:(NSNotification *)notification {
    [self resignFirstResponder];
}

#pragma mark - Handle long press gestures

- (void)labelLongPressed:(UILongPressGestureRecognizer *)recognizer {
    // @see http://nshipster.com/uimenucontroller/
    if (recognizer.state == UIGestureRecognizerStateRecognized) {
        WCInteractiveLabel *label = (WCInteractiveLabel *)recognizer.view;
        CGPoint location = [recognizer locationInView:recognizer.view];
        
        [recognizer.view becomeFirstResponder];
        
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        [menuController setMenuItems:[self customMenuItems]];
        // show menu in cener
        if (self.showContextMenuAlwaysCenetered) {
            [menuController setTargetRect:recognizer.view.frame inView:recognizer.view.superview];
        }
        else {
            // show menu on tapping point
            // @see http://stackoverflow.com/questions/1146587/how-to-get-uimenucontroller-work-for-a-custom-view
            [menuController setTargetRect:CGRectMake(location.x, location.y, 0.0f, 0.0f) inView:recognizer.view];
        }
        
        [menuController setMenuVisible:YES animated:YES];
    }
}

@end
