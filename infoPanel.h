//
//  infoPanel.h
//  tPortfolio
//
//  Created by Takahiro Sayama on 11/01/15.
//  Copyright 2011 tanuki-project. All rights reserved.
//

#import		<Cocoa/Cocoa.h>

@interface infoItem : NSObject {
	int				index;
	NSString*		name;
	NSString*		code;
	NSString*		price;
	NSString*		diff;
	float			raise;
	NSString*		currency;
}

- (id) init;

@property	(readwrite)			int				index;
@property	(readwrite,copy)	NSString*		name;
@property	(readwrite,copy)	NSString*		code;
@property	(readwrite,copy)	NSString*		price;
@property	(readwrite,copy)	NSString*		diff;
@property	(readwrite,copy)	NSString*		currency;
@property	(readwrite)			float			raise;
@end


@interface infoPanel : NSWindowController <NSSpeechSynthesizerDelegate> {
	NSMutableArray				*items;
	NSMutableString				*priceList;
	NSString					*title;
	BOOL						speeching;
	NSString					*speechText;
	NSSpeechSynthesizer			*speechSynth;
    int                         speechIndex;
	IBOutlet NSPanel			*infoPanel;
	IBOutlet NSTextView			*infoView;
	IBOutlet NSTextField		*infoField;
	IBOutlet NSTableView		*infoTableView;
	IBOutlet NSScrollView		*infoScrollView;
	IBOutlet NSArrayController	*itemController;
	IBOutlet NSButton			*speechButton;
}

- (IBAction)controlSpeech:(id)sender;
- (IBAction)startSpeech:(id)sender;
- (IBAction)stopSpeech:(id)sender;
- (int)speechItem;
- (void)setItem :(NSString*)name :(NSString*)code :(NSString*)price :(NSString*)diff :(float)raise :(NSString*)country;
- (void)rearrangePanel;
- (void)sortItems;
- (void)tableView:(NSTableView*)tableView sortDescriptorsDidChange:(NSArray*)oldDescriptors;
- (void)setFontColor:(NSColor*)color;
- (void)localizeView;

@property	(readwrite)			BOOL				speeching;
@property	(readwrite,retain)	NSMutableArray*		items;
@property	(readwrite,copy)	NSMutableString*	priceList;
@property	(readwrite,copy)	NSString*			title;
@property	(readwrite,retain)	NSPanel*			infoPanel;
@property	(readwrite,retain)	NSTextView*			infoView;
@property	(readwrite,retain)	NSTableView*		infoTableView;
@property	(readwrite,retain)	NSScrollView*		infoScrollView;
@property	(readwrite,retain)	NSTextField*		infoField;
@end
