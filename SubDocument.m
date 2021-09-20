//
//  SubDocument.m
//  tPortfolio
//
//  Created by Takahiro Sayama on 10/12/12.
//  Copyright 2011 tanuki-project. All rights reserved.
//

#import		"SubDocument.h"
#import		"PortfolioItem.h"
#import		"MyDocument.h"
#include	"AppController.h"

extern	AppController	*tPrtController;
extern	PortfolioItem	*tPrtPortfolioItem;
extern  bool            enableDataInputSheet;

@interface SubDocument ()
- (void)startObservingTrades:(TradeItem *)item;
- (void)stopObservingTrades:(TradeItem *)item;
@end

@implementation SubDocument

- (id)init
{
	NSLog(@"init SubDocument");
    self = [super initWithWindowNibName:@"SubDocument"];
	if (self == nil) {
		return nil;
	}
	portfolioItem = tPrtPortfolioItem;
	trades = [portfolioItem trades];
	doc = [[NSDocument alloc] init];
	[[self window] setTitle:[portfolioItem itemName]];
    parentDoc = nil;
    clickCnt = 0;
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
	NSLog(@"dealloc SubDocument");
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
	NSLog(@"Close: SubDocument");
#ifdef NO_AUTOSAVE
	[win saveFrameUsingName:tPrtSubWindowFrameKey];
#endif
	[super close];
}

- (void)windowDidLoad
{
	NSLog(@"Nib file is loaded %@", [portfolioItem itemName]);
	[datePicker setDateValue:[NSDate date]];
	[self setEnabledButtons];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *colorAsData;
	colorAsData = [defaults objectForKey:tPrtTableBgColorKey];
	//[tableView setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];
	[tableView setBackgroundColor:[NSKeyedUnarchiver unarchiveObjectWithData:colorAsData]];
	colorAsData = [defaults objectForKey:tPrtTableFontColorKey];
	[self setFontColor:[NSKeyedUnarchiver unarchiveObjectWithData:colorAsData]];
	if ([defaults boolForKey:tPrtTradeDetailKey] == YES) {
		[self setHiddenColumn:NO];
		[checkDetail setState:NSOnState];
	} else {
		[self setHiddenColumn:YES];
		[checkDetail setState:NSOffState];
	}
#ifdef NO_AUTOSAVE
	[win setFrameUsingName:tPrtSubWindowFrameKey];
#endif
	[self localizeView];
	int row = [tableView selectedRow];
	if (row != -1) {
		[self setTableColumeAttribute:row];
	}
	[[self priceField] setDoubleValue:[portfolioItem price]];
	[[self averageField] setDoubleValue:[portfolioItem av_price]];
	[[self quantityField] setDoubleValue:[portfolioItem quantity]];
	[[self investedField] setDoubleValue:[portfolioItem investment]];
	[[self estimatedField] setDoubleValue:[portfolioItem value]];
	double performanceValue = 0;
	if ([portfolioItem investment]) {
		// NSLog(@"windowDidLoad: credit = %d",[portfolioItem credit]);
		if ([portfolioItem credit] == TRADE_TYPE_SHORTSELL) {
			performanceValue = (1 - [portfolioItem value]/[portfolioItem investment])*100;
		} else {
			performanceValue = ([portfolioItem value]/[portfolioItem investment] - 1)*100;
		}
	}
	[[self performanceField] setStringValue:[NSString stringWithFormat:@"%.2f",performanceValue]];
	[[self latentGainField] setDoubleValue:[portfolioItem lproperty]];
	[[self capitalGainField] setDoubleValue:[portfolioItem profit]];
	[[self incomeGainField] setDoubleValue:[portfolioItem income]];
	[[self totalGainField] setDoubleValue:[portfolioItem lproperty]+[portfolioItem profit]+[portfolioItem income]];
	[targetStepper setDoubleValue:[portfolioItem yieldTarget]*100];
	[lossCutStepper setDoubleValue:[portfolioItem lossCutLimit]*100];
	[targetForm selectTextAtIndex:0];
	if ([portfolioItem yieldTarget] == 0) {
		[targetForm setStringValue:@""];
	} else {
		[targetForm setDoubleValue:[portfolioItem yieldTarget]];
	}
	[targetForm selectTextAtIndex:1];
	if ([portfolioItem lossCutLimit] == 0) {
		[targetForm setStringValue:@""];
	} else {
		[targetForm setDoubleValue:[portfolioItem lossCutLimit]];
	}
	[targetForm setEnabled:NO];
	[targetForm setEnabled:YES];
	[self setTargetFlag];
}

#pragma mark Actions

