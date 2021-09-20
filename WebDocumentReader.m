//
//  WebDocumentReader.m
//  tPortfolio
//
//  Created by Takahiro Sayama on 11/01/01.
//  Copyright 2011 tanuki-project. All rights reserved.
//

#import		"WebDocumentReader.h"
#import		"PortfolioItem.h"
#import		"infoPanel.h"
#include	"MyDocument.h"
#include	"Bookmark.h"
#include	"AppController.h"
#include    "RssReader.h"

extern AppController	*tPrtController;

@implementation WebDocumentReader

- (id)init
{
	doc = [tPrtController mainDoc];
	documentTitle = nil;
	documentUrl = nil;
	documentContent = nil;
	documentData = nil;
	targetItem = nil;
	targetPrice = 0;
	connectionIndex = 0;
	connectionRetry = NO;
	connectAscending = YES;
	crawling = NO;
	crawlingPaused = NO;
	crawlingList=nil;
	crawlingIndex = 0;
	lastConnection = nil;
	strPrice = nil;
	compareLastHistory = NO;
    crawlingTimer = nil;
    scrollTimer = nil;
    scrollCount = 0;
    maxScrollCount = WEB_AUTOSCROLL_COUNT;
    self = [super init];
	return self;
}

- (void)dealloc
{
	[self stopCrawling:NO];
	[self deleteCrawlingList];
	if (documentTitle)
		[documentTitle release];
	if (lastConnection)
		[lastConnection cancel];
	if (documentUrl)
		[documentUrl release];
	if (documentContent)
		[documentContent release];
	if (documentData)
		[documentData release];
	if (targetItem)
		[targetItem release];
	[super dealloc];
}

#pragma mark Notifiers

- (void)webView:(WebView*)sender didStartProvisionalLoadForFrame:(WebFrame*)frame {
	if ([sender mainFrame] != frame) {
		return;
	}
	NSURLRequest *req = [[frame provisionalDataSource] request];
	NSString *url = [[req URL] absoluteString];
	NSLog(@"didStartProvisionalLoadForFrame: %@", url);
	[[doc urlField] setStringValue:url];
}

- (void)webView:(WebView*)sender didReceiveTitle: (NSString*)title forFrame:(WebFrame*)frame
{
	if (frame == [sender mainFrame]) {
		NSLog(@"didReceiveTitle: %@ %@", title, [[doc webView] mainFrameURL]);
		if (documentTitle) {
			[documentTitle release];
		}
        if (scrollTimer) {
            [self stopTimerScroll];
        }
		[[doc webTitle] setStringValue:title];
		documentTitle = [title retain];
		[[doc urlField] setStringValue:[[doc webView] mainFrameURL]];
	}
}

- (void)webView:(WebView*)sender didFinishLoadForFrame:(WebFrame*)frame
{
	if ([sender mainFrame] != frame) {
		return;
	}
	NSLog(@"didFinishLoadForFrame %@ %@", documentTitle, [[doc webView] mainFrameURL]);
    NSLog(@"frameView origin = (%0.f,%0.f)", [[frame frameView] bounds].origin.x, [[frame frameView] bounds].origin.y);
 	[[doc goBack] setEnabled:[[doc webView] canGoBack]];
	[[doc goForward] setEnabled:[[doc webView] canGoForward]];
	[[doc urlField] setStringValue:[[doc webView] mainFrameURL]];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[[doc urlField] stringValue] forKey:tPrtLastUrlKey];
	if (crawling == YES && crawlingPaused == NO) {
		NSSound *sound = [NSSound soundNamed:@"Pop"];
		[sound play];
        if (maxScrollCount == WEB_AUTOSCROLL_COUNT) {
            [self startTimerCrawling:CRAWLING_TIMER_CMD_CNT];
        } else {
            [self startTimerCrawling:CRAWLING_TIMER_CMD_SCROLL];
        }
        [[doc webView] scrollLineDown:self];
        scrollCount = maxScrollCount;
        [self startTimerScroll];
	} else if ([[doc reader] crawling] == YES && [[doc reader] crawlingPaused] == NO) {
		NSSound *sound = [NSSound soundNamed:@"Pop"];
		[sound play];
		[[doc reader] startTimerCrawling:CRAWLING_TIMER_CMD_SCROLL];
        [[doc webView] scrollLineDown:self];
        scrollCount = RSS_AUTOSCROLL_COUNT;
        [self startTimerScroll];
    }
    return;
}



#pragma mark HTTP Conection

- (void)startConnection:(NSURLRequest*)req
{
	NSString *url = [[req URL] absoluteString];
	if (documentUrl) {
		[documentUrl release];
	}
	if (lastConnection) {
		[lastConnection cancel];
	}
	documentUrl = [url retain];
	lastConnection = [NSURLConnection connectionWithRequest:req delegate:self];
}

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
	NSLog(@"didReceiveResponse");
	[doc enableUrlRequest:NO];
	if (documentData) {
		[documentData release];
	}
    NSLog( @"size = %llu", [response expectedContentLength]);
    NSLog(@"%@", [response MIMEType]);
    NSLog(@"%@", [response textEncodingName]);
	documentData = [[NSMutableData alloc] init];
	[self purgeDocumentData];
}

- (void)connection:(NSURLConnection*)connection
	didReceiveData:(NSData*)data
{
	// NSLog(@"didReceiveData: %d", [data length]);
	if (documentData) {
		[documentData appendData:data];
	}
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
	NSLog(@"didFailWithError: %@", error);
	if (targetItem) {
		[targetItem release];
		targetItem = nil;
	}
	if (lastConnection == connection) {
		lastConnection = nil;
	}

	if (connectionIndex) {
		if (connectionRetry == NO) {
			// try to connect another server
			targetItem = [doc searchPortfolioItemByIndex:connectionIndex];
			if (targetItem) {
				[targetItem retain];
				[doc autoConnection:connectionIndex:YES];
				return;
			}
		}
		[doc setProgressConnection:NO];
		if ([doc progressWebView] == NO) {
			[doc enableUrlRequest:YES];
			[[doc progress] stopAnimation:self];
		}
	}
	
	NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
									 defaultButton:NSLocalizedString(@"OK",@"Ok")
								   alternateButton:nil
									   otherButton:nil
						 informativeTextWithFormat:NSLocalizedString(@"CONNECTION_FAILED", @"Failed to connect server: %@"), [error localizedDescription]];
	[alert beginSheetModalForWindow:[doc win] modalDelegate:self didEndSelector:nil contextInfo:nil];
	
	if (connectionIndex == 0) {
		[doc enableUrlRequest:YES];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	int		rc;
	NSLog(@"didFinishLoading");
	NSString *htmlString = [[NSString alloc] initWithData:documentData encoding:NSUTF8StringEncoding];
	if (htmlString == nil) {
		htmlString = [[NSString alloc] initWithData:documentData encoding:NSShiftJISStringEncoding];
	}
	if (htmlString == nil) {
		htmlString = [[NSString alloc] initWithData:documentData encoding:NSJapaneseEUCStringEncoding];
	}
	//NSRange range1 = [htmlString rangeOfString:@"<body"];
	//NSRange range2 = [htmlString rangeOfString:@"/body>"];
	//NSLog(@"didReceiveData: %d bytes <body>=%d </body>=%d", [htmlString length], range1.location, range2.location-1);
	[self purgeDocumentData];
	documentContent = [htmlString retain];
	if (lastConnection == connection) {
		lastConnection = nil;
	}
	if (targetItem) {
		rc = [self getItemPrice];
		if (rc < 0 && connectionIndex && connectionRetry == NO) {
			targetItem = [doc searchPortfolioItemByIndex:connectionIndex];
			if (targetItem) {
				[targetItem retain];
				[doc autoConnection:connectionIndex:YES];
				return;
			}
		}
	}
	
	if (connectionIndex == 0) {
		[doc enableUrlRequest:YES];
		return;
	}
	[doc autoConnection:connectionIndex:NO];
}

#pragma mark Paser

- (void)getCompareSetting
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	compareLastHistory = [defaults boolForKey:tPrtSortInfoPanelKey];
}

