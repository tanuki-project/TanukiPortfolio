//
//  SubDocument.h
//  tPortfolio
//
//  Created by Takahiro Sayama on 10/12/12.
//  Copyright 2011 tanuki-project. All rights reserved.
//

#import		<Cocoa/Cocoa.h>

@class	TradeItem;
@class	PortfolioItem;
@class	MyDocument;

#define TRADE_SHEET_HIGHT_MAX       208
#define TRADE_SHEET_HIGHT_OFFSET    30

@interface SubDocument : NSWindowController {
	PortfolioItem				*portfolioItem;
	NSMutableArray				*trades;
	NSDocument					*doc;
    MyDocument                  *parentDoc;
	bool						stepperEdited;
    int                         clickCnt;
    NSButton                    *tradeSender;
	IBOutlet NSTableView		*tableView;
	IBOutlet NSDatePicker		*datePicker;
	IBOutlet NSArrayController	*tradeController;
	IBOutlet NSTextField		*priceField;
	IBOutlet NSTextField		*averageField;
	IBOutlet NSTextField		*quantityField;
	IBOutlet NSTextField		*performanceField;
	IBOutlet NSTextField		*investedField;
	IBOutlet NSTextField		*estimatedField;
	IBOutlet NSTextField		*totalGainField;
	IBOutlet NSTextField		*latentGainField;
	IBOutlet NSTextField		*capitalGainField;
	IBOutlet NSTextField		*incomeGainField;
	IBOutlet NSTextField		*labelPrice;
	IBOutlet NSTextField		*labelAverage;
	IBOutlet NSTextField		*labelQuantity;
	IBOutlet NSTextField		*labelPerformance;
	IBOutlet NSTextField		*labelInvested;
	IBOutlet NSTextField		*labelEstimated;
	IBOutlet NSTextField		*labelTotalGain;
	IBOutlet NSTextField		*labelLatentGain;
	IBOutlet NSTextField		*labelCapitalGain;
	IBOutlet NSTextField		*labelIncomeGain;
	IBOutlet NSButton			*buyButon;
	IBOutlet NSButton			*sellButon;
	IBOutlet NSButton			*dividendButon;
	IBOutlet NSButton			*splitButon;
	IBOutlet NSButton			*estimateButon;
	IBOutlet NSButton			*deleteButton;
	IBOutlet NSButton			*undoButon;
	IBOutlet NSButton			*redoButon;
	IBOutlet NSButton			*checkButon;
	IBOutlet NSButton			*checkDetail;
	IBOutlet NSImageView		*flagImage;
	IBOutlet NSForm				*targetForm;
	IBOutlet NSStepper			*targetStepper;
	IBOutlet NSStepper			*lossCutStepper;
	IBOutlet NSWindow			*win;
    IBOutlet NSWindow           *tradeSheet;
    IBOutlet NSButton           *tradeOk;
    IBOutlet NSButton           *tradeCancel;
    IBOutlet NSButton           *tradeCheckBox;
    IBOutlet NSTextField        *tradeText;
    IBOutlet NSDatePicker		*tradeDatePicker;
    IBOutlet NSTextField        *tradeDateLabel;
    IBOutlet NSTextField        *tradePriceField;
    IBOutlet NSTextField        *tradePriceLabel;
    IBOutlet NSTextField        *tradeValueField1st;
    IBOutlet NSTextField        *tradeValueField2nd;
    IBOutlet NSTextField        *tradeValueField3rd;
    IBOutlet NSTextField        *tradeValueLabel1st;
    IBOutlet NSTextField        *tradeValueLabel2nd;
    IBOutlet NSTextField        *tradeValueLabel3rd;
    IBOutlet NSTextField        *tradeCommentField;
    IBOutlet NSTextField        *tradeCommentLabel;
    IBOutlet NSTextField        *tradeSettlementField;
    IBOutlet NSTextField        *tradeSettlementLabel;
}

- (IBAction)addBuy:(id)sender;
- (IBAction)addSell:(id)sender;
- (IBAction)addDividend:(id)sender;
- (IBAction)addSplit:(id)sender;
- (IBAction)addAccount:(id)sender;
- (IBAction)undoTradeItem:(id)sender;
- (IBAction)redoTradeItem:(id)sender;
- (IBAction)checkoutTrades:(id)sender;
- (IBAction)checkDetail:(id)sender;
- (IBAction)clickImage:(id)sender;
- (IBAction)changePrice:(id)sender;
- (IBAction)changeYieldTarget:(id)sender;
- (IBAction)changeLossCutLimit:(id)sender;
- (IBAction)changeTargetForm:(id)sender;
- (IBAction)showTradeSheet:(id)sender;
- (IBAction)endTradeSheet:(id)sender;
- (IBAction)changeTradeCheckBox:(id)sender;
- (IBAction)showTradeSettlement:(id)sender;

- (void)createTradeItem:(NSString*)type;
- (void)createTradeItemWithValue:(NSString*)type
                           price:(double)price
                          bought:(double)bought
                            sold:(double)sold
                          charge:(double)charge
                             tax:(double)tax
                          income:(double)income
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
- (void)setEnabledButtons;
- (void)setTableColumeAttribute:(int)row;
- (void)setHiddenColumn:(bool)hidden;
- (void)setTargetFlag;
- (void)actionClose:(NSNotification *)notification;
- (void)actionSelectView:(NSNotification *)notification;
- (void)rearrangeDocument;
- (void)setFontColor:(NSColor*)color;
- (void)localizeView;

@property	(readwrite,assign)	PortfolioItem	*portfolioItem;
@property   (readwrite,assign)  MyDocument      *parentDoc;
@property	(readwrite,retain)	NSMutableArray	*trades;
@property	(readwrite,retain)	NSTextField*	priceField;
@property	(readwrite,retain)	NSTextField*	averageField;
@property	(readwrite,retain)	NSTextField*	quantityField;
@property	(readwrite,retain)	NSTextField*	performanceField;
@property	(readwrite,retain)	NSTextField*	investedField;
@property	(readwrite,retain)	NSTextField*	estimatedField;
@property	(readwrite,retain)	NSTextField*	totalGainField;
@property	(readwrite,retain)	NSTextField*	latentGainField;
@property	(readwrite,retain)	NSTextField*	capitalGainField;
@property	(readwrite,retain)	NSTextField*	incomeGainField;
@property	(readwrite,retain)	NSForm*			targetForm;
@property	(readwrite,retain)	NSWindow*		win;
@end
