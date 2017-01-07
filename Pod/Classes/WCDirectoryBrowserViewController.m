//
//  WCDirectoryBrowserViewController.m
//  WCFileExplorer
//
//  Created by wesley chen on 16/11/3.
//  Copyright © 2016年 wesley chen. All rights reserved.
//

#import "WCDirectoryBrowserViewController.h"

#import <WCFileExplorer/WCInteractiveLabel.h>
#import <WCFileExplorer/WCContextMenuCell.h>
#import <WCFileExplorer/WCTextEditViewController.h>
#import <WCFileExplorer/WCImageBrowserViewController.h>
#import <objc/runtime.h>

#define SectionHeader_H                 40.0f

#define WC_FAVORITE_PATHS_PLIST_PATH    [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/WCFileExplorer/favorite_paths.plist"]

typedef NS_ENUM(NSUInteger, WCPathType) {
    WCPathTypeUnknown,  /**< the other paths */
    WCPathTypeHome,     /**< the path has home folder */
    WCPathTypeBundle,   /**< the path has bundle folder */
};

NSString *WCPathTypeUnknownKey = @"unknown";
NSString *WCPathTypeHomeKey = @"home";
NSString *WCPathTypeBundleKey = @"bundle";

static NSString *NSStringFromWCPathType(WCPathType pathType)
{
    switch (pathType) {
        case WCPathTypeUnknown:
        default:
            return WCPathTypeUnknownKey;
        case WCPathTypeHome:
            return WCPathTypeHomeKey;
        case WCPathTypeBundle:
            return WCPathTypeBundleKey;
    }
}

@interface WCPathItem ()
@property (nonatomic, copy, readwrite) NSString *path;
@property (nonatomic, copy) NSString *relativePath;
@property (nonatomic, assign) WCPathType pathType;
@end

@implementation WCPathItem
+ (instancetype)itemWithPath:(NSString *)path {
    WCPathItem *item = [[WCPathItem alloc] init];
    item.path = path;
    return item;
}

+ (instancetype)itemWithName:(NSString *)name path:(NSString *)path {
    WCPathItem *item = [self itemWithPath:path];
    item.name = name;
    return item;
}
@end

// File Attributes
static NSString *WCFileAttributeFileSize = @"WCFileAttributeFileSize"; /*! size of file, or size of total files in a directory */
static NSString *WCFileAttributeIsDirectory = @"WCFileAttributeIsDirectory";
static NSString *WCFileAttributeNumberOfFilesInDirectory = @"WCFileAttributeNumberOfFilesInDirectory";

@interface WCDirectoryBrowserViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, WCInteractiveLabelDelegate, WCContextMenuCellDelegate, UIActionSheetDelegate>
@property (nonatomic, copy) NSString *pwdPath;  /**< current folder path */
@property (nonatomic, strong) NSArray *files;   /**< list name of files */
@property (nonatomic, strong) NSArray *filesFiltered; /**< list name of filtered files */
@property (nonatomic, strong) NSMutableDictionary *fileAttributes; /**< attributes of files */

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIDocumentInteractionController *documentController;

@property (nonatomic, strong) WCInteractiveLabel *labelTitle;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, assign) BOOL isSearching;

@property (nonatomic, strong) NSMutableArray *imageFiles;

@end

@interface UIView (WCDirectoryBrowserViewController)
@property (nonatomic, strong) id userInfo;
@end

@implementation UIView (WCDirectoryBrowserViewController)
static const char * const UIView_WCDirectoryBrowserViewController_UserInfoObjectTag = "UIView_Frame_UserInfoObjectTag";
@dynamic userInfo;
- (void)setUserInfo:(id)userInfo {
    objc_setAssociatedObject(self, UIView_WCDirectoryBrowserViewController_UserInfoObjectTag, userInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (id)userInfo {
    return objc_getAssociatedObject(self, UIView_WCDirectoryBrowserViewController_UserInfoObjectTag);
}
@end

@implementation WCDirectoryBrowserViewController

#pragma mark - Public Methods

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        _pwdPath = path;
    }
    return self;
}

