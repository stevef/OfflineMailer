//
//  OfflineViewController.h
//  OfflineMailer
//
//  Created by Steve Finkelstein on 4/5/09.
//  Copyright __InsertCompanyNameHere__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"

@interface OfflineViewController : UIViewController {
	NetworkStatus currentNetworkStatus;
}

- (void)reachabilityChanged:(NSNotification *)note;
- (void)updateNetworkStatus;

@end
