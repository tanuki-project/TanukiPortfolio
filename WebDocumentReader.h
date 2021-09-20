//
//  WebDocumentReader.h
//  tPortfolio
//
//  Created by Takahiro Sayama on 11/01/01.
//  Copyright 2011 tanuki-project. All rights reserved.
//

#import		<Cocoa/Cocoa.h>
#import		<WebKit/WebKit.h>

@class	MyDocument;
@class	PortfolioItem;
@class	Bookmark;

#pragma mark JP Web site

#define	URL_TANUKI_PROJECT				@"http://www012.upp.so-net.ne.jp/tanuki-project/"
#define	URL_YAHOO_JP_FINANCE			@"http://finance.yahoo.co.jp/"
#define	URL_MINKABU						@"http://minkabu.jp/"
#define	URL_GOOGLE_JP					@"http://google.co.jp/"
#define	URL_TICKER_LOOKUP_JP			URL_YAHOO_JP_FINANCE
#define	URL_TICKER_LOOKUP_JP_FUND		@"http://www.bloomberg.co.jp/apps/data?pid=jp09_ticker_lookup"
#define	DEFAULT_JP_WEB_SITE				URL_YAHOO_JP_FINANCE

#define	FORMAT_MINKABU_JP_STOCK			@"http://minkabu.jp/stock/%@#contents"
#define	FORMAT_YAHOO_JP_STOCK			@"http://stocks.finance.yahoo.co.jp/stocks/detail/?code=%@#financeSearch"
#define	FORMAT_YAHOO_JP_JPY				@"http://stocks.finance.yahoo.co.jp/stocks/detail/?code=%@JPY#financeSearch"
#define	FORMAT_YAHOO_JP_USD				@"http://stocks.finance.yahoo.co.jp/stocks/detail/?code=%@USD#financeSearch"
#define	FORMAT_YAHOO_JP_GBP				@"http://stocks.finance.yahoo.co.jp/stocks/detail/?code=%@GBP#financeSearch"
#define	FORMAT_YAHOO_JP_EUR				@"http://stocks.finance.yahoo.co.jp/stocks/detail/?code=%@EUR#financeSearch"
#define	FORMAT_YAHOO_JP_CAD				@"http://stocks.finance.yahoo.co.jp/stocks/detail/?code=%@CAD#financeSearch"
#define	FORMAT_YAHOO_JP_AUD				@"http://stocks.finance.yahoo.co.jp/stocks/detail/?code=%@AUD#financeSearch"
#define	FORMAT_YAHOO_JP_CHF				@"http://stocks.finance.yahoo.co.jp/stocks/detail/?code=%@CHF#financeSearch"
#define	FORMAT_YAHOO_JP_YY				@"http://stocks.finance.yahoo.co.jp/stocks/detail/?code=%@%@#financeSearch"
#define	FORMAT_YAHOO_JP_FUND			@"http://stocks.finance.yahoo.co.jp/stocks/detail/?code=%@"
#define	FORMAT_BLOOMBERG_JP_FUND        @"http://www.bloomberg.co.jp/apps/quote?T=jp09/quote.wm&ticker=%@:JP"

#define	PREFIX_MINKABU_JP_STOCK			@"http://minkabu.jp/stock/"
#define	PREFIX_YAHOO_JP_STOCK			@"http://stocks.finance.yahoo.co.jp/stocks/detail/"
#define	PREFIX_YAHOO_JP_FUND			@"http://www.morningstar.co.jp/webasp/yahoo-fund/fund/"
#define	PREFIX_MORNINGSTAR_JP_FUND		@"http://www.morningstar.co.jp/FundData/SnapShot.do"
#define	PREFIX_BLOOMBERG_JP_FUND        @"http://www.bloomberg.co.jp/apps/quote?"

#define	FILTER_MINKABU_JP_FROM1			@"stock-for-securities-company"
#define	FILTER_MINKABU_JP_FROM2			@"data-price=\""
#define	FILTER_MINKABU_JP_TO1			@"</div>"
#define	FILTER_MINKABU_JP_TO2			@"\" "
//#define FILTER_MINKABU_JP_RM            @"<span class=\"decimal\">"

#define	FILTER_YAHOO_JP_FROM1			@"mainStocksPriceBoard"
#define	FILTER_YAHOO_JP_FROM2			@"\"price\":\""
#define	FILTER_YAHOO_JP_TO1				@"mainIndicatorDetail"
#define	FILTER_YAHOO_JP_TO2				@"\","

