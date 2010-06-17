//
//  OfflineViewController.m
//  OfflineMailer
//
//  Created by Steve Finkelstein on 4/5/09.
//  Copyright __InsertCompanyNameHere__ 2009. All rights reserved.
//

#import "OfflineViewController.h"
#import "SettingsViewController.h"

@implementation OfflineViewController

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView 
{
	[super loadView];
}

// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad {
    [super viewDidLoad];

	[[NSNotificationCenter defaultCenter] 
		addObserver:self 
		selector:@selector(reachabilityChanged:) 
		name:@"kNetworkReachabilityChangedNotification" 
		object:nil];
	
	[[Reachability sharedReachability] setHostName:@"catalyst.httpd.org"];
	[self updateNetworkStatus];
}

// for subclasses to implement
- (void)reachabilityChanged:(NSNotification *)note
{}

// for subclasses to implement
- (void)updateNetworkStatus 
{}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}


@end
