//
//  WCImageZoomView.h
//  Pods
//
//  Created by wesley chen on 17/1/7.
//
//

#import <UIKit/UIKit.h>

@interface WCImageZoomView : UIScrollView <UIScrollViewDelegate>

@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGesture;

- (void)displayImage:(UIImage *)image;

@end
