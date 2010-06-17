//
//  DataManager.m
//  OfflineMailer
//
//  Created by Steve Finkelstein on 5/20/09.
//  Copyright 2009 __InsertCompanyNameHere__. All rights reserved.
//

#import "DataManager.h"

#import "Contact.h"
#import "Message.h"

#import <Three20/Three20.h>

#import "NSData+Base64Additions.h"
#import "OfflineMailerAppDelegate.h"
#import "OMGlobals.h"

#define DEFAULT_SMTP_PORT 25
#define SMTP_DELAY_TIME 10

@interface DataManager (Private)
- (NSArray *)getResultSetFromQueue;
- (NSNumber *)currentTimeStamp;
@end

@implementation DataManager

@synthesize hostName;
@synthesize smtpUserName;
@synthesize smtpPassword;
@synthesize smtpPort;

@synthesize networkOperationQueue;

@synthesize queuedMessages;
@synthesize sentMessages;

@synthesize appDelegate;

@synthesize managedObjectContext;

static DataManager *dataMgr = nil;

#pragma mark -
#pragma mark Memory Management
- (void)dealloc
{
	[hostName release];
	[smtpUserName release];
	[smtpPassword release];
	[smtpPort release];
	
	[networkOperationQueue release];
	
	[queuedMessages release];
	[sentMessages release];
	
	[managedObjectContext release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark init/alloc
// Initialize the singleton instance if needed and return
+(DataManager *)sharedDataManager 
{
    @synchronized(self) { // thread safe init
		if (dataMgr == nil) {
			[[self alloc] init];
		}
	}
	return dataMgr;
}

+ (id)allocWithZone:(NSZone *)zone 
{
    @synchronized(self) {
        if (dataMgr == nil) {
            dataMgr = [super allocWithZone:zone];
            return dataMgr;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

// Shouldn't be called by anyone but DataManager itself. 
- (id)init 
{
	if(self = [super init]) 
	{
		[self loadDefaultSettings];
		
		appDelegate = [[UIApplication sharedApplication] delegate];
		
		[networkOperationQueue cancelAllOperations];
		networkOperationQueue = [NSOperationQueue new];
		[networkOperationQueue setMaxConcurrentOperationCount:1];
				
		self.queuedMessages = [NSMutableDictionary dictionary];
		self.sentMessages = [NSMutableDictionary dictionary];
	}
	
	return self;
}

+(id)copy
{
	@synchronized(self)
	{
		NSAssert(dataMgr == nil, @"Attempted to copy the singleton.");
	}
	
	return dataMgr;
}

- (id)retain 
{
    return self;
}

- (unsigned)retainCount 
{
    return UINT_MAX;  //denotes an object that cannot be released
}

- (void)release 
{
    // do nothing, we do not want this to release.
}

- (id)autorelease 
{
    return self;
}

#pragma mark -
- (void)loadDefaultSettings 
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	self.hostName = [defaults objectForKey:@"hostName"];
	self.smtpPort = [defaults objectForKey:@"smtpPort"];
	self.smtpPassword = [defaults objectForKey:@"smtpPassword"];
	self.smtpUserName = [defaults objectForKey:@"smtpUserName"];

	if (self.smtpPort == nil) {
		self.smtpPort = [NSNumber numberWithInt:DEFAULT_SMTP_PORT];
	}
}

#pragma mark -
#pragma mark Utility Methods
- (NSNumber *)currentTimeStamp
{
	return [NSNumber numberWithInt:(int)[[NSDate date] timeIntervalSince1970]];
}

- (NSString *)getNewMessageID
{
	NSString *newId = @"1"; 
	
	NSEntityDescription *entity = 
		[NSEntityDescription entityForName:@"Message" inManagedObjectContext:managedObjectContext];
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:entity];
	NSString *predicateString = @"messageID = max(messageID)";
	NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString];
	[fetchRequest setPredicate:predicate];
	
	NSError *error = nil;
	NSArray *allMessages = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
	if ([allMessages count] > 0) {
		Message *message = [allMessages objectAtIndex:0];
		NSString *messageID = [message valueForKey:@"messageID"];
		NSNumberFormatter *numberFormatter = 
			[[[NSNumberFormatter alloc] init] autorelease];
		NSNumber *num = [numberFormatter numberFromString:messageID];
		newId = [NSString stringWithFormat:@"%d", [num intValue] +1];
	}
	
	[fetchRequest release];
	
	return newId;
}

- (Message *)getMessageWithID:(NSString *)messageID
{
	NSEntityDescription *entity = 
		[NSEntityDescription entityForName:@"Message" inManagedObjectContext:managedObjectContext];
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:entity];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageID = %@", messageID];
	[fetchRequest setPredicate:predicate];
	
	NSError *error = nil;
	NSArray *message = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
	
	[fetchRequest release];
	
	return [message objectAtIndex:0];
}

#pragma mark -
#pragma mark Mailer Helpers
- (void)sendEmailWithFields:(NSArray *)fields forContacts:(NSArray *)contacts
{
	// message subject
  TTMessageSubjectField *subjField = [fields objectAtIndex:1];
	
	// email body
	TTMessageTextField *bodyField = [fields objectAtIndex:2];
	
	// recipients
	NSMutableString *recipients = [[NSMutableString alloc] init];
	NSInteger cnt = [contacts count];
	for (int i=0; i < cnt; ++i) {
		NSString *anEmail = nil;
		if (i == cnt - 1)
				anEmail = [NSString stringWithFormat:@"%@", (Contact *)[[contacts objectAtIndex:i] email]];
		else
				anEmail = [NSString stringWithFormat:@"%@,", (Contact *)[[contacts objectAtIndex:i] email]];

		[recipients appendString:anEmail];
	}
	
	NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:recipients, @"recipients", subjField.text, @"subject", bodyField.text, @"body", nil];
	[recipients release];
	
	if (self.appDelegate.hasNetworkConnection) {
		NSInvocationOperation *onlineEmailOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(emailInvocationOperation:) object:data];
		[networkOperationQueue addOperation:onlineEmailOperation];	
		[onlineEmailOperation release];
	} else {
	
		//
		// get the next id for messageid, its unique identifier.
		//
		NSString *newId = [self getNewMessageID];
		 
		//
		// Create a new Message object and add it to the Managed Object Context.
		//
		Message *message = (Message *)[NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:managedObjectContext];
		
		// configure the message object using KVC, a common pattern 
		// when using Core Data.
		[message setValue:recipients forKey:@"to"];
		[message setValue:bodyField.text forKey:@"body"];
		[message setValue:subjField.text forKey:@"subject"];
		[message setValue:newId forKey:@"messageID"];		
		[message setValue:[NSNumber numberWithInt:0] forKey:@"dateSent"];
		[message setValue:[NSNumber numberWithBool:NO] forKey:@"status"];
		
		NSLog(@"newId in queue: %@", newId);
		
		NSError *error = nil;
		if (![managedObjectContext save:&error]) {
			// handle the error in a production setting.
		} else {
			[[NSNotificationCenter defaultCenter] postNotificationName:kMessageQueuedSuccessfully object:nil];
		}
	}
}

