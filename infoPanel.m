//
//  infoPanel.m
//  tPortfolio
//
//  Created by Takahiro Sayama on 11/01/15.
//  Copyright 2011 tanuki-project. All rights reserved.
//

#include	"PreferenceController.h"
#include	"infoPanel.h"

extern NSString		*speechVoice;
extern NSString		*speechVoiceLocaleIdentifier;
extern double       speechSpeed;

@implementation infoItem

- (id)init
{
    self = [super init];
    if (self) {
        index = 0;
        name = nil;
        price = nil;
        diff = nil;
        raise = 0;
        currency = nil;
    }
	return self;
}

- (void)dealloc
{
	if (name) {
		[name release];
	}
	if (code) {
		[code release];
	}
	if (price) {
		[price release];
	}
	if (diff) {
		[diff release];
	}
	[super dealloc];
}

@synthesize		index;
@synthesize		name;
@synthesize		code;
@synthesize		price;
@synthesize		diff;
@synthesize		raise;
@synthesize		currency;
@end


@implementation infoPanel

+ (void)initialize
{
	NSLog(@"initialize infoPanel");
}

- (id)init
{
	NSLog(@"init infoPanel");
    self = [super initWithWindowNibName:@"infoPanel"];
	if (self == nil) {
		return nil;
	}
	items = [[NSMutableArray alloc] init];
	priceList = [[NSMutableString alloc] init];
	[priceList setString:@"\r\n"];
	title = nil;
	//NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	//[nc addObserver:self selector:@selector(sortDescriptorsDidChange:)
	//		   name:sortDescriptorsDidChange
	//		 object:infoTableView];
	speechText = nil;
	speeching = NO;
	speechSynth = [[NSSpeechSynthesizer alloc] initWithVoice:nil];
	[speechSynth setDelegate:self];
	return self;
}

- (void)dealloc
{
	if (items) {
		[items removeAllObjects];
		[items release];
	}
	if (title) {
		[title release];
	}
	if (priceList) {
		[priceList release];
	}
	if (speechText) {
		[speechText release];
	}
	[speechSynth release];
	[super dealloc];
}

/*
- (void)close
{
	NSLog(@"Close: infoPanel");
	if (speeching) {
		[self stopSpeech:self];
	}
	[super close];
}
*/

- (void)windowDidLoad
{
	NSLog(@"Nib file is loaded");
	[self localizeView];
}

- (void)rearrangePanel
{
	[infoTableView reloadData];
	[itemController rearrangeObjects];
	[infoTableView deselectAll:self];
}

- (void)setItem:(NSString*)name :(NSString*)code :(NSString*)price :(NSString*)diff :(float)raise :(NSString*)currency
{
	if (items == nil) {
		items = [[NSMutableArray alloc] init];
	}
	infoItem* item = [[infoItem alloc] init];
	if (item) {
		[item setName:[name retain]];
		[item setCode:[code retain]];
		[item setPrice:[price retain]];
		[item setDiff:[diff retain]];
		[item setRaise:raise];
		[item setCurrency:currency];
		[items addObject:item];
		[item setIndex:[items count]];
		[item release];
	}
}

- (void)sortItems
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults boolForKey:tPrtSortInfoPanelKey] == NO) {
		return;
	}
	NSSortDescriptor	*descriptor;
	NSMutableArray		*sortDescriptors = [[NSMutableArray alloc] init];
	descriptor = [[NSSortDescriptor alloc] initWithKey:@"raise" ascending:NO selector:@selector(compare:)];
	[sortDescriptors addObject:descriptor];
	[items sortUsingDescriptors:sortDescriptors];
	[descriptor release];
	[sortDescriptors release];
	int index = 0;
	for (infoItem* item in items) {
		index++;
		[item setIndex:index];
	}
}

- (void)tableView:(NSTableView*)tableView sortDescriptorsDidChange:(NSArray*)oldDescriptors
{
	NSLog(@"sortDescriptorsDidChange");
	NSArray* new = [tableView sortDescriptors];
	[items sortUsingDescriptors:new];
	[tableView reloadData];
}

#pragma mark Speech

- (IBAction)controlSpeech:(id)sender {
	if (speeching == NO) {
		[self startSpeech:sender];
	} else {
		[self stopSpeech:sender];
	}
}									

- (IBAction)startSpeech:(id)sender
{
	NSLog(@"startSpeech: %@ %f", [speechSynth voice], speechSpeed);
    speechIndex = 1;
	speeching = YES;
    if ([self speechItem] == -1) {
        speechIndex = 0;
        speeching = NO;
        return;
    }
	NSImage *template = [NSImage imageNamed:@"NSStopProgressFreestandingTemplate"];
	if (template) {
		[speechButton setImage:template];
	}
}

- (IBAction)stopSpeech:(id)sender
{
	NSLog(@"stopSpeech");
	if (speeching == YES) {
		[speechSynth stopSpeaking];
		speeching = NO;
        speechIndex = 0;
		NSImage *template = [NSImage imageNamed:@"NSGoRightTemplate"];
		if (template) {
			[speechButton setImage:template];
		}
	}
}

- (void)speechSynthesizer:(NSSpeechSynthesizer*)sender
		didFinishSpeaking:(BOOL)complete
{
	NSLog(@"didFinishSpeaking:infoPanel");
    if (speeching && speechIndex > 0 && speechIndex < [items count]) {
        speechIndex++;
        if ([self speechItem] == 0) {
            return;
        }
    }
	NSImage *template = [NSImage imageNamed:@"NSGoRightTemplate"];
	if (template) {
		[speechButton setImage:template];
	}
	if (speechText) {
		[speechText release];
	}
	speechText = nil;
	speeching = NO;
    // reset selected row
    NSIndexSet* ixset = [NSIndexSet indexSetWithIndex:0];
    [infoTableView selectRowIndexes:ixset byExtendingSelection:NO];
    [infoTableView scrollRowToVisible:0];
    [infoTableView deselectAll:self];
}

- (int)speechItem {
	NSLog(@"speechItem: %@ %f", [speechSynth voice], speechSpeed);
	bool				isJp = NO;
	NSMutableString*	text = [[NSMutableString alloc] init];
	[text setString:@""];
	if ([speechVoiceLocaleIdentifier isEqualToString:@"ja_JP"] == YES) {
		isJp = YES;			// Japanese speeach is available.
	}
	NSString* line;
	NSCharacterSet* chSet = [NSCharacterSet characterSetWithCharactersInString:@"1234567890"];
	for (infoItem* item in items) {
        if ([item index] != speechIndex) {
            continue;
        }
		NSScanner* scanString = [[NSScanner alloc] initWithString:[item price]];
		NSString* sccaned = nil;
		NSString* price = nil;
		[scanString scanUpToCharactersFromSet:chSet intoString:&sccaned];
		if (sccaned) {
			if (isJp == YES) {
				price = [[NSString alloc] initWithFormat:@"%@%@", [[item price] stringByReplacingOccurrencesOfString:sccaned withString:@""], [item currency]];
			} else {
				price = [[item price] retain];
			}
		} else {
			price = [[NSString alloc] initWithFormat:@"%@", [[item price] stringByReplacingOccurrencesOfString:@"," withString:@""]];
		}
		[scanString release];
		NSMutableString* code = [[NSMutableString alloc] init];
		[code setString:@""];
		int len = [[item code] length];
		for (int i =0; i < len; i++) {
			NSRange range = NSMakeRange(i,1);
			if (range.length == 0) {
				break;
			}
			NSString* subString = [[item code] substringWithRange:range];
			if (i > 0) {
				[code appendString:@" "];
			}
			[code appendString:subString];
		}
		if ([[item diff] isEqualToString:@"0"]) {
			if (isJp == YES) {
				line = [NSString stringWithFormat:@"ナンバー%d, %@, %@, 価格, %@, 変わらず. \n",
						speechIndex, code, [item name], price];
			} else {
				line = [NSString stringWithFormat:@"Number%d, %@, %@, Value, %@, Unchanged. \n",
						speechIndex, code, [item name], price];
			}
		} else if ([item raise] == INFINITY) {
			if (isJp == YES) {
				line = [NSString stringWithFormat:@"ナンバー%d, %@, %@, 価格, %@, 新規銘柄. \n",
						speechIndex, code, [item name], price];
			} else {
				line = [NSString stringWithFormat:@"Number%d, %@, %@, Value, %@, New item. \n",
						speechIndex, code, [item name], price];
			}
		} else {
			if (isJp == YES) {
				if ([[item diff] hasPrefix:@"-"] == YES) {
					line = [NSString stringWithFormat:@"ナンバー%d, %@, %@, 価格 %@, %@, マイナス %0.2f パーセント. \n",
							speechIndex, code, [item name], price,
							[[item diff] stringByReplacingOccurrencesOfString:@"-" withString:@"マイナス "],
							-[item raise]*100];
				} else {
					line = [NSString stringWithFormat:@"ナンバー%d, %@, %@, 価格 %@, %@, プラス %0.2f パーセント. \n",
							speechIndex, code, [item name], price, [[item diff] stringByReplacingOccurrencesOfString:@"+" withString:@"プラス "],
							[item raise]*100];
				}
			} else {
				if ([[item diff] hasPrefix:@"-"] == YES) {
					line = [NSString stringWithFormat:@"Number%d, %@, %@, Value, %@, %@, %0.2f Percent. \n",
							speechIndex, code, [item name], price, [item diff], [item raise]*100];
				} else {
					line = [NSString stringWithFormat:@"Number%d, %@, %@, Value, %@, %@, +%0.2f Percent. \n",
							speechIndex, code, [item name], price, [item diff], [item raise]*100];
				}
			}
            /*
            if (isJp == YES) {
				if ([[item diff] hasPrefix:@"-"] == YES) {
					line = [NSString stringWithFormat:@"ナンバー%d, %@, %@, 価格 %@, 下落, %@, マイナス %0.2f パーセント. \n",
							speechIndex, code, [item name], price,
							[[item diff] stringByReplacingOccurrencesOfString:@"-" withString:@"マイナス "],
							-[item raise]*100];
				} else {
					line = [NSString stringWithFormat:@"ナンバー%d, %@, %@, 価格 %@, 上昇, %@, プラス %0.2f パーセント. \n",
							speechIndex, code, [item name], price, [[item diff] stringByReplacingOccurrencesOfString:@"+" withString:@"プラス "],
							[item raise]*100];
				}
			} else {
				if ([[item diff] hasPrefix:@"-"] == YES) {
					line = [NSString stringWithFormat:@"Number%d, %@, %@, Value, %@, Fell, %@, %0.2f Percent. \n",
							speechIndex, code, [item name], price, [item diff], [item raise]*100];
				} else {
					line = [NSString stringWithFormat:@"Number%d, %@, %@, Value, %@, Rose, %@, +%0.2f Percent. \n",
							speechIndex, code, [item name], price, [item diff], [item raise]*100];
				}
			}
            */
		}
		[price release];
		[text appendString:line];
		[code release];
        // Select row of current item
        long row = [items indexOfObject:item];
		NSIndexSet* ixset = [NSIndexSet indexSetWithIndex:row];
		[infoTableView selectRowIndexes:ixset byExtendingSelection:NO];
		[infoTableView scrollRowToVisible:row];
        if (speechText != nil) {
            [speechText release];
        }
        speechText = [[NSString stringWithFormat:@"%@",text] retain];
        [text release];
        if ([speechText isEqualToString:@""] == YES) {
            return -1;
        }
        NSLog(@"Speech:\n%@", speechText);
        [speechSynth setVoice:speechVoice];
        [speechSynth setRate:speechSpeed];
        [speechSynth startSpeakingString:speechText];
        return 0;
	}
    [text release];
    return -1;
}

