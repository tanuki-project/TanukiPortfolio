//
//  PortfolioItem.m
//  tPortfolio
//
//  Created by Takahiro Sayama on 10/12/05.
//  Copyright 2011 tanuki-project. All rights reserved.
//

#import		"PortfolioItem.h"
#import		"PreferenceController.h"

extern bool			customCountry;
extern NSString*	customCountryCode;
extern NSString*	customCountryName;
extern NSString*	customCurrencyCode;
extern NSString*	customCurrencyName;
extern NSString*	customCurrencySymbol;

@implementation TradeItem

- (id)init
{
	NSLog(@"init TradeItem");
	self = [super init];
	if (self == nil) {
		return nil;
	}
	date = [[NSDate alloc] init];
	kind = [[NSString alloc] init];
	price = 0;
	buy = 0;
	sell = 0;
	charge = 0;
	dividend = 0;
	tax = 0;
	comment = @"";
	settlement = 0;
	quantity = 0;
	profit = 0;
	value = 0;
	av_price = 0;
	return self;
}

- (id) initWith:(NSDate*)Date :
		(NSString*)Kind :
		(double)Price :
		(double)Quantity :
		(int)Unit :
		(double)Charge :
		(double)Dividend :
		(double)Tax :
		(NSString*)Comment :
		(NSString*)Country
{
	NSLog(@"init TradeItem");
	self = [super init];
	if ( self == nil ) {
		return self;
	}
	int	roundRate = 1;
	if ([Country isEqualToString:TRADE_ITEM_COUNTRY_JP] == NO) {
		roundRate = 100;
	}
	date = Date;
	kind = Kind;
	[kind retain];
	price = Price;
	buy = 0;
	sell = 0;
	quantity = 0;
	charge = Charge;
	dividend = Dividend;
	tax = Tax;
	if ([self tradeTypeToType:kind] == TRADE_ITEM_TYPE_I_BUY) {
		buy = Quantity;
		settlement = round(price*buy*roundRate/Unit)/roundRate + charge + tax;
	} else if ([self tradeTypeToType:kind] == TRADE_ITEM_TYPE_I_SELL) {
		sell = Quantity;
		settlement = round(price*sell*roundRate/Unit)/roundRate - charge - tax;
	} else if ([self tradeTypeToType:kind] == TRADE_ITEM_TYPE_I_DIVIDEND) {
		settlement = dividend - charge - tax;
	} else if ([self tradeTypeToType:kind] == TRADE_ITEM_TYPE_I_REINVESTMENT) {
		buy = Quantity;
		settlement = dividend - charge - tax;
	} else if ([self tradeTypeToType:kind] == TRADE_ITEM_TYPE_I_SPLIT) {
		buy = quantity;
		settlement = 0;
	} else {
		settlement = 0;
	}
	av_price = 0;
	profit = 0;
	value = 0;
	comment = Comment;
	[comment retain];
	return self;
}

- (void)dealloc
{
	NSLog(@"dealloc TradeItem");
	if (kind) {
		[kind release];
	}
	if (comment) {
		[comment release];
	}
	[super dealloc];
}

- (void)setNilValueForKey:(NSString *)key
{
	NSLog(@"setNilValueForKey TradeItem");
	if ([key isEqual:@"price"]) {
		[self setPrice:0.0];
	} else if ([key isEqual:@"sell"]) {
		[self setSell:0.0];
	} else if ([key isEqual:@"buy"]) {
		[self setBuy:0.0];
	} else if ([key isEqual:@"charge"]) {
		[self setCharge:0.0];
	} else if ([key isEqual:@"dividend"]) {
		[self setDividend:0.0];
	} else if ([key isEqual:@"tax"]) {
		[self setTax:0.0];
	} else {
		[super setNilValueForKey:key];
	}
}

#pragma mark Archiver

- (void)encodeWithCoder:(NSCoder *)coder
{
	// NSLog(@"encodeWithCoder TradeItem %@ %@ %@ %f %f %f %f %f %f", kind, date, comment, price, sell, buy, charge, dividend, tax);
	[coder encodeObject:kind forKey:@"kind"];
	[coder encodeObject:date forKey:@"date"];
	[coder encodeDouble:price forKey:@"price"];
	[coder encodeDouble:sell forKey:@"sell"];
	[coder encodeDouble:buy forKey:@"buy"];
	[coder encodeDouble:charge forKey:@"charge"];
	[coder encodeDouble:dividend forKey:@"dividend"];
	[coder encodeDouble:tax forKey:@"tax"];
	[coder encodeObject:comment forKey:@"comment"];
}

- (id)initWithCoder:(NSCoder *)coder
{
	self = [super init];
	NSString* itemKind = [[coder decodeObjectForKey:@"kind"] retain];
    double  Buy = 0;
    double  Sell = 0;
	date = [[coder decodeObjectForKey:@"date"] retain];
	price = [coder decodeDoubleForKey:@"price"];
	Buy = [coder decodeDoubleForKey:@"buy"];
    Sell = [coder decodeDoubleForKey:@"sell"];
    buy = Buy;
    sell = Sell;
	charge = [coder decodeDoubleForKey:@"charge"];
	dividend = [coder decodeDoubleForKey:@"dividend"];
	tax = [coder decodeDoubleForKey:@"tax"];
	comment = [[coder decodeObjectForKey:@"comment"] retain];
	int intKind = [self tradeTypeToType:itemKind];
	switch (intKind) {
		case TRADE_ITEM_TYPE_I_BUY:
			kind = NSLocalizedString(@"BUY",@"Buy");
			break;
		case TRADE_ITEM_TYPE_I_SELL:
			kind = NSLocalizedString(@"SELL",@"Sell");
			break;
		case TRADE_ITEM_TYPE_I_DIVIDEND:
			kind = NSLocalizedString(@"DIVIDEND",@"Dividend");
			break;
		case TRADE_ITEM_TYPE_I_REINVESTMENT:
			kind = NSLocalizedString(@"REINVESTMENT",@"Reinvestment");
			break;
		case TRADE_ITEM_TYPE_I_SPLIT:
			kind = NSLocalizedString(@"SPLIT",@"Split");
			break;
        case TRADE_ITEM_TYPE_I_DEPOSIT:
			kind = NSLocalizedString(@"DEPOSIT",@"Deposit");
            break;
        case TRADE_ITEM_TYPE_I_WITHDRAW:
			kind = NSLocalizedString(@"WITHDRAW",@"Withdraw");
            break;
        case TRADE_ITEM_TYPE_I_INTEREST:
			kind = NSLocalizedString(@"INTEREST",@"Interest");
            break;
		case TRADE_ITEM_TYPE_I_ESTIMATE:
		default:
			kind = NSLocalizedString(@"NOTE",@"Note");
			// kind = NSLocalizedString(@"EVALUATE",@"Evaluate");
			break;
	}
	[itemKind release];
	[kind retain];
	// NSLog(@"initWithCoder TradeItem %@ %@  %@ %f %f %f %f %f %f", kind, date, comment, price, sell, buy, charge, dividend, tax);
	return self;
}

