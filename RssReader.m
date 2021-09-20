//
//  RssReader.m
//  TanukiPortfolio
//
//  Created by Takahiro Sayama on 2012/09/01.
//  Copyright (c) 2012年 tanuki-project. All rights reserved.
//

#import     "RssReader.h"
#import     "MyDocument.h"
#include    "WebDocumentReader.h"

extern	AppController	*tPrtController;
extern	PortfolioItem	*tPrtPortfolioItem;

extern  NSString    *tPrtFeedListKey;
extern  NSString    *tPrtLastFeedKey;

Boolean             enableTimer = YES;
extern bool         enableRedirect;

@interface RssReader ()

@end

@implementation RssReader

- (id)init
{
	NSLog(@"init RssReader");
	if (self) {
        self = [super initWithWindowNibName:@"RssReader"];
        channel = [[rssChannel alloc] init];
        rssItems = [[NSMutableArray alloc] init];
        bookmarks = nil;
        lastFeed = nil;
        cachePolicy = NSURLRequestReturnCacheDataElseLoad;
        //timer = nil;
        //timerIndex = 0;
        fetchIndex = 0;
        loading = NO;
        documentTitle = nil;
        documentUrl = nil;
        documentContent = nil;
        documentData = nil;
        lastConnection = nil;
        crawling = NO;
        crawlingPaused = NO;
        //crawlingList=nil;
        crawlingIndex = 0;
        crawlingDst = 0;
        crawlingTimer = nil;
        redirect = NO;
        oneShotTimer = nil;
	}
    return self;
}

- (void)dealloc
{
	NSLog(@"dealloc RssReader");
    [rssItems removeAllObjects];
    if (bookmarks) {
        [bookmarks release];
    }
    [self stopCrawling:NO];
	[super dealloc];
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [tableView setDoubleAction:@selector(actionDoubleClick:)];
    [self localizeView];
	[self loadBookmark];
    [tableView setTarget:self];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* urlKey = [defaults objectForKey:tPrtLastFeedKey];
    if (urlKey) {
        [feedField setStringValue:urlKey];
    } else {
        NSString* lang = NSLocalizedString(@"LANG",@"English");
        NSLog(@"localizeView: %@", lang);
        if ([lang isEqualToString:@"Japanese"]) {
            [feedField setStringValue:@"feed://www.apple.com/jp/main/rss/hotnews/hotnews.rss"];
        } else {
            [feedField setStringValue:@"feed://www.apple.com/main/rss/hotnews/hotnews.rss"];
        }
    }
	NSData *colorAsData;
	colorAsData = [defaults objectForKey:tPrtTableBgColorKey];
	//[tableView setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];
	[tableView setBackgroundColor:[NSKeyedUnarchiver unarchiveObjectWithData:colorAsData]];
    NSNotificationCenter *nc=[NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(actionSelected:)
               name:NSTableViewSelectionDidChangeNotification
             object:tableView];
	colorAsData = [defaults objectForKey:tPrtTableFontColorKey];
	[self setFontColor:[NSKeyedUnarchiver unarchiveObjectWithData:colorAsData]];
    [tableView reloadData];
    [linkButton setEnabled:NO];
    if (redirect == NO) {
        if ([[feedField stringValue] isEqualToString:@""]) {
            [self fetchAll:self];
        } else {
            [self fetchRSS:self];
        }
    }
    cachePolicy = NSURLRequestReloadRevalidatingCacheData;
    return;
}

- (void)actionSelected:(NSNotification *)notification {
    if ([notification object] != tableView) {
        return;
    }
	if (oneShotTimer) {
		[oneShotTimer invalidate];
		[oneShotTimer release];
		oneShotTimer = nil;
	}
	oneShotTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1
                                                     target:self
                                                   selector:@selector(showSelectedRow:)
                                                   userInfo:nil
                                                    repeats:NO] retain];
    return;
}

