//
//  Contact.m
//  OfflineMailer
//
//  Created by Steve Finkelstein on 5/25/09.
//  Copyright 2009 __Insert Company Name Here__. All rights reserved.
//

#import "Contact.h"


@implementation Contact
@synthesize firstName;
@synthesize lastName;
@synthesize email;

- (void)dealloc
{
	[firstName release];
	[lastName release];
	[email release];
	
	[super dealloc];
}

- (id)initWithFirstName:(NSString *)fName lastName:(NSString *)lName email:(NSString *)anEmail
{
	if (self = [super init]) {
		self.firstName = (fName == nil) ? @"" : fName;
		self.lastName = (lName == nil) ? @"" :lName;
		self.email = (anEmail == nil) ? @"" : anEmail;
	}
	
	return self;
}

- (NSString *)fullName
{
	return [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
}

@end