-(void)actionClose:(NSNotification *)notification {
	NSLog(@"actionClose");
	[portfolioItem DoSettlement];
#ifdef NO_AUTOSAVE
	[win saveFrameUsingName:tPrtSubWindowFrameKey];
#endif
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

#pragma mark Accesser

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
	[[undo prepareWithInvocationTarget:self]
		removeObjectFromTradesAtIndex:index];
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
	[self setEnabledButtons];
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
	// NSLog(@"startObservingTrades: %@", item);
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
	// NSLog(@"stopObservingTrades: %@", item);
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

- (void)setTableColumeAttribute:(int)row
{
	NSLog(@"setTableColumeAttribute row = %d", row);
	if (row < 0) {
		return;
	}
	[tradeController rearrangeObjects];
	TradeItem *item = [trades objectAtIndex:row];
	NSTableColumn *column = nil;
	if ([item tradeTypeToType:[item kind]] == TRADE_ITEM_TYPE_I_ESTIMATE) {
		column = [tableView  tableColumnWithIdentifier:@"buy"];
		[column setEditable:NO];
		column = [tableView  tableColumnWithIdentifier:@"sell"];
		[column setEditable:NO];
		column = [tableView  tableColumnWithIdentifier:@"dividend"];
		[column setEditable:NO];
		column = [tableView  tableColumnWithIdentifier:@"charge"];
		[column setEditable:NO];
		column = [tableView  tableColumnWithIdentifier:@"tax"];
		[column setEditable:NO];
	} else {
		column = [tableView  tableColumnWithIdentifier:@"charge"];
		[column setEditable:YES];
		column = [tableView  tableColumnWithIdentifier:@"tax"];
		[column setEditable:YES];
		if ([item tradeTypeToType:[item kind]] == TRADE_ITEM_TYPE_I_DIVIDEND) {
			column = [tableView  tableColumnWithIdentifier:@"buy"];
			[column setEditable:NO];
			column = [tableView  tableColumnWithIdentifier:@"sell"];
			[column setEditable:NO];
			column = [tableView  tableColumnWithIdentifier:@"dividend"];
			[column setEditable:YES];
		} else if ([item tradeTypeToType:[item kind]] == TRADE_ITEM_TYPE_I_BUY ||
				   [item tradeTypeToType:[item kind]] == TRADE_ITEM_TYPE_I_REINVESTMENT) {
			column = [tableView  tableColumnWithIdentifier:@"buy"];
			[column setEditable:YES];
			column = [tableView  tableColumnWithIdentifier:@"sell"];
			[column setEditable:NO];
			column = [tableView  tableColumnWithIdentifier:@"dividend"];
			[column setEditable:YES];
		} else if ([item tradeTypeToType:[item kind]] == TRADE_ITEM_TYPE_I_SELL) {
			column = [tableView  tableColumnWithIdentifier:@"buy"];
			[column setEditable:NO];
			column = [tableView  tableColumnWithIdentifier:@"sell"];
			[column setEditable:YES];
			column = [tableView  tableColumnWithIdentifier:@"dividend"];
			[column setEditable:NO];
		} else if ([item tradeTypeToType:[item kind]] == TRADE_ITEM_TYPE_I_SPLIT) {
			column = [tableView  tableColumnWithIdentifier:@"buy"];
			[column setEditable:YES];
			column = [tableView  tableColumnWithIdentifier:@"sell"];
			[column setEditable:YES];
			column = [tableView  tableColumnWithIdentifier:@"dividend"];
			[column setEditable:NO];
		}
	}
}

- (void)setEnabledButtons
{
	NSUndoManager *undo = [doc undoManager];
	if ([undo canUndo]) {
		[undoButon setEnabled:YES];
	} else {
		[undoButon setEnabled:NO];
	}
	if ([undo canRedo]) {
		[redoButon setEnabled:YES];
	} else {
		[redoButon setEnabled:NO];
	}
	if ([trades count] == 0) {
		[checkButon setEnabled:NO];
		[deleteButton setEnabled:NO];
	} else {
		[checkButon setEnabled:YES];
		[deleteButton setEnabled:YES];
	}
}

- (void)setHiddenColumn:(bool)hidden
{
	NSTableColumn *column = nil;
	//column = [tableView  tableColumnWithIdentifier:@"settlement"];
	//[column setHidden:hidden];
	//[column setWidth:60];
	//column = [tableView  tableColumnWithIdentifier:@"profit"];
	//[column setHidden:hidden];
	//[column setWidth:60];
	column = [tableView  tableColumnWithIdentifier:@"average"];
	[column setHidden:hidden];
	[column setWidth:72];
	column = [tableView  tableColumnWithIdentifier:@"quantity"];
	[column setHidden:hidden];
	[column setWidth:60];
	column = [tableView  tableColumnWithIdentifier:@"investment"];
	[column setHidden:hidden];
	[column setWidth:72];
	column = [tableView  tableColumnWithIdentifier:@"value"];
	[column setHidden:hidden];
	[column setWidth:72];
	column = [tableView  tableColumnWithIdentifier:@"latent"];
	[column setHidden:hidden];
	[column setWidth:72];
	[tradeController rearrangeObjects];
}

- (void)setTargetFlag
{
	NSImage *template;
	NSString *path = [[NSString alloc] initWithFormat:@"Marker%@",[portfolioItem flagColor]];
	template = [NSImage imageNamed:path];
	if (template) {
		[flagImage setImage:template];
	}
	[path release];
}

- (void)rearrangeDocument
{
	[tradeController rearrangeObjects];
    if (parentDoc) {
        [parentDoc rearrangeDocument];
    }
	[[self priceField] setDoubleValue:[portfolioItem price]];
	[[self averageField] setDoubleValue:[portfolioItem av_price]];
	[[self quantityField] setDoubleValue:[portfolioItem quantity]];
	[[self investedField] setDoubleValue:[portfolioItem investment]];
	[[self estimatedField] setDoubleValue:[portfolioItem value]];
	double performanceValue = 0;
	if ([portfolioItem investment]) {
		// NSLog(@"rearrangeDocument: credit = %d",[portfolioItem credit]);
		if ([portfolioItem credit] == TRADE_TYPE_SHORTSELL) {
			performanceValue = (1 - [portfolioItem value]/[portfolioItem investment])*100;
		} else {
			performanceValue = ([portfolioItem value]/[portfolioItem investment] - 1)*100;
		}
	}
	[[self performanceField] setStringValue:[NSString stringWithFormat:@"%.2f",performanceValue]];
	[[self latentGainField] setDoubleValue:[portfolioItem lproperty]];
	[[self capitalGainField] setDoubleValue:[portfolioItem profit]];
	[[self incomeGainField] setDoubleValue:[portfolioItem income]];
	[[self totalGainField] setDoubleValue:[portfolioItem lproperty]+[portfolioItem profit]+[portfolioItem income]];
	[targetForm selectTextAtIndex:0];
	[targetForm setDoubleValue:[portfolioItem yieldTarget]];
	[targetForm selectTextAtIndex:1];
	[targetForm setDoubleValue:[portfolioItem lossCutLimit]];
	[targetForm setEnabled:NO];
	[targetForm setEnabled:YES];
	[self setTargetFlag];
}

#pragma mark Actions

- (IBAction)checkoutTrades:(id)sender
{
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
	[tableView deselectAll:self];
	[portfolioItem DoSettlement];
	[self rearrangeDocument];
}

- (void)createTradeItem:(NSString*)type
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

- (void)createTradeItemWithValue:(NSString*)type
                           price:(double)price
                          bought:(double)bought
                            sold:(double)sold
                          charge:(double)charge
                             tax:(double)tax
                          income:(double)income
                         comment:(NSString*)comment
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
                                          fromDate:[tradeDatePicker dateValue]];
    [t setDate: [calendar dateFromComponents:compo]];
    [calendar release];
    if (type) {
        [t setKind:type];
    }
    if (comment) {
        [t setComment:comment];
    }
    [t setPrice:price];
    [t setBuy:bought];
    [t setSell:sold];
    [t setCharge:charge];
    [t setTax:tax];
    [t setDividend:income];
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

