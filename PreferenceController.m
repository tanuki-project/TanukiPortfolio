//
//  PreferenceController.m
//  tPortfolio
//
//  Created by Takahiro Sayama on 10/12/05.
//  Copyright 2011 tanuki-project. All rights reserved.
//

#import		"PreferenceController.h"
#import     "MyDocument.h"
#include	"Bookmark.h"
#include	"PortfolioItem.h"
#include	"AppController.h"

extern double       speechSpeed;

@interface PreferenceController ()
- (void)startObservingBookmark:(Bookmark *)item;
- (void)stopObservingBookmark:(Bookmark *)item;
@end

NSString* const tPrtTableBgColorKey =           @"Table Background Color";
NSString* const tPrtTableFontColorKey =         @"Table Font Color";
NSString* const tPrtCountryKey =                @"Default Country Code";
NSString* const tPrtEmptyDocKey =               @"Empty Document Flag";
NSString* const tPrtAutoSaveKey =               @"Enable Auto Save Flag";
NSString* const tPrtTradeOrderKey =             @"Trade Item Order Flag";
NSString* const tPrtEnableDataSheetKey =        @"Enable Data Input Sheet";
NSString* const tPrtSeparateCashKey =           @"Separate Cash Flag";
NSString* const tPrtAutoUpdateKey =             @"Price Auto Update Flag";
NSString* const tPrtSortInfoPanelKey =          @"Sort Information Panel Flag";

NSString* const tPrtCustomCountryKey =          @"Custom Country Flag";
NSString* const tPrtCustomCountryCodeKey =      @"Custom Country Code";
NSString* const tPrtCustomCountryNameKey =      @"Custom Country Name";
NSString* const tPrtCustomCurrencyCodeKey =     @"Custom Currency Code";
NSString* const tPrtCustomCurrencyNameKey =     @"Custom Currency Name";
NSString* const tPrtCustomCurrencySymbolKey =   @"Custom Currency Symbol";
NSString* const tPrtFaveriteKanjiKey =          @"Faverite Kanji";

bool			customCountry = NO;
bool			separateCash = YES;
NSString*		customCountryCode = nil;
NSString*		customCountryName = nil;
NSString*		customCurrencyCode = nil;
NSString*		customCurrencyName = nil;
NSString*		customCurrencySymbol = nil;

NSString* const tPrtColorChangedNotification =      @"tPrtColorChanged";
NSString* const tPrtBookmarkChangedNotification =   @"tPrtBookmarkChanged";
NSString* const tPrtFeedChangedNotification =       @"tPrtFeedChanged";
//NSString* const tPrtShowTextChangedNotification = @"tPrtShowTextChanged";

NSString* const tPrtHomeUrlKey =            @"Home WebView URL";
NSString* const tPrtLastUrlKey =            @"Last WebView URL";
NSString* const tPrtBookmarkListKey =       @"Bookmark List";
NSString* const tPrtFeedListKey =           @"Feed List";
NSString* const tPrtLastFeedKey =           @"Last Feed URL";
NSString* const tPrtPortfolioDetailKey =    @"Portfolio Detail Flag";
NSString* const tPrtTradeDetailKey =        @"Trade Detail Flag";
NSString* const tPrtEnableRedirectKey =     @"Enable Redirect";

bool            autosaveInPlace = NO;
bool            openUntitled = NO;
bool            enableRedirect = NO;
bool            enableDataInputSheet = YES;

extern AppController	*tPrtController;

@implementation PreferenceController

- (id)init
{
	NSLog(@"init Preference");
    self = [super initWithWindowNibName:@"Preferences"];
	if (self == nil) {
		return nil;
	}
	// bookmarks = [[NSMutableArray alloc] init];
	bookmarks = nil;
	feeds = nil;
	bookmarksModified = NO;
	feedsModified = NO;
	[saveButton setEnabled:NO];
	[cancelButton setEnabled:NO];
	[saveFeedButton setEnabled:NO];
	[cancelFeedButton setEnabled:NO];
	return self;
}

