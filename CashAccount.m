//
//  CashAccount.m
//  TanukiPortfolio
//
//  Created by Takahiro Sayama on 2012/12/16.
//  Copyright (c) 2012年 tanuki-project. All rights reserved.
//

#import     "CashAccount.h"
#import		"PortfolioItem.h"
#import		"MyDocument.h"
#include	"AppController.h"

extern PortfolioItem	*tPrtCashItem;
extern bool             enableDataInputSheet;

@interface CashAccount ()
- (void)startObservingTrades:(TradeItem *)item;
- (void)stopObservingTrades:(TradeItem *)item;
@end

@implementation CashAccount

- (id)init
{
	NSLog(@"init CashAccount");
    self = [super initWithWindowNibName:@"CashAccount"];
	if (self == nil) {
		return nil;
	}
	portfolioItem = tPrtCashItem;
	trades = [portfolioItem trades];
	doc = [[NSDocument alloc] init];
	[[self window] setTitle:[portfolioItem itemName]];
    parentDoc = nil;
	NSLog(@"count = %d",(int)[trades count]);

	// Set Notifier
	NSNotificationCenter *nc=[NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(actionClose:)
               name:NSWindowWillCloseNotification
             object:win];
	[nc addObserver:self selector:@selector(actionSelectView:)
               name:NSTableViewSelectionDidChangeNotification
             object:tableView];
	
	// Start Undo Manager
	for (TradeItem *item in trades) {
		[self startObservingTrades:item];
	}
    return self;
}

- (void)dealloc
{
	NSLog(@"dealloc CashAccount");
	[portfolioItem DoSettlement];
    
	// Remove Notifier
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];
    
	// Stop Undo Manager
	for (TradeItem *item in trades) {
		[self stopObservingTrades:item];
	}
	trades = nil;
	portfolioItem = nil;
	if (doc) {
		[doc dealloc];
		doc = nil;
	}
	[super dealloc];
}

- (void)close
{
	NSLog(@"Close: CashAccount");
	[super close];
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
	[datePicker setDateValue:[NSDate date]];
	[self setEnabledButtons];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *colorAsData;
	colorAsData = [defaults objectForKey:tPrtTableBgColorKey];
	//[tableView setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];
	[tableView setBackgroundColor:[NSKeyedUnarchiver unarchiveObjectWithData:colorAsData]];
	colorAsData = [defaults objectForKey:tPrtTableFontColorKey];
	[self setFontColor:[NSKeyedUnarchiver unarchiveObjectWithData:colorAsData]];
	[self localizeView];
	int row = [tableView selectedRow];
	if (row != -1) {
		[self setTableColumeAttribute:row];
	}
	[balanceField setDoubleValue:[portfolioItem quantity]];
}

#pragma mark Accesser

- (void)createTradeItem:(NSString*)type :(NSString*)comment
{
	NSLog(@"createTradeItem");
	NSWindow *w = [tableView window];
	BOOL editingEnded = [w makeFirstResponder:w];
	if (!editingEnded) {
		NSLog(@"Unable to end editing");
		return;
	}
	NSUndoManager *undo = [doc undoManager];
	if ([undo groupingLevel]) {
		[undo endUndoGrouping];
		[undo beginUndoGrouping];
	}
	// Add TradeItem
	TradeItem *t = [tradeController newObject];
	NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *compo = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit)
										  fromDate:[datePicker dateValue]];
	[t setDate: [calendar dateFromComponents:compo]];
	[calendar release];
	if (type) {
		[t setKind:type];
	}
    if (comment) {
        [t setComment:comment];
    }
	[t setPrice:[portfolioItem price]];
	if ([portfolioItem order] == TRADE_ITEM_ORDER_ASCENDING) {
		NSLog(@"add trade as last record.");
		[tradeController addObject:t];
	} else {
		NSLog(@"add trade as first record.");
		[tradeController insertObject:t atArrangedObjectIndex:0];
	}
	[portfolioItem SortTradesByDate];
	[tradeController rearrangeObjects];
    
	// Set Edit point
	NSArray *a = [tradeController arrangedObjects];
	int row = [a indexOfObjectIdenticalTo:t];
	if (row != -1) {
		// NSLog(@"strating edit of %@ in row %d", t, row);
		[tableView editColumn:1 row:row withEvent:nil select:YES];
	}
	[t release];
	[self setTableColumeAttribute:row];
	[self setEnabledButtons];
}