#define	FILTER_YAHOO_JP_FX_FROM1		@"<table class=\"stocksTable\" summary=\"株価詳細\">"
#define FILTER_YAHOO_JP_FX_FROM2        @"<td class=\"stoksPrice\">"
#define FILTER_YAHOO_JP_FX_TO1          @"</table>"
#define FILTER_YAHOO_JP_FX_TO2          @"</td>"

#define	FILTER_YAHOO_JP_FUND_FROM1		@"mainFundPriceBoard"
#define	FILTER_YAHOO_JP_FUND_FROM2		@"\"price\":\""
//#define	FILTER_YAHOO_JP_FUND_FROM3		@"<p>基準価額</p>"
#define	FILTER_YAHOO_JP_FUND_TO2		@"\","
#define	FILTER_YAHOO_JP_FUND_TO1		@"mainFundRanking"

#define	FILTER_MORNINGSTAR_JP_FROM1		@"<div class=\"fundnamea\">"
#define	FILTER_MORNINGSTAR_JP_FROM2		@"<table class=\"tpdt\">"
#define	FILTER_MORNINGSTAR_JP_FROM3		@"<span class=\"fprice\">"
#define	FILTER_MORNINGSTAR_JP_TO1		@"<!--/topdata-->"
#define	FILTER_MORNINGSTAR_JP_TO2		@"</span>円</td>"

#define	FILTER_BLOOMBERG_JP_FROM1		@"<div class=\"schema-org-financial-quote\">"
#define	FILTER_BLOOMBERG_JP_FROM2		@"<meta itemprop=\"tickerSymbol\""
#define	FILTER_BLOOMBERG_JP_FROM3		@"<meta itemprop=\"price\" content=\""
#define	FILTER_BLOOMBERG_JP_TO1         @"<meta itemprop=\"priceChange\""
#define	FILTER_BLOOMBERG_JP_TO2         @"\" />"

#pragma mark US web site

#define	URL_YAHOO_US_FINANCE			@"http://finance.yahoo.com/"
#define	URL_GOOGLE_US					@"http://google.com/"
#define	URL_GOOGLE_FINANCE				@"http://www.google.com/finance"
#define	URL_TICKER_LOOKUP_US			@"http://finance.yahoo.com/lookup"
#define	DEFAULT_US_WEB_SITE				URL_YAHOO_US_FINANCE

#define	FORMAT_YAHOO_US_STOCK			@"http://finance.yahoo.com/q?s=%@#yfi_doc"
#define	FORMAT_YAHOO_US_FX				@"http://finance.yahoo.com/q?s=%@=X#yfi_doc"
#define	FORMAT_YAHOO_US_USD				@"http://finance.yahoo.com/q?s=%@USD=X#yfi_doc"
#define	FORMAT_YAHOO_US_JPY				@"http://finance.yahoo.com/q?s=%@JPY=X#yfi_doc"
#define	FORMAT_MORNINGSTAR_US_FUND		@"http://quote.morningstar.com/fund/f.aspx?Country=USA&Symbol=%@#TickerWrapper"
#define	FORMAT_MORNINGSTAR_US_STOCK		@"http://quote.morningstar.com/stock/s.aspx?t=%@#TickerWrapper"
#define	FORMAT_GOOGLE_FINANCE			@"http://www.google.com/finance?q=%@"
#define	FORMAT_GOOGLE_FINANCE_JPY		@"http://www.google.com/finance?q=%@JPY"
#define	FORMAT_GOOGLE_FINANCE_USD		@"http://www.google.com/finance?q=%@USD"
#define	FORMAT_GOOGLE_FINANCE_GBP		@"http://www.google.com/finance?q=%@GBP"
#define	FORMAT_GOOGLE_FINANCE_EUR		@"http://www.google.com/finance?q=%@EUR"
#define	FORMAT_GOOGLE_FINANCE_CAD		@"http://www.google.com/finance?q=%@CAD"
#define	FORMAT_GOOGLE_FINANCE_AUD		@"http://www.google.com/finance?q=%@AUD"
#define	FORMAT_GOOGLE_FINANCE_FX		@"http://www.google.com/finance?q=%@%@"

#define	PREFIX_YAHOO_US_STOCK			@"http://finance.yahoo.com/q?s="
#define	PREFIX_MORNINGSTAR_US_FUND		@"http://quote.morningstar.com/fund/"
#define	PREFIX_MORNINGSTAR_US_STOCK		@"http://quote.morningstar.com/stock/"
#define	PREFIX_GOOGLE_FINANCE			@"http://www.google.com/finance?q="