- (void)dealloc
{
	[self setBookmarks:nil];
	[self setFeeds:nil];
	[super dealloc];
}

- (void)startObservingBookmark:(Bookmark*)item
{
	// NSLog(@"startObservingBookmark: %@", item);
	[item addObserver:self
		   forKeyPath:@"title"
			  options:NSKeyValueObservingOptionOld
			  context:NULL];
	[item addObserver:self
		   forKeyPath:@"url"
			  options:NSKeyValueObservingOptionOld
			  context:NULL];
}

- (void)stopObservingBookmark:(Bookmark*)item
{
	// NSLog(@"stopObservingBookmark: %@", item);
	[item removeObserver:self forKeyPath:@"title"];
	[item removeObserver:self forKeyPath:@"url"];
}

- (void)changeKeyPath:(NSString*)keyPath
			 obObject:(id)obj
			  toValue:(id)newValue
{
	NSLog(@"changeKeyPath: %@", keyPath);
}

- (void)observeValueForKeyPath:(NSString*)keyPath
					  ofObject:(id)object
						change:(NSDictionary*)change
					   context:(void*)context
{
	NSLog(@"observeValueForKeyPath: %@", keyPath);
    NSLog(@"%@",[[PreferenceTab selectedTabViewItem] label]);
    if ([[[PreferenceTab selectedTabViewItem] label] isEqualToString:@"Bookmarks"] == YES) {
        bookmarksModified = YES;
        [saveButton setEnabled:YES];
        [cancelButton setEnabled:YES];
    } else if ([[[PreferenceTab selectedTabViewItem] label] isEqualToString:@"RSS Feeds"] == YES) {
        feedsModified = YES;
        [saveFeedButton setEnabled:YES];
        [cancelFeedButton setEnabled:YES];
    }
}

- (NSColor*)tableBgColor
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *colorAsData = [defaults objectForKey:tPrtTableBgColorKey];
	return [NSKeyedUnarchiver unarchiveObjectWithData:colorAsData];
}

- (NSColor*)tableFontColor
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *colorAsData = [defaults objectForKey:tPrtTableFontColorKey];
	return [NSKeyedUnarchiver unarchiveObjectWithData:colorAsData];
}

- (BOOL)emptyDoc
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults boolForKey:tPrtEmptyDocKey];
}

- (BOOL)autoSave
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults boolForKey:tPrtAutoSaveKey];
}

- (BOOL)tradeOrder
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults boolForKey:tPrtTradeOrderKey];
}

- (BOOL)separateCash
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults boolForKey:tPrtSeparateCashKey];
}

- (BOOL)autoUpdate
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults boolForKey:tPrtAutoUpdateKey];
}

- (BOOL)sortInfoPanel
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults boolForKey:tPrtSortInfoPanelKey];
}

- (BOOL)enableDataInputSheet
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:tPrtEnableDataSheetKey];
}

- (NSString*)countryCode
{
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
	return defaultCountry;
}

- (NSString*)homeUrl
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* home = [defaults objectForKey:tPrtHomeUrlKey];
	if (home == nil) {
		home = @"";
	}
	return home;
}

- (NSString*)faveriteKanji
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* kanji = [defaults objectForKey:tPrtFaveriteKanjiKey];
	if (kanji == nil) {
		kanji = @"";
	}
	return kanji;
}

