//
//  TTAddressBookDataSource.m
//  OfflineMailer
//
//  Created by Steve Finkelstein on 5/24/09.
//  Copyright 2009 __InsertCompanyNameHere__. All rights reserved.
//

#import "TTAddressBookDataSource.h"
#import "OfflineMailerAppDelegate.h"
#import "Contact.h"

@implementation TTAddressBookDataSource
@synthesize contactsByName;

- (void)dealloc
{
	[_names release];
	[_contacts release];
	[contactsByName release];
	
	[super dealloc];
}

+ (TTAddressBookDataSource *)abDataSourceForSearch:(BOOL)forSearch
{
	ABAddressBookRef addressBook = ABAddressBookCreate();
	NSArray *peopleArray = (NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
	NSMutableArray *allContacts = [NSMutableArray array];
	
	for (id person in peopleArray) {
	  if ([(NSString *)ABRecordCopyValue(person, kABPersonOrganizationProperty) autorelease]) continue;
	  NSMutableString *firstName = [(NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty) autorelease];
	  NSMutableString *lastName = [(NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty) autorelease];
	  ABMutableMultiValueRef multiValueEmail = ABRecordCopyValue(person, kABPersonEmailProperty);
		
	  NSString *email = nil;
	  if (ABMultiValueGetCount(multiValueEmail) > 0) {
			email = [(NSString *)ABMultiValueCopyValueAtIndex(multiValueEmail, 0) autorelease];
	  } else {
			continue;
		}
				
	  Contact *aContact = [[[Contact alloc] initWithFirstName:firstName lastName:lastName email:email] autorelease];
		[allContacts addObject:aContact];
		
		/*
		OfflineMailerAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
		Contact *contact = (Contact *)[NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:appDelegate.managedObjectContext];

		[contact setFirstName:firstName];
		[contact setLastName:lastName];
		[contact setEmail:email];
	
		// Commit the change.
		NSError *error;
		if (![appDelegate.managedObjectContext save:&error]) {
			// Handle the error.
			NSString *errorMsg = @"An error has occurred saving the managed object context.";
			UIAlertView *anAlert = 
				[[[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] autorelease];
			[anAlert show];
		}
		*/
	
	}
	
	TTAddressBookDataSource *dataSource =  [[[TTAddressBookDataSource alloc] initWithNames:allContacts] autorelease];

	if (!forSearch) {
		[dataSource rebuildItems];
	}

	CFRelease(addressBook);
	
	return dataSource;
}

- (id)initWithNames:(NSArray*)names {
  if (self = [super init]) {
    _names = [names copy];
		contactsByName = [NSMutableDictionary new];
	
		for (Contact *aContact in _names) {
			NSMutableString *fullName = [[[NSMutableString alloc] initWithString:[aContact fullName]] autorelease];
			[fullName replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [fullName length])];
			[self.contactsByName setObject:aContact forKey:fullName];
		}
  }
  return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
// UITableViewDataSource

- (NSArray*)sectionIndexTitlesForTableView:(UITableView*)tableView {
  return [self lettersForSectionsWithSearch:YES withCount:NO];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// TTTableViewDataSource

- (NSString*)tableView:(UITableView*)tableView labelForObject:(id)object {
  TTTableField* field = object;
  return field.text;
}

- (void)tableView:(UITableView*)tableView prepareCell:(UITableViewCell*)cell
        forRowAtIndexPath:(NSIndexPath*)indexPath {
  cell.accessoryType = UITableViewCellAccessoryNone;
}

- (void)tableView:(UITableView*)tableView search:(NSString*)text {
  [_sections release];
  _sections = nil;
  [_items release];

  if (text.length) {
    _items = [[NSMutableArray alloc] init];
    
    text = [text lowercaseString];
	for (Contact *aContact in _names) {
	  NSString *name = [aContact fullName];
	  // blurb here about NSNotFound vs == 0.
      if ([[name lowercaseString] rangeOfString:text].location != NSNotFound) {
        TTTableField* field = [[[TTTableField alloc] initWithText:name url:aContact.email] autorelease];
        [_items addObject:field];
      }
    }    
  } else {
    _items = nil;
  }
  
  [self dataSourceDidFinishLoad];
}

- (Contact *)contactWithName:(TTTableField *)name
{
	NSMutableString *trimmedName = [[[NSMutableString alloc] initWithString:name.text] autorelease];
	[trimmedName replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [trimmedName length])];
	Contact *aContact = [self.contactsByName objectForKey:trimmedName];
	
	return aContact;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)rebuildItems 
{
	NSMutableDictionary *map = [NSMutableDictionary dictionary];
	for (Contact *aContact in _names) {
	  NSString *letter = [NSString stringWithFormat:@"%c", [aContact.firstName characterAtIndex:0]];
	  NSMutableArray *section = [map objectForKey:letter];
	  if (!section) {
			section = [NSMutableArray array];
			[map setObject:section forKey:letter];
	  }
	  
	  NSString *fullName = [NSString stringWithFormat:@"%@ %@", aContact.firstName, aContact.lastName];
	  TTTableField *field = [[[TTTableField alloc] initWithText:fullName url:aContact.email] autorelease];
	  [section addObject:field];
	  
	  [_items release];
	  _items = [NSMutableArray new];
	  [_sections release];
	  _sections = [NSMutableArray new];
	  
	  NSArray *letters = [map.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	  
	  for (NSString *letter in letters) {
			NSArray *items = [map objectForKey:letter];
			[_sections addObject:letter];
			[_items addObject:items];
	  }
	}
}


@end