- (int)tradeTypeToType:(NSString*)typeString {
	if ([typeString isEqualToString:TRADE_ITEM_TYPE_EN_BUY] ||
		[typeString isEqualToString:TRADE_ITEM_TYPE_JP_BUY]) {
		return TRADE_ITEM_TYPE_I_BUY;
	}
	if ([typeString isEqualToString:TRADE_ITEM_TYPE_EN_SELL] ||
		[typeString isEqualToString:TRADE_ITEM_TYPE_JP_SELL]) {
		return TRADE_ITEM_TYPE_I_SELL;
	}
	if ([typeString isEqualToString:TRADE_ITEM_TYPE_EN_DIVIDEND] ||
		[typeString isEqualToString:TRADE_ITEM_TYPE_JP_DIVIDEND]) {
		return TRADE_ITEM_TYPE_I_DIVIDEND;
	}
	if ([typeString isEqualToString:TRADE_ITEM_TYPE_EN_REINVESTMENT] ||
		[typeString isEqualToString:TRADE_ITEM_TYPE_JP_REINVESTMENT]) {
		return TRADE_ITEM_TYPE_I_REINVESTMENT;
	}
	if ([typeString isEqualToString:TRADE_ITEM_TYPE_EN_SPLIT] ||
		[typeString isEqualToString:TRADE_ITEM_TYPE_JP_SPLIT]) {
		return TRADE_ITEM_TYPE_I_SPLIT;
	}
	if ([typeString isEqualToString:TRADE_ITEM_TYPE_EN_DEPOSIT] ||
		[typeString isEqualToString:TRADE_ITEM_TYPE_JP_DEPOSIT]) {
		return TRADE_ITEM_TYPE_I_DEPOSIT;
	}
	if ([typeString isEqualToString:TRADE_ITEM_TYPE_EN_WITHDRAW] ||
		[typeString isEqualToString:TRADE_ITEM_TYPE_JP_WITHDRAW]) {
		return TRADE_ITEM_TYPE_I_WITHDRAW;
	}
	if ([typeString isEqualToString:TRADE_ITEM_TYPE_EN_INTEREST] ||
		[typeString isEqualToString:TRADE_ITEM_TYPE_JP_INTEREST]) {
		return TRADE_ITEM_TYPE_I_INTEREST;
	}
	if ([typeString isEqualToString:TRADE_ITEM_TYPE_EN_ESTIMATE] ||
		[typeString isEqualToString:TRADE_ITEM_TYPE_JP_ESTIMATE]) {
		return TRADE_ITEM_TYPE_I_ESTIMATE;
	}
	if ([typeString isEqualToString:TRADE_ITEM_TYPE_EN_NOTE] ||
		[typeString isEqualToString:TRADE_ITEM_TYPE_JP_NOTE]) {
		return TRADE_ITEM_TYPE_I_ESTIMATE;
	}
	return TRADE_ITEM_TYPE_I_UNKNOWN;
	NSLog(@"tradeTypeToType UNKNOWN TYPE: %@", typeString);
}

@synthesize		index;
@synthesize		date;
@synthesize		kind;
@synthesize		comment;
@synthesize		price;
@synthesize		sell;
@synthesize		buy;
@synthesize		settlement;
@synthesize		charge;
@synthesize		dividend;
@synthesize		tax;
@synthesize		quantity;
@synthesize		av_price;
@synthesize		profit;
@synthesize		value;
@synthesize		investment;
@synthesize		lprofit;
@end


@implementation PortfolioItem

- (id)init
{
	NSLog(@"init PortfolioItem");
	self = [super init];
	if (self == nil) {
		return self;
	}
	version = ITEM_VESRION;
	itemName = NSLocalizedString(@"NEW_ITEM",@"New Item");
	[itemName retain];
	itemCode = @"";
	flagColor = ITEM_COLOR_WHITE;

	if ([ITEM_TYPE_EN_STOCK isEqualToString:NSLocalizedString(@"STOCK",@"Stock:actual")]) {
		itemType = ITEM_TYPE_EN_STOCK;
	} else {
		itemType = ITEM_TYPE_JP_STOCK;
	}
	type = [self itemTypeToType:itemType];
	url = INITIAL_IR_SITE;
    comment = nil;
	price = 0.0;
	av_price = 0.0;
	quantity = 0.0;
	unit = 1;
	credit = TRADE_TYPE_REALBUY;
	value = 0.0;
	investment = 0.0;
	reinvest = 0.0;
	profit = 0.0;
	income = 0.0;
	lproperty = 0.0;
	rise = 0.0;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	order = [defaults boolForKey:tPrtTradeOrderKey];
	country = [[defaults objectForKey:tPrtCountryKey] retain];
	if (country == nil) {
		NSString* lang = NSLocalizedString(@"LANG",@"English");
		if ([lang isEqualToString:@"Japanese"]) {
			country = TRADE_ITEM_COUNTRY_JP;
		} else {
			country = TRADE_ITEM_COUNTRY_US;
		}
	}
	yieldTarget = YIELD_TARGET_DEFAULT;
	lossCutLimit = LOSSCUT_LIMIT_DEFAULT;
	trades = [[NSMutableArray alloc] init];
	date = [[NSDate alloc] init];
    created = [[NSDate alloc] init];
    status = 0x00;
    NSLog(@"created date=%@", created);
	return self;
}

- (void)dealloc
{
	NSLog(@"dealloc PortfolioItem");
	[itemName release];
	[itemCode release];
	[itemType release];
	[url release];
	[trades removeAllObjects];
	[trades release];
	[super dealloc];
}

- (void) Clear {
	[trades removeAllObjects];
	return;
}

- (void) Add:(TradeItem*)trade {
	NSLog(@"Add");
	int			i, n;
	NSDate*		date1;
	NSDate*		date2;
	TradeItem*	wt;
	date1 = [trade date];
	n = [trades count];
	NSLog(@"count of %@ = %d", [self itemName], n);
	for (i = 0; i < n; i++) {
		wt = [trades objectAtIndex:i];
		date2 = [ wt date ];
		NSLog(@"Add trade: trade item order = %d", order);
		if (order == TRADE_ITEM_ORDER_ASCENDING) {
			if ([date1 laterDate: date2] == date2) {
				break;
			}
		} else {
			if ([date1 earlierDate: date2] == date2) {
				break;
			}
		}
	}
	//[trade retain];
	[trades insertObject:trade atIndex:i];
	NSLog(@"insertObject atIndex:%d", i);
	n = [trades count];
	for (i = 0; i < n; i++) {
		wt = [trades objectAtIndex:i];
		[wt setIndex: i];
		// NSLog(@"index = %d",i);
	}
	// n = [trades count];
	// NSLog(@"count = %d", n);
	[self DoSettlement];
	return;
}

