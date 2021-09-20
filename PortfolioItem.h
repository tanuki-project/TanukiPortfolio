//
//  PortfolioItem.h
//  tPortfolio
//
//  Created by Takahiro Sayama on 10/12/05.
//  Copyright 2011 tanuki-project. All rights reserved.
//

#import		<Foundation/Foundation.h>

#define	ITEM_VESRION_ZERO				0
#define	ITEM_VESRION					2

#define	ITEM_TYPE_CASH					0
#define	ITEM_TYPE_STOCK					1
#define	ITEM_TYPE_STOCK_BUY				2
#define	ITEM_TYPE_STOCK_SELL			3
#define	ITEM_TYPE_ETF					4
#define	ITEM_TYPE_ETF_BUY				5
#define	ITEM_TYPE_ETF_SELL				6
#define	ITEM_TYPE_FUND					7
#define	ITEM_TYPE_FUND_10000			8
#define	ITEM_TYPE_CURRENCY				9
#define	ITEM_TYPE_CURRENCY_BUY			10
#define	ITEM_TYPE_CURRENCY_SELL			11
#define	ITEM_TYPE_INDEX					12
#define	ITEM_TYPE_OTHER					99

#define	ITEM_TYPE_EN_CASH				@"Cash"
#define	ITEM_TYPE_EN_STOCK				@"Stock:actual"
#define	ITEM_TYPE_EN_STOCK_BUY			@"Stock:long"
#define	ITEM_TYPE_EN_STOCK_SELL			@"Stock:short"
#define	ITEM_TYPE_EN_ETF				@"ETF:real"
#define	ITEM_TYPE_EN_ETF_BUY			@"ETF:long"
#define	ITEM_TYPE_EN_ETF_SELL			@"ETF:short"
#define	ITEM_TYPE_EN_FUND				@"Fund"
#define	ITEM_TYPE_EN_FUND_10000			@"Fund:10000unit"
#define	ITEM_TYPE_EN_CURRENCY			@"Currency"
#define	ITEM_TYPE_EN_CURRENCY_BUY		@"FX:long"
#define	ITEM_TYPE_EN_CURRENCY_SELL		@"FX:short"
#define	ITEM_TYPE_EN_INDEX				@"Index"
#define	ITEM_TYPE_EN_OTHER				@"Other"

#define	ITEM_TYPE_JP_CASH				@"現金"
#define	ITEM_TYPE_JP_STOCK				@"株式(現物)"
#define	ITEM_TYPE_JP_STOCK_BUY			@"株式(買建)"
#define	ITEM_TYPE_JP_STOCK_SELL			@"株式(売建)"
#define	ITEM_TYPE_JP_ETF				@"ETF(現物)"
#define	ITEM_TYPE_JP_ETF_BUY			@"ETF(買建)"
#define	ITEM_TYPE_JP_ETF_SELL			@"ETF(売建)"
#define	ITEM_TYPE_JP_FUND				@"投信"
#define	ITEM_TYPE_JP_FUND_10000			@"投信(1万口)"
#define	ITEM_TYPE_JP_CURRENCY			@"外貨"
#define	ITEM_TYPE_JP_CURRENCY_BUY		@"FX(買建)"
#define	ITEM_TYPE_JP_CURRENCY_SELL		@"FX(売建)"
#define	ITEM_TYPE_JP_INDEX				@"指数"
#define	ITEM_TYPE_JP_OTHER				@"その他"

#define	ITEM_COLOR_PURPLE				@"Purple"
#define	ITEM_COLOR_BLUE					@"Blue"
#define	ITEM_COLOR_GREEN				@"Green"
#define	ITEM_COLOR_WHITE				@"White"
#define	ITEM_COLOR_YELLOW				@"Yellow"
#define	ITEM_COLOR_ORANGE				@"Orange"
#define	ITEM_COLOR_RED					@"Red"

#define	ITEM_CATEGORY_UNKNOWN			0
#define	ITEM_CATEGORY_STOCK				1
#define	ITEM_CATEGORY_CURRENCY			2
#define	ITEM_CATEGORY_FUND				3
#define	ITEM_CATEGORY_INDEX				ITEM_CATEGORY_STOCK
#define	ITEM_CATEGORY_CASH              ITEM_CATEGORY_UNKNOWN

