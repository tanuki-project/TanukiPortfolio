//
//  GraphView.h
//  TanukiPortfolio
//
//  Created by Takahiro Sayama on 2013/04/27.
//  Copyright (c) 2013年 tanuki-project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GraphPanel.h"

#define GRAPH_BASE_POINT_X  20
#define GRAPH_BASE_POINT_Y  30
#define GRAPH_WIDTH         600
#define GRAPH_HIGHT         360
#define GRAPH_BAR_HIGHT     300
#define GRAPH_BAR_COUNT     25
#define GRAPH_BAR_WIDTH     12
#define GRAPH_BAR_OFFSET    24
#define GRAPH_BAR_CHINK     6

@class	GraphPanel;

@interface graphItem : NSObject {
    NSInteger       index;
	double			value;  // 評価額
	double			rise;   // 騰落率
    NSDate          *date;  // 日付
    NSBezierPath    *bar;
    NSBezierPath    *scale;
}

@property	(readwrite)			NSInteger       index;
@property	(readwrite)			double          value;
@property	(readwrite)			double          rise;
@property	(readwrite,copy)	NSDate*			date;
@property	(readwrite,copy)	NSBezierPath    *bar;
@property	(readwrite,copy)	NSBezierPath    *scale;

@end

@interface GraphView : NSView
{
    double          max;
    NSInteger       unit;
    NSString        *currency;
    NSInteger       activeIndex;
    NSBezierPath    *baseLine;
    NSBezierPath    *scaleLine;
    NSBezierPath    *rightLine;
    NSMutableArray  *items;
    GraphPanel      *parent;
}

- (void)setValueAtIndex:(double)value :(NSInteger)index;
- (void)setPerformanceAtIndex:(double)rise :(NSInteger)index;
- (void)setDateAtIndex:(NSDate*)date :(NSInteger)index;
- (void)buildBar;

@property	(readwrite)			double          max;
@property	(readwrite)			NSInteger       unit;
@property	(readwrite)			NSInteger       activeIndex;
@property	(readwrite,retain)  GraphPanel      *parent;

@end