- (void) Add:
	(NSDate*)Date :
	(NSString*)Kind :
	(double)Price :
	(double)Quantity :
	(int)Unit :
	(double)charge :
	(double)dividend :
	(double)tax :
	(NSString*)Comment
{
	TradeItem*	trade = nil;
	trade = [[TradeItem alloc] initWith: Date: Kind: Price: Quantity: Unit: charge: dividend: tax: Comment: country];
	if ([trade tradeTypeToType:Kind] == TRADE_ITEM_TYPE_I_SPLIT) {
		if (credit == TRADE_TYPE_SHORTSELL) {
			[ trade setBuy:0 ];
			[ trade setSell:Quantity ];
		}
	}
	[self Add:trade];
    [trade release];
	return;
}

- (void) Remove:(TradeItem*)trade {
	int			i, n;
	TradeItem*	wt;
	[trades removeObject: trade];
	n = [trades count];
	for (i = 0; i < n; i++) {
		wt = [trades objectAtIndex:i];
		[wt setIndex:i];
	}
	[self DoSettlement];
	return;
}

- (void) RemoveById:(int)id {
	int			i, n;
	TradeItem*	wt;
	n = [trades count];
	for (i = 0; n; i++) {
		wt = [trades objectAtIndex:i];
		if ([wt index] == id) {
			[trades removeObject:wt];
			break;
		}
	}
	n = [trades count];
	for (i = 0; i < n; i++) {
		wt = [trades objectAtIndex:i];
		[wt setIndex:i];
	}
	[self DoSettlement];
	return;
}

- (void) ApplyPriceTag:(NSDate*)Date :(double)Price {
	TradeItem*	trade;
	trade = [self Search:Date:TRADE_ITEM_TYPE_NONE];
	if (trade) {
		[trade setPrice: Price];
		[self DoSettlement];
	} else {
		[self Add:Date:NSLocalizedString(@"NOTE",@"Note"):Price:0:0:0:0:0:@""];
		// [self Add:Date:NSLocalizedString(@"EVALUATE",@"Evaluate"):Price:0:0:0:0:0:@""];
	}
	return;
}

- (void) RemovePriceTag:(NSDate*)Date {
	TradeItem*	trade;
	trade = [self Search:Date:TRADE_ITEM_TYPE_NONE];
	if (trade) {
		[trades removeObject: trade];
	}
}

- (TradeItem*) Search:(int)id {
	for (TradeItem*	trade in trades) {
		if (id == [trade index]) {
			return trade;
		}
	}
	return nil;
}

- (TradeItem*) Search:(NSDate*)Date :(int)Type {
	for (TradeItem*	trade in trades) {
		if ([Date isEqual:[trade date]]) {
			switch (Type) {
				case TRADE_ITEM_TYPE_BUY:
					if ([trade buy] > 0) {
						return trade;
					}
					break;
				case TRADE_ITEM_TYPE_SELL:
					if ([trade sell] > 0) {
						return trade;
					}
					break;
				case TRADE_ITEM_TYPE_NONE:
					if ([trade buy] == 0 && [trade sell] == 0) {
						return trade;
					}
					break;
			}
		}
	}
	return nil;
}

- (bool) RebuildTrades {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	bool orderSetting = [defaults boolForKey:tPrtTradeOrderKey];
	if (order != orderSetting) {
		NSLog(@"rebuild trades in reverse order");
		NSMutableArray* rt = [[NSMutableArray alloc] init];
		for (TradeItem* trade in trades) {
			[rt insertObject:trade atIndex:0];
		}
		[trades removeAllObjects];
		[trades release];
		trades = rt;
		order = orderSetting;
		return YES;
	}
	return NO;
}

- (void) DoSettlement {
	// NSLog(@"DoSettlemen");
	int				roundRate = 1;
	if ([[self country] isEqualToString:TRADE_ITEM_COUNTRY_JP] == NO) {
		roundRate = 100;
	}	
	[self SortTradesByDate];
	type = [self itemTypeToType:itemType];
	if (type == ITEM_TYPE_FUND_10000) {
		[self setUnit:10000];
	} else {
		[self setUnit:1];
	}
	if (type == ITEM_TYPE_STOCK_BUY ||
		   type == ITEM_TYPE_ETF_BUY ||
		   type == ITEM_TYPE_CURRENCY_BUY) {
		credit = TRADE_TYPE_LONGBUY;
	} else if (type == ITEM_TYPE_STOCK_SELL ||
		   type == ITEM_TYPE_ETF_SELL ||
		   type == ITEM_TYPE_CURRENCY_SELL) {
		credit = TRADE_TYPE_SHORTSELL;
	} else {
		credit = TRADE_TYPE_REALBUY;
	}
    if (type == ITEM_TYPE_CASH) {
        if (price != 1.0) {
            [self setPrice:1.0];
        }
		[self setUnit:1];
    }
	for (TradeItem *trade in trades) {
		if ([trade buy] > 0) {
			if ([trade tradeTypeToType:[trade kind]] == TRADE_ITEM_TYPE_I_BUY ||
				[trade tradeTypeToType:[trade kind]] == TRADE_ITEM_TYPE_I_REINVESTMENT ||
				[trade tradeTypeToType:[trade kind]] == TRADE_ITEM_TYPE_I_ESTIMATE) {
				if ([trade dividend] == 0) {
					[trade setKind:NSLocalizedString(@"BUY",@"Buy")];
				} else {
					[trade setKind:NSLocalizedString(@"REINVESTMENT",@"Reinvestment")];
				}
			}
		}

		if ([trade tradeTypeToType:[trade kind]] == TRADE_ITEM_TYPE_I_BUY) {
			[trade setSettlement:round([trade price]*[trade buy]*roundRate/unit)/roundRate+[trade charge]+[trade tax]];
		} else if ([trade tradeTypeToType:[trade kind]] == TRADE_ITEM_TYPE_I_SELL) {
			[trade setSettlement:round([trade price]*[trade sell]*roundRate/unit)/roundRate-[trade charge]-[trade tax]];
		} else if ([trade tradeTypeToType:[trade kind]] == TRADE_ITEM_TYPE_I_DIVIDEND) {
			[trade setSettlement:[trade dividend]-[trade charge]-[trade tax]];
		} else if ([trade tradeTypeToType:[trade kind]] == TRADE_ITEM_TYPE_I_REINVESTMENT) {
			[trade setSettlement:[trade dividend]-[trade charge]-[trade tax]];
		} else if ([trade tradeTypeToType:[trade kind]] == TRADE_ITEM_TYPE_I_DEPOSIT ||
                   [trade tradeTypeToType:[trade kind]] == TRADE_ITEM_TYPE_I_INTEREST) {
			[trade setSettlement:round([trade price]*[trade buy]*roundRate/unit)/roundRate+[trade charge]+[trade tax]];
		} else if ([trade tradeTypeToType:[trade kind]] == TRADE_ITEM_TYPE_I_WITHDRAW) {
			[trade setSettlement:round([trade price]*[trade sell]*roundRate/unit)/roundRate-[trade charge]-[trade tax]];
        } else if ([trade tradeTypeToType:[trade kind]] == TRADE_ITEM_TYPE_I_SPLIT) {
            [trade setSettlement:0];
		} else {
			[trade setSettlement:0];
		}
	}
	switch (credit) {
		case TRADE_TYPE_SHORTSELL:
			[self DoSettlementSell];
			break;
		default:
			[self DoSettlementBuy];
			break;
	}

	// NSLog(@"quantity=%f value=%f investment=%f lproperty=%f",quantity,value,investment,lproperty);
	// NSLog(@"price=%f av_price=%f rise=%f profit=%f income=%f",price,av_price,rise,profit,income);
	if (rise >= 0) {
		flagColor = ITEM_COLOR_WHITE;
		if (rise >= yieldTarget*100) {
			if (rise >= 100) {
				flagColor = ITEM_COLOR_PURPLE;
			} else if (rise >= yieldTarget*200 ||
				rise >= YIELD_TARGET_DEFAULT*200) {
				flagColor = ITEM_COLOR_BLUE;
			} else {
				flagColor = ITEM_COLOR_GREEN;
			}
		}
	} else {
		flagColor = ITEM_COLOR_YELLOW;
		if (rise <= lossCutLimit*100) {
			if (fabs(rise) >= fabs(lossCutLimit)*200 ||
				fabs(rise) >= fabs(LOSSCUT_LIMIT_DEFAULT)*200) {
				flagColor = ITEM_COLOR_RED;
			} else {
				flagColor = ITEM_COLOR_ORANGE;
			}
		}
	}
	return;
}