#define	TRADE_TYPE_CASH                 0
#define	TRADE_TYPE_REALBUY				1
#define	TRADE_TYPE_LONGBUY				2
#define	TRADE_TYPE_SHORTSELL			3

#define	TRADE_ITEM_TYPE_NONE			0
#define	TRADE_ITEM_TYPE_BUY				1
#define	TRADE_ITEM_TYPE_SELL			2

#define TRADE_ITEM_TYPE_I_UNKNOWN		0
#define TRADE_ITEM_TYPE_I_BUY			1
#define TRADE_ITEM_TYPE_I_SELL			2
#define TRADE_ITEM_TYPE_I_DIVIDEND		3
#define TRADE_ITEM_TYPE_I_REINVESTMENT	4
#define TRADE_ITEM_TYPE_I_SPLIT			5
#define TRADE_ITEM_TYPE_I_ESTIMATE		6
#define TRADE_ITEM_TYPE_I_DEPOSIT		7
#define TRADE_ITEM_TYPE_I_WITHDRAW		8
#define TRADE_ITEM_TYPE_I_INTEREST		9

#define TRADE_ITEM_TYPE_EN_BUY			@"Buy"
#define TRADE_ITEM_TYPE_EN_SELL			@"Sell"
#define TRADE_ITEM_TYPE_EN_DIVIDEND		@"Dividend"
#define TRADE_ITEM_TYPE_EN_REINVESTMENT	@"Reinvestment"
#define TRADE_ITEM_TYPE_EN_SPLIT		@"Split"
#define TRADE_ITEM_TYPE_EN_ESTIMATE		@"Estimate"
#define TRADE_ITEM_TYPE_EN_NOTE			@"Note"
#define TRADE_ITEM_TYPE_EN_DEPOSIT		@"Deposit"
#define TRADE_ITEM_TYPE_EN_WITHDRAW		@"Withdraw"
#define TRADE_ITEM_TYPE_EN_INTEREST		@"Interest"

#define TRADE_ITEM_TYPE_JP_BUY			@"買付"
#define TRADE_ITEM_TYPE_JP_SELL			@"売付"
#define TRADE_ITEM_TYPE_JP_DIVIDEND		@"配当・分配"
#define TRADE_ITEM_TYPE_JP_REINVESTMENT	@"再投資"
#define TRADE_ITEM_TYPE_JP_SPLIT		@"分割"
#define TRADE_ITEM_TYPE_JP_ESTIMATE		@"評価額"
#define TRADE_ITEM_TYPE_JP_NOTE			@"記録"
#define TRADE_ITEM_TYPE_JP_DEPOSIT		@"入金"
#define TRADE_ITEM_TYPE_JP_WITHDRAW		@"出金"
#define TRADE_ITEM_TYPE_JP_INTEREST		@"金利"

#define	TRADE_ITEM_ORDER_ASCENDING		YES
#define	TRADE_ITEM_ORDER_DESCENDING		NO