+ (NSArray<WCPathItem *> *)favoritePathItems {
    NSMutableArray<WCPathItem *> *arrM = [NSMutableArray array];
    
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:WC_FAVORITE_PATHS_PLIST_PATH];
    
    if ([dict isKindOfClass:[NSDictionary class]]) {
        
        for (NSString *path in dict[WCPathTypeHomeKey]) {
            WCPathItem *item = [WCPathItem itemWithPath:[NSHomeDirectory() stringByAppendingPathComponent:path]];
            item.pathType = WCPathTypeHome;
            item.relativePath = path;
            [arrM addObject:item];
        }
        
        for (NSString *path in dict[WCPathTypeBundleKey]) {
            WCPathItem *item = [WCPathItem itemWithPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:path]];
            item.pathType = WCPathTypeBundle;
            item.relativePath = path;
            [arrM addObject:item];
        }
        
        for (NSString *path in dict[WCPathTypeUnknownKey]) {
            WCPathItem *item = [WCPathItem itemWithPath:path];
            item.pathType = WCPathTypeUnknown;
            item.relativePath = path;
            [arrM addObject:item];
        }
    }

    return arrM;
}

+ (void)deleteFavoritePathItemWithItem:(WCPathItem *)item {
    WCPathType pathType = item.pathType;
    
    NSMutableDictionary *plistDictM = [NSMutableDictionary dictionary];
    
    NSData *data = [NSData dataWithContentsOfFile:WC_FAVORITE_PATHS_PLIST_PATH];
    NSMutableDictionary *dictM = (NSMutableDictionary *)[NSPropertyListSerialization
                                                         propertyListFromData:data
                                                         mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                                         format:0
                                                         errorDescription:nil];
    
    [plistDictM addEntriesFromDictionary:dictM];
    
    NSMutableArray *arrM = [NSMutableArray arrayWithArray:dictM[NSStringFromWCPathType(pathType)]];
    
    NSString *pathToRemove = nil;
    for (NSString *path in arrM) {
        if ([path isEqualToString:item.relativePath]) {
            pathToRemove = path;
            break;
        }
    }
    
    if (pathToRemove) {
        [arrM removeObject:pathToRemove];
        plistDictM[NSStringFromWCPathType(pathType)] = arrM;
        
        BOOL success = [plistDictM writeToFile:WC_FAVORITE_PATHS_PLIST_PATH atomically:YES];
        if (!success) {
            NSLog(@"delete path failed");
        }
    }
}

#pragma mark

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([self respondsToSelector:@selector(setAutomaticallyAdjustsScrollViewInsets:)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.tableView];
    
    self.labelTitle.text = self.pwdPath;
    [self.labelTitle sizeToFit];
    
    self.navigationItem.titleView = self.labelTitle;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.pwdPath.length) {
        NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.pwdPath error:nil];
        self.files = [fileNames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        self.filesFiltered = [self.files copy];
        
        [self parseAttributesOfFiles];
    }
    
    if (self.isSearching) {
        [self.tableView setContentOffset:CGPointMake(0, 0) animated:NO];
    }
    else {
        [self.tableView setContentOffset:CGPointMake(0, CGRectGetHeight(self.searchBar.frame)) animated:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.imageFiles = [NSMutableArray array];
    
    for (NSString *file in self.filesFiltered) {
        if ([self fileIsPicture:file]) {
            [self.imageFiles addObject:file];
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Getters

- (WCInteractiveLabel *)labelTitle {
    if (!_labelTitle) {
        WCInteractiveLabel *label = [[WCInteractiveLabel alloc] initWithFrame:CGRectZero];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:15.0f];
        label.lineBreakMode = NSLineBreakByTruncatingHead;
        label.textColor = [UIColor blueColor];
        label.contextMenuItemTypes = @[ @(WCContextMenuItemCopy), @(WCContextMenuItemView)];
        label.delegate = self;
        label.showContextMenuAlwaysCenetered = YES;
        
        _labelTitle = label;
    }
    
    return _labelTitle;
}

- (UITableView *)tableView {
    if (!_tableView) {
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        CGFloat topInset = 64.0f;
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, topInset, screenSize.width, screenSize.height - topInset) style:UITableViewStyleGrouped];
        tableView.delegate = self;
        tableView.dataSource = self;
        
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, 44)];
        searchBar.delegate = self;
        searchBar.returnKeyType = UIReturnKeyDone;
        _searchBar = searchBar;
        
        tableView.tableHeaderView = searchBar;
        
        _tableView = tableView;
    }
    
    return _tableView;
}

