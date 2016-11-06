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

@interface WCDirectoryBrowserViewController () <UITableViewDelegate, UITableViewDataSource, WCInteractiveLabelDelegate, WCContextMenuCellDelegate>
@property (nonatomic, copy) NSString *pwdPath;  /**< current folder path */
@property (nonatomic, strong) NSArray *files;   /**< list name of files */

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIDocumentInteractionController *documentController;

@property (nonatomic, strong) WCInteractiveLabel *labelTitle;

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
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.tableView];
    
    self.labelTitle.text = self.pwdPath;
    [self.labelTitle sizeToFit];
    
    self.navigationItem.titleView = self.labelTitle;
    
    if (self.pwdPath.length) {
        self.files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.pwdPath error:nil];
    }
    
    UIMenuItem *testMenuItem = [[UIMenuItem alloc] initWithTitle:@"Test" action:@selector(test:)];
    [[UIMenuController sharedMenuController] setMenuItems: @[testMenuItem]];
    [[UIMenuController sharedMenuController] update];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
        label.contextMenuItems = WCContextMenuItemCopy | WCContextMenuItemView;
        label.delegate = self;
        label.showContextMenuAlwaysCenetered = YES;
        
        _labelTitle = label;
    }
    
    return _labelTitle;
}

- (UITableView *)tableView {
    if (!_tableView) {
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height) style:UITableViewStylePlain];
        tableView.delegate = self;
        tableView.dataSource = self;
        
        _tableView = tableView;
    }
    
    return _tableView;
}

#pragma mark - Utility

- (NSString *)pathForFile:(NSString *)file {
    return [self.pwdPath stringByAppendingPathComponent:file];
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
    return [self.files count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *sCellIdentifier = @"Cell";
    
    WCContextMenuCell *cell = (WCContextMenuCell *)[tableView dequeueReusableCellWithIdentifier:sCellIdentifier];
    if (cell == nil) {
        cell = [[WCContextMenuCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:sCellIdentifier];
        cell.textLabel.font = [UIFont systemFontOfSize:16.0];
    }
    
    NSString *file = [self.files objectAtIndex:indexPath.row];
    NSString *path = [self pathForFile:file];
    BOOL isDir = [self fileIsDirectory:file];
    
    cell.textLabel.text = file;
    cell.textLabel.textColor = isDir ? [UIColor blueColor] : [UIColor darkTextColor];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *file = self.files[indexPath.row];
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
    
    NSString *file = self.files[indexPath.row];
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
        
        UIDocumentInteractionController *vc = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
        vc.UTI = @"public.text";
        [vc presentOptionsMenuFromRect:CGRectZero inView:self.view animated:YES];
    }
    else if (item & WCContextMenuItemProperty) {
        NSLog(@"WCContextMenuItemProperty");
    }
}

@end