#define	TRADE_ITEM_COUNTRY_AD			@"AD"
#define	TRADE_ITEM_COUNTRY_AE			@"AE"
#define	TRADE_ITEM_COUNTRY_AM			@"AM"
#define	TRADE_ITEM_COUNTRY_AO			@"AO"
#define	TRADE_ITEM_COUNTRY_AR			@"AR"
#define	TRADE_ITEM_COUNTRY_AT			@"AT"
#define	TRADE_ITEM_COUNTRY_AU			@"AU"
#define	TRADE_ITEM_COUNTRY_AZ			@"AZ"
#define	TRADE_ITEM_COUNTRY_BE			@"BE"
#define	TRADE_ITEM_COUNTRY_BG			@"BG"
#define	TRADE_ITEM_COUNTRY_BH			@"BH"
#define	TRADE_ITEM_COUNTRY_BN			@"BN"
#define	TRADE_ITEM_COUNTRY_BO			@"BO"
#define	TRADE_ITEM_COUNTRY_BR			@"BR"
#define	TRADE_ITEM_COUNTRY_BT			@"BT"
#define	TRADE_ITEM_COUNTRY_CA			@"CA"
#define	TRADE_ITEM_COUNTRY_CH			@"CH"
#define	TRADE_ITEM_COUNTRY_CL			@"CL"
#define	TRADE_ITEM_COUNTRY_CN			@"CN"
#define	TRADE_ITEM_COUNTRY_CO			@"CO"
#define	TRADE_ITEM_COUNTRY_CR			@"CR"
#define	TRADE_ITEM_COUNTRY_CY			@"CY"
#define	TRADE_ITEM_COUNTRY_CZ			@"CZ"
#define	TRADE_ITEM_COUNTRY_DE			@"DE"
#define	TRADE_ITEM_COUNTRY_DK			@"DK"
#define	TRADE_ITEM_COUNTRY_DO			@"DO"
#define	TRADE_ITEM_COUNTRY_DZ			@"DZ"
#define	TRADE_ITEM_COUNTRY_EC			@"EC"
#define	TRADE_ITEM_COUNTRY_EE			@"EE"
#define	TRADE_ITEM_COUNTRY_EG			@"EG"
#define	TRADE_ITEM_COUNTRY_ES			@"ES"
#define	TRADE_ITEM_COUNTRY_EU			@"EU"
#define	TRADE_ITEM_COUNTRY_FI			@"FI"
#define	TRADE_ITEM_COUNTRY_FR			@"FR"
#define	TRADE_ITEM_COUNTRY_GR			@"GR"
#define	TRADE_ITEM_COUNTRY_GT			@"GT"
#define	TRADE_ITEM_COUNTRY_HK			@"HK"
#define	TRADE_ITEM_COUNTRY_HN			@"HN"
#define	TRADE_ITEM_COUNTRY_HR			@"HR"
#define	TRADE_ITEM_COUNTRY_HU			@"HU"
#define	TRADE_ITEM_COUNTRY_ID			@"ID"
#define	TRADE_ITEM_COUNTRY_IE			@"IE"
#define	TRADE_ITEM_COUNTRY_IL			@"IL"
#define	TRADE_ITEM_COUNTRY_IN			@"IN"
#define	TRADE_ITEM_COUNTRY_IR			@"IR"
#define	TRADE_ITEM_COUNTRY_IS			@"IS"
#define	TRADE_ITEM_COUNTRY_IT			@"IT"
#define	TRADE_ITEM_COUNTRY_JM			@"JM"
#define	TRADE_ITEM_COUNTRY_JP			@"JP"
#define	TRADE_ITEM_COUNTRY_KE			@"KE"
#define	TRADE_ITEM_COUNTRY_KH			@"KH"
#define	TRADE_ITEM_COUNTRY_KR			@"KR"
#define	TRADE_ITEM_COUNTRY_KW			@"KW"
#define	TRADE_ITEM_COUNTRY_KZ			@"KZ"
#define	TRADE_ITEM_COUNTRY_LB			@"LB"
#define	TRADE_ITEM_COUNTRY_LK			@"LK"
#define	TRADE_ITEM_COUNTRY_LT			@"LT"
#define	TRADE_ITEM_COUNTRY_LU			@"LU"
#define	TRADE_ITEM_COUNTRY_LV			@"LV"
#define	TRADE_ITEM_COUNTRY_ML			@"ML"
#define	TRADE_ITEM_COUNTRY_MN			@"MN"
#define	TRADE_ITEM_COUNTRY_MO			@"MO"
#define	TRADE_ITEM_COUNTRY_MT			@"MT"
#define	TRADE_ITEM_COUNTRY_MX			@"MX"
#define	TRADE_ITEM_COUNTRY_MY			@"MY"
#define	TRADE_ITEM_COUNTRY_NG			@"NG"
#define	TRADE_ITEM_COUNTRY_NL			@"NL"
#define	TRADE_ITEM_COUNTRY_NO			@"NO"
#define	TRADE_ITEM_COUNTRY_NZ			@"NZ"
#define	TRADE_ITEM_COUNTRY_OM			@"OM"
#define	TRADE_ITEM_COUNTRY_PA			@"PA"
#define	TRADE_ITEM_COUNTRY_PE			@"PE"
#define	TRADE_ITEM_COUNTRY_PH			@"PH"
#define	TRADE_ITEM_COUNTRY_PK			@"PK"
#define	TRADE_ITEM_COUNTRY_PL			@"PL"
#define	TRADE_ITEM_COUNTRY_PT			@"PT"
#define	TRADE_ITEM_COUNTRY_PY			@"PY"
#define	TRADE_ITEM_COUNTRY_RO			@"RO"
#define	TRADE_ITEM_COUNTRY_RU			@"RU"
#define	TRADE_ITEM_COUNTRY_SA			@"SA"
#define	TRADE_ITEM_COUNTRY_SE			@"SE"
#define	TRADE_ITEM_COUNTRY_SG			@"SG"
#define	TRADE_ITEM_COUNTRY_SI			@"SI"
#define	TRADE_ITEM_COUNTRY_SK			@"SK"
#define	TRADE_ITEM_COUNTRY_SN			@"SN"
#define	TRADE_ITEM_COUNTRY_SV			@"SV"
#define	TRADE_ITEM_COUNTRY_TH			@"TH"
#define	TRADE_ITEM_COUNTRY_TR			@"TR"
#define	TRADE_ITEM_COUNTRY_TW			@"TW"
#define	TRADE_ITEM_COUNTRY_UK			@"UK"
#define	TRADE_ITEM_COUNTRY_US			@"US"
#define	TRADE_ITEM_COUNTRY_UY			@"UY"
#define	TRADE_ITEM_COUNTRY_VE			@"VE"
#define	TRADE_ITEM_COUNTRY_VN			@"VN"
#define	TRADE_ITEM_COUNTRY_YE			@"YE"
#define	TRADE_ITEM_COUNTRY_ZA			@"ZA"

