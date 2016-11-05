//
//  WCInteractiveLabel.h
//  Pods
//
//  Created by wesley chen on 16/11/3.
//
//

#import <UIKit/UIKit.h>

#import <WCFileExplorer/WCContextMenuItemDefines.h>

@class WCInteractiveLabel;

@protocol WCInteractiveLabelDelegate <NSObject>
- (void)interactiveLabel:(WCInteractiveLabel *)label contextMenuItemClicked:(WCContextMenuItem)item withSender:(id)sender;
@end

@interface WCInteractiveLabel : UILabel

@property (nonatomic, assign) WCContextMenuItem contextMenuItems;                   /**< showed context menu items */
@property (nonatomic, assign) WCContextMenuItem allowCustomActionContextMenuItems;  /**< allow menu items perform custom action */
@property (nonatomic, weak) id<WCInteractiveLabelDelegate> delegate;
@property (nonatomic, assign) BOOL showContextMenuAlwaysCenetered;                  /**< show context menu centered on label. Default is YES */

@end
