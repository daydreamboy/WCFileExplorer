//
//  WCContextMenuCell.m
//  Pods
//
//  Created by wesley chen on 16/11/4.
//
//

#import "WCContextMenuCell.h"

@interface WCContextMenuCell ()
@property (nonatomic, assign) WCContextMenuItem contextMenuItemOptions;
@end

@implementation WCContextMenuCell

#pragma mark - Public Methods

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.showContextMenuAlwaysCenetered = YES;
        
        // @see http://stackoverflow.com/questions/6591044/uilabel-with-uimenucontroller-not-resigning-first-responder-with-touch-outside
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMenuControllerDidHideMenuNotification:) name:UIMenuControllerDidHideMenuNotification object:nil];
        
        UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(cellLongPressed:)];
        // Avoid hightlight aborting when long pressed
        longPressRecognizer.cancelsTouchesInView = NO;
        [self addGestureRecognizer:longPressRecognizer];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIMenuControllerDidHideMenuNotification object:nil];
}

- (BOOL)canBecomeFirstResponder {
    NSLog(@"_cmd: %@", NSStringFromSelector(_cmd));
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
        else if (action == @selector(shareAction:) && (self.contextMenuItemOptions & WCContextMenuItemShare)) {
            return YES;
        }
        else if (action == @selector(propertyAction:) && (self.contextMenuItemOptions & WCContextMenuItemProperty)) {
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
        else if (option & WCContextMenuItemShare) {
            NSString *title = itemTitle.length ? itemTitle : NSLocalizedString(@"Share", nil);
            [items addObject:[[UIMenuItem alloc] initWithTitle:title action:@selector(shareAction:)]];
        }
        else if (option & WCContextMenuItemProperty) {
            NSString *title = itemTitle.length ? itemTitle : NSLocalizedString(@"Property", nil);
            [items addObject:[[UIMenuItem alloc] initWithTitle:title action:@selector(propertyAction:)]];
        }
    }
    
    return items;
}

#pragma mark > Menu Item Actions (without UIResponderStandardEditActions)

- (void)viewAction:(id)sender {
    if (self.allowCustomActionContextMenuItems & WCContextMenuItemView) {
        if ([self.delegate respondsToSelector:@selector(contextMenuCell:contextMenuItemClicked:withSender:)]) {
            [self.delegate contextMenuCell:self contextMenuItemClicked:WCContextMenuItemView withSender:self];
        }
    }
    else {
        // Default action
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:self.text delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
        [alert show];
    }
}

- (void)copyAction:(id)sender {
    if (self.allowCustomActionContextMenuItems & WCContextMenuItemCopy) {
        if ([self.delegate respondsToSelector:@selector(contextMenuCell:contextMenuItemClicked:withSender:)]) {
            [self.delegate contextMenuCell:self contextMenuItemClicked:WCContextMenuItemCopy withSender:self];
        }
    }
    else {
        // Default action
        [UIPasteboard generalPasteboard].string = self.textLabel.text;
    }
}

- (void)shareAction:(id)sender {
    if (self.allowCustomActionContextMenuItems & WCContextMenuItemShare) {
        if ([self.delegate respondsToSelector:@selector(contextMenuCell:contextMenuItemClicked:withSender:)]) {
            [self.delegate contextMenuCell:self contextMenuItemClicked:WCContextMenuItemShare withSender:self];
        }
    }
    else {
        // Default action
        // do nothing here
    }
}

- (void)propertyAction:(id)sender {
    if (self.allowCustomActionContextMenuItems & WCContextMenuItemProperty) {
        if ([self.delegate respondsToSelector:@selector(contextMenuCell:contextMenuItemClicked:withSender:)]) {
            [self.delegate contextMenuCell:self contextMenuItemClicked:WCContextMenuItemProperty withSender:self];
        }
    }
    else {
        // Default action
        // do nothing here
    }
}

#pragma mark - NSNotification

- (void)handleMenuControllerDidHideMenuNotification:(NSNotification *)notification {
//    NSLog(@"_cmd: %@", NSStringFromSelector(_cmd));
    [self resignFirstResponder];
}

#pragma mark - Handle long press gestures

- (void)cellLongPressed:(UILongPressGestureRecognizer *)recognizer {
    // @see http://nshipster.com/uimenucontroller/
    if (recognizer.state == UIGestureRecognizerStateRecognized) {
        NSLog(@"_cmd: %@", NSStringFromSelector(_cmd));
        WCContextMenuCell *label = (WCContextMenuCell *)recognizer.view;
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
        
        // Prevent - tableView:didSelectRowAtIndexPath: called after long pressed
        recognizer.cancelsTouchesInView = YES;
    }
}

@end