#define	FILTER_YAHOO_US_FROM1           @"<div class=\"yfi_rt_quote_summary\""
#define	FILTER_YAHOO_US_FROM2			@"<span id=\"yfs_l84_%@\">"
#define	FILTER_YAHOO_US_FROM2_FX		@"<span id=\"yfs_l10_%@=x\">"
#define	FILTER_YAHOO_US_FROM2_USD		@"<span id=\"yfs_l10_%@usd=x\">"
#define	FILTER_YAHOO_US_TO1				@"<div id=\"yfi_headlines\" class=\"yfi_quote_headline\">"
#define	FILTER_YAHOO_US_TO2             @"</span></span>"
#define	FILTER_YAHOO_US_FROM1_PREV		@"<div id=\"yfi_investing_head\">"
#define	FILTER_YAHOO_US_FROM2_PREV		@"<span id=\"yfs_l10_%@\">"
#define	FILTER_YAHOO_US_TO2_PREV		@"</span></b>"

#define FILTER_YAHOO_MOBILE_FROM1       @"<span class=\"title\"><font color=\"\">%@</font></span><br/>"
#define FILTER_YAHOO_MOBILE_FROM1_IX    @"<span class=\"title\"><font color=\"\">^%@</font></span><br/>"
#define FILTER_YAHOO_MOBILE_FROM1_FX    @"<span class=\"title\"><font color=\"\">%@=X</font></span><br/>"
#define	FILTER_YAHOO_MOBILE_FROM1_YY	@"<span class=\"title\"><font color=\"\">%@%@=X</font></span><br/>"
#define FILTER_YAHOO_MOBILE_FROM2       @"<span class=\"title\"><font color=\"\"><b>"
#define FILTER_YAHOO_MOBILE_TO1         @"<font color=\"\">Open:</font>"
#define FILTER_YAHOO_MOBILE_TO2         @"</b></font>"

#define	FILTER_GOOGLE_FROM1				@"data-last-normal-market-timestamp="
#define	FILTER_GOOGLE_FROM2				@"<span class=\"pr\">"
#define	FILTER_GOOGLE_FROM2_FUND		@"<span class=pr>"
#define	FILTER_GOOGLE_FROM3				@"_l\">"
#define	FILTER_GOOGLE_TO1				@"<div class=mdata-dis>"
#define	FILTER_GOOGLE_TO1_FUND			@"<div class=chart>"
#define	FILTER_GOOGLE_TO2				@"</div>"

//#define FILTER_GOOGLE_FROM1             @"data-last-normal-market-timestamp="
//#define    FILTER_GOOGLE_FROM2                @"<span class=\"pr\">"
//#define FILTER_GOOGLE_FROM2_FX          @"data-tz-offset="
//#define    FILTER_GOOGLE_FROM3                @"_l\">"
//#define FILTER_GOOGLE_FROM3_FX          @"<div class=\"YMlKec fxKbKc\">"
//#define    FILTER_GOOGLE_TO1                @"<div class=mdata-dis>"
//#define FILTER_GOOGLE_TO1_FX            @"https://www.google.com/"
//#define FILTER_GOOGLE_TO2               @"</div>"

#pragma mark xx.finance.yahoo.com

#define	URL_YAHOO_XX_FINANCE			@"http://%@.finance.yahoo.com/"
#define	FORMAT_YAHOO_XX_STOCK			@"http://%@.finance.yahoo.com/q?s=%@#yfi_doc"
#define	FORMAT_YAHOO_XX_FX				@"http://%@.finance.yahoo.com/q?s=%@=X#yfi_doc"
#define	FORMAT_YAHOO_XX_YY				@"http://%@.finance.yahoo.com/q?s=%@%@=X#yfi_doc"
#define	FORMAT_YAHOO_XX_JPY				@"http://%@.finance.yahoo.com/q?s=%@JPY=X#yfi_doc"
#define	PREFIX_YAHOO_XX_STOCK			@"http://%@.finance.yahoo.com/q?s="
#define	FILTER_YAHOO_XX_FROM2_YY		@"<span id=\"yfs_l10_%@%@=x\">"

#define	PREFIX_YAHOO_FR_STOCK			@"http://fr.finance.yahoo.com/q?s="
#define	PREFIX_YAHOO_IT_STOCK			@"http://it.finance.yahoo.com/q?s="
#define	PREFIX_YAHOO_ES_STOCK			@"http://es.finance.yahoo.com/q?s="
#define	PREFIX_YAHOO_BR_STOCK			@"http://br.finance.yahoo.com/q?s="

