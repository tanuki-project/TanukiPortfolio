//
//  MyDocument.m
//  tPortfolio
//
//  Created by Takahiro Sayama on 10/12/05.
//  Copyright 2011 tanuki-project. All rights reserved.
//

#import		"MyDocument.h"
#import		"PortfolioItem.h"
#import		"infoPanel.h"
#import     "GraphPanel.h"
#import     "GraphView.h"
#include	"WebDocumentReader.h"
#include	"Bookmark.h"
#include	"AppController.h"

extern AppController	*tPrtController;
extern PortfolioItem	*tPrtPortfolioItem;
extern PortfolioItem	*tPrtCashItem;

#ifdef NO_AUTOSAVE
NSString* const tPrtMainWindowFrameKey	= @"MyDocument";
NSString* const tPrtSubWindowFrameKey	= @"SubDocument";
#endif
NSString* const tPrtSelectAutoPilotKey  = @"Select AutoPilot";

float defaultHeight = DEFAULT_SPLIT_HIGHT;

extern NSString*    tPrtFaveriteKanjiKey;
extern bool         autosaveInPlace;
extern bool         enableRedirect;
extern bool         enableDataInputSheet;

extern bool			customCountry;
extern bool			separateCash;
extern NSString*	customCountryCode;
extern NSString*	customCountryName;
extern NSString*	customCurrencyCode;
extern NSString*	customCurrencyName;
extern NSString*	customCurrencySymble;

@interface MyDocument ()
- (void)startObservingPortfolio:(PortfolioItem *)item;
- (void)stopObservingPortfolio:(PortfolioItem *)item;
@end

@implementation MyDocument

- (id)init
{
    self = [super init];
    if (self) {    
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
		portfolioArray = [[NSMutableArray alloc] init];
		if (portfolioArray == nil) {
			[super dealloc];
			return nil;
		}
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self
			   selector:@selector(handleColorChange:)
				   name:tPrtColorChangedNotification
				 object:nil];
		[nc addObserver:self
			   selector:@selector(handleBookmarkChange:)
				   name:tPrtBookmarkChangedNotification
				 object:nil];
		[nc addObserver:self
			   selector:@selector(handleFeedChange:)
				   name:tPrtFeedChangedNotification
				 object:nil];
		[nc addObserver:self
			   selector:@selector(progressStarted:)
				   name:WebViewProgressStartedNotification
				 object:nil];
		[nc addObserver:self
			   selector:@selector(progressFinished:)
				   name:WebViewProgressFinishedNotification
				 object:nil];
		//[nc addObserver:self selector:@selector(selectionDidChanging:)
		//		   name:NSTableViewSelectionIsChangingNotification
		//		 object:tableView];
		[nc addObserver:self selector:@selector(selectionDidChanged:)
				   name:NSTableViewSelectionDidChangeNotification
				 object:tableView];
		[nc addObserver:self selector:@selector(actionClose:)
				   name:NSWindowWillCloseNotification
				 object:win];
		//[nc addObserver:self selector:@selector(applicationWillBecomeActive:)
		//		   name:NSApplicationWillBecomeActiveNotification
		//		 object:win];
		NSLog(@"Registerd with notification center");
		subDocument = nil;
        cashAccount = nil;
        reader = nil;
		currentItem = nil;
        cashItem = nil;
		iPanel = nil;
        gPanel = nil;
		prevInfoPanel = nil;
		webReader = [[WebDocumentReader alloc] init];
		if (webReader == nil) {
			[portfolioArray dealloc];
			[super dealloc];
			return nil;
		}
		[webReader setDoc:self];
		bookmarks = nil;
		portfolioSumArray = [[NSMutableArray alloc] init];
		prevItems = [[NSMutableArray alloc] init];
		prevPriceList = nil;
		progressWebView = NO;
		progressConnection = NO;
        speechingPortfolio = NO;
        speechIndex = 0;
        extended = NO;
        selectAutoPilot = NO;
		[tPrtController addDoc:self];
	}
    return self;
}

- (void)dealloc
{
	NSLog(@"dealloc MyDocument");
	//[self setPrintInfo:nil];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];
	if (subDocument != nil) {
		[subDocument close];
	}
    if (cashAccount != nil) {
        [cashAccount close];
    }
	if (reader != nil) {
		[reader close];
        [reader release];
	}
	for (Bookmark *bookmark in bookmarks) {
		[bookmarks removeObject:bookmark];
		[bookmark release];
	}
	[bookmarks dealloc];
	if (webReader) {
		[webReader dealloc];
		webReader = nil;
	}
	for (PortfolioItem *item in portfolioArray) {
		[self stopObservingPortfolio:item];
	}
	[super dealloc];
}

- (void)close
{
	NSLog(@"Close: MyDocument");
#ifdef NO_AUTOSAVE
	[win saveFrameUsingName:tPrtMainWindowFrameKey];
#endif
	if (subDocument) {
		[subDocument close];
        [subDocument release];
		subDocument = nil;
	}
    if (cashAccount) {
        [cashAccount close];
        [cashAccount release];
        cashAccount = nil;
    }
	if (reader) {
		[reader close];
        [reader release];
		reader = nil;
	}
	if (gPanel) {
		[[gPanel graphPanel] close];
        [gPanel close];
        [gPanel release];
		gPanel = nil;
	}
	if ([webView isLoading]) {
		[webView stopLoading:self];
        usleep(1000);
        if ([webView isLoading]) {
            [webView stopLoading:self];
            usleep(1000);
        }
	}
	[webView close];
	if (iPanel != nil) {
		[iPanel stopSpeech:self];
		[iPanel close];
		iPanel = nil;
	}
	if (webReader) {
		[webReader dealloc];
		webReader = nil;
	}
	[tPrtController removeDoc:self];
	[super close];
}

- (void)actionClose:(NSNotification *)notification {
	NSLog(@"actionClose");
}

+ (BOOL)autosavesInPlace {
    autosaveInPlace = YES;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	bool value = [defaults boolForKey:tPrtAutoSaveKey];
	//NSLog(@"autosavesInPlace: %d", value);
    return value;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *colorAsData;
	colorAsData = [defaults objectForKey:tPrtTableBgColorKey];
	if (colorAsData) {
		[tableView setBackgroundColor:[NSKeyedUnarchiver unarchiveObjectWithData:colorAsData]];
		[tableViewSum setBackgroundColor:[NSKeyedUnarchiver unarchiveObjectWithData:colorAsData]];
	}
	colorAsData = [defaults objectForKey:tPrtTableFontColorKey];
	if (colorAsData) {
		[self setFontColor:[NSKeyedUnarchiver unarchiveObjectWithData:colorAsData]];
	}
	if ([defaults boolForKey:tPrtPortfolioDetailKey] == YES) {
		[self setHiddenColumn:NO];
		[checkDetail setState:NSOnState];
	} else {
		[self setHiddenColumn:YES];
		[checkDetail setState:NSOffState];
	}
    NSString *kanji = [defaults objectForKey:tPrtFaveriteKanjiKey];
    if (kanji && [kanji isEqualToString:@""] == NO) {
        [tanukiBelly setHidden:NO];
        [tanukiBelly setStringValue:kanji];
    } else {
        [tanukiBelly setHidden:YES];
    }
#ifdef NO_AUTOSAVE
	[win setFrameUsingName:tPrtMainWindowFrameKey];
#endif
	[webView setFrameLoadDelegate:(id)webReader];
	[webView setDownloadDelegate:(id)webView];
    [[webView preferences] setCacheModel:WebCacheModelDocumentBrowser];
	WebFrame* mainFrame;
	NSURL* url = nil;
	NSString* urlKey = [defaults objectForKey:tPrtHomeUrlKey];
	if (urlKey == nil || [urlKey isEqualToString:@""] == YES) {
		urlKey = [defaults objectForKey:tPrtLastUrlKey];
	}
	if (urlKey) {
		url = [NSURL URLWithString:urlKey];
		NSLog(@"StartupUrl :%@", url);
	}
	if (url == nil) {
		url = [NSURL URLWithString:DEFAULT_JP_WEB_SITE];
	}
	NSURLRequest* urlRequest = [NSURLRequest requestWithURL:url];
	mainFrame = [webView mainFrame];
	[mainFrame loadRequest:urlRequest];
	[datePicker setDateValue:[NSDate date]];
	int i = 1;
	for (PortfolioItem* item in portfolioArray) {
		[item setIndex:i++];
	}
	//[tableView setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];
	[tableView setDoubleAction:@selector(openItem:)];
	[tableView setTarget:self];
	[tableViewSum setDoubleAction:@selector(openGraph:)];
	// [webTitle setStringValue:@""];
	[self buildCountyList];
	[self localizeView];
	[self allocatePortfolioSumArray];
	[self loadBookmark];
	[self rearrangeDocument];
	
	bool update = [defaults boolForKey:tPrtAutoUpdateKey];
	NSLog(@"auto update = %d",update);
	if (update && [portfolioArray count] > 0) {
		iPanel = [[infoPanel alloc] init];
		if (iPanel) {
			[iPanel setTitle:@"Information : Change from last update"];
		}
		[webReader setModifiedPrice:0];
		[webReader setConnectAscending:YES];
		[webReader clearCrawlingList];
		[self autoConnection:0:NO];
		usleep(500000);
		NSSound *sound = [NSSound soundNamed:@"Pop"];
		[sound play];
	}
    NSRect splitRect = [splitView frame];
    defaultHeight = splitRect.size.height;
    //selectAutoPilot = [defaults boolForKey:tPrtSelectAutoPilotKey];
}

- (void)applicationWillBecomeActive:(NSNotification *)aNotification
{
	NSLog(@"applicationWillBecomeActive: %@ %d", [[self win] title], [[self win] isMainWindow]);
}


#pragma mark Portfolio Controller

- (void)setPortfolio:(NSMutableArray*)a
{
	if (a == portfolioArray) {
		return;
	}
	
	NSLog(@"setPortfolio");
	for (PortfolioItem *item in portfolioArray) {
		[self stopObservingPortfolio:item];
	}
	[a retain];
	[portfolioArray release];
	portfolioArray = a;
	for (PortfolioItem *item in portfolioArray) {
		[item DoSettlement];
		[self startObservingPortfolio:item];
	}
	[self rearrangeDocument];
}

- (void)startObservingPortfolio:(PortfolioItem *)item
{
	// NSLog(@"startObservingPortfolio: %@", item);
	[item addObserver:self
		   forKeyPath:@"itemName"
			  options:NSKeyValueObservingOptionOld
			  context:NULL];	
	[item addObserver:self
		   forKeyPath:@"itemCode"
			  options:NSKeyValueObservingOptionOld
			  context:NULL];
	[item addObserver:self
		   forKeyPath:@"itemType"
			  options:NSKeyValueObservingOptionOld
			  context:NULL];
	[item addObserver:self
		   forKeyPath:@"country"
			  options:NSKeyValueObservingOptionOld
			  context:NULL];
	[item addObserver:self
		   forKeyPath:@"price"
			  options:NSKeyValueObservingOptionOld
			  context:NULL];
	[item addObserver:self
		   forKeyPath:@"quantity"
			  options:NSKeyValueObservingOptionOld
			  context:NULL];
	[item addObserver:self
		   forKeyPath:@"url"
			  options:NSKeyValueObservingOptionOld
			  context:NULL];
}

- (void)stopObservingPortfolio:(PortfolioItem*)item
{
	// NSLog(@"stopObservingPortfolio: %@", item);
	[item removeObserver:self forKeyPath:@"itemName"];
	[item removeObserver:self forKeyPath:@"itemCode"];
	[item removeObserver:self forKeyPath:@"itemType"];
	[item removeObserver:self forKeyPath:@"country"];
	[item removeObserver:self forKeyPath:@"price"];
	[item removeObserver:self forKeyPath:@"quantity"];
	[item removeObserver:self forKeyPath:@"url"];
}

- (void)insertObject:(PortfolioItem *)p inPortfolioArrayAtIndex:(int)index
{
	// NSLog(@"adding %@ to %@", p, portfolioArray);
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self]
						removeObjectFromPortfolioArrayAtIndex:index];
	if (![undo isUndoing]) {
		[undo setActionName:@"Insert PortfolioItem"];
	}
	[self startObservingPortfolio:p];
	[portfolioArray insertObject:p atIndex:index];
	int i = 1;
	for (PortfolioItem* item in portfolioArray) {
		[item setIndex:i++];
	}
	NSLog(@"portfolio count = %d", (int)[portfolioArray count]);
}

- (void)removeObjectFromPortfolioArrayAtIndex:(int)index
{
	PortfolioItem *p = [portfolioArray objectAtIndex:index];
	NSLog(@"removing %@ to %@", p, portfolioArray);
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self]
	 insertObject:p inPortfolioArrayAtIndex:index];
	if (![undo isUndoing]) {
		[undo setActionName:@"Delete PortfolioItem"];
	}
	[self stopObservingPortfolio:p];
	[portfolioArray removeObjectAtIndex:index];
	int i = 1;
	for (PortfolioItem* item in portfolioArray) {
		[item setIndex:i++];
	}
	NSLog(@"portfolio count = %d", (int)[portfolioArray count]);
	[self rearrangeDocument];
}

- (void)changeKeyPath:(NSString*)keyPath
			 obObject:(id)obj
			  toValue:(id)newValue
{
	NSLog(@"changeKeyPath: %@", keyPath);
	[obj setValue:newValue forKeyPath:keyPath];
}

- (void)observeValueForKeyPath:(NSString*)keyPath
					  ofObject:(id)object
						change:(NSDictionary*)change
					   context:(void*)context
{
	NSUndoManager *undo = [self undoManager];
	id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
	
	if (oldValue == [NSNull null]) {
		oldValue = nil;
	}
	NSLog(@"oldValue:%@ = %@", keyPath, oldValue);
	[[undo prepareWithInvocationTarget:self] changeKeyPath:keyPath
												  obObject:object
												   toValue:oldValue];
    if ([keyPath isEqualToString:@"itemType"] == YES) {
        PortfolioItem *item = object;
        [item setType:[item itemTypeToType:[item itemType]]];
        NSLog(@"%@", [item itemName]);
    }
	[undo setActionName:@"Edit"];
}

- (void)sumPortfolio:(PortfolioSum*)sum
{
	int		items = 0;
	double	investedValue = 0;
	double	estimatedValue = 0;
	double	cashValue = 0;
	double	creditLongEstimatedValue = 0;
	double	creditLongDealedValue = 0;
	double	creditShortEstimatedValue = 0;
	double	creditShortDealedValue = 0;
	double	capitalGainValue = 0;
	double	incomeGainValue = 0;
	double	latentGainValue = 0;
	double	totalGainValue = 0;
	double	preformanceValue = 0;
    Boolean separate = separateCash;

	for (PortfolioItem* item in portfolioArray) {
		if ([[sum countryCode] isEqualToString:[item country]] != YES) {
			continue;
		}
		items++;
        if ([item type] == ITEM_TYPE_CASH && separate == YES) {
            cashValue += [item value];
            continue;
        }
		if ([item credit] == TRADE_TYPE_SHORTSELL) {
			creditShortEstimatedValue += [item value];
			creditShortDealedValue += [item investment];
		} else if ([item credit] == TRADE_TYPE_LONGBUY) {
			creditLongEstimatedValue += [item value];
			creditLongDealedValue += [item investment];
		} else {
			investedValue += [item investment];
			estimatedValue += [item value];
		}
		capitalGainValue += [item profit];
		incomeGainValue += [item income];
		latentGainValue += [item lproperty];
	}
	totalGainValue = capitalGainValue + incomeGainValue + latentGainValue;
	if ((investedValue+creditLongDealedValue+creditShortEstimatedValue) > 0) {
		preformanceValue = ((estimatedValue+creditLongEstimatedValue+creditShortDealedValue)/(investedValue+creditLongDealedValue+creditShortEstimatedValue)-1)*100;
	}

	[sum setItems: items];
	[sum setInvested: investedValue];
	[sum setEstimated: estimatedValue];
	[sum setCash: cashValue];
	[sum setCreditLongEstimated: creditLongEstimatedValue];
	[sum setCreditLongDealed: creditLongDealedValue];
	[sum setCreditShortEstimated: creditShortEstimatedValue];
	[sum setCreditShortDealed: creditShortDealedValue];
	[sum setCapitalGain: capitalGainValue];
	[sum setIncomeGain: incomeGainValue];
	[sum setLatentGain: latentGainValue];
	[sum setTotalGain: totalGainValue];
	[sum setPerformance: preformanceValue];
    [sum selectFlagColor];
    // [tableViewSum];
    NSTableColumn *column = nil;
	column = [tableViewSum tableColumnWithIdentifier:@"cash"];
    if (separate == YES) {
        [column setHidden:NO];
    } else {
        [column setHidden:YES];
    }
	NSLog(@"sumPortfolio(%@): %.0f,%.0f,%.2f,%.0f",[sum countryCode], round(investedValue),round(estimatedValue),preformanceValue,round(totalGainValue));
}

#pragma mark PortfolioSumArray

- (void)allocatePortfolioSumArray
{
	if (portfolioArray) {
		[self releasePortfolioSumArray];
	}
	for (PortfolioItem* item in portfolioArray) {
		bool	found = NO;
		for (PortfolioSum* sum in portfolioSumArray) {
			if ([[item country] isEqualToString:[sum countryCode]]) {
				found = YES;
			}
		}
		if (found == NO) {
			PortfolioSum* newSum = [[PortfolioSum alloc] init];
			if (newSum == nil) {
				continue;
			}
			[newSum setCountryCode:[item country]];
			if ([[item country] isEqualToString:@"AE"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_AE",@"United Arab Emirates")];
				[newSum setCurrency:@"AED"];
				[newSum setDomain:@""];
			} else if ([[item country] isEqualToString:@"AR"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_AR",@"Argentina")];
				[newSum setCurrency:@"ARS"];
				[newSum setDomain:@""];
			} else if ([[item country] isEqualToString:@"AT"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_AT",@"Austria")];
				[newSum setCurrency:@"EUR"];
				[newSum setDomain:@"de"];
			} else if ([[item country] isEqualToString:@"AU"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_AU",@"Australia")];
				[newSum setCurrency:@"AUD"];
				[newSum setDomain:@"au"];
			} else if ([[item country] isEqualToString:@"BE"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_BE",@"Belgium")];
				[newSum setCurrency:@"EUR"];
				[newSum setDomain:@"de"];
			} else if ([[item country] isEqualToString:@"BR"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_BR",@"Brazil")];
				[newSum setCurrency:@"BRL"];
				[newSum setDomain:@"br"];
			} else if ([[item country] isEqualToString:@"CA"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_CA",@"Canada")];
				[newSum setCurrency:@"CAD"];
				[newSum setDomain:@"ca"];
			} else if ([[item country] isEqualToString:@"CH"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_CH",@"Switzerland")];
				[newSum setCurrency:@"CHF"];
				[newSum setDomain:@"de"];
			} else if ([[item country] isEqualToString:@"CN"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_CN",@"Chaina")];
				[newSum setCurrency:@"CHY"];
				[newSum setDomain:@""];
			} else if ([[item country] isEqualToString:@"DE"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_DE",@"Germany")];
				[newSum setCurrency:@"EUR"];
				[newSum setDomain:@"de"];
			} else if ([[item country] isEqualToString:@"DK"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_DK",@"Denmark")];
				[newSum setCurrency:@"DKK"];
				[newSum setDomain:@""];
			} else if ([[item country] isEqualToString:@"EG"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_EG",@"Egypt")];
				[newSum setCurrency:@"EGP"];
				[newSum setDomain:@""];
			} else if ([[item country] isEqualToString:@"ES"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_ES",@"Spain")];
				[newSum setCurrency:@"EUR"];
				[newSum setDomain:@"es"];
			} else if ([[item country] isEqualToString:@"EU"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_EU",@"European Union")];
				[newSum setCurrency:@"EUR"];
				[newSum setDomain:@"de"];
			} else if ([[item country] isEqualToString:@"FI"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_FI",@"Finland")];
				[newSum setCurrency:@"EUR"];
				[newSum setDomain:@""];
			} else if ([[item country] isEqualToString:@"FR"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_FR",@"France")];
				[newSum setCurrency:@"EUR"];
				[newSum setDomain:@"fr"];
			} else if ([[item country] isEqualToString:@"GR"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_GR",@"Greece")];
				[newSum setCurrency:@"EUR"];
				[newSum setDomain:@""];
			} else if ([[item country] isEqualToString:@"HK"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_HK",@"HongKong")];
				[newSum setCurrency:@"HKD"];
				[newSum setDomain:@""];
			} else if ([[item country] isEqualToString:@"ID"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_ID",@"Indonesia")];
				[newSum setCurrency:@"IDR"];
				[newSum setDomain:@""];
			} else if ([[item country] isEqualToString:@"IN"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_IN",@"India")];
				[newSum setCurrency:@"INR"];
				[newSum setDomain:@"in"];
			} else if ([[item country] isEqualToString:@"IT"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_IT",@"Italy")];
				[newSum setCurrency:@"EUR"];
				[newSum setDomain:@"it"];
			} else if ([[item country] isEqualToString:@"JP"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_JP",@"Japan")];
				[newSum setCurrency:@"JPY"];
				[newSum setDomain:@"jp"];
			} else if ([[item country] isEqualToString:@"KR"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_KR",@"Koria")];
				[newSum setCurrency:@"KRW"];
				[newSum setDomain:@""];
			} else if ([[item country] isEqualToString:@"LU"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_LU",@"Luxembourg")];
				[newSum setCurrency:@"EUR"];
				[newSum setDomain:@"de"];
			} else if ([[item country] isEqualToString:@"MX"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_MX",@"Mexico")];
				[newSum setCurrency:@"MXN"];
				[newSum setDomain:@"mx"];
			} else if ([[item country] isEqualToString:@"MY"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_MY",@"Malaysia")];
				[newSum setCurrency:@"MYR"];
				[newSum setDomain:@""];
			} else if ([[item country] isEqualToString:@"NL"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_NL",@"")];
				[newSum setCurrency:@"EUR"];
				[newSum setDomain:@""];
			} else if ([[item country] isEqualToString:@"NO"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_NO",@"")];
				[newSum setCurrency:@"NOK"];
				[newSum setDomain:@""];
			} else if ([[item country] isEqualToString:@"NZ"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_NZ",@"New Zealand")];
				[newSum setCurrency:@"NZD"];
				[newSum setDomain:@"nz"];
			} else if ([[item country] isEqualToString:@"PH"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_PH",@"Philippines")];
				[newSum setCurrency:@"PHP"];
				[newSum setDomain:@""];
			} else if ([[item country] isEqualToString:@"PT"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_PT",@"")];
				[newSum setCurrency:@"EUR"];
				[newSum setDomain:@""];
			} else if ([[item country] isEqualToString:@"RU"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_RU",@"Russia")];
				[newSum setCurrency:@"RUB"];
				[newSum setDomain:@""];
			} else if ([[item country] isEqualToString:@"SA"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_SA",@"Saudi Arabia")];
				[newSum setCurrency:@"SAR"];
				[newSum setDomain:@""];
			} else if ([[item country] isEqualToString:@"SE"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_SE",@"Sweden")];
				[newSum setCurrency:@"SEK"];
				[newSum setDomain:@""];
			} else if ([[item country] isEqualToString:@"SG"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_SG",@"Singapura")];
				[newSum setCurrency:@"SGD"];
				[newSum setDomain:@"sg"];
			} else if ([[item country] isEqualToString:@"TH"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_TH",@"Thailand")];
				[newSum setCurrency:@"THB"];
				[newSum setDomain:@""];
			} else if ([[item country] isEqualToString:@"TR"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_TR",@"Turkey")];
				[newSum setCurrency:@"TRY"];
				[newSum setDomain:@""];
			} else if ([[item country] isEqualToString:@"TW"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_TW",@"Taiwan")];
				[newSum setCurrency:@"TWD"];
				[newSum setDomain:@""];
			} else if ([[item country] isEqualToString:@"UK"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_UK",@"United Kingdom")];
				[newSum setCurrency:@"GBP"];
				[newSum setDomain:@"uk"];
			} else if ([[item country] isEqualToString:@"US"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_US",@"United States")];
				[newSum setCurrency:@"USD"];
				[newSum setDomain:@""];
			} else if ([[item country] isEqualToString:@"VN"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_VN",@"Vietnam")];
				[newSum setCurrency:@"VND"];
				[newSum setDomain:@""];
			} else if ([[item country] isEqualToString:@"ZA"] == YES) {
				[newSum setCountry:NSLocalizedString(@"COUNTRY_SA",@"South Africa")];
				[newSum setCurrency:@"ZAR"];
				[newSum setDomain:@""];
			} else {
				if ([[item country] isEqualToString:customCountryCode] == YES) {
					[newSum setCountry:customCountryName];
					[newSum setCurrency:customCurrencyCode];
				} else {
					[newSum setCountry:[item country]];
					[newSum setCurrency:@"***"];
				}
				[newSum setDomain:@""];
			}
			[portfolioSumArray addObject:newSum];
			[newSum release];
		}
	}
}

- (void)releasePortfolioSumArray
{
	[portfolioSumArray removeAllObjects];
}

- (void)setPortfolioSumArray
{
	for (PortfolioSum* sum in portfolioSumArray) {
		[self sumPortfolio: sum];
	}
}

- (NSString*)CountryToCurrency:(NSString*)country
{
	for (PortfolioSum* sum in portfolioSumArray) {
		if ([country isEqualToString:[sum countryCode]] == YES)
			return [sum currency];
	}
	[self allocatePortfolioSumArray];
	for (PortfolioSum* sum in portfolioSumArray) {
		if ([country isEqualToString:[sum countryCode]] == YES)
			return [sum currency];
	}
	return nil;
}

- (NSString*)CountryToDomain:(NSString*)country
{
	for (PortfolioSum* sum in portfolioSumArray) {
		if ([country isEqualToString:[sum countryCode]] == YES)
			return [sum domain];
	}
	[self allocatePortfolioSumArray];
	for (PortfolioSum* sum in portfolioSumArray) {
		if ([country isEqualToString:[sum countryCode]] == YES)
			return [sum domain];
	}
	return nil;
}


#pragma mark Actions

- (IBAction)clickImage:(id)sender
{
    NSLog(@"clickImage");
    if ([portfolioArray count] == 0) {
        return;
    }
    if ([tPrtController speeching] == YES) {
        [tPrtController stopSpeech:self];
    } else {
        [tPrtController startReadPortfolio:self];
    }
}

- (IBAction)takeStringUrl:(id)sender
{
	NSLog(@"takeStringUrl: %@", [urlField stringValue]);
	NSString* urlString = [urlField stringValue];
	NSURL* url;
	if (urlString == nil || [urlString isEqualToString:@""]) {
		[[webView mainFrame] reload];
		return;
	}
	if ([urlString hasPrefix:@"http://"] || [urlString hasPrefix:@"https://"]) {
		url = [NSURL URLWithString:urlString];
    } else if ([urlString hasPrefix:@"feed:"] == YES) {
        NSRange range = [urlString rangeOfString:@"feed:"];
        NSMutableString* feed = [[NSMutableString alloc] initWithFormat:@"%@",urlString];
        [feed replaceCharactersInRange:range withString:@"http:"];
		url = [NSURL URLWithString:feed];
        [feed release];
	} else {
		NSRange range = [urlString rangeOfString:@"."];
		if (range.length == 0) {
			url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@.com", urlString]];
		} else {
			url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", urlString]];
		}
	}
	if (url) {
		NSURLRequest* urlRequest = [NSURLRequest requestWithURL:url];
		if (urlRequest) {
			[[webView mainFrame] loadRequest:urlRequest];
		}
	}
}

- (IBAction)createPortfolioItem:(id)sender
{
    NSLog(@"createPortfolioItem");
    if (sender == addButton && enableDataInputSheet == YES) {
        [self showProtfolioItemSheet:sender];
        return;
    }
	NSWindow *w = [tableView window];
	BOOL editingEnded = [w makeFirstResponder:w];
	if (!editingEnded) {
		NSLog(@"Unable to end editing");
		return;
	}
	NSUndoManager *undo = [self undoManager];	
	if ([undo groupingLevel]) {
		[undo endUndoGrouping];
		[undo beginUndoGrouping];
	}

	PortfolioItem *p = [portfolioController newObject];
    if (sender == portfolioItemOk || sender == portfolioItemSheet) {
        // Import portfolio item's attribute from portfolioItemSheet
        [p setCountry:[portfolioItemCountryBox stringValue]];
        [p setItemType:[portfolioItemTypeBox stringValue]];
        [p setItemCode:[portfolioItemCodeField stringValue]];
        [p setItemName:[portfolioItemNameField stringValue]];
        [p setUrl:[portfolioItemSiteField stringValue]];
    }
	[portfolioController addObject:p];
	[portfolioController rearrangeObjects];

	NSArray *a = [portfolioController arrangedObjects];	
	int row = [a indexOfObjectIdenticalTo:p];
	if (row != -1) {
		// NSLog(@"strating edit of %@ in row %d", p, row);
		[tableView editColumn:1 row:row withEvent:nil select:YES];
	}
	[p release];
	[self allocatePortfolioSumArray];
}

- (IBAction)removePortfolioItem:(id)sender
{
	NSLog(@"removePortfolioItem");
	NSArray *selectdePeople = [portfolioController selectedObjects];
	NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"DELETE",@"Delete")
									 defaultButton:NSLocalizedString(@"DELETE",@"Delete")
								   alternateButton:NSLocalizedString(@"CANCEL",@"Cancel")
									   otherButton:nil
						 informativeTextWithFormat:NSLocalizedString(@"SURE_DELETE",@"Do you really want to delete %d items ?"), [selectdePeople count]];
	NSLog(@"Stating alert sheet");
	[alert beginSheetModalForWindow:[tableView window]
					  modalDelegate:self
					 didEndSelector:@selector(alertEndedRemove:code:context:) contextInfo:NULL];
	[self allocatePortfolioSumArray];
}

- (void)alertEndedRemove:(NSAlert*)alert
					code:(int)choice
				 context:(void*)v
{
	NSLog(@"Alert sheet ended");
	if (choice == NSAlertDefaultReturn) {
		[portfolioController remove:nil];
	}
}

- (IBAction)sortPortfolio:(id)sender
{
	if ([portfolioArray count] == 0) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"NO_ITEMS",@"No item in portfolio.")];
		[alert beginSheetModalForWindow:[self win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
	NSPopUpButton* popUp = sender;
	NSLog(@"sortPortfolio: %d", (int)[popUp indexOfSelectedItem]);
	switch ([popUp indexOfSelectedItem]) {
		case 0:
			[self sortPortfolioByKey:@"itemName":YES:YES];
			break;
		case 1:
			[self sortPortfolioByKey:@"itemCode":YES:YES];
			break;
		case 2:
			[self sortPortfolioByKey:@"country":YES:YES];
			break;
		case 3:
			[self sortPortfolioByKey:@"type":NO:YES];
			break;
		case 4:
			[self sortPortfolioByKey:@"rise":NO:NO];
			break;
		case 5:
			[self sortPortfolioByKey:@"value":NO:NO];
			break;
		case 6:
			[self sortPortfolioByKey:@"investment":NO:NO];
			break;
		case 7:
			[self sortPortfolioByKey:@"lproperty":NO:NO];
			break;
		case 8:
			[self sortPortfolioByKey:@"profit":NO:NO];
			break;
		case 9:
			[self sortPortfolioByKey:@"income":NO:NO];
			break;
		default:
			break;
	}
}

- (IBAction)checkoutPortfolio:(id)sender
{
	NSLog(@"checkoutPortfolio at %@",[datePicker dateValue]);
	NSLog(@"isMainWindow: %d",[[self win] isMainWindow]);
	if ([portfolioArray count] == 0) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"NO_ITEMS",@"No item in portfolio.")];
		[alert beginSheetModalForWindow:[self win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
	NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *compo = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit)
										  fromDate:[datePicker dateValue]];
	NSString* dateFormat = [[NSString alloc] initWithFormat:@"%ld/%ld/%ld", (long)[compo year], (long)[compo month], (long)[compo day]];
	NSAlert*  alert = [NSAlert alertWithMessageText:NSLocalizedString(@"INFO",@"Info")
									  defaultButton:NSLocalizedString(@"OK",@"Ok")
									alternateButton:nil
										otherButton:nil
						  informativeTextWithFormat:NSLocalizedString(@"DO_CHECKOUT", @"Checkout portfolio at %@"),dateFormat];
	[alert beginSheetModalForWindow:[self win] modalDelegate:self didEndSelector:nil contextInfo:nil];
	for (PortfolioItem* item in portfolioArray) {
		[item setDate:[calendar dateFromComponents:compo]];
		[item DoSettlement];
	}
	[calendar release];
	[dateFormat release];
	[tableView deselectAll:self];
	[tableViewSum deselectAll:self];
	[self allocatePortfolioSumArray];
	[self setPortfolioSumArray];
	for (PortfolioItem* item in portfolioArray) {
		[item setDate:[NSDate date]];
	}
	[self rearrangeDocument];
}

- (void)openItem:(id)sender
{
    if (sender != tableView) {
        return;
    }
	[tableView reloadData];
	int	row = [tableView clickedRow];
	if (row == -1) {
		row = [tableView selectedRow];
	}
	NSLog(@"openItem: row=%d", row);
	if (row == -1) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"NOT_SELECTED",@"No item selected.")];
		[alert beginSheetModalForWindow:[self win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
	if (row != [tableView selectedRow]) {
		return;
	}
	PortfolioItem *item = [portfolioArray objectAtIndex:row];
    if ([item type] == ITEM_TYPE_CASH) {
        if (cashAccount) {
            if(cashItem == item) {
                [cashAccount showWindow:self];
                [cashAccount rearrangeDocument];
                return;
            }
            [cashAccount close];
            cashAccount = nil;
        }
        [item RebuildTrades];
        [item DoSettlement];
        tPrtCashItem = item;
        cashAccount = [[CashAccount alloc] init];
        if (cashAccount == nil) {
            return;
        }
        [cashAccount setParentDoc:self];
        NSLog(@"showing %@", cashAccount);
        [cashAccount showWindow:nil];
        cashItem = item;
    } else {
        if (subDocument) {
            if (currentItem == item) {
                [subDocument showWindow:self];
                [subDocument rearrangeDocument];
                return;
            }
            [subDocument close];
            subDocument = nil;
        }
        [item RebuildTrades];
        [item DoSettlement];
        tPrtPortfolioItem = item;
        subDocument = [[SubDocument alloc] init];
        if (subDocument == nil) {
            return;
        }
        [subDocument setParentDoc:self];
        NSLog(@"showing %@", subDocument);
        [subDocument showWindow:nil];
        currentItem = item;
    }
    return;
}

- (void)openGraph:(id)sender
{
    if (sender == tableView) {
        return;
    }
	[tableViewSum reloadData];
	NSInteger row = [tableViewSum clickedRow];
	if (row == -1) {
		row = [tableViewSum selectedRow];
	}
	if (row == -1) {
        if ([tableViewSum numberOfRows] == 0) {
            return;
        }
        row = 0;
    }
    NSLog(@"openGraph :%ld", (long)row);
    PortfolioSum *item = [portfolioSumArray objectAtIndex:row];
    NSLog(@"openGraph :%ld :%@", (long)row, [item countryCode]);
    if (gPanel) {
        if ([gPanel showGraph] == YES) {
            [self buildGraph:[item countryCode]];
            [[gPanel graphPanel] orderFront:sender];
            return;
        } else {
            [gPanel close];
            [gPanel release];
            gPanel = nil;
        }
    }
    if (gPanel == nil) {
        gPanel = [[GraphPanel alloc] init];
        [gPanel setParentDoc:self];
    }
    if (gPanel == nil) {
        return;
    }
    [[gPanel graphPanel] setTitle:[NSString stringWithFormat:@"%@ - %@",[win title],NSLocalizedString(@"TRANSITION","Transition of Investment Assets")]];
    [gPanel showWindow:sender];
    [[gPanel graphPanel] setFloatingPanel:NO];
    [gPanel setShowGraph:YES];
    [self buildGraph:[item countryCode]];
}

- (IBAction)goToIRSite:(id)sender
{
	int	row = [tableView selectedRow];
	NSLog(@"goToIRSite: row=%d", row);
	if (row == -1) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"NOT_SELECTED",@"No item selected.")];
		[alert beginSheetModalForWindow:[self win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
	PortfolioItem *item = [portfolioArray objectAtIndex:row];
	NSString *urlString = [item url];
	if (urlString == nil || [urlString isEqual:@""] || [urlString isEqual:INITIAL_IR_SITE]) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
								defaultButton:NSLocalizedString(@"OK",@"Ok")
							  alternateButton:nil
								  otherButton:nil
					informativeTextWithFormat:NSLocalizedString(@"NO_IR_SITE",@"IR Site not specified.")];
		[alert beginSheetModalForWindow:[self win] modalDelegate:self didEndSelector:@selector(alertEditIR:code:context:) contextInfo:nil];
		return;
	}
	[webReader stopCrawling:YES];
    [reader stopCrawling:YES];
	[self jumpUrl:urlString:NO];
    [self enableWeb];
}

- (void)alertEditIR:(NSAlert*)alert
				 code:(int)choice
			  context:(void*)v
{
	int	row = [tableView selectedRow];
	NSLog(@"alertEditIR: row=%d", row);
	if (row == -1) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"NOT_SELECTED",@"No item selected.")];
		[alert beginSheetModalForWindow:[self win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
	[tableView editColumn:15 row:row withEvent:nil select:YES];
}

- (IBAction)setIRSite:(id)sender
{
	int	row = [tableView selectedRow];
	NSLog(@"goToIRSite: row=%d", row);
	if (row == -1) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"NOT_SELECTED",@"No item selected.")];
		[alert beginSheetModalForWindow:[self win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
	PortfolioItem *item = [portfolioArray objectAtIndex:row];
	[item setUrl: [urlField stringValue]];
	[tableView editColumn:15 row:row withEvent:nil select:YES];
}

- (IBAction)goToPortalSite:(id)sender
{
	int	row = [tableView selectedRow];
	NSString *urlString = nil;
	NSLog(@"goToPortalSite: row=%d", row);
	if (row == -1) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"NOT_SELECTED",@"No item selected.")];
		[alert beginSheetModalForWindow:[self win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
	PortfolioItem *item = [portfolioArray objectAtIndex:row];
    if ([item type] == ITEM_TYPE_CASH) {
        NSBeep();
        return;
    }
	if ([item itemCode] == nil || [[item itemCode] isEqualToString:@""]) {
		NSAlert* alert;
		NSString* lang = NSLocalizedString(@"LANG",@"English");
		switch ([item itemCategory]) {
			case ITEM_CATEGORY_CURRENCY:
				alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
												 defaultButton:NSLocalizedString(@"OK",@"Ok")
											   alternateButton:nil
												   otherButton:nil
									 informativeTextWithFormat:NSLocalizedString(@"NO_CURRENCY_CODE",@"currency code not specified.")];
				[alert beginSheetModalForWindow:[self win] modalDelegate:self didEndSelector:@selector(alertEditCode:code:context:) contextInfo:nil];
				break;
			default:
				if ([lang isEqualToString:@"Japanese"]) {
					if ([item itemCategory] == ITEM_CATEGORY_FUND) {
						urlString = [NSString stringWithFormat:URL_TICKER_LOOKUP_JP_FUND];
					} else {
						urlString = [NSString stringWithFormat:URL_TICKER_LOOKUP_JP];
					}
				} else {
					urlString = [NSString stringWithFormat:URL_TICKER_LOOKUP_US];
				}
				[self jumpUrl:urlString:NO];
				[self enableUrlRequest:NO];
				alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
												 defaultButton:NSLocalizedString(@"OK",@"Ok")
											   alternateButton:nil
												   otherButton:nil
									 informativeTextWithFormat:NSLocalizedString(@"NO_STOCK_CODE",@"ticker code not specified.")];
				[alert beginSheetModalForWindow:[self win] modalDelegate:self didEndSelector:@selector(alertEditCode:code:context:) contextInfo:nil];
				break;
		}
		return;
	}

	if ([[item country] isEqualToString:TRADE_ITEM_COUNTRY_JP] == YES) {
		switch ([item itemCategory]) {
			case ITEM_CATEGORY_STOCK:
				if ([item type] == ITEM_TYPE_INDEX) {
					if ([[item itemCode] hasPrefix:@"^"]) {
						urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_STOCK,[item itemCodeYahoo]];
					}
				}
				if (urlString == nil) {
					urlString = [NSString stringWithFormat:FORMAT_MINKABU_JP_STOCK,[item itemCodeJP]];
				}
				break;
			case ITEM_CATEGORY_CURRENCY:
				if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"JPY"]) {
					urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_JPY,[item itemCode]];
				} else {
					urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_STOCK,[item itemCode]];
				}
				break;
			case ITEM_CATEGORY_FUND:
				//urlString = [NSString stringWithFormat:FORMAT_MORNINGSTAR_JP_FUND,[item itemCode]];
				urlString = [NSString stringWithFormat:FORMAT_BLOOMBERG_JP_FUND,[item itemCode]];
				break;
			default:
				return;
				break;
		}
	} else {
		switch ([item itemCategory]) {
			case ITEM_CATEGORY_STOCK:
			case ITEM_CATEGORY_FUND:
				if ([item type] == ITEM_TYPE_INDEX) {
					urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_STOCK,[item itemCodeYahoo]];
				} else {
					urlString = [NSString stringWithFormat:FORMAT_GOOGLE_FINANCE,[item itemCodeGoogle]];
				}
				break;
			case ITEM_CATEGORY_CURRENCY:
				if ([[item country] isEqualToString:TRADE_ITEM_COUNTRY_US] == YES) {
					if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"USD"]) {
						urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_USD,[item itemCode]];
					} else {
						urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_FX,[item itemCode]];
					}
				} else if ([[item country] isEqualToString:TRADE_ITEM_COUNTRY_DE] == YES ||
					[[item country] isEqualToString:TRADE_ITEM_COUNTRY_EU] == YES) {
					if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"EUR"]) {
						urlString = [NSString stringWithFormat:FORMAT_YAHOO_DE_EUR,[item itemCode]];
					} else {
						urlString = [NSString stringWithFormat:FORMAT_YAHOO_DE_FX,[item itemCode]];
					}
				} else {
					NSString* currency = [self CountryToCurrency: [item country]];
					NSString* domain = [self CountryToDomain: [item country]];
					if ([[item itemCode] length] == 3 && currency && ![[item itemCode] isEqualToString:currency]) {
						urlString = [NSString stringWithFormat:FORMAT_YAHOO_XX_YY,[[item country] lowercaseString],[item itemCode],currency];
					} else {
						if (domain == nil || [domain isEqualToString:@""] == YES) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_FX,[item itemCode]];
						} else {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_XX_FX,domain,[item itemCode]];
						}
					}
				}
				break;
			default:
				return;
				break;
		}
	}
	[webReader stopCrawling:YES];
    [reader stopCrawling:YES];
	[webReader setTargetItem:item];
	[webReader purgeDocumentData];
	[self enableUrlRequest:NO];
	[self jumpUrl:urlString:YES];
    [self enableWeb];
}

- (void)alertEditCode:(NSAlert*)alert
					  code:(int)choice
				   context:(void*)v
{
	int	row = [tableView selectedRow];
	NSLog(@"alertEditCode: row=%d", row);
	if (row == -1) {
		return;
	}
	for (int i = 0; i < 20; i++) {
		usleep(100000);
		if (progressWebView == NO) {
			break;
		}
	}
	[tableView editColumn:2 row:row withEvent:nil select:YES];
}

- (IBAction)goToYahooFinance:(id)sender
{
	NSString *urlString = nil;
	int	row = [tableView selectedRow];
	NSLog(@"goToYahooFinance: row=%d", row);
	NSString* lang = NSLocalizedString(@"LANG",@"English");
	if (row == -1) {
		if ([lang isEqualToString:@"Japanese"]) {
			urlString = [NSString stringWithFormat:URL_YAHOO_JP_FINANCE];
		} else {
			urlString = [NSString stringWithFormat:URL_YAHOO_US_FINANCE];
		}
		[self jumpUrl:urlString:YES];
        [self enableWeb];
	} else {
		PortfolioItem *item = [portfolioArray objectAtIndex:row];
		if ([item itemCode] == nil || [[item itemCode] isEqualToString:@""]) {
			if ([lang isEqualToString:@"Japanese"]) {
				urlString = [NSString stringWithFormat:URL_YAHOO_JP_FINANCE];
			} else {
				urlString = [NSString stringWithFormat:URL_YAHOO_US_FINANCE];
			}
			[self jumpUrl:urlString:NO];
		} else {
			if ([[item country] isEqualToString:TRADE_ITEM_COUNTRY_JP] == YES) {
				if ([item itemCategory] == ITEM_CATEGORY_CURRENCY && 
					[[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"JPY"]) {
					urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_JPY,[item itemCode]];
				} else if ([item itemCategory] == ITEM_CATEGORY_FUND) { 
					urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_FUND,[item itemCode]];
				} else {
					if ([item type] == ITEM_TYPE_INDEX) {
						if ([[item itemCode] hasPrefix:@"^"]) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_STOCK,[item itemCodeYahoo]];
						}
					}
					if (urlString == nil) {
						urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_STOCK,[item itemCodeJP]];
					}
				}
			} else if ([[item country] isEqualToString:TRADE_ITEM_COUNTRY_US] == YES) {
				if ([item itemCategory] == ITEM_CATEGORY_CURRENCY) {
					if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"USD"]) {
						urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_USD,[item itemCode]];
					} else {
						urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_FX,[item itemCode]];
					}
				} else {
					urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_STOCK,[item itemCodeYahoo]];
				}
			} else if ([[item country] isEqualToString:TRADE_ITEM_COUNTRY_DE] == YES ||
					   [[item country] isEqualToString:TRADE_ITEM_COUNTRY_EU]) {
				if ([item itemCategory] == ITEM_CATEGORY_CURRENCY) {
					if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"EUR"]) {
						urlString = [NSString stringWithFormat:FORMAT_YAHOO_DE_EUR,[item itemCode]];
					} else {
						urlString = [NSString stringWithFormat:FORMAT_YAHOO_DE_FX,[item itemCode]];
					}
				} else {
					urlString = [NSString stringWithFormat:FORMAT_YAHOO_DE_STOCK,[item itemCodeYahoo]];
				}
			} else if ([[item country] isEqualToString:TRADE_ITEM_COUNTRY_CH] == YES) {
				if ([item itemCategory] == ITEM_CATEGORY_CURRENCY) {
					if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"CHF"]) {
						urlString = [NSString stringWithFormat:FORMAT_YAHOO_DE_CHF,[item itemCode]];
					} else {
						urlString = [NSString stringWithFormat:FORMAT_YAHOO_DE_FX,[item itemCode]];
					}
				} else {
					urlString = [NSString stringWithFormat:FORMAT_YAHOO_DE_STOCK,[item itemCodeYahoo]];
				}
			} else { // Other Country
				NSString* domain = [self CountryToDomain: [item country]];
				if ([item itemCategory] == ITEM_CATEGORY_CURRENCY) {
					NSString* currency = [self CountryToCurrency: [item country]];
					if ([[item itemCode] length] == 3 && currency && ![[item itemCode] isEqualToString:currency]) {
						urlString = [NSString stringWithFormat:FORMAT_YAHOO_XX_YY,[[item country] lowercaseString],[item itemCode],currency];
					} else {
						if (domain == nil || [domain isEqualToString:@""] == YES) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_FX,[item itemCode]];
						} else {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_XX_FX,domain,[item itemCode]];
						}
					}
				} else {
					if (domain == nil || [domain isEqualToString:@""] == YES) {
						urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_STOCK,[item itemCodeYahoo]];
					} else {
						urlString = [NSString stringWithFormat:FORMAT_YAHOO_XX_STOCK,domain,[item itemCodeYahoo]];
					}
				}
			}
			[webReader setTargetItem:item];
			[webReader purgeDocumentData];
			[self enableUrlRequest:NO];
			[webReader stopCrawling:YES];
            [reader stopCrawling:YES];
			[self jumpUrl:urlString:YES];
            [self enableWeb];
		}
	}
}

- (IBAction)refreshPrice:(id)sender
{
	[self startConnection:YES];
}

- (IBAction)refreshPriceDescending:(id)sender
{
	[self startConnection:NO];
}

- (IBAction)checkDetail:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([checkDetail state] == NSOnState) {
		[self setHiddenColumn:NO];
		[defaults setBool:YES forKey:tPrtPortfolioDetailKey];		
	} else {
		[self setHiddenColumn:YES];
		[defaults setBool:NO forKey:tPrtPortfolioDetailKey];		
	}
	[self rearrangeDocument];
}

- (IBAction)evaluateAllItems:(id)sender
{
	NSLog(@"evaluateAllItems");
	if ([portfolioArray count] == 0) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"NO_ITEMS",@"No item in portfolio.")];
		[alert beginSheetModalForWindow:[self win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
	NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *compo = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit)
										  fromDate:[datePicker dateValue]];
	NSString* dateFormat = [[NSString alloc] initWithFormat:@"%ld/%ld/%ld", (long)[compo year], (long)[compo month], (long)[compo day]];
	NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"OK",@"Ok")
									 defaultButton:NSLocalizedString(@"OK",@"Ok")
								   alternateButton:NSLocalizedString(@"CANCEL",@"Cancel")
									   otherButton:nil
						 informativeTextWithFormat:NSLocalizedString(@"SURE_EVALUATE",@"Do you want to record prices of all items on %@ ?"), dateFormat];
	NSLog(@"Stating alert sheet");
	[alert beginSheetModalForWindow:[tableView window]
					  modalDelegate:self
					 didEndSelector:@selector(alertEndedEvaluate:code:context:) contextInfo:NULL];
	[calendar release];
	[dateFormat release];
}

- (IBAction)openReader:(id)sender {
    NSLog(@"openReader");
    if (reader == nil) {
        reader = [[RssReader alloc] init];
        if (reader == nil) {
            return;
        }
        [reader setParentDoc:self];
    }
    NSLog(@"showing %@", reader);
    [reader showWindow:nil];
}

- (IBAction)changeStepper:(id)sender {
    int value = [itemStepper intValue];
	[tableView reloadData];
	[portfolioController rearrangeObjects];
    long count = [portfolioArray count];
    long index = [tableView selectedRow];
    NSLog(@"changeStepper: %d", value);
    [itemStepper setIntValue:0];
    if (index == -1) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"NOT_SELECTED",@"No item selected.")];
		[alert beginSheetModalForWindow:[self win] modalDelegate:self didEndSelector:nil contextInfo:nil];
        return;
    }
    if (count <= 1) {
        return;
    }
    if (value > 0) {
        // Up
        if (index == 0) {
            return;
        }
        [portfolioArray exchangeObjectAtIndex:index withObjectAtIndex:index - 1];
    } else if (value < 0) {
        // Down
        if (index == (count - 1)) {
            return;
        }
        [portfolioArray exchangeObjectAtIndex:index withObjectAtIndex:index + 1];
    }
    NSSound *sound = [NSSound soundNamed:@"Pop"];
    [sound play];
	index = 0;
	for (PortfolioItem* item in portfolioArray) {
		[item setIndex:++index];
	}
	[self rearrangeDocument];
	[self setPortfolioEdited];
}

- (IBAction)extendView:(id)sender {
    float trimHight = SPLIT_TREM_HIGHT;
    //NSRect winRect = [win frame];
    NSRect customRect = [customView frame];
    NSRect splitRect = [splitView frame];
    //NSLog(@"mask = %ld", (long)[splitView autoresizingMask]);
    //NSLog(@"window = (%.0f,%.0f),(%.0f, %.0f)", winRect.size.width, winRect.size.height, winRect.origin.x, winRect.origin.y);
    //NSLog(@"custom = (%.0f,%.0f),(%.0f, %.0f)", customRect.size.width, customRect.size.height, customRect.origin.x, customRect.origin.y);
    //NSLog(@"split = (%.0f,%.0f),(%.0f, %.0f)", splitRect.size.width, splitRect.size.height, splitRect.origin.x, splitRect.origin.y);
    if (extended == NO) {
        NSImage *template = [NSImage imageNamed:@"NSExitFullScreenTemplate"];
        [extendView setImage:template];
        splitRect.size.height = customRect.size.height - trimHight;
        splitRect.origin.y -= (customRect.size.height - trimHight - defaultHeight);
        [splitView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [webView setHidden:YES];
        [webTitle setHidden:YES];
        [comboBoxBookmark setHidden:YES];
        [splitView setFrame:splitRect];
        if ([portfolioSumArray count] > 2) {
            [splitView setPosition:112 ofDividerAtIndex:0];
        } else {
            [splitView setPosition:55 ofDividerAtIndex:0];
        }
        extended = YES;
    } else {
        NSImage *template = [NSImage imageNamed:@"NSEnterFullScreenTemplate"];
        [extendView setImage:template];
        [splitView setAutoresizingMask:NSViewWidthSizable|NSViewMinYMargin];
        splitRect.size.height = defaultHeight;
        splitRect.origin.y += (customRect.size.height - trimHight - defaultHeight);
        [webView setHidden:NO];
        [webTitle setHidden:NO];
        [comboBoxBookmark setHidden:NO];
        [splitView setFrame:splitRect];
        [splitView setPosition:55 ofDividerAtIndex:0];
        extended = NO;
    }
    [self rearrangeDocument];
    //winRect = [win frame];
    //customRect = [customView frame];
    //splitRect = [splitView frame];
    //NSLog(@"mask = %ld", (long)[splitView autoresizingMask]);
    //NSLog(@"window = (%.0f,%.0f),(%.0f, %.0f)", winRect.size.width, winRect.size.height, winRect.origin.x, winRect.origin.y);
    //NSLog(@"custom = (%.0f,%.0f),(%.0f, %.0f)", customRect.size.width, customRect.size.height, customRect.origin.x, customRect.origin.y);
    //NSLog(@"split = (%.0f,%.0f),(%.0f, %.0f)", splitRect.size.width, splitRect.size.height, splitRect.origin.x, splitRect.origin.y);
}

- (void)alertEndedEvaluate:(NSAlert*)alert
					  code:(int)choice
				   context:(void*)v
{
	NSLog(@"alertEndedEvaluate");
	if (choice == NSAlertDefaultReturn) {
		NSLog(@"Evaluate all items");
		NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		NSDateComponents *compo = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit)
											  fromDate:[datePicker dateValue]];
		for (PortfolioItem* item in portfolioArray) {
            if ([item type] == ITEM_TYPE_CASH) {
                continue;
            }
			TradeItem* trade = [[TradeItem alloc] init];
			if (trade == nil) {
				continue;
			}
			[trade setDate:[calendar dateFromComponents:compo]];
			[trade setKind:NSLocalizedString(@"NOTE",@"Note")];
			// [trade setKind:NSLocalizedString(@"EVALUATE",@"Evaluate")];
			[trade setPrice:[item price]];
			[[item trades] addObject:trade];
			[trade release];
			[item DoSettlement];
		}
		[calendar release];
		[self setPortfolioSumArray];
		[self setPortfolioEdited];
	}
}

- (IBAction)selectBookmark:(id)sender
{
	int	selected = [comboBoxBookmark indexOfSelectedItem];
	NSLog(@"selectBookmark: %d: %@", selected, [comboBoxBookmark stringValue]);
	Bookmark* bookmark = nil;
	NSString* title = [webTitle stringValue];
	NSString* url = [urlField stringValue];
	int	index = 0;
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
			[webReader stopCrawling:YES];
            [reader stopCrawling:YES];
			[self jumpUrl:[bookmark url]:NO];
			[bookmark release];
			NSSound *sound = [NSSound soundNamed:@"Submarine"];
			[sound play];
			break;
	}
	[self saveBookmark];
    //[comboBoxBookmark setTitleWithMnemonic:NSLocalizedString(@"BOOKMARK",@"Bookmarks")];
    [comboBoxBookmark selectItemWithObjectValue:NSLocalizedString(@"BOOKMARK",@"Bookmarks")];
}

- (IBAction)startCrawlingYahoo:(id)sender
{
	[webReader startCrawling:YES:NO:NO:NO];
}

- (IBAction)startCrawlingMinkabu:(id)sender
{
	[webReader startCrawling:NO:NO:YES:NO];
}

- (IBAction)startCrawlingGoogle:(id)sender
{
	[webReader startCrawling:NO:YES:NO:NO];
}

- (IBAction)startCrawlingBookmark:(id)sender
{
	[webReader startCrawlingBookmark];
}

- (IBAction)startCrawlingIR:(id)sender
{
	[webReader startCrawling:NO:NO:NO:YES];
}

- (IBAction)stopCrawling:(id)sender
{
	if ([webView isLoading]) {
		[webView stopLoading:sender];
	}
	[webReader stopCrawling:YES];
    [reader stopCrawling:YES];
}

- (WebView*)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request
{
	NSLog(@"createWebViewWithRequest: %@", request);
	NSURL *url = [[request URL] absoluteURL];
	[[NSWorkspace sharedWorkspace] openURL:url];
	return NULL;
}

- (void)webView:(WebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)actionInformation
														 request:(NSURLRequest *)request
													newFrameName:(NSString *)frameName
												decisionListener:(id)listener
{
	NSLog(@"decidePolicyForNewWindowAction: %@", request);
	NSURL *url = [[request URL] absoluteURL];
	NSURLRequest* urlRequest = [ NSURLRequest requestWithURL:url ];
	if (urlRequest) {
		if ([webView isLoading]) {
			[webView stopLoading:self];
		}
		WebFrame* mainFrame = [webView mainFrame];
		[mainFrame loadRequest:urlRequest];
	}
}

- (void)webView:(WebView*)sender decidePolicyForNavigationAction:(NSDictionary *)info
        request:(NSURLRequest *)request
          frame:(WebFrame*)frame
decisionListener:(id<WebPolicyDecisionListener>)listener
{
	//NSLog(@"decidePolicyForNewWindowAction: %@", request);
    if (enableRedirect == YES && [reader crawling] == NO) {
        NSURL *url = [[request URL] absoluteURL];
        if ([[url absoluteString] hasPrefix:@"feed://"] == YES ||
            [[url path] hasSuffix:@"/feed"] == YES ||
            [[url path] hasSuffix:@".rss"] == YES ||
            [[url path] hasSuffix:@".rdf"] == YES) {
            NSLog(@"open feed request: %@", [url absoluteString]);
            if (reader == nil) {
                reader = [[RssReader alloc] init];
                if (reader == nil) {
                    return;
                }
                [reader setParentDoc:self];
            }
            [ listener ignore];
            [reader setRedirect:YES];
            [reader showWindow:self];
            [[reader feedField] setStringValue:[url absoluteString]];
            [reader fetch:self];
            return;
        }
    }
    [ listener use ];
}

- (void)jumpUrl:(NSString*)urlString :(bool)connect
{
	WebFrame*		mainFrame;
	NSURL           *url;
    NSURLRequest    *urlRequest;
    //NSURL* url = [NSURL URLWithString:urlString];
    //NSURLRequest* urlRequest = [ NSURLRequest requestWithURL:url ];

	if ([urlString hasPrefix:@"http://"] || [urlString hasPrefix:@"https://"]) {
		url = [NSURL URLWithString:urlString];
    } else if ([urlString hasPrefix:@"feed:"] == YES) {
        NSRange range = [urlString rangeOfString:@"feed:"];
        NSMutableString* feed = [[NSMutableString alloc] initWithFormat:@"%@",urlString];
        [feed replaceCharactersInRange:range withString:@"http:"];
		url = [NSURL URLWithString:feed];
        [feed release];
	} else {
		url = [NSURL URLWithString:urlString];
    }
    urlRequest = [ NSURLRequest requestWithURL:url ];

	if (urlRequest) {
		if ([webView isLoading]) {
			[webView stopLoading:self];
		}
		mainFrame = [webView mainFrame];
		[mainFrame loadRequest:urlRequest];
		if (connect == YES) {
			[webReader startConnection:urlRequest];
		}
	}
}

- (void)startConnection:(bool)ascend
{
	if ([portfolioArray count] == 0) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"NO_ITEMS",@"No item in portfolio.")];
		[alert beginSheetModalForWindow:[self win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
	NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *compo = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit)
										  fromDate:[datePicker dateValue]];
	for (PortfolioItem* item in portfolioArray) {
		[item setDate:[calendar dateFromComponents:compo]];
	}
	NSDateComponents* today = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit)
										  fromDate:[NSDate date]];
	NSString* iPanelTitle;
	if ([[calendar dateFromComponents:compo] isEqualToDate: [calendar dateFromComponents:today]]) {
		iPanelTitle = [[NSString alloc] initWithFormat:@"Information : Change from last update"];
	} else {
		iPanelTitle = [[NSString alloc] initWithFormat:@"Information : Change from %ld/%ld/%ld", (long)[compo year], (long)[compo month], (long)[compo day]];
	}
	[calendar release];
	[tableView deselectAll:self];
	[tableViewSum deselectAll:self];
	[webReader pauseCrawling:YES];
	[webReader setModifiedPrice:0];
	[webReader clearCrawlingList];
	[webReader getCompareSetting];
	if (iPanel) {
		[iPanel stopSpeech:self];
		prevInfoPanel = iPanel;
		iPanel = nil;
	}
	iPanel = [[infoPanel alloc] init];
	if (iPanel) {
		[iPanel setTitle:iPanelTitle];
	}
	[iPanelTitle release];
	[webReader setConnectAscending:ascend];
	[self autoConnection:0:NO];
}

- (void)autoConnection:(int)index :(bool)retry
{
	int i = 0;
	bool primary;
	if ([webReader connectAscending] == YES) {
		if (retry == YES) {
			primary = NO;
		} else {
			primary = YES;
		}
	} else {
		if (retry == YES) {
			primary = YES;
		} else {
			primary = NO;
		}
	}
	NSString* lang = NSLocalizedString(@"LANG",@"English");
	PortfolioItem* item;
	for (item in portfolioArray) {
		i++;
		if (retry == YES) {
			if (i < index) {
				continue;
			}
		} else {
			if (i <= index) {
				continue;
			}
		}
		if (item == nil || [item itemCode] == nil ||
            [[item itemCode] isEqualToString:@""] ||
            [item type] == ITEM_TYPE_CASH) {
			continue;
		}
		
		// Select row of current item
		NSIndexSet* ixset = [NSIndexSet indexSetWithIndex:index];
		[tableView selectRowIndexes:ixset byExtendingSelection:NO];
		[tableView scrollRowToVisible:index];
		
		NSString *urlString = nil;
		if ([[item country] isEqualToString:TRADE_ITEM_COUNTRY_JP] == YES) {
			switch ([item itemCategory]) {
				case ITEM_CATEGORY_STOCK:
					if (primary == YES) {
						if ([item type] == ITEM_TYPE_INDEX) {
							if ([[item itemCode] hasPrefix:@"^"]) {
								urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_STOCK,[item itemCodeYahoo]];
							}
						}
						if (urlString == nil) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_STOCK,[item itemCodeJP]];
						}
					} else {
						if ([item type] == ITEM_TYPE_INDEX) {
							if ([[item itemCode] hasPrefix:@"^"]) {
								urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_STOCK,[item itemCodeJP]];
							}
						}
						if (urlString == nil) {
							if ([lang isEqualToString:@"Japanese"]) {
								urlString = [NSString stringWithFormat:FORMAT_MINKABU_JP_STOCK,[item itemCodeJP]];
							} else {
								urlString = [NSString stringWithFormat:FORMAT_GOOGLE_FINANCE,[item itemCodeGoogle]];
							}
						}
					}
					break;
				case ITEM_CATEGORY_CURRENCY:
					if (primary == YES) {
						if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"JPY"]) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_JPY,[item itemCode]];
						} else {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_STOCK,[item itemCode]];
						}
					} else {
						if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"JPY"]) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_USD,[item itemCode]];
						} else {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_FX,[item itemCode]];
						}
					}
					break;
				case ITEM_CATEGORY_FUND:
				default:
					if (primary == YES) {
						// urlString = [NSString stringWithFormat:FORMAT_MORNINGSTAR_JP_FUND,[item itemCode]];
                        urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_FUND,[item itemCode]];
					} else {
                        urlString = [NSString stringWithFormat:FORMAT_BLOOMBERG_JP_FUND,[item itemCode]];
					}
					break;
			}
		} else if ([[item country] isEqualToString:TRADE_ITEM_COUNTRY_US] == YES) {
			switch ([item itemCategory]) {
				case ITEM_CATEGORY_CURRENCY:
					if (primary == YES) {
						if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"USD"]) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_USD,[item itemCode]];
						} else {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_FX,[item itemCode]];
						}
					} else {
						if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"USD"]) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_USD,[item itemCode]];
						} else {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_STOCK,[item itemCode]];
						}
					}
					break;
				case ITEM_CATEGORY_STOCK:
				case ITEM_CATEGORY_FUND:
				default:
					if (primary == YES) {
						urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_STOCK,[item itemCodeYahoo]];
					} else {
						urlString = [NSString stringWithFormat:FORMAT_GOOGLE_FINANCE,[item itemCodeGoogle]];
					}
					break;
			}
		} else if ([[item country] isEqualToString:TRADE_ITEM_COUNTRY_DE] == YES ||
				   [[item country] isEqualToString:TRADE_ITEM_COUNTRY_EU] == YES) {
			switch ([item itemCategory]) {
				case ITEM_CATEGORY_CURRENCY:
					if (primary == YES) {
						if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"EUR"]) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_DE_EUR,[item itemCode]];
						} else {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_DE_FX,[item itemCode]];
						}
					} else {
						if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"EUR"]) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_EUR,[item itemCode]];
						} else {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_STOCK,[item itemCode]];
						}
					}
					break;
				case ITEM_CATEGORY_STOCK:
				case ITEM_CATEGORY_FUND:
				default:
					if (primary == YES) {
						urlString = [NSString stringWithFormat:FORMAT_YAHOO_DE_STOCK,[item itemCodeYahoo]];
					} else {
						if ([item type] == ITEM_TYPE_INDEX) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_STOCK,[item itemCodeYahoo]];
						} else {
							urlString = [NSString stringWithFormat:FORMAT_GOOGLE_FINANCE,[item itemCodeGoogle]];
						}
					}
					break;
			}
		} else if ([[item country] isEqualToString:TRADE_ITEM_COUNTRY_CH] == YES) {
			switch ([item itemCategory]) {
				case ITEM_CATEGORY_CURRENCY:
					if (primary == YES) {
						if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"CHF"]) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_DE_CHF,[item itemCode]];
						} else {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_DE_FX,[item itemCode]];
						}
					} else {
						if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"CHF"]) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_CHF,[item itemCode]];
						} else {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_STOCK,[item itemCode]];
						}
					}
					break;
				case ITEM_CATEGORY_STOCK:
				case ITEM_CATEGORY_FUND:
				default:
					if (primary == YES) {
						urlString = [NSString stringWithFormat:FORMAT_YAHOO_DE_STOCK,[item itemCodeYahoo]];
					} else {
						if ([item type] == ITEM_TYPE_INDEX) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_STOCK,[item itemCodeYahoo]];
						} else {
							urlString = [NSString stringWithFormat:FORMAT_GOOGLE_FINANCE,[item itemCodeGoogle]];
						}
					}
					break;
			}
		} else {	// Other Country
			NSString* currency;
			NSString* domain = [self CountryToDomain: [item country]];
			switch ([item itemCategory]) {
				case ITEM_CATEGORY_CURRENCY:
					currency = [self CountryToCurrency: [item country]];
					if (primary == YES) {
						if ([[item itemCode] length] == 3 && currency && ![[item itemCode] isEqualToString:currency]) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_XX_YY,[[item country] lowercaseString],[item itemCode],currency];
						} else {
							if (domain == nil || [domain isEqualToString:@""] == YES) {
								urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_FX,[item itemCode]];
							} else {
								urlString = [NSString stringWithFormat:FORMAT_YAHOO_XX_FX,domain,[item itemCode]];
							}
						}
					} else {
						if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:currency]) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_YY,[item itemCode],currency];
						} else {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_STOCK,[item itemCode]];
						}
					}
					break;
				case ITEM_CATEGORY_STOCK:
				case ITEM_CATEGORY_FUND:
				default:
					if (primary == YES) {
						if ([item type] == ITEM_TYPE_INDEX) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_STOCK,[item itemCodeYahoo]];
						} else if (domain == nil || [domain isEqualToString:@""] == YES) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_STOCK,[item itemCodeYahoo]];
						} else {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_XX_STOCK,domain,[item itemCodeYahoo]];
						}
					} else {
						if ([item type] == ITEM_TYPE_INDEX) {
							if (domain != nil && [domain isEqualToString:@""] == NO) {
								urlString = [NSString stringWithFormat:FORMAT_YAHOO_XX_STOCK,domain,[item itemCodeYahoo]];
							} else {
								urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_STOCK,[item itemCodeYahoo]];
							}
						} else {
							urlString = [NSString stringWithFormat:FORMAT_GOOGLE_FINANCE,[item itemCodeGoogle]];
						}
					}
					break;
			}
		}

		NSURL* url = [NSURL URLWithString:urlString];
		NSURLRequest* urlRequest = [NSURLRequest requestWithURL:url];
		[webReader setConnectionRetry:retry];
		[webReader setConnectionIndex:i];
		[webReader setTargetItem:item];
		[self enableUrlRequest:NO];
		progressConnection = YES;
		[progress startAnimation:self];
		[webReader startConnection:urlRequest];
		//NSSound *sound = [NSSound soundNamed:@"Pop"];
		//[sound play];
		break;
	}
	if (item) {
		[item retain];
	} else {
		progressConnection = NO;
		if (progressWebView == NO) {
			[progress stopAnimation:self];
		}
		[self enableUrlRequest:YES];
		[webReader setConnectionIndex:0];
		
		// reset selected row
		NSIndexSet* ixset = [NSIndexSet indexSetWithIndex:0];
		[tableView selectRowIndexes:ixset byExtendingSelection:NO];
		[tableView scrollRowToVisible:index];
		[tableView deselectAll:self];
		
		NSAlert *alert;
		if ([webReader modifiedPrice]) {
			// Prices are updated.
			if (iPanel == nil) {
				iPanel = [[infoPanel alloc] init];
			}
			if (prevInfoPanel) {
				[prevInfoPanel close];
				[prevInfoPanel release];
				prevInfoPanel = nil;
			}
			//NSLog(@"PriceList: %@", priceList);
			//for (infoItem* ii in [iPanel items]) {
			//	NSLog(@"%@ %@ %@ %.2f", [ii name], [ii price], [ii diff], [ii raise]*100);
			//}
			for (PortfolioItem* item in portfolioArray) {
				[item setDate:[NSDate date]];
			}
			[iPanel sortItems];
			[iPanel showWindow:self];
			[[iPanel infoPanel] setTitle:[iPanel title]];
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			NSData *colorAsData;
			colorAsData = [defaults objectForKey:tPrtTableBgColorKey];
			if (colorAsData) {
				[[iPanel infoTableView] setBackgroundColor:[NSKeyedUnarchiver unarchiveObjectWithData:colorAsData]];
				[[iPanel infoView] setBackgroundColor:[NSKeyedUnarchiver unarchiveObjectWithData:colorAsData]];
			}
			colorAsData = [defaults objectForKey:tPrtTableFontColorKey];
			if (colorAsData) {
				[iPanel setFontColor:[NSKeyedUnarchiver unarchiveObjectWithData:colorAsData]];
			}
            //selectAutoPilot = [defaults boolForKey:tPrtSelectAutoPilotKey];
			[[iPanel infoView] setEditable:YES];
			[[iPanel infoView] setString:[iPanel priceList]];
			[[iPanel infoView] setEditable:NO];
			[[iPanel infoTableView] deselectAll:self];
			[iPanel rearrangePanel];
            if (selectAutoPilot == YES) {
                alert = [NSAlert alertWithMessageText:NSLocalizedString(@"INFO",@"Info")
                                        defaultButton:NSLocalizedString(@"AUTO_PILOT",@"AutoPilot")
                                      alternateButton:NSLocalizedString(@"CANCEL",@"Cancel")
                                          otherButton:NSLocalizedString(@"SPEECH",@"Speech")
                            informativeTextWithFormat:NSLocalizedString(@"ALL_PRICE_UPDATED",@"prices of %d items are updated."), [webReader modifiedPrice]];
            } else {
                alert = [NSAlert alertWithMessageText:NSLocalizedString(@"INFO",@"Info")
                                        defaultButton:NSLocalizedString(@"CANCEL",@"Cancel")
                                      alternateButton:NSLocalizedString(@"AUTO_PILOT",@"AutoPilot")
                                          otherButton:NSLocalizedString(@"SPEECH",@"Speech")
                            informativeTextWithFormat:NSLocalizedString(@"ALL_PRICE_UPDATED",@"prices of %d items are updated."), [webReader modifiedPrice]];
            }
		} else {
			// Prices are not modified.
			[iPanel release];
			iPanel = prevInfoPanel;
            //NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            //selectAutoPilot = [defaults boolForKey:tPrtSelectAutoPilotKey];
            if (selectAutoPilot == YES) {
                alert = [NSAlert alertWithMessageText:NSLocalizedString(@"INFO",@"Info")
                                        defaultButton:NSLocalizedString(@"AUTO_PILOT",@"AutoPilot")
                                      alternateButton:NSLocalizedString(@"CANCEL",@"Cancel")
                                          otherButton:nil
                            informativeTextWithFormat:NSLocalizedString(@"NO_PRICE_UPDATED",@"prices of items are not updated.")];
            } else {
                alert = [NSAlert alertWithMessageText:NSLocalizedString(@"INFO",@"Info")
                                        defaultButton:NSLocalizedString(@"CANCEL",@"Cancel")
                                      alternateButton:NSLocalizedString(@"AUTO_PILOT",@"AutoPilot")
                                          otherButton:nil
                            informativeTextWithFormat:NSLocalizedString(@"NO_PRICE_UPDATED",@"prices of items are not updated.")];
            }
		}
		[alert beginSheetModalForWindow:[self win] modalDelegate:self didEndSelector:@selector(alertAutoConnection:code:context:) contextInfo:NULL];
		//for (infoItem* ii in [iPanel items]) {
		//	NSLog(@"%@ %@ %@ %.2f", [ii name], [ii price], [ii diff], [ii raise]*100);
		//}
	}
}

- (void)alertAutoConnection:(NSAlert*)alert
					   code:(int)choice
					context:(void*)v
{
	NSLog(@"alertAutoConnection");
    if (selectAutoPilot == YES) {
        if (choice == NSAlertDefaultReturn) {
            [self enableWeb];
            [webReader startCrawling];
        } else if (choice == NSAlertOtherReturn) {
            [iPanel startSpeech:self];
        } else {
            //selectAutoPilot = NO;
        }
    } else {
        if (choice == NSAlertAlternateReturn) {
            [self enableWeb];
            [webReader startCrawling];
            //selectAutoPilot = YES;
        } else if (choice == NSAlertOtherReturn) {
            [iPanel startSpeech:self];
        }
    }
    //NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //[defaults setBool:selectAutoPilot forKey:tPrtSelectAutoPilotKey];
}

- (void)enableUrlRequest:(bool)isEnable
{
	[[self goToIR] setEnabled:isEnable];
	[[self goToPortal] setEnabled:isEnable];
	[[self goToYahoo] setEnabled:isEnable];
	[[self refreshPrice] setEnabled:isEnable];
	if (isEnable == YES) {
		[[self refreshPrice] setState:NSOffState];
	}
	[[self urlField] setEnabled:isEnable];
}

- (void)enableWeb
{
    if (extended == YES) {
        [self extendView:self];
    }
}

- (PortfolioItem*)searchPortfolioItemByIndex:(int)index
{
	for (PortfolioItem* item in portfolioArray) {
		if (index == [item index]) {
			// NSLog(@"searchPortfolioItemByIndex:%d = %@", index, [item itemName]);
			return item;
		}
	}
	return nil;
}

- (void)addCashItem
{
    Boolean hasCash = NO;
    for (PortfolioItem *item in portfolioArray) {
        if ([item type] == ITEM_TYPE_CASH) {
            hasCash = YES;
        }
    }
    if (hasCash == YES) {
        return;
    }
    PortfolioItem *cash = [[PortfolioItem alloc] init];
    if (cash == nil) {
        return;
    }
    [cash setType:ITEM_TYPE_CASH];
    if ([ITEM_TYPE_EN_STOCK isEqualToString:NSLocalizedString(@"CASH",@"Cash")]) {
        [cash setItemType:ITEM_TYPE_EN_CASH];
        [cash setItemName:ITEM_TYPE_EN_CASH];
    } else {
        [cash setItemType:ITEM_TYPE_JP_CASH];
        [cash setItemName:ITEM_TYPE_JP_CASH];
    }
    [cash setItemCode:@"-----"];
    [cash setPrice:1.0];
    [self startObservingPortfolio:cash];
    [portfolioArray insertObject:cash atIndex:0];
    [cash release];
	return;
}

- (void)sortPortfolioByKey:(NSString*)key :(bool)caseInsensitive :(bool)ascend
{
	NSLog(@"sortPortfolipByKey: %@", key);
	if (key == nil) {
		return;
	}
	NSSortDescriptor	*descriptor;
	NSMutableArray		*sortDescriptors = [[NSMutableArray alloc] init];
	if (caseInsensitive) {
		descriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:ascend selector:@selector(caseInsensitiveCompare:)];
	} else {
		descriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:ascend selector:@selector(compare:)];
	}
	[sortDescriptors addObject:descriptor];
	[portfolioArray sortUsingDescriptors:sortDescriptors];
	[descriptor release];
	[sortDescriptors release];
    speechIndex = 0;
	int index = 0;
	for (PortfolioItem* item in portfolioArray) {
		[item setIndex:++index];
	}
	[self rearrangeDocument];
	[self setPortfolioEdited];
}

#pragma mark Performance sheet

- (IBAction)checkoutPerformance:(id)sender
{
    NSLog(@"checkoutPerformance");
    [self showPerformanceSheet:sender];
}

- (IBAction)showPerformanceSheet:(id)sender
{
    NSLog(@"showPerformanceSheet");
    [NSApp beginSheet:performanceSheet
       modalForWindow:win
        modalDelegate:nil
       didEndSelector:NULL
          contextInfo:NULL];
    [performanceFromDate setDateValue: [datePicker dateValue]];
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *compoFrom = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit)
                                              fromDate:[performanceFromDate dateValue]];
    [compoFrom setYear:[compoFrom year] -1];
    [performanceFromDate setDateValue: [calendar dateFromComponents:compoFrom]];
    [calendar release];
    [performanceToDate setDateValue: [datePicker dateValue]];
}

- (IBAction)endPerformanceSheet:(id)sender
{
    NSLog(@"endPerformanceSheet");
    [NSApp endSheet:performanceSheet];
    [performanceSheet orderOut:sender];
    if (sender == performanceCancel) {
        return;
    }
    NSComparisonResult result = [[performanceFromDate dateValue] compare:[performanceToDate dateValue]];
    if (result != NSOrderedAscending) {
        NSBeep();
        [NSApp beginSheet:performanceSheet
           modalForWindow:win
            modalDelegate:nil
           didEndSelector:NULL
              contextInfo:NULL];
        return;
    }
    
    // allocate infoPanel
    if (prevInfoPanel) {
        [prevInfoPanel close];
        [prevInfoPanel release];
        prevInfoPanel = nil;
    }
    if (iPanel) {
        [iPanel stopSpeech:self];
        prevInfoPanel = iPanel;
        iPanel = nil;
    }
    iPanel = [[infoPanel alloc] init];
    
    // build date
    for (PortfolioItem* item in portfolioArray) {
        if ([item type] == ITEM_CATEGORY_CASH) {
            continue;
        }
        double fromPrice;
        double toPrice;
        bool isFloat = NO;
        NSString*	c = [item itemCurrencySymbol];
        fromPrice = [item GetRecordedPrice:[performanceFromDate dateValue]];
        toPrice = [item GetRecordedPrice:[performanceToDate dateValue]];
        float diff = toPrice - fromPrice;
        float raise = round((toPrice/fromPrice-1)*100000)/1000;
        if ([item itemCategory] == ITEM_CATEGORY_CURRENCY ||
            [item type] == ITEM_TYPE_INDEX) {
            isFloat = YES;
        }
        NSString* priceStr;
        if (isFloat == YES) {
            priceStr = [NSString stringWithFormat:@"%@%0.4f", c, toPrice];
        } else {
            priceStr = [NSString stringWithFormat:@"%@%0.2f", c, toPrice];
        }
        NSString* diffStr;
        if (diff >= 0) {
            if (isFloat == YES) {
                diffStr = [NSString stringWithFormat:@"+%0.4f", diff];
            } else {
                diffStr = [NSString stringWithFormat:@"+%0.2f", diff];
            }
        } else {
            if (isFloat == YES) {
                diffStr = [NSString stringWithFormat:@"%0.4f", diff];
            } else {
                diffStr = [NSString stringWithFormat:@"%0.2f", diff];
            }
        }
        [iPanel setItem:[item itemName]:[item itemCode] :priceStr :diffStr :raise/100 :[item itemCurrencyNameJP]];
    }
    [iPanel sortItems];
    
    // show info panel
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *compoFrom = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit)
                                              fromDate:[performanceFromDate dateValue]];
    NSDateComponents *compoTo = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit)
                                            fromDate:[performanceToDate dateValue]];
    NSString* iPanelTitle;
    iPanelTitle = [[NSString alloc] initWithFormat:@"Information : Change from %ld/%ld/%ld to %ld/%ld/%ld",
                   (long)[compoFrom year], (long)[compoFrom month], (long)[compoFrom day],
                   (long)[compoTo year], (long)[compoTo month], (long)[compoTo day]];
    [calendar release];
    [iPanel showWindow:self];
    [[iPanel infoPanel] setTitle:iPanelTitle];
    [iPanelTitle release];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *colorAsData;
    colorAsData = [defaults objectForKey:tPrtTableBgColorKey];
    if (colorAsData) {
        [[iPanel infoTableView] setBackgroundColor:[NSKeyedUnarchiver unarchiveObjectWithData:colorAsData]];
        [[iPanel infoView] setBackgroundColor:[NSKeyedUnarchiver unarchiveObjectWithData:colorAsData]];
    }
    colorAsData = [defaults objectForKey:tPrtTableFontColorKey];
    if (colorAsData) {
        [iPanel setFontColor:[NSKeyedUnarchiver unarchiveObjectWithData:colorAsData]];
    }
    [[iPanel infoView] setEditable:YES];
    [[iPanel infoView] setString:[iPanel priceList]];
    [[iPanel infoView] setEditable:NO];
    [[iPanel infoTableView] deselectAll:self];
    [iPanel rearrangePanel];
}

#pragma mark Portfolio Item sheet