- (void)showSelectedRow:(NSTimer*)timer
{
    NSInteger row = [tableView selectedRow];
    if (row == -1) {
        [textView setString:@""];
        return;
    }
    NSLog(@"actionSelected: %ld", (long)row);
    rssItem *item = [rssItems objectAtIndex:row];
    if (item && [item description]) {
        NSDictionary *dic = [[NSDictionary alloc] init];
        NSData *data = [[item description] dataUsingEncoding:NSUTF16StringEncoding];
        NSAttributedString *as = [[NSAttributedString alloc] initWithHTML:data options:dic documentAttributes:nil];
        if (as) {
            [[textView textStorage] setAttributedString:as];
            NSFont *font = [NSFont systemFontOfSize:15];
            [[textView textStorage] setFont:font];
            NSLog(@"font = %@", [[textView textStorage]font]);
            [as release];
        } else {
            [textView setString:[item description]];
        }
        [dic release];
    } else {
        [textView setString:@""];
    }
}

- (IBAction)fetch:(id)sender
{
    if ([[feedField stringValue] hasPrefix:@"http://"] == NO &&
        [[feedField stringValue] hasPrefix:@"https://"] == NO &&
        [[feedField stringValue] hasPrefix:@"feed://"] == NO) {
        return;
    }
    if ([lastFeed isEqualToString:[feedField stringValue]] == YES) {
        return;
    }
    if (loading == YES) {
        return;
    }
    NSSound *sound = [NSSound soundNamed:@"Pop"];
    [sound play];
    [self stopCrawling:YES];
    [self fetchRSS:sender];
    return;
}

- (IBAction)fetchRSS:(id)sender
{
    [rssItems removeAllObjects];
    [rssArray rearrangeObjects];
    [tableView reloadData];
    [linkButton setHidden:YES];
    [progress setHidden:NO];
    [progress startAnimation:nil];
    [rssItems removeAllObjects];
    [rssArray rearrangeObjects];
    [tableView reloadData];
    [feedField setEnabled:NO];
    [forwardButton setEnabled:NO];
    [backButton setEnabled:NO];
    loading = NO;
    NSTableColumn *column = [tableView tableColumnWithIdentifier:@"Feed"];
    [column setHidden:YES];
    [self startRssConnection:self];
    return;
}

- (IBAction)fetchAll:(id)sender
{
    if ([bookmarks count] == 0) {
        return;
    }
    if (loading == YES) {
        loading = NO;
        return;
    }
    [self stopCrawling:YES];
    [linkButton setEnabled:NO];
    [linkButton setHidden:YES];
    [progress setHidden:NO];
    [progress startAnimation:nil];
    [rssItems removeAllObjects];
    [rssArray rearrangeObjects];
    [tableView reloadData];
    [feedField setEnabled:NO];
    [forwardButton setEnabled:NO];
    [backButton setEnabled:NO];
    fetchIndex = 0;
    loading = YES;
    NSTableColumn *column = [tableView tableColumnWithIdentifier:@"Feed"];
    [column setHidden:NO];

    Bookmark* feed = [bookmarks objectAtIndex:fetchIndex];
    if (feed) {
        [feedField setStringValue:[feed url]];
        [self startRssConnection:self];
    }
    fetchIndex++;
}

