//
//  RssReader.h
//  TanukiPortfolio
//
//  Created by Takahiro Sayama on 2012/09/01.
//  Copyright (c) 2012年 tanuki-project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppController.h"
#import "rssItem.h"
#import "Bookmark.h"

#define	CRAWLING_TIMER_CMD_CNT			0
#define	CRAWLING_TIMER_CMD_CANCEL		1
#define	CRAWLING_TIMER_CMD_SCROLL		2

#define RSS_AUTOSCROLL_COUNT            8
#define RSS_WAIT_TIMER                  3.6

@interface RssReader : NSWindowController {
    MyDocument                      *parentDoc;
	NSMutableArray					*bookmarks;
    rssChannel                      *channel;
    NSMutableArray                  *rssItems;
    NSString                        *lastFeed;
    NSInteger                       cachePolicy;
    NSInteger                       fetchIndex;
    Boolean                         loading;
	NSString                        *documentTitle;
	NSString                        *documentUrl;
	NSMutableData                   *documentData;
	NSString                        *documentContent;
    NSURLConnection*                lastConnection;
    bool                            crawling;
	bool                            crawlingPaused;
    bool                            forward;
	int                             crawlingIndex;
	int                             crawlingDst;
	NSTimer*                        crawlingTimer;
	int                             crawlingTimerCmd;
    bool                            redirect;
    NSTimer*                        oneShotTimer;
    IBOutlet NSArrayController      *rssArray;
    IBOutlet NSTextField            *feedField;
    IBOutlet NSTextFieldCell        *feedTitle;
    IBOutlet NSButton               *forwardButton;
    IBOutlet NSButton               *backButton;
    IBOutlet NSButton               *linkButton;
    IBOutlet NSProgressIndicator    *progress;
	IBOutlet NSTableView            *tableView;
    IBOutlet NSComboBox             *comboBoxBookmark;
    IBOutlet NSWindow               *win;
    IBOutlet NSTextView             *textView;
}

- (IBAction)selectBookmark:(id)sender;
- (IBAction)fetch:(id)sender;
- (IBAction)fetchAll:(id)sender;
- (IBAction)fetchRSS:(id)sender;
- (IBAction)openItem:(id)sender;
- (IBAction)startRssConnection:(id)sender;
- (IBAction)crawlingRSS:(id)sender;
- (void)getFeed:(NSData*)urlData;
- (void)handleFeedChange:(NSNotification*)note;
- (void)actionDoubleClick:(id)sender;
- (void)startConnection:(NSURLRequest*)req;
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data;
- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
- (void)startCrawling:(int)indexFrom :(int)indexTo;
- (void)stopCrawling:(bool)warn;
- (void)continueCrawling;
- (void)pauseCrawling:(bool)pause;
- (void)startTimerCrawling:(int)cmd;
- (void)stopTimerCrawling;
- (void)checkTimerCrawling:(NSTimer*) timer;
- (void)loadBookmark;
- (void)saveBookmark;
- (void)setFontColor:(NSColor*)color;
- (void)localizeView;

/*
- (void)sortUsingDescriptors:(NSArray*)sortDescriptors;
- (void)tableView:(NSTableView*)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors;
- (IBAction)caseInsensitiveCompare:(id)sender;
*/

@property   (readwrite,retain)	NSMutableArray  *rssItems;
@property   (readwrite,assign)	NSTableView     *tableView;
@property   (readwrite,assign)  MyDocument      *parentDoc;
@property	(readwrite,retain)	NSMutableArray  *bookmarks;
@property	(readwrite)			bool			crawling;
@property	(readwrite)			bool			crawlingPaused;
@property	(readwrite)			bool			redirect;
@property   (readwrite,assign)  NSTextField     *feedField;

@end