- (void)createTradeItemWithValue :(NSString*)type
                          deposit:(double)deposit
                         withdraw:(double)witdraw
                          comment:(NSString*)comment;
{
    NSLog(@"createTradeItemWithValue");
    NSWindow *w = [tableView window];
    BOOL editingEnded = [w makeFirstResponder:w];
    if (!editingEnded) {
        NSLog(@"Unable to end editing");
        return;
    }
    NSUndoManager *undo = [doc undoManager];
    if ([undo groupingLevel]) {
        [undo endUndoGrouping];
        [undo beginUndoGrouping];
    }
    // Add TradeItem
    TradeItem *t = [tradeController newObject];
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *compo = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit)
                                          fromDate:[tradeDatePicker dateValue]];
    [t setDate: [calendar dateFromComponents:compo]];
    [t setBuy:deposit];
    [t setSell:witdraw];
    [calendar release];
    if (type) {
        [t setKind:type];
    }
    if (comment) {
        [t setComment:comment];
    }
    [t setPrice:[portfolioItem price]];
    if ([portfolioItem order] == TRADE_ITEM_ORDER_ASCENDING) {
        NSLog(@"add trade as last record.");
        [tradeController addObject:t];
    } else {
        NSLog(@"add trade as first record.");
        [tradeController insertObject:t atArrangedObjectIndex:0];
    }
    [portfolioItem SortTradesByDate];
    [tradeController rearrangeObjects];
    
    // Set Edit point
    NSArray *a = [tradeController arrangedObjects];
    int row = [a indexOfObjectIdenticalTo:t];
    if (row != -1) {
        // NSLog(@"strating edit of %@ in row %d", t, row);
        [tableView editColumn:1 row:row withEvent:nil select:YES];
    }
    [t release];
    [portfolioItem DoSettlement];
    [self setTableColumeAttribute:row];
    [self setEnabledButtons];
}

- (void)setTradesArray:(NSMutableArray*)a
{
	if (a == trades) {
		return;
	}
	
	NSLog(@"setTrades");
	for (TradeItem *item in trades) {
		[self stopObservingTrades:item];
	}
	[a retain];
	[trades release];
	trades = a;
	for (TradeItem *item in trades) {
		[self startObservingTrades:item];
	}
	[self setEnabledButtons];
}

- (void)insertObject:(TradeItem *)t inTradesAtIndex:(int)index
{
	// NSLog(@"insertObject: adding %@ to %@",t,trades);
	NSUndoManager *undo = [doc undoManager];
	NSLog(@"undo = %@",undo);
	[[undo prepareWithInvocationTarget:self] removeObjectFromTradesAtIndex:index];
	if (![undo isUndoing]) {
		[undo setActionName:@"Insert TradeItem"];
	}
	[self setEnabledButtons];
	[self startObservingTrades:t];
	[trades insertObject:t atIndex:index];
    if (parentDoc) {
        [parentDoc setPortfolioEdited];
    }
	NSLog(@"portfolio count = %d", (int)[trades count]);
}

- (void)removeObjectFromTradesAtIndex:(int)index
{
	NSLog(@"removeObjectFromTradeAtIndex: %d",index);
	TradeItem *t = [trades objectAtIndex:index];
	//NSLog(@"removing %@ to %@", t, trades);
	NSUndoManager *undo = [doc undoManager];
	NSLog(@"undo = %@",undo);
	[[undo prepareWithInvocationTarget:self]
    insertObject:t inTradesAtIndex:index];
	if (![undo isUndoing]) {
		[undo setActionName:@"Delete TradeItem"];
	}
	//[self setEnabledButtons];
	[self stopObservingTrades:t];
	[trades removeObjectAtIndex:index];
    if (parentDoc) {
        [parentDoc setPortfolioEdited];
    }
	NSLog(@"portfolio count = %d", (int)[trades count]);
	[portfolioItem DoSettlement];
	[self rearrangeDocument];
}

- (void)startObservingTrades:(TradeItem *)item
{
	NSLog(@"startObservingTrades: %@", item);
	[item addObserver:self
		   forKeyPath:@"date"
			  options:NSKeyValueObservingOptionOld
			  context:NULL];
	[item addObserver:self
		   forKeyPath:@"kind"
			  options:NSKeyValueObservingOptionOld
			  context:NULL];
	[item addObserver:self
		   forKeyPath:@"comment"
			  options:NSKeyValueObservingOptionOld
			  context:NULL];
	[item addObserver:self
		   forKeyPath:@"price"
			  options:NSKeyValueObservingOptionOld
			  context:NULL];
	[item addObserver:self
		   forKeyPath:@"buy"
			  options:NSKeyValueObservingOptionOld
			  context:NULL];
	[item addObserver:self
		   forKeyPath:@"sell"
			  options:NSKeyValueObservingOptionOld
			  context:NULL];
	[item addObserver:self
		   forKeyPath:@"charge"
			  options:NSKeyValueObservingOptionOld
			  context:NULL];
	[item addObserver:self
		   forKeyPath:@"dividend"
			  options:NSKeyValueObservingOptionOld
			  context:NULL];
	[item addObserver:self
		   forKeyPath:@"tax"
			  options:NSKeyValueObservingOptionOld
			  context:NULL];
}

