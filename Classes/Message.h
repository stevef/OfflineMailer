//
//  Message.h
//  OfflineMailer
//
//  Created by Steve Finkelstein on 8/4/09.
//  Copyright 2009 __Insert Company Name Here__. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface Message :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * subject;
@property (nonatomic, retain) NSNumber * dateSent;
@property (nonatomic, retain) NSString * messageID;
@property (nonatomic, retain) NSString * to;
@property (nonatomic, retain) NSString * body;

@end



