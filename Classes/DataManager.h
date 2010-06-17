//
//  DataManager.h
//  OfflineMailer
//
//  Created by Steve Finkelstein on 5/20/09.
//  Copyright 2009 __InsertCompanyNameHere__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SKPSMTPMessage.h"

typedef enum {
	MessageTypeQueued = 0, 
	MessageTypeSent
} MessageType;

@class OfflineMailerAppDelegate;

@interface DataManager : NSObject <SKPSMTPMessageDelegate> {
	NSString *hostName;
	NSString *smtpUserName;
	NSString *smtpPassword;
	NSNumber *smtpPort;
	
	NSOperationQueue *networkOperationQueue;
	
	NSMutableDictionary *queuedMessages;
	NSMutableDictionary *sentMessages;
	
	OfflineMailerAppDelegate *appDelegate;
	
	NSManagedObjectContext *managedObjectContext;
}

@property (nonatomic, retain) NSString *hostName;
@property (nonatomic, retain) NSString *smtpUserName;
@property (nonatomic, retain) NSString *smtpPassword;
@property (nonatomic, retain) NSNumber *smtpPort;

@property (nonatomic, retain) NSMutableDictionary *queuedMessages;
@property (nonatomic, retain) NSMutableDictionary *sentMessages;

@property (nonatomic, assign) OfflineMailerAppDelegate *appDelegate;

// operation queues for network 
@property (nonatomic, retain) NSOperationQueue *networkOperationQueue;

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

- (void)loadDefaultSettings;

- (void)sendEmailWithFields:(NSArray *)fields forContacts:(NSArray *)contacts;
- (void)emailInvocationOperation:(id)data;
- (void)messageSent:(SKPSMTPMessage *)message;

+ (DataManager *)sharedDataManager;

// database methods
- (NSUInteger)numberOfMessagesInQueue;
- (NSUInteger)numberOfMessagesSent;

// - (void)displayAllMessagesOfType:(MessageType)type;

- (void)flushQueue;

@end