- (void)stopObservingTrades:(TradeItem*)item
{
	NSLog(@"stopObservingTrades: %@", item);
	[item removeObserver:self forKeyPath:@"date"];
	[item removeObserver:self forKeyPath:@"kind"];
	[item removeObserver:self forKeyPath:@"comment"];
	[item removeObserver:self forKeyPath:@"price"];
	[item removeObserver:self forKeyPath:@"buy"];
	[item removeObserver:self forKeyPath:@"sell"];
	[item removeObserver:self forKeyPath:@"charge"];
	[item removeObserver:self forKeyPath:@"dividend"];
	[item removeObserver:self forKeyPath:@"tax"];
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
	NSUndoManager *undo = [doc undoManager];
	id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
	if (oldValue == [NSNull null]) {
		oldValue = nil;
	}
	NSLog(@"oldValue = %@", oldValue);
	[[undo prepareWithInvocationTarget:self] changeKeyPath:keyPath
												  obObject:object
												   toValue:oldValue];
	[undo setActionName:@"Edit"];
    if (parentDoc) {
        [parentDoc setPortfolioEdited];
    }
	[self setEnabledButtons];
}

- (void)setEnabledButtons
{
	NSUndoManager *undo = [doc undoManager];
	if ([undo canUndo]) {
		[undoButton setEnabled:YES];
	} else {
		[undoButton setEnabled:NO];
	}
	if ([undo canRedo]) {
		[redoButton setEnabled:YES];
	} else {
		[redoButton setEnabled:NO];
	}
	if ([trades count] == 0) {
		[checkoutButton setEnabled:NO];
		[deleteButton setEnabled:NO];
	} else {
		[checkoutButton setEnabled:YES];
		[deleteButton setEnabled:YES];
	}
}


- (void)rearrangeDocument
{
	[tradeController rearrangeObjects];
    if (parentDoc) {
        [parentDoc rearrangeDocument];
    }
	[balanceField setDoubleValue:[portfolioItem quantity]];
}

#pragma mark Actions

-(void)actionClose:(NSNotification *)notification {
	NSLog(@"actionClose");
	[portfolioItem DoSettlement];
	[parentDoc setCurrentItem:nil];
}

-(void)actionSelectView:(NSNotification *)notification {
	NSLog(@"actionSelectView");
    int row;
    row = [tableView selectedRow];
    if (row == -1) {
		return;
	}
	NSLog(@"selected row = %d", row);
	[self setTableColumeAttribute:row];
}

- (IBAction)checkoutTrades:(id)sender
{
    NSLog(@"checkoutTrades");
    /*
	NSDateFormatter	*dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%y/%m/%d" allowNaturalLanguage:NO];
	NSString *dateString;
	[tableView deselectAll:sender];
	for (TradeItem *item in trades) {
		dateString = [[dateFormatter stringFromDate:[item date]] retain];
		// NSLog(@"kind=%@ date=%@",[item kind],dateString);
		if ([item tradeTypeToType:[item kind]] == TRADE_ITEM_TYPE_I_ESTIMATE) {
			if ([item buy] != 0 || [item sell] != 0 || [item charge] != 0 || [item dividend] != 0 || [item tax] != 0) {
				NSLog(@"following items shul'd be zero: buy,sell,charge,dividend,tax (%@ %@)",[item kind],dateString);
			}
		} else if ([item tradeTypeToType:[item kind]] == TRADE_ITEM_TYPE_I_BUY ||
				   [item tradeTypeToType:[item kind]] == TRADE_ITEM_TYPE_I_REINVESTMENT) {
			if ([item sell] != 0) {
				NSLog(@"following items shul'd be zero: sell (%@ %@)",[item kind],dateString);
			}
			if ([item buy] == 0) {
				NSLog(@"buy is zero (%@ %@)",[item kind],[item date]);
			}
		} else if ([item tradeTypeToType:[item kind]] == TRADE_ITEM_TYPE_I_SELL) {
			if ([item buy] != 0 || [item dividend] != 0) {
				NSLog(@"following items shul'd be zero: buy,dividend (%@ %@)",[item kind],dateString);
			}
			if ([item sell] == 0) {
				NSLog(@"sell is zero (%@ %@)",[item kind],dateString);
			}
		} else if ([item tradeTypeToType:[item kind]] == TRADE_ITEM_TYPE_I_DIVIDEND) {
			if ([item buy] != 0 || [item sell] != 0 || [item charge] != 0) {
				NSLog(@"following items shul'd be zero: buy,sell,charge (%@ %@)",[item kind],dateString);
			}
			if ([item dividend] == 0) {
				NSLog(@"dividend is zero (%@ %@)",[item kind],dateString);
			}
		} else if ([item tradeTypeToType:[item kind]] == TRADE_ITEM_TYPE_I_SPLIT) {
			if ([item dividend] != 0) {
				NSLog(@"following items shul'd be zero: dividend (%@ %@)",[item kind],dateString);
			}
		}
		[dateString release];
		dateString = nil;
	}
	[dateFormatter release];
     */
	[tableView deselectAll:self];
	[portfolioItem DoSettlement];
	[self rearrangeDocument];
}