- (IBAction)addBuy:(id)sender
{
	if ([portfolioItem credit] == TRADE_TYPE_SHORTSELL) {
		double	sold =0;
		for (TradeItem* trade in [portfolioItem trades]) {
			sold += [trade sell];
		}
		if (sold == 0) {
			NSLog(@"addBuy : Can't buy");
			NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
											 defaultButton:NSLocalizedString(@"OK",@"Ok")
										   alternateButton:nil
											   otherButton:nil
								 informativeTextWithFormat:NSLocalizedString(@"NOT_HOLD",@"You don't hold this item not yet.")];
			[alert beginSheetModalForWindow:[self win] modalDelegate:self didEndSelector:nil contextInfo:nil];
			return;
		}
	}
    if (enableDataInputSheet == YES) {
        [self showTradeSheet:sender];
    } else {
        [self createTradeItem:NSLocalizedString(@"BUY",@"Buy")];
    }
}

- (IBAction)addSell:(id)sender
{
	if ([portfolioItem credit] != TRADE_TYPE_SHORTSELL) {
		double	bought =0;
		for (TradeItem* trade in [portfolioItem trades]) {
			bought += [trade buy];
		}
		if (bought == 0) {
			NSLog(@"addBuy : Can't sell");
			NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
											 defaultButton:NSLocalizedString(@"OK",@"Ok")
										   alternateButton:nil
											   otherButton:nil
								 informativeTextWithFormat:NSLocalizedString(@"NOT_HOLD",@"You don't hold this item not yet.")];
			[alert beginSheetModalForWindow:[self win] modalDelegate:self didEndSelector:nil contextInfo:nil];
			return;
		}
	}
    if (enableDataInputSheet == YES) {
        [self showTradeSheet:sender];
    } else {
        [self createTradeItem:NSLocalizedString(@"SELL",@"Sell")];
    }
}

