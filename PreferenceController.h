//
//  PreferenceController.h
//  tPortfolio
//
//  Created by Takahiro Sayama on 10/12/05.
//  Copyright 2011 tanuki-project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#pragma mark Enable NSLog

#if !defined(NS_BLOCK_ASSERTIONS)

#if !defined(NSLog)
#define NSLog( m, args... ) NSLog( m, ##args )
#endif

#else

#if !defined(NSLog)
#define NSLog( m, args... )
#endif

#endif

#define SPEECH_RATE_SLOW        150
#define SPEECH_RATE_NORMAL      200
#define SPEECH_RATE_FAST        275
#define SPEECH_RATE_VERYFAST    350

@class	Bookmark;

extern NSString* const tPrtTableBgColorKey;
extern NSString* const tPrtTableFontColorKey;
extern NSString* const tPrtEmptyDocKey;
extern NSString* const tPrtAutoSaveKey;
extern NSString* const tPrtTradeOrderKey;
extern NSString* const tPrtSeparateCashKey;
extern NSString* const tPrtAutoUpdateKey;
extern NSString* const tPrtSortInfoPanelKey;
extern NSString* const tPrtCountryKey;

extern NSString* const tPrtColorChangedNotification;
extern NSString* const tPrtBookmarkChangedNotification;
extern NSString* const tPrtFeedChangedNotification;
//extern NSString* const tPrtShowTextChangedNotification;

extern NSString* const tPrtHomeUrlKey;
extern NSString* const tPrtLastUrlKey;
extern NSString* const tPrtBookmarkListKey;
extern NSString* const tPrtPortfolioDetailKey;
extern NSString* const tPrtTradeDetailKey;

@interface PreferenceController : NSWindowController {
	NSMutableArray				*bookmarks;
	NSMutableArray				*feeds;
	bool						bookmarksModified;
	bool						feedsModified;
	NSString					*country;
	IBOutlet NSTabView			*PreferenceTab;
	IBOutlet NSArrayController	*bookmarkController;
	IBOutlet NSArrayController	*feedController;
	IBOutlet NSColorWell		*colorWell;
	IBOutlet NSColorWell		*fontColorWell;
	IBOutlet NSTextField		*colorLabel;
	IBOutlet NSButton			*checkboxNewDoc;
	IBOutlet NSButton			*checkboxAutoSave;
	IBOutlet NSButton			*checkboxOrder;
	IBOutlet NSButton			*checkboxSeparateCash;
    IBOutlet NSButton			*checkboxEnableDataSheet;
	IBOutlet NSButton			*checkboxAutoUpdate;
	IBOutlet NSButton			*checkboxRedirect;
	IBOutlet NSButton			*checkboxSortInfoPanel;
	IBOutlet NSButton			*checkboxCountry;
	IBOutlet NSForm				*countryCodeForm;
	IBOutlet NSForm				*countryNameForm;
	IBOutlet NSForm				*currencyCodeForm;
	IBOutlet NSForm				*currencyNameForm;
	IBOutlet NSForm				*currencySymbolForm;
    IBOutlet NSForm             *tanukiBellyForm;
	IBOutlet NSComboBox			*countryComboBox;
	IBOutlet NSTextField		*countryLabel;
	IBOutlet NSImageView		*countryFlag;
	IBOutlet NSTextField		*urlField;
	IBOutlet NSTextField		*urlLabel;
	IBOutlet NSTableView		*tableView;
	IBOutlet NSButton			*deleteButton;
	IBOutlet NSButton			*saveButton;
	IBOutlet NSButton			*cancelButton;
	IBOutlet NSTableView		*feedsTableView;
	IBOutlet NSButton			*deleteFeedButton;
	IBOutlet NSButton			*saveFeedButton;
	IBOutlet NSButton			*cancelFeedButton;
	IBOutlet NSWindow			*prefPanel;
}

- (void)startObservingBookmark:(Bookmark*)item;
- (void)stopObservingBookmark:(Bookmark*)item;
- (void)changeKeyPath:(NSString*)keyPath
			 obObject:(id)obj
			  toValue:(id)newValue;
- (void)observeValueForKeyPath:(NSString*)keyPath
					  ofObject:(id)object
						change:(NSDictionary*)change
					   context:(void*)context;

- (NSColor*)tableBgColor;
- (BOOL)emptyDoc;
- (BOOL)autoSave;
- (BOOL)tradeOrder;
- (BOOL)autoUpdate;
- (NSString*)countryCode;
- (NSString*)homeUrl;
- (void)setCountryFlag;

- (IBAction)changeBackgroundColor:(id)sender;
- (IBAction)changeFontColor:(id)sender;
- (IBAction)changeNewEmptyDoc:(id)sender;
- (IBAction)changeAutoSave:(id)sender;
- (IBAction)changeTradeOrder:(id)sender;
- (IBAction)changeEnableDataSheet:(id)sender;
- (IBAction)changeAutoUpdate:(id)sender;
- (IBAction)changeRedirect:(id)sender;
- (IBAction)changeSortInfoPanel:(id)sender;
- (IBAction)deleteItem:(id)sender;
- (IBAction)saveModification:(id)sender;
- (IBAction)cancelModification:(id)sender;
- (IBAction)selectCountry:(id)sender;
- (IBAction)changeUrl:(id)sender;
- (IBAction)changeCustomCountry:(id)sender;
- (IBAction)changeCustomCountryCode:(id)sender;
- (IBAction)changeCustomCountryName:(id)sender;
- (IBAction)changeCustomCurrencyCode:(id)sender;
- (IBAction)changeCustomCurrencyName:(id)sender;
- (IBAction)changeCustomCurrencySymbol:(id)sender;
- (IBAction)changeFaveriteKanji:(id)sender;

- (void)setBookmarks:(NSMutableArray*)a;
- (void)setFeeds:(NSMutableArray*)a;
- (void)insertObject:(Bookmark*)p inBookmarksAtIndex:(int)index;
- (void)insertFeedObject:(Bookmark*)p inBookmarksAtIndex:(int)index;
- (void)removeObjectFromBookmarksAtIndex:(int)index;
- (void)removeObjectFromFeedsAtIndex:(int)index;
- (void)loadBookmark;
- (void)loadFeed;
- (void)saveBookmark;
- (void)saveFeed;
- (void)buildCountyList;
- (void)localizeView;                               

@property	(readwrite,retain)	NSTextField*		colorLabel;
@property	(readwrite,retain)	NSComboBox*			countryComboBox;
@property	(readwrite,retain)	NSButton*			checkboxNewDoc;
@property	(readwrite,retain)	NSButton*			checkboxOrder;
@property	(readwrite,retain)	NSButton*			checkboxAutoUpdate;
@property	(readwrite,retain)	NSButton*			checkboxSortInfoPanel;
@end