- (void)setFontColor:(NSColor*)color
{
	NSTableColumn *column = nil;
	NSLog(@"setFontColor");
	
	// set font color of tableView
	column = [infoTableView  tableColumnWithIdentifier:@"index"];
	[(id)[column dataCell] setTextColor:color];
	column = [infoTableView  tableColumnWithIdentifier:@"code"];
	[(id)[column dataCell] setTextColor:color];
	column = [infoTableView  tableColumnWithIdentifier:@"item"];
	[(id)[column dataCell] setTextColor:color];
	column = [infoTableView  tableColumnWithIdentifier:@"price"];
	[(id)[column dataCell] setTextColor:color];
	column = [infoTableView  tableColumnWithIdentifier:@"differ"];
	[(id)[column dataCell] setTextColor:color];
	column = [infoTableView  tableColumnWithIdentifier:@"raise"];
	[(id)[column dataCell] setTextColor:color];
	[infoTableView reloadData];
}

#pragma mark Localize

- (void) localizeView
{
	NSLog(@"localizeView");
	NSTableColumn *column = nil;
	NSString* lang = NSLocalizedString(@"LANG",@"English");
	NSLog(@"localizeView: %@", lang);
	if ([lang isEqualToString:@"Japanese"]) {
		column = [infoTableView  tableColumnWithIdentifier:@"code"];
		[[column headerCell] setStringValue:@"コード"];
		column = [infoTableView  tableColumnWithIdentifier:@"item"];
		[[column headerCell] setStringValue:@"銘柄"];
		column = [infoTableView  tableColumnWithIdentifier:@"price"];
		[[column headerCell] setStringValue:@"価格"];
		column = [infoTableView  tableColumnWithIdentifier:@"differ"];
		[[column headerCell] setStringValue:@"値幅"];
		column = [infoTableView  tableColumnWithIdentifier:@"raise"];
		[[column headerCell] setStringValue:@"騰落率"];
	}
}

@synthesize		speeching;
@synthesize		items;
@synthesize		title;
@synthesize		priceList;
@synthesize		infoPanel;
@synthesize		infoView;
@synthesize		infoTableView;
@synthesize		infoScrollView;
@synthesize		infoField;
@end
