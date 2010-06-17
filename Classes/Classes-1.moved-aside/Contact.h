//
//  Contact.h
//  OfflineMailer
//
//  Created by Steve Finkelstein on 8/2/09.
//  Copyright 2009 __Insert Company Name Here__. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface Contact :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * contactID;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;

@end