- (void) DoSettlementBuy {
	NSEnumerator*	enumerator;
	int				roundRate = 1;
	TradeItem*		prev_trade = nil;
	double			Quantity = 0;	// 現保有数	
	profit = 0;						// 累積売買益
	income = 0;						// 累積配当益
	lproperty = 0;					// 現含み益
	investment = 0;					// 現買建額
	reinvest = 0;					// 現再投資額
	quantity = [self GetQuantity];	// 累積保有数
	value = [self GetValue];		// 現評価額
    boolean_t       debug = NO;

    if (debug == YES) {
        NSLog(@"DoSettlementBuy: %@", itemName);
    }
	if ([[self country] isEqualToString:TRADE_ITEM_COUNTRY_JP] == NO) {
		roundRate = 100;
	}
	if (order == TRADE_ITEM_ORDER_ASCENDING) {
		enumerator = [trades objectEnumerator];
	} else {
		enumerator = [trades reverseObjectEnumerator];
	}
	for (TradeItem*	trade in enumerator) {
		[trade setProfit:0];
		if (date != nil) {
			if ([date earlierDate:[trade date]] == date && [date isEqualToDate:[trade date]] == NO) {
                if (debug == YES) {
                    NSLog(@"DoSettlementBuy:break: %@ %@ %@", date, [trade date], [date earlierDate:[trade date]]);
                }
				break;
			}
		}

        if ([trade tradeTypeToType:[trade kind]] == TRADE_ITEM_TYPE_I_SPLIT) {
            NSLog(@"Split");
        }

		// 現保有数・現評価額
		Quantity += [trade buy];
		Quantity -= [trade sell];
		[trade setQuantity:Quantity];
		[trade setValue:[trade price]*Quantity/unit];
		
		// 平均取得単価
		if (Quantity == 0) {
			[trade setAv_price:0];
		} else if (prev_trade == nil) {
			[trade setAv_price: [trade settlement]/Quantity*unit];
		} else {
            if ([trade sell] > 0 && [trade settlement] == 0) {
                // In case Reverse stock split.
                double	sum = [prev_trade av_price]*[prev_trade quantity]/unit;
                // NSLog(@"sum=%f quantity=%f",sum, Quantity);
                [trade setAv_price:sum*unit/Quantity];
            } else if ([trade buy] == 0) {
				[trade setAv_price:[prev_trade av_price]];
			} else {
				double	sum = [prev_trade av_price]*[prev_trade quantity]/unit;
				if ([trade dividend] == 0) {
					sum += [trade settlement];
				}
				// NSLog(@"sum=%f quantity=%f",sum, Quantity);
				[trade setAv_price:sum*unit/Quantity];
			}
		}
		
		// 売買益
		if ([trade sell] == 0) {
			[trade setProfit:0];
        } else if ([trade sell] > 0 && [trade settlement] == 0) {
            // In case Reverse stock split.
            [trade setProfit:0];
		} else if (prev_trade) {
			[trade setProfit:([trade price]-[prev_trade av_price])*[trade sell]/unit-[trade charge]-[trade tax]];
			[trade setProfit:round([trade profit]*roundRate)/roundRate];
		}
		
		if ([trade dividend] != 0) {
			if ([trade buy] == 0) {
				income += [trade dividend];
				income -= [trade tax];
			} else {
				reinvest += [trade dividend];
				reinvest += [trade tax];
			}
		}
		profit += [trade profit];
		av_price = round([trade av_price]*100*roundRate)/(100*roundRate);
		investment = round([trade quantity]*[trade av_price]*roundRate/unit)/roundRate;
		[trade setInvestment:investment];
		[trade setValue:[trade quantity]*[trade price]/unit];
		[trade setLprofit:[trade value]-[trade investment]];
		// NSLog(@"Trade: profit=%f av_price=%f", [trade profit],[trade av_price]);

		// Save Current trade
		if (Quantity != 0) {
			prev_trade = trade;
		} else {
			prev_trade = nil;
		}		
	}
	lproperty = value - investment;
	// NSLog(@"Portfolio: value=%f investment=%f", value, investment);
	if (quantity > 0) {
		rise = (price/av_price-1)*100;
	} else {
		rise = 0;
	}
	return;
}