- (IBAction)addDividend:(id)sender
{
	double	bought =0;
	double	sold =0;
	for (TradeItem* trade in [portfolioItem trades]) {
		bought += [trade buy];
		sold += [trade sell];
	}
	if (bought == 0 && sold == 0) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"NOT_HOLD",@"You don't hold this item not yet.")];
		[alert beginSheetModalForWindow:[self win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
    if (enableDataInputSheet == YES) {
        [self showTradeSheet:sender];
    } else {
        [self createTradeItem:NSLocalizedString(@"DIVIDEND",@"Dividend")];
    }
}

- (IBAction)addSplit:(id)sender
{
	double	bought =0;
	double	sold =0;
	for (TradeItem* trade in [portfolioItem trades]) {
		bought += [trade buy];
		sold += [trade sell];
	}
	if (bought == 0 && sold == 0) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"NOT_HOLD",@"You don't hold this item not yet.")];
		[alert beginSheetModalForWindow:[self win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
    if (enableDataInputSheet == YES) {
        [self showTradeSheet:sender];
    } else {
        [self createTradeItem:NSLocalizedString(@"SPLIT",@"Split")];
    }
}

- (IBAction)addAccount:(id)sender
{
    if (enableDataInputSheet == YES) {
        [self showTradeSheet:sender];
    } else {
        [self createTradeItem:NSLocalizedString(@"NOTE",@"Note")];
    }
}

- (IBAction)checkDetail:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([checkDetail state] == NSOnState) {
		[self setHiddenColumn:NO];
		[defaults setBool:YES forKey:tPrtTradeDetailKey];		
	} else {
		[self setHiddenColumn:YES];
		[defaults setBool:NO forKey:tPrtTradeDetailKey];		
	}
}

- (IBAction)clickImage:(id)sender
{
    NSLog(@"clickImage");
    if (parentDoc == nil) {
        return;
    }
    [[parentDoc win] orderFront:self];
    [[self win] orderFront:self];
    long row = [[parentDoc portfolioArray] indexOfObject:portfolioItem];
    if (row == -1) {
        return;
    }
    // reset selected row
    NSIndexSet* ixset = [NSIndexSet indexSetWithIndex:row];
    [[parentDoc tableView] selectRowIndexes:ixset byExtendingSelection:NO];
    [[parentDoc tableView] scrollRowToVisible:row];
    if ((clickCnt % 3) == 1) {
        [parentDoc goToPortalSite:self];
    } else if ((clickCnt % 3) == 2) {
        if ([[portfolioItem url] isEqualToString:@""] == YES ||
            [[portfolioItem url] isEqual:INITIAL_IR_SITE] == YES) {
            clickCnt++;
            [parentDoc goToYahooFinance:self];
        } else {
            [parentDoc goToIRSite:self];
        }
    } else {
        [parentDoc goToYahooFinance:self];
    }
    clickCnt++;
}

- (IBAction)changePrice:(id)sender
{
    NSLog(@"changePrice: %@", [priceField stringValue]);
	double price = [priceField doubleValue];
	[priceField setEnabled:NO];
	if ([portfolioItem price] != price) {
		[portfolioItem setPrice:price];
		if (parentDoc) {
			[parentDoc setPortfolioEdited];
		}
	}
	[priceField setEnabled:YES];
}

- (IBAction)changeYieldTarget:(id)sender
{
	static bool changed = NO;
	NSLog(@"changeYieldTarget: %0.1f", [targetStepper doubleValue]);
	[portfolioItem setYieldTarget:[targetStepper doubleValue]/100];
	[targetForm selectTextAtIndex:0];
	if ([portfolioItem yieldTarget] == 0) {
		[targetForm setStringValue:@""];
	} else {
		stepperEdited = YES;
		[targetForm setDoubleValue:[portfolioItem yieldTarget]];
	}
	if (parentDoc) {
		if (changed == NO) {
			changed = YES;
			[parentDoc setPortfolioEdited];
		}
	}
}


- (IBAction)changeLossCutLimit:(id)sender
{
	static bool	changed = NO;
	NSLog(@"changeLossCutLimit: %0.1f", [lossCutStepper doubleValue]);
	[portfolioItem setLossCutLimit:[lossCutStepper doubleValue]/100];
	[targetForm selectTextAtIndex:1];
	if ([portfolioItem lossCutLimit] == 0) {
		[targetForm setStringValue:@""];
	} else {
		stepperEdited = YES;
		[targetForm setDoubleValue:[portfolioItem lossCutLimit]];
	}
	if (parentDoc) {
		if (changed == NO) {
			changed = YES;
			[parentDoc setPortfolioEdited];
		}
	}
}