- (void)windowDidLoad
{
	NSLog(@"Nib file is loaded");
	[self localizeView];
	[colorWell setColor:[self tableBgColor]];
	[fontColorWell setColor:[self tableFontColor]];
	[self buildCountyList];
	[countryComboBox setStringValue:[self countryCode]];
	[self setCountryFlag];
	[urlField setStringValue:[self homeUrl]];
    [tanukiBellyForm setStringValue:[self faveriteKanji]];
	[checkboxNewDoc setState:[self emptyDoc]];
	[checkboxAutoSave setState:[self autoSave]];
	[checkboxOrder setState:[self tradeOrder]];
    [checkboxEnableDataSheet setState:[self enableDataInputSheet]];
	[checkboxSeparateCash setState:separateCash];
	[checkboxAutoUpdate setState:[self autoUpdate]];
	[checkboxRedirect setState:enableRedirect];
	[checkboxSortInfoPanel setState:[self sortInfoPanel]];
	[bookmarkController rearrangeObjects];
	[checkboxCountry setState:customCountry];
	[countryCodeForm setEnabled:customCountry];
	[countryNameForm setEnabled:customCountry];
	[currencyCodeForm setEnabled:customCountry];
	[currencyNameForm setEnabled:customCountry];
	[currencySymbolForm setEnabled:customCountry];
	if (customCountry == YES) {
		[countryCodeForm setStringValue:customCountryCode];
		[countryNameForm  setStringValue:customCountryName];
		[currencyCodeForm  setStringValue:customCurrencyCode];
		[currencyNameForm  setStringValue:customCurrencyName];
		[currencySymbolForm setStringValue:customCurrencySymbol];
	}
    [checkboxNewDoc setEnabled:openUntitled];
    [checkboxAutoSave setEnabled:autosaveInPlace];
}

- (IBAction)changeBackgroundColor:(id)sender
{
	NSColor *color = [colorWell color];
	NSLog(@"Bg color changed: %@", color);
	NSData *colorAsData = [NSKeyedArchiver archivedDataWithRootObject:color];
	[[NSUserDefaults standardUserDefaults] setObject:colorAsData forKey:tPrtTableBgColorKey];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSLog(@"Sending Notification");
	NSDictionary *d = [NSDictionary dictionaryWithObject:color
												  forKey:@"color"];
	[nc postNotificationName:tPrtColorChangedNotification object:self userInfo:d];
}

- (IBAction)changeFontColor:(id)sender
{
	NSColor *color = [fontColorWell color];
	NSLog(@"Font color changed: %@", color);
	NSData *colorAsData = [NSKeyedArchiver archivedDataWithRootObject:color];
	[[NSUserDefaults standardUserDefaults] setObject:colorAsData forKey:tPrtTableFontColorKey];
	[self changeBackgroundColor:sender];
}

- (IBAction)changeNewEmptyDoc:(id)sender
{
	int state = [checkboxNewDoc state];
	NSLog(@"Checkbox new empty doc changed %d", state);
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:state forKey:tPrtEmptyDocKey];
}

- (IBAction)changeAutoSave:(id)sender
{
	int state = [checkboxAutoSave state];
	NSLog(@"Checkbox enable auto save %d", state);
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:state forKey:tPrtAutoSaveKey];
}

- (IBAction)changeTradeOrder:(id)sender
{
	int state = [checkboxOrder state];
	NSLog(@"Checkbox trade order changed %d", state);
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:state forKey:tPrtTradeOrderKey];
}
- (IBAction)changeEnableDataSheet:(id)sender
{
    int state = [checkboxEnableDataSheet state];
    NSLog(@"Checkbox Enable Data Sheet %d", state);
    enableDataInputSheet = state;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:state forKey:tPrtEnableDataSheetKey];
}

- (IBAction)changeSeparateCash:(id)sender
{
	int state = [checkboxSeparateCash state];
	NSLog(@"Checkbox separate cash changed %d", state);
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:state forKey:tPrtSeparateCashKey];
    separateCash = state;
}

- (IBAction)changeAutoUpdate:(id)sender
{
	int state = [checkboxAutoUpdate state];
	NSLog(@"Checkbox auto update changed %d", state);
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:state forKey:tPrtAutoUpdateKey];
}

- (IBAction)changeRedirect:(id)sender
{
	int state = [checkboxRedirect state];
	NSLog(@"Checkbox redirect changed %d", state);
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:state forKey:tPrtEnableRedirectKey];
    enableRedirect = state;
}