#pragma mark

- (void)parseAttributesOfFiles {
    NSMutableArray *directories = [NSMutableArray array];
    
    NSMutableDictionary *dictM = [NSMutableDictionary dictionary];
    for (NSString *fileName in self.files) {
        
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        NSString *path = [self pathForFile:fileName];
        NSArray *subFileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
        
        BOOL isDirectory = NO;
        unsigned long long fileSize = [self sizefFileAtPath:path isDirectory:&isDirectory];
        
        attributes[WCFileAttributeIsDirectory] = @(isDirectory);
        if (!isDirectory) {
            // file
            attributes[WCFileAttributeFileSize] = @(fileSize);
        }
        else {
            // directory
            attributes[WCFileAttributeNumberOfFilesInDirectory] = @(subFileNames.count);
            [directories addObject:[fileName copy]];
        }
        
        if (attributes.count) {
            dictM[fileName] = attributes;
        }
    }
    self.fileAttributes = dictM;
    
    // calculate folder size
    if (directories.count) {
        __weak typeof(self) weak_self = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            for (NSString *fileName in directories) {
                if (weak_self == nil) {
                    // if the current view controller not exists, just abort loop
                    return;
                }
                
                NSString *path = [self pathForFile:fileName];
                NSError *error = nil;
                unsigned long long totalSize = [self sizeOfDirectoryAtPath:path error:&error];
                
                NSMutableDictionary *attributes = weak_self.fileAttributes[fileName];
                attributes[WCFileAttributeFileSize] = (error == nil ? @(totalSize) : error);
                
                // once a folder size is calculated, refresh table view to be more real time
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong WCDirectoryBrowserViewController *strong_self = weak_self;
                    [strong_self.tableView reloadData];
                });
            }
            
            // after all folders' size is calculated, refresh table view
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong WCDirectoryBrowserViewController *strong_self = weak_self;
                [strong_self.tableView reloadData];
            });
        });
    }
}

#pragma mark - Utility

- (NSString *)pathForFile:(NSString *)file {
    return [self.pwdPath stringByAppendingPathComponent:file];
}

- (unsigned long long)sizefFileAtPath:(NSString *)path isDirectory:(BOOL *)isDirectory {
    BOOL isDirectoryL = NO;
    BOOL isExisted = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectoryL];
    
    *isDirectory = isDirectoryL;
    if (isDirectoryL || !isExisted) {
        // If the path is a directory, or no file at the path exists
        return 0;
    }
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    
    return [attributes[NSFileSize] unsignedLongLongValue];
}

- (unsigned long long)sizeOfDirectoryAtPath:(NSString *)path error:(NSError **)error {
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:path error:error];
    if (*error) {
        NSLog(@"error: %@", *error);
    }
    NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
    NSString *fileName;
    unsigned long long fileSize = 0;
    
    while (fileName = [filesEnumerator nextObject]) {
        NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[path stringByAppendingPathComponent:fileName] error:nil];
        fileSize += [fileDictionary fileSize];
    }
    
    return fileSize;
}

- (NSString *)prettySizeWithBytes:(unsigned long long)bytes {
    NSString *sizeString = [NSByteCountFormatter stringFromByteCount:bytes countStyle:NSByteCountFormatterCountStyleFile];
    return sizeString;
}
         
#pragma mark > Check Files

- (BOOL)fileIsDirectory:(NSString *)file {
    BOOL isDir = NO;
    NSString *path = [self pathForFile:file];
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    return isDir;
}

- (BOOL)fileIsPlist:(NSString *)file {
    return [[file.lowercaseString pathExtension] isEqualToString:@"plist"];
}

- (BOOL)fileIsPicture:(NSString *)file {
    NSString *ext = [[file pathExtension] lowercaseString];
    
    return [ext isEqualToString:@"png"] || [ext isEqualToString:@"jpg"];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.filesFiltered count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *sCellIdentifier = @"Cell";
    
    WCContextMenuCell *cell = (WCContextMenuCell *)[tableView dequeueReusableCellWithIdentifier:sCellIdentifier];
    if (cell == nil) {
        cell = [[WCContextMenuCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:sCellIdentifier];
        cell.textLabel.font = [UIFont systemFontOfSize:16.0];
    }
    
    NSString *file = [self.filesFiltered objectAtIndex:indexPath.row];
    NSString *path = [self pathForFile:file];
    
    NSDictionary *attributes = self.fileAttributes[file];
    BOOL isDir = [attributes[WCFileAttributeIsDirectory] boolValue];
    
    cell.textLabel.text = file;
    cell.textLabel.textColor = isDir ? [UIColor blueColor] : [UIColor darkTextColor];
    
    NSString *sizeString = nil;
    if (attributes[WCFileAttributeFileSize] == nil) {
        sizeString = @"Computing size...";
    }
    else {
        if ([attributes[WCFileAttributeFileSize] isKindOfClass:[NSError class]]) {
            NSError *error = (NSError *)attributes[WCFileAttributeFileSize];
            sizeString = error.localizedDescription;
        }
        else {
            sizeString = [self prettySizeWithBytes:[attributes[WCFileAttributeFileSize] unsignedLongLongValue]];
        }
    }

    if (!isDir) {
        // file
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", sizeString];
    }
    else {
        // directory
        NSString *unit = [attributes[WCFileAttributeNumberOfFilesInDirectory] isEqualToNumber:@(1)] ? @"file" : @"files";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@ (%@)", attributes[WCFileAttributeNumberOfFilesInDirectory], unit, sizeString];
    }
    cell.detailTextLabel.textColor = [UIColor grayColor];
    cell.accessoryType = isDir ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    
    if (isDir) {
        cell.contextMenuItemTypes = @[ @(WCContextMenuItemView), @(WCContextMenuItemCopy), @(WCContextMenuItemFavorite), @(WCContextMenuItemDeletion) ];
        cell.contextMenuItemTitles = @[ @"View Path", @"Copy Path", @"Bookmark", @"Delete" ];
    }
    else {
        cell.contextMenuItemTypes = @[ @(WCContextMenuItemView), @(WCContextMenuItemCopy), @(WCContextMenuItemShare), @(WCContextMenuItemProperty), @(WCContextMenuItemFavorite), @(WCContextMenuItemDeletion) ];
        cell.contextMenuItemTitles = @[ @"View Path", @"Copy Path", @"Export File", @"View Property", @"Bookmark", @"Delete" ];
    }
    cell.allowCustomActionContextMenuItems = WCContextMenuItemView | WCContextMenuItemCopy | WCContextMenuItemShare | WCContextMenuItemProperty | WCContextMenuItemFavorite | WCContextMenuItemDeletion;
    cell.delegate = self;
    
    if ([self fileIsPicture:file]) {
        UIImage *img = [UIImage imageWithContentsOfFile:path];
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        cell.imageView.image = img;
    }
    else {
        cell.imageView.image = nil;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    CGFloat paddingT = 15.0f;
    CGFloat paddingL = 15.0f;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, SectionHeader_H)];
    
    if ([self.filesFiltered count]) {
        NSString *loadingTip = nil;
        unsigned long long totalSize = 0;
        
        for (NSString *file in self.filesFiltered) {
            NSDictionary *attributes = self.fileAttributes[file];
            if (attributes[WCFileAttributeFileSize] == nil) {
                loadingTip = @"Computing size...";
                break;
            }
            else {
                if ([attributes[WCFileAttributeFileSize] isKindOfClass:[NSNumber class]]) {
                    totalSize += [attributes[WCFileAttributeFileSize] unsignedLongLongValue];
                }
            }
        }
        
        NSString *unit = [self.filesFiltered count] == 1 ? @"item" : @"items";
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(paddingL, paddingT, screenSize.width - paddingL, 20)];
        label.text = [NSString stringWithFormat:@"%lu %@ (%@)", (unsigned long)[self.filesFiltered count], unit, loadingTip == nil ? [self prettySizeWithBytes:totalSize] : loadingTip];
        label.font = [UIFont systemFontOfSize:14.0f];
        label.textColor = [UIColor darkGrayColor];
        
        [view addSubview:label];
    }
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return SectionHeader_H;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *file = self.filesFiltered[indexPath.row];
    NSString *path = [self pathForFile:file];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    if ([self fileIsDirectory:file]) {
        WCDirectoryBrowserViewController *vc = [[WCDirectoryBrowserViewController alloc] initWithPath:path];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if ([self fileIsPicture:file]) {
        NSMutableArray *images = [NSMutableArray array];
        NSUInteger currentIndex = 0;
        for (NSUInteger i = 0; i < [self.imageFiles count]; i++) {
            NSString *imageFile = self.imageFiles[i];

            UIImage *image = [UIImage imageWithContentsOfFile:[self pathForFile:imageFile]];
            if (image) {
                [images addObject:image];
                
                if ([imageFile isEqualToString:file]) {
                    currentIndex = i;
                }
            }
        }
        
        if (images.count) {
            WCImageBrowserViewController *vc = [[WCImageBrowserViewController alloc] initWithImages:images index:currentIndex];
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
    else {
        WCTextEditViewController *vc = [[WCTextEditViewController alloc] initWithFilePath:path];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self.searchBar setShowsCancelButton:YES animated:YES];
    self.isSearching = YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self.searchBar resignFirstResponder];
    self.searchBar.text = @"";
    
    self.isSearching = NO;
    
    self.filesFiltered = [self.files copy];
    [self.tableView reloadData];
    
    CGFloat offsetY = CGRectGetHeight(self.searchBar.frame);
    [self.tableView setContentOffset:CGPointMake(0, offsetY) animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    if (searchText.length) {
        NSMutableArray *arrM = [NSMutableArray array];
        
        for (NSString *fileName in self.files) {
            
            if ([fileName rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [arrM addObject:fileName];
            }
        }
        
        self.filesFiltered = arrM;
    }
    else {
        self.filesFiltered = [self.files copy];
    }
    
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self.searchBar resignFirstResponder];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        NSLog(@"Delete");
        NSError *error = nil;
        NSString *fileName = actionSheet.userInfo;
        NSString *filePath = [self pathForFile:fileName];
        if (filePath.length && [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error]) {
            NSMutableArray *arrM = [NSMutableArray arrayWithArray:self.files];
            [arrM removeObject:fileName];
            
            self.files = arrM;
            self.filesFiltered = [self.files copy];
            [self.tableView reloadData];
        }
        else {
            NSLog(@"delete file failed at path: %@, error: %@", filePath, error);
        }
    }
}

#pragma mark - WCInteractiveLabelDelegate

- (void)interactiveLabel:(WCInteractiveLabel *)label contextMenuItemClicked:(WCContextMenuItem)item withSender:(id)sender {
    if (item & WCContextMenuItemView) {
        NSLog(@"view");
    }
    if (item & WCContextMenuItemCopy) {
        NSLog(@"Copy");
    }
}

#pragma mark - WCContextMenuCellDelegate

- (void)contextMenuCell:(WCContextMenuCell *)cell contextMenuItemClicked:(WCContextMenuItem)item withSender:(id)sender {
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:cell.center];
    
    NSString *file = self.filesFiltered[indexPath.row];
    NSString *path = [self pathForFile:file];
    
    if (item & WCContextMenuItemView) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:path delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
        [alert show];
    }
    else if (item & WCContextMenuItemCopy) {
        [UIPasteboard generalPasteboard].string = path;
    }
    else if (item & WCContextMenuItemShare) {
        NSURL *fileURL = [NSURL fileURLWithPath:path];
        
        self.documentController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
        self.documentController.UTI = @"public.data";
        [self.documentController presentOptionsMenuFromRect:CGRectZero inView:self.view animated:YES];
    }
    else if (item & WCContextMenuItemProperty) {
        NSLog(@"WCContextMenuItemProperty");
    }
    else if (item & WCContextMenuItemFavorite) {
        NSLog(@"WCContextMenuItemFavorite");
        [self doSavePathToFavorites:path];
    }
    else if (item & WCContextMenuItemDeletion) {
        NSLog(@"ONEContextMenuItemFavorite");
        NSString *title = [NSString stringWithFormat:@"%@%@?", @"Confirm delete ", file];
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:nil];
        actionSheet.userInfo = file;
        [actionSheet showInView:self.view];
    }
}

