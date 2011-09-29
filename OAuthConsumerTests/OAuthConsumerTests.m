//
//  OAuthConsumerTests.m
//  OAuthConsumerTests
//
//  Created by Daniel Demiss on 29.09.11.
//  Copyright (c) 2011 CELLULAR GmbH. All rights reserved.
//

#import "OAuthConsumerTests.h"
#import "OAToken.h"
#import <Security/Security.h>

static NSString *const service = @"tweeeter";
static NSString *const account = @"dude";
static NSString *const accessGroup = @"the.full.monty"; // this MUST be written in the Entitlements.plist

static NSString *const asciiToken = @"asdfghjklqwertzuiop";
static NSString *const asciiTokenSecret = @"yxcvbnm,.-1234567890";

static NSString *const utf8Token = @"asdfghjklöä";
static NSString *const utf8TokenSecret = @"Iñtërnâtiônàlizætiøn";

static NSDictionary *sQueryDictionaryWithAccessGroup(BOOL shouldIncludeAccessGroup);
static void sDeleteOldStuff();

@implementation OAuthConsumerTests


- (void)setUp
{
	[super setUp];
	sDeleteOldStuff();
}

- (void)tearDown
{
	[super tearDown];
	sDeleteOldStuff();
}

- (void)testLoadStoreSimpleASCII
{
	OAToken *originalToken = [[OAToken alloc] initWithKey:asciiToken secret:asciiTokenSecret];

	OSStatus saveStatus = [originalToken storeInKeychainForService:service account:account];
	STAssertTrue(errSecSuccess==saveStatus, @"Actual status: %ld\nparameters %@ %@", saveStatus, service, account);

	OAToken *loadedToken = [[OAToken alloc] initWithStoredCredentialsForService:service account:account];
	STAssertNotNil(loadedToken.key, @"loaded token did not contain the key", nil);
	STAssertNotNil(loadedToken.secret, @"token did not contain the secret", nil);

	STAssertEqualObjects(originalToken.key, loadedToken.key, @"original and stored tokens were not equal!", nil);
	STAssertEqualObjects(originalToken.secret, loadedToken.secret, @"original and stored secrets were not equal!", nil);
}

- (void)testLoadStoreFullASCII
{
#warning This test fails: I don't know if the implementation is really incorrect or if I'm just too stupid to set up my test rig :-/
#warning I guess, it's the latter case...
	OAToken *originalToken = [[OAToken alloc] initWithKey:asciiToken secret:asciiTokenSecret];

	OSStatus saveStatus = [originalToken storeInKeychainForService:service account:account accessGroup:accessGroup];
	STAssertTrue(errSecSuccess==saveStatus, @"actual status: %ld\nparameters %@ %@ %@", saveStatus, service, account, accessGroup);

	OAToken *loadedToken = [[OAToken alloc] initWithStoredCredentialsForService:service account:account accessGroup:accessGroup];
	STAssertNotNil(loadedToken.key, @"loaded token did not contain the key", nil);
	STAssertNotNil(loadedToken.secret, @"token did not contain the secret", nil);
	
	STAssertEqualObjects(originalToken.key, loadedToken.key, @"original and stored tokens were not equal!", nil);
	STAssertEqualObjects(originalToken.secret, loadedToken.secret, @"original and stored secrets were not equal!", nil);	
}

- (void)testLoadStoreSimpleUTF8
{
	OAToken *originalToken = [[OAToken alloc] initWithKey:utf8Token	secret:utf8TokenSecret];

	OSStatus saveStatus = [originalToken storeInKeychainForService:service account:account];
	STAssertTrue(errSecSuccess==saveStatus, @"Actual status: %ld\nparameters %@ %@", saveStatus, service, account);

	OAToken *loadedToken = [[OAToken alloc] initWithStoredCredentialsForService:service account:account];
	STAssertNotNil(loadedToken.key, @"loaded token did not contain the key", nil);
	STAssertNotNil(loadedToken.secret, @"token did not contain the secret", nil);
	
	STAssertEqualObjects(originalToken.key, loadedToken.key, @"original and stored tokens were not equal!", nil);
	STAssertEqualObjects(originalToken.secret, loadedToken.secret, @"original and stored secrets were not equal!", nil);
}

- (void)testLoadStoreFullUTF8
{
#warning This test fails: I don't know if the implementation is really wrong or if I'm just too stupid to set up my test rig :-/
#warning I guess, it's the latter case...
	OAToken *originalToken = [[OAToken alloc] initWithKey:utf8Token	secret:utf8TokenSecret];
	OSStatus saveStatus = [originalToken storeInKeychainForService:service account:account accessGroup:accessGroup];

	STAssertTrue(errSecSuccess==saveStatus, @"Actual status: %ld\nparameters %@ %@ %@", saveStatus, service, account, accessGroup);
	OAToken *loadedToken = [[OAToken alloc] initWithStoredCredentialsForService:service account:account accessGroup:accessGroup];
	STAssertNotNil(loadedToken.key, @"loaded token did not contain the key", nil);
	STAssertNotNil(loadedToken.secret, @"token did not contain the secret", nil);
	
	STAssertEqualObjects(originalToken.key, loadedToken.key, @"original and stored tokens were not equal!", nil);
	STAssertEqualObjects(originalToken.secret, loadedToken.secret, @"original and stored secrets were not equal!", nil);
}

@end

static NSDictionary *sQueryDictionaryWithAccessGroup(BOOL flag)
{
	NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
						   (__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass,
						   (flag ? accessGroup : nil), (__bridge id)kSecAttrAccessGroup,
						   nil];
	return query;
}

static void sDeleteOldStuff()
{
	NSDictionary *query = sQueryDictionaryWithAccessGroup(NO);
	OSStatus deletionStatus = SecItemDelete((__bridge CFDictionaryRef)query);
	NSLog(@"status without: %ld", deletionStatus);
	
	query = sQueryDictionaryWithAccessGroup(YES);
	deletionStatus = SecItemDelete((__bridge CFDictionaryRef)query);
	NSLog(@"status with: %ld", deletionStatus);
}