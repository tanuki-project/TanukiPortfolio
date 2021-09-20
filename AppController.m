//
//  AppController.m
//  tPortfolio
//
//  Created by Takahiro Sayama on 10/12/05.
//  Copyright 2011 tanuki-project. All rights reserved.
//

#import		"AppController.h"
#import		"PreferenceController.h"
#import		"MyDocument.h"
#include	"WebDocumentReader.h"
#include	"infoPanel.h"
#include	"PortfolioItem.h"

NSString* const tPrtSpeechSpeedKey = @"Speech Speed";
NSString* const tPrtSpeechVoiceKey = @"Speech Voice";

extern NSString*    tPrtEnableRedirectKey;
extern NSString*	tPrtCustomCountryKey;
extern NSString*	tPrtCustomCountryCodeKey;
extern NSString*	tPrtCustomCountryNameKey;
extern NSString*	tPrtCustomCurrencyCodeKey;
extern NSString*	tPrtCustomCurrencyNameKey;
extern NSString*	tPrtCustomCurrencySymbolKey;
extern NSString*    tPrtFaveriteKanjiKey;
extern NSString*    tPrtSelectAutoPilotKey;
extern NSString*    tPrtEnableDataSheetKey;

extern bool         openUntitled;
extern bool         enableRedirect;
extern bool         enableDataInputSheet;
extern bool			separateCash;

extern bool			customCountry;
extern NSString*	customCountryCode;
extern NSString*	customCountryName;
extern NSString*	customCurrencyCode;
extern NSString*	customCurrencyName;
extern NSString*	customCurrencySymbol;

AppController		*tPrtController = nil;
PortfolioItem		*tPrtPortfolioItem = nil;
PortfolioItem		*tPrtCashItem = nil;
NSString			*speechVoice = nil;
NSString			*speechVoiceLocaleIdentifier = nil;
double				speechSpeed = SPEECH_RATE_NORMAL;

@implementation AppController

+ (void)initialize
{
	// set default user preference values.
	NSMutableDictionary	*defaultValues = [NSMutableDictionary dictionary];
	NSData *colorAsData = [NSKeyedArchiver archivedDataWithRootObject:[NSColor whiteColor]];
	[defaultValues setObject:colorAsData forKey:tPrtTableBgColorKey];
	colorAsData = [NSKeyedArchiver archivedDataWithRootObject:[NSColor blackColor]];
	[defaultValues setObject:colorAsData forKey:tPrtTableFontColorKey];
	[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:tPrtEmptyDocKey];
	[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:tPrtAutoSaveKey];
	[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:tPrtTradeOrderKey];
	[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:tPrtSeparateCashKey];
	[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:tPrtAutoUpdateKey];
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:tPrtSortInfoPanelKey];
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:tPrtPortfolioDetailKey];
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:tPrtTradeDetailKey];
	[defaultValues setObject:[NSNumber numberWithDouble:SPEECH_RATE_NORMAL] forKey:tPrtSpeechSpeedKey];	
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:tPrtCustomCountryKey];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:tPrtEnableRedirectKey];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:tPrtEnableDataSheetKey];
    //[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:tPrtSelectAutoPilotKey];
	[defaultValues setObject:@"狸" forKey:tPrtFaveriteKanjiKey];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
	//NSLog(@"registreted defaults: %@", defaultValues);
}