- (IBAction)changeSortInfoPanel:(id)sender
{
	int state = [checkboxSortInfoPanel state];
	NSLog(@"Checkbox show text changed %d", state);
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:state forKey:tPrtSortInfoPanelKey];
}

- (IBAction)selectCountry:(id)sender
{
	//int	selected = [countryComboBox indexOfSelectedItem];
	//NSLog(@"selectCountry: %d: %@", selected, [countryComboBox stringValue]);
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[countryComboBox stringValue] forKey:tPrtCountryKey];
	[self setCountryFlag];
}

- (IBAction)changeUrl:(id)sender
{
	NSString *urlString = [urlField stringValue];
	NSLog(@"changeUrl: %@", urlString);
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:urlString forKey:tPrtHomeUrlKey];
}

- (IBAction)changeFaveriteKanji:(id)sender
{
	NSString *kanji = [tanukiBellyForm stringValue];
	NSLog(@"changeFaveriteKanji: %@", kanji);
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:kanji forKey:tPrtFaveriteKanjiKey];
	[self changeBackgroundColor:sender];
}

- (IBAction)changeCustomCountry:(id)sender
{
	// NSLog(@"changeCustomCountry: %d", [checkboxCountry state]);
	customCountry = [checkboxCountry state];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:customCountry forKey:tPrtCustomCountryKey];
	[countryCodeForm setEnabled:customCountry];
	[countryNameForm setEnabled:customCountry];
	[currencyCodeForm setEnabled:customCountry];
	[currencyNameForm setEnabled:customCountry];
	[currencySymbolForm setEnabled:customCountry];
	if (customCountry == YES) {
		[countryCodeForm setStringValue:customCountryCode];
		[countryNameForm  setStringValue:customCountryName];
		[currencyCodeForm  setStringValue:customCurrencyCode];
		[currencyNameForm  setStringValue:customCurrencyName];
		[currencySymbolForm setStringValue:customCurrencySymbol];
	} else {
		[countryCodeForm setStringValue:@"XT"];
		[countryNameForm  setStringValue:@"Republic of Tanuki (OVO)"];
		[currencyCodeForm  setStringValue:@"XTL"];
		[currencyNameForm  setStringValue:@"Leaf"];
		[currencySymbolForm setStringValue:@""];
	}
	[self buildCountyList];
	[tPrtController buildCountryList];
}

- (IBAction)changeCustomCountryCode:(id)sender
{
	NSString *value = [countryCodeForm stringValue];
	NSLog(@"changeCustomCountryCode: %@", value);
	if ([value length] != 2 && [value length] != 0) {
		NSBeep();
		[countryCodeForm setStringValue:customCountryCode];
		return;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:value forKey:tPrtCustomCountryCodeKey];
	customCountryCode = value;
	[self buildCountyList];
	[tPrtController buildCountryList];
}

- (IBAction)changeCustomCountryName:(id)sender
{
	NSString *value = [countryNameForm stringValue];
	NSLog(@"changeCustomCountryName: %@", customCountryName);
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:value forKey:tPrtCustomCountryNameKey];
	customCountryName = value;
}

- (IBAction)changeCustomCurrencyCode:(id)sender
{
	NSString *value = [currencyCodeForm stringValue];
	NSLog(@"changeCustomCurrencyCode");
	if ([value length] != 3 && [value length] != 0) {
		NSBeep();
		[currencyCodeForm setStringValue:customCurrencyCode];
		return;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:value forKey:tPrtCustomCurrencyCodeKey];
	customCurrencyCode = value;
	[self buildCountyList];
	[tPrtController buildCountryList];
}

- (IBAction)changeCustomCurrencyName:(id)sender
{
	NSString *value = [currencyNameForm stringValue];
	NSLog(@"changeCustomCurrencySymbol");
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:value forKey:tPrtCustomCurrencyNameKey];
	customCurrencyName = value;
}