- (void)getFeed:(NSData*)urlData
{
	NSXMLDocument		*doc = nil;
	NSError             *error;
    boolean_t           bFeed;
    if (urlData == nil) {
        return;
    }
    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
                                     defaultButton:NSLocalizedString(@"OK",@"Ok")
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"PARSE_RSS_FAILED", @"Failed to parse RSS.")];

	doc = [[NSXMLDocument alloc] initWithData:urlData
									  options:NSXMLDocumentTidyXML
										error:&error];
	if (!doc) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
        [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
        //[feedField setStringValue:@""];
		return;
	}

    NSArray* itemNodes = nil;
    itemNodes = [[doc nodesForXPath:@"//feed" error:&error] retain];
    if (itemNodes && [itemNodes count] > 0) {
        bFeed = YES;
    } else {
        bFeed = NO;
    }
    if (itemNodes) {
        [itemNodes release];
    }
    if (bFeed == NO) {
        itemNodes = [[doc nodesForXPath:@"//channel" error:&error] retain];
        if (itemNodes == nil) {
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert runModal];
            [doc release];
            [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
            //[feedField setStringValue:@""];
            return;
        }
        if ([itemNodes count] == 0) {
            [itemNodes release];
            [doc release];
            [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
            //[feedField setStringValue:@""];
            if (redirect == YES) {
                if (enableRedirect == YES) {
                    enableRedirect = NO;
                    [parentDoc jumpUrl:[feedField stringValue] :NO];
                    enableRedirect = YES;
                } else {
                    [parentDoc jumpUrl:[feedField stringValue] :NO];
                }
                redirect = NO;
            }
            return;
        }
        [itemNodes release];
    }
    if (bFeed) {
        [channel readFeed:doc];
    } else {
        [channel readChannel:doc];
    }
    [feedTitle setTitle:[channel title]];
    [win setTitle:[channel title]];

    if (bFeed) {
        itemNodes = [[doc nodesForXPath:@"//entry" error:&error] retain];
    } else {
        itemNodes = [[doc nodesForXPath:@"//item" error:&error] retain];
    }
	if (itemNodes == nil) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
        [doc release];
        [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
        //[feedField setStringValue:@""];
		return;
	}
    [itemNodes release];
    
    for (NSXMLElement* element in itemNodes) {
        if ([element kind] != NSXMLElementKind) {
            continue;
        }
        rssItem* item = [[rssItem alloc] init];
        [item readItem:element];
        if ([item link] && [[item link] isEqualToString:@""] == NO) {
            [item setFeed:[channel title]];
            [rssItems addObject:item];
        }
        [item release];
    }
    if ([rssItems count] > 0) {
        [linkButton setEnabled:YES];
    }
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[feedField stringValue] forKey:tPrtLastFeedKey];
    if (lastFeed) {
        [lastFeed release];
    }
    lastFeed = [[NSString alloc] initWithString:[feedField stringValue]];
	NSLog(@"tableView = %@", tableView);
    NSLog(@"%@",[feedTitle title]);
    
    // Sort Items
    NSSortDescriptor	*descriptor;
    NSMutableArray		*sortDescriptors = [[NSMutableArray alloc] init];
    descriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO selector:@selector(compare:)];
    [sortDescriptors addObject:descriptor];
    [rssItems sortUsingDescriptors:sortDescriptors];
    [descriptor release];
    [sortDescriptors release];

    [rssArray rearrangeObjects];
	[tableView reloadData];
    [doc release];
    return;
}

- (IBAction)openItem:(id)sender
{
	NSInteger	row = [tableView selectedRow];
	//if (row == -1) {
    //    row = [tableView selectedRow];
    //}
	NSLog(@"openItem: row=%lu", (long)row);
	if (row == -1) {
        [linkButton setState:NO];
		return;
	}
    [tableView scrollRowToVisible:row];
    [rssItems sortUsingDescriptors:[tableView sortDescriptors]];
    [rssArray rearrangeObjects];
	[tableView reloadData];
    rssItem* item = [rssItems objectAtIndex:row];
	NSString	*urlString = [item link];
    if ([urlString hasPrefix:@"http://"] == NO &&
        [urlString hasPrefix:@"https://"] == NO) {
        [linkButton setState:NO];
        return;
    }
    // Show link on builtin browser
    [self stopCrawling:YES];
    NSSound *sound = [NSSound soundNamed:@"Submarine"];
    [sound play];
    [parentDoc enableWeb];
    [parentDoc jumpUrl:urlString :NO];
	// NSURL *url = [NSURL URLWithString:urlString];
	// [[NSWorkspace sharedWorkspace] openURL:url];
	// NSLog(@"openItem: url=%@",url);
    [[parentDoc win] orderFront:self];
    [[self window] orderFront:self];
    [linkButton setState:NO];
    return;
}

- (IBAction)selectBookmark:(id)sender
{
	int	selected = [comboBoxBookmark indexOfSelectedItem];
	NSLog(@"selectBookmark: %d: %@", selected, [comboBoxBookmark stringValue]);
	Bookmark* bookmark = nil;
	NSString* title = [channel title];
	NSString* url = [feedField stringValue];
	int	index = 0;
    NSSound *sound = [NSSound soundNamed:@"Pop"];
	if (selected == 0) {
		// find duplicate entry
		for (bookmark in bookmarks) {
			index++;
			if ([[bookmark url] isEqualToString:url] &&
				[[bookmark title] isEqualToString:title]) {
				if (selected == 0) {
					NSLog(@"Duplicate bookmark: %@", title);
					selected = index;
				}
			}
		}
	}
	switch (selected) {
		case 0:
			// insert object as first item
			bookmark = [[Bookmark alloc] init];
			if (bookmark == nil) {
				break;
			}
			[bookmark setBookmark:title:url];
			[bookmarks insertObject:bookmark atIndex:0];
			[comboBoxBookmark insertItemWithObjectValue:title atIndex:1];
			NSLog(@"Add Bookmark : %d %@ %@ %@", (int)[bookmarks count], bookmark, [bookmark title], [bookmark url]);
			[bookmark release];
			if ([bookmarks count] > MAX_BOOKMARK_NUM) {
				// remove last object
				[bookmarks removeLastObject];
				[comboBoxBookmark removeItemAtIndex:MAX_BOOKMARK_NUM+1];
			}
			[sound play];
			break;
		default:
			bookmark = [bookmarks objectAtIndex:selected-1];
			if (bookmark == nil) {
				NSLog(@"Bookmark is nil %d/%d", selected, (int)[bookmarks count]);
				break;
			}
			[bookmark retain];
			if (selected > 1) {
				// move bookmark to first
				title = [bookmark title];
				[bookmarks removeObjectAtIndex:selected-1];
				[bookmarks insertObject:bookmark atIndex:0];
				[comboBoxBookmark removeItemAtIndex:selected];
				[comboBoxBookmark insertItemWithObjectValue:title atIndex:1];
			}
			NSLog(@"Jump Bookmark %@ %@ %@", bookmark, [bookmark title], [bookmark url]);
			//[webReader stopCrawling:YES];
			//[self jumpUrl:[bookmark url]:NO];
            [self stopCrawling:YES];
            [feedField setStringValue:[bookmark url]];
			[sound play];
            [self fetchRSS:self];
			[bookmark release];
			break;
	}
	[self saveBookmark];
	//[comboBoxBookmark setTitleWithMnemonic:NSLocalizedString(@"RSS_FEED",@"RSS Feed")];
    [comboBoxBookmark selectItemWithObjectValue:NSLocalizedString(@"RSS_FEED",@"RSS Feed")];
    return;
}

- (void)actionDoubleClick:(id)sender
{
    if ([rssItems count] == 0) {
        return;
    }
    NSLog(@"actionDoubleClick %lu", (long)[tableView clickedRow]);
    if ([tableView selectedRow] == [tableView clickedRow]) {
        [self openItem:self];
    }
    return;
}

#pragma mark bookmark

- (void)loadBookmark
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *bookmarkAsData = [defaults objectForKey:tPrtFeedListKey];
	if (bookmarkAsData == nil) {
		bookmarks = [[NSMutableArray alloc] init];
		return;
	}
	bookmarks = [NSKeyedUnarchiver unarchiveObjectWithData:bookmarkAsData];
	if (bookmarks == nil) {
		bookmarks = [[NSMutableArray alloc] init];
	} else {
		[bookmarks retain];
		for (Bookmark* bookmark in bookmarks) {
			//NSLog(@"bookmark %@ %@", [bookmark title], [bookmark url]);
			NSString* title = [bookmark title];
			[comboBoxBookmark addItemWithObjectValue:title];
		}
	}
}

