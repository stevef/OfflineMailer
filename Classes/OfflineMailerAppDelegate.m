//
//  OfflineMailerAppDelegate.m
//  OfflineMailer
//
//  Created by Steve Finkelstein on 4/5/09.
//  Copyright __InsertCompanyNameHere__ 2009. All rights reserved.
//

#define OFFLINE_DB_NAME @"offline.sql"

#import "OfflineMailerAppDelegate.h"
#import "AccountViewController.h"
#import "DataManager.h"
#import "SettingsViewController.h"

@interface OfflineMailerAppDelegate (OMPrivate)
@end

@implementation OfflineMailerAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize remoteHostStatus;
@synthesize internetConnectionStatus;
@synthesize localWiFiConnectionStatus;
@synthesize hasNetworkConnection;

#pragma mark -
#pragma mark Memory Management
- (void)dealloc 
{
	[managedObjectModel release];
	[managedObjectContext release];
	[persistentStoreCoordinator release];
	
	[window release];
	[navigationController release];
	
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {    

	// register for offline/online notifications.
	[[NSNotificationCenter defaultCenter] 
		addObserver:self 
		selector:@selector(reachabilityChanged:) 
		name:@"kNetworkReachabilityChangedNotification" 
		object:nil];
		
	AccountViewController *rootViewController =
		[[[AccountViewController alloc] init] autorelease];
	[rootViewController setManagedObjectContext:[self managedObjectContext]];
	
	[[DataManager sharedDataManager] setManagedObjectContext:[self managedObjectContext]];

	// SMTP might not require authentication, so we only check if there
	// is a remote hostname available.
	NSString *remoteServer = [[DataManager sharedDataManager] hostName];

	// Here we ensure we have the settings we need to proceed.
	if (remoteServer == nil) 
	{
		SettingsViewController *settingsController = [[[SettingsViewController alloc] init] autorelease];
		navigationController =
			[[UINavigationController alloc]
			initWithRootViewController:settingsController];		
		navigationController.navigationBarHidden = YES;
	} else {
		navigationController =
			[[UINavigationController alloc]
				initWithRootViewController:rootViewController];
		
		[[Reachability sharedReachability] setHostName:remoteServer];
		[self updateNetworkStatus];
	}
	
	//BOOL success = [self initDatabase];
	
	// Note, we might not want to throw an exception if the database isn't
	// reachable in a production application. We could instead let the application
	// continue to launch as expected. However, when offline, we need to take heed
	// and let our users know.
	//if (!success) {
	//	NSAssert(0, @"Failed to initialize database.");
	//}
	
	[window addSubview:navigationController.view];
	[window makeKeyAndVisible];
}

/**
 applicationWillTerminate: saves changes in the application's managed object context before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication *)application {
	NSError *error;
	if (managedObjectContext != nil) {
		if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
			// Handle error.
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			exit(-1);  // Fail
		} 
	}
}

#pragma mark -
#pragma mark Saving

/**
 Performs the save action for the application, which is to send the save:
 message to the application's managed object context.
 */
- (IBAction)saveAction:(id)sender {
	
    NSError *error;
    if (![[self managedObjectContext] save:&error]) {
		// Handle error
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail
    }
}

#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
	
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return managedObjectContext;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
	if (managedObjectModel != nil) {
			return managedObjectModel;
	}
	managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
	return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
	if (persistentStoreCoordinator != nil) {
			return persistentStoreCoordinator;
	}

	NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"offlinemailer.sqlite"]];

	NSError *error;
	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
	if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {
			// Handle error
	}    

	return persistentStoreCoordinator;
}

#pragma mark -
#pragma mark Application's documents directory

/**
 Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}


#pragma mark -
#pragma mark Database Methods
/*
- (BOOL)initDatabase
{
		
	// We only create the database here if needed. The default database schema is
	// added as a resource. [offline.sql] 
	// modeled after Apple's SQLiteBooks sample -- as noted by Apple, we first
	// check for an existing database. If it doesn't exist, only then will we copy
	// the db provided with our App Bundle.
	
	BOOL success = NO;
	BOOL openError = NO;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error;
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:OFFLINE_DB_NAME];
	success = [fileManager fileExistsAtPath:writableDBPath];
	if (success) {
		self.appDb = [FMDatabase databaseWithPath:writableDBPath];
		if (![self.appDb open]) {
			openError = TRUE;
			return openError;
		}
		
		[self.appDb setLogsErrors:TRUE];
		return success;
	}
	
	// The writable database does not exist, so copy the default to the appropriate location.
	NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:OFFLINE_DB_NAME];
	success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
	if (!success) {
			NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
	}
	
	return success;
}
*/
#pragma mark - 
#pragma mark Network Connectivity
- (void)reachabilityChanged:(NSNotification *)notification
{
	[self updateNetworkStatus];
}

- (void)updateNetworkStatus
{
	// Query the SystemConfiguration framework for the state of the device's network connections.
	self.remoteHostStatus						= [[Reachability sharedReachability] remoteHostStatus];
	self.internetConnectionStatus		= [[Reachability sharedReachability] internetConnectionStatus];
	self.localWiFiConnectionStatus	= [[Reachability sharedReachability] localWiFiConnectionStatus];
	
	if (self.remoteHostStatus == NotReachable || self.internetConnectionStatus == NotReachable) {
		// we aren't reachable.
		self.hasNetworkConnection = NO;
	} else {
		self.hasNetworkConnection = YES;
	}
}



@end
