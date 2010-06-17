//
//  AccountViewController.m
//  OfflineMailer
//
//  Created by Steve Finkelstein on 4/10/09.
//  Copyright 2009 __InsertCompanyNameHere__. All rights reserved.
//

#import "AccountViewController.h"
#import "SettingsViewController.h"

#import "DataManager.h"
#import "TTAddressBookDataSource.h"
//#import "MockDataSource.h"
#import "BlueBadge.h"

#import "Contact.h"

#import "OMGlobals.h"
	
#define BADGE_VIEW_TAG 555

@implementation AccountViewController
@synthesize sectionArray, lightBulbView, messageController, dataSource, tableView, managedObjectContext;

#pragma mark -
#pragma mark Memory Management
- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[dataSource release];
	[tableView release];
	[sectionArray release];
	[lightBulbView release];
	[messageController release];
	[managedObjectContext release];
	
	[super dealloc];
}

- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

#pragma mark -
#pragma mark Init
- (id)init 
{
  if (self = [super init]) {
    dataSource = nil;
		// register for message notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageSent:) name:kMessageSentSuccessfully object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageQueued:) name:kMessageQueuedSuccessfully object:nil];
  }
  return self;
}

#pragma mark -
#pragma mark Notification Callbacks
- (void)messageSent:(NSNotification *)notification
{
	// Assign a reference to our "Sent Mail" cell.
//	UITableViewCell *sentCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
//	
//	// Retrieve current sent count
//	NSUInteger numSent = [[DataManager sharedDataManager] numberOfMessagesSent];
//	
//	BlueBadge *sentMailBadge = [sentCell viewWithTag:BADGE_VIEW_TAG];
//	[sentMailBadge drawWithCount:numSent];
	
	// We'll call reloadData here so the counts can update..
	[tableView reloadData];
	
	[messageController dismissModalViewControllerAnimated:YES];
}

- (void)messageQueued:(NSNotification *)notification
{
		NSLog(@"Number of message now in queue: %d", [[DataManager sharedDataManager] numberOfMessagesInQueue]);
		[self.tableView reloadData];
		[messageController dismissModalViewControllerAnimated:YES];
}


#pragma mark -
- (BlueBadge *)badgeWithCount:(NSInteger)count
{
		CGRect badgeFrame = CGRectMake(250, 12, 50, 50);
		BlueBadge *blueBadge = [[BlueBadge alloc] initWithFrame:badgeFrame];
		[blueBadge drawWithCount:count];
		
		return [blueBadge autorelease];
}

#pragma mark -
#pragma mark TTMessageControllerDelegate
- (void)composeController:(TTMessageController*)controller didSendFields:(NSArray*)fields
{
	NSMutableArray *contacts = [[NSMutableArray alloc] initWithCapacity:0];
  TTMessageRecipientField *toField = [fields objectAtIndex:0];

	for (id recipient in toField.recipients) {
		Contact *aContact = [dataSource contactWithName:recipient];
		[contacts addObject:aContact];
	}
	[[DataManager sharedDataManager] sendEmailWithFields:fields forContacts:contacts];
	
	[contacts release];
}

- (void)composeControllerDidCancel:(TTMessageController*)controller 
{
  [controller dismissModalViewControllerAnimated:YES];
}

// This happens when the + button is clicked.
- (void)composeControllerShowRecipientPicker:(TTMessageController*)controller {
	SearchTestController* searchController = [[[SearchTestController alloc] init] autorelease];
	searchController.delegate = self;
	searchController.title = @"Address Book";
	searchController.navigationItem.prompt = @"Select a recipient";
	searchController.navigationItem.rightBarButtonItem = 
    [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
												   target:self action:@selector(cancelAddressBook)] autorelease];
    
	UINavigationController* navController = [[[UINavigationController alloc] init] autorelease];
	[navController pushViewController:searchController animated:NO];
	[controller presentModalViewController:navController animated:YES];
}

