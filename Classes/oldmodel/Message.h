//
//  Message.h
//  OfflineMailer
//
//  Created by Steve Finkelstein on 6/13/09.
//  Copyright 2009 __Insert Company Name Here__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Message : NSObject 
{
	NSString *message_id;
	NSString *recipients;
	NSString *subject;
	NSString *message;
	NSInteger dateSent;
}

@property (nonatomic, retain) NSString *message_id;
@property (nonatomic, retain) NSString *recipients;
@property (nonatomic, retain) NSString *subject;
@property (nonatomic, retain) NSString *message;
@property (nonatomic, assign) NSInteger dateSent;

@end