#define	TRADE_ITEM_CURRENCY_AE			@"AED"
#define	TRADE_ITEM_CURRENCY_AR			@"ARS"
#define	TRADE_ITEM_CURRENCY_AU			@"AUD"
#define	TRADE_ITEM_CURRENCY_BR			@"BRL"
#define	TRADE_ITEM_CURRENCY_CA			@"CAD"
#define	TRADE_ITEM_CURRENCY_CH			@"CHF"
#define	TRADE_ITEM_CURRENCY_CN			@"CNY"
#define	TRADE_ITEM_CURRENCY_CZ			@"CZK"
#define	TRADE_ITEM_CURRENCY_DE			@"DKK"
#define	TRADE_ITEM_CURRENCY_EG			@"EGP"
#define	TRADE_ITEM_CURRENCY_EU			@"EUR"
#define	TRADE_ITEM_CURRENCY_IN			@"INR"
#define	TRADE_ITEM_CURRENCY_HK			@"HKD"
#define	TRADE_ITEM_CURRENCY_HU			@"HUF"
#define	TRADE_ITEM_CURRENCY_ID			@"IDR"
#define	TRADE_ITEM_CURRENCY_IE			@"LTL"
#define	TRADE_ITEM_CURRENCY_JP			@"JPY"
#define	TRADE_ITEM_CURRENCY_KR			@"KRW"
#define	TRADE_ITEM_CURRENCY_MX			@"MXN"
#define	TRADE_ITEM_CURRENCY_MY			@"MYR"
#define	TRADE_ITEM_CURRENCY_NO			@"NOK"
#define	TRADE_ITEM_CURRENCY_NZ			@"NZD"
#define	TRADE_ITEM_CURRENCY_PH			@"PHP"
#define	TRADE_ITEM_CURRENCY_RU			@"RUB"
#define	TRADE_ITEM_CURRENCY_RO			@"RON"
#define	TRADE_ITEM_CURRENCY_SA			@"SAR"
#define	TRADE_ITEM_CURRENCY_SE			@"SEK"
#define	TRADE_ITEM_CURRENCY_SG			@"SGD"
#define	TRADE_ITEM_CURRENCY_TH			@"THB"
#define	TRADE_ITEM_CURRENCY_TR			@"TRY"
#define	TRADE_ITEM_CURRENCY_TW			@"TWD"
#define	TRADE_ITEM_CURRENCY_UK			@"GBP"
#define	TRADE_ITEM_CURRENCY_US			@"USD"
#define	TRADE_ITEM_CURRENCY_VN			@"VND"
#define	TRADE_ITEM_CURRENCY_ZA			@"ZAR"

