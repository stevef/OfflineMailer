//
//  AccountViewController.h
//  OfflineMailer
//
//  Created by Steve Finkelstein on 4/10/09.
//  Copyright 2009 __InsertCompanyNameHere__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OfflineViewController.h"
#import "SearchTestController.h"
#import "Three20/Three20.h"

@class TTAddressBookDataSource;
@class BlueBadge;

@interface AccountViewController : OfflineViewController 
	<UITableViewDataSource, UITableViewDelegate, TTMessageControllerDelegate, SearchTestControllerDelegate>
{
	UITableView *tableView;
	NSArray *sectionArray;
	UIImageView *lightBulbView;
	
	TTAddressBookDataSource *dataSource;
	TTMessageController *messageController;
	
	NSManagedObjectContext *managedObjectContext;
}

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) NSArray *sectionArray;
@property (nonatomic, retain) UIImageView *lightBulbView;
@property (nonatomic, retain) TTAddressBookDataSource *dataSource;
@property (nonatomic, retain) TTMessageController *messageController;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

- (void)setupToolBar;
- (UIImage *)lightBulb;
- (void)composeMessage:(id)sender;

#pragma mark -
- (void)messageSent:(NSNotification *)notification;
- (void)messageQueued:(NSNotification *)notification;

#pragma mark -
- (BlueBadge *)badgeWithCount:(NSInteger)count;

@end
