//
//  GraphPanel.m
//  TanukiPortfolio
//
//  Created by Takahiro Sayama on 2013/04/27.
//  Copyright (c) 2013年 tanuki-project. All rights reserved.
//

#import "GraphPanel.h"
#import "MyDocument.h"

@interface GraphPanel ()

@end

@implementation GraphPanel

- (id)init
{
	NSLog(@"init GraphPanel");
    self = [super initWithWindowNibName:@"GraphPanel"];
	if (self == nil) {
		return nil;
	}
    showGraph = NO;
    term = 1;
    country = [[NSString alloc] initWithString:@""];
    symbol = [[NSString alloc] initWithString:@""];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(graphClose:)
               name:NSWindowWillCloseNotification
             object:[self window]];
    return self;
}

/*
- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}
*/

- (void)dealloc
{
    //NSLog(@"dealloc: graphItem");
    if (country) {
        [country release];
    }
    if (symbol) {
        [symbol release];
    }
    [super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [graphView setParent:self];
    if ([segmantTerm selectedSegment] == 0) {
        term = 1;
    } else {
        term = 3;
    }
}

- (void)graphClose:(NSNotification *)notification
{
    NSLog(@"close: graphPanel");
    showGraph = NO;
}

- (void)setGraphString:(NSString*)string
{
    [graphText setStringValue:string];
}

- (IBAction)termChanged:(id)sender {
    NSLog(@"termChanged: %ld", (long)[segmantTerm selectedSegment]);
    if ([segmantTerm selectedSegment] == 0) {
        term = 1;
    } else {
        term = 3;
    }
    [graphView setActiveIndex:GRAPH_BAR_COUNT - 1];
    [parentDoc buildGraph:country];
}

@synthesize showGraph;
@synthesize country;
@synthesize symbol;
@synthesize term;
@synthesize graphPanel;
@synthesize graphView;
@synthesize graphText;
@synthesize parentDoc;

@end
