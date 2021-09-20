//
//  CashAccount.h
//  TanukiPortfolio
//
//  Created by Takahiro Sayama on 2012/12/16.
//  Copyright (c) 2012年 tanuki-project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class	TradeItem;
@class	PortfolioItem;
@class	MyDocument;

@interface CashAccount : NSWindowController {
    PortfolioItem				*portfolioItem;
	NSMutableArray				*trades;
	NSDocument					*doc;
    MyDocument                  *parentDoc;
    NSButton                    *tradeSender;
	IBOutlet NSTableView		*tableView;
    IBOutlet NSDatePicker       *datePicker;
	IBOutlet NSArrayController	*tradeController;
	IBOutlet NSTextField		*balanceField;
	IBOutlet NSTextField		*labelBalance;
    IBOutlet NSButton           *depositButton;
    IBOutlet NSButton           *withdrawButton;
    IBOutlet NSButton           *interestButton;
    IBOutlet NSButton           *checkoutButton;
    IBOutlet NSButton           *deleteButton;
	IBOutlet NSButton			*undoButton;
	IBOutlet NSButton			*redoButton;
	IBOutlet NSWindow			*win;
    IBOutlet NSWindow           *tradeSheet;
    IBOutlet NSButton           *tradeOk;
    IBOutlet NSButton           *tradeCancel;
    IBOutlet NSTextField        *tradeText;
    IBOutlet NSDatePicker		*tradeDatePicker;
    IBOutlet NSTextField        *tradeDateLabel;
    IBOutlet NSTextField        *tradeValueField;
    IBOutlet NSTextField        *tradeValueLabel;
    IBOutlet NSTextField        *tradeCommentField;
    IBOutlet NSTextField        *tradeCommentLabel;
}

- (IBAction)addDeposit:(id)sender;
- (IBAction)addWithdraw:(id)sender;
- (IBAction)addInterest:(id)sender;
- (IBAction)undoTradeItem:(id)sender;
- (IBAction)redoTradeItem:(id)sender;
- (IBAction)checkoutTrades:(id)sender;
- (IBAction)showTradeSheet:(id)sender;
- (IBAction)endTradeSheet:(id)sender;

- (void)createTradeItem :(NSString*)type :(NSString*)comment;
- (void)createTradeItemWithValue :(NSString*)type
                          deposit:(double)deposit
                         withdraw:(double)witdraw
                          comment:(NSString*)comment;
- (void)setTrades:(NSMutableArray*)a;
- (void)insertObject:(TradeItem *)p inTradesAtIndex:(int)index;
- (void)removeObjectFromTradesAtIndex:(int)index;
- (void)startObservingTrades:(TradeItem*)item;
- (void)stopObservingTrades:(TradeItem*)item;
- (void)changeKeyPath:(NSString*)keyPath
			 obObject:(id)obj
			  toValue:(id)newValue;
- (void)observeValueForKeyPath:(NSString*)keyPath
					  ofObject:(id)object
						change:(NSDictionary*)change
					   context:(void*)context;
- (void)setTableColumeAttribute:(int)row;
- (void)rearrangeDocument;
- (void)setFontColor:(NSColor*)color;
- (void)localizeView;

@property	(readwrite,assign)	PortfolioItem	*portfolioItem;
@property   (readwrite,assign)  MyDocument      *parentDoc;
@property	(readwrite,retain)	NSMutableArray	*trades;
@property	(readwrite,retain)	NSWindow*		win;
@property   (readwrite,assign)	NSTableView     *tableView;

@end