- (void) DoSettlementSell {
	int				roundRate = 1;
	NSEnumerator*	enumerator;
	TradeItem*		prev_trade = nil;
	double			Quantity = 0;	// 現保有数
	profit = 0;						// 累積売買益
	income = 0;						// 累積配当益
	lproperty = 0;					// 現含み益
	investment = 0;					// 現買建額
	reinvest = 0;					// 現再投資額
	quantity = [self GetQuantity];	// 累積保有数
	value = [self GetValue];		// 現評価額
    boolean_t       debug = NO;

    if (debug == YES) {
        NSLog(@"DoSettlementSell: %@", itemName);
    }
	if ([[self country] isEqualToString:TRADE_ITEM_COUNTRY_JP] == NO) {
		roundRate = 100;
	}
	if (order == TRADE_ITEM_ORDER_ASCENDING) {
		enumerator = [trades objectEnumerator];
	} else {
		enumerator = [trades reverseObjectEnumerator];
	}
	for (TradeItem*	trade in enumerator) {
		[trade setProfit:0];
		if (date != nil) {
			if ([date earlierDate:[trade date]] == date && [date isEqualToDate:[trade date]] == NO) {
                if (debug == YES) {
                    NSLog(@"DoSettlementSell:break: %@ %@ %@", date, [trade date], [date earlierDate:[trade date]]);
                }
				break;
			}
		}
		
		// 現売建数・現評価額
		Quantity += [trade sell];
		Quantity -= [trade buy];
		[trade setQuantity:Quantity];
		[trade setValue:[trade price]*Quantity];
		[trade setLprofit:[trade investment]-[trade value]];
		
		// 平均取得単価
		if (Quantity == 0) {
			[trade setAv_price:0];
		} else if (prev_trade == nil) {
			[trade setAv_price:[trade settlement]/Quantity];
		} else {
            if ([trade buy] > 0 && [trade settlement] == 0) {
                // In case Reverse stock split.
                [trade setAv_price:([prev_trade av_price]*[prev_trade quantity])/Quantity];
            } else if ([trade sell] == 0) {
				[trade setAv_price:[prev_trade av_price]];
			} else {				
				[trade setAv_price:([trade settlement]+[prev_trade av_price]*[prev_trade quantity])/Quantity];
			}
		}

		// 売買益
		if ([trade buy] == 0) {
			[trade setProfit:0];
        } else if ([trade buy] > 0 && [trade settlement] == 0) {
            [trade setProfit:0];
		} else if (prev_trade) {
			[trade setProfit:([prev_trade av_price]-[trade price])*[trade buy]/unit-[trade charge]-[trade tax]];
			[trade setProfit:round([trade profit]*roundRate)/roundRate];
		}
		
		if ([trade dividend] != 0) {
				income += [trade dividend];
				income -= [trade tax];
		}
		profit += [trade profit];
		av_price = round([trade av_price]*100*roundRate)/(100*roundRate);
		investment = round([trade quantity]*[trade av_price]*roundRate/unit)/roundRate;
		[trade setInvestment:investment];
		[trade setValue:[trade quantity]*[trade price]/unit];
		// NSLog(@"Trade: profit=%f av_price=%f", [trade profit],[trade av_price]);
		
		// Save Current trade
		if (Quantity != 0) {
			prev_trade = trade;
		} else {
			prev_trade = nil;
		}
	}
	lproperty = investment - value;
	// NSLog(@"Portfolio: value=%f investment=%f", value, investment);
	if (quantity > 0) {
		rise = (1-price/av_price)*100;
	} else {
		rise = 0;
	}
	return;
}

- (double) GetQuantity {
	double			Quantity = 0;		// 現保有数
	NSEnumerator*	enumerator;
	if (order == TRADE_ITEM_ORDER_ASCENDING) {
		enumerator = [trades objectEnumerator];
	} else {
		enumerator = [trades reverseObjectEnumerator];
	}
	for (TradeItem*	trade in enumerator) {
		[trade setProfit:0];
		if (date != nil && [trade date] != nil) {
			if ([date earlierDate:[trade date]] == date && [date isEqualToDate:[trade date]] == NO) {
				NSLog(@"GetQuantity:break: %@ %@ %@", date, [trade date], [date earlierDate:[trade date]]);
				break;
			}
		}
		if (credit == TRADE_TYPE_SHORTSELL) {
			Quantity += [trade sell];
			Quantity -= [trade buy];
		} else {
			Quantity += [trade buy];
			Quantity -= [trade sell];
		}
	}
	return Quantity;
}

- (double) GetValue {
	double Value;
	double tprice;
	tprice = [self GetPriceByDate:date];
	if ([[self country] isEqualToString:TRADE_ITEM_COUNTRY_JP] == YES) {
		Value = round(quantity*tprice/unit);
	} else {
		Value = round(quantity*tprice*100/unit)/100;
	}
	return Value;
}

- (void)setNilValueForKey:(NSString *)key
{
	if ([key isEqual:@"price"]) {
		[self setPrice:0.0];
	} else {
		[super setNilValueForKey:key];
	}
}

- (double) GetPriceByDate:(NSDate*)Date {
	double tprice = 0;
	NSEnumerator*	enumerator;
	if (date == nil || [trades count] ==0) {
		return price;
	}
	NSDate* today;
	NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *compo = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit)
										  fromDate:[NSDate date]];
	today = [calendar dateFromComponents:compo];
	[calendar release];
	if ([today isEqualToDate:Date] == YES || [today earlierDate:Date] == today) {
		return price;
	}
	NSLog(@"GetPriceByDate: trade item order = %d", order);
	if (order == TRADE_ITEM_ORDER_ASCENDING) {
		enumerator = [trades objectEnumerator];
	} else {
		enumerator = [trades reverseObjectEnumerator];
	}
	for (TradeItem*	trade in enumerator) {
		if ([date earlierDate:[trade date]] == date && [date isEqualToDate:[trade date]] == NO) {
			return tprice;			
			NSLog(@"GetPriceByDate:break: %@ %@ %@", date, [trade date], [date earlierDate:[trade date]]);
		}
		tprice = [trade price];
	}
	if (tprice > 0) {
		return tprice;
	}
	return price;
}

- (double) GetRecordedPrice:(NSDate*)Date {
    double tprice = 0;
    NSEnumerator*	enumerator;
    if (Date == nil || [trades count] ==0) {
        return 0;
    }
    NSLog(@"GetRecorded: trade item order = %d", order);
    NSDate* today;
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *compo;
    compo = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:[NSDate date]];
    today = [calendar dateFromComponents:compo];
    compo = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:Date];
    if ([today isEqualToDate:[calendar dateFromComponents:compo]] == YES) {
        [calendar release];
        return price;
    }
    [calendar release];

    if (order == TRADE_ITEM_ORDER_ASCENDING) {
        enumerator = [trades objectEnumerator];
    } else {
        enumerator = [trades reverseObjectEnumerator];
    }
    for (TradeItem*	trade in enumerator) {
        if ([Date laterDate:[trade date]] == [trade date] && [Date isEqualToDate:[trade date]] == NO) {
            return tprice;
            NSLog(@"GetPriceByDate:break: %@ %@ %@", date, [trade date], [date earlierDate:[trade date]]);
        }
        tprice = [trade price];
    }
    return tprice;
}