- (void)saveBookmark
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *bookmarkAsData = [NSKeyedArchiver archivedDataWithRootObject:bookmarks];
	[defaults setObject:bookmarkAsData forKey:tPrtFeedListKey];
}

- (void)handleFeedChange:(NSNotification*)note
{
	NSLog(@"Received nptification: %@", note);
	[bookmarks removeAllObjects];
	[comboBoxBookmark removeAllItems];
	[comboBoxBookmark removeAllItems];
	NSString* lang = NSLocalizedString(@"LANG",@"English");
	if ([lang isEqualToString:@"Japanese"]) {
		[comboBoxBookmark addItemWithObjectValue:@"フィードを追加する (50件まで)"];
	} else {
		[comboBoxBookmark addItemWithObjectValue:@"Add Feed (Up to 50 items)"];
	}
	[self loadBookmark];
}

- (void)setFontColor:(NSColor*)color
{
	NSTableColumn *column = nil;
	NSLog(@"setFontColor");
	
	// set font color of tableView
	column = [tableView  tableColumnWithIdentifier:@"Date"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"Feed"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"Title"];
	[(id)[column dataCell] setTextColor:color];
	//[tableView reloadData];
}

/*
- (void)tableView:(NSTableView*)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    NSLog(@"sortDescriptorsDidChange");
}

- (IBAction)caseInsensitiveCompare:(id)sender
{
    NSLog(@"caseInsensitiveCompare");
}

- (void)sortUsingDescriptors:(NSArray*)sortDescriptors
{
    NSLog(@"sortUsingDescriptors");
}

- (void)editingDidEnd:(NSNotification *)notification
{
    NSLog(@"editingDidEnd");
}
 */

#pragma mark HTTP Conection

- (IBAction)startRssConnection:(id)sender
{
    if ([[feedField stringValue] hasPrefix:@"http://"] == NO &&
        [[feedField stringValue] hasPrefix:@"https://"] == NO &&
        [[feedField stringValue] hasPrefix:@"feed://"] == NO) {
        return;
    }
	NSString *input = [feedField stringValue];
	NSString *searchString = [input stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSLog(@"searchString = %@", searchString);
    
	NSMutableString *urlString = [NSMutableString stringWithFormat: @"%@", searchString];
    if ([urlString hasPrefix:@"feed:"] == YES) {
        NSRange range = [urlString rangeOfString:@"feed:"];
        [urlString replaceCharactersInRange:range withString:@"http:"];
    }
	NSURL *url = [NSURL URLWithString:urlString];
	NSLog(@"url = %@", url);
	NSURLRequest* urlRequest = [NSURLRequest requestWithURL:url];
    [self startConnection:urlRequest];
}

- (IBAction)crawlingRSS:(id)sender {
    NSImage *template;
    if (crawling == NO) {
        NSInteger	row = [tableView selectedRow];
        [tableView scrollRowToVisible:row];
        [rssItems sortUsingDescriptors:[tableView sortDescriptors]];
        [rssArray rearrangeObjects];
        [tableView reloadData];
        if (sender == forwardButton) {
            if (row == -1) {
                row = 0;
            }
            [self startCrawling:row:[rssItems count]-1];
            if (crawling == NO) {
                return;
            }
            //template = [NSImage imageNamed:@"NSStopProgressTemplate"];
            template = [NSImage imageNamed:@"ImageStopSmall"];
            [forwardButton setImage:template];
            [backButton setEnabled:NO];
            forward = YES;
        } else {
            if (row == -1) {
                row = [rssItems count]-1;
            }
            [self startCrawling:row:0];
            if (crawling == NO) {
                return;
            }
            //template = [NSImage imageNamed:@"NSStopProgressTemplate"];
            template = [NSImage imageNamed:@"ImageStopSmall"];
            [backButton setImage:template];
            [forwardButton setEnabled:NO];
            forward = NO;
        }
    } else {
        crawling = NO;
        template = [NSImage imageNamed:@"NSRightFacingTriangleTemplate"];
        [forwardButton setImage:template];
        [forwardButton setEnabled:YES];
        template = [NSImage imageNamed:@"NSLeftFacingTriangleTemplate"];
        [backButton setImage:template];
        [backButton setEnabled:YES];
    }
}

- (void)startConnection:(NSURLRequest*)req
{
    NSLog(@"RSSReader: startConnection");
	NSString *url = [[req URL] absoluteString];
	if (documentUrl) {
		[documentUrl release];
	}
	if (lastConnection) {
		[lastConnection cancel];
	}
	documentUrl = [url retain];
	lastConnection = [NSURLConnection connectionWithRequest:req delegate:self];
}

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
	NSLog(@"RSSReader: didReceiveResponse");
	if (documentData) {
		[documentData release];
	}
    NSLog( @"size = %llu", [response expectedContentLength]);
    NSLog(@"%@", [response MIMEType]);
    //NSLog(@"%@", [response textEncodingName]);
	documentData = [[NSMutableData alloc] init];
	[self purgeDocumentData];
}

