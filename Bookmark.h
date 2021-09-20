//
//  Bookmark.h
//  tPortfolio
//
//  Created by Takahiro Sayama on 11/01/10.
//  Copyright 2011 tanuki-project. All rights reserved.
//

#import		<Foundation/Foundation.h>

#define	MAX_BOOKMARK_NUM	50

@interface Bookmark : NSObject {
	NSString*	title;
	NSString*	url;
}

- (id) init;
- (void)setBookmark:(NSString*)newTitle :(NSString*)newUrl;
- (bool)isEqualBookmark:(Bookmark*)src :(Bookmark*)dst;

@property	(readwrite,copy)	NSString*		title;
@property	(readwrite,copy)	NSString*		url;
@end