- (int)getItemPrice
{
	if ([[targetItem country] isEqualToString:TRADE_ITEM_COUNTRY_JP] == YES) {
		if ([targetItem type] == ITEM_TYPE_INDEX && [[targetItem itemCode] hasPrefix:@"^"] == YES) {
			return [self getItemPriceCom];
		}
		return [self getItemPriceJP];
	} else {
		return [self getItemPriceCom];
	}
	return -1;
}

- (int)getItemPriceJP
{
	double		newPrice = -1;
	double		prevPrice = 0;
	NSString*	filter_from1 = nil;
	NSString*	filter_to1 = nil;
	NSString*	filter_from2 = nil;
	NSString*	filter_to2 = nil;
	NSString*	filter_from3 = nil;
    NSString*	filter_rm = nil;
	NSString*	c = nil;

	targetPrice = 0;
	NSLog(@"getItemPriceJP: %@", documentUrl);
	if ([documentUrl hasPrefix:PREFIX_MINKABU_JP_STOCK]) {
		// set filter for minkabu
		NSLog(@"getItemPriceJP minkabu: %@", [targetItem itemName]);
		filter_from1	= FILTER_MINKABU_JP_FROM1;
		filter_to1		= FILTER_MINKABU_JP_TO1;
		filter_from2	= FILTER_MINKABU_JP_FROM2;
		filter_to2		= FILTER_MINKABU_JP_TO2;
        //filter_rm       = FILTER_MINKABU_JP_RM;
	} else if ([documentUrl hasPrefix:PREFIX_MORNINGSTAR_JP_FUND]) {
		// set filter for morningstar
		NSLog(@"getItemPriceJP morningstar: %@", [targetItem itemName]);
		filter_from1	= FILTER_MORNINGSTAR_JP_FROM1;
		filter_to1		= FILTER_MORNINGSTAR_JP_TO1;
		filter_from2	= FILTER_MORNINGSTAR_JP_FROM2;
		filter_to2		= FILTER_MORNINGSTAR_JP_TO2;
		filter_from3	= FILTER_MORNINGSTAR_JP_FROM3;
	} else if ([documentUrl hasPrefix:PREFIX_BLOOMBERG_JP_FUND]) {
		// set filter for morningstar
		NSLog(@"getItemPriceJP Bloomberg: %@", [targetItem itemName]);
		filter_from1	= FILTER_BLOOMBERG_JP_FROM1;
		filter_to1		= FILTER_BLOOMBERG_JP_TO1;
		filter_from2	= FILTER_BLOOMBERG_JP_FROM2;
		filter_to2		= FILTER_BLOOMBERG_JP_TO2;
		filter_from3	= FILTER_BLOOMBERG_JP_FROM3;
	} else if ([documentUrl hasPrefix:PREFIX_YAHOO_JP_STOCK]) {
		NSLog(@"getItemPriceJP yahoo: %@", [targetItem itemName]);
		switch ([targetItem itemCategory]) {
			case ITEM_CATEGORY_STOCK:
				filter_from1	= FILTER_YAHOO_JP_FROM1;
                filter_from2    = FILTER_YAHOO_JP_FROM2;
                filter_to1      = FILTER_YAHOO_JP_TO1;
                filter_to2      = FILTER_YAHOO_JP_TO2;
				break;
			case ITEM_CATEGORY_FUND:
                filter_from1    = FILTER_YAHOO_JP_FUND_FROM1;
                filter_from2    = FILTER_YAHOO_JP_FUND_FROM2;
                filter_to1      = FILTER_YAHOO_JP_FUND_TO1;
                filter_to2      = FILTER_YAHOO_JP_FUND_TO2;
                break;
			case ITEM_CATEGORY_CURRENCY:
			default:
                filter_from1    = FILTER_YAHOO_JP_FX_FROM1;
                filter_from2    = FILTER_YAHOO_JP_FX_FROM2;
                filter_to1      = FILTER_YAHOO_JP_FX_TO1;
                filter_to2      = FILTER_YAHOO_JP_FX_TO2;
				break;
		}
	} else if ([documentUrl hasPrefix:PREFIX_YAHOO_JP_FUND]) {
		NSLog(@"getItemPriceJP yahoo & morningstar: %@", [targetItem itemName]);
		filter_from1	= FILTER_YAHOO_JP_FUND_FROM1;
		filter_to1		= FILTER_YAHOO_JP_FUND_TO1;
		filter_from2	= FILTER_YAHOO_JP_FUND_FROM2;
		filter_to2		= FILTER_YAHOO_JP_FUND_TO2;
		//filter_from3	= FILTER_YAHOO_JP_FUND_FROM3;
	} else if ([documentUrl hasPrefix:PREFIX_GOOGLE_FINANCE]) {
		NSLog(@"getItemPriceJP google: %@", [targetItem itemName]);
		filter_from1	= FILTER_GOOGLE_FROM1;
		if ([targetItem itemCategory] == ITEM_CATEGORY_FUND) {
			filter_from2	= FILTER_GOOGLE_FROM2_FUND;
			filter_to1		= FILTER_GOOGLE_TO1_FUND;
		} else {
			filter_from2	= FILTER_GOOGLE_FROM2;
			filter_from3	= FILTER_GOOGLE_FROM3;
			filter_to1		= FILTER_GOOGLE_TO1;
		}
		filter_to2		= FILTER_GOOGLE_TO2;
	} else {
		NSLog(@"getItemPriceJP unknown: %@", [targetItem itemName]);
		return -1;
	}
	NSRange range = [documentContent rangeOfString:filter_from1];
	if (range.length == 0) {
		NSLog(@"filter_from1 isn't found %d,%d", (int)range.location, (int)range.length);
		NSLog(@"\r\n%@",documentContent);
		// return -1;
	}

	NSString* subString1;
    //subString1 = [documentContent substringFromIndex:range.location];

    if (range.length == 0) {
        subString1 = [documentContent substringFromIndex:0];
    } else {
        subString1 = [documentContent substringFromIndex:range.location];;
    }

	range = [subString1 rangeOfString:filter_to1];
	if (range.length == 0) {
		NSLog(@"filter_to1 isn't found %d,%d", (int)range.location, (int)range.length);
		// NSLog(@"\r\n%@",subString1);
		return -1;
	}
	NSString* subString2 = [subString1 substringToIndex:range.location];
	
	range = [subString2 rangeOfString:filter_from2];
	if (range.length == 0) {
		NSLog(@"filter_from2 isn't found");
		return -1;
	}
	subString1 = [subString2 substringFromIndex:range.location];
	
	range = [subString1 rangeOfString:filter_to2];
	if (range.length == 0) {
		NSLog(@"filter_to2 isn't found");
		return -1;
	}
	subString2 = [subString1 substringToIndex:range.location];
    if (subString2 && filter_rm) {
        subString2 = [subString2 stringByReplacingOccurrencesOfString:filter_rm withString:@""];
    }
	if (filter_from3) {
		range = [subString2 rangeOfString:filter_from3];
		if (range.length == 0) {
			NSLog(@"filter_from3 isn't found");
			return -1;
		}
		subString1 = [subString2 substringFromIndex:range.location+range.length];
		if (strPrice) {
			[strPrice release];
		}
		strPrice = [subString1 retain];
	} else {
		subString1 = [subString2 substringFromIndex:[filter_from2 length]];
		if (strPrice) {
			[strPrice release];
		}
		strPrice = [subString1 retain];
	}
	
	NSArray* splits = [strPrice componentsSeparatedByString:@","];
	NSMutableString* price = [[NSMutableString alloc] init];
	for (NSString* split in splits) {
		[price appendString:split];
	}
	//newPrice = [price doubleValue];
	if ([price isEqualToString:@""] == YES) {
		NSLog(@"price is empty: %@", strPrice);
		[price release];
		return -1;
	}
	
	if ([targetItem itemCategory] == ITEM_CATEGORY_CURRENCY) {
		NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
		[formatter setFormat:@"#,##0.00##"];
		if (strPrice) {
			[strPrice release];
		}
		newPrice = round([price doubleValue]*10000)/10000;
		strPrice = [NSString stringWithFormat:@"%@",[formatter stringFromNumber:[NSNumber numberWithDouble:newPrice]]];
		[strPrice retain];
	}

	newPrice = round([price doubleValue]*10000)/10000;
	if ([price hasPrefix:@"-"] == YES) {
		newPrice = -1;
	}
	[price release];

    // Debug
    // newPrice = [targetItem price];

	if (newPrice < 0) {
		NSLog(@"value of price is minus: %f", newPrice);
		return -1;
	}
	if ([targetItem type] == ITEM_TYPE_INDEX) {
		c = @"";
	} else {
		c = @"¥";
	}

	prevPrice = [targetItem GetPriceByDate:[targetItem date]];
	NSLog(@"New price = %f %@ Prev price = %.2f", newPrice, strPrice, prevPrice);
	if (newPrice >= 0 && newPrice != prevPrice) {
		bool bNewItem = NO;
		if ([targetItem price] == 0) {
			bNewItem = YES;
		}
		targetPrice = newPrice;
		float diff = newPrice - prevPrice;
		float raise = round((newPrice/prevPrice-1)*100000)/1000;
		NSString* diffStr;
		bool isFloat = NO;
		if ([targetItem itemCategory] == ITEM_CATEGORY_CURRENCY ||
			[targetItem type] == ITEM_TYPE_INDEX) {
			isFloat = YES;
		}
		if (diff >= 0) {
			if (isFloat == YES) {
				if ([targetItem type] == ITEM_TYPE_INDEX) {
					diffStr = [NSString stringWithFormat:@"+%0.2f",diff];
				} else {
					diffStr = [NSString stringWithFormat:@"+%0.4f",diff];
				}
			} else {
				diffStr = [NSString stringWithFormat:@"+%0.f",diff];
			}
		} else {
			if (isFloat == YES) {
				if ([targetItem type] == ITEM_TYPE_INDEX) {
					diffStr = [NSString stringWithFormat:@"%0.2f", diff];
				} else {
					diffStr = [NSString stringWithFormat:@"%0.4f", diff];
				}
			} else {
				diffStr = [NSString stringWithFormat:@"%0.f", diff];
			}
		}
		if (connectionIndex == 0) {
			NSAlert *alert;
			if (isFloat == YES) {
				if ([targetItem type] == ITEM_TYPE_INDEX) {
					alert = [NSAlert alertWithMessageText:NSLocalizedString(@"INFO",@"Info")
											defaultButton:NSLocalizedString(@"OK",@"Ok")
										  alternateButton:NSLocalizedString(@"CANCEL",@"Cancel")
											  otherButton:nil
								informativeTextWithFormat:NSLocalizedString(@"PRICE_UPDATED_INDEX",@"value of %@ is updated: %.2f (%@)\nDo you import it ?"), [targetItem itemName], newPrice, diffStr];
				} else {
					alert = [NSAlert alertWithMessageText:NSLocalizedString(@"INFO",@"Info")
											defaultButton:NSLocalizedString(@"OK",@"Ok")
										  alternateButton:NSLocalizedString(@"CANCEL",@"Cancel")
											  otherButton:nil
								informativeTextWithFormat:NSLocalizedString(@"PRICE_UPDATED_JPF",@"exchange rate of %@ is updated: ¥%0.4f (%@)\nDo you import it?"), [targetItem itemName], newPrice, diffStr];
				}
			} else {
				alert = [NSAlert alertWithMessageText:NSLocalizedString(@"INFO",@"Info")
										defaultButton:NSLocalizedString(@"OK",@"Ok")
									  alternateButton:NSLocalizedString(@"CANCEL",@"Cancel")
										  otherButton:nil
							informativeTextWithFormat:NSLocalizedString(@"PRICE_UPDATED_JP",@"price of %@ is updated: ¥%.0f (%@)\nDo you import it?"), [targetItem itemName], newPrice, diffStr];
			}
			[alert beginSheetModalForWindow:[doc win] modalDelegate:self didEndSelector:@selector(alertEndedUpdate:code:context:) contextInfo:nil];
			return (int)newPrice;
		} else {
			modifiedPrice++;
			NSString* priceItem;
			if (bNewItem) {
				priceItem = [NSString stringWithFormat:@"%@  %@   %@%@\r\n",[targetItem itemCode],[targetItem itemName],c,strPrice];
			} else {
				if (raise > 0) {
					priceItem = [NSString stringWithFormat:@"%@  %@   %@%@  %@  +%.2f%@\r\n",[targetItem itemCode],[targetItem itemName],c,strPrice,diffStr,raise,@"%"];
				} else {
					priceItem = [NSString stringWithFormat:@"%@  %@   %@%@  %@  %.2f%@\r\n",[targetItem itemCode],[targetItem itemName],c,strPrice,diffStr,raise,@"%"];
				}
			}
			[[[doc iPanel]priceList] appendString:priceItem];
			[[doc iPanel] setItem:[targetItem itemName]:[targetItem itemCode]:[NSString stringWithFormat:@"%@%@",c,strPrice]:diffStr:raise/100:[targetItem itemCurrencyNameJP]];
			[targetItem setPrice:targetPrice];
		}
	} else {
		NSString* priceItem;
		if ([targetItem itemCategory] == ITEM_CATEGORY_CURRENCY) {
			priceItem = [NSString stringWithFormat:@"%@  %@   %@%@  0.00  0.00%@\r\n",[targetItem itemCode],[targetItem itemName],c,strPrice,@"%"];
		} else {
			priceItem = [NSString stringWithFormat:@"%@  %@   %@%@  0  0.00%@\r\n",[targetItem itemCode],[targetItem itemName],c,strPrice,@"%"];
		}

		[[[doc iPanel]priceList] appendString:priceItem];
		[[doc iPanel] setItem:[targetItem itemName]:[targetItem itemCode]:[NSString stringWithFormat:@"%@%@",c,strPrice]:@"0":0:[targetItem itemCurrencyNameJP]];
	}
	if (connectionIndex != 0) {
		[self addItemToCrawlingList:documentUrl];
	}
	[targetItem setDate:[NSDate date]];
	[targetItem DoSettlement];
	[doc rearrangeDocument];
	if ([[doc subDocument] portfolioItem] == targetItem) {
		[[doc subDocument] rearrangeDocument];
	}
	targetItem = nil;
	targetPrice = 0;
	return (int)newPrice;
}