- (IBAction)showProtfolioItemSheet:(id)sender
{
    NSLog(@"showProtfolioItemSheet");
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* defaultCountry = [defaults objectForKey:tPrtCountryKey];
    if (defaultCountry == nil) {
        NSString* lang = NSLocalizedString(@"LANG",@"English");
        if ([lang isEqualToString:@"Japanese"]) {
            defaultCountry = TRADE_ITEM_COUNTRY_JP;
        } else {
            defaultCountry = TRADE_ITEM_COUNTRY_US;
        }
    }
    [self setPortfolioItemCountryFlag];
    [portfolioItemCountryBox setStringValue:defaultCountry];
    [portfolioItemCodeField setStringValue:@""];
    [portfolioItemNameField setStringValue:NSLocalizedString(@"NEW_ITEM",@"New Item")];
    [portfolioItemSiteField setStringValue:@"http://"];
    [portfolioItemNoteField setStringValue:@""];
    [portfolioItemCountryName setStringValue:@""];
    [NSApp beginSheet:portfolioItemSheet
       modalForWindow:win
        modalDelegate:nil
       didEndSelector:NULL
          contextInfo:NULL];
    [self buildPortfolioItemComboBox];
    [self setPortfolioItemCountryFlag];
}

- (IBAction)endProtfolioItemSheet:(id)sender
{
    NSLog(@"endPortfolioItemSheet");
    if (sender == portfolioItemCancel) {
        [NSApp endSheet:portfolioItemSheet];
        [portfolioItemSheet orderOut:sender];
        return;
    }
    if ([[portfolioItemCountryBox stringValue] isEqualToString:@""] == YES ||
        [[portfolioItemTypeBox stringValue] isEqualToString:@""] == YES ) {
        NSBeep();
        return;
    }
    if ([[portfolioItemCodeField stringValue] isEqualToString:@""] == YES &&
        [[portfolioItemNameField stringValue] isEqualToString:@""] == YES ) {
        NSBeep();
        return;
    }
    [NSApp endSheet:portfolioItemSheet];
    [portfolioItemSheet orderOut:sender];
    [self createPortfolioItem:sender];
}

- (IBAction)setPortfolioItem:(id)sender
{
    NSLog(@"setPortfolioItem");
    if (sender == portfolioItemCodeField) {
        ;
    } else if (sender == portfolioItemSiteField) {
        if ([[portfolioItemSiteField stringValue] hasPrefix:@"http://"] ||
            [[portfolioItemSiteField stringValue] hasPrefix:@"https://"]) {
            ;
        }
    }
    return;
}

- (IBAction)setCountryFlag:(id)sender
{
    [self setPortfolioItemCountryFlag];
}

- (void)setPortfolioItemCountryFlag
{
    NSLog(@"setPortfolioItemCountryFlag: %@",[portfolioItemCountryBox stringValue]);
    NSImage *template;
    NSString *path = [[NSString alloc] initWithFormat:@"flag%@",[portfolioItemCountryBox stringValue]];
    template = [NSImage imageNamed:path];
    if (template == nil) {
        template = [NSImage imageNamed:@"flag-None"];
    }
    if (template) {
        [portfolioItemCountryFlag setImage:template];
    }
    [path release];
    if ([[portfolioItemCountryBox stringValue] isEqualToString:@"AE"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_AE",@"United Arab Emirates")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"AR"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_AR",@"Argentina")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"AT"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_AT",@"Austria")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"AU"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_AU",@"Australia")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"BE"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_BE",@"Belgium")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"BR"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_BR",@"Brazil")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"CA"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_CA",@"Canada")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"CH"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_CH",@"Switzerland")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"CN"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_CN",@"Chaina")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"DE"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_DE",@"Germany")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"DK"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_DK",@"Denmark")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"EG"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_EG",@"Egypt")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"ES"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_ES",@"Spain")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"EU"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_EU",@"European Union")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"FI"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_FI",@"Finland")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"FR"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_FR",@"France")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"GR"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_GR",@"Greece")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"HK"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_HK",@"HongKong")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"ID"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_ID",@"Indonesia")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"IN"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_IN",@"India")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"IT"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_IT",@"Italy")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"JP"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_JP",@"Japan")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"KR"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_KR",@"Koria")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"LU"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_LU",@"Luxembourg")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"MX"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_MX",@"Mexico")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"MY"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_MY",@"Malaysia")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"NL"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_NL",@"Netherlands")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"NO"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_NO",@"Norway")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"NZ"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_NZ",@"New Zealand")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"PH"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_PH",@"Philippines")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"PT"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_PT",@"Portugal")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"RU"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_RU",@"Russia")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"SA"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_SA",@"Saudi Arabia")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"SE"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_SE",@"Sweden")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"SG"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_SG",@"Singapura")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"TH"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_TH",@"Thailand")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"TR"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_TR",@"Turkey")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"TW"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_TW",@"Taiwan")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"UK"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_UK",@"United Kingdom")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"US"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_US",@"United States")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"VN"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_VN",@"Vietnam")];
    } else if ([[portfolioItemCountryBox stringValue] isEqualToString:@"ZA"] == YES) {
        [portfolioItemCountryName setStringValue:NSLocalizedString(@"COUNTRY_SA",@"South Africa")];
    } else {
        if ([[portfolioItemCountryBox stringValue] isEqualToString:customCountryCode] == YES) {
            [portfolioItemCountryName setStringValue:customCountryName];
        } else {
            [portfolioItemCountryName setStringValue: @"Unknown"];
        }
    }
}

- (void)buildPortfolioItemComboBox
{
    [portfolioItemCountryBox removeAllItems];
    if (customCountry == YES &&
        [customCountryCode length] == 2 &&
        [customCurrencyCode length] == 3) {
        [portfolioItemCountryBox addItemWithObjectValue:customCountryCode];
    }
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_AE];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_AT];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_AR];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_AU];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_BE];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_BR];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_CA];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_CH];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_CN];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_DE];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_DK];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_EG];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_ES];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_EU];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_FI];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_FR];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_GR];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_HK];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_ID];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_IN];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_IT];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_JP];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_KR];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_LU];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_MX];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_MY];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_NL];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_NO];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_NZ];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_PH];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_PT];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_RU];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_SA];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_SE];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_SG];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_SI];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_SK];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_TH];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_TR];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_TW];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_UK];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_US];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_VN];
    [portfolioItemCountryBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_ZA];
}

#pragma mark Graph

/*
- (void)allocPortfolioWorkArray
{
    [self freePortfolioWorkArray];
    portfolioWorkArray = [[NSMutableArray alloc] init];
    if (portfolioWorkArray == nil) {
        return;
    }
    for (PortfolioItem *item in portfolioArray) {
        [portfolioWorkArray addObject:item];
    }
    return;
}

- (void)freePortfolioWorkArray
{
    if (portfolioWorkArray == nil) {
        return;
    }
    [portfolioWorkArray removeAllObjects];
    [portfolioWorkArray release];
    return;
}
*/

- (void)buildGraph:(NSString*)countryCode
{
    //[self allocPortfolioWorkArray];
    NSDate *date, *baseDate;
    NSInteger year;
    NSInteger month;
    NSInteger day;
    NSInteger index;
    NSString *symbol = nil;
    NSInteger term = [gPanel term];
    double estimatedValue;
    double investedValue;
    double creditLongEstimatedValue;
    double creditLongDealedValue;
    double creditShortEstimatedValue;
    double creditShortDealedValue;
    double performanceValue;
    double cash;
    double max;
    Boolean separate = separateCash;
    NSLog(@"buildGraph");
    date = [datePicker dateValue];
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *compo = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit)
										  fromDate:date];
    baseDate = [calendar dateFromComponents:compo];
    estimatedValue = 0;
    investedValue = 0;
    performanceValue = 0;
    creditLongDealedValue = 0;
    creditShortDealedValue = 0;
    creditLongEstimatedValue = 0;
    creditShortEstimatedValue = 0;
    cash = 0;
	for (PortfolioItem* item in portfolioArray) {
        if ([[item country] isEqualToString:countryCode] ==YES) {
            [item setDate:[calendar dateFromComponents:compo]];
            [item DoSettlement];
            if ([item type] == ITEM_TYPE_CASH && separate == YES) {
                cash += [item value];
            } else {
                if ([item credit] == TRADE_TYPE_SHORTSELL) {
                    creditShortEstimatedValue += [item value];
                    creditShortDealedValue += [item investment];
                } else if ([item credit] == TRADE_TYPE_LONGBUY) {
                    creditLongEstimatedValue += [item value];
                    creditLongDealedValue += [item investment];
                } else {
                    investedValue += [item investment];
                    estimatedValue += [item value];
                }
            }
            if (symbol == nil) {
                symbol = [item itemCurrencySymbol];
            }
        }
	}
    max = estimatedValue;
    if (investedValue > max) {
        max = investedValue;
    }
    [gPanel setSymbol:symbol];
    [gPanel setCountry:countryCode];
    
    year = [compo year];
    month = [compo month];
    day = [compo day];
    index = GRAPH_BAR_COUNT - 1;
    NSLog(@"%ld/%ld/%ld: %f", (long)year, (long)month, (long)day, estimatedValue);
    [[gPanel graphView] setValueAtIndex:estimatedValue:index];
    [[gPanel graphView] setDateAtIndex:[calendar dateFromComponents:compo]:index];
    if ((investedValue+creditLongDealedValue+creditShortEstimatedValue) > 0) {
		performanceValue = ((estimatedValue+creditLongEstimatedValue+creditShortDealedValue)/(investedValue+creditLongDealedValue+creditShortEstimatedValue)-1)*100;
	}
    [[gPanel graphView] setPerformanceAtIndex:performanceValue:index];

    for (int i = 0; i < term*GRAPH_BAR_COUNT-1; i++) {
        month--;
        if (month <= 0) {
            month = 12;
            year--;
        }
        if (term > 1 && (month % term) != 0) {
            continue;
        }
        [compo setMonth:month];
        [compo setYear:year];
        [compo setDay:1];
        date = [calendar dateFromComponents:compo];
        NSRange range = [calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:date];
        [compo setDay:range.length];
        year = [compo year];
        month = [compo month];
        day = [compo day];
        date = [calendar dateFromComponents:compo];
        estimatedValue = 0;
        investedValue = 0;
        performanceValue = 0;
        creditLongDealedValue = 0;
        creditShortDealedValue = 0;
        creditLongEstimatedValue = 0;
        creditShortEstimatedValue = 0;
        cash = 0;
        for (PortfolioItem* item in portfolioArray) {
            if ([[item country] isEqualToString:countryCode] ==YES) {
                [item setDate:date];
                [item DoSettlement];
                if ([item type] == ITEM_TYPE_CASH && separate == YES) {
                    cash += [item value];
                } else {
                    if ([item credit] == TRADE_TYPE_SHORTSELL) {
                        creditShortEstimatedValue += [item value];
                        creditShortDealedValue += [item investment];
                    } else if ([item credit] == TRADE_TYPE_LONGBUY) {
                        creditLongEstimatedValue += [item value];
                        creditLongDealedValue += [item investment];
                    } else {
                        investedValue += [item investment];
                        estimatedValue += [item value];
                    }
                }
            }
        }
        NSLog(@"%ld/%ld/%ld: %f", (long)year, (long)month, (long)day, estimatedValue);
        if (estimatedValue > max) {
            max = estimatedValue;
        }
        if (investedValue > max) {
            max = investedValue;
        }
        index--;
        [[gPanel graphView] setValueAtIndex:estimatedValue:index];
        [[gPanel graphView] setDateAtIndex:[calendar dateFromComponents:compo]:index];
        if ((investedValue+creditLongDealedValue+creditShortEstimatedValue) > 0) {
            performanceValue = ((estimatedValue+creditLongEstimatedValue+creditShortDealedValue)/(investedValue+creditLongDealedValue+creditShortEstimatedValue)-1)*100;
        }
        [[gPanel graphView] setPerformanceAtIndex:performanceValue:index];
        if (index == 0) {
            break;
        }
    }
    [[gPanel graphView] setMax:max];
    [[gPanel graphView] buildBar];
	for (PortfolioItem* item in portfolioArray) {
        if ([[item country] isEqualToString:countryCode] ==YES) {
            [item setDate:baseDate];
            [item DoSettlement];
        }
	}
    NSInteger unit;
    NSInteger num;
    for (unit =1, num = max/unit; num > 15; unit = unit*10) {
        num = max/(unit*10);
    }
    [[gPanel graphView] setUnit:unit];
    [calendar release];
    //[self freePortfolioWorkArray];
}

#pragma mark Archiver

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If the given outError != NULL, ensure that you set *outError when returning nil.

    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.

    // For applications targeted for Panther or earlier systems, you should use the deprecated API -dataRepresentationOfType:. In this case you can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.

    // if ( outError != NULL ) {
	// 	*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	// }
	// return nil;
	NSLog(@"dataOfType");
	[[tableView window] endEditingFor:nil];	
	NSData *d = [NSKeyedArchiver archivedDataWithRootObject:portfolioArray];	
	return d;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type.  If the given outError != NULL, ensure that you set *outError when returning NO.

    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead. 
    
    // For applications targeted for Panther or earlier systems, you should use the deprecated API -loadDataRepresentation:ofType. In this case you can also choose to override -readFromFile:ofType: or -loadFileWrapperRepresentation:ofType: instead.
    
    // if ( outError != NULL ) {
	// 	*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	// }
    // return YES;
	NSLog(@"About to read data of type %@", typeName);
	NSMutableArray *newArray = nil;
	@try {
		newArray = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	}
	@catch (NSException *e) {
		if (outError) {
			NSDictionary *d = [NSDictionary
							   dictionaryWithObject:@"The data is corrupted."
							   forKey:NSLocalizedFailureReasonErrorKey];
			*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:d];
		}
		return NO;
	}
	[self setPortfolio:newArray];
	return YES;
}

- (void)loadBookmark
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *bookmarkAsData = [defaults objectForKey:tPrtBookmarkListKey];
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
	[defaults setObject:bookmarkAsData forKey:tPrtBookmarkListKey];	
}

#pragma mark Preference

- (void)handleColorChange:(NSNotification*)note
{
	NSLog(@"Received nptification: %@", note);
	NSColor *color = [[note userInfo] objectForKey:@"color"];
	[ tableView setBackgroundColor:color ];
	[ tableViewSum setBackgroundColor:color ];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *colorAsData;
	colorAsData = [defaults objectForKey:tPrtTableFontColorKey];
	if (colorAsData) {
		[self setFontColor:[NSKeyedUnarchiver unarchiveObjectWithData:colorAsData]];
	}
    if (reader) {
        [[reader tableView] setBackgroundColor:color];
        [reader setFontColor:[NSKeyedUnarchiver unarchiveObjectWithData:colorAsData]];
    }
    if (cashAccount) {
        [[cashAccount tableView] setBackgroundColor:color];
        [cashAccount setFontColor:[NSKeyedUnarchiver unarchiveObjectWithData:colorAsData]];
    }
    NSString *kanji = [defaults objectForKey:tPrtFaveriteKanjiKey];
    if (kanji && [kanji isEqualToString:@""] == NO) {
        [tanukiBelly setHidden:NO];
        [tanukiBelly setStringValue:kanji];
    } else {
        [tanukiBelly setHidden:YES];
    }
}

- (void)handleBookmarkChange:(NSNotification*)note
{
	NSLog(@"Received nptification: %@", note);
	[bookmarks removeAllObjects];
	[comboBoxBookmark removeAllItems];
	[comboBoxBookmark removeAllItems];
	NSString* lang = NSLocalizedString(@"LANG",@"English");
	if ([lang isEqualToString:@"Japanese"]) {
		[comboBoxBookmark addItemWithObjectValue:@"ブックマークを追加する (50件まで)"];
	} else {
		[comboBoxBookmark addItemWithObjectValue:@"Add Bookmark (Up to 50 items)"];
	}
	[self loadBookmark];
}

- (void)handleFeedChange:(NSNotification*)note
{
	NSLog(@"Received nptification: %@", note);
    if (reader) {
        [reader handleFeedChange:note];
    }
}

#pragma mark View Controller

- (void)progressStarted:(NSNotification *)notification
{
    [progress setHidden:NO];
    [progress startAnimation:self];
	progressWebView = YES;
}

- (void)progressFinished:(NSNotification *)notification
{
	progressWebView = NO;
	if (progressConnection == NO) {
		[progress stopAnimation:self];
		[self enableUrlRequest:YES];
	}
}

/*
- (void)selectionDidChanging:(NSNotification *)notification {
	NSLog(@"selectionDidChanging: row = %d", [tableView selectedRow]);
}
*/

- (void)selectionDidChanged:(NSNotification *)notification {
	NSLog(@"selectionDidChanged: row = %d", (int)[tableView selectedRow]);
	[self setTableColumeAttribute:[tableView selectedRow]];
}