- (id)init
{
	self = [super init];
	NSLog(@"init AppController");
	preferenceController = nil;
	docs = [[NSMutableArray alloc] init];
	tPrtController = self;
	mainDoc = nil;
	speechingDoc = nil;
	voiceList = [[NSSpeechSynthesizer availableVoices] retain];
	speeching = NO;
	speechSynth = [[NSSpeechSynthesizer alloc] initWithVoice:nil];
	[speechSynth setDelegate:self];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	speechSpeed = [defaults doubleForKey: tPrtSpeechSpeedKey];
    if (speechSpeed < SPEECH_RATE_SLOW || speechSpeed > SPEECH_RATE_VERYFAST) {
        speechSpeed = SPEECH_RATE_NORMAL;
    }
    speechVoice = [defaults objectForKey: tPrtSpeechVoiceKey];
    if (speechVoice) {
        for (int i = 0; i < [voiceList count]; i++) {
            NSString* voice = [voiceList objectAtIndex:i];
            if (voice && [voice isEqualToString:speechVoice] == YES) {
                speechVoiceLocaleIdentifier = [self voiceLocaleIdentifier:i];
                break;
            }
        }
    } 
    if (speechVoiceLocaleIdentifier == nil) {
        for (int i = 0; i < [voiceList count]; i++) {
            NSString* voice = [voiceList objectAtIndex:i];
            if (voice && [voice isEqualToString:[speechSynth voice]] == YES) {
                speechVoice = [voiceList objectAtIndex:i];
                speechVoiceLocaleIdentifier = [self voiceLocaleIdentifier:i];
                break;
            }
        }
    }
    enableRedirect = [defaults boolForKey:tPrtEnableRedirectKey];
    enableDataInputSheet = [defaults boolForKey:tPrtEnableDataSheetKey];
	customCountry = [defaults boolForKey:tPrtCustomCountryKey];
	customCountryCode = [defaults objectForKey:tPrtCustomCountryCodeKey];
	if (customCountryCode == nil) {
		customCountryCode = @"";
	}
	customCountryName = [defaults objectForKey:tPrtCustomCountryNameKey];
	if (customCountryName == nil) {
		customCountryName = @"";
	}
	customCurrencyCode = [defaults objectForKey:tPrtCustomCurrencyCodeKey];
	if (customCurrencyCode == nil) {
		customCurrencyCode = @"";
	}
	customCurrencyName = [defaults objectForKey:tPrtCustomCurrencyNameKey];
	if (customCurrencyName == nil) {
		customCurrencyName = @"";
	}
	customCurrencySymbol = [defaults objectForKey:tPrtCustomCurrencySymbolKey];
	if (customCurrencySymbol == nil) {
		customCurrencySymbol = @"";
	}
    separateCash = [defaults boolForKey:tPrtSeparateCashKey];
	return self;
}

- (void)dealloc
{
	NSLog(@"dealloc AppController");
	[self removeAllDocs];
	[voiceList release];
	[speechSynth release];
	[super dealloc];
}

- (void)menuWillOpen:(NSMenu *)menu
{
	NSLog(@"menuWillOpen");
	[self selectMainDoc];
	[self buildVoiceMenu];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
	NSLog(@"validateMenuItem: %@", item);
	SEL action = [item action];
    if (action == @selector(showPreferencePanel:)) {
		return YES;
	}
	if (action == @selector(selectVoice:)) {
		return YES;
	}
	if (mainDoc == nil) {
		return NO;
	}
	if (action == @selector(openItem:) ||
		action == @selector(updatePrice:) ||
		action == @selector(goToIR:) ||
		action == @selector(setIRSite:)) {
		if ([[mainDoc tableView] selectedRow] != -1) {
			return YES;
		}
	}
	if (action == @selector(openReader:)) {
        return YES;
    }
	if (action == @selector(checkoutPortfolio:) ||
        action == @selector(checkoutPerformance:) ||
		action == @selector(updateAllPricePrimary:) ||
		action == @selector(updateAllPriceSecondary:) ||
		action == @selector(evaluateAllItems:) ||
		action == @selector(startCrawlingYahoo:) ||
		action == @selector(startCrawlingGoogle:) ||
		action == @selector(startCrawlingMinkabu:) ||
		action == @selector(startCrawlingIR:) ||
		action == @selector(exportCSV:) ||
		action == @selector(exportWinCSV:)) {
		if ([[mainDoc portfolioArray] count] > 0) {
			return YES;
		}
	}
	if (action == @selector(startCrawlingBookmark:)) {
		if ([[mainDoc bookmarks] count] > 0) {
			return YES;
		}
	}
	if (action == @selector(stopCrawling:)) {
		if ([[mainDoc webReader] crawling] == YES) {
			return YES;
		}
	}
	if (action == @selector(goToYahoo:) ||
		action == @selector(importCSV:) ||
		action == @selector(importWinCSV:) ||
		action == @selector(importDJI:) ||
		action == @selector(importCORE30:) ||
		action == @selector(importUSD:) ||
		action == @selector(importEUR:) ||
		action == @selector(importJPY:) ||
		action == @selector(importIndex:)) {
		return YES;
	}
	if (action == @selector(initHistory:) ||
		action == @selector(clipHistory:)) {
		if ([[mainDoc portfolioArray] count] > 0 &&
			[[mainDoc tableView] selectedRow] != -1) {
			return YES;
		}
	}
	if (action == @selector(initHistoryAll:) ||
		action == @selector(clipPortfolio:)) {
		if ([[mainDoc portfolioArray] count] > 0) {
			return YES;
		}
	}
	if (action == @selector(showInfoPanel:) ||
		action == @selector(clipInfoPanel:)) {
		if ([mainDoc iPanel]) {
			return YES;
		}
	}
	if (action == @selector(showGraphPanel:)) {
        if ([[mainDoc portfolioSumArray] count] > 0 && [[mainDoc tableViewSum] numberOfRows] > 0) {
            return YES;
        }
    }
	if (action == @selector(startReadPanel:)) {
		if ([mainDoc iPanel] && [[mainDoc iPanel] speeching] == NO) {
			return YES;
		}
	}
	if (action == @selector(stopReadPanel:)) {
		if ([mainDoc iPanel] && [[mainDoc iPanel] speeching] == YES) {
			return YES;
		}
	}
	if (action == @selector(startReadPortfolio:)) {
		if (speeching == NO) {
			if ([mainDoc portfolioArray] && [[mainDoc portfolioArray] count] > 0) {
				return YES;
			}
		}
	}
	if (action == @selector(startSpeech:)) {
		if (speeching == NO) {
			NSPasteboard* pb = [NSPasteboard pasteboardWithName:NSGeneralPboard];
			NSArray* types = [pb types];
			if ([types containsObject:NSStringPboardType]) {
				return YES;
			}
		}
	}
	if (action == @selector(stopSpeech:)) {
		if (speeching == YES) {
			return YES;
		}
	}
	if (action == @selector(setSpeechSpeedSlow:)) {
		if (speechSpeed != SPEECH_RATE_SLOW) {
			return YES;
		}
	}
	if (action == @selector(setSpeechSpeedNormal:)) {
		if (speechSpeed != SPEECH_RATE_NORMAL) {
			return YES;
		}
	}
	if (action == @selector(setSpeechSpeedFast:)) {
		if (speechSpeed != SPEECH_RATE_FAST) {
			return YES;
		}
	}
	if (action == @selector(setSpeechSpeedVeryFast:)) {
		if (speechSpeed != SPEECH_RATE_VERYFAST) {
			return YES;
		}
	}
	return NO;
}