- (void) SortTradesByDate
{
	NSSortDescriptor	*descriptor;
	NSMutableArray		*sortDescriptors = [[NSMutableArray alloc] init];
	NSLog(@"SortTradesByDate: trade item order = %d", order);
	if (order == TRADE_ITEM_ORDER_ASCENDING) {
		descriptor=[[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES selector:@selector(compare:)];
		// NSLog(@"SortTradesByDate: ascending:YES :%@ ", itemName);
	} else {
		descriptor=[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO selector:@selector(compare:)];
		// NSLog(@"SortTradesByDate: ascending:NO :%@ ", itemName);
	}
	[sortDescriptors addObject:descriptor];
	[trades sortUsingDescriptors:sortDescriptors];
	[descriptor release];
	[sortDescriptors release];
}

#pragma mark Archiver

- (void)encodeWithCoder:(NSCoder *)coder
{
	NSLog(@"encodeWithCoder %@ %@ %@ %f", itemName, itemCode, itemType, price);
	[coder encodeDouble:version forKey:@"version"];
	[coder encodeObject:itemName forKey:@"itemName"];
	[coder encodeObject:itemCode forKey:@"itemCode"];
	[coder encodeObject:itemType forKey:@"itemType"];
	[coder encodeDouble:price forKey:@"price"];
	if (version > ITEM_VESRION_ZERO) {
		[coder encodeObject:country forKey:@"country"];
		if (yieldTarget != 0) {
			[coder encodeDouble:yieldTarget forKey:@"yieldTarget"];
		}
		if (lossCutLimit != 0) {
			[coder encodeDouble:lossCutLimit forKey:@"lossCutLimit"];
		}
	}
	[coder encodeObject:url forKey:@"url"];
    [coder encodeObject:created forKey:@"created"];
    [coder encodeInt64:status forKey:@"status"];
	// NSLog(@"encodeWithCoder: trade item order = %d", order);
	if (order == TRADE_ITEM_ORDER_ASCENDING) {
		[coder encodeObject:trades forKey:@"trades"];
	} else {
		NSMutableArray* rt = [[NSMutableArray alloc] init];
		for (TradeItem* trade in trades) {
			[rt insertObject:trade atIndex:0];
		}
		[coder encodeObject:rt forKey:@"trades"];
		[rt removeAllObjects];
		[rt release];
	}
}

- (id)initWithCoder:(NSCoder *)coder
{
	NSLog(@"initWithCoder");
	self = [super init];
	version = [coder decodeDoubleForKey:@"version"];
	itemName = [[coder decodeObjectForKey:@"itemName"] retain];
	if (itemName == nil) {
		NSLog(@"initWithCoder: itemName is nil");
	}
	itemCode = [[coder decodeObjectForKey:@"itemCode"] retain];
	if (itemCode == nil) {
		NSLog(@"initWithCoder: itemCode is nil");
	}
	NSString* itemTypeStr = [[coder decodeObjectForKey:@"itemType"] retain];
	if (itemTypeStr == nil) {
		NSLog(@"initWithCoder: itemType is nil");
	}
	price = [coder decodeDoubleForKey:@"price"];
	url = [[coder decodeObjectForKey:@"url"] retain];
	if (url == nil) {
		NSLog(@"initWithCoder: url is nil");
	}
    created = [[coder decodeObjectForKey:@"created"] retain];
    if (created == nil) {
        created = [[NSDate alloc] init];
    }
    status = [coder decodeInt64ForKey:@"status"];
	if (version == ITEM_VESRION_ZERO) {
		country = TRADE_ITEM_COUNTRY_JP;
		yieldTarget = YIELD_TARGET_DEFAULT;
		lossCutLimit = LOSSCUT_LIMIT_DEFAULT;
	} else {
		country = [[coder decodeObjectForKey:@"country"] retain];
		if (country == nil) {
			NSLog(@"initWithCoder: country is nil");
		}
		yieldTarget = [coder decodeDoubleForKey:@"yieldTarget"];
		if (yieldTarget == 0) {
			yieldTarget = YIELD_TARGET_DEFAULT;
		}
		lossCutLimit = [coder decodeDoubleForKey:@"lossCutLimit"];
		if (lossCutLimit == 0) {
			lossCutLimit = LOSSCUT_LIMIT_DEFAULT;
		}
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	order = [defaults boolForKey:tPrtTradeOrderKey];
	// NSLog(@"initWithCoder: trade item order = %d", order);
	trades = [[coder decodeObjectForKey:@"trades"] retain];
	if (trades == nil) {
		trades = [[NSMutableArray alloc] init];
	} else {
		if (order == TRADE_ITEM_ORDER_DESCENDING) {
			NSLog(@"rebuild trades in reverse order");
			NSMutableArray* rt = [[NSMutableArray alloc] init];
			for (TradeItem* trade in trades) {
				[rt insertObject:trade atIndex:0];
			}
			[trades removeAllObjects];
			[trades release];
			trades = rt;
		}
	}
	credit = TRADE_TYPE_REALBUY;
	unit = 1;
	rise = 0;
	type = [self itemTypeToType:itemTypeStr];
	itemType = [self localizedItemType:type];
	[itemTypeStr release];
	[itemType retain];
	if (type == ITEM_TYPE_FUND_10000) {
		unit = 10000;
	} else if (type == ITEM_TYPE_STOCK_BUY ||
			   type == ITEM_TYPE_ETF_BUY ||
			   type == ITEM_TYPE_CURRENCY_BUY ||
               type == ITEM_TYPE_CASH) {
		credit = TRADE_TYPE_LONGBUY;
	} else if (type == ITEM_TYPE_STOCK_SELL ||
			   type == ITEM_TYPE_ETF_SELL ||
			   type == ITEM_TYPE_CURRENCY_SELL) {
		credit = TRADE_TYPE_SHORTSELL;
	}
    for (TradeItem* trade in trades) {  // convert trade kind
        if (type == ITEM_TYPE_CASH) {
            if ([[trade kind] isEqualToString:NSLocalizedString(@"BUY",@"Buy")] == YES) {
                [trade setKind:NSLocalizedString(@"DEPOSIT",@"Deposit")];
            } else if ([[trade kind] isEqualToString:NSLocalizedString(@"SELL",@"Sell")] == YES) {
                [trade setKind:NSLocalizedString(@"WITHDRAW",@"Withdraw")];
            }
        } else {
            if ([[trade kind] isEqualToString:NSLocalizedString(@"DEPOSIT",@"Deposit")] == YES) {
                [trade setKind:NSLocalizedString(@"BUY",@"Buy")];
            } else if ([[trade kind] isEqualToString:NSLocalizedString(@"WITHDRAW",@"Withdraw")] == YES) {
                [trade setKind:NSLocalizedString(@"SELL",@"Sell")];
            }
        }
    }
	version = ITEM_VESRION;
	flagColor = ITEM_COLOR_WHITE;
	[self DoSettlement];
	return self;
}

#pragma mark Localize

- (int)itemTypeToType:(NSString*)typeString
{
	if (typeString == nil) {
		return ITEM_TYPE_OTHER;
	}
	if ([typeString isEqualToString:ITEM_TYPE_EN_STOCK] ||
		[typeString isEqualToString:ITEM_TYPE_JP_STOCK]) {
		return ITEM_TYPE_STOCK;
	}
	if ([typeString isEqualToString:ITEM_TYPE_EN_STOCK_BUY] ||
		[typeString isEqualToString:ITEM_TYPE_JP_STOCK_BUY]) {
		return ITEM_TYPE_STOCK_BUY;
	}
	if ([typeString isEqualToString:ITEM_TYPE_EN_STOCK_SELL] ||
		[typeString isEqualToString:ITEM_TYPE_JP_STOCK_SELL]) {
		return ITEM_TYPE_STOCK_SELL;
	}
	if ([typeString isEqualToString:ITEM_TYPE_EN_ETF] ||
		[typeString isEqualToString:ITEM_TYPE_JP_ETF]) {
		return ITEM_TYPE_ETF;
	}
	if ([typeString isEqualToString:ITEM_TYPE_EN_ETF_BUY] ||
		[typeString isEqualToString:ITEM_TYPE_JP_ETF_BUY]) {
		return ITEM_TYPE_ETF_BUY;
	}
	if ([typeString isEqualToString:ITEM_TYPE_EN_ETF_SELL] ||
		[typeString isEqualToString:ITEM_TYPE_JP_ETF_SELL]) {
		return ITEM_TYPE_ETF_SELL;
	}
	if ([typeString isEqualToString:ITEM_TYPE_EN_FUND] ||
		[typeString isEqualToString:ITEM_TYPE_JP_FUND]) {
		return ITEM_TYPE_FUND;
	}
	if ([typeString isEqualToString:ITEM_TYPE_EN_FUND_10000] ||
		[typeString isEqualToString:ITEM_TYPE_JP_FUND_10000]) {
		return ITEM_TYPE_FUND_10000;
	}
	if ([typeString isEqualToString:ITEM_TYPE_EN_CURRENCY] ||
		[typeString isEqualToString:ITEM_TYPE_JP_CURRENCY]) {
		return ITEM_TYPE_CURRENCY;
	}
	if ([typeString isEqualToString:ITEM_TYPE_EN_CURRENCY_BUY] ||
		[typeString isEqualToString:ITEM_TYPE_JP_CURRENCY_BUY]) {
		return ITEM_TYPE_CURRENCY_BUY;
	}
	if ([typeString isEqualToString:ITEM_TYPE_EN_CURRENCY_SELL] ||
		[typeString isEqualToString:ITEM_TYPE_JP_CURRENCY_SELL]) {
		return ITEM_TYPE_CURRENCY_SELL;
	}
	if ([typeString isEqualToString:ITEM_TYPE_EN_INDEX] ||
		[typeString isEqualToString:ITEM_TYPE_JP_INDEX]) {
		return ITEM_TYPE_INDEX;
	}
	if ([typeString isEqualToString:ITEM_TYPE_EN_CASH] ||
		[typeString isEqualToString:ITEM_TYPE_JP_CASH]) {
		return ITEM_TYPE_CASH;
	}
	if ([typeString isEqualToString:ITEM_TYPE_EN_OTHER] ||
		[typeString isEqualToString:ITEM_TYPE_JP_OTHER]) {
		return ITEM_TYPE_OTHER;
	}
	return ITEM_TYPE_STOCK;
}

- (int)itemCategory
{
	int	category = ITEM_CATEGORY_UNKNOWN;
	type = [self itemTypeToType:itemType];
	switch (type) {
		case ITEM_TYPE_STOCK:
		case ITEM_TYPE_STOCK_BUY:
		case ITEM_TYPE_STOCK_SELL:
		case ITEM_TYPE_ETF:
		case ITEM_TYPE_ETF_BUY:
		case ITEM_TYPE_ETF_SELL:
			category = ITEM_CATEGORY_STOCK;
			break;
		case ITEM_TYPE_FUND:
		case ITEM_TYPE_FUND_10000:
			category = ITEM_CATEGORY_FUND;
			break;
		case ITEM_TYPE_CURRENCY:
		case ITEM_TYPE_CURRENCY_BUY:
		case ITEM_TYPE_CURRENCY_SELL:
			category = ITEM_CATEGORY_CURRENCY;
			break;
		case ITEM_TYPE_INDEX:
			category = ITEM_CATEGORY_INDEX;
			break;
		case ITEM_TYPE_OTHER:
		case ITEM_TYPE_CASH:
		default:
			break;
	}
	return category;
}

- (NSString*)itemCurrencySymbol
{
	NSString* c;
	if (type == ITEM_TYPE_INDEX) {
		c = @"";
	} else if (customCountry == YES &&
			   [country isEqualToString:customCountryCode] == YES &&
			   [customCurrencySymbol length] != 0) {
		c = customCurrencySymbol;
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_JP] == YES) {
		c = @"¥";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_UK] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_EG] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_TR] == YES) {
		c = @"£";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_AT] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_BE] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_DE] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_ES] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_EU] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_FI] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_FR] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_GR] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_IT] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_LU] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_NL] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_PT] == YES) {
		c = @"€";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_BR] == YES) {
		c = @"B$";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_CH] == YES) {
		c = @"Fr.";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_IN] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_ID] == YES) {
		c = @"₨";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_CN] == YES) {
		c = @"Ұ";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_KR] == YES) {
		c = @"₩";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_RU] == YES) {
		c = @"руб";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_TH] == YES) {
		c = @"฿";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_PH] == YES) {
		c = @"₱";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_MX] == YES) {
		c = @"Mex$";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_VN] == YES) {
		c = @"₫";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_ZA] == YES) {
		c = @"R";		
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_AE] == YES) {
		c = @"DH";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_DK] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_NO] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_SE] == YES) {
		c = @"kr";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_MY] == YES) {
		c = @"RM";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_SA] == YES) {
		c = @"SAR";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_US] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_CA] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_HK] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_TW] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_SG] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_NZ] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_AU] == YES) {
		c = @"$";
	} else {
		c = @"¤";
	}
	return c;
}

