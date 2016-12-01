//
//  WCDirectoryBrowserViewController.h
//  WCFileExplorer
//
//  Created by wesley chen on 16/11/3.
//  Copyright © 2016年 wesley chen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WCPathItem : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy, readonly) NSString *path;
+ (instancetype)itemWithPath:(NSString *)path;
+ (instancetype)itemWithName:(NSString *)name path:(NSString *)path;
@end

@interface WCDirectoryBrowserViewController : UIViewController

+ (NSArray<WCPathItem *> *)favoritePathItems;
+ (void)deleteFavoritePathItemWithItem:(WCPathItem *)item;

- (instancetype)initWithPath:(NSString *)path;

@end
