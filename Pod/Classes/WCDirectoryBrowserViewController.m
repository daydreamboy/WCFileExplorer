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

#define SectionHeader_H 40.0f

// File Attributes
static NSString *WCFileAttributeFileSize = @"WCFileAttributeFileSize"; /*! size of file, or size of total files in a directory */
static NSString *WCFileAttributeIsDirectory = @"WCFileAttributeIsDirectory";
static NSString *WCFileAttributeNumberOfFilesInDirectory = @"WCFileAttributeNumberOfFilesInDirectory";

@interface WCDirectoryBrowserViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, WCInteractiveLabelDelegate, WCContextMenuCellDelegate>
@property (nonatomic, copy) NSString *pwdPath;  /**< current folder path */
@property (nonatomic, strong) NSArray *files;   /**< list name of files */
@property (nonatomic, strong) NSArray *filesFiltered; /**< list name of filtered files */
@property (nonatomic, strong) NSDictionary *fileAttributes; /**< attributes of files */

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIDocumentInteractionController *documentController;

@property (nonatomic, strong) WCInteractiveLabel *labelTitle;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, assign) BOOL isSearching;

@end

@implementation WCDirectoryBrowserViewController

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        _pwdPath = path;
    }
    return self;
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
    
    if (self.pwdPath.length) {
        NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.pwdPath error:nil];
        self.files = [fileNames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        self.filesFiltered = [self.files copy];
        
        [self parseAttributesOfFiles];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    CGFloat offsetY = self.isSearching ? 0 : CGRectGetHeight(self.searchBar.frame);
    [self.tableView setContentOffset:CGPointMake(0, offsetY) animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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
            
            unsigned long long totalSize = [self sizeOfDirectoryAtPath:path];
            attributes[WCFileAttributeFileSize] = @(totalSize);
        }
        
        if (attributes.count) {
            dictM[fileName] = attributes;
        }
    }
    self.fileAttributes = dictM;
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

- (unsigned long long)sizeOfDirectoryAtPath:(NSString *)path {
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:path error:nil];
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
    if (bytes < 1024) {
        return [NSString stringWithFormat:@"%llu bytes", bytes];
    }
    else if (bytes < 1024 * 1024) {
        return [NSString stringWithFormat:@"%llu KB", bytes / 1024];
    }
    else if (bytes < 1024 * 1024 * 1024) {
        return [NSString stringWithFormat:@"%llu MB", bytes / (1024 * 1024)];
    }
    else if (bytes < 1024 * 1024 * 1024 * 1024) {
        return [NSString stringWithFormat:@"%llu GB", bytes / (1024 * 1024 * 1024)];
    }
    else {
        return [NSString stringWithFormat:@"%llu TB", bytes / (1024 * 1024 * 1024 * 1024)];
    }
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
    
    NSString *size = [self prettySizeWithBytes:[attributes[WCFileAttributeFileSize] unsignedLongLongValue]];
    if (!isDir) {
        // file
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", size];
    }
    else {
        // directory
        NSString *unit = [attributes[WCFileAttributeNumberOfFilesInDirectory] isEqualToNumber:@(1)] ? @"file" : @"files";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@ (%@)", attributes[WCFileAttributeNumberOfFilesInDirectory], unit, size];
    }
    cell.detailTextLabel.textColor = [UIColor grayColor];
    cell.accessoryType = isDir ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    
    if (isDir) {
        cell.contextMenuItemTypes = @[ @(WCContextMenuItemView), @(WCContextMenuItemCopy) ];
        cell.contextMenuItemTitles = @[ @"View Path", @"Copy Path" ];
    }
    else {
        cell.contextMenuItemTypes = @[ @(WCContextMenuItemView), @(WCContextMenuItemCopy), @(WCContextMenuItemShare), @(WCContextMenuItemProperty) ];
        cell.contextMenuItemTitles = @[ @"View Path", @"Copy Path", @"Export File", @"View Property" ];
    }
    cell.allowCustomActionContextMenuItems = WCContextMenuItemView | WCContextMenuItemCopy | WCContextMenuItemShare | WCContextMenuItemProperty;
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
        
        unsigned long long totalSize = 0;
        for (NSString *file in self.filesFiltered) {
            NSDictionary *attributes = self.fileAttributes[file];
            totalSize += [attributes[WCFileAttributeFileSize] unsignedLongLongValue];
        }
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(paddingL, paddingT, screenSize.width - paddingL, 20)];
        label.text = [NSString stringWithFormat:@"%lu items (%@)", (unsigned long)[self.filesFiltered count], [self prettySizeWithBytes:totalSize]];
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
}

@end
