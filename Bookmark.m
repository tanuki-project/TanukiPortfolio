//
//  Bookmark.m
//  tPortfolio
//
//  Created by Takahiro Sayama on 11/01/10.
//  Copyright 2011 tanuki-project. All rights reserved.
//

#import		"Bookmark.h"
#include	"PreferenceController.h"

@implementation Bookmark
- (id)init
{
    self = [super init];
	title = nil;
	url = nil;
	return self;
}

- (void)dealloc
{
	if (title) {
		[title release];
	}
	if (url) {
		[url release];
	}
	[super dealloc];
}

- (void)setBookmark:(NSString*)newTitle :(NSString*)newUrl
{
	if (title) {
		[title release];
	}
	if (url) {
		[url release];
	}
	if (newTitle) {
		title = [newTitle retain];
	} else {
		title = nil;
	}
	url = [newUrl retain];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	// NSLog(@"encodeWithCoder @% @%", title, url);
	[coder encodeObject:title forKey:@"title"];
	[coder encodeObject:url forKey:@"url"];
}

- (id)initWithCoder:(NSCoder *)coder
{
	self = [super init];
	title = [[coder decodeObjectForKey:@"title"] retain];
	url = [[coder decodeObjectForKey:@"url"] retain];
	// NSLog(@"initWithCoder @% @%", title, url);
	return self;
}

- (bool)isEqualBookmark:(Bookmark*)src :(Bookmark*)dst
{
	if ([[src url] isEqualToString:[dst url]] &&
		[[src title] isEqualToString:[dst title]]) {
		return YES;
	}
	return NO;
}

@synthesize		title;
@synthesize		url;
@end