- (int)getItemPriceCom
{
	double		newPrice = -1;
	double		prevPrice = 0;
	NSString*	filter_from1 = nil;
	NSString*	filter_to1 = nil;
	NSString*	filter_from2 = nil;
	NSString*	filter_to2 = nil;
	NSString*	filter_from3 = nil;
    NSString*	filter_from1_prev = nil;
    NSString*	filter_from2_prev = nil;
    NSString*	filter_from1_mobile = nil;
	NSString*	c = nil;
	targetPrice = 0;
	bool isFloat = NO;
	NSLog(@"getItemPriceCom: %@", documentUrl);
	if ([documentUrl hasPrefix:PREFIX_YAHOO_US_STOCK]) {
		NSLog(@"getItemPriceCom yahoo: %@", [targetItem itemName]);
		filter_from1	= FILTER_YAHOO_US_FROM1;
		filter_to1		= FILTER_YAHOO_US_TO1;
		if ([targetItem itemCategory] == ITEM_CATEGORY_CURRENCY) {
			if ([[targetItem itemCode] length] == 3 && [[targetItem itemCode] isEqualToString:@"USD"] == NO) {
				filter_from2	= [NSString stringWithFormat:FILTER_YAHOO_US_FROM2_USD,[[targetItem itemCode] lowercaseString]];
			} else {
				filter_from2	= [NSString stringWithFormat:FILTER_YAHOO_US_FROM2_FX,[[targetItem itemCode] lowercaseString]];
			}
			isFloat = YES;
		} else {
			if ([[targetItem itemCode] hasPrefix:@"^"]) {
				filter_from2	= [NSString stringWithFormat:FILTER_YAHOO_US_FROM2,[[targetItem itemCode] lowercaseString]];
				filter_from2_prev	= [NSString stringWithFormat:FILTER_YAHOO_US_FROM2_PREV,[[targetItem itemCode] lowercaseString]];
			} else {
				filter_from2	= [NSString stringWithFormat:FILTER_YAHOO_US_FROM2,[[targetItem itemCodeYahoo] lowercaseString]];
				filter_from2_prev	= [NSString stringWithFormat:FILTER_YAHOO_US_FROM2_PREV,[[targetItem itemCodeYahoo] lowercaseString]];
			}
		}
		filter_to2		= FILTER_YAHOO_US_TO2;
		filter_from1_prev	= FILTER_YAHOO_US_FROM1_PREV;
	} else if ([documentUrl hasPrefix:PREFIX_YAHOO_DE_STOCK]) {
		NSLog(@"getItemPriceCom de.yahoo: %@", [targetItem itemName]);
		filter_from1	= FILTER_YAHOO_US_FROM1;
		filter_to1		= FILTER_YAHOO_US_TO1;
		if ([targetItem itemCategory] == ITEM_CATEGORY_CURRENCY) {
			if ([[targetItem country] isEqualToString:@"CH"] &&
				[[targetItem itemCode] length] == 3 && [[targetItem itemCode] isEqualToString:@"CHF"] == NO) {
				filter_from2	= [NSString stringWithFormat:FILTER_YAHOO_DE_FROM2_CHF,[[targetItem itemCode] lowercaseString]];
			} else if ([[targetItem itemCode] length] == 3 && [[targetItem itemCode] isEqualToString:@"EUR"] == NO) {
				filter_from2	= [NSString stringWithFormat:FILTER_YAHOO_DE_FROM2_EUR,[[targetItem itemCode] lowercaseString]];
			} else {
				filter_from2	= [NSString stringWithFormat:FILTER_YAHOO_US_FROM2_FX,[[targetItem itemCode] lowercaseString]];
			}
			isFloat = YES;
		} else {
			if ([[targetItem itemCode] hasPrefix:@"^"]) {
				filter_from2	= [NSString stringWithFormat:FILTER_YAHOO_US_FROM2,[[targetItem itemCode] lowercaseString]];
				filter_from2_prev	= [NSString stringWithFormat:FILTER_YAHOO_US_FROM2_PREV,[[targetItem itemCode] lowercaseString]];
			} else {
				filter_from2	= [NSString stringWithFormat:FILTER_YAHOO_US_FROM2,[[targetItem itemCodeYahoo] lowercaseString]];
				filter_from2_prev	= [NSString stringWithFormat:FILTER_YAHOO_US_FROM2_PREV,[[targetItem itemCodeYahoo] lowercaseString]];
			}
		}
		filter_to2		= FILTER_YAHOO_US_TO2;
		filter_from1_prev	= FILTER_YAHOO_US_FROM1_PREV;
	} else if ([documentUrl hasPrefix:PREFIX_GOOGLE_FINANCE]) {
		NSLog(@"getItemPriceCom google: %@", [targetItem itemName]);
		filter_from1	= FILTER_GOOGLE_FROM1;
		if ([targetItem itemCategory] == ITEM_CATEGORY_FUND) {
			filter_from2	= FILTER_GOOGLE_FROM2_FUND;
			filter_to1		= FILTER_GOOGLE_TO1_FUND;
		} else {
			filter_from2	= FILTER_GOOGLE_FROM2;
			filter_from3	= FILTER_GOOGLE_FROM3;
			filter_to1		= FILTER_GOOGLE_TO1;
		}
		filter_to2		= FILTER_GOOGLE_TO2;
	} else {	// Other Country
		NSLog(@"getItemPriceCom xx.yahoo: %@", [targetItem itemName]);
		NSString* domain = [doc CountryToDomain:[targetItem country]];
		NSString* yahoo_url;
		if (domain && [domain isEqualToString:@""] == NO) {
			yahoo_url = [NSString stringWithFormat:URL_YAHOO_XX_FINANCE,domain];
		} else {
			yahoo_url = [NSString stringWithFormat:URL_YAHOO_XX_FINANCE,[[targetItem country] lowercaseString]];
		}
		if ([documentUrl hasPrefix:yahoo_url]) {
			NSString* currency = [doc CountryToCurrency:[targetItem country]];
			filter_from1	= FILTER_YAHOO_US_FROM1;
			filter_to1		= FILTER_YAHOO_US_TO1;
			if ([targetItem itemCategory] == ITEM_CATEGORY_CURRENCY) {
				if ([[targetItem itemCode] length] == 3 && currency != nil &&
					[[targetItem itemCode] isEqualToString:currency] == NO) {
                    filter_from2	= [NSString stringWithFormat:FILTER_YAHOO_XX_FROM2_YY,[[targetItem itemCode] lowercaseString],[currency lowercaseString]];
                    filter_from1_mobile	= [NSString stringWithFormat:FILTER_YAHOO_MOBILE_FROM1_YY,[[targetItem itemCode] uppercaseString],[currency uppercaseString]];
				} else {
                    filter_from2	= [NSString stringWithFormat:FILTER_YAHOO_US_FROM2_FX,[[targetItem itemCode] lowercaseString]];
                    filter_from1_mobile	= [NSString stringWithFormat:FILTER_YAHOO_MOBILE_FROM1_FX,[[targetItem itemCode] uppercaseString]];
				}
				isFloat = YES;
			} else {
				if ([[targetItem itemCode] hasPrefix:@"^"]) {
					filter_from2	= [NSString stringWithFormat:FILTER_YAHOO_US_FROM2,[[targetItem itemCode] lowercaseString]];
                    filter_from2_prev	= [NSString stringWithFormat:FILTER_YAHOO_US_FROM2_PREV,[[targetItem itemCode] lowercaseString]];
                    filter_from1_mobile	= [NSString stringWithFormat:FILTER_YAHOO_MOBILE_FROM1,[[targetItem itemCode] uppercaseString]];
				} else {
					filter_from2	= [NSString stringWithFormat:FILTER_YAHOO_US_FROM2,[[targetItem itemCodeYahoo] lowercaseString]];
                    filter_from2_prev	= [NSString stringWithFormat:FILTER_YAHOO_US_FROM2_PREV,[[targetItem itemCodeYahoo] lowercaseString]];
                    filter_from1_mobile	= [NSString stringWithFormat:FILTER_YAHOO_MOBILE_FROM1,[[targetItem itemCodeYahoo] uppercaseString]];
				}
			}
			filter_to2		= FILTER_YAHOO_US_TO2;
            filter_from1_prev	= FILTER_YAHOO_US_FROM1_PREV;
		} else {
			NSLog(@"getItemPrice unknown: %@", [targetItem itemName]);
			return -1;
		}
	}
	NSRange range = [documentContent rangeOfString:filter_from1];
	if (range.length == 0) {
		NSLog(@"filter_from1 isn't found %d,%d", (int)range.location, (int)range.length);
		// NSLog(@"\r\n%@",documentContent);
        if (filter_from1_prev) {
            range = [documentContent rangeOfString:filter_from1_prev];
            if (range.length == 0) {
                NSLog(@"filter_from1_prev isn't found %d,%d", (int)range.location, (int)range.length);
            } else {
                if (filter_from2_prev) {
                    filter_from2 = filter_from2_prev;
                }
                filter_to2 = FILTER_YAHOO_US_TO2_PREV;
            }
        }
	}
    if (range.length == 0 && filter_from1_mobile) {
        range = [documentContent rangeOfString:filter_from1_mobile];
        if (range.length == 0) {
            NSLog(@"filter_from1_mobile isn't found %d,%d", (int)range.location, (int)range.length);
        } else {
            filter_from2 = FILTER_YAHOO_MOBILE_FROM2;
            filter_to1 = FILTER_YAHOO_MOBILE_TO1;
            filter_to2 = FILTER_YAHOO_MOBILE_TO2;
        }
    }

	NSString* subString1;
    //subString1 = [documentContent substringFromIndex:range.location];
    if (range.length == 0) {
        subString1 = [documentContent substringFromIndex:0];
    } else {
        subString1 = [documentContent substringFromIndex:range.location];;
    }
	
	range = [subString1 rangeOfString:filter_to1];
	if (range.length == 0) {
		NSLog(@"filter_to1 isn't found %d,%d", (int)range.location, (int)range.length);
		// NSLog(@"\r\n%@",subString1);
		return -1;
	}
	NSString* subString2 = [subString1 substringToIndex:range.location];
	
	range = [subString2 rangeOfString:filter_from2];
	if (range.length == 0) {
        if (filter_from2_prev) {
            range = [subString2 rangeOfString:filter_from2_prev];
        }
        if (range.length == 0) {
            NSLog(@"filter_from2 isn't found: %@\n%@", filter_from2, subString2);
            return -1;
        }
	}
	subString1 = [subString2 substringFromIndex:range.location];
	
	range = [subString1 rangeOfString:filter_to2];
	if (range.length == 0) {
		NSLog(@"filter_to2 isn't found");
		return -1;
	}
	subString2 = [subString1 substringToIndex:range.location];
	if (filter_from3) {
		range = [subString2 rangeOfString:filter_from3];
		if (range.length == 0) {
			NSLog(@"filter_from3 isn't found");
			return -1;
		}
		subString1 = [subString2 substringFromIndex:range.location+range.length];
		if (strPrice) {
			[strPrice release];
		}
		strPrice = [subString1 retain];
	} else {
		subString1 = [subString2 substringFromIndex:[filter_from2 length]];
		if (strPrice) {
			[strPrice release];
		}
		strPrice = [subString1 retain];
	}

	NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
	NSMutableString* price = [[NSMutableString alloc] init];
	if ([documentUrl hasPrefix:PREFIX_YAHOO_DE_STOCK] ||
		[documentUrl hasPrefix:PREFIX_YAHOO_IT_STOCK] ||
		[documentUrl hasPrefix:PREFIX_YAHOO_ES_STOCK] ||
		[documentUrl hasPrefix:PREFIX_YAHOO_BR_STOCK]) {
		NSArray* splits = [strPrice componentsSeparatedByString:@"."];
		for (NSString* split in splits) {
			[price appendString:[split stringByReplacingOccurrencesOfString:@"," withString:@"."]];
		}
	} else if ([documentUrl hasPrefix:PREFIX_YAHOO_FR_STOCK]) {
			NSArray* splits = [strPrice componentsSeparatedByString:@" "];
			for (NSString* split in splits) {
				[price appendString:[split stringByReplacingOccurrencesOfString:@"," withString:@"."]];
			}
	} else {
		NSArray* splits = [strPrice componentsSeparatedByString:@","];
		for (NSString* split in splits) {
			[price appendString:split];
		}
	}
	//newPrice = [price doubleValue];
	if ([price isEqualToString:@""] == YES) {
		NSLog(@"price is empty: %@", strPrice);
		[price release];
		return -1;
	}
	if (isFloat == YES) {
		newPrice = round([price doubleValue]*10000)/10000;
		[formatter setFormat:@"#,##0.00##"];
	} else {
		newPrice = round([price doubleValue]*100)/100;
		[formatter setFormat:@"#,##0.00"];
	}
	if ([price hasPrefix:@"-"] == YES) {
		newPrice = -1;
	}
	[price release];
	if (newPrice < 0) {
		NSLog(@"value of price is minus: %f", newPrice);
		return -1;
	}

	if (strPrice) {
		[strPrice release];
	}

    // Debug
    // newPrice = [targetItem price];

	//NSLog(@"%@",[formatter stringFromNumber:[NSNumber numberWithInt:newPrice]]);
	strPrice = [NSString stringWithFormat:@"%@",[formatter stringFromNumber:[NSNumber numberWithDouble:newPrice]]];
	[strPrice retain];

	c = [targetItem itemCurrencySymbol];
	/*
	if ([targetItem type] == ITEM_TYPE_INDEX) {
		c = @"";
	} else if ([[targetItem country] isEqualToString:TRADE_ITEM_COUNTRY_UK] == YES ||
			   [[targetItem country] isEqualToString:TRADE_ITEM_COUNTRY_TR] == YES) {
		c = @"£";
	} else if ([[targetItem country] isEqualToString:TRADE_ITEM_COUNTRY_EU] == YES ||
			   [[targetItem country] isEqualToString:TRADE_ITEM_COUNTRY_FR] == YES ||
			   [[targetItem country] isEqualToString:TRADE_ITEM_COUNTRY_IT] == YES ||
			   [[targetItem country] isEqualToString:TRADE_ITEM_COUNTRY_DE] == YES) {
		c = @"€";
	} else if ([[targetItem country] isEqualToString:TRADE_ITEM_COUNTRY_BR] == YES) {
		c = @"B$";
	} else if ([[targetItem country] isEqualToString:TRADE_ITEM_COUNTRY_CH] == YES) {
		c = @"Fr.";
	} else if ([[targetItem country] isEqualToString:TRADE_ITEM_COUNTRY_IN] == YES ||
			   [[targetItem country] isEqualToString:TRADE_ITEM_COUNTRY_ID]) {
		c = @"₨";
	} else if ([[targetItem country] isEqualToString:TRADE_ITEM_COUNTRY_CN] == YES) {
		c = @"¥";
	} else if ([[targetItem country] isEqualToString:TRADE_ITEM_COUNTRY_KR] == YES) {
		c = @"₩";
	} else if ([[targetItem country] isEqualToString:TRADE_ITEM_COUNTRY_RU] == YES) {
		c = @"руб";
	} else if ([[targetItem country] isEqualToString:TRADE_ITEM_COUNTRY_TH] == YES) {
		c = @"฿";
	} else if ([[targetItem country] isEqualToString:TRADE_ITEM_COUNTRY_PH] == YES) {
		c = @"₱";
	} else if ([[targetItem country] isEqualToString:TRADE_ITEM_COUNTRY_VN] == YES) {
		c = @"₫";
	} else if ([[targetItem country] isEqualToString:TRADE_ITEM_COUNTRY_SA] == YES) {
		c = @"R";
	} else {
		c = @"$";
	}
	*/
	
	prevPrice = [targetItem GetPriceByDate:[targetItem date]];
	NSLog(@"New price = %f %@ Prev price = %.2f", newPrice, strPrice, prevPrice);
	if (newPrice >= 0 && newPrice != prevPrice) {
		bool bNewItem = NO;
		if ([targetItem price] == 0) {
			bNewItem = YES;
		}
		targetPrice = newPrice;
		float diff = newPrice - prevPrice;
		float raise = round((newPrice/prevPrice-1)*100000)/1000;
		NSString* diffStr;
		if (diff >= 0) {
			if (isFloat == YES) {
				diffStr = [NSString stringWithFormat:@"+%0.4f", diff];
			} else {
				diffStr = [NSString stringWithFormat:@"+%0.2f", diff];
			}
		} else {
			if (isFloat == YES) {
				diffStr = [NSString stringWithFormat:@"%0.4f", diff];
			} else {
				diffStr = [NSString stringWithFormat:@"%0.2f", diff];
			}
		}
		if (connectionIndex == 0) {
			NSAlert *alert;
			if (isFloat == YES) {
				alert = [NSAlert alertWithMessageText:NSLocalizedString(@"INFO",@"Info")
										defaultButton:NSLocalizedString(@"OK",@"Ok")
									  alternateButton:NSLocalizedString(@"CANCEL",@"Cancel")
										  otherButton:nil
							informativeTextWithFormat:NSLocalizedString(@"PRICE_UPDATED_ENF",@"exchange rate of %@ is updated: %@%.4f (%@)\nDo you import it ?"), [targetItem itemName], c, newPrice, diffStr];
			} else {
				if ([targetItem type] == ITEM_TYPE_INDEX) {
					alert = [NSAlert alertWithMessageText:NSLocalizedString(@"INFO",@"Info")
											defaultButton:NSLocalizedString(@"OK",@"Ok")
										  alternateButton:NSLocalizedString(@"CANCEL",@"Cancel")
											  otherButton:nil
								informativeTextWithFormat:NSLocalizedString(@"PRICE_UPDATED_INDEX",@"value of %@ is updated: ¥%.2f (%@)\nDo you import it ?"), [targetItem itemName], newPrice, diffStr];
				} else {
					alert = [NSAlert alertWithMessageText:NSLocalizedString(@"INFO",@"Info")
											defaultButton:NSLocalizedString(@"OK",@"Ok")
										  alternateButton:NSLocalizedString(@"CANCEL",@"Cancel")
											  otherButton:nil
								informativeTextWithFormat:NSLocalizedString(@"PRICE_UPDATED_EN",@"price of %@ is updated: %@%.2f (%@)\nDo you import it ?"), [targetItem itemName], c, newPrice, diffStr];
				}
			}
			[alert beginSheetModalForWindow:[doc win] modalDelegate:self didEndSelector:@selector(alertEndedUpdate:code:context:) contextInfo:nil];
			return (int)newPrice;
		} else {
			modifiedPrice++;
			NSString*	priceItem;
			if (bNewItem) {
				priceItem = [NSString stringWithFormat:@"%@  %@   %@%@\r\n",[targetItem itemCode],[targetItem itemName],c,strPrice];
			} else {
				if (raise > 0) {
					priceItem = [NSString stringWithFormat:@"%@  %@   %@%@  %@  +%.2f%@\r\n",[targetItem itemCode],[targetItem itemName],c,strPrice,diffStr,raise,@"%"];
				} else {
					priceItem = [NSString stringWithFormat:@"%@  %@   %@%@  %@  %.2f%@\r\n",[targetItem itemCode],[targetItem itemName],c,strPrice,diffStr,raise,@"%"];
				}
			}
			[[[doc iPanel]priceList] appendString:priceItem];
			[[doc iPanel] setItem:[targetItem itemName]:[targetItem itemCode]:[NSString stringWithFormat:@"%@%@",c,strPrice]:diffStr:raise/100:[targetItem itemCurrencyNameJP]];
			[targetItem setPrice:targetPrice];
		}
	} else {
		NSString* priceItem = [NSString stringWithFormat:@"%@  %@   %@%@  0.00  0.00%@\r\n",[targetItem itemCode],[targetItem itemName],c,strPrice,@"%"];
		[[[doc iPanel]priceList] appendString:priceItem];
		[[doc iPanel] setItem:[targetItem itemName]:[targetItem itemCode]:[NSString stringWithFormat:@"%@%@",c,strPrice]:@"0":0:[targetItem itemCurrencyNameJP]];
	}
	if (connectionIndex != 0) {
		[self addItemToCrawlingList:documentUrl];
	}
	[targetItem setDate:[NSDate date]];
	[targetItem DoSettlement];
	if ([[doc subDocument] portfolioItem] == targetItem) {
		[[doc subDocument] rearrangeDocument];
	}
	targetItem = nil;
	targetPrice = 0;
	[doc rearrangeDocument];
	return (int)newPrice;
}

