//
//  rssItem.h
//  Reader
//
//  Created by Takahiro Sayama on 2012/08/28.
//
//

#import <Foundation/Foundation.h>

@interface rssItem : NSObject {
    NSString*   title;
    NSString*   link;
    NSString*   pubDate;
    NSString*   feed;
    NSDate*     date;
    NSString*   description;
}

- (void)readItem:(NSXMLElement*)element;
- (void)removeLF;
- (void)removeT;
- (void)transZ;

@property	(readwrite,copy)	NSString*   title;
@property	(readwrite,copy)	NSString*   link;
@property	(readwrite,copy)	NSString*   pubDate;
@property	(readwrite,copy)	NSString*   feed;
@property	(readwrite,copy)	NSDate*     date;
@property	(readwrite,copy)	NSString*   description;

@end

@interface rssChannel : NSObject {
    NSString*   rss_version;
    NSString*   title;
    NSString*   link;
    NSString*   description;
    NSString*   lastBuildDate;
}

- (void)readChannel:(NSXMLDocument*)doc;
- (void)readFeed:(NSXMLDocument*)doc;
- (void)removeLF;

@property	(readwrite,copy)	NSString*   rss_version;
@property	(readwrite,copy)	NSString*   title;
@property	(readwrite,copy)	NSString*   link;
@property	(readwrite,copy)	NSString*   description;
@property	(readwrite,copy)	NSString*   lastBuildDate;

@end