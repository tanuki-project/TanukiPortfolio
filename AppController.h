//
//  AppController.h
//  tPortfolio
//
//  Created by Takahiro Sayama on 10/12/05.
//  Copyright 2011 tanuki-project. All rights reserved.
//

#import		<Cocoa/Cocoa.h>

@class	PreferenceController;
@class	SubDocument;
@class	Bookmark;
@class	MyDocument;

@interface AppController : NSObject <NSSpeechSynthesizerDelegate> {
	PreferenceController	*preferenceController;
	NSMutableArray			*docs;
	MyDocument				*mainDoc;
	MyDocument				*speechingDoc;
	NSArray					*voiceList;
	NSSpeechSynthesizer		*speechSynth;
	BOOL					speeching;
	IBOutlet NSMenuItem		*voiceMenu;		
}

- (void)menuWillOpen:(NSMenu *)menu;
- (void)addDoc:(MyDocument*)doc;
- (void)removeDoc:(MyDocument*)doc;
- (void)selectMainDoc;
- (void)removeAllDocs;
- (void)buildVoiceMenu;
- (void)buildCountryList;
- (int)speechPortfolioItem;
- (void)speechSynthesizer:(NSSpeechSynthesizer*)sender didFinishSpeaking:(BOOL)complete;

- (IBAction)showPreferencePanel:(id)sender;
- (IBAction)checkoutPortfolio:(id)sender;
- (IBAction)startCrawlingYahoo:(id)sender;
- (IBAction)startCrawlingMinkabu:(id)sender;
- (IBAction)startCrawlingGoogle:(id)sender;
- (IBAction)startCrawlingIR:(id)sender;
- (IBAction)startCrawlingBookmark:(id)sender;
- (IBAction)stopCrawling:(id)sender;
- (IBAction)updateAllPricePrimary:(id)sender;
- (IBAction)updateAllPriceSecondary:(id)sender;
- (IBAction)evaluateAllItems:(id)sender;
- (IBAction)updatePrice:(id)sender;
- (IBAction)openItem:(id)sender;
- (IBAction)openReader:(id)sender;
- (IBAction)goToYahoo:(id)sender;
- (IBAction)goToIR:(id)sender;
- (IBAction)setIRSite:(id)sender;
- (IBAction)exportCSV:(id)sender;
- (IBAction)importCSV:(id)sender;
- (IBAction)exportWinCSV:(id)sender;
- (IBAction)importWinCSV:(id)sender;
- (IBAction)importDJI:(id)sender;
- (IBAction)importJPY:(id)sender;
- (IBAction)importUSD:(id)sender;
- (IBAction)importEUR:(id)sender;
- (IBAction)importCORE30:(id)sender;
- (IBAction)importIndex:(id)sender;
- (IBAction)initHistory:(id)sender;
- (IBAction)initHistoryAll:(id)sender;
- (IBAction)showInfoPanel:(id)sender;
- (IBAction)showGraphPanel:(id)sender;
- (IBAction)clipInfoPanel:(id)sender;
- (IBAction)clipHistory:(id)sender;
- (IBAction)clipPortfolio:(id)sender;
- (IBAction)startSpeech:(id)sender;
- (IBAction)stopSpeech:(id)sender;
- (IBAction)startReadPanel:(id)sender;
- (IBAction)stopReadPanel:(id)sender;
- (IBAction)startReadPortfolio:(id)sender;
- (IBAction)selectVoice:(id)sender;
- (IBAction)setSpeechSpeedSlow:(id)sender;
- (IBAction)setSpeechSpeedNormal:(id)sender;
- (IBAction)setSpeechSpeedFast:(id)sender;
- (IBAction)setSpeechSpeedVeryFast:(id)sender;
- (NSString*)voiceName:(int)index;
- (NSString*)voiceLocaleIdentifier:(int)index;

@property	(readwrite,assign)	MyDocument*			mainDoc;
@property   (readwrite)         BOOL                speeching;

@end