- (void)buildVoiceMenu
{
	static bool bFirst = YES;
	if (bFirst == NO) {
		return;
	}
	for (int i = 0; i < [voiceList count]; i++) {

        NSString *voiceItem;
        NSString *voiceId = [self voiceLocaleIdentifier:i];
        if (voiceId && [voiceId isEqualToString:@"en_US"] == NO) {
            voiceItem = [[NSString alloc] initWithFormat:@"%@ (%@)",[self voiceName:i],voiceId];
        } else {
            voiceItem = [[NSString alloc] initWithFormat:@"%@",[self voiceName:i]];
        }
        NSLog(@"voiceItem: %@",voiceItem);
		NSMenuItem* subMenu = [[NSMenuItem alloc] initWithTitle:voiceItem action:@selector(selectVoice:) keyEquivalent:@""];
		[[voiceMenu submenu] insertItem:subMenu atIndex:i];
		NSString* voice = [voiceList objectAtIndex:i];
		if (voice && [voice isEqualToString:speechVoice] == YES) {
			[subMenu setState:YES];
		}
        [voiceItem release];
		[subMenu release];
	}
	bFirst = NO;
}

- (void)buildCountryList
{
	for (MyDocument* doc in docs) {
		[doc buildCountyList];
	}
}

- (void)addDoc:(MyDocument*)doc
{
	if (doc == nil) {
		return;
	}
	NSLog(@"addDoc: %@", [[doc win] title]);
	[docs addObject:doc];
	mainDoc = doc;
}

- (void)removeDoc:(MyDocument*)doc
{
	if (doc == nil) {
		return;
	}
	NSLog(@"removeDoc: %@", [[doc win] title]);
	if (doc == speechingDoc) {
		speechingDoc = nil;
		[self stopSpeech:self];
	}
	[docs removeObject:doc];
	[self selectMainDoc];
	if (mainDoc == nil) {
		[self stopSpeech:self];
	}
}