- (NSString*)itemCurrencyNameJP
{
	NSString* c;
	if (type == ITEM_TYPE_INDEX) {
		c = @"";
	} else if (customCountry == YES &&
			   [country isEqualToString:customCountryCode] == YES &&
			   [customCurrencyCode length] != 0) {
		c = customCurrencyCode;
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_JP] == YES) {
		c = @"円";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_UK] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_TR] == YES) {
		c = @"ポンド";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_EU] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_LU] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_FR] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_IT] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_DE] == YES) {
		c = @"ユーロ";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_BR] == YES) {
		c = @"レアル";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_CH] == YES) {
		c = @"フラン";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_IN] == YES) {
		c = @"ルピー";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_ID] == YES) {
		c = @"ルピア";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_CN] == YES) {
		c = @"元";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_KR] == YES) {
		c = @"ウォン";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_RU] == YES) {
		c = @"ルーブル";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_TH] == YES) {
		c = @"バーツ";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_PH] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_MX] == YES) {
		c = @"ペソ";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_VN] == YES) {
		c = @"ドン";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_ZA] == YES) {
		c = @"ランド";
	} else if ([country isEqualToString:TRADE_ITEM_COUNTRY_US] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_CA] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_HK] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_TW] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_SG] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_NZ] == YES ||
			   [country isEqualToString:TRADE_ITEM_COUNTRY_AU] == YES) {
		c = @"ドル";
	} else {
		c = @"";
	}
	return c;
}