#pragma mark - Favorites

- (void)doSavePathToFavorites:(NSString *)path {
    BOOL isDirectory = NO;
    BOOL existed = [[NSFileManager defaultManager] fileExistsAtPath:WC_FAVORITE_PATHS_PLIST_PATH isDirectory:&isDirectory];
    
    if (!existed || isDirectory) {
        if (isDirectory) {
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }
        
        NSString *directoryPath = [WC_FAVORITE_PATHS_PLIST_PATH stringByDeletingLastPathComponent];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:NULL]) {
            // create the directory
            [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        // create new file
        [[NSFileManager defaultManager] createFileAtPath:WC_FAVORITE_PATHS_PLIST_PATH contents:nil attributes:nil];
    }
    
    NSString *relativePath = nil;
    WCPathType pathType = [self pathTypeForPath:path relativePath:&relativePath];
    
    NSMutableDictionary *plistDictM = [NSMutableDictionary dictionary];
    
    NSData *data = [NSData dataWithContentsOfFile:WC_FAVORITE_PATHS_PLIST_PATH];
    NSMutableDictionary *dictM = (NSMutableDictionary *)[NSPropertyListSerialization
                                                         propertyListFromData:data
                                                         mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                                         format:0
                                                         errorDescription:nil];
    
    [plistDictM addEntriesFromDictionary:dictM];
    
    NSMutableArray *arrM = [NSMutableArray arrayWithArray:dictM[NSStringFromWCPathType(pathType)]];
    
    if (pathType == WCPathTypeUnknown) {
        [arrM addObject:relativePath];
    }
    else if (pathType == WCPathTypeHome) {
        [arrM addObject:relativePath];
    }
    else if (pathType == WCPathTypeBundle) {
        [arrM addObject:relativePath];
    }
    
    plistDictM[NSStringFromWCPathType(pathType)] = arrM;
    
    BOOL success = [plistDictM writeToFile:WC_FAVORITE_PATHS_PLIST_PATH atomically:YES];
    if (!success) {
        NSLog(@"write failed");
    }
}

- (WCPathType)pathTypeForPath:(NSString *)path relativePath:(NSString **)relativePath {
    static NSString *sHomeFolderName;
    static NSString *sBundleFolderName;
    
    NSString *relativePathL = [path copy];
    
    if (!sHomeFolderName) {
        sHomeFolderName = [NSHomeDirectory() lastPathComponent];
    }
    
    if (!sBundleFolderName) {
        sBundleFolderName = [[[NSBundle mainBundle] bundlePath] lastPathComponent];
    }
    
    if ([path rangeOfString:sHomeFolderName].location != NSNotFound) {
        NSRange range = [path rangeOfString:sHomeFolderName];
        relativePathL = [path substringFromIndex:range.location + range.length];
        *relativePath = [relativePathL stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
        
        return WCPathTypeHome;
    }
    else if ([path rangeOfString:sBundleFolderName].location != NSNotFound) {
        NSRange range = [path rangeOfString:sBundleFolderName];
        relativePathL = [path substringFromIndex:range.location + range.length];
        *relativePath = [relativePathL stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
        
        return WCPathTypeBundle;
    }
    else {
        *relativePath = relativePathL;
        return WCPathTypeUnknown;
    }
}

@end
