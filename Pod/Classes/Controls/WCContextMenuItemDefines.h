//
//  WCContextMenuItemDefines.h
//  Pods
//
//  Created by wesley chen on 16/11/4.
//
//

#ifndef WCContextMenuItemDefines_h
#define WCContextMenuItemDefines_h

// Predefined Menu Items, and order is fixed
typedef NS_OPTIONS(NSUInteger, WCContextMenuItem) {
    WCContextMenuItemView       = 1 << 0, // 0
    WCContextMenuItemCopy       = 1 << 1, // 2
    WCContextMenuItemShare      = 1 << 2, // 4
    WCContextMenuItemProperty   = 1 << 3, // 8
    WCContextMenuItemFavorite   = 1 << 4,
};


#endif /* WCContextMenuItemDefines_h */
