//
//  MyDocument.h
//  tPortfolio
//
//  Created by Takahiro Sayama on 10/12/05.
//  Copyright 2011 tanuki-project. All rights reserved.
//

#import		<Cocoa/Cocoa.h>
#import		<WebKit/WebKit.h>
#import		"PreferenceController.h"
#import		"SubDocument.h"
#import		"RssReader.h"
#import		"infoPanel.h"
#import		"GraphPanel.h"
#import		"CashAccount.h"

@class	PortfolioItem;
@class	PortfolioSum;
@class	WebDocumentReader;
@class	Bookmark;
@class	infoPanel;

#ifdef NO_AUTOSAVE
extern NSString* const tPrtMainWindowFrameKey;
extern NSString* const tPrtSubWindowFrameKey;
#endif

#define DEFAULT_SPLIT_HIGHT 235
#define SPLIT_TREM_HIGHT    2

@interface MyDocument : NSDocument {
	NSMutableArray					*portfolioArray;
	//NSMutableArray				*portfolioWorkArray;
	NSMutableArray					*portfolioSumArray;
	NSMutableArray					*bookmarks;
	NSMutableArray					*feeds;
	SubDocument						*subDocument;
    CashAccount                     *cashAccount;
    RssReader                       *reader;
	infoPanel						*iPanel;
	infoPanel						*prevInfoPanel;
	NSMutableArray					*prevItems;
	NSString						*prevPriceList;
	PortfolioItem					*currentItem;
	PortfolioItem					*cashItem;
	WebDocumentReader				*webReader;
	bool							progressWebView;
	bool							progressConnection;
    bool                            speechingPortfolio;
    int                             speechIndex;
    boolean_t                       extended;
    GraphPanel                      *gPanel;
    boolean_t                       selectAutoPilot;
	IBOutlet NSWindow				*win;
    IBOutlet NSTextField            *tanukiBelly;
	IBOutlet NSTableView			*tableView;
	IBOutlet NSTableView			*tableViewSum;
	IBOutlet NSComboBoxCell			*comboBoxItem;
	IBOutlet NSComboBoxCell			*countryComboBox;
	IBOutlet NSComboBox				*comboBoxBookmark;
	IBOutlet NSArrayController		*portfolioController;
	IBOutlet NSArrayController		*portfolioSumController;
	IBOutlet WebView				*webView;
	IBOutlet NSDatePicker			*datePicker;
	IBOutlet NSTextField			*webTitle;
    IBOutlet NSView                 *customView;
	IBOutlet NSSplitView			*splitView;
	IBOutlet NSTextField			*urlField;
	IBOutlet NSPopUpButton			*sortButton;
	IBOutlet NSButton				*addButton;
	IBOutlet NSButton				*deleteButton;
	IBOutlet NSButton				*checkoutButton;
	IBOutlet NSButton				*goForward;
	IBOutlet NSButton				*goBack;
	IBOutlet NSButton				*goToIR;
	IBOutlet NSButton				*goToPortal;
	IBOutlet NSButton				*goToYahoo;
	IBOutlet NSButton				*refreshPrice;
	IBOutlet NSButton				*checkDetail;
    IBOutlet NSButton               *openReader;
    IBOutlet NSButton               *extendView;
	IBOutlet NSProgressIndicator	*progress;
    IBOutlet NSStepper              *itemStepper;
    IBOutlet NSWindow               *portfolioItemSheet;
    IBOutlet NSTextField            *portfolioItemCodeLabel;
    IBOutlet NSTextField            *portfolioItemCodeField;
    IBOutlet NSTextField            *portfolioItemTypeLabel;
    IBOutlet NSComboBox				*portfolioItemTypeBox;
    IBOutlet NSTextField            *portfolioItemNameLabel;
    IBOutlet NSTextField            *portfolioItemNameField;
    IBOutlet NSTextField            *portfolioItemCountryLabel;
    IBOutlet NSComboBox				*portfolioItemCountryBox;
    IBOutlet NSImageView            *portfolioItemCountryFlag;
    IBOutlet NSTextField            *portfolioItemCountryName;
    IBOutlet NSTextField            *portfolioItemSiteLabel;
    IBOutlet NSTextField            *portfolioItemSiteField;
    IBOutlet NSTextField            *portfolioItemNoteLabel;
    IBOutlet NSTextField            *portfolioItemNoteField;
    IBOutlet NSButton               *portfolioItemOk;
    IBOutlet NSButton               *portfolioItemCancel;
    IBOutlet NSWindow               *performanceSheet;
    IBOutlet NSButton               *performanceOk;
    IBOutlet NSButton               *performanceCancel;
    IBOutlet NSDatePicker			*performanceFromDate;
    IBOutlet NSDatePicker			*performanceToDate;
    IBOutlet NSTextField            *performanceLabel;
}

- (IBAction)clickImage:(id)sender;
- (IBAction)takeStringUrl:(id)sender;
- (IBAction)sortPortfolio:(id)sender;
- (IBAction)checkoutPortfolio:(id)sender;
- (IBAction)checkoutPerformance:(id)sender;
- (IBAction)createPortfolioItem:(id)sender;
- (IBAction)removePortfolioItem:(id)sender;
- (IBAction)goToIRSite:(id)sender;
- (IBAction)setIRSite:(id)sender;
- (IBAction)goToPortalSite:(id)sender;
- (IBAction)goToYahooFinance:(id)sender;
- (IBAction)refreshPrice:(id)sender;
- (IBAction)refreshPriceDescending:(id)sender;
- (IBAction)selectBookmark:(id)sender;
- (IBAction)startCrawlingYahoo:(id)sender;
- (IBAction)showPerformanceSheet:(id)sender;
- (IBAction)endPerformanceSheet:(id)sender;
- (IBAction)showProtfolioItemSheet:(id)sender;
- (IBAction)endProtfolioItemSheet:(id)sender;
- (IBAction)setCountryFlag:(id)sender;
- (IBAction)setPortfolioItem:(id)sender;