- (IBAction)undoTradeItem:(id)sender
{
	NSLog(@"undoTradeItem");
	NSUndoManager *undo = [doc undoManager];
	if ([undo canUndo]) {
		[undo undo];
	}
	[self setEnabledButtons];
    [tradeController rearrangeObjects];
}

- (IBAction)redoTradeItem:(id)sender
{
	NSLog(@"redoTradeItem");
	NSUndoManager *undo = [doc undoManager];
	if ([undo canRedo]) {
		[undo redo];
	}
	[self setEnabledButtons];
    [tradeController rearrangeObjects];
}

- (IBAction)addDeposit:(id)sender
{
    NSLog(@"addDeposit");
    if (enableDataInputSheet == YES) {
        [self showTradeSheet:sender];
    } else {
        [self createTradeItem:NSLocalizedString(@"DEPOSIT",@"Deposit"):nil];
    }
}

- (IBAction)addWithdraw:(id)sender
{
    NSLog(@"addWithdraw");
    if (enableDataInputSheet == YES) {
        [self showTradeSheet:sender];
    } else {
        [self createTradeItem:NSLocalizedString(@"WITHDRAW",@"Withdraw"):nil];
    }
}

- (IBAction)addInterest:(id)sender
{
    NSLog(@"addInterest");
	[self createTradeItem:NSLocalizedString(@"DEPOSIT",@"Deposit"):NSLocalizedString(@"INTEREST",@"Interest")];
}

- (void)setTableColumeAttribute:(int)row
{
	NSLog(@"    row = %d", row);
	if (row < 0) {
		return;
	}
	[tradeController rearrangeObjects];
	TradeItem *item = [trades objectAtIndex:row];
	NSTableColumn *column = nil;
	if ([item tradeTypeToType:[item kind]] == TRADE_ITEM_TYPE_I_DEPOSIT ||
        [item tradeTypeToType:[item kind]] == TRADE_ITEM_TYPE_I_INTEREST) {
		column = [tableView  tableColumnWithIdentifier:@"deposit"];
		[column setEditable:YES];
		column = [tableView  tableColumnWithIdentifier:@"withdraw"];
		[column setEditable:NO];
    } else if ([item tradeTypeToType:[item kind]] == TRADE_ITEM_TYPE_I_WITHDRAW) {
		column = [tableView  tableColumnWithIdentifier:@"deposit"];
		[column setEditable:NO];
		column = [tableView  tableColumnWithIdentifier:@"withdraw"];
		[column setEditable:YES];
    }
}