#define INITIAL_IR_SITE					@"http://"

#define	YIELD_TARGET_DEFAULT			0.25
#define	YIELD_TARGET_MAX				0.999
#define	YIELD_TARGET_MIN				0.001
#define	LOSSCUT_LIMIT_DEFAULT			-0.15
#define	LOSSCUT_LIMIT_MAX				-0.001
#define	LOSSCUT_LIMIT_MIN				-0.999

#pragma mark TradeIten

@interface TradeItem : NSObject {
	int			index;
	/* 入力データ */
	NSDate*		date;		// 日付
	NSString*	kind;		// 取引種別
	double		price;		// 価格
	double		buy;		// 買数量
	double		sell;		// 売数量
	double		charge;		// 手数料
	double		dividend;	// 配当・分配金
	double		tax;		// 税金
	NSString*	comment;	// コメント
	
	/* 集計データ */
	double		settlement;	// 受渡し金額
	double		quantity;	// 取引後保有数量
	double		av_price;	// 取引後平均単価
	double		profit;		// 取引時売買益
	double		value;		// 取引後評価額
	double		investment;	// 投資額
	double		lprofit;	// 含み益
}

- (id) init;
- (id) initWith: (NSDate*)date :(NSString*)kind :(double)price :(double)quantity :(int)unit :(double)charge :(double)dividend :(double)tax :(NSString*)comment :(NSString*)country;
- (int) tradeTypeToType:(NSString*)typeString;

@property	(readwrite)			int			index;
@property	(readwrite,copy)	NSDate*		date;
@property	(readwrite,copy)	NSString*	kind;
@property	(readwrite,copy)	NSString*	comment;
@property	(readwrite)			double		price;
@property	(readwrite)			double		buy;
@property	(readwrite)			double		sell;
@property	(readwrite)			double		settlement;
@property	(readwrite)			double		charge;
@property	(readwrite)			double		dividend;
@property	(readwrite)			double		tax;
@property	(readwrite)			double		quantity;
@property	(readwrite)			double		av_price;
@property	(readwrite)			double		profit;
@property	(readwrite)			double		value;
@property	(readwrite)			double		investment;
@property	(readwrite)			double		lprofit;
@end

#pragma mark PortfolioItem

@interface PortfolioItem : NSObject <NSCoding> {
	/* 管理情報 */
	int				version;        // Vresion of format
	int				index;          // Index
	int				sortKey;        // sort key
	int				type;           // record type
	bool			order;          // record order
	NSDate*			created;        // 日付
    int64_t         status;         // status

	/* 入力データ */
	NSString*		itemName;		// 銘柄名
	NSString*		itemCode;		// 銘柄コード
	NSString*		itemType;		// 銘柄種別
	double			price;			// 価格
	double			quantity;		// 数量
	int				unit;			// 単位
	int				credit;			// 信用取引
	NSString*		url;			// IR Site
	NSString*		country;		// 国名
    NSString*		comment;		// コメント
	double			yieldTarget;	// 目標価格
	double			lossCutLimit;	// ロスカット価格

	/* 集計データ */
	double			value;          // 現評価額
	double			investment;     // 現投資額
	double			reinvest;       // 現再投資額
	double			av_price;       // 現平均単価
	double			profit;         // 累積売買益
	double			income;         // 累積配当益
	double			lproperty;      // 現含み益
	double			rise;           // 騰落率
	NSString*		flagColor;      // 色

	NSDate*			date;           // 日付
	NSMutableArray*	trades;         // 取引履歴
}