- (IBAction)changeCustomCurrencySymbol:(id)sender
{
	NSString *value = [currencySymbolForm stringValue];
	NSLog(@"changeCustomCurrencySymbol");
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:value forKey:tPrtCustomCurrencySymbolKey];
	customCurrencySymbol = value;
}

- (void)setCountryFlag
{
	NSImage *template;
	NSString *path = [[NSString alloc] initWithFormat:@"flag%@",[countryComboBox stringValue]];
	template = [NSImage imageNamed:path];
	if (template == nil) {
		template = [NSImage imageNamed:@"flag-None"];
	}
	if (template) {
		[countryFlag setImage:template];
	}
	[path release];	
}

#pragma mark Bookmark

- (void)setBookmarks:(NSMutableArray*)a
{
	if (a == bookmarks) {
		return;
	}
	
	NSLog(@"setBookmarks");
	[a retain];
	for (Bookmark* bookmark in bookmarks) {
		[self stopObservingBookmark:bookmark];
	}
	[bookmarks removeAllObjects];
	[bookmarks release];
	bookmarks = a;
}

- (void)insertObject:(Bookmark*)p inBookmarksAtIndex:(int)index
{
	[self startObservingBookmark:p];
	[bookmarks insertObject:p atIndex:index];
}

- (void)removeObjectFromBookmarksAtIndex:(int)index
{
	Bookmark* bookmark = [bookmarks objectAtIndex:index];
	if (bookmark) {
		[self stopObservingBookmark:bookmark];
		[bookmarks removeObjectAtIndex:index];
	}
}

#pragma mark Feed

- (void)setFeeds:(NSMutableArray*)a
{
	if (a == feeds) {
		return;
	}
	
	NSLog(@"setBookmarks");
	[a retain];
	for (Bookmark* bookmark in feeds) {
		[self stopObservingBookmark:bookmark];
	}
	[feeds removeAllObjects];
	[feeds release];
	feeds = a;
}

- (void)insertFeedObject:(Bookmark*)p inBookmarksAtIndex:(int)index
{
	[self startObservingBookmark:p];
	[feeds insertObject:p atIndex:index];
}

- (void)removeObjectFromFeedsAtIndex:(int)index
{
	Bookmark* bookmark = [feeds objectAtIndex:index];
	if (bookmark) {
		[self stopObservingBookmark:bookmark];
		[feeds removeObjectAtIndex:index];
	}
}

/*
- (void)selectionDidChanging:(NSNotification *)notification {
	NSLog(@"selectionDidChanging: row = %d", [tableView selectedRow]);
}

- (void)selectionDidChanged:(NSNotification *)notification {
	NSLog(@"selectionDidChanged: row = %d", [tableView selectedRow]);
}
*/

#pragma mark EditBookmark

- (IBAction)deleteItem:(id)sender
{
	int row = [tableView selectedRow];
	if (row == -1) {
		return;
	}
	NSLog(@"deleteItem");
	[self removeObjectFromBookmarksAtIndex:row];
	[bookmarkController rearrangeObjects];
    [tableView reloadData];
	bookmarksModified = YES;
	[saveButton setEnabled:YES];
	[cancelButton setEnabled:YES];
}

- (IBAction)saveModification:(id)sender
{
	NSLog(@"saveModification");
	int index = 0;
	for (Bookmark* bookmark in bookmarks) {
		int column = -1;
		if ([bookmark title] == nil || [[bookmark title] isEqualToString:@""]) {
			column = 0;
		}
		if ([bookmark url] == nil || [[bookmark url] isEqualToString:@""]) {
			column = 1;
		}
		if (column == 0 || column == 1) {
			NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
											 defaultButton:NSLocalizedString(@"OK",@"Ok")
										   alternateButton:nil
											   otherButton:nil
								 informativeTextWithFormat:NSLocalizedString(@"INVALID_PARAM",@"paramater is invalid or not specified.")];
			[alert beginSheetModalForWindow:prefPanel modalDelegate:self didEndSelector:nil contextInfo:nil];
			[tableView editColumn:column row:index withEvent:nil select:YES];
			return;
		}
		index++;
	}
	[self saveBookmark];
	bookmarksModified = NO;
	[saveButton setEnabled:NO];
	[cancelButton setEnabled:NO];
	[bookmarkController rearrangeObjects];
    [tableView reloadData];
}