- (IBAction)changeTargetForm:(id)sender {
	static	bool changed = NO;
	long	index = [targetForm indexOfSelectedItem];
	double	value = round([targetForm doubleValue]*1000)/1000;
	if (stepperEdited == YES) {
		stepperEdited = NO;
		NSLog(@"changeTargetForm: stepper changed.");
		return;
	}
	NSLog(@"changeTargetForm: %lu %0.1f", index, value);
	if (index == 0) {
		double max = YIELD_TARGET_MAX;
		double min = YIELD_TARGET_MIN;
		if (value != [portfolioItem yieldTarget]) {
			if (value > max) {
				[targetForm setDoubleValue:[portfolioItem yieldTarget]];
			} else if (value < min) {
				[targetForm setDoubleValue:[portfolioItem yieldTarget]];
			} else {
				NSLog(@"yieldTarget edited: %0.3f", value);
				[portfolioItem setYieldTarget:value];
				[targetStepper setDoubleValue:value*100];
				if (parentDoc) {
					if (changed == NO) {
						changed = YES;
						[parentDoc setPortfolioEdited];
					}
				}
			}
		}
	} else if (index == 1) {
		double max = LOSSCUT_LIMIT_MAX;
		double min = LOSSCUT_LIMIT_MIN;
		if (value != [portfolioItem lossCutLimit]) {
			if (value > max) {
				[targetForm setDoubleValue:[portfolioItem lossCutLimit]];
			} else if (value < min) {
				[targetForm setDoubleValue:[portfolioItem lossCutLimit]];
			} else {
				NSLog(@"lossCutLimit edited: %0.3f", value);
				[portfolioItem setLossCutLimit:value];
				[lossCutStepper setDoubleValue:value*100];
				if (parentDoc) {
					if (changed == NO) {
						changed = YES;
						[parentDoc setPortfolioEdited];
					}
				}
			}
		}
	}
}


- (void)setFontColor:(NSColor*)color
{
	NSTableColumn *column = nil;
	NSLog(@"setFontColor");
	
	// set font color of tableView
	column = [tableView  tableColumnWithIdentifier:@"index"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"type"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"date"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"memo"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"price"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"buy"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"sell"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"dividend"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"charge"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"tax"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"settlement"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"profit"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"average"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"quantity"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"investment"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"value"];
	[(id)[column dataCell] setTextColor:color];
	column = [tableView  tableColumnWithIdentifier:@"latent"];
	[(id)[column dataCell] setTextColor:color];
	[tableView reloadData];
}

