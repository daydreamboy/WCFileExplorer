//
//  WCInteractiveLabel.h
//  Pods
//
//  Created by wesley chen on 16/11/3.
//
//

#import <UIKit/UIKit.h>

@interface WCInteractiveLabel : UILabel

@property (nonatomic, assign) BOOL copyMenuEnabled;

// Custom menu items
- (UIMenuItem *)viewMenuItem;

@end