- (void)selectMainDoc
{
	if ([docs count] == 0) {
		mainDoc = nil;
		return;
	}
	for (MyDocument* doc in docs) {
		if (mainDoc == nil) {
			NSLog(@"setMainDoc: %@", [[doc win] title]);
			mainDoc = doc;
		}
		if ([[doc win] isMainWindow] == YES) {
			if (mainDoc != doc) {
				mainDoc = doc;
				NSLog(@"setMainDoc: %@", [[doc win] title]);
			}
			break;
		}
	}
}

- (void)removeAllDocs
{
	[docs removeAllObjects];
	[docs release];
}

- (IBAction)showPreferencePanel:(id)sender
{
	if (!preferenceController) {
		preferenceController = [[PreferenceController alloc] init];
	}
	NSLog(@"showing %@", preferenceController);
	[preferenceController loadBookmark];
	[preferenceController loadFeed];
	[preferenceController showWindow:self];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication*)sender
{
	static bool bFirst = YES;
	bool shouldOpen = NO;
    openUntitled = YES;
	if (bFirst == YES) {
		[self buildVoiceMenu];
		shouldOpen = [[NSUserDefaults standardUserDefaults] boolForKey:tPrtEmptyDocKey];
	}
	NSLog(@"applicationShould OpenUntitledFile: %d", shouldOpen);
	bFirst = NO;
	return shouldOpen;
}

#pragma mark Actions

- (IBAction)checkoutPortfolio:(id)sender
{
	NSLog(@"checkoutPortfolio");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	NSSound *sound = [NSSound soundNamed:@"Pop"];
	[sound play];
	[mainDoc checkoutPortfolio:sender];
}

- (IBAction)checkoutPerformance:(id)sender
{
    NSLog(@"checkoutPerformance");
    if (mainDoc == nil) {
        NSBeep();
        return;
    }
    NSSound *sound = [NSSound soundNamed:@"Pop"];
    [sound play];
    [mainDoc checkoutPerformance:sender];
}

