//
//  WCContextMenuCell.h
//  Pods
//
//  Created by wesley chen on 16/11/4.
//
//

#import <UIKit/UIKit.h>

#import <WCFileExplorer/WCContextMenuItemDefines.h>

@class WCContextMenuCell;

@protocol WCContextMenuCellDelegate <NSObject>
- (void)contextMenuCell:(WCContextMenuCell *)cell contextMenuItemClicked:(WCContextMenuItem)item withSender:(id)sender;
@end

/*!
 *  WARNING: Conflict with default menu actions. If you use default menu for cell, please implement these methods instead of using WCContextMenuCell
 *
 - (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath;
 - (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender;
 - (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender;
 */
@interface WCContextMenuCell : UITableViewCell

/*!
 *  Showed context menu items' types, e.g. @(WCContextMenuItemView)
 *
 *  @warning If not defined, won't show context menu
 */
@property (nonatomic, strong) NSArray<NSNumber *> *contextMenuItemTypes;

/*!
 *  Showed context menu items' titles, related to `contextMenuItemTypes` <br/>
 *  If not defined, use default titles
 */
@property (nonatomic, strong) NSArray<NSString *> *contextMenuItemTitles;

/*!
 *  Allow menu items perform custom action
 */
@property (nonatomic, assign) WCContextMenuItem allowCustomActionContextMenuItems;
@property (nonatomic, weak) id<WCContextMenuCellDelegate> delegate;

/*!
 *  Show context menu centered on label. Default is YES
 */
@property (nonatomic, assign) BOOL showContextMenuAlwaysCenetered;

@end
