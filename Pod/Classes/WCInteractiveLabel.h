//
//  WCInteractiveLabel.h
//  Pods
//
//  Created by wesley chen on 16/11/3.
//
//

#import <UIKit/UIKit.h>

// Predefined Menu Items, and order is fixed
typedef NS_OPTIONS(NSUInteger, WCContextMenuItem) {
    WCContextMenuItemView = 1 << 0,
    WCContextMenuItemCopy = 1 << 1,
};

@protocol WCInteractiveLabelDelegate <NSObject>
- (void)contextMenuItemClicked:(WCContextMenuItem)item withSender:(id)sender;
@end

@interface WCInteractiveLabel : UILabel

@property (nonatomic, assign) WCContextMenuItem contextMenuItems;
@property (nonatomic, assign) WCContextMenuItem allowCustomActionContextMenuItems;
@property (nonatomic, weak) id<WCInteractiveLabelDelegate> delegate;

@end