- (id) init;
- (void) Clear;
- (void) Add:(TradeItem*)trade;
- (void) Add:(NSDate*)date :(NSString*)kind :(double)price :(double)quantity :(int)unit :(double)charge :(double)dividend :(double)tax :(NSString*)comment;
- (void) Remove:(TradeItem*)trade;
- (void) RemoveById:(int)id;
- (void) ApplyPriceTag:(NSDate*)date :(double)price;
- (void) RemovePriceTag:(NSDate*)date;
- (TradeItem*) Search:(int)id;
- (TradeItem*) Search:(NSDate*)date :(int)type;
- (bool) RebuildTrades;
- (void) DoSettlement;
- (void) DoSettlementBuy;
- (void) DoSettlementSell;
- (double) GetQuantity;
- (double) GetValue;
- (double) GetPriceByDate:(NSDate*)date;
- (double) GetRecordedPrice:(NSDate*)date;
- (void) SortTradesByDate;
- (int)itemTypeToType:(NSString*)typeString;
- (int)itemCategory;
- (NSString*)itemCurrencySymbol;
- (NSString*)itemCurrencyNameJP;
- (NSString*)itemCodeToUrl;
- (NSString*)itemCodeGoogle;
- (NSString*)itemCodeYahoo;
- (NSString*)itemCodeJP;
- (NSString*)localizedItemType:(int)typeInt;

@property	(readwrite)			int				index;
@property	(readwrite)			int				sortKey;
@property	(readwrite)			int				type;
@property	(readwrite)			bool			order;
@property	(readwrite,copy)	NSString*		itemName;
@property	(readwrite,copy)	NSString*		itemCode;
@property	(readwrite,copy)	NSString*		itemType;
@property	(readwrite,copy)	NSString*		url;
@property	(readwrite,copy)	NSString*		country;
@property	(readwrite)			double			price;
@property	(readwrite)			double			yieldTarget;
@property	(readwrite)			double			lossCutLimit;
@property	(readwrite)			double			av_price;
@property	(readwrite)			double			quantity;
@property	(readwrite)			int				unit;
@property	(readwrite)			int				credit;
@property	(readwrite,copy)	NSDate*			date;
@property	(readwrite)			double			value;
@property	(readwrite)			double			investment;
@property	(readwrite)			double			profit;
@property	(readwrite)			double			income;
@property	(readwrite)			double			lproperty;
@property	(readwrite)			double			rise;
@property	(readwrite,copy)	NSString*		flagColor;
@property	(readwrite,copy)	NSMutableArray*	trades;
@end

#pragma mark PortfolioSum

@interface PortfolioSum : NSObject {
	int			items;					// 銘柄数
	NSString*	countryCode;			// 国名
	NSString*	country;				// 国名
	NSString*	domain;					// ドメイン
	NSString*	currency;				// 通貨
	double		invested;				// 投資額
	double		estimated;				// 評価額
	double		cash;                   // 評価額
	double		creditLongDealed;		// 信用買建額
	double		creditLongEstimated;	// 信用買建評価額
	double		creditShortDealed;		// 信用売建額
	double		creditShortEstimated;	// 信用売建評価額
	double		performance;			// 騰落率
	double		capitalGain;			// 譲渡益
	double		incomeGain;				// 配当益
	double		latentGain;				// 含み益
	double		totalGain;				// 収支
	NSString*	flagColor;              // 色
}

- (id) init;
- (void)selectFlagColor;

@property	(readwrite)			int			items;
@property	(readwrite,copy)	NSString*	countryCode;
@property	(readwrite,copy)	NSString*	country;
@property	(readwrite,copy)	NSString*	domain;
@property	(readwrite,copy)	NSString*	currency;
@property	(readwrite)			double		invested;
@property	(readwrite)			double		estimated;
@property	(readwrite)			double		cash;
@property	(readwrite)			double		creditLongDealed;
@property	(readwrite)			double		creditLongEstimated;
@property	(readwrite)			double		creditShortDealed;
@property	(readwrite)			double		creditShortEstimated;
@property	(readwrite)			double		performance;
@property	(readwrite)			double		capitalGain;
@property	(readwrite)			double		incomeGain;
@property	(readwrite)			double		latentGain;
@property	(readwrite)			double		totalGain;
@property	(readwrite,copy)	NSString*	flagColor;

@end

