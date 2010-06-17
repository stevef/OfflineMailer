//
//  Contact.h
//  OfflineMailer
//
//  Created by Steve Finkelstein on 5/25/09.
//  Copyright __InsertCompanyNameHere__ 2009. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Contact : NSObject {
	NSString *firstName;
	NSString *lastName;
	NSString *email;
}

@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, copy) NSString *email;

- (id)initWithFirstName:(NSString *)fName lastName:(NSString *)lName email:(NSString *)anEmail;
- (NSString *)fullName;

@end
