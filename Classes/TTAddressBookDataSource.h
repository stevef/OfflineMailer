//
//  TTAddressBookDataSource.h
//  OfflineMailer
//
//  Created by Steve Finkelstein on 5/24/09.
//  Copyright 2009 __InsertCompanyNameHere__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Three20/Three20.h>
#import <AddressBook/AddressBook.h>

@class Contact;

@interface TTAddressBookDataSource : TTSectionedDataSource {
	NSArray *_names;
	NSArray *_contacts;
	NSMutableDictionary *contactsByName;
}

@property (nonatomic, retain) NSMutableDictionary *contactsByName;

+ (TTAddressBookDataSource *)abDataSourceForSearch:(BOOL)forSearch;

- (id)initWithNames:(NSArray*)names;

- (void)rebuildItems;

- (Contact *)contactWithName:(TTTableField *)name;

@end