- (IBAction)showTradeSheet:(id)sender
{
    NSLog(@"showPerformanceSheet");
    NSString* lang = NSLocalizedString(@"LANG",@"English");
    //NSLog(@"localizeView: %@", lang);
    NSRect frame = [tradeSheet frame];
    // NSLog(@"frame size = %f, %f", frame.size.height, frame.size.width);
    if (frame.size.height < TRADE_SHEET_HIGHT_MAX) {
        frame.size.height = TRADE_SHEET_HIGHT_MAX;
    }
    [tradeDatePicker setDateValue: [datePicker dateValue]];
    [tradePriceField setDoubleValue:[portfolioItem price]];
    [tradeValueField1st setDoubleValue:0];
    [tradeValueField2nd setDoubleValue:0];
    [tradeValueField3rd setDoubleValue:0];
    [tradeCheckBox setHidden:YES];
    [tradeValueField2nd setEnabled:YES];
    [tradeValueField3rd setEnabled:YES];
    [tradeCheckBox setHidden:YES];
    [tradeValueField1st setHidden:YES];
    [tradeValueField2nd setHidden:YES];
    [tradeValueField3rd setHidden:YES];
    [tradePriceField setHidden:YES];
    [tradePriceField setHidden:NO];
    [tradeCommentField setHidden:YES];
    [tradeCommentField setHidden:NO];
    [tradeOk setTitle:NSLocalizedString(@"OK",@"Ok")];
    [tradeCancel setTitle:NSLocalizedString(@"CANCEL",@"Cancel")];
    [tradeSettlementField setDoubleValue:0];
    [tradeCheckBox setState:NSOffState];
    [tradeCommentField setStringValue:@""];
    if ([lang isEqualToString:@"Japanese"]) {
        [tradeDateLabel setStringValue:@"日付"];
        [tradePriceLabel setStringValue:@"取引値"];
        [tradeCommentLabel setStringValue:@"メモ"];
        [tradeSettlementLabel setStringValue:@"決済額"];
    } else {
        [tradeDateLabel setStringValue:@"Date"];
        [tradePriceLabel setStringValue:@"Price"];
        [tradeCommentLabel setStringValue:@"Memo"];
        [tradeSettlementLabel setStringValue:@"Settlement"];
    }
    if (sender == buyButon) {
        [tradeCheckBox setHidden:NO];
        [tradeValueLabel1st setHidden:NO];
        [tradeValueField1st setHidden:NO];
        [tradeValueLabel2nd setHidden:NO];
        [tradeValueField2nd setHidden:NO];
        [tradeValueLabel3rd setHidden:NO];
        [tradeValueField3rd setHidden:NO];
        [tradeValueField3rd setEnabled:NO];
        if ([lang isEqualToString:@"Japanese"]) {
            [tradeCheckBox setTitle:@"再投資"];
            [tradeText setStringValue:@"取引価格と買付数と手数料を入力してください"];
            [tradeValueLabel1st setStringValue:@"買付数:"];
            [tradeValueLabel2nd setStringValue:@"手数料:"];
            [tradeValueLabel3rd setStringValue:@"配当・分売金:"];
        } else {
            [tradeCheckBox setTitle:@"Reinvestment"];
            [tradeText setStringValue:@"Please input the price and the number of purchase and charge."];
            [tradeValueLabel1st setStringValue:@"Quantity:"];
            [tradeValueLabel2nd setStringValue:@"Charge:"];
            [tradeValueLabel3rd setStringValue:@"Income:"];
        }
    } else if (sender == sellButon) {
        [tradeValueLabel1st setHidden:NO];
        [tradeValueField1st setHidden:NO];
        [tradeValueLabel2nd setHidden:NO];
        [tradeValueField2nd setHidden:NO];
        [tradeValueLabel3rd setHidden:NO];
        [tradeValueField3rd setHidden:NO];
        if ([lang isEqualToString:@"Japanese"]) {
            [tradeText setStringValue:@"取引価格と売付数と手数料、納税額を入力してください"];
            [tradeValueLabel1st setStringValue:@"売付数:"];
            [tradeValueLabel2nd setStringValue:@"手数料:"];
            [tradeValueLabel3rd setStringValue:@"納税額:"];
        } else {
            [tradeText setStringValue:@"Please input the number of sold with the price and the charge, tax."];
            [tradeValueLabel1st setStringValue:@"Quantity:"];
            [tradeValueLabel2nd setStringValue:@"Charge:"];
            [tradeValueLabel3rd setStringValue:@"Tax:"];
        }
    } else if (sender == dividendButon) {
        [tradeValueLabel1st setHidden:NO];
        [tradeValueField1st setHidden:NO];
        [tradeValueLabel2nd setHidden:NO];
        [tradeValueField2nd setHidden:NO];
        [tradeValueLabel3rd setHidden:YES];
        [tradeValueField3rd setHidden:YES];
        if ([lang isEqualToString:@"Japanese"]) {
            [tradeText setStringValue:@"配当・分配支払日の価格と配当・分配額、納税額を入力してください"];
            [tradeValueLabel1st setStringValue:@"配当・分売金:"];
            [tradeValueLabel2nd setStringValue:@"納税額:"];
        } else {
            [tradeText setStringValue:@"Please input the price and dividend income and tax."];
            [tradeValueLabel1st setStringValue:@"Income:"];
            [tradeValueLabel2nd setStringValue:@"Tax:"];
        }
    } else if (sender == splitButon) {
        [tradeCheckBox setHidden:NO];
        [tradeValueLabel1st setHidden:NO];
        [tradeValueField1st setHidden:NO];
        [tradeValueLabel2nd setHidden:YES];
        [tradeValueField2nd setHidden:YES];
        [tradeValueLabel3rd setHidden:YES];
        [tradeValueField3rd setHidden:YES];
        if ([lang isEqualToString:@"Japanese"]) {
            [tradeCheckBox setTitle:@"株式併合"];
            [tradeText setStringValue:@"株式分割により増加した株数と分割後の価格を入力してください"];
            [tradeValueLabel1st setStringValue:@"数量:"];
        } else {
            [tradeCheckBox setTitle:@"Reverse Split"];
            [tradeText setStringValue:@"Please input the price and number of increased by stock split."];
            [tradeValueLabel1st setStringValue:@"Quantity:"];
        }
        frame.size.height -= TRADE_SHEET_HIGHT_OFFSET;
    } else if (sender == estimateButon) {
        [tradeValueLabel1st setHidden:YES];
        [tradeValueField1st setHidden:YES];
        [tradeValueLabel2nd setHidden:YES];
        [tradeValueField2nd setHidden:YES];
        [tradeValueLabel3rd setHidden:YES];
        [tradeValueField3rd setHidden:YES];
        if ([lang isEqualToString:@"Japanese"]) {
            [tradeText setStringValue:@"価格を記録しますか?"];
        } else {
            [tradeText setStringValue:@"Dou you record the price?"];
        }
        frame.size.height -= TRADE_SHEET_HIGHT_OFFSET;
    } else {
        NSBeep();
        return;
    }
    tradeSender = sender;
    [tradeSheet setFrame:frame display:YES];
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
    double tradePrice = [tradePriceField doubleValue];
    double tradeBought = 0;
    double tradeSold = 0;
    double tradeCharge = 0;
    double tradeTax = 0;
    double tradeIncome = 0;
    NSString*   tradeType = nil;
    if (tradeSender == buyButon) {
        tradeType = [[NSString alloc] initWithString:NSLocalizedString(@"BUY",@"Buy")];
        tradeBought = [tradeValueField1st doubleValue];
        tradeCharge = [tradeValueField2nd doubleValue];
        tradeIncome = [tradeValueField3rd doubleValue];
    } else if (tradeSender == sellButon) {
        tradeType = [[NSString alloc] initWithString:NSLocalizedString(@"SELL",@"Sell")];
        tradeSold = [tradeValueField1st doubleValue];
        tradeCharge = [tradeValueField2nd doubleValue];
        tradeTax = [tradeValueField3rd doubleValue];
    } else if (tradeSender == dividendButon) {
        tradeType = [[NSString alloc] initWithString:NSLocalizedString(@"DIVIDEND",@"Dividend")];
        tradeIncome = [tradeValueField1st doubleValue];
        tradeTax = [tradeValueField2nd doubleValue];
    } else if (tradeSender == splitButon) {
        tradeType = [[NSString alloc] initWithString:NSLocalizedString(@"SPLIT",@"Split")];
        tradeBought = [tradeValueField1st doubleValue];
        if ([tradeCheckBox state] == NSOnState) {
            // Reverse stock split
            tradeSold = tradeBought;
            tradeBought = 0;
        }
        if ([portfolioItem credit] == TRADE_TYPE_SHORTSELL) {
            // When credit is short sell, swap bought and sold.
            double work = tradeSold;
            tradeSold = tradeBought;
            tradeBought = work;
        }
    } else if (tradeSender == estimateButon) {
        tradeType = [[NSString alloc] initWithString:NSLocalizedString(@"NOTE",@"Note")];
    } else {
        NSBeep();
        [tradeType release];
        return;
    }
    [self createTradeItemWithValue:tradeType
                             price:tradePrice
                            bought:tradeBought
                              sold:tradeSold
                            charge:tradeCharge
                               tax:tradeTax
                            income:tradeIncome
                           comment:[tradeCommentField stringValue]];
    [tradeType release];
    return;
}