- (NSString*)itemCodeToUrl
{
	// Convert '^' to "%5E"
	NSString* code;
	NSRange range = [itemCode rangeOfString:@"^"];
	if (range.length > 0) {
		code = [itemCode stringByReplacingOccurrencesOfString:@"^" withString:@"%5E"];
	} else {
		code = itemCode;
	}
	return code;
}

- (NSString*)itemCodeGoogle
{
	NSString* code;
	NSRange range = [itemCode rangeOfString:@"."];
	if (range.length > 0) {
		code = [itemCode substringToIndex:range.location];
	} else {
		code = itemCode;
	}
	// Convert '^' to '.'
	range = [code rangeOfString:@"^"];
	if (range.length > 0) {
		return [code stringByReplacingOccurrencesOfString:@"^" withString:@"."];
	}
	return code;
}

- (NSString*)itemCodeYahoo
{
	NSString* code = [self itemCodeToUrl];
	NSRange range = [code rangeOfString:@":"];
	if (range.length > 0) {
		return [code substringFromIndex:range.location+1];
	}
	return code;
}

- (NSString*)itemCodeJP
{
	NSString* itemCodeYahoo = [self itemCodeYahoo];
	if (itemCodeYahoo == nil) {
		itemCodeYahoo = [self itemCodeToUrl];
	}
	NSRange range = [itemCodeYahoo rangeOfString:@"."];
	if (range.length > 0) {
		return [itemCodeYahoo substringToIndex:range.location];
	}
	return itemCodeYahoo;
}

- (NSString*)localizedItemType:(int)typeInt
{
	NSString*	typeString = nil;
	switch (typeInt) {
		case	ITEM_TYPE_STOCK:
			typeString = NSLocalizedString(@"STOCK",@"Stock:actual");
			break;
		case	ITEM_TYPE_STOCK_BUY:
			typeString = NSLocalizedString(@"STOCK_BUY",@"Stock:long");
			break;
		case	ITEM_TYPE_STOCK_SELL:
			typeString = NSLocalizedString(@"STOCK_SELL",@"Stock:short");
			break;
		case	ITEM_TYPE_ETF:
			typeString = NSLocalizedString(@"ETF",@"ETF:actual");
			break;
		case	ITEM_TYPE_ETF_BUY:
			typeString = NSLocalizedString(@"ETF_BUY",@"ETF:long");
			break;
		case	ITEM_TYPE_ETF_SELL:
			typeString = NSLocalizedString(@"ETF_SELL","ETF:short");
			break;
		case	ITEM_TYPE_FUND:
			typeString = NSLocalizedString(@"FUND",@"Fund");
			break;
		case	ITEM_TYPE_FUND_10000:
			typeString = NSLocalizedString(@"FUND_10000",@"Fund:10000unit");
			break;
		case	ITEM_TYPE_CURRENCY:
			typeString = NSLocalizedString(@"CURRENCY",@"Currency"); 
			break;
		case	ITEM_TYPE_CURRENCY_BUY:
			typeString = NSLocalizedString(@"CURRENCY_BUY",@"FX:long"); 
			break;
		case	ITEM_TYPE_CURRENCY_SELL:
			typeString = NSLocalizedString(@"CURRENCY_SEL",@"FX:short"); 
			break;
		case	ITEM_TYPE_INDEX:
			typeString = NSLocalizedString(@"INDEX",@"Index"); 
			break;
		case	ITEM_TYPE_CASH:
			typeString = NSLocalizedString(@"CASH",@"Cash");
			break;
		case ITEM_TYPE_OTHER:
		default:
			typeString = NSLocalizedString(@"OTHER",@"Other");
			break;
	}
	return typeString;
}

@synthesize		index;
@synthesize		sortKey;
@synthesize		type;
@synthesize		order;
@synthesize		itemName;
@synthesize		itemCode;
@synthesize		itemType;
@synthesize		url;
@synthesize		country;
@synthesize		price;
@synthesize		yieldTarget;
@synthesize		lossCutLimit;
@synthesize		av_price;
@synthesize		quantity;
@synthesize		unit;
@synthesize		credit;
@synthesize		date;
@synthesize		value;
@synthesize		investment;
@synthesize		profit;
@synthesize		income;
@synthesize		lproperty;
@synthesize		rise;
@synthesize		flagColor;
@synthesize		trades;
@end


@implementation PortfolioSum

- (id)init
{
	NSLog(@"init PortfolioSum");
	self = [super init];
	if (self == nil) {
		return nil;
	}
	items = 0;
	countryCode = nil;
	country = nil;
	domain = nil;
	currency = nil;
	invested = 0;
	estimated = 0;
    cash = 0;
	creditLongDealed = 0;
	creditLongEstimated = 0;
	creditShortDealed = 0;
	creditShortEstimated = 0;
	performance = 0;
	capitalGain = 0;
	incomeGain = 0;
	latentGain = 0;
	totalGain = 0;
	flagColor = ITEM_COLOR_WHITE;
	return self;
}

- (void)dealloc
{
	NSLog(@"dealloc SumPorffolio");
	if (countryCode) {
		[countryCode release];
	}
	if (currency) {
		[currency release];
	}
	[super dealloc];
}

- (void)selectFlagColor
{
	if (performance >= 0) {
		flagColor = ITEM_COLOR_WHITE;
		if (performance >= YIELD_TARGET_DEFAULT*100) {
			if (performance >= 100) {
				flagColor = ITEM_COLOR_PURPLE;
			} else if (performance >= YIELD_TARGET_DEFAULT*200) {
				flagColor = ITEM_COLOR_BLUE;
			} else {
				flagColor = ITEM_COLOR_GREEN;
			}
		}
	} else {
		flagColor = ITEM_COLOR_YELLOW;
		if (performance <= LOSSCUT_LIMIT_DEFAULT*100) {
			if (performance >= fabs(LOSSCUT_LIMIT_DEFAULT)*200) {
				flagColor = ITEM_COLOR_RED;
			} else {
				flagColor = ITEM_COLOR_ORANGE;
			}
		}
	}
    
}

@synthesize		items;
@synthesize		countryCode;
@synthesize		country;
@synthesize		domain;
@synthesize		currency;
@synthesize		invested;
@synthesize		estimated;
@synthesize		cash;
@synthesize		creditLongDealed;
@synthesize		creditLongEstimated;
@synthesize		creditShortDealed;
@synthesize		creditShortEstimated;
@synthesize		performance;
@synthesize		capitalGain;
@synthesize		incomeGain;
@synthesize		latentGain;
@synthesize		totalGain;
@synthesize		flagColor;

@end