#pragma mark de.finance.yahoo.com

#define	URL_YAHOO_DE_FINANCE			@"http://de.finance.yahoo.com/"
#define	FORMAT_YAHOO_DE_STOCK			@"http://de.finance.yahoo.com/q?s=%@#yfi_doc"
#define	FORMAT_YAHOO_DE_FX				@"http://de.finance.yahoo.com/q?s=%@=X#yfi_doc"
#define	FORMAT_YAHOO_DE_EUR				@"http://de.finance.yahoo.com/q?s=%@EUR=X#yfi_doc"
#define	FORMAT_YAHOO_DE_CHF				@"http://de.finance.yahoo.com/q?s=%@CHF=X#yfi_doc"
#define	FORMAT_YAHOO_DE_JPY				@"http://de.finance.yahoo.com/q?s=%@JPY=X#yfi_doc"
#define	PREFIX_YAHOO_DE_STOCK			@"http://de.finance.yahoo.com/q?s="
#define	FILTER_YAHOO_DE_FROM2_EUR		@"<span id=\"yfs_l10_%@eur=x\">"
#define	FILTER_YAHOO_DE_FROM2_CHF		@"<span id=\"yfs_l10_%@chf=x\">"

#define	CRAWLING_TIMER_CMD_CNT			0
#define	CRAWLING_TIMER_CMD_CANCEL		1
#define	CRAWLING_TIMER_CMD_SCROLL		2

#define WEB_AUTOSCROLL_COUNT            2
#define BOOKMARK_AUTOSCROLL_COUNT       8
#define AUTOPILOT_WAIT_TIMER            5.0
#define AUTOPILOT_CONT_TIMER            3.6
#define AUTOPILOT_CANCEL_TIMER          12.0
#define AUTOSCROLL_TIMER                0.10

#pragma mark class

@interface WebDocumentReader : NSObject {
	MyDocument*			doc;
	PortfolioItem*		targetItem;
	int					connectionIndex;
	bool				connectionRetry;
	bool				connectAscending;
	int					modifiedPrice;
	double				targetPrice;
	bool				compareLastHistory;
	NSString*			strPrice;
	NSString*			documentTitle;
	NSString*			documentUrl;
	NSMutableData*		documentData;
	NSString*			documentContent;
	bool				crawling;
	bool				crawlingPaused;
	NSMutableArray*		crawlingList;
	int					crawlingIndex;
	NSTimer*			crawlingTimer;
	int					crawlingTimerCmd;
	NSTimer*			scrollTimer;
    int                 scrollCount;
    int                 maxScrollCount;
	NSURLConnection*	lastConnection;
}

- (void)startConnection:(NSURLRequest*)req;
- (void)getCompareSetting;
- (int)getItemPrice;
- (int)getItemPriceJP;
- (int)getItemPriceCom;
- (void)purgeDocumentData;
- (int)createCrawlingList:(bool)yahoo :(bool)google :(bool)minkabu :(bool)ir;
- (int)createCrawlingList:(NSMutableArray*)bookmarks;
- (void)deleteCrawlingList;
- (void)clearCrawlingList;
- (void)addItemToCrawlingList:(NSString*)url;
- (void)startCrawling;
- (void)startCrawling:(bool)yahoo :(bool)google :(bool)minkabu :(bool)ir;
- (void)startCrawlingBookmark;
- (void)stopCrawling:(bool)warn;
- (void)continueCrawling;
- (void)pauseCrawling:(bool)pause;
- (void)startTimerCrawling:(int)cmd;
- (void)stopTimerCrawling;
- (void)checkTimerCrawling:(NSTimer*)timer;
- (void)startTimerScroll;
- (void)stopTimerScroll;
- (void)checkTimerScroll:(NSTimer*)timer;

@property	(readwrite,assign)	PortfolioItem	*targetItem;
@property	(readwrite,assign)	MyDocument		*doc;

@property	(readwrite,copy)	NSString*		documentUrl;
@property	(readwrite)			int				connectionIndex;
@property	(readwrite)			bool			connectionRetry;
@property	(readwrite)			bool			connectAscending;
@property	(readwrite)			bool			crawling;
@property	(readwrite)			int				modifiedPrice;
@property	(readwrite)			int				scrollCount;
@end