- (void)connection:(NSURLConnection*)connection
	didReceiveData:(NSData*)data
{
	NSLog(@"RSSReader: didReceiveData: %ld", (long)[data length]);
	if (documentData) {
		[documentData appendData:data];
	}
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
	NSLog(@"RSSReader: didFailWithError: %@", error);
	if (lastConnection == connection) {
		lastConnection = nil;
	}
	NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
									 defaultButton:NSLocalizedString(@"OK",@"Ok")
								   alternateButton:nil
									   otherButton:nil
						 informativeTextWithFormat:NSLocalizedString(@"CONNECTION_FAILED", @"Failed to connect server: %@"), [error localizedDescription]];
	[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
    //[feedField setStringValue:@""];
    [self completeRSSConnection];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSLog(@"RSSReader: didFinishLoading");
	NSString *htmlString = [[NSString alloc] initWithData:documentData encoding:NSUTF8StringEncoding];
	if (htmlString == nil) {
		htmlString = [[NSString alloc] initWithData:documentData encoding:NSShiftJISStringEncoding];
	}
	if (htmlString == nil) {
		htmlString = [[NSString alloc] initWithData:documentData encoding:NSJapaneseEUCStringEncoding];
	}
	[self purgeDocumentData];
	documentContent = [htmlString retain];
	if (lastConnection == connection) {
		lastConnection = nil;
	}
    [self getFeed:documentData];
    [self completeRSSConnection];
    redirect = NO;
    return;
}

- (void)completeRSSConnection
{
    if (fetchIndex >= [bookmarks count] || loading == NO) {
        if (loading) {
            [feedField setStringValue:@""];
        }
        NSTableColumn *column = [tableView tableColumnWithIdentifier:@"Feed"];
        if (loading == YES) {
            [column setHidden:NO];
        } else {
            [column setHidden:YES];
        }
        [feedField setEnabled:YES];
        [forwardButton setEnabled:YES];
        [backButton setEnabled:YES];
        [progress stopAnimation:nil];
        [progress setHidden:YES];
        [linkButton setHidden:NO];
        [linkButton setState:NO];
        if (loading == YES && [rssItems count] > 0) {
            [win setTitle:@"RSS Reader"];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:@"" forKey:tPrtLastFeedKey];
            if (lastFeed) {
                [lastFeed release];
            }
            lastFeed = [[NSString alloc] initWithString:@""];
        }
        loading = NO;
        
        // Sort Items
        NSSortDescriptor	*descriptor;
        NSMutableArray		*sortDescriptors = [[NSMutableArray alloc] init];
        descriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO selector:@selector(compare:)];
        [sortDescriptors addObject:descriptor];
        [rssItems sortUsingDescriptors:sortDescriptors];
        [descriptor release];
        [sortDescriptors release];
        if ([tableView selectedRow] == -1) {
            NSIndexSet* ixset = [NSIndexSet indexSetWithIndex:0];
            [tableView selectRowIndexes:ixset byExtendingSelection:NO];
            [tableView scrollRowToVisible:0];
        } else {
            [tableView scrollRowToVisible:[tableView selectedRow]];
        }
    } else {
        Bookmark* feed = [bookmarks objectAtIndex:fetchIndex];
        if (feed) {
            [feedField setStringValue:[feed url]];
            [self startRssConnection:self];
            fetchIndex++;
        }
    }
}