- (void)setTableColumeAttribute:(int)row
{
	NSLog(@"setTableColumeAttribute row = %d", row);
	if (row < 0) {
		return;
	}
	PortfolioItem *item = [portfolioArray objectAtIndex:row];
	NSTableColumn *columnKind = nil;
	NSTableColumn *columnCountry = nil;
	columnKind = [tableView  tableColumnWithIdentifier:@"kind"];
	columnCountry = [tableView  tableColumnWithIdentifier:@"country"];
	if ([item trades] != nil && [[item trades] count]) {
		NSLog(@"trades is not empty");
		[columnKind setEditable:NO];
		[columnCountry setEditable:NO];
	} else {
		NSLog(@"trades is empty");
		[columnKind setEditable:YES];
		[columnCountry setEditable:YES];
	}
}

- (void)setPortfolioEdited
{
	[win setDocumentEdited:true];
	[self updateChangeCount:NSChangeDone];
}

- (void)setHiddenColumn:(bool)hidden
{
	NSTableColumn *column = nil;
	column = [tableView tableColumnWithIdentifier:@"estimate"];
	[column setHidden:hidden];
	column = [tableView tableColumnWithIdentifier:@"investment"];
	[column setHidden:hidden];
	column = [tableView tableColumnWithIdentifier:@"latent"];
	[column setHidden:hidden];
	column = [tableView tableColumnWithIdentifier:@"profit"];
	[column setHidden:hidden];
	column = [tableView tableColumnWithIdentifier:@"income"];
	[column setHidden:hidden];
	column = [tableViewSum tableColumnWithIdentifier:@"long"];
	[column setHidden:hidden];
	column = [tableViewSum  tableColumnWithIdentifier:@"short"];
	[column setHidden:hidden];
}

-(void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row{
	NSLog(@"willDisplayCell");
	/*
	[cell setTextColor:[NSColor redColor]];
	[cell setBackgroundColor:[NSColor grayColor]];
	[cell setDrawsBackground:YES];
	[cell setFont:[NSFont boldSystemFontOfSize:12]];
	[cell setAlignment:NSRightTextAlignment];
	 */
}

- (void)rearrangeDocument
{
	[self setPortfolioSumArray];
	[tableView reloadData];
	[tableViewSum reloadData];
	[portfolioController rearrangeObjects];
	[portfolioSumController rearrangeObjects];
    if (tableView) {
        [self setTableColumeAttribute:[tableView selectedRow]];        
    }
}

#pragma mark CSV Archiver

- (void)importCSV:(bool)convert
{
	NSOpenPanel *opanel = [NSOpenPanel openPanel];
	int opRet;
	[opanel setAllowedFileTypes: [NSArray arrayWithObjects:@"csv",@"'CSV'",nil]];
    opRet = [opanel runModal];
	if (opRet == NSOKButton){
        NSURL *dataURL = [opanel URL];
		NSLog(@"URL: %@",dataURL);
		[self importPortfolio:[dataURL path]:convert];
		//for (PortfolioItem* item in portfolioArray) {
			//NSLog(@"%@ %@ %@ %@",[item itemName],[item itemCode],[item itemType],[item url]);
			//for (TradeItem* trade in [item trades]) {
			//	NSLog(@"%@ %@",[trade date],[trade kind]);
			//}
		//}
	}else{
		NSLog(@"Cansel");
	}
}

/*
- (void)importCSV:(bool)convert
{
	NSOpenPanel *opanel = [NSOpenPanel openPanel];
	int opRet;
	NSArray *fileTypes = [NSArray arrayWithObjects:@"csv",@"'CSV'",nil];
    opRet = [opanel runModalForDirectory:NSHomeDirectory() file:nil types:fileTypes];
	//[opanel setAllowedFileTypes: [NSArray arrayWithObjects:@"csv",@"'CSV'",nil]];
    //opRet = [opanel runModal];
	if (opRet == NSOKButton){
		NSString *dataPath = [opanel filename];
        // NSURL *dataURL = [opanel URL];
		[self importPortfolio:dataPath:convert];
		//NSLog(@"URL: %@",dataURL);
		//[self importPortfolio:[dataURL path]:convert];
		for (PortfolioItem* item in portfolioArray) {
			NSLog(@"%@ %@ %@ %@",[item itemName],[item itemCode],[item itemType],[item url]);
			for (TradeItem* trade in [item trades]) {
				NSLog(@"%@ %@",[trade date],[trade kind]);
			}
		}
	}else{
		NSLog(@"Cansel");
	}
}
*/

static bool tPrtConvert = NO;

- (void)exportCSV:(bool)convert
{
	NSSavePanel *spanel = [NSSavePanel savePanel];
	tPrtConvert = convert;
	//[spanel setRequiredFileType:@"csv"];
	[spanel setAllowedFileTypes: [NSArray arrayWithObjects: @"csv",@"CSV",nil]];
    /*
	[spanel beginSheetForDirectory:NSHomeDirectory()
							  file:nil
					modalForWindow:[self win]
					 modalDelegate:self
					didEndSelector:@selector(didEndSaveSheet:returnCode:conextInfo:)
					   contextInfo:nil];
     */
    [spanel beginSheetModalForWindow:win
                   completionHandler:^(NSInteger result) {
                       if (result == NSOKButton) {
                           NSString *dataPath = [[spanel URL] path];
                           [self exportPortfolio:dataPath:tPrtConvert];
                       }else{
                           NSLog(@"Cansel");
                       }
                   }
     ];
    //[spanel beginSheetModalForWindow:win completionHandler:@selector(didEndSaveSheet:returnCode:)];
}

/*
- (void)didEndSaveSheet:(NSSavePanel *)savePanel returnCode:(int)returnCode conextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton){
		NSString *dataPath = [[savePanel URL] path];
		[self exportPortfolio:dataPath:tPrtConvert];
	}else{
		NSLog(@"Cansel");
	}
}
*/

static NSString* importPath;

- (void)importSample:(NSString*)path
{
	NSLog(@"importSample: samplePath = %@", path);
	NSBundle*	bundle = [NSBundle mainBundle];
	NSString*	samplePath = [bundle pathForResource:path ofType:@"csv"];
	if (samplePath == nil) {
		return;
	}
	/*
	if ([portfolioArray count] > 0) {
		importPath = [samplePath retain];
		NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"OK",@"Ok")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:NSLocalizedString(@"CANCEL",@"Cancel")
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"ITEM_EXIST",@"Items are already exist in portfolio.\nDo you import data ?")];
		[alert beginSheetModalForWindow:[self win]
						  modalDelegate:self
						 didEndSelector:@selector(alertEndedSample:code:context:) contextInfo:nil];
		return;
	}
	*/
	[self importPortfolio:samplePath:NO];
}

- (void)alertEndedSample:(NSAlert*)alert
					code:(int)choice
				 context:(void*)path
{
	NSLog(@"alertEndedSample");
	if (choice == NSAlertDefaultReturn && importPath != nil) {
		//NSBundle*	bundle = [NSBundle mainBundle];
		// NSString*   p = path;
		// NSLog(@"p=%@",p);
		//NSString*	samplePath = [bundle pathForResource:path ofType:@"csv"];
		//if (samplePath == nil) {
		//	return;
		//}
		[self importPortfolio:importPath:NO];
	}
	if (importPath) {
		[importPath release];
		importPath = nil;
	}
}

- (void)exportPortfolio:(NSString *)path :(bool)convert
{
	NSLog(@"exportPortfolio: %@", path);
	NSMutableString* textContent = [[NSMutableString alloc] init];
	NSDateFormatter	*dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%Y/%m/%d" allowNaturalLanguage:NO];

	NSString* lang = NSLocalizedString(@"LANG",@"English");
	NSLog(@"localizeView: %@", lang);
	if ([lang isEqualToString:@"Japanese"]) {
		[textContent appendString:@"銘柄情報,銘柄名,銘柄コード,国名コード,種別,取引値\r\n"];
		[textContent appendString:@"取引日,単価,購入数,売却数,手数料,配当･分配,税,コメント\r\n"];
	} else {
		[textContent appendString:@"Item,Name,Code,Country,Type,Price\r\n"];
		[textContent appendString:@"Date,Price,Bought,Sold,Charge,Dividend,Tax,Comment\r\n"];
	}		
	for (PortfolioItem *item in portfolioArray) {
		if ([item url] == nil) {
			[textContent appendFormat:@"DEFINE,%@,%@,%@,%@,%0.4f,\r\n",
			 [[item itemName] stringByReplacingOccurrencesOfString:@"," withString:@""],
			 [item itemCode],[item country],[item itemType],[item price]];
		} else {
			[textContent appendFormat:@"DEFINE,%@,%@,%@,%@,%0.4f,%@\r\n",
			 [[item itemName] stringByReplacingOccurrencesOfString:@"," withString:@""],
			 [item itemCode],[item country],[item itemType],[item price],[item url]];
		}
		/*
		if ([item url] == nil) {
			[textContent appendFormat:@"DEFINE,%@,%@,%@,%@,%.2f,\r\n",
			 [[item itemName] stringByReplacingOccurrencesOfString:@"," withString:@""],
			 [item itemCode],[item country],[item itemType],[item price]];
		} else {
			[textContent appendFormat:@"DEFINE,%@,%@,%@,%@,%.2f,%@\r\n",
			 [[item itemName] stringByReplacingOccurrencesOfString:@"," withString:@""],
			 [item itemCode],[item country],[item itemType],[item price],[item url]];
		}
		*/
		NSEnumerator*	enumerator;
		if ([item order] == TRADE_ITEM_ORDER_ASCENDING) {
			enumerator = [[item trades] objectEnumerator];
		} else {
			enumerator = [[item trades] reverseObjectEnumerator];
		}
		for (TradeItem *trade in enumerator) {
			NSString *dateString = [dateFormatter stringFromDate:[trade date]];
			NSLog(@"%@",dateString);
			if (([trade buy] > 0 || [trade sell] > 0) && [trade settlement] == 0 && [trade dividend] == 0) {
				[textContent appendFormat:@"%@,%0.4f*,%.4f,%.4f,%.2f,%.2f,%.2f,%@\r\n",
				 dateString,[trade price],[trade buy],[trade sell],
				 [trade charge],[trade dividend],[trade tax],[trade comment]];
			} else {
				[textContent appendFormat:@"%@,%0.4f,%.4f,%.4f,%.2f,%.2f,%.2f,%@\r\n",
				 dateString,[trade price],[trade buy],[trade sell],
				 [trade charge],[trade dividend],[trade tax],[trade comment]];
			}
			/*
			if (([trade buy] > 0 || [trade sell] > 0) && [trade settlement] == 0) {
				[textContent appendFormat:@"%@,%.2f*,%.4f,%.4f,%.2f,%.2f,%.2f,%@\r\n",
				 dateString,[trade price],[trade buy],[trade sell],
				 [trade charge],[trade dividend],[trade tax],[trade comment]];
			} else {
				[textContent appendFormat:@"%@,%.2f,%.4f,%.4f,%.2f,%.2f,%.2f,%@\r\n",
				 dateString,[trade price],[trade buy],[trade sell],
				 [trade charge],[trade dividend],[trade tax],[trade comment]];
			}
			*/
		}
	}
	NSLog(@"\r\n%@", textContent);
	if (convert == YES) {
		[self writeSJisText:path:textContent];
	} else {
		[textContent writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil];
	}
	[textContent release];
	[dateFormatter release];
}

- (void)importPortfolio:(NSString *)path :(bool)convert
{
	NSLog(@"importPortfolio: %@", path);
	int	line = 0;
	int	column = 0;
	int count = 0;
	int length;
	NSRange range, subrange;
    NSString* parsedLine;
	NSArray* splits;
	NSDateFormatter	*dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%Y/%m/%d" allowNaturalLanguage:NO];
	PortfolioItem* item = nil;
	NSString* textContent;
	if (convert == YES) {
		textContent = [self readSJisText:path];
	} else {
		textContent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
	}
	// NSLog(@"\r\n%@", textContent);
	if (textContent == nil) {
		NSLog(@"failed to import CVS: %@", path);
		NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"IMPORT_FAILED",@"Failed to import CSV: %@"),path];
		[alert beginSheetModalForWindow:win modalDelegate:self didEndSelector:nil contextInfo:nil];
		[dateFormatter release];
		return;
	}

	[textContent retain];
	length = [textContent length];
	range = NSMakeRange(0, length);
	while(range.length > 0) {
		subrange = [textContent lineRangeForRange:NSMakeRange(range.location,0)];
		parsedLine = [textContent substringWithRange:subrange];
		range.location = NSMaxRange(subrange);
		range.length -= subrange.length;
		NSLog(@"%@",parsedLine);
		line++;
		column = 0;
		splits = [parsedLine componentsSeparatedByString:@","];
		//for (NSString* split in splits) {
		//	NSLog(@"%@",split);
		//}
		int limit = [splits count];
		NSString* split = [splits objectAtIndex:column];
		if ([split isEqualToString:@"DEFINE"] && limit >= 6) {
            if (item) {
                [portfolioController addObject:item];
                [item release];
                item = nil;
            }
            // Add Item
            NSString *name = nil;
            NSString *code = nil;
            NSString *country = nil;
			column++;	// 1
            item = [portfolioController newObject];
            name = [splits objectAtIndex:column];
            // NSLog(@"name: %@",name);
			[item setItemName:name];
			column++;	// 2
            code = [splits objectAtIndex:column];
            // NSLog(@"code: %@",code);
			[item setItemCode:code]; 
			column++;	// 3
			if (limit < 7) {
				[item setCountry:@"JP"];
			} else {
                country = [splits objectAtIndex:column];
                NSLog(@"country: %@",country);
				[item setCountry:country];
				column++;	// 4
			}
			NSString *itemTypeStr = [splits objectAtIndex:column]; 
            // NSLog(@"value: %@",itemTypeStr);
			[item setType:[item itemTypeToType:itemTypeStr]];
			[item setItemType:[item localizedItemType:[item type]]];
			[item setUnit:1];
			[item setCredit:TRADE_TYPE_REALBUY];
			if ([item type] == ITEM_TYPE_FUND_10000) {
				[item setUnit:10000];
			} else if ([item type] == ITEM_TYPE_STOCK_BUY ||
					   [item type] == ITEM_TYPE_ETF_BUY ||
					   [item type] == ITEM_TYPE_CURRENCY_BUY) {
				[item setCredit:TRADE_TYPE_LONGBUY];
			} else if ([item type] == ITEM_TYPE_STOCK_SELL ||
					   [item type] == ITEM_TYPE_ETF_SELL ||
					   [item type] == ITEM_TYPE_CURRENCY_SELL) {
				[item setCredit:TRADE_TYPE_SHORTSELL];
			}
			column++;	// 5
			[item setPrice:[[splits objectAtIndex:column] floatValue]];
			column++;	// 6
			NSString* urlString = [splits objectAtIndex:column];
            // NSLog(@"urlString: %@",urlString);
			if ([urlString hasSuffix:@"\r\n"]) {
				[item setUrl:[urlString substringToIndex:[urlString length]-2]];
			} else if ([urlString hasSuffix:@"\r"] || [urlString hasSuffix:@"\n"]) {
				[item setUrl:[urlString substringToIndex:[urlString length]-1]];					
			} else {
				[item setUrl:urlString];
			}
			count++;	// 7
		} else if ([split isEqualToString:@"PROFILE"]) {
			continue;
		} else if ([split isEqualToString:@"BOOKMARK"]) {
			continue;
		} else {
            // Add Trade
			if (item == nil || [splits count] < 7) {
				continue;
			}
			bool is_split = NO;
			TradeItem* trade = [[TradeItem alloc] init];
			// 日付取得
			[trade setDate:[dateFormatter dateFromString:split]];
			column++;
			// 価格取得
			NSString* value = [splits objectAtIndex:column];
			if ([value hasSuffix:@"*"]) {
				is_split = YES;
				[trade setPrice:[[value substringToIndex:[value length]-1] floatValue]];					
			} else {
				[trade setPrice:[value floatValue]];
			}
			column++;
			// 買付数量取得
			[trade setBuy:[[splits objectAtIndex:column] floatValue]];
			column++;
			// 売付数量取得
			[trade setSell:[[splits objectAtIndex:column] floatValue]];
			column++;
			// 手数料取得
			[trade setCharge:[[splits objectAtIndex:column] floatValue]];
			column++;
			// 配当・分配取得
			[trade setDividend:[[splits objectAtIndex:column] floatValue]];
			column++;
			// 税金取得
			[trade setTax:[[splits objectAtIndex:column] floatValue]];
			column++;
			// コメント取得
			if ([splits count] > 7) {
                [trade setComment:[splits objectAtIndex:column]];
                if ([[trade comment] isEqualToString:@"\r\n"] == YES ||
                    [[trade comment] isEqualToString:@"\n"] == YES) {
                    [trade setComment:@""];
                }
			} else {
				[trade setComment:@""];
			}
			// 取引額計算
			if ([trade buy] > 0) {
				// 買い
				if ([trade dividend] == 0) {
					[trade setKind:NSLocalizedString(@"BUY",@"Buy")];
					[trade setSettlement:round([trade buy]*[trade price]/[item unit])+[trade tax]+[trade charge]];
				} else {
					[trade setKind:NSLocalizedString(@"REINVESTMENT",@"Reinvestment")];
					[trade setSettlement:[trade dividend]+[trade tax]+[trade charge]];
				}
			} else if ([trade sell] > 0) {
				// 売り
				[trade setKind:NSLocalizedString(@"SELL",@"Sell")];
				[trade setSettlement:round([trade sell]*[trade price]/[item unit])+[trade tax]-[trade charge]];
			} else if ([trade dividend] > 0) {
				// 配当・分配
				[trade setKind:NSLocalizedString(@"DIVIDEND",@"Dividend")];
				[trade setSettlement:[trade dividend]-[trade tax]];
			} else {
				[trade setSettlement:0];
				[trade setKind:NSLocalizedString(@"NOTE",@"Note")];
				// [trade setKind:NSLocalizedString(@"EVALUATE",@"Evaluate")];
			}
			if (is_split == true) {
				// 分割
				[trade setKind:NSLocalizedString(@"SPLIT",@"Split")];
				[trade setSettlement:[trade tax]+[trade charge]];
			}
			// NSLog(@"%@,%f,%f,%f",[trade date],[trade price],[trade buy],[trade sell]);
			[item Add:trade];
			[trade release];
		}
	}
    if (item) {
        [portfolioController addObject:item];
        [portfolioController rearrangeObjects];
        [item release];
        item = nil;
    }
	[textContent release];
	[dateFormatter release];

	int i = 1;
	for (PortfolioItem *item in portfolioArray) {
		[item setIndex:i++];
		[item DoSettlement];
	}
	[self allocatePortfolioSumArray];
	[self setPortfolioSumArray];
	[self rearrangeDocument];
	NSLog(@"%d items imported from CVS: %@", count, path);
	NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"INFO",@"Info")
									 defaultButton:NSLocalizedString(@"OK",@"Ok")
								   alternateButton:nil
									   otherButton:nil
						 informativeTextWithFormat:NSLocalizedString(@"IMPORT_SUCCESS",@"%d items imported from CSV:\n%@"), count, path];
	[alert beginSheetModalForWindow:win modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (NSString*)readSJisText:(NSString*)path
{
	NSLog(@"readSJisText:%@",path);
	NSData* sjisData = [NSData dataWithContentsOfFile:path];
	NSString* textContent = [[NSString alloc] initWithData:sjisData encoding:NSShiftJISStringEncoding];
	if (textContent == nil) {
		NSLog(@"failed to convert sjis to utf8.");
		return nil;
	}
	[textContent autorelease];
	return textContent;
}

- (void)writeSJisText:(NSString*)path :(NSString*)textContent
{
	NSLog(@"writeSJisText:%@",path);
	NSData* sjisData = [textContent dataUsingEncoding:NSShiftJISStringEncoding allowLossyConversion:YES];
	if (sjisData == nil) {
		NSLog(@"failed to convert utf8 to sjis.");
		return;
	}
	[sjisData writeToFile:path atomically:YES];
}

- (void) initHistory
{
	NSLog(@"initHistory");
	NSArray *selectde = [portfolioController selectedObjects];
	NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"DELETE",@"Delete")
									 defaultButton:NSLocalizedString(@"CANCEL",@"Cancel")
								   alternateButton:NSLocalizedString(@"DELETE",@"Delete")
									   otherButton:nil
						 informativeTextWithFormat:NSLocalizedString(@"SURE_INIT",@"Do you want to delete trade history ？\nYou can't restore them after delete."), [selectde count]];
	NSLog(@"Stating alert sheet");
	[alert beginSheetModalForWindow:[tableView window]
					  modalDelegate:self
					 didEndSelector:@selector(alertEndedInitHistory:code:context:) contextInfo:NULL];
	[self allocatePortfolioSumArray];
}