- (void)alertEndedUpdate:(NSAlert*)alert
					code:(int)choice
				 context:(void*)v
{
	if (choice == NSAlertDefaultReturn) {
		NSLog(@"Alert price updated: %0.2f", targetPrice);
		[targetItem setPrice:targetPrice];
		[targetItem DoSettlement];
		[doc rearrangeDocument];
		if ([[doc subDocument] portfolioItem] == targetItem) {
			[[doc subDocument] rearrangeDocument];
		}
	}
	targetItem = nil;
	targetPrice = 0;
	return;
}

- (void)purgeDocumentData
{
	if (documentContent) {
		[documentContent release];
		documentContent = nil;
	}
}

#pragma mark Autopilot

- (int)createCrawlingList :(bool)yahoo :(bool)google :(bool)minkabu :(bool)ir
{
	NSLog(@"createCrawlingList");
	if (crawlingList) {
		[self deleteCrawlingList];
	}
	crawlingList = [[NSMutableArray alloc] init];
	for (PortfolioItem *item in [doc portfolioArray]) {
		Bookmark* bookmark;
		NSString* urlString;
		NSString* lang = NSLocalizedString(@"LANG",@"English");
		if (yahoo == YES && [item itemCode] != nil &&
			[[item itemCode] isEqualToString:@""] == NO) {
			// Add yahoo to list
			if ([[item country] isEqualToString:TRADE_ITEM_COUNTRY_JP] == YES) {
				if ([item itemCategory] == ITEM_CATEGORY_CURRENCY) {
					if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"JPY"]) {
						if ([lang isEqualToString:@"Japanese"]) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_JPY,[item itemCode]];
						} else {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_JPY,[item itemCode]];
						}
					} else {
						if ([lang isEqualToString:@"Japanese"]) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_STOCK,[item itemCode]];
						} else {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_FX,[item itemCode]];
						}
					}
				} else if ([item itemCategory] == ITEM_CATEGORY_FUND) {
					urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_FUND,[item itemCode]];
				} else {
					if ([item type] == ITEM_TYPE_INDEX) {
						if ([[item itemCode] hasPrefix:@"^"]) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_STOCK,[item itemCodeYahoo]];
						}
					}
					if (urlString) {
						urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_STOCK,[item itemCodeJP]];
					}
				}
			} else if ([[item country] isEqualToString:TRADE_ITEM_COUNTRY_US] == YES) {
				if ([item itemCategory] == ITEM_CATEGORY_CURRENCY) { 
					if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"USD"]) {
						if ([lang isEqualToString:@"Japanese"]) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_USD,[item itemCode]];
						} else {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_USD,[item itemCode]];
						}
					} else {
						if ([lang isEqualToString:@"Japanese"]) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_STOCK,[item itemCode]];
						} else {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_FX,[item itemCode]];
						}
					}
				} else {
					urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_STOCK,[item itemCodeYahoo]];
				}
			} else if ([[item country] isEqualToString:TRADE_ITEM_COUNTRY_EU] == YES ||
					   [[item country] isEqualToString:TRADE_ITEM_COUNTRY_DE] == YES) {
				if ([item itemCategory] == ITEM_CATEGORY_CURRENCY) {
					if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"EUR"]) {
						if ([lang isEqualToString:@"Japanese"]) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_EUR,[item itemCode]];
						} else {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_DE_EUR,[item itemCode]];
						}
					} else {
						if ([lang isEqualToString:@"Japanese"]) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_STOCK,[item itemCode]];
						} else {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_DE_FX,[item itemCode]];
						}
					}
				} else {
					urlString = [NSString stringWithFormat:FORMAT_YAHOO_DE_STOCK,[item itemCodeYahoo]];
				}
			} else if ([[item country] isEqualToString:TRADE_ITEM_COUNTRY_CH] == YES) {
				if ([item itemCategory] == ITEM_CATEGORY_CURRENCY) { 
					if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"CHF"]) {
						if ([lang isEqualToString:@"Japanese"]) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_CHF,[item itemCode]];
						} else {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_DE_CHF,[item itemCode]];
						}
					} else {
						if ([lang isEqualToString:@"Japanese"]) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_STOCK,[item itemCode]];
						} else {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_DE_FX,[item itemCode]];
						}
					}
				} else {
					urlString = [NSString stringWithFormat:FORMAT_YAHOO_DE_STOCK,[item itemCodeYahoo]];
				}
			} else {	// Other Country
				NSString* currency = [doc CountryToCurrency: [item country]];
				NSString* domain = [doc CountryToDomain: [item country]];
				if ([item itemCategory] == ITEM_CATEGORY_CURRENCY) {
					if (currency &&[[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:currency]) {
						if ([lang isEqualToString:@"Japanese"]) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_YY,[item itemCode],currency];
						} else {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_XX_YY,[[item country] lowercaseString],[item itemCode],currency];
						}
					} else {
						if ([lang isEqualToString:@"Japanese"]) {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_JP_STOCK,[item itemCode]];
						} else {
							urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_FX,[item itemCode]];
						}
					}
				} else {
					if (domain == nil || [domain isEqualToString:@""] == YES) {
						urlString = [NSString stringWithFormat:FORMAT_YAHOO_US_STOCK,[item itemCodeYahoo]];
					} else {
						urlString = [NSString stringWithFormat:FORMAT_YAHOO_XX_STOCK,domain,[item itemCodeYahoo]];
					}
				}
			}
			for (Bookmark *bookmark in crawlingList) {
				if ([[bookmark url] isEqualToString:urlString]) {
					NSLog(@"bookmark already added %@",[bookmark url]);
					urlString = nil;
					break;
				}
			}
			if (urlString) {
				bookmark = [[Bookmark alloc] init];
				[bookmark setBookmark:nil:urlString];
				[crawlingList addObject:bookmark];
				NSLog(@"bookmark add %@",[bookmark url]);
				[bookmark release];
			}
		}
		if (google == YES && [item itemCode] != nil &&
			[[item itemCode] isEqualToString:@""] == NO &&
			[item type] != ITEM_TYPE_INDEX) {
			// Add google to list
			if ([item itemCategory] == ITEM_CATEGORY_CURRENCY) {
				if ([[item country] isEqualToString:TRADE_ITEM_COUNTRY_US] == YES) {
					if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"USD"]) {
						urlString = [NSString stringWithFormat:FORMAT_GOOGLE_FINANCE_USD,[item itemCode]];
					} else {
						urlString = [NSString stringWithFormat:FORMAT_GOOGLE_FINANCE,[item itemCode]];
					}
				} else if ([[item country] isEqualToString:TRADE_ITEM_COUNTRY_UK] == YES) {
					if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"GBP"]) {
						urlString = [NSString stringWithFormat:FORMAT_GOOGLE_FINANCE_GBP,[item itemCode]];
					} else {
						urlString = [NSString stringWithFormat:FORMAT_GOOGLE_FINANCE,[item itemCode]];
					}
				} else if ([[item country] isEqualToString:TRADE_ITEM_COUNTRY_EU] == YES ||
						   [[item country] isEqualToString:TRADE_ITEM_COUNTRY_FR] == YES ||
						   [[item country] isEqualToString:TRADE_ITEM_COUNTRY_DE] == YES) {
					if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"EUR"]) {
						urlString = [NSString stringWithFormat:FORMAT_GOOGLE_FINANCE_EUR,[item itemCode]];
					} else {
						urlString = [NSString stringWithFormat:FORMAT_GOOGLE_FINANCE,[item itemCode]];
					}
				} else if ([[item country] isEqualToString:TRADE_ITEM_COUNTRY_CA] == YES) {
					if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"CAD"]) {
						urlString = [NSString stringWithFormat:FORMAT_GOOGLE_FINANCE_CAD,[item itemCode]];
					} else {
						urlString = [NSString stringWithFormat:FORMAT_GOOGLE_FINANCE,[item itemCode]];
					}					
				} else if ([[item country] isEqualToString:TRADE_ITEM_COUNTRY_AU] == YES) {
					if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"AUD"]) {
						urlString = [NSString stringWithFormat:FORMAT_GOOGLE_FINANCE_AUD,[item itemCode]];
					} else {
						urlString = [NSString stringWithFormat:FORMAT_GOOGLE_FINANCE,[item itemCode]];
					}
				} else if ([[item country] isEqualToString:TRADE_ITEM_COUNTRY_JP] == YES) {
					if ([[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:@"JPY"]) {
						urlString = [NSString stringWithFormat:FORMAT_GOOGLE_FINANCE_JPY,[item itemCode]];
					} else {
						urlString = [NSString stringWithFormat:FORMAT_GOOGLE_FINANCE,[item itemCode]];
					}
				} else {
					NSString* currency = [doc CountryToCurrency: [item country]];
					if ([item itemCategory] == ITEM_CATEGORY_CURRENCY && currency &&
						[[item itemCode] length] == 3 && ![[item itemCode] isEqualToString:currency]) {
						urlString = [NSString stringWithFormat:FORMAT_GOOGLE_FINANCE_FX,[item itemCode],currency];
					} else {
						urlString = [NSString stringWithFormat:FORMAT_GOOGLE_FINANCE,[item itemCode]];
					}
				}
			} else {
				urlString = [NSString stringWithFormat:FORMAT_GOOGLE_FINANCE,[item itemCodeGoogle]];
			}
			for (Bookmark *bookmark in crawlingList) {
				if ([[bookmark url] isEqualToString:urlString]) {
					NSLog(@"bookmark already added %@",[bookmark url]);
					urlString = nil;
					break;
				}
			}
			if (urlString) {
				bookmark = [[Bookmark alloc] init];
				[bookmark setBookmark:nil:urlString];
				[crawlingList addObject:bookmark];
				NSLog(@"bookmark add %@",[bookmark url]);
				[bookmark release];
			}
		}
		if (minkabu == YES && [item itemCode] != nil &&
			[[item itemCode] isEqualToString:@""] == NO &&
			[item type] != ITEM_TYPE_INDEX) {
			// Add minkabu to list
			if ([[item country] isEqualToString:TRADE_ITEM_COUNTRY_JP] == YES  && [item itemCategory] == ITEM_CATEGORY_STOCK) {
				urlString = [NSString stringWithFormat:FORMAT_MINKABU_JP_STOCK,[item itemCodeJP]];
				for (Bookmark *bookmark in crawlingList) {
					if ([[bookmark url] isEqualToString:urlString]) {
						NSLog(@"bookmark already added %@",[bookmark url]);
						urlString = nil;
						break;
					}
				}
				if (urlString) {
					bookmark = [[Bookmark alloc] init];
					[bookmark setBookmark:nil:urlString];
					[crawlingList addObject:bookmark];
					NSLog(@"bookmark add %@",[bookmark url]);
					[bookmark release];
				}
			}
		}
		if (ir == YES && [item url] != nil &&
			[[item url] isEqualToString:@""] == NO &&
			[[item url] isEqualToString:INITIAL_IR_SITE] == NO) {
			// Add IR to list
			urlString = [item url];
			for (Bookmark *bookmark in crawlingList) {
				if ([[bookmark url] isEqualToString:urlString]) {
					NSLog(@"bookmark already added %@",[bookmark url]);
					urlString = nil;
					break;
				}
			}
			if (urlString) {
				bookmark = [[Bookmark alloc] init];
				[bookmark setBookmark:nil:urlString];
				[crawlingList addObject:bookmark];
				NSLog(@"bookmark add %@",[bookmark url]);
				[bookmark release];
			}
		}
	}
	return [crawlingList count];
}

