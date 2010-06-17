//
//  OfflineMailerAppDelegate.h
//  OfflineMailer
//
//  Created by Steve Finkelstein on 4/5/09.
//  Copyright __InsertCompanyNameHere__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"

@interface OfflineMailerAppDelegate : NSObject <UIApplicationDelegate> {
	
	// Core Data Additions
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;	    
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
		
	UIWindow *window;
	UINavigationController *navigationController;
	
	// Network status
	NetworkStatus remoteHostStatus;	// server status.
	NetworkStatus internetConnectionStatus; // carrier data network.
	NetworkStatus localWiFiConnectionStatus; // wifi network.
	BOOL hasNetworkConnection;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;

@property NetworkStatus remoteHostStatus;
@property NetworkStatus internetConnectionStatus;
@property NetworkStatus localWiFiConnectionStatus;
@property (assign) BOOL hasNetworkConnection;

@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, readonly) NSString *applicationDocumentsDirectory;

- (IBAction)saveAction:sender;

#pragma mark -
- (void)reachabilityChanged:(NSNotification *)notification;
- (void)updateNetworkStatus;

@end