// Dismiss Address Book controller.
- (void)cancelAddressBook 
{
	[messageController dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark SearchTestControllerDelegate
- (void)searchTestController:(SearchTestController*)controller didSelectObject:(id)object
{
  [messageController addRecipient:object forFieldAtIndex:0];
  [controller dismissModalViewControllerAnimated:YES];
}

- (void)reachabilityChanged:(NSNotification *)note
{
	[self updateNetworkStatus];
}

- (void)updateNetworkStatus 
{
	currentNetworkStatus = [[Reachability sharedReachability] remoteHostStatus];
	[lightBulbView setImage:[self lightBulb]];
	
	if (currentNetworkStatus == ReachableViaWiFiNetwork || currentNetworkStatus == ReachableViaCarrierDataNetwork) {
		// Check the offline queue since we're on the network.
		NSInteger queueCount = [[DataManager sharedDataManager] numberOfMessagesInQueue];
		if (queueCount) {
			[[DataManager sharedDataManager] flushQueue];
		}
	}
}

- (UIImage *)lightBulb
{
	return (currentNetworkStatus == NotReachable) 
	 	? [UIImage imageNamed:@"light_bulb_off.png"]
		: [UIImage imageNamed:@"light_bulb_on.png"];
}

- (UIImageView *)lightBulbView
{
	CGRect frame = CGRectMake(0, 0, 36.0f, 36.0f);
	UIImage *lightBulb = [self lightBulb];
	lightBulbView = [[UIImageView alloc] initWithImage:lightBulb];
	[lightBulbView setFrame:frame];
	
	return [lightBulbView autorelease];
}

#pragma mark -
- (void)composeMessage:(id)sender
{
	id recipient = [[[TTTableField alloc] initWithText:nil url:TT_NULL_URL] autorelease];
	TTMessageController* controller = [[TTMessageController alloc] 
		initWithRecipients:[NSArray arrayWithObject:recipient]];
	self.messageController = controller;
	messageController.delegate = self;
	messageController.dataSource = dataSource;
	
	[controller release];
	
	[self presentModalViewController:messageController animated:YES];
}

#pragma mark -
- (void)setupToolBar
{
	// create the UIToolbar at the bottom of the view controller
	//
	UIToolbar *toolbar = [UIToolbar new];
	[toolbar setBarStyle:UIBarStyleDefault];
	
	// size up the toolbar and set its frame
	[toolbar sizeToFit];
	CGFloat toolbarHeight = [toolbar frame].size.height;
	CGRect mainViewBounds = self.view.bounds;
	[toolbar setFrame:CGRectMake(CGRectGetMinX(mainViewBounds),
								 CGRectGetMinY(mainViewBounds) + CGRectGetHeight(mainViewBounds) - (toolbarHeight * 2.0),
								 CGRectGetWidth(mainViewBounds),
								 toolbarHeight)];
	
	// toolbar items
	NSMutableArray *toolbarItems = [[NSMutableArray alloc] init];
	UIBarButtonItem *bulbItem = [[UIBarButtonItem alloc] initWithCustomView:[self lightBulbView]];
	UIBarButtonItem *fixedSpace = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil] autorelease];
	[fixedSpace setWidth:225.0f];
	
	[toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeMessage:)] autorelease]];
	[toolbarItems addObject:fixedSpace];
	[toolbarItems addObject:bulbItem];
	
	[toolbar setItems:toolbarItems];
	[self.view insertSubview:toolbar aboveSubview:tableView];
	
	[toolbar release];
	[toolbarItems release];	
	[bulbItem release];
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView 
{
	[super loadView];
	
	CGRect myBounds = self.view.bounds;
	TTLOGRECT(myBounds);
	
	dataSource = [[TTAddressBookDataSource abDataSourceForSearch:YES] retain];
	UITableView *aTableView = 
		[[[UITableView alloc] 
			initWithFrame:[[UIScreen mainScreen] bounds]
			style:UITableViewStylePlain] autorelease];
	
	aTableView.scrollEnabled = NO;
	
	[self.view addSubview:aTableView];
	self.tableView = aTableView;
	[self setupToolBar];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[self setTitle:[NSString stringWithFormat:@"%@@%@", 
		[[DataManager sharedDataManager] smtpUserName], 
		[[DataManager sharedDataManager] hostName]]];
}

- (void)viewWillAppear:(BOOL)animated
{

}

- (UITableView *)tableView
{
	return tableView;
}

- (void)setTableView:(UITableView *)newTableView
{
	[tableView release];
	tableView = [newTableView retain];
	[tableView setDelegate:self];
	[tableView setDataSource:self];
}

#pragma mark -
- (NSArray *)sectionArray
{
	return [NSArray arrayWithObjects:@"Offline Queue", @"Sent Mail", nil];
}

#pragma mark -
#pragma mark TableView DataSource/Delegate Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[self sectionArray] count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"aCell";
	
	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		BlueBadge *countBadge = [[self badgeWithCount:0] retain];
		[countBadge setTag:BADGE_VIEW_TAG];
		[cell addSubview:countBadge];
		[countBadge release];
	}
	
	NSString *rowName = [self.sectionArray objectAtIndex:[indexPath row]];
		
	if ([indexPath row] == 0)
		cell.imageView.image = [UIImage imageNamed:@"folder.png"];
	else if ([indexPath row] == 1) {
		cell.imageView.image = [UIImage imageNamed:@"send_email.png"];
	}
		
	cell.textLabel.text = [NSString stringWithString:rowName];
	
	// check if we have any offline messages in queue.
	if ([indexPath row] == 0) {
		NSUInteger queueCount = [[DataManager sharedDataManager] numberOfMessagesInQueue];
		BlueBadge *badgeView = (BlueBadge *)[cell viewWithTag:555];
		[badgeView drawWithCount:queueCount];
		// Display messages in queue, not required -- for debugging.
		//[[DataManager sharedDataManager] displayAllMessagesOfType:MessageTypeSent];
	}
	
	// count number of sent messages, if any.
	if ([indexPath row] == 1) {
		NSUInteger sentCount = [[DataManager sharedDataManager] numberOfMessagesSent];
		BlueBadge *sentBadge = (BlueBadge *)[cell viewWithTag:BADGE_VIEW_TAG];
		[sentBadge drawWithCount:sentCount];
	}

	return cell;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