- (int)createCrawlingList:(NSMutableArray*)bookmarks
{
	if (crawlingList) {
		[self deleteCrawlingList];
	}
	crawlingList = [[NSMutableArray alloc] init];
	for (Bookmark* bookmark in bookmarks) {
		[crawlingList addObject:bookmark];
	}
	return [crawlingList count];
}

- (void)deleteCrawlingList
{
	NSLog(@"DeleteCrawlingList");
	[crawlingList removeAllObjects];
	[crawlingList release];
	crawlingList = nil;
	return;
}

- (void)clearCrawlingList
{
	NSLog(@"ClearCrawlingList");
	if (crawling == YES) {
		crawling = NO;
		crawlingIndex = 0;
		[self stopTimerCrawling];
		NSLog(@"Crawling is stopped");
	}
	[crawlingList removeAllObjects];
	return;
}

- (void)addItemToCrawlingList:(NSString*)url
{
	if (url == nil) {
		return;
	}
	for (Bookmark *bookmark in crawlingList) {
		if ([[bookmark url] isEqualToString:url]) {
			NSLog(@"bookmark already added %@",[bookmark url]);
			return;
		}
	}
	if (crawlingList == nil) {
		crawlingList = [[NSMutableArray alloc] init];
	}
	Bookmark* bookmark = [[Bookmark alloc] init];
	[bookmark setBookmark:nil:url];
	[crawlingList addObject:bookmark];
	NSLog(@"bookmark add %@",[bookmark url]);
	[bookmark release];
}

