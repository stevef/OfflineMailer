//
//  Message.m
//  OfflineMailer
//
//  Created by Steve Finkelstein on 6/13/09.
//  Copyright 2009 __Insert Company Name Here__. All rights reserved.
//

#import "Message.h"


@implementation Message
@synthesize message_id;
@synthesize recipients;
@synthesize subject;
@synthesize message;
@synthesize dateSent;

#pragma mark -
#pragma mark Initializer
- (id)initWithDictionary:(NSDictionary *)aDict
{
	NSAssert(aDict != nil, @"Attempt to init without dictionary");
	if (self = [super init])
	{
		self.message_id = [aDict objectForKey:@"message_id"];
		self.recipients = [aDict objectForKey:@"recipients"];
		self.subject = [aDict objectForKey:@"subject"];
		self.message = [aDict objectForKey:@"message"];
		self.dateSent = 0;
	}
	
	return self;
}

@end
