//
//  OAToken_KeychainExtensions.m
//  TouchTheFireEagle
//
//  Created by Jonathan Wight on 04/04/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "OAToken_KeychainExtensions.h"

@implementation OAToken (OAToken_KeychainExtensions)

#if TARGET_OS_IPHONE

static NSString * const kTokenKey = @"token";
static NSString * const kTokenSecretKey = @"token_secret";

- (OSStatus)storeInKeychainForService:(NSString *)serviceName account:(NSString *)accountName
{
	return [self storeInKeychainForService:serviceName account:accountName accessGroup:nil];
}

- (OSStatus)storeInKeychainForService:(NSString *)serviceName account:(NSString *)accountName accessGroup:(NSString *)accessGroup
{
	NSParameterAssert( serviceName!=nil );
	NSParameterAssert( accountName!=nil );

	// prepare all credential information for storing:
	NSDictionary *oauthCredentials = [NSDictionary dictionaryWithObjectsAndKeys:
									  self.key, kTokenKey,
									  self.secret, kTokenSecretKey,
									  nil];
	NSData *credentialData = [NSKeyedArchiver archivedDataWithRootObject:oauthCredentials];

	// Regeardless what we do, all keychain APIs use a dictionary for storage, which we prepare here:
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								credentialData, (__bridge id)kSecAttrGeneric,
								accountName, (__bridge id)kSecAttrAccount,
								serviceName, (__bridge id) kSecAttrService,
								// accessGroup may be nil, so this MUST be the last K/V-pair
								accessGroup, (__bridge id) kSecAttrAccessGroup,
								nil];

	// There are two scenarios:
	// 1. There is nothing stored in the keychain for this service-name.
	// 2. We already have a token/secret pair that need to be updated.
	//
	// Due to the way OAuth works, scenario 1 is much more likely, so we handle it first.

	CFTypeRef result;
	OSStatus saveStatus = SecItemAdd((__bridge CFDictionaryRef)attributes, &result);
	if ( noErr == saveStatus ) return noErr;

	// Something went wrong!
	// If the reason was that an items with this combination of identifiers already exists, we can easily recover.
	// If not, we simply log the error and die here.
	NSLog(@"D'uh!");
	return saveStatus;
	
	return noErr;
}

- (id)initWithStoredCredentialsForService:(NSString *)serviceName account:(NSString *)accountName
{
	return [self initWithStoredCredentialsForService:serviceName account:accountName accessGroup:nil];
}

- (id)initWithStoredCredentialsForService:(NSString *)serviceName account:(NSString *)accountName accessGroup:(NSString *)accessGroup;
{
	NSParameterAssert( serviceName!=nil );
	NSParameterAssert( accountName!=nil );
	if ( !(self = [super init]) ) return nil;

	NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
						   (__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass,
						   serviceName, (__bridge id)kSecAttrService,
						   accountName, (__bridge id)kSecAttrAccount,
						   // this MUST be the last K/V-pair because access-group MAY be nil
						   accessGroup, (__bridge id)kSecAttrAccessGroup,
						   nil];
	CFDataRef result;
	OSStatus readStatus = SecItemCopyMatching( (__bridge CFDictionaryRef)query, (CFTypeRef *)&result);

	// TODO: Logging
	if ( noErr != readStatus || result == NULL ) return nil;

	NSDictionary *credentials = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge_transfer NSData*)result];
	NSString *token = [credentials objectForKey:kTokenKey];
	NSString *tokenSecret = [credentials objectForKey:kTokenSecretKey];

	if ( !token || !tokenSecret ) {
		NSLog(@"Failed to retrieve a valid credential pair for service '%@'/account '%@'!\nAccess group: %@", serviceName, accountName, accessGroup);
		return nil;
	}

	self.key = token;
	self.secret = tokenSecret;

	return self;
}

#else
- (id)initWithKeychainUsingAppName:(NSString *)name serviceProviderName:(NSString *)provider 
{
    if ( !(self = [super init]) ) return nil;

    SecKeychainItemRef item;
	NSString *serviceName = [NSString stringWithFormat:@"%@::OAuth::%@", name, provider];
	OSStatus status = SecKeychainFindGenericPassword(NULL,
													 strlen([serviceName UTF8String]),
													 [serviceName UTF8String],
													 0,
													 NULL,
													 NULL,
													 NULL,
													 &item);
    if (status != noErr) {
        return nil;
    }
    
    // from Advanced Mac OS X Programming, ch. 16
    UInt32 length;
    char *password;
    SecKeychainAttribute attributes[8];
    SecKeychainAttributeList list;
	
    attributes[0].tag = kSecAccountItemAttr;
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[2].tag = kSecLabelItemAttr;
    attributes[3].tag = kSecModDateItemAttr;
    
    list.count = 4;
    list.attr = attributes;
    
    status = SecKeychainItemCopyContent(item, NULL, &list, &length, (void **)&password);
    
    if (status == noErr) {
        self.key = [[NSString alloc] initWithBytes:list.attr[0].data
                                             length:list.attr[0].length
                                           encoding:NSUTF8StringEncoding];
        if (password != NULL) {
            char passwordBuffer[1024];
            
            if (length > 1023) {
                length = 1023;
            }
            strncpy(passwordBuffer, password, length);
            
            passwordBuffer[length] = '\0';
            self.secret = [NSString stringWithUTF8String:passwordBuffer];
        }
        
        SecKeychainItemFreeContent(&list, password);
        
    } else {
		// TODO find out why this always works in i386 and always fails on ppc
		NSLog(@"Error from SecKeychainItemCopyContent: %d", status);
        return nil;
    }
    
    return self;
}


- (OSStatus)storeInDefaultKeychainWithAppName:(NSString *)name serviceProviderName:(NSString *)provider 
{
    return [self storeInKeychain:NULL appName:name serviceProviderName:provider];
}

- (OSStatus)storeInKeychain:(SecKeychainRef)keychain appName:(NSString *)name serviceProviderName:(NSString *)provider 
{
	OSStatus status = SecKeychainAddGenericPassword(keychain,                                     
                                                    [name length] + [provider length] + 9, 
                                                    [[NSString stringWithFormat:@"%@::OAuth::%@", name, provider] UTF8String],
                                                    [self.key length],                        
                                                    [self.key UTF8String],
                                                    [self.secret length],
                                                    [self.secret UTF8String],
                                                    NULL
                                                    );
	return status;
}
#endif
@end