- (void)emailInvocationOperation:(id)data
{
	NSAutoreleasePool *aPool = [[NSAutoreleasePool alloc] init];
	NSString *body = [data objectForKey:@"body"];
	NSString *recipients = [data objectForKey:@"recipients"];
	NSString *subject = [data objectForKey:@"subject"];
	NSString *messageID = [data objectForKey:@"messageID"];
	
	if (!messageID) {
		// No message created yet? Let's create it.
		NSNumber *currentTime = [self currentTimeStamp];
		messageID = [self getNewMessageID];
		
		Message *message = (Message *)[NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:managedObjectContext];
			
		[message setValue:recipients forKey:@"to"];
		[message setValue:body forKey:@"body"];
		[message setValue:subject forKey:@"subject"];
		[message setValue:messageID forKey:@"messageID"];		
		[message setValue:currentTime forKey:@"dateSent"];
		
		NSLog(@"messageID in emailInvocationOperation: %@", messageID);
		
		NSError *error = nil;
		if (![managedObjectContext save:&error]) {
			// handle the error
		} 
	}
	
	//
	// TODO: Add a status property to Message object. Date alone isn't enough.
	// we need to only send status to sent after the delegate gets successfully hit.
	// not based on date alone.
	//
			
	SKPSMTPMessage *smtpMsg = [[SKPSMTPMessage alloc] init];
	smtpMsg.fromEmail = @""; // SET FROM MAIL
	smtpMsg.toEmail = recipients;
	smtpMsg.relayHost = self.hostName;
	smtpMsg.requiresAuth = YES;
	smtpMsg.login = @""; // SET SMTP LOGIN IF NEEDED
	smtpMsg.pass = @""; // SET SMTP PASS IF NEEDED
	smtpMsg.subject = subject;
	smtpMsg.wantsSecure = YES;
	smtpMsg.messageID = messageID;
	
	smtpMsg.delegate = self;
	NSDictionary *plainText = 
		[NSDictionary dictionaryWithObjectsAndKeys:@"text/plain",kSKPSMTPPartContentTypeKey,
			body,kSKPSMTPPartMessageKey,@"8bit",kSKPSMTPPartContentTransferEncodingKey,nil];
        
	smtpMsg.parts = [NSArray arrayWithObjects:plainText,nil];
	[smtpMsg send];
	
	[aPool drain];
}