- (void)purgeDocumentData
{
	if (documentContent) {
		[documentContent release];
		documentContent = nil;
	}
}

#pragma mark Auto Pilot

- (void)startCrawling:(int)indexFrom :(int)indexTo
{
	NSLog(@"startCrawling");
    if ([rssItems count] == 0) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"NO_CRAWLING_SITE",@"web site for autopilot not found.")];
		[alert beginSheetModalForWindow:win modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
    }
    if (indexFrom  < 0 || indexTo < 0  || indexFrom > [rssItems count]) {
        return;
    }
    if (indexTo > indexFrom) {
        if (indexTo >= [rssItems count]) {
            indexTo = [rssItems count] - 1;
        }
    }
    crawlingDst = indexTo;
	crawlingIndex = indexFrom;
    [[parentDoc webReader] stopCrawling:NO];
	crawling = YES;
    rssItem *item = [rssItems objectAtIndex:indexFrom];
    if (item) {
		NSIndexSet* ixset = [NSIndexSet indexSetWithIndex:indexFrom];
		[tableView selectRowIndexes:ixset byExtendingSelection:NO];
		[tableView scrollRowToVisible:indexFrom];
		NSSound *sound = [NSSound soundNamed:@"Submarine"];
		[sound play];
		[parentDoc jumpUrl:[item link]:NO];
		[parentDoc enableUrlRequest:NO];
        [parentDoc enableWeb];
		[self startTimerCrawling:CRAWLING_TIMER_CMD_CANCEL];
    }
}

- (void)stopCrawling:(bool)warn
{
	NSLog(@"stopCrawling");
	if (crawling == YES) {
        NSImage *template;
		crawling = NO;
		crawlingIndex = 0;
        template = [NSImage imageNamed:@"NSRightFacingTriangleTemplate"];
        [forwardButton setImage:template];
        [forwardButton setEnabled:YES];
        template = [NSImage imageNamed:@"NSLeftFacingTriangleTemplate"];
        [backButton setImage:template];
        [backButton setEnabled:YES];
		[self stopTimerCrawling];
		[parentDoc enableUrlRequest:YES];
		if (warn == YES) {
			NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"INFO",@"Info")
											 defaultButton:NSLocalizedString(@"OK",@"Ok")
										   alternateButton:nil
											   otherButton:nil
								 informativeTextWithFormat:NSLocalizedString(@"CRAWLING_INTERRUPTED",@"autopilot is interrupted.")];
			[alert beginSheetModalForWindow:win modalDelegate:self didEndSelector:nil contextInfo:nil];
		}
	}
}

- (void)continueCrawling
{
	NSLog(@"continueCrawling");
	if (crawling == NO) {
		return;
	}
    if (forward == YES) {
        crawlingIndex++;
        if ([rssItems count] <= crawlingIndex) {
            [self stopCrawling:NO];
            return;
        }

    } else {
        crawlingIndex--;
        if (crawlingIndex < 0) {
            [self stopCrawling:NO];
            return;
        }
    }
	rssItem* item = [rssItems objectAtIndex:crawlingIndex];
	if (item) {
		NSIndexSet* ixset = [NSIndexSet indexSetWithIndex:crawlingIndex];
		[tableView selectRowIndexes:ixset byExtendingSelection:NO];
		[tableView scrollRowToVisible:crawlingIndex];
		NSSound *sound = [NSSound soundNamed:@"Submarine"];
		[sound play];
		[parentDoc jumpUrl:[item link]:NO];
		[parentDoc enableUrlRequest:NO];
        [parentDoc enableWeb];
		[self startTimerCrawling:CRAWLING_TIMER_CMD_CANCEL];
	}
}