- (IBAction)changeTradeCheckBox:(id)sender
{
    if (sender != tradeCheckBox) {
        return;
    }
    if (tradeSender == buyButon) {
        NSString* lang = NSLocalizedString(@"LANG",@"English");
        if ([sender state] == NSOnState) {
            if ([lang isEqualToString:@"Japanese"]) {
                [tradeText setStringValue:@"再投資時の価格と買付数と配当・分配額を入力してください"];
            } else {
                [tradeText setStringValue:@"Please input the dividend and price and the number of purchase."];
            }
            [tradeValueField2nd setEnabled:NO];
            [tradeValueField2nd setDoubleValue:0];
            [tradeValueField3rd setEnabled:YES];
        } else {
            if ([lang isEqualToString:@"Japanese"]) {
                [tradeText setStringValue:@"取引価格と買付数と手数料を入力してください"];
            } else {
                [tradeText setStringValue:@"Please input the price and the number of purchase and charge."];
            }
            [tradeValueField2nd setEnabled:YES];
            [tradeValueField3rd setEnabled:NO];
            [tradeValueField3rd setDoubleValue:0];
        }
        [self showTradeSettlement:sender];
    } else if (tradeSender == splitButon) {
        NSString* lang = NSLocalizedString(@"LANG",@"English");
        if ([sender state] == NSOnState) {
            if ([lang isEqualToString:@"Japanese"]) {
                [tradeText setStringValue:@"株式併合により減少した株数と併合後の価格を入力してください"];
            } else {
                [tradeText setStringValue:@"Please input the price and number of decreased by reverse split."];
            }
        } else {
            if ([lang isEqualToString:@"Japanese"]) {
                [tradeText setStringValue:@"株式分割により増加した株数と分割後の価格を入力してください"];
                [tradeValueLabel1st setStringValue:@"数量:"];
            } else {
                [tradeText setStringValue:@"Please input the price and number of increased by stock split."];
                [tradeValueLabel1st setStringValue:@"Quantity:"];
            }
        }
    } else {
        NSBeep();
    }
    return;
}