#pragma mark -
#pragma mark SKPSMTPMessage Delegate Methods
- (void)messageSent:(SKPSMTPMessage *)smtpMessage
{
	NSLog(@"delegate - message sent for message id: %@", [smtpMessage messageID]);
	
	NSString *messageID = [smtpMessage messageID];
	
	// retrieve Message based on ID
	Message *message = [self getMessageWithID:messageID];
	
	// Update status to sent and current timestamp.
	NSNumber *currentTime = [self currentTimeStamp];
	
	[message setValue:currentTime forKey:@"dateSent"];
	[message setValue:[NSNumber numberWithBool:YES] forKey:@"status"];
	
	NSError *error = nil;
	
	if (![managedObjectContext save:&error]) {
		// handle error;
	}
		
	// post a notification to alert the client that the message has been sent.
	[[NSNotificationCenter defaultCenter] postNotificationName:kMessageSentSuccessfully object:nil];
}

- (void)messageFailed:(SKPSMTPMessage *)message error:(NSError *)error
{
    [message release];
    
    NSLog(@"delegate - error(%d): %@", [error code], [error localizedDescription]);
}

#pragma mark -
#pragma mark Database Methods
// previous, SQLite3 version.
//- (NSUInteger)numberOfMessagesInQueue
//{
//	return [self.appDelegate.appDb intForQuery:@"select count(*) from mail where status = ?", [NSNumber numberWithInt:MessageTypeQueued]];
//}

- (NSUInteger)numberOfMessagesInQueue
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Message" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"status == NO"];
	[request setPredicate:pred];
	
	NSError *error = nil;
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
	if (fetchResults == nil) {
		// handle error here.
	}
	
	[request release];
	
	return [fetchResults count];
}

// old sqlite3 implementation
//- (NSUInteger)numberOfMessagesSent
//{
//	return [self.appDelegate.appDb intForQuery:@"select count(*) from mail where status = ?", [NSNumber numberWithInt:MessageTypeSent]];
//}

- (NSUInteger)numberOfMessagesSent
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Message" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"status == YES"];
	[request setPredicate:pred];
	
	NSError *error = nil;
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
	if (fetchResults == nil) {
		// handle error here.
	}
	
	[request release];
	
	return [fetchResults count];
}

/*
- (void)displayAllMessagesOfType:(MessageType)type
{
	FMResultSet *rs = [self.appDelegate.appDb executeQuery:@"select * from mail where status = ?", [NSNumber numberWithInt:type]];
	NSString *to, *pk, *subject, *message = nil;
	NSInteger date;
	
	while ([rs next]) { 
		// Recover the call time 
		pk = [rs stringForColumn:@"pk"];
		to = [rs stringForColumn:@"recipients"]; 
		subject = [rs stringForColumn:@"subject"];
		message = [rs stringForColumn:@"message"];
		date = [rs intForColumn:@"date"];
		
		NSLog(@"pk: %@\nto: %@\nsubject: %@\nmessage: %@\ndate: %d", pk, to, subject, message, date);
	}
	
	[rs close];
}
*/

- (NSArray *)getResultSetFromQueue
{
/*
	return [self.appDelegate.appDb executeQuery:@"select * from mail where status = ?", [NSNumber numberWithInt:MessageTypeQueued]];
*/
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Message" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"status == NO"];
	[request setPredicate:pred];
	
	NSError *error = nil;
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
	if (fetchResults == nil) {
		// handle error here.
	}
	
	[request release];
	
	return fetchResults;
}

- (void)flushQueue
{
	NSLog(@"Flushing queue");
	
	if (self.appDelegate.hasNetworkConnection) {
		// 
		// retrieve all messages with a status of 0. (note for self, change 0 to some mnemonic constant)
		//
		
		NSArray *messages = [self getResultSetFromQueue];
		for (Message *message in messages) {
		// temporary. this will be replaced by just invoking emailInvocationOperation: with a message object 
		// instead of a dict.
			NSMutableDictionary *data = [NSMutableDictionary new];
			[data setValue:[message valueForKey:@"body"] forKey:@"body"];
			[data setValue:[message valueForKey:@"to"] forKey:@"recipients"];
			[data setValue:[message valueForKey:@"messageID"] forKey:@"messageID"];
			[data setValue:[message valueForKey:@"subject"] forKey:@"subject"];
			
			NSInvocationOperation *onlineEmailOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(emailInvocationOperation:) object:data];
			[networkOperationQueue addOperation:onlineEmailOperation];
				
			[onlineEmailOperation release];
			[data release];
		}
	}
}

@end