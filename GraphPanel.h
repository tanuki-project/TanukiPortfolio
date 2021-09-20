//
//  GraphPanel.h
//  TanukiPortfolio
//
//  Created by Takahiro Sayama on 2013/04/27.
//  Copyright (c) 2013年 tanuki-project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GraphView.h"

@class	GraphView;
@class  MyDocument;

@interface GraphPanel : NSWindowController
{
    Boolean                     showGraph;
    NSString                    *country;
    NSString                    *symbol;
    NSInteger                   term;
    MyDocument                  *parentDoc;
	IBOutlet NSPanel            *graphPanel;
    IBOutlet GraphView          *graphView;
    IBOutlet NSTextField        *graphText;
    IBOutlet NSSegmentedControl *segmantTerm;
}

- (id) init;
- (void) setGraphString:(NSString*)string;
- (IBAction)termChanged:(id)sender;

@property	(readwrite)         Boolean     showGraph;
@property	(readwrite,copy)	NSString*	country;
@property	(readwrite,copy)	NSString*	symbol;
@property	(readwrite)         NSInteger   term;
@property	(readwrite,retain)	NSPanel     *graphPanel;
@property	(readwrite,retain)	GraphView   *graphView;
@property	(readwrite,retain)	NSTextField *graphText;
@property   (readwrite,assign)  MyDocument  *parentDoc;

@end