- (IBAction)startCrawlingYahoo:(id)sender
{
	NSLog(@"startCrawlingYahoo");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	if ([mainDoc progressWebView] == YES ||
		[mainDoc progressConnection] == YES) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"HTTP_IN_PROGRESS",@"HTTP access is in progress.")];
		[alert beginSheetModalForWindow:[mainDoc win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
	[mainDoc startCrawlingYahoo:sender];
}

- (IBAction)startCrawlingMinkabu:(id)sender
{
	NSLog(@"startCrawlingMinkabu");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	if ([mainDoc progressWebView] == YES ||
		[mainDoc progressConnection] == YES) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"HTTP_IN_PROGRESS",@"HTTP access is in progress.")];
		[alert beginSheetModalForWindow:[mainDoc win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
	[mainDoc startCrawlingMinkabu:sender];
}

- (IBAction)startCrawlingGoogle:(id)sender
{
	NSLog(@"startCrawlingGoogle");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	if ([mainDoc progressWebView] == YES ||
		[mainDoc progressConnection] == YES) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"HTTP_IN_PROGRESS",@"HTTP access is in progress.")];
		[alert beginSheetModalForWindow:[mainDoc win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
	[mainDoc startCrawlingGoogle:sender];
}

- (IBAction)startCrawlingIR:(id)sender
{
	NSLog(@"startCrawlingIR");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	if ([mainDoc progressWebView] == YES ||
		[mainDoc progressConnection] == YES) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"HTTP_IN_PROGRESS",@"HTTP access is in progress.")];
		[alert beginSheetModalForWindow:[mainDoc win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
	[mainDoc startCrawlingIR:sender];
}

- (IBAction)startCrawlingBookmark:(id)sender
{
	NSLog(@"startCrawlingBookmark");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	if ([mainDoc progressWebView] == YES ||
		[mainDoc progressConnection] == YES) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"HTTP_IN_PROGRESS",@"HTTP access is in progress.")];
		[alert beginSheetModalForWindow:[mainDoc win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
	[mainDoc startCrawlingBookmark:sender];
}

- (IBAction)stopCrawling:(id)sender
{
	NSLog(@"stopCrawlingYahoo");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	[mainDoc stopCrawling:sender];
}

- (IBAction)updateAllPricePrimary:(id)sender
{
	NSLog(@"updateAllPrice");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	if ([mainDoc progressWebView] == YES ||
		[mainDoc progressConnection] == YES) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"HTTP_IN_PROGRESS",@"HTTP access is in progress.")];
		[alert beginSheetModalForWindow:[mainDoc win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
	NSSound *sound = [NSSound soundNamed:@"Ping"];
	[sound play];
	[mainDoc refreshPrice:sender];
}

- (IBAction)updateAllPriceSecondary:(id)sender
{
	NSLog(@"updateAllPrice");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	if ([mainDoc progressWebView] == YES ||
		[mainDoc progressConnection] == YES) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"HTTP_IN_PROGRESS",@"HTTP access is in progress.")];
		[alert beginSheetModalForWindow:[mainDoc win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
	NSSound *sound = [NSSound soundNamed:@"Ping"];
	[sound play];
	[mainDoc refreshPriceDescending:sender];
}

- (IBAction)evaluateAllItems:(id)sender
{
	NSLog(@"evaluateAllItems");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	[mainDoc evaluateAllItems:sender];
}

- (IBAction)openItem:(id)sender
{
	NSLog(@"openItem");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	[mainDoc openItem:sender];
}

- (IBAction)openReader:(id)sender
{
	NSLog(@"openReader");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	[mainDoc openReader:sender];
}

- (IBAction)updatePrice:(id)sender
{
	NSLog(@"updatePrice");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	if ([mainDoc progressWebView] == YES ||
		[mainDoc progressConnection] == YES) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"HTTP_IN_PROGRESS",@"HTTP access is in progress.")];
		[alert beginSheetModalForWindow:[mainDoc win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
	NSSound *sound = [NSSound soundNamed:@"Submarine"];
	[sound play];
	[mainDoc goToPortalSite:sender];
}

- (IBAction)goToYahoo:(id)sender
{
	NSLog(@"goToYahoo");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	if ([mainDoc progressWebView] == YES ||
		[mainDoc progressConnection] == YES) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"HTTP_IN_PROGRESS",@"HTTP access is in progress.")];
		[alert beginSheetModalForWindow:[mainDoc win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
	NSSound *sound = [NSSound soundNamed:@"Submarine"];
	[sound play];
	[mainDoc goToYahooFinance:sender];
}

- (IBAction)goToIR:(id)sender
{
	NSLog(@"goToIR");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	if ([mainDoc progressWebView] == YES ||
		[mainDoc progressConnection] == YES) {
		NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
										 defaultButton:NSLocalizedString(@"OK",@"Ok")
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"HTTP_IN_PROGRESS",@"HTTP access is in progress.")];
		[alert beginSheetModalForWindow:[mainDoc win] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
	NSSound *sound = [NSSound soundNamed:@"Submarine"];
	[sound play];
	[mainDoc goToIRSite:sender];
}

- (IBAction)setIRSite:(id)sender
{
	NSLog(@"goToIR");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	[mainDoc setIRSite:sender];
}

- (IBAction)showInfoPanel:(id)sender
{
	NSLog(@"showInfoPanel");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	if ([[mainDoc iPanel] speeching] == NO) {
        [[mainDoc iPanel] rearrangePanel];
        [[[mainDoc iPanel] infoTableView] deselectAll:self];        
    }
	[[mainDoc iPanel] showWindow:self];
}

- (IBAction)showGraphPanel:(id)sender
{
	NSLog(@"showInfoPanel");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
    if ([[mainDoc portfolioSumArray] count] == 0) {
        return;
    }
	[mainDoc openGraph:sender];
}

#pragma mark CSV

- (IBAction)importCSV:(id)sender
{
	NSLog(@"importCSV");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	[mainDoc importCSV:NO];
}

- (IBAction)exportCSV:(id)sender
{
	NSLog(@"exportCSV");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	[mainDoc exportCSV:NO];
}

- (IBAction)importWinCSV:(id)sender
{
	NSLog(@"importWinCSV");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	[mainDoc importCSV:YES];
}

- (IBAction)exportWinCSV:(id)sender
{
	NSLog(@"exportWiCSV");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	[mainDoc exportCSV:YES];
}

- (IBAction)importDJI:(id)sender
{
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	[mainDoc importSample:@"Template-DJI"];
}

- (IBAction)importCORE30:(id)sender
{
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	[mainDoc importSample:@"Template-Core30"];
}

- (IBAction)importJPY:(id)sender
{
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	[mainDoc importSample:@"Template-FX-JPY"];
}

- (IBAction)importUSD:(id)sender
{
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	[mainDoc importSample:@"Template-FX-USD"];
}

- (IBAction)importEUR:(id)sender
{
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	[mainDoc importSample:@"Template-FX-EUR"];
}

- (IBAction)importIndex:(id)sender
{
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	[mainDoc importSample:@"Template-Index"];
}

- (IBAction)initHistory:(id)sender
{
	if (mainDoc == nil || [[mainDoc tableView] selectedRow] == -1) {
		NSBeep();
		return;
	}
	[mainDoc initHistory];
}

- (IBAction)initHistoryAll:(id)sender
{
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	[[mainDoc tableView] deselectAll:self];
	[mainDoc initHistory];
}

#pragma mark Clip

- (IBAction)clipInfoPanel:(id)sender
{
	NSLog(@"clipInfoPanel");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	NSMutableString* clip = [[NSMutableString alloc] init];
	[clip setString:@""];
	NSString* line;
	for (infoItem* item in [[mainDoc iPanel] items]) {
		if ([item raise] > 0) {
			line = [NSString stringWithFormat:@"%@\t%@\t%@\t%@\t+%0.2f%@\r\n", [item code], [item name], [item price], [item diff], [item raise]*100, @"%"];
		} else {
			line = [NSString stringWithFormat:@"%@\t%@\t%@\t%@\t%0.2f%@\r\n", [item code], [item name], [item price], [item diff], [item raise]*100, @"%"];
		}
		NSLog(@"%@",line);
		[clip appendString:line];
	}
	NSPasteboard* pb = [NSPasteboard pasteboardWithName:NSGeneralPboard];
	[pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	[pb setString:clip forType:NSStringPboardType];
	[clip release];
}

- (IBAction)clipHistory:(id)sender
{
	NSLog(@"clipHistory");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	int row = [[mainDoc tableView] selectedRow];
	if (row == -1) {
		NSBeep();
		return;
	}
	NSDateFormatter	*dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%Y/%m/%d" allowNaturalLanguage:NO];
	NSMutableString* clip = [[NSMutableString alloc] init];
	[clip setString:NSLocalizedString(@"CLIP_HISTORY_HEAD",@"Type\tDate\tPrice\tBuy\tSell\tIncome\tCharge\tTax\tSettlement\tProfit\tMemo\r\n")];
	NSString* line;	
	PortfolioItem *item = [[mainDoc portfolioArray] objectAtIndex:row];
	for (TradeItem* trade in [item trades]) {
		line = [NSString stringWithFormat:@"%@\t%@\t%0.2f\t%0.4f\t%0.4f\t%0.2f\t%0.2f\t%0.2f\t%0.2f\t%0.2f\t%@\r\n",
				[trade kind], [dateFormatter stringFromDate:[trade date]], [trade price], [trade buy], [trade sell],
				[trade dividend], [trade charge], [trade tax], [trade settlement], [trade profit], [trade comment]];
		NSLog(@"%@",line);
		[clip appendString:line];
	}
	NSPasteboard* pb = [NSPasteboard pasteboardWithName:NSGeneralPboard];
	[pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	[pb setString:clip forType:NSStringPboardType];
	[clip release];
	[dateFormatter release];
}

- (IBAction)clipPortfolio:(id)sender
{
	NSLog(@"clipPortfolio");
	if (mainDoc == nil) {
		NSBeep();
		return;
	}
	NSMutableString* clip = [[NSMutableString alloc] init];
	[clip setString:NSLocalizedString(@"CLIP_PORTFOLIO_HEAD",@"Code\tItem\tKind\tCountry\tPrice\tAverage\tQuantity\tPerformance\r\n")];
	NSString* line;
	for (PortfolioItem* item in [mainDoc portfolioArray]) {
		line = [NSString stringWithFormat:@"%@\t%@\t%@\t%@\t%0.2f\t%0.4f\t%0.4f\t%0.2f\r\n",
				[item itemCode], [item itemName], [item itemType], [item country],
				[item price], [item av_price], [item quantity],[item rise]];
		NSLog(@"%@",line);
		[clip appendString:line];
	}
	NSPasteboard* pb = [NSPasteboard pasteboardWithName:NSGeneralPboard];
	[pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	[pb setString:clip forType:NSStringPboardType];
	[clip release];
}

#pragma mark Speech

- (IBAction)startReadPortfolio:(id)sender
{
	NSLog(@"startReadPortfolio");
	if (mainDoc == nil || [[mainDoc portfolioArray] count] == 0) {
		NSBeep();
		return;
	}
    [mainDoc setSpeechIndex:1];
    speeching = YES;
    speechingDoc = mainDoc;
    if ([self speechPortfolioItem] == -1) {
        [mainDoc setSpeechIndex:0];
        speeching = NO;
        speechingDoc = nil;
    }    
}

- (IBAction)startSpeech:(id)sender
{
	NSLog(@"startSpeech");
	NSPasteboard* pb = [NSPasteboard pasteboardWithName:NSGeneralPboard];
	NSArray* types = [pb types];
	if ([types containsObject:NSStringPboardType]) {
		NSString* text = [pb stringForType:NSStringPboardType];
		NSLog(@"%@", text);
		[speechSynth setVoice:speechVoice];
        [speechSynth setRate:speechSpeed];
		[speechSynth startSpeakingString:text];
		speeching = YES;
	}
}

- (IBAction)stopSpeech:(id)sender
{
	NSLog(@"stopSpeech");
	if (speeching == YES) {
		[speechSynth stopSpeaking];
		speechingDoc = nil;
		speeching = NO;
	}
}

- (int)speechPortfolioItem
{
	NSLog(@"speechPortfolioItem");
    if (speechingDoc == nil) {
        return -1;
    }
	bool				isJp = NO;
	int					index = [speechingDoc speechIndex];
	NSMutableString*	text = [[NSMutableString alloc] init];
	[text setString:@""];
	if ([speechVoiceLocaleIdentifier isEqualToString:@"ja_JP"] == YES) {
		isJp = YES;			// Japanese speeach is available.
	}
	for (PortfolioItem* item in [speechingDoc portfolioArray]) {
        if (index != [item index]) {
            continue;
        }
		NSString* line;
		NSNumberFormatter*	formatter = [[[NSNumberFormatter alloc] init] autorelease];
		NSMutableString* code = [[NSMutableString alloc] init];
		[code setString:@""];
		int len = [[item itemCode] length];
		for (int i =0; i < len; i++) {
			NSRange range = NSMakeRange(i,1);
			if (range.length == 0) {
				break;
			}
			NSString* subString = [[item itemCode] substringWithRange:range];
			if (i > 0) {
				[code appendString:@" "];
			}
			[code appendString:subString];
		}
		if ([item itemCategory] == ITEM_CATEGORY_CURRENCY) {
			[formatter setFormat:@"#,##0.00##"];
		} else if ([[item country] isEqualToString:TRADE_ITEM_COUNTRY_JP]) {
			if ([item itemCategory] == ITEM_CATEGORY_STOCK || [item itemCategory] == ITEM_CATEGORY_FUND) {
				[formatter setFormat:@"#,###"];
			} else {
				[formatter setFormat:@"#,##0.00"];
			}
		} else {
			[formatter setFormat:@"#,##0.00"];
		}
		NSString* strPrice = [NSString stringWithFormat:@"%@",[formatter stringFromNumber:[NSNumber numberWithDouble:[item price]]]];
		[formatter setFormat:@"#,##0.####"];
		NSString* strQuantity = [NSString stringWithFormat:@"%@",[formatter stringFromNumber:[NSNumber numberWithDouble:[item quantity]]]];		
		if (isJp == YES) {
            if ([item type] == ITEM_TYPE_CASH) {
				line = [NSString stringWithFormat:@"ナンバー%d, %@, %@, 残高, %@%@ . \n",
						index, code, [item itemName], strQuantity, [item itemCurrencyNameJP]];
			} else if ([item rise] < 0) {
				line = [NSString stringWithFormat:@"ナンバー%d, %@, %@, 価格, %@%@, 保有数, %@, パフォーマンス, マイナス %0.2fパーセント. \n",
						index, code, [item itemName], [item itemCurrencyNameJP], strPrice, strQuantity, -[item rise]];
			} else {
				line = [NSString stringWithFormat:@"ナンバー%d, %@, %@, 価格, %@%@, 保有数, %@, パフォーマンス, %0.2f パーセント. \n",
						index, code, [item itemName], [item itemCurrencyNameJP], strPrice, strQuantity, [item rise]];
			}
		} else {
            if ([item type] == ITEM_TYPE_CASH) {
                line = [NSString stringWithFormat:@"Number%d, %@, %@, Balance, %@%@ .\n",
                        index, code, [item itemName], [item itemCurrencySymbol], strQuantity];
            } else {
                line = [NSString stringWithFormat:@"Number%d, %@, %@, Value, %@%@, Quantity, %@, Performance, %0.2f percent. \n",
                        index, code, [item itemName], [item itemCurrencySymbol], strPrice, strQuantity, [item rise]];
            }
		}
		NSLog(@"%@",line);
		[text appendString:line];
		[code release];
        [speechSynth setVoice:speechVoice];
        [speechSynth setRate:speechSpeed];
        [speechSynth startSpeakingString:text];
        [text release];
        // Select row of current item
        long row = [[speechingDoc portfolioArray] indexOfObject:item];
        NSIndexSet* ixset = [NSIndexSet indexSetWithIndex:row];
        [[speechingDoc tableView] selectRowIndexes:ixset byExtendingSelection:NO];
        [[speechingDoc tableView] scrollRowToVisible:row];
        return 0;
	}
	[text release];
    return -1;
}

- (void)speechSynthesizer:(NSSpeechSynthesizer*)sender
		didFinishSpeaking:(BOOL)complete
{
	NSLog(@"didFinishSpeaking");
    if (speechingDoc) {
        int index = [speechingDoc speechIndex];
        if (index > 0) {
            index++;
            [speechingDoc setSpeechIndex:index];
            if ([self speechPortfolioItem] == 0) {
                return;
            }
        }
    }
    NSIndexSet* ixset = [NSIndexSet indexSetWithIndex:0];
    [[speechingDoc tableView] selectRowIndexes:ixset byExtendingSelection:NO];
    [[speechingDoc tableView] scrollRowToVisible:0];
    [[speechingDoc tableView] deselectAll:self];
	speechingDoc = nil;
	speeching = NO;
}

- (IBAction)startReadPanel:(id)sender
{
	NSLog(@"startReadPanel");
	if (mainDoc == nil || [mainDoc iPanel] == nil) {
		NSBeep();
		return;
	}
	[[mainDoc iPanel] startSpeech:self];
}

- (IBAction)stopReadPanel:(id)sender
{
	NSLog(@"stopReadPanel");
	if (mainDoc == nil || [mainDoc iPanel] == nil) {
		NSBeep();
		return;
	}
	[[mainDoc iPanel] stopSpeech:self];
}

- (IBAction)selectVoice:(id)sender
{
	NSLog(@"selectVoice: %@", [sender title]);
	int	num = [[voiceMenu submenu] numberOfItems];
	for (int i = 0; i < num; i++) {
		NSMenuItem* item = [[voiceMenu submenu] itemAtIndex:i];
		if ([[sender title] isEqualToString:[item title]] == YES) {
			speechVoice = [voiceList objectAtIndex:i];
			speechVoiceLocaleIdentifier = [self voiceLocaleIdentifier:i];
			if (speechVoice) {
				[item setState:YES];
			}
		} else {
			[item setState:NO];
		}
	}
    if (speechVoice) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject: speechVoice forKey:tPrtSpeechVoiceKey];
    }
}

- (NSString*)voiceName:(int)index
{
	NSString* voice = [voiceList objectAtIndex:index];
	NSDictionary* dict = [NSSpeechSynthesizer attributesForVoice:voice];
	return [dict objectForKey:NSVoiceName];
}

- (NSString*)voiceLocaleIdentifier:(int)index
{
	NSString* voice = [voiceList objectAtIndex:index];
	NSDictionary* dict = [NSSpeechSynthesizer attributesForVoice:voice];
	return [dict objectForKey:NSVoiceLocaleIdentifier];
}

- (IBAction)setSpeechSpeedSlow:(id)sender
{
    speechSpeed = SPEECH_RATE_SLOW;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setDouble: speechSpeed forKey:tPrtSpeechSpeedKey];
}

- (IBAction)setSpeechSpeedNormal:(id)sender
{
    speechSpeed = SPEECH_RATE_NORMAL;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setDouble: speechSpeed forKey:tPrtSpeechSpeedKey];
}

- (IBAction)setSpeechSpeedFast:(id)sender {
    speechSpeed = SPEECH_RATE_FAST;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setDouble: speechSpeed forKey:tPrtSpeechSpeedKey];
}

- (IBAction)setSpeechSpeedVeryFast:(id)sender {
    speechSpeed = SPEECH_RATE_VERYFAST;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setDouble: speechSpeed forKey:tPrtSpeechSpeedKey];
}

@synthesize		mainDoc;
@synthesize     speeching;

@end
