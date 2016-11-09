//
//  WCSearchInputAccessoryView.h
//  Pods
//
//  Created by wesley chen on 16/11/7.
//
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, WCSearchInputAccessoryViewExpandMode) {
    WCSearchInputAccessoryViewExpandModeNone,
    WCSearchInputAccessoryViewExpandModeTop,
    WCSearchInputAccessoryViewExpandModeBottom,
    WCSearchInputAccessoryViewExpandModeTopBottom,
};

@class WCSearchInputAccessoryView;

@protocol WCSearchInputAccessoryViewDelegate <NSObject>

- (void)WCSearchInputAccessoryView:(WCSearchInputAccessoryView *)view didSearchKey:(NSString *)searchKey;
- (void)WCSearchInputAccessoryView:(WCSearchInputAccessoryView *)view navigateToPreviousKey:(NSString *)searchKey;
- (void)WCSearchInputAccessoryView:(WCSearchInputAccessoryView *)view navigateToNextKey:(NSString *)searchKey;

@end

@interface WCSearchInputAccessoryView : UIView

@property (nonatomic, weak) id<WCSearchInputAccessoryViewDelegate> delegate;

- (void)setSearchResultText:(NSString *)text animated:(BOOL)animated;
- (void)setPreviousNavigateButtonEnabled:(BOOL)enabled;
- (void)setNextNavigateButtonEnabled:(BOOL)enabled;

@end
