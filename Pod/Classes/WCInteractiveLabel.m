//
//  WCInteractiveLabel.m
//  Pods
//
//  Created by wesley chen on 16/11/3.
//
//

#import "WCInteractiveLabel.h"

@interface WCInteractiveLabel ()
@property (nonatomic, assign) WCContextMenuItem contextMenuItemOptions;
@end

@implementation WCInteractiveLabel

#pragma mark

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.showContextMenuAlwaysCenetered = YES;
        
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

- (void)setContextMenuItemTypes:(NSArray<NSNumber *> *)contextMenuItemTypes {
    _contextMenuItemTypes = contextMenuItemTypes;
    
    if (self.contextMenuItemTypes.count) {
        WCContextMenuItem options = kNilOptions;
        
        for (NSNumber *number in self.contextMenuItemTypes) {
            WCContextMenuItem opt = [number unsignedIntegerValue];
            options = options | opt;
        }
        
        self.contextMenuItemOptions = options;
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    
    if (self.contextMenuItemTypes.count) {
        
        // Test actions and options
        if (action == @selector(viewAction:) && (self.contextMenuItemOptions & WCContextMenuItemView)) {
            return YES;
        }
        else if (action == @selector(copyAction:) && (self.contextMenuItemOptions & WCContextMenuItemCopy)) {
            return YES;
        }
        else {
            return NO;
        }
    }
    else {
        // No menu items defined
        return NO;
    }
}

- (NSArray *)customMenuItems {
    NSMutableArray *items = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < [self.contextMenuItemTypes count]; i++) {
        WCContextMenuItem option = [self.contextMenuItemTypes[i] unsignedIntegerValue];
        
        NSString *itemTitle = i < [self.contextMenuItemTitles count] ? self.contextMenuItemTitles[i] : nil;
        
        if (option & WCContextMenuItemView) {
            NSString *title = itemTitle.length ? itemTitle : NSLocalizedString(@"View", nil);
            [items addObject:[[UIMenuItem alloc] initWithTitle:title action:@selector(viewAction:)]];
        }
        else if (option & WCContextMenuItemCopy) {
            NSString *title = itemTitle.length ? itemTitle : NSLocalizedString(@"Copy", nil);
            [items addObject:[[UIMenuItem alloc] initWithTitle:title action:@selector(copyAction:)]];
        }
    }
    
    return items;
}


#pragma mark > Menu Item Actions (without UIResponderStandardEditActions)

- (void)viewAction:(id)sender {
    if (self.allowCustomActionContextMenuItems & WCContextMenuItemView) {
        if ([self.delegate respondsToSelector:@selector(interactiveLabel:contextMenuItemClicked:withSender:)]) {
            [self.delegate interactiveLabel:self contextMenuItemClicked:WCContextMenuItemView withSender:self];
        }
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:self.text delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
        [alert show];
    }
}

- (void)copyAction:(id)sender {
    if (self.allowCustomActionContextMenuItems & WCContextMenuItemCopy) {
        if ([self.delegate respondsToSelector:@selector(interactiveLabel:contextMenuItemClicked:withSender:)]) {
            [self.delegate interactiveLabel:self contextMenuItemClicked:WCContextMenuItemCopy withSender:self];
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
