//
//  WCImageBrowserViewController.m
//  Pods
//
//  Created by wesley chen on 17/1/6.
//
//

#import "WCImageBrowserViewController.h"
#import "WCImageZoomView.h"

@interface WCImageBrowserViewController () <UIScrollViewDelegate>
@property (nonatomic, strong) NSMutableSet *recycledPages;
@property (nonatomic, strong) NSMutableSet *visiblePages;
@property (nonatomic, strong) NSMutableArray *images;
@property (nonatomic, assign) NSUInteger firstShowedIndex;

@property (nonatomic, strong) UIScrollView *pagingScrollView;
@property (nonatomic, strong) UITapGestureRecognizer *singleTap;
@end

@implementation WCImageBrowserViewController

- (instancetype)initWithImages:(NSArray<UIImage *> *)images index:(NSUInteger)index {
    self = [super init];
    if (self) {
        _images = images;
        _firstShowedIndex = index;
        
        [self setup];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.view.backgroundColor = [UIColor whiteColor];
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pagingScrollViewSingleTapped:)];
    singleTap.numberOfTapsRequired = 1;
    self.singleTap = singleTap;
    
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
    scrollView.pagingEnabled = YES;
    scrollView.backgroundColor = [UIColor blackColor];
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.contentSize = CGSizeMake(pagingScrollViewFrame.size.width * [self imageCount], pagingScrollViewFrame.size.height);
    scrollView.delegate = self;
    [scrollView addGestureRecognizer:singleTap];
    [self.view addSubview:scrollView];
    self.pagingScrollView = scrollView;
 
    [self scrollToPage:_firstShowedIndex animated:NO];
}

#pragma mark

- (void)setup {
    _recycledPages = [NSMutableSet set];
    _visiblePages = [NSMutableSet set];
    
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
}

- (NSUInteger)imageCount {
    return [self.images count];
}

- (void)scrollToPage:(NSUInteger)page animated:(BOOL)animated {
    
    NSAssert(page >= 0 && page < [self imageCount], @"page %d out of bounds[0...%d]", page, [self imageCount]);
    
    if (page) {
        CGRect rect = CGRectMake(page * CGRectGetWidth(self.pagingScrollView.bounds), 0, CGRectGetWidth(self.pagingScrollView.bounds), CGRectGetHeight(self.pagingScrollView.bounds));
        [self.pagingScrollView scrollRectToVisible:rect animated:animated];
    }
    else {
        [self tilePages];
    }
}

- (void)tilePages {
    CGRect visibleBounds = self.pagingScrollView.bounds;
    
    NSInteger firstNeededPageIndex = floorf(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds));
    NSInteger lastNeededPageIndex = floorf((CGRectGetMaxX(visibleBounds) - 1) / CGRectGetWidth(visibleBounds));
    
    firstNeededPageIndex = MAX(firstNeededPageIndex, 0);
    lastNeededPageIndex  = MIN(lastNeededPageIndex, [self imageCount] - 1);
    
    for (WCImageZoomView *page in self.visiblePages) {
        if (page.index < firstNeededPageIndex || page.index > lastNeededPageIndex) {
            [self.recycledPages addObject:page];
            [page removeFromSuperview];
        }
    }
    [self.visiblePages minusSet:self.recycledPages];
    
    for (NSUInteger index = firstNeededPageIndex; index <= lastNeededPageIndex; index++) {
        if (![self isDisplayingPageForIndex:index]) {
            WCImageZoomView *page = [self dequeueRecycledPage];
            if (page == nil) {
                page = [[WCImageZoomView alloc] init];
            }
            // configure page's frame and image
            [self configurePage:page forIndex:index];
            [self.pagingScrollView addSubview:page];
            [self.visiblePages addObject:page];
        }
    }
}

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index {
    BOOL foundPage = NO;
    for (WCImageZoomView *page in self.visiblePages) {
        if (page.index == index) {
            foundPage = YES;
            break;
        }
    }
    return foundPage;
}

- (WCImageZoomView *)dequeueRecycledPage {
    WCImageZoomView *page = [self.recycledPages anyObject];
    if (page) {
        [self.recycledPages removeObject:page];
    }
    return page;
}

- (void)configurePage:(WCImageZoomView *)page forIndex:(NSUInteger)index {
    page.index = index;
    page.frame = [self frameForPageAtIndex:index];
    
    [page displayImage:self.images[index]];
    [self.singleTap requireGestureRecognizerToFail:page.doubleTapGesture];
}

- (NSUInteger)currentPageIndexWithScrollView:(UIScrollView *)scrollView {
    CGFloat pagingScrollViewWidth = scrollView.frame.size.width;
    NSUInteger index = floor((scrollView.contentOffset.x - pagingScrollViewWidth / 2.0) / pagingScrollViewWidth) + 1;
    
    index = MAX(index, 0);
    index = MIN(index, [self imageCount] - 1);
    
    return index;
}

#pragma mark - Frame Calculation

#define PADDING  10

- (CGRect)frameForPagingScrollView {
    CGRect frame = [[UIScreen mainScreen] bounds];
    frame.origin.x -= PADDING;
    frame.size.width += (2 * PADDING);
    return frame;
}
                  
- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    
    CGRect pageFrame = pagingScrollViewFrame;
    pageFrame.size.width -= (2 * PADDING);
    pageFrame.origin.x = pagingScrollViewFrame.size.width * index + PADDING;
    
    return pageFrame;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self tilePages];
    
    NSUInteger pageIndex = [self currentPageIndexWithScrollView:self.pagingScrollView];
}

#pragma mark - Actions

- (void)pagingScrollViewSingleTapped:(UITapGestureRecognizer *)recognizer {
    
}

@end