- (void)startCrawling
{
	if (crawlingList == nil) {
		return;
	}
    [[doc reader] stopCrawling:NO];
	crawling = YES;
	crawlingIndex = 0;
	Bookmark* bookmark = [crawlingList objectAtIndex:crawlingIndex];
	if (bookmark) {
		NSSound *sound = [NSSound soundNamed:@"Submarine"];
		[sound play];
		[doc jumpUrl:[bookmark url]:NO];
		[doc enableUrlRequest:NO];
        maxScrollCount = WEB_AUTOSCROLL_COUNT;
		[self startTimerCrawling:CRAWLING_TIMER_CMD_CANCEL];
	}
}

- (void)startCrawling:(bool)yahoo :(bool)google :(bool)minkabu :(bool)ir
{
	NSLog(@"startCrawling");
	if ([[doc portfolioArray] count] == 0) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"NO_ITEMS",@"No item in portfolio.")];
		[alert beginSheetModalForWindow:[doc win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}	
	[self createCrawlingList:yahoo:google:minkabu:ir];
	if ([crawlingList count] == 0) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"NO_CRAWLING_SITE",@"web site for autopilot not found.")];
		[alert beginSheetModalForWindow:[doc win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
    [[doc reader] stopCrawling:NO];
	crawling = YES;
	crawlingIndex = 0;
	Bookmark* bookmark = [crawlingList objectAtIndex:crawlingIndex];
	if (bookmark) {
		NSSound *sound = [NSSound soundNamed:@"Submarine"];
		[sound play];
		[doc jumpUrl:[bookmark url]:NO];
		[doc enableUrlRequest:NO];
        [doc enableWeb];
        if (ir == YES) {
            maxScrollCount = BOOKMARK_AUTOSCROLL_COUNT;
        } else {
            maxScrollCount = WEB_AUTOSCROLL_COUNT;
        }
		[self startTimerCrawling:CRAWLING_TIMER_CMD_CANCEL];
	}
}

- (void)startCrawlingBookmark
{
	NSLog(@"startCrawlingBookmark");
	[self createCrawlingList:[doc bookmarks]];
	if ([crawlingList count] == 0) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"NO_CRAWLING_SITE",@"web site for autopilot not found.")];
		[alert beginSheetModalForWindow:[doc win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
    [[doc reader] stopCrawling:NO];
	crawling = YES;
	crawlingIndex = 0;
	Bookmark* bookmark = [crawlingList objectAtIndex:crawlingIndex];
	if (bookmark) {
		NSSound *sound = [NSSound soundNamed:@"Submarine"];
		[sound play];
		[doc jumpUrl:[bookmark url]:NO];
		[doc enableUrlRequest:NO];
        [doc enableWeb];
        maxScrollCount = BOOKMARK_AUTOSCROLL_COUNT;
		[self startTimerCrawling:CRAWLING_TIMER_CMD_CANCEL];
	}
}

- (void)stopCrawling:(bool)warn
{
	NSLog(@"stopCrawling");
	if (crawling == YES) {
		crawling = NO;
		crawlingIndex = 0;
		[self stopTimerCrawling];
		[doc enableUrlRequest:YES];
		if (warn == YES) {
			NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"INFO",@"Info")
											 defaultButton:NSLocalizedString(@"OK",@"Ok")
										   alternateButton:nil
											   otherButton:nil
								 informativeTextWithFormat:NSLocalizedString(@"CRAWLING_INTERRUPTED",@"autopilot is interrupted.")];
			[alert beginSheetModalForWindow:[doc win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		}
	}
}

- (void)continueCrawling
{
	NSLog(@"continueCrawling");
	if (crawling == NO) {
		return;
	}
	crawlingIndex++;
	if ([crawlingList count] <= crawlingIndex) {
		[self stopCrawling:NO];
		return;
	}
	Bookmark* bookmark = [crawlingList objectAtIndex:crawlingIndex];
	if (bookmark) {
		NSSound *sound = [NSSound soundNamed:@"Submarine"];
		[sound play];
		[doc jumpUrl:[bookmark url]:NO];
		[doc enableUrlRequest:NO];
        [doc enableWeb];
		[self startTimerCrawling:CRAWLING_TIMER_CMD_CANCEL];
	}
}

- (void)pauseCrawling:(bool)pause {
	if (crawling == NO) {
		crawlingPaused = NO;
		return;
	}
	if (pause == YES) {
		[self stopTimerCrawling];
	} else {
		[self continueCrawling];
	}
	crawlingPaused = pause;
}

- (void)startTimerCrawling:(int)cmd {
	float timer;
    if (maxScrollCount == WEB_AUTOSCROLL_COUNT) {
        timer = AUTOPILOT_WAIT_TIMER;
    } else {
        timer = AUTOPILOT_CONT_TIMER;
    }
	if (crawlingTimer) {
		[self stopTimerCrawling];
	}
	crawlingTimerCmd = cmd;
	if (cmd == CRAWLING_TIMER_CMD_CANCEL) {
		timer = AUTOPILOT_CANCEL_TIMER;
	}
	crawlingTimer = [[NSTimer scheduledTimerWithTimeInterval:timer
													  target:self
													selector:@selector(checkTimerCrawling:)
													userInfo:nil
													 repeats:NO] retain];
	[doc enableUrlRequest:YES];
}

- (void)stopTimerCrawling {
	if (crawlingTimer) {
		[crawlingTimer invalidate];
		[crawlingTimer release];
		crawlingTimer = nil;
	}
}

- (void)checkTimerCrawling:(NSTimer*) timer {
	switch (crawlingTimerCmd) {
		case CRAWLING_TIMER_CMD_CNT:
			if (crawlingList == NO) {
				[self stopTimerCrawling];
				return;
			}
            [[doc webView] scrollLineDown:self];
            scrollCount = WEB_AUTOSCROLL_COUNT;
            [self startTimerScroll];
			[self continueCrawling];
			break;
		case CRAWLING_TIMER_CMD_SCROLL:
            [[doc webView] scrollLineDown:self];
            scrollCount = maxScrollCount;
            [self startTimerScroll];
            [self startTimerCrawling:CRAWLING_TIMER_CMD_CNT];
            break;
		case CRAWLING_TIMER_CMD_CANCEL:
			if ([[doc webView] isLoading] == YES) {
				[[doc webView] stopLoading:doc];
                [[doc webView] scrollLineDown:self];
                scrollCount = maxScrollCount;
                [self startTimerScroll];
				if (crawling == YES && crawlingPaused == NO) {
					NSSound *sound = [NSSound soundNamed:@"Pop"];
					[sound play];
                    if (maxScrollCount == WEB_AUTOSCROLL_COUNT) {
                        [self startTimerCrawling:CRAWLING_TIMER_CMD_CNT];
                    } else {
                        [self startTimerCrawling:CRAWLING_TIMER_CMD_SCROLL];
                    }
				}
			}
			break;
	}
}

- (void)startTimerScroll {
	float timer = AUTOSCROLL_TIMER;
	if (scrollTimer) {
		[self stopTimerScroll];
	}
    if (scrollCount > 0) {
        scrollTimer = [[NSTimer scheduledTimerWithTimeInterval:timer
                                                        target:self
                                                      selector:@selector(checkTimerScroll:)
                                                      userInfo:nil
                                                       repeats:NO] retain];
    }
}

- (void)stopTimerScroll {
	if (scrollTimer) {
		[scrollTimer invalidate];
		[scrollTimer release];
		scrollTimer = nil;
	}
}

- (void)checkTimerScroll:(NSTimer*) timer {
    [[doc webView] scrollLineDown:self];
    scrollCount--;
    if (scrollCount > 0) {
        [self startTimerScroll];
    } else {
        [self stopTimerScroll];
    }
}

@synthesize		targetItem;
@synthesize		doc;
@synthesize		documentUrl;
@synthesize		connectionIndex;
@synthesize		connectionRetry;
@synthesize		connectAscending;
@synthesize		crawling;
@synthesize		modifiedPrice;
@synthesize     scrollCount;
@end