- (IBAction)cancelModification:(id)sender
{
	NSLog(@"cancelModification");
	[self loadBookmark];
	[bookmarkController rearrangeObjects];	
	bookmarksModified = NO;
	[saveButton setEnabled:NO];
	[cancelButton setEnabled:NO];
}

- (void)loadBookmark
{
	NSMutableArray *array;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *bookmarkAsData = [defaults objectForKey:tPrtBookmarkListKey];
	if (bookmarkAsData == nil) {
		return;
	}
	array = [NSKeyedUnarchiver unarchiveObjectWithData:bookmarkAsData];
	if (array == nil) {
		return;
	}
	if (bookmarks == nil) {
		bookmarks = [[NSMutableArray alloc] init];
	} else {
		for (Bookmark* bookmark in bookmarks) {
			[self stopObservingBookmark:bookmark];
		}
		[bookmarks removeAllObjects];
	}
	for (Bookmark* bookmark in array) {
		// NSLog(@"%@: %@", [bookmark title], [bookmark url]);
		[bookmarks addObject:bookmark];
	}
	for (Bookmark* bookmark in bookmarks) {
		[self startObservingBookmark:bookmark];
	}
	[bookmarkController rearrangeObjects];
    [tableView reloadData];
	return;
}

- (void)saveBookmark
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *bookmarkAsData = [NSKeyedArchiver archivedDataWithRootObject:bookmarks];
	[defaults setObject:bookmarkAsData forKey:tPrtBookmarkListKey];	

	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSLog(@"Sending Notification");
	NSDictionary *d = [NSDictionary dictionaryWithObject:bookmarks
												  forKey:@"bookmark"];
	[nc postNotificationName:tPrtBookmarkChangedNotification object:self userInfo:d];
}

#pragma mark EditFeed

- (IBAction)deleteFeedItem:(id)sender
{
	int row = [feedsTableView selectedRow];
	if (row == -1) {
		return;
	}
	NSLog(@"deleteItem");
	[self removeObjectFromFeedsAtIndex:row];
	[feedController rearrangeObjects];
    [feedsTableView reloadData];
	feedsModified = YES;
	[saveFeedButton setEnabled:YES];
	[cancelFeedButton setEnabled:YES];
}

- (IBAction)saveFeedModification:(id)sender
{
	NSLog(@"saveModification");
	int index = 0;
	for (Bookmark* bookmark in feeds) {
		int column = -1;
		if ([bookmark title] == nil || [[bookmark title] isEqualToString:@""]) {
			column = 0;
		}
		if ([bookmark url] == nil || [[bookmark url] isEqualToString:@""]) {
			column = 1;
		}
		if (column == 0 || column == 1) {
			NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
											 defaultButton:NSLocalizedString(@"OK",@"Ok")
										   alternateButton:nil
											   otherButton:nil
								 informativeTextWithFormat:NSLocalizedString(@"INVALID_PARAM",@"paramater is invalid or not specified.")];
			[alert beginSheetModalForWindow:prefPanel modalDelegate:self didEndSelector:nil contextInfo:nil];
			[feedsTableView editColumn:column row:index withEvent:nil select:YES];
			return;
		}
		index++;
	}
	[self saveFeed];
	feedsModified = NO;
	[saveFeedButton setEnabled:NO];
	[cancelFeedButton setEnabled:NO];
	[feedController rearrangeObjects];
    [feedsTableView reloadData];
}