- (IBAction)showTradeSettlement:(id)sender
{
    double tradePrice = [tradePriceField doubleValue];
    double tradeBought = 0;
    double tradeSold = 0;
    double tradeCharge = 0;
    double tradeTax = 0;
    double tradeIncome = 0;
    double tradeSettlement = 0;

    if (tradeSender == buyButon) {
        tradeBought = [tradeValueField1st doubleValue];
        tradeCharge = [tradeValueField2nd doubleValue];
        tradeIncome = [tradeValueField3rd doubleValue];
        if ([tradeCheckBox state] == NSOffState) {
            tradeSettlement = tradePrice*tradeBought/[portfolioItem unit] + tradeCharge + tradeTax;
        } else {
            if (sender == tradePriceField || sender == tradeValueField1st) {
                if (tradePrice > 0 && tradeBought > 0 && tradeIncome == 0) {
                    [tradeValueField3rd setDoubleValue:round(100*tradePrice*tradeBought/[portfolioItem unit])/100];
                    tradeIncome = [tradeValueField3rd doubleValue];
                }
            }
            tradeSettlement = tradeIncome - tradeTax;
        }
    } else if (tradeSender == sellButon) {
        tradeSold = [tradeValueField1st doubleValue];
        tradeCharge = [tradeValueField2nd doubleValue];
        tradeTax = [tradeValueField3rd doubleValue];
        tradeSettlement = tradePrice*tradeSold/[portfolioItem unit] - tradeCharge - tradeTax;
    } else if (tradeSender == dividendButon) {
        tradeIncome = [tradeValueField1st doubleValue];
        tradeTax = [tradeValueField2nd doubleValue];
        tradeSettlement = tradeIncome - tradeTax;
    }
    [tradeSettlementField setDoubleValue:round(100*tradeSettlement)/100];
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
		[buyButon setTitle:@"買付"];
		[sellButon setTitle:@"売付"];
		[dividendButon setTitle:@"配当・分配"];
		[splitButon setTitle:@"分割"];
		[estimateButon setTitle:@"記録する"];
		[checkButon setTitle:@"計算する"];
		[undoButon setTitle:@"取消し"];
		[redoButon setTitle:@"やり直し"];
		[deleteButton setTitle:@"削除"];
		[checkDetail setTitle:@"詳細情報"];
		[labelPrice setStringValue:@"取引値 :"];
		[labelAverage setStringValue:@"平均単価 :"];
		[labelQuantity setStringValue:@"保有数 :"];
		[labelPerformance setStringValue:@"騰落率 :"];
		[labelInvested setStringValue:@"投資額 :"];
		[labelEstimated setStringValue:@"評価額 :"];
		[labelTotalGain setStringValue:@"収支 :"];
		[labelLatentGain setStringValue:@"含み益 :"];
		[labelCapitalGain setStringValue:@"譲渡益 :"];
		[labelIncomeGain setStringValue:@"配当益 :"];
		[[targetForm cellAtIndex:0] setTitle:@"利益目標 :"];
		[[targetForm cellAtIndex:1] setTitle:@"損失限度 :"];
		column = [tableView  tableColumnWithIdentifier:@"type"];
		[[column headerCell] setStringValue:@"種別"];
		column = [tableView  tableColumnWithIdentifier:@"date"];
		[[column headerCell] setStringValue:@"日付"];
		column = [tableView  tableColumnWithIdentifier:@"memo"];
		[[column headerCell] setStringValue:@"メモ"];
		column = [tableView  tableColumnWithIdentifier:@"price"];
		[[column headerCell] setStringValue:@"価格"];
		column = [tableView  tableColumnWithIdentifier:@"buy"];
		[[column headerCell] setStringValue:@"買付数"];
		column = [tableView  tableColumnWithIdentifier:@"sell"];
		[[column headerCell] setStringValue:@"売付数"];
		column = [tableView  tableColumnWithIdentifier:@"dividend"];
		[[column headerCell] setStringValue:@"配当益"];
		column = [tableView  tableColumnWithIdentifier:@"charge"];
		[[column headerCell] setStringValue:@"手数料"];
		column = [tableView  tableColumnWithIdentifier:@"tax"];
		[[column headerCell] setStringValue:@"税"];
		column = [tableView  tableColumnWithIdentifier:@"settlement"];
		[[column headerCell] setStringValue:@"決済額"];
		column = [tableView  tableColumnWithIdentifier:@"profit"];
		[[column headerCell] setStringValue:@"譲渡益"];
		column = [tableView  tableColumnWithIdentifier:@"average"];
		[[column headerCell] setStringValue:@"平均単価"];
		column = [tableView  tableColumnWithIdentifier:@"quantity"];
		[[column headerCell] setStringValue:@"保有数"];
		column = [tableView  tableColumnWithIdentifier:@"investment"];
		[[column headerCell] setStringValue:@"投資額"];
		column = [tableView  tableColumnWithIdentifier:@"value"];
		[[column headerCell] setStringValue:@"評価額"];
		column = [tableView  tableColumnWithIdentifier:@"latent"];
		[[column headerCell] setStringValue:@"含み益"];
	}
}

@synthesize		portfolioItem;
@synthesize     parentDoc;
@synthesize		trades;
@synthesize		priceField;
@synthesize		averageField;
@synthesize		quantityField;
@synthesize		performanceField;
@synthesize		investedField;
@synthesize		estimatedField;
@synthesize		totalGainField;
@synthesize		latentGainField;
@synthesize		capitalGainField;
@synthesize		incomeGainField;
@synthesize		targetForm;
@synthesize		win;
@end
