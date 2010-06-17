//
//  SettingsViewController.m
//  OfflineMailer
//
//  Created by Steve Finkelstein on 4/9/09.
//  Copyright 2009 __InsertCompanyNameHere__. All rights reserved.
//

#import "SettingsViewController.h"


@implementation SettingsViewController

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView 
{
	[super loadView];
	
	// Create the main view
	UIView *aView = [[[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease];
	[aView setBackgroundColor:[UIColor darkGrayColor]];

	// Caution image 
	UIImage *caution  = [UIImage imageNamed:@"alert_125x125.png"];
	UIImageView *cautionView = [[UIImageView alloc] initWithImage:caution];
	[cautionView setFrame:CGRectMake(85, 30, 125, 125)];
	[aView addSubview:cautionView];
	[cautionView release];
	
	// Advisory label
	UILabel *aLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 235, 200)];
	[aLabel setCenter:aView.center];
	[aLabel setFont:[UIFont boldSystemFontOfSize:18]];
	[aLabel setBackgroundColor:[UIColor darkGrayColor]];
	[aLabel setTextColor:[UIColor orangeColor]];
	[aLabel setLineBreakMode:UILineBreakModeWordWrap];
	[aLabel setNumberOfLines:0];
	[aLabel setText:@"Warning: Please fill in all mail server settings in the Settings Application."]; 
	[aView addSubview:aLabel];
	
	[aLabel release];
	
	self.view = aView;
}

- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc 
{
    [super dealloc];
}


@end