- (void)pauseCrawling:(bool)pause {
	if (crawling == NO) {
		crawlingPaused = NO;
		return;
	}
	if (pause == YES) {
		[self stopTimerCrawling];
	} else {
		[self continueCrawling];
	}
	crawlingPaused = pause;
}

- (void)startTimerCrawling:(int)cmd {
	float timer = RSS_WAIT_TIMER;
	if (crawlingTimer) {
		[self stopTimerCrawling];
	}
	crawlingTimerCmd = cmd;
	if (cmd == CRAWLING_TIMER_CMD_CANCEL) {
		timer = AUTOPILOT_CANCEL_TIMER;
	}
	crawlingTimer = [[NSTimer scheduledTimerWithTimeInterval:timer
													  target:self
													selector:@selector(checkTimerCrawling:)
													userInfo:nil
													 repeats:NO] retain];
	[parentDoc enableUrlRequest:YES];
}

- (void)stopTimerCrawling {
	if (crawlingTimer) {
		[crawlingTimer invalidate];
		[crawlingTimer release];
		crawlingTimer = nil;
	}
}

- (void)checkTimerCrawling:(NSTimer*) timer {
	switch (crawlingTimerCmd) {
		case CRAWLING_TIMER_CMD_CNT:
			if (rssItems == nil) {
				[self stopTimerCrawling];
				return;
			}
			[self continueCrawling];
            [[parentDoc webView] scrollLineDown:self];
            [[parentDoc webReader] setScrollCount:RSS_AUTOSCROLL_COUNT];
            [[parentDoc webReader] startTimerScroll];
			break;
		case CRAWLING_TIMER_CMD_SCROLL:
            [[parentDoc webView] scrollLineDown:self];
            [[parentDoc webReader] setScrollCount:RSS_AUTOSCROLL_COUNT];
            [[parentDoc webReader] startTimerScroll];
            [self startTimerCrawling:CRAWLING_TIMER_CMD_CNT];
            break;
		case CRAWLING_TIMER_CMD_CANCEL:
			if ([[parentDoc webView] isLoading] == YES) {
				[[parentDoc webView] stopLoading:parentDoc];
				if (crawling == YES && crawlingPaused == NO) {
					NSSound *sound = [NSSound soundNamed:@"Pop"];
					[sound play];
                    [[parentDoc webView] scrollLineDown:self];
                    [[parentDoc webReader] setScrollCount:RSS_AUTOSCROLL_COUNT];
                    [[parentDoc webReader] startTimerScroll];
					[self startTimerCrawling:CRAWLING_TIMER_CMD_SCROLL];
				}
			}
			break;
	}
}

#pragma mark Localizer

- (void) localizeView
{
	NSTableColumn *column = nil;
	NSString* lang = NSLocalizedString(@"LANG",@"English");
	NSLog(@"localizeView: %@", lang);
	if ([lang isEqualToString:@"Japanese"]) {
		[comboBoxBookmark removeAllItems];
		//[comboBoxBookmark setTitleWithMnemonic:@"RSSフィード"];
        [comboBoxBookmark selectItemWithObjectValue:@"RSSフィード"];
		[comboBoxBookmark addItemWithObjectValue:@"フィードを追加する (50件まで)"];
		column = [tableView  tableColumnWithIdentifier:@"Date"];
		[[column headerCell] setStringValue:@"日付"];
		column = [tableView  tableColumnWithIdentifier:@"Feed"];
		[[column headerCell] setStringValue:@"フィード"];
		column = [tableView  tableColumnWithIdentifier:@"Title"];
		[[column headerCell] setStringValue:@"タイトル"];
	}
}

@synthesize rssItems;
@synthesize tableView;
@synthesize parentDoc;
@synthesize bookmarks;
@synthesize crawling;
@synthesize crawlingPaused;
@synthesize redirect;
@synthesize feedField;

@end