- (void)setFontColor:(NSColor*)color
{
	NSTableColumn *column = nil;
	NSLog(@"setFontColor");
	
	// set font color of tableView
	column = [tableView  tableColumnWithIdentifier:@"type"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"date"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"deposit"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"balance"];
	[(id)[column dataCell] setTextColor:color];
    column = [tableView  tableColumnWithIdentifier:@"balance"];
    [(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"withdraw"];
	[(id)[column dataCell] setTextColor:color];
	[tableView reloadData];
}

- (IBAction)showTradeSheet:(id)sender
{
    NSLog(@"showPerformanceSheet");
    NSString* lang = NSLocalizedString(@"LANG",@"English");
    [tradeDatePicker setDateValue: [datePicker dateValue]];
    [tradeValueField setDoubleValue:0];
    [tradeCommentField setHidden:YES];
    [tradeCommentField setHidden:NO];
    [tradeCommentField setStringValue:@""];
    [tradeOk setTitle:NSLocalizedString(@"OK",@"Ok")];
    [tradeCancel setTitle:NSLocalizedString(@"CANCEL",@"Cancel")];
    if ([lang isEqualToString:@"Japanese"]) {
        [tradeDateLabel setStringValue:@"日付"];
        [tradeCommentLabel setStringValue:@"メモ"];
    } else {
        [tradeDateLabel setStringValue:@"Date"];
        [tradeCommentLabel setStringValue:@"Memo"];
    }
    if (sender == depositButton) {
        if ([lang isEqualToString:@"Japanese"]) {
            [tradeText setStringValue:@"入金額を入力してください"];
            [tradeValueLabel setStringValue:@"入金額:"];
        } else {
            [tradeText setStringValue:@"Please input the amount of deposit."];
            [tradeValueLabel setStringValue:@"Deposit:"];
        }
    } else if (sender == withdrawButton) {
        if ([lang isEqualToString:@"Japanese"]) {
            [tradeText setStringValue:@"出金額を入力してください"];
            [tradeValueLabel setStringValue:@"出金額:"];
        } else {
            [tradeText setStringValue:@"Please input the amount of withdrawal."];
            [tradeValueLabel setStringValue:@"Withdraw:"];
        }
    } else {
        NSBeep();
        return;
    }
    tradeSender = sender;
    [NSApp beginSheet:tradeSheet
       modalForWindow:win
        modalDelegate:nil
       didEndSelector:NULL
          contextInfo:NULL];
    return;
}

- (IBAction)endTradeSheet:(id)sender
{
    NSLog(@"endPerformanceSheet");
    [NSApp endSheet:tradeSheet];
    [tradeSheet orderOut:sender];
    if (sender == tradeCancel) {
        return;
    }
    double tradeValue = [tradeValueField doubleValue];
    double tradeDeposit = 0;
    double tradeWithdraw = 0;
    NSString*   tradeType = nil;
    if (tradeSender == depositButton) {
        tradeDeposit = tradeValue;
        tradeType = [[NSString alloc] initWithString:NSLocalizedString(@"DEPOSIT",@"Deposit")];
    } else if (tradeSender == withdrawButton) {
        tradeWithdraw = tradeValue;
        tradeType = [[NSString alloc] initWithString:NSLocalizedString(@"WITHDRAW",@"Withdraw")];
    } else {
        NSBeep();
        [tradeType release];
        return;
    }
    [self createTradeItemWithValue:tradeType
                            deposit:tradeDeposit
                          withdraw:tradeWithdraw
                           comment:[tradeCommentField stringValue]];
    [tradeType release];
    return;
}

#pragma mark Localizer

- (void) localizeView
{
	NSLog(@"localizeView");
	NSTableColumn *column = nil;
	NSString* lang = NSLocalizedString(@"LANG",@"English");
	NSLog(@"localizeView: %@", lang);
	if ([lang isEqualToString:@"Japanese"]) {
		[labelBalance setStringValue:@"残高 :"];
		[depositButton setTitle:@"入金"];
		[withdrawButton setTitle:@"出金"];
		[interestButton setTitle:@"金利"];
		[checkoutButton setTitle:@"計算する"];
		[deleteButton setTitle:@"削除"];
		[undoButton setTitle:@"取消し"];
		[redoButton setTitle:@"やり直し"];
		column = [tableView  tableColumnWithIdentifier:@"type"];
		[[column headerCell] setStringValue:@"種別"];
		column = [tableView  tableColumnWithIdentifier:@"date"];
		[[column headerCell] setStringValue:@"日付"];
		column = [tableView  tableColumnWithIdentifier:@"deposit"];
		[[column headerCell] setStringValue:@"入金額"];
		column = [tableView  tableColumnWithIdentifier:@"withdraw"];
		[[column headerCell] setStringValue:@"出金額"];
		column = [tableView  tableColumnWithIdentifier:@"balance"];
		[[column headerCell] setStringValue:@"残高"];
		column = [tableView  tableColumnWithIdentifier:@"memo"];
		[[column headerCell] setStringValue:@"メモ"];
    }
}

@synthesize		portfolioItem;
@synthesize     parentDoc;
@synthesize		trades;
@synthesize		win;
@synthesize		tableView;
@end
