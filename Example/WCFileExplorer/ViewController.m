//
//  WCViewController.m
//  WCFileExplorer
//
//  Created by wesley_chen on 11/03/2016.
//  Copyright (c) 2016 wesley_chen. All rights reserved.
//

#import "ViewController.h"

#import "WCDirectoryBrowserViewController.h"
#import "WCTextEditViewController.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray<WCPathItem *> *listData;
@property (nonatomic, strong) NSMutableArray<WCPathItem *> *reservedPaths;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSString *homePath = NSHomeDirectory();
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    
    NSString *appName = [bundlePath lastPathComponent];
    
    self.reservedPaths = [@[
                           [WCPathItem itemWithName:@"App Home Direcotry" path:homePath],
                           [WCPathItem itemWithName:appName path:bundlePath]
                           ] mutableCopy];
    
    if ([self deviceJailBroken]) {
        [self.reservedPaths addObject:[WCPathItem itemWithName:@"/" path:@"/"]];
    }
    
    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSMutableArray *arrM = [NSMutableArray arrayWithArray:self.reservedPaths];
    [arrM addObjectsFromArray:[WCDirectoryBrowserViewController favoritePathItems]];
    self.listData = arrM;
    
    [self.tableView reloadData];
}

#pragma mark - Getters

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

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.listData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *sCellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:sCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:sCellIdentifier];
        cell.textLabel.font = [UIFont systemFontOfSize:16.0];
    }
    
    WCPathItem *item = self.listData[indexPath.row];
    
    BOOL isDirectory = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:item.path isDirectory:&isDirectory];
    
    cell.textLabel.text = item.name ? item.name : [item.path lastPathComponent];
    cell.textLabel.textColor = isDirectory ? [UIColor blueColor] : [UIColor darkTextColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    WCPathItem *item = self.listData[indexPath.row];
    if ([self.reservedPaths containsObject:item]) {
        return NO;
    }
    else {
        return YES;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    WCPathItem *item = self.listData[indexPath.row];
    NSString *path = item.path;
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    BOOL isDirectory = NO;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    if (exists) {
        if (isDirectory) {
            WCDirectoryBrowserViewController *vc = [[WCDirectoryBrowserViewController alloc] initWithPath:path];
            [self.navigationController pushViewController:vc animated:YES];
        }
        else {
            WCTextEditViewController *vc = [[WCTextEditViewController alloc] initWithFilePath:path];
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"Delete" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        WCPathItem *item = self.listData[indexPath.row];
        
        if (![self.reservedPaths containsObject:item]) {
            [self.listData removeObject:item];
            [WCDirectoryBrowserViewController deleteFavoritePathItemWithItem:item];
            
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }];
    
    return @[action];
}

#pragma mark

- (BOOL)deviceJailBroken {
    NSArray *jailbreak_tool_pathes = @[
                                       @"/Applications/Cydia.app",
                                       @"/Library/MobileSubstrate/MobileSubstrate.dylib",
                                       @"/bin/bash",
                                       @"/usr/sbin/sshd",
                                       @"/etc/apt"
                                       ];
    
    for (NSUInteger i = 0; i < jailbreak_tool_pathes.count; i++) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:jailbreak_tool_pathes[i]]) {
            return YES;
        }
    }
    return NO;
}

@end