- (IBAction)cancelFeedModification:(id)sender
{
	NSLog(@"cancelModification");
	[self loadFeed];
	[feedController rearrangeObjects];
	feedsModified = NO;
	[saveFeedButton setEnabled:NO];
	[cancelFeedButton setEnabled:NO];
}

- (void)loadFeed
{
	NSMutableArray *array;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *bookmarkAsData = [defaults objectForKey:tPrtFeedListKey];
	if (bookmarkAsData == nil) {
		return;
	}
	array = [NSKeyedUnarchiver unarchiveObjectWithData:bookmarkAsData];
	if (array == nil) {
		return;
	}
	if (feeds == nil) {
		feeds = [[NSMutableArray alloc] init];
	} else {
		for (Bookmark* bookmark in feeds) {
			[self stopObservingBookmark:bookmark];
		}
		[feeds removeAllObjects];
	}
	for (Bookmark* bookmark in array) {
		// NSLog(@"%@: %@", [bookmark title], [bookmark url]);
		[feeds addObject:bookmark];
	}
	for (Bookmark* bookmark in feeds) {
		[self startObservingBookmark:bookmark];
	}
    [feedsTableView reloadData];
	return;
}

- (void)saveFeed
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *bookmarkAsData = [NSKeyedArchiver archivedDataWithRootObject:feeds];
	[defaults setObject:bookmarkAsData forKey:tPrtFeedListKey];
    
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSLog(@"Sending Notification");
	NSDictionary *d = [NSDictionary dictionaryWithObject:feeds
												  forKey:@"feed"];
	[nc postNotificationName:tPrtFeedChangedNotification object:self userInfo:d];
}

#pragma mark CountryList

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
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_SI];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_SK];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_TH];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_TR];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_TW];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_UK];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_US];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_VN];
	[countryComboBox addItemWithObjectValue:TRADE_ITEM_COUNTRY_ZA];
}

#pragma mark Localizer

- (void) localizeView
{
	NSString* lang = NSLocalizedString(@"LANG",@"English");
	NSLog(@"localizeView: %@", lang);
	if ([lang isEqualToString:@"Japanese"]) {
		[urlLabel setStringValue:@"ホームページ:"];
		[colorLabel setStringValue:@"テーブルのテキストと背景の色:"];
		[countryLabel setStringValue:@"デフォルト国コード:"];
		[checkboxNewDoc setTitle:@" 起動時に名称未設定ドキュメントを自動的に開く"];
		[checkboxAutoSave setTitle:@" オートセーブを有効にする"];
		[checkboxOrder setTitle:@" 取引履歴を古い順に表示"];
        [checkboxSeparateCash setTitle:@" 現金を分離して資産を計算する"];
        [checkboxEnableDataSheet setTitle:@" データ入力シートを有効にする"];
		[checkboxAutoUpdate setTitle:@" ドキュメントを開いたら自動的に価格を更新"];
		[checkboxRedirect setTitle:@" URLリクエストをRSSリーダーに転送する"];
		[checkboxSortInfoPanel setTitle:@" informationパネルの銘柄を騰落率でソート"];
		[checkboxCountry setTitle:@"オプションの国と通貨: "];
		[[countryCodeForm cellAtIndex:0] setTitle:@"  国:      コード"];
		[[countryNameForm cellAtIndex:0] setTitle:@"  名前"];
		[[currencyCodeForm cellAtIndex:0] setTitle:@"  通貨:   コード"];
		[[currencyNameForm cellAtIndex:0] setTitle:@"  名前"];
		[[currencySymbolForm cellAtIndex:0] setTitle:@"    記号"];		
		[[tanukiBellyForm cellAtIndex:0] setTitle:@"好きな漢字: "];		
	}
}

@synthesize		colorLabel;
@synthesize		countryComboBox;
@synthesize		checkboxNewDoc;
@synthesize		checkboxOrder;
@synthesize		checkboxAutoUpdate;
@synthesize		checkboxSortInfoPanel;
@end