- (IBAction)startCrawlingMinkabu:(id)sender;
- (IBAction)startCrawlingGoogle:(id)sender;
- (IBAction)startCrawlingIR:(id)sender;
- (IBAction)startCrawlingBookmark:(id)sender;
- (IBAction)stopCrawling:(id)sender;
- (IBAction)checkDetail:(id)sender;
- (IBAction)evaluateAllItems:(id)sender;
- (IBAction)openReader:(id)sender;
- (IBAction)changeStepper:(id)sender;
- (IBAction)extendView:(id)sender;

- (void)openItem:(id)sender;
- (void)openGraph:(id)sender;
- (void)buildGraph:(NSString*)countryCode;
- (void)actionClose:(NSNotification *)notification;
- (void)startConnection:(bool)ascend;
- (void)autoConnection:(int)index :(bool)retry;
- (void)sortPortfolioByKey:(NSString*)key :(bool)caseInsensitive :(bool)ascend;
- (PortfolioItem*)searchPortfolioItemByIndex:(int)index;
- (void)jumpUrl:(NSString*)urlString :(bool)connect;
- (void)loadBookmark;
- (void)saveBookmark;
- (void)enableUrlRequest:(bool)lock;
- (void)setPortfolio:(NSMutableArray*)a;
- (void)insertObject:(PortfolioItem*)p inPortfolioArrayAtIndex:(int)index;
- (void)removeObjectFromPortfolioArrayAtIndex:(int)index;
- (void)startObservingPortfolio:(PortfolioItem*)item;
- (void)stopObservingPortfolio:(PortfolioItem*)item;
- (void)changeKeyPath:(NSString*)keyPath
			 obObject:(id)obj
			  toValue:(id)newValue;
- (void)observeValueForKeyPath:(NSString*)keyPath
					  ofObject:(id)object
						change:(NSDictionary*)change
					   context:(void*)context;
- (void)setTableColumeAttribute:(int)row;
- (void)setPortfolioEdited;
- (void)sumPortfolio:(PortfolioSum*)sum;
- (void)setHiddenColumn:(bool)hidden;
- (void)rearrangeDocument;
- (void)enableWeb;

-(void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell
  forTableColumn:(NSTableColumn *)tableColumn
			 row:(int)row;

- (void)allocatePortfolioSumArray;
- (void)releasePortfolioSumArray;
- (void)setPortfolioSumArray;
- (NSString*)CountryToCurrency:(NSString*)country;
- (NSString*)CountryToDomain:(NSString*)country;

- (void)exportCSV:(bool)convert;
- (void)importCSV:(bool)convert;
- (void)importSample:(NSString*)path;

- (void)exportPortfolio:(NSString*)path :(bool)convert;
- (void)importPortfolio:(NSString*)path :(bool)convert;
//- (void)importPortfolio:(NSURL*)path:(bool)convert;
- (NSString*)readSJisText:(NSString*)path;
- (void)writeSJisText:(NSString*)path :(NSString*)content;

- (void)initHistory;
- (void)buildCountyList;
- (void)setFontColor:(NSColor*)color;
- (void)localizeView;

@property	(readwrite,assign)	SubDocument*			subDocument;
@property	(readwrite,assign)	CashAccount*			cashAccount;
@property	(readwrite,assign)	infoPanel*				iPanel;
@property	(readwrite,assign)	PortfolioItem*			currentItem;
@property	(readwrite,assign)	PortfolioItem*			cashItem;
@property	(readwrite,assign)	WebDocumentReader*		webReader;
@property	(readwrite,assign)	RssReader*              reader;
@property	(readwrite)			bool					progressWebView;
@property	(readwrite)			bool					progressConnection;
@property   (readwrite)         bool                    speechingPortfolio;
@property   (readwrite)         int                     speechIndex;
@property	(readwrite,retain)	NSMutableArray*			portfolioArray;
@property	(readwrite,retain)	NSMutableArray*			bookmarks;
@property	(readwrite,retain)	NSMutableArray*			portfolioSumArray;
@property	(readwrite,retain)	NSTextField*			urlField;
@property	(readwrite,retain)	NSTextField*			webTitle;
@property	(readwrite,retain)	NSTextField*			tanukiBelly;
@property	(readwrite,retain)	NSWindow*				win;
@property	(readwrite,retain)	WebView*				webView;
@property	(readwrite,retain)	NSTableView*			tableView;
@property	(readwrite,retain)	NSTableView*			tableViewSum;
@property	(readwrite,retain)	NSButton*				goBack;
@property	(readwrite,retain)	NSButton*				goForward;
@property	(readwrite,retain)	NSButton*				goToIR;
@property	(readwrite,retain)	NSButton*				goToPortal;
@property	(readwrite,retain)	NSButton*				goToYahoo;
@property	(readwrite,retain)	NSButton*				refreshPrice;
@property	(readwrite,retain)	NSDatePicker*			datePicker;
@property	(readwrite,retain)	NSProgressIndicator*	progress;
@property   (readwrite)         boolean_t               extended;
@end
