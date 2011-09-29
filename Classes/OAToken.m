//
//  OAToken.m
//  OAuthConsumer
//
//  Created by Jon Crosby on 10/19/07.
//  Copyright 2007 Kaboomerang LLC. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


#import "OAToken.h"

#if TARGET_OS_IPHONE

static NSString * const kTokenKey = @"token";
static NSString * const kTokenSecretKey = @"token_secret";

static NSDictionary * sKeychainQueryForService_account_accessGroup(NSString *serviceName, NSString *accountName, NSString *accessGroup);

#define keychainError( error_constant, message_container ) case error_constant:\
	message_container = (__bridge NSString*)CFSTR(#error_constant);\
	break;

#endif


@implementation OAToken {
@protected
	NSString *key;
	NSString *secret;
}

@synthesize key, secret;

#pragma mark init

- (id)init
{
	if (self = [super init])
	{
		self->key = @"";
		self->secret = @"";
	}
    return self;
}

- (id)initWithKey:(NSString *)aKey secret:(NSString *)aSecret
{
	if (self = [super init])
	{
		self.key = aKey;
		self.secret = aSecret;
	}
	return self;
}

- (id)initWithHTTPResponseBody:(NSString *)body
{
	if (self = [super init])
	{
		NSArray *pairs = [body componentsSeparatedByString:@"&"];

		for (NSString *pair in pairs) {
			NSArray *elements = [pair componentsSeparatedByString:@"="];
			if ([[elements objectAtIndex:0] isEqualToString:@"oauth_token"]) {
				self.key = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			} else if ([[elements objectAtIndex:0] isEqualToString:@"oauth_token_secret"]) {
				self.secret = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			}
		}
	}
    return self;
}

#if TARGET_OS_IPHONE

- (OSStatus)storeInKeychainForService:(NSString *)serviceName account:(NSString *)accountName
{
	return [self storeInKeychainForService:serviceName account:accountName accessGroup:nil];
}

- (OSStatus)storeInKeychainForService:(NSString *)serviceName account:(NSString *)accountName accessGroup:(NSString *)accessGroup
{
	NSParameterAssert( serviceName!=nil );
	NSParameterAssert( accountName!=nil );

	// prepare all credential information for storing:
	NSMutableDictionary *oauthCredentials = [NSMutableDictionary dictionaryWithObjectsAndKeys:
											 self.key, kTokenKey,
											 self.secret, kTokenSecretKey,
											 nil];
	NSData *credentialData = [NSKeyedArchiver archivedDataWithRootObject:oauthCredentials];

	// Regeardless what we do, all keychain APIs use a dictionary for storage, which we prepare here:
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								(__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass,
								(__bridge id)kCFBooleanTrue, (__bridge id)kSecReturnAttributes,
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

	CFTypeRef result = NULL;
	OSStatus saveStatus = SecItemAdd((__bridge CFDictionaryRef)attributes, &result);
	if ( errSecSuccess == saveStatus ) return errSecSuccess;

	// Something went wrong!
	// If the reason was that an items with this combination of identifiers already exists, we can easily recover.
	// If not, we simply log the error and die here.

	if ( errSecDuplicateItem != saveStatus ) {
		NSString *error = @"an unknown error";
		switch (saveStatus) {
			keychainError( errSecNotAvailable, error);
			keychainError( errSecItemNotFound, error);
			keychainError( errSecDecode, error );
			keychainError(errSecAuthFailed, error);
			keychainError(errSecAllocate, error);
			keychainError(errSecInteractionNotAllowed, error);
			keychainError(errSecParam, error);
			keychainError(errSecUnimplemented, error);
			keychainError(errSecSuccess, error);
			default:
				break;
		}
		NSLog(@"Failed to store due to %@ (%ld)", error, saveStatus);
		return saveStatus;
	}

	// woohoo, we have the item present in the keychain, let's try updateing it
	NSDictionary *query = sKeychainQueryForService_account_accessGroup(serviceName, accountName, accessGroup);
	saveStatus = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributes);

	return saveStatus;
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


	NSDictionary *query = sKeychainQueryForService_account_accessGroup(serviceName, accountName, accessGroup);
	CFDictionaryRef result = NULL;
	OSStatus readStatus = SecItemCopyMatching( (__bridge CFDictionaryRef)query, (CFTypeRef *)&result);

	// TODO: Logging
	if ( errSecSuccess != readStatus || result == NULL ) return nil;

	CFDataRef credentialData = CFDictionaryGetValue(result, kSecAttrGeneric);
	NSDictionary *credentials = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData*)credentialData];
	CFRelease(result);
	NSString *token = [credentials objectForKey:kTokenKey];
	NSString *tokenSecret = [credentials objectForKey:kTokenSecretKey];

	if ( !token || !tokenSecret ) {
		NSLog(@"Failed to retrieve a valid credential pair for service '%@'/account '%@'!\nAccess group: %@", serviceName, accountName, accessGroup);
		return nil;
	}

	self->key = token;
	self->secret = tokenSecret;

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

#if TARGET_OS_IPHONE

static NSDictionary *sKeychainQueryForService_account_accessGroup(NSString *serviceName, NSString *accountName, NSString *accessGroup)
{
	NSCParameterAssert( serviceName!=nil );
	NSCParameterAssert( accountName!=nil );

	NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
						   (__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass,
						   serviceName, (__bridge id)kSecAttrService,
						   accountName, (__bridge id)kSecAttrAccount,
						   (__bridge id)kCFBooleanTrue, (__bridge id)kSecReturnAttributes,
						   // this MUST be the last K/V-pair because access-group MAY be nil
						   accessGroup, (__bridge id)kSecAttrAccessGroup,
						   nil];

	return query;
}

#endif