- (void)alertEndedInitHistory:(NSAlert*)alert
					code:(int)choice
				 context:(void*)v
{
	NSLog(@"Alert sheet ended");
	if (choice == NSAlertAlternateReturn) {
		NSLog(@"Remove all trade history");
		int row = [tableView selectedRow];
		if (row == -1) {
			for (PortfolioItem* item in portfolioArray) {
				[item Clear];
				[item DoSettlement];
			}
		} else {
			PortfolioItem *item = [portfolioArray objectAtIndex:row];
			if (item) {
				[item Clear];
				[item DoSettlement];
			}
		}
		[self rearrangeDocument];
		[self setPortfolioEdited];
	}
}

- (void)buildCountyList
{
	[countryComboBox removeAllItems];
	if (customCountry == YES &&
		[customCountryCode length] == 2 &&
		[customCurrencyCode length] == 3) {
		[countryComboBox addItemWithObjectValue:customCountryCode];
	}
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_AE];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_AT];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_AR];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_AU];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_BE];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_BR];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_CA];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_CH];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_CN];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_DE];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_DK];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_EG];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_ES];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_EU];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_FI];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_FR];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_GR];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_HK];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_ID];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_IN];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_IT];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_JP];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_KR];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_LU];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_MX];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_MY];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_NL];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_NO];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_NZ];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_PH];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_PT];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_RU];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_SA];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_SE];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_SG];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_TH];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_TR];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_TW];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_UK];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_US];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_VN];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_ZA];
}

- (void)setFontColor:(NSColor*)color
{
	NSTableColumn *column = nil;
	NSLog(@"setFontColor");
    [tanukiBelly setTextColor:color];

	// set font color of tableView
	column = [tableView  tableColumnWithIdentifier:@"index"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"item"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"code"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"country"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"kind"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"url"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"price"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"average"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"quantity"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"performance"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"estimate"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"investment"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"latent"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"profit"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"income"];
	[(id)[column dataCell] setTextColor:color];
	[tableView reloadData];
	
	// set font color of tableViewSun
	column = [tableViewSum  tableColumnWithIdentifier:@"country"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableViewSum  tableColumnWithIdentifier:@"currency"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableViewSum  tableColumnWithIdentifier:@"performance"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableViewSum  tableColumnWithIdentifier:@"invested"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableViewSum  tableColumnWithIdentifier:@"estimated"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableViewSum  tableColumnWithIdentifier:@"long"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableViewSum  tableColumnWithIdentifier:@"short"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableViewSum  tableColumnWithIdentifier:@"latent"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableViewSum  tableColumnWithIdentifier:@"capital"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableViewSum  tableColumnWithIdentifier:@"income"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableViewSum  tableColumnWithIdentifier:@"balance"];
	[(id)[column dataCell] setTextColor:color];
    column = [tableViewSum  tableColumnWithIdentifier:@"cash"];
    [(id)[column dataCell] setTextColor:color];
	[tableViewSum reloadData];
}

#pragma mark Localizer

- (void) localizeView
{
	NSTableColumn *column = nil;
	NSString* lang = NSLocalizedString(@"LANG",@"English");
	NSLog(@"localizeView: %@", lang);
	if ([lang isEqualToString:@"Japanese"]) {
		[addButton setTitle:@"追加"];
		[deleteButton setTitle:@"削除"];
		[checkoutButton setTitle:@"計算する"];
		[checkDetail setTitle:@"詳細表示"];
		[sortButton removeAllItems];
		[sortButton addItemWithTitle:@"銘柄でソート"];
		[sortButton addItemWithTitle:@"証券コードでソート"];
		[sortButton addItemWithTitle:@"国名コードでソート"];
		[sortButton addItemWithTitle:@"種別でソート"];
		[sortButton addItemWithTitle:@"騰落率でソート"];
		[sortButton addItemWithTitle:@"評価額でソート"];
		[sortButton addItemWithTitle:@"投資額でソート"];
		[sortButton addItemWithTitle:@"含み益でソート"];
		[sortButton addItemWithTitle:@"譲渡益でソート"];
		[sortButton addItemWithTitle:@"配当益でソート"];
		[comboBoxItem removeAllItems];
		[comboBoxItem addItemWithObjectValue:@"株式(現物)"];
		[comboBoxItem addItemWithObjectValue:@"株式(買建)"];
		[comboBoxItem addItemWithObjectValue:@"株式(売建)"];
		[comboBoxItem addItemWithObjectValue:@"ETF(現物)"];
		[comboBoxItem addItemWithObjectValue:@"ETF(買建)"];
		[comboBoxItem addItemWithObjectValue:@"ETF(売建)"];
		[comboBoxItem addItemWithObjectValue:@"投信"];
		[comboBoxItem addItemWithObjectValue:@"投信(1万口)"];
		[comboBoxItem addItemWithObjectValue:@"外貨"];
		[comboBoxItem addItemWithObjectValue:@"FX(買建)"];
		[comboBoxItem addItemWithObjectValue:@"FX(売建)"];
		[comboBoxItem addItemWithObjectValue:@"現金"];
		[comboBoxItem addItemWithObjectValue:@"指数"];
		[comboBoxItem addItemWithObjectValue:@"その他"];
		[comboBoxBookmark removeAllItems];
        //[comboBoxBookmark setTitleWithMnemonic:@"ブックマーク"];
        [comboBoxBookmark selectItemWithObjectValue:@"ブックマーク"];
		[comboBoxBookmark addItemWithObjectValue:@"ブックマークを追加する (50件まで)"];
		column = [tableView  tableColumnWithIdentifier:@"item"];
		[[column headerCell] setStringValue:@"銘柄"];
		column = [tableView  tableColumnWithIdentifier:@"code"];
		[[column headerCell] setStringValue:@"証券コード"];
		column = [tableView  tableColumnWithIdentifier:@"country"];
		[[column headerCell] setStringValue:@"国名コード"];
		column = [tableView  tableColumnWithIdentifier:@"kind"];
		[[column headerCell] setStringValue:@"種別"];
		column = [tableView  tableColumnWithIdentifier:@"url"];
		[[column headerCell] setStringValue:@"IRサイト"];
		column = [tableView  tableColumnWithIdentifier:@"price"];
		[[column headerCell] setStringValue:@"価格"];
		column = [tableView  tableColumnWithIdentifier:@"average"];
		[[column headerCell] setStringValue:@"平均単価"];
		column = [tableView  tableColumnWithIdentifier:@"quantity"];
		[[column headerCell] setStringValue:@"保有数"];
		column = [tableView  tableColumnWithIdentifier:@"performance"];
		[[column headerCell] setStringValue:@"騰落率"];
		column = [tableView  tableColumnWithIdentifier:@"estimate"];
		[[column headerCell] setStringValue:@"評価額"];
		column = [tableView  tableColumnWithIdentifier:@"investment"];
		[[column headerCell] setStringValue:@"投資額"];
		column = [tableView  tableColumnWithIdentifier:@"latent"];
		[[column headerCell] setStringValue:@"含み益"];
		column = [tableView  tableColumnWithIdentifier:@"profit"];
		[[column headerCell] setStringValue:@"譲渡益"];
		column = [tableView  tableColumnWithIdentifier:@"income"];
		[[column headerCell] setStringValue:@"配当益"];
		column = [tableViewSum  tableColumnWithIdentifier:@"country"];
		[[column headerCell] setStringValue:@"国・地域"];
		column = [tableViewSum  tableColumnWithIdentifier:@"currency"];
		[[column headerCell] setStringValue:@"通貨"];
		column = [tableViewSum  tableColumnWithIdentifier:@"performance"];
		[[column headerCell] setStringValue:@"騰落率"];
		column = [tableViewSum  tableColumnWithIdentifier:@"invested"];
		[[column headerCell] setStringValue:@"投資額"];
		column = [tableViewSum  tableColumnWithIdentifier:@"estimated"];
		[[column headerCell] setStringValue:@"評価額"];
		column = [tableViewSum  tableColumnWithIdentifier:@"cash"];
		[[column headerCell] setStringValue:@"現金"];
		column = [tableViewSum  tableColumnWithIdentifier:@"long"];
		[[column headerCell] setStringValue:@"買建額"];
		column = [tableViewSum  tableColumnWithIdentifier:@"short"];
		[[column headerCell] setStringValue:@"売建額"];
		column = [tableViewSum  tableColumnWithIdentifier:@"latent"];
		[[column headerCell] setStringValue:@"含み益"];
		column = [tableViewSum  tableColumnWithIdentifier:@"capital"];
		[[column headerCell] setStringValue:@"譲渡益"];
		column = [tableViewSum  tableColumnWithIdentifier:@"income"];
		[[column headerCell] setStringValue:@"配当益"];
		column = [tableViewSum  tableColumnWithIdentifier:@"balance"];
		[[column headerCell] setStringValue:@"収支"];
        [performanceOk setTitle:NSLocalizedString(@"DO",@"Do")];
        [performanceCancel setTitle:NSLocalizedString(@"CANCEL",@"Cancel")];
        [performanceLabel setStringValue:@"期間の選択"];
        [portfolioItemOk setTitle:NSLocalizedString(@"OK",@"Ok")];
        [portfolioItemCancel setTitle:NSLocalizedString(@"CANCEL",@"Cancel")];
        [portfolioItemCountryLabel setStringValue:@"国/地域"];
        [portfolioItemTypeLabel setStringValue:@"種別:"];
        [portfolioItemCodeLabel setStringValue:@"証券コード:"];
        [portfolioItemNameLabel setStringValue:@"銘柄名:"];
        [portfolioItemSiteLabel setStringValue:@"IRサイト:"];
        [portfolioItemNoteLabel setStringValue:@"メモ:"];
	}
    [portfolioItemTypeBox removeAllItems];
    [portfolioItemTypeBox addItemWithObjectValue:NSLocalizedString(@"STOCK",@"Stock:actual")];
    [portfolioItemTypeBox addItemWithObjectValue:NSLocalizedString(@"STOCK_BUY",@"Stock:long")];
    [portfolioItemTypeBox addItemWithObjectValue:NSLocalizedString(@"STOCK_SELL",@"Stock:short")];
    [portfolioItemTypeBox addItemWithObjectValue:NSLocalizedString(@"ETF",@"ETF:actual")];
    [portfolioItemTypeBox addItemWithObjectValue:NSLocalizedString(@"ETF_BUY",@"ETF:long")];
    [portfolioItemTypeBox addItemWithObjectValue:NSLocalizedString(@"ETF_SELL",@"ETF:short")];
    [portfolioItemTypeBox addItemWithObjectValue:NSLocalizedString(@"FUND",@"Fund")];
    [portfolioItemTypeBox addItemWithObjectValue:NSLocalizedString(@"FUND_10000",@"Fund:10000unit")];
    [portfolioItemTypeBox addItemWithObjectValue:NSLocalizedString(@"CURRENCY",@"Currency")];
    [portfolioItemTypeBox addItemWithObjectValue:NSLocalizedString(@"CURRENCY_BUY",@"FX:long")];
    [portfolioItemTypeBox addItemWithObjectValue:NSLocalizedString(@"CURRENCY_SEL",@"FX:short")];
    [portfolioItemTypeBox addItemWithObjectValue:NSLocalizedString(@"CASH",@"Cash")];
    [portfolioItemTypeBox addItemWithObjectValue:NSLocalizedString(@"INDEX",@"Index")];
    [portfolioItemTypeBox addItemWithObjectValue:NSLocalizedString(@"OTHER",@"Other")];
    [portfolioItemTypeBox setStringValue:NSLocalizedString(@"STOCK",@"Stock:actual")];
}

/*
- (void)mouseDown:(NSEvent*)event
{
	NSLog(@"mouseDown:%ld", (long)[event clickCount]);
}

- (void)mouseDragged:(NSEvent*)event
{
	NSPoint	p = [event locationInWindow];
	NSLog(@"mouseDragged:%@", NSStringFromPoint(p));
}
*/

@synthesize		subDocument;
@synthesize		cashAccount;
@synthesize		iPanel;
@synthesize		webReader;
@synthesize     reader;
@synthesize		currentItem;
@synthesize		cashItem;
@synthesize		progressWebView;
@synthesize		progressConnection;
@synthesize     speechingPortfolio;
@synthesize     speechIndex;

@synthesize		portfolioArray;
@synthesize		bookmarks;
@synthesize		portfolioSumArray;
@synthesize		urlField;
@synthesize		webTitle;
@synthesize		tanukiBelly;
@synthesize		win;
@synthesize		webView;
@synthesize		tableView;
@synthesize		tableViewSum;
@synthesize		goBack;
@synthesize		goForward;
@synthesize		goToIR;
@synthesize		goToPortal;
@synthesize		goToYahoo;
@synthesize		refreshPrice;
@synthesize		datePicker;
@synthesize		progress;
@synthesize		extended;
@end
