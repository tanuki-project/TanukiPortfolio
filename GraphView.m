//
//  GraphView.m
//  TanukiPortfolio
//
//  Created by Takahiro Sayama on 2013/04/27.
//  Copyright (c) 2013年 tanuki-project. All rights reserved.
//

#import "GraphView.h"
#import "GraphPanel.h"

@implementation graphItem

- (id)init
{
    //NSLog(@"init: graphItem");
    self = [super init];
    if (self) {
        index = 0;
        value = 0;
        bar = [[NSBezierPath alloc] init];
        [bar setLineWidth:2.0];
        scale = [[NSBezierPath alloc] init];
        [scale setLineWidth:1.0];
    }
	return self;
}

- (void)dealloc
{
    //NSLog(@"dealloc: graphItem");
    if (bar) {
        [bar release];
    }
    if (scale) {
        [scale release];
    }
    [super dealloc];
}

@synthesize index;
@synthesize value;
@synthesize rise;
@synthesize date;
@synthesize bar;
@synthesize scale;

@end

@implementation GraphView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        NSPoint p;
        max = GRAPH_BAR_HIGHT;
        unit = GRAPH_BAR_HIGHT/10;
        //strValue = [[NSString alloc] init];
        activeIndex = GRAPH_BAR_COUNT - 1;
        baseLine = [[NSBezierPath alloc] init];
        scaleLine = [[NSBezierPath alloc] init];
        rightLine = [[NSBezierPath alloc] init];
        [baseLine setLineWidth:1.0];
        [scaleLine setLineWidth:1.0];
        [rightLine setLineWidth:1.0];
        p = [self graphPoint:-0.5:-0.5];
        [baseLine moveToPoint:p];
        [scaleLine moveToPoint:p];
        p = [self graphPoint:GRAPH_WIDTH+0.5:-0.5];
        [baseLine lineToPoint:p];
        [baseLine closePath];
        p = [self graphPoint:-0.5:GRAPH_HIGHT+0.5];
        [scaleLine lineToPoint:p];
        [scaleLine closePath];
        p = [self graphPoint:GRAPH_WIDTH+0.5:-0.5];
        [rightLine moveToPoint:p];
        p = [self graphPoint:GRAPH_WIDTH+0.5:GRAPH_HIGHT+0.5];
        [rightLine lineToPoint:p];
        [rightLine closePath];
        items = [[NSMutableArray alloc] init];
        for (int i = 0; i < GRAPH_BAR_COUNT; i++) {
            graphItem *item = [[graphItem alloc] init];
            [item setIndex:i];
            [item setValue:0];
            [item setDate:[[NSDate alloc] init]];
            [items addObject:item];
            [item release];
        }
        [self buildBar];
    }
    
    return self;
}

- (void)mouseDown:(NSEvent *)event
{
    NSPoint p = [event locationInWindow];
    NSLog(@"Mouse Down (%f,%f)", p.x, p.y);
    if (p.x < GRAPH_BASE_POINT_X || p.y < GRAPH_BASE_POINT_Y) {
        return;
    }
    if (p.x > (GRAPH_BASE_POINT_X+GRAPH_WIDTH) ||
        p.y > (GRAPH_BASE_POINT_Y+GRAPH_HIGHT)) {
        return;
    }
    NSInteger index = (p.x-GRAPH_BASE_POINT_X)/GRAPH_BAR_OFFSET;
    if (index < GRAPH_BAR_COUNT) {
        activeIndex = index;
        NSLog(@"activeIndex = %ld", (long)index);
        [self setNeedsDisplay:YES];
    }
}

- (void)swipeWithEvent:(NSEvent *)event
{
    NSLog(@"swipeWithEvent:");
}

/*
- (void)keyDown:(NSEvent *)event
{
    NSLog(@"KeyDown %@", event);
}
 */

- (void)drawRect:(NSRect)dirtyRect
{
    NSLog(@"drawRect");
    // Drawing code here.
    
    // Draw base and left/lite scale lines.
    [[NSColor lightGrayColor] set];
    //[[NSColor whiteColor] set];
    [self buildScale];
    [baseLine stroke];
    [scaleLine stroke];
    [rightLine stroke];
    
    // Draw graph items
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    for (graphItem *item in items) {
        NSDateComponents *compo = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit)
                                              fromDate:[item date ]];
        NSInteger month = [compo month];
        NSInteger year = [compo year];
        if (([parent term] == 1 && month == 1) || ([parent term] == 3 && month <= 3)) {
            // draw year string
            NSPoint p = [self graphPoint:[item index]*GRAPH_BAR_OFFSET-GRAPH_BAR_CHINK+2:-30];
            NSString* str = [[NSString alloc] initWithFormat:@"%ld",(long)year];
            //[self drawString:str :p :@{NSForegroundColorAttributeName:[NSColor whiteColor]}];
            [self drawString:str :p :@{NSForegroundColorAttributeName:[NSColor darkGrayColor]}];
            [str release];
        }
        [[NSColor lightGrayColor] set];
        //[[NSColor whiteColor] set];
        [[item scale] stroke];
        if ([item value] == 0) {
            [[NSColor grayColor] set];
        } else {
            [[NSColor lightGrayColor] set];
        }
        [[item bar] fill];
        
        // Draw indicator line
        if (activeIndex == [item index]) {
            //[[NSColor whiteColor] set];
            [[NSColor darkGrayColor] set];
            [[item bar] stroke];
            NSInteger intValue = [item value];
            NSDateComponents *compo = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit)
                                                  fromDate:[item date ]];

            NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
            [formatter setFormat:@"#,##0"];
            [parent setGraphString:[NSString stringWithFormat:@"%ld/%ld/%ld: %@  -  %@ %@ (%0.2f%@)",
                                    (long)[compo year], (long)[compo month], (long)[compo day],
                                    [parent country], [parent symbol],
                                    [formatter stringFromNumber:[NSNumber numberWithDouble:intValue]],
                                    [item rise], @"%"]];
        }
    }
    [calendar release];
}

- (NSPoint)graphPoint:(float)x :(float)y
{
    NSPoint result;
    result.x = x + GRAPH_BASE_POINT_X;
    result.y = y + GRAPH_BASE_POINT_Y;
    //NSLog(@"graphPoint = %f,%f", result.x, result.y);
    return result;
}

- (void)buildScale
{
    NSPoint p, q;
    float y = -0.5;
    float offset = GRAPH_BAR_HIGHT*unit/max;
    if (GRAPH_HIGHT/offset > 10) {
        offset = offset*2;
    } else if (GRAPH_HIGHT/offset < 4) {
        offset = offset/2;
    }
    [scaleLine removeAllPoints];
    p = [self graphPoint:-0.5:-0.5];
    [scaleLine moveToPoint:p];
    for (y = y + offset; y < GRAPH_BASE_POINT_Y + GRAPH_HIGHT; y += offset) {
        //NSLog(@"y = %f", round(y)+1.5);
        p = [self graphPoint:-0.5:round(y)+1.5];
        [scaleLine lineToPoint:p];
        q = [self graphPoint:GRAPH_WIDTH:round(y)+1.5];
        [scaleLine lineToPoint:q];
        [scaleLine lineToPoint:p];
    }
    p = [self graphPoint:-0.5:GRAPH_HIGHT];
    [scaleLine lineToPoint:p];
    //[scaleLine closePath];
}

- (void)buildBar
{
    //NSInteger prev_year = 0;
    //NSInteger prev_month = 0;
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    for (graphItem *item in items) {
        NSDateComponents *compo = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit)
                                              fromDate:[item date]];
        NSPoint p;
        NSInteger month = [compo month];
        double hight = 0;
        if (max == 0) {
            hight = 1;
        } else {
            hight = [item value]*(GRAPH_BAR_HIGHT/max) + 1;
        }
        [[item bar] removeAllPoints];
        [[item bar] setLineWidth:2.0];
        p = [self graphPoint:[item index]*GRAPH_BAR_OFFSET+GRAPH_BAR_CHINK:-0.5];
        [[item bar] moveToPoint:p];
        p = [self graphPoint:[item index]*GRAPH_BAR_OFFSET+GRAPH_BAR_CHINK+GRAPH_BAR_WIDTH:-0.5];
        [[item bar] lineToPoint:p];
        p = [self graphPoint:[item index]*GRAPH_BAR_OFFSET+GRAPH_BAR_CHINK+GRAPH_BAR_WIDTH:hight];
        [[item bar] lineToPoint:p];
        p = [self graphPoint:[item index]*GRAPH_BAR_OFFSET+GRAPH_BAR_CHINK:hight];
        [[item bar] lineToPoint:p];
        [[item bar] closePath];
        [[item scale] removeAllPoints];
        [[item scale] setLineWidth:1.0];
        p = [self graphPoint:([item index]+1)*GRAPH_BAR_OFFSET-0.5:-0.5];
        [[item scale] moveToPoint:p];
        if (month == 12) {
            p = [self graphPoint:([item index]+1)*GRAPH_BAR_OFFSET-0.5:-8.5];
        } else if ((month % 3) == 0) {
            p = [self graphPoint:([item index]+1)*GRAPH_BAR_OFFSET-0.5:-3.5];
        } else {
            p = [self graphPoint:([item index]+1)*GRAPH_BAR_OFFSET-0.5:-1.5];
        }
        [[item scale] lineToPoint:p];
        //NSLog(@"hight = %f bar = %@", hight, [item bar]);
    }
    [calendar release];
    [self setNeedsDisplay:YES];
}

- (void)drawString:(NSString*)msg :(NSPoint)p :(NSDictionary *)attr
{
    NSTextStorage *textStorage = [[NSTextStorage alloc] init];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    NSTextContainer *textContainer = [[NSTextContainer alloc] init];
    [layoutManager addTextContainer:textContainer];
    [textContainer release];
    [textStorage addLayoutManager:layoutManager];
    [layoutManager release];
    //NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:msg attributes:@{NSForegroundColorAttributeName:[NSColor whiteColor]}];
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:msg attributes:attr];
    [textStorage appendAttributedString: attributedString];
    NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
    [layoutManager drawGlyphsForGlyphRange: glyphRange atPoint: p];
    [attributedString release];
    [textStorage release];
}

- (void)setValueAtIndex:(double)value :(NSInteger)index
{
    graphItem *item = [items objectAtIndex:index];
    if (item) {
        [item setValue:value];
    }
}

- (void)setPerformanceAtIndex:(double)rise :(NSInteger)index
{
    graphItem *item = [items objectAtIndex:index];
    if (item) {
        [item setRise:rise];
    }
}

- (void)setDateAtIndex:(NSDate*)date :(NSInteger)index
{
    graphItem *item = [items objectAtIndex:index];
    if (item) {
        [item setDate:date];
    }
}

@synthesize max;
@synthesize unit;
@synthesize activeIndex;
@synthesize parent;

@end
