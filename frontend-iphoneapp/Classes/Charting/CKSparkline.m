#import "CKSparkline.h"


#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)


@implementation CKSparkline

@synthesize selected;
@synthesize lineColor;
@synthesize highlightedLineColor;
@synthesize lineWidth;
@synthesize data, scaleData;
@synthesize computedData, computedScale;
@synthesize page;
@synthesize minimum,maximum;
@synthesize highResData;    //changes data label if highres data
@synthesize chartDays, timeZone,timeFraction;
@synthesize plannedOpenTimeAdjusted,plannedMidTimeAdjusted,plannedCloseTimeAdjusted;

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
		[self initializeDefaults];
    }
	
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
		[self initializeDefaults];
    }
	
    return self;
}


- (void)initializeDefaults
{
	self.selected = NO;
	self.backgroundColor = [UIColor clearColor];
	self.lineColor = [UIColor colorWithWhite:0.65 alpha:1.0];
	self.highlightedLineColor = [UIColor whiteColor];
	self.lineWidth = 0.8;
}


- (void)setSelected:(BOOL)isSelected
{
	selected = isSelected;	
	[self setNeedsDisplay];
}


- (void)setData:(NSArray *)newData
{
    //NSLog(@"Graph %d, Scale Data: %@",page,scaleData);
	
    CGFloat max = 0.0;
	CGFloat min = FLT_MAX;

	NSMutableArray *mutableComputedData = [[NSMutableArray alloc] initWithCapacity:[newData count]];

	for (NSNumber *dataValue in newData) {
		min = MIN([dataValue floatValue], min);
		max = MAX([dataValue floatValue], max);
        self.minimum = min;
        self.maximum = max;
	}
	
	for (NSNumber *dataValue in newData) {
		NSNumber *value = [[NSNumber alloc] initWithFloat:([dataValue floatValue] - min) / (max - min)];
		[mutableComputedData addObject:value];
		[value release];
	}
	
	[computedData release];	
	computedData = mutableComputedData;
    computedScale = [[NSMutableArray alloc] initWithArray:scaleData];
    
    
	[data release];
	data = [newData retain];
	
	[self setNeedsDisplay];
}


- (void)drawRect:(CGRect)rect
{

    if ([self.computedData count] < 1)
		return;

    int topMargin = 10;
    int heightoffset = 30;      //Add this many units of base
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGRect lineRect = CGRectInset(rect, self.lineWidth / 2, self.lineWidth/2);
	CGFloat minX = CGRectGetMinX(lineRect)-1;
	CGFloat maxX = CGRectGetMaxX(lineRect)+1;
    if (chartDays ==1) NSLog(@"Time Fraction (timeFraction): %f",self.timeFraction);
    if (chartDays ==1) maxX = maxX * self.timeFraction;
    
	CGFloat minY = CGRectGetMinY(lineRect)+topMargin;
	CGFloat maxY = CGRectGetMaxY(lineRect);
	
    CGContextSaveGState(context);   //save clean state
    
	CGColorRef strokeColor = [(self.selected ? self.highlightedLineColor : self.lineColor) CGColor];
	CGContextSetStrokeColorWithColor(context, strokeColor);
	CGContextSetLineWidth(context, self.lineWidth);

	CGContextBeginPath(context);
    
    UIBezierPath* beizerPath2 = [UIBezierPath bezierPath];
    
    [beizerPath2 moveToPoint:CGPointMake(minX, maxY-heightoffset)];
    [beizerPath2 addLineToPoint:CGPointMake(minX, maxY-heightoffset - (maxY-heightoffset - minY) * [[computedData objectAtIndex:0] floatValue])]; 
    [beizerPath2 moveToPoint:CGPointMake(minX, maxY-heightoffset - (maxY-heightoffset - minY) * [[computedData objectAtIndex:0] floatValue])];

    NSMutableString *datastring = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"Graph %d, Graph Data: ",page] ];
	for (int i = 0; i < [self.computedData count]; i++) {
        [beizerPath2 addLineToPoint:CGPointMake(minX + (maxX - minX) * ((CGFloat)i / ([self.computedData count] - 1)), maxY-heightoffset - (maxY-heightoffset - minY) * [[self.computedData objectAtIndex:i] floatValue])];
        [datastring appendString:[self.data objectAtIndex:i] ];
        [datastring appendString:@", "];       
        
	}
    //NSLog(@"%@",datastring);
    //NSLog(@"Graph %d, Min: %f, Max: %f",page,self.minimum, self.maximum );
    
    [beizerPath2 addLineToPoint:CGPointMake(maxX, maxY)];               //bottom on RHS   
    [beizerPath2 addLineToPoint:CGPointMake(minX, maxY)];    
    [beizerPath2 addLineToPoint:CGPointMake(minX, maxY-heightoffset)];  //back to start
    
    beizerPath2.lineWidth = 0.25;
    //CGContextSetShadow(context, CGSizeMake(-2, 2), 3);  //shadow
    [[UIColor colorWithRed:0.341 green:0.486 blue:0.584 alpha:1] setFill]; 
    [[UIColor colorWithRed:1 green:1 blue:1 alpha:0.7] setStroke]; 
    [beizerPath2 fill];
    [beizerPath2 stroke];
    
    
    //------------------------------------
    //Draw Scale
    CGContextRestoreGState(context);    //REstore clean state
    //NSLog(@"Scale Data 2: %@",computedScale);
    [[UIColor colorWithRed:1 green:1 blue:1 alpha:1] setFill];      //set scale text color
    
    //Set Scale Min/MAx
    float interval = (maxY-minY-heightoffset);
    float divisions = 3;
    float div_height = interval/divisions; 
    float yincrement = (self.maximum - self.minimum) /divisions;

    //NSLog(@"Graph Debug: interval %f, div_height %f ,divisions: %f",interval, div_height,divisions);

    //Y Axis Scale Labels
    for (int i=0; i<=divisions ; i++)
    {
        int y = minY+(div_height)*i;
        CGRect textFrame = CGRectMake(CGRectGetMaxX(lineRect)-48,(i==0) ? y-10 : y-15,45,25); //Frame for Y Axis Text Labels
        NSString *text = [NSString stringWithFormat:@"%.2f",self.maximum - i*yincrement];
       [text drawInRect:textFrame withFont:[[UIFont fontWithName:@"Avenir-Heavy" size:12] retain] lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentRight];


		//Y Grid Lines
        int gridlinesEnabled = 1;
        if (gridlinesEnabled==1) {
            CGContextSetLineWidth(context, 1);
            CGContextSetRGBStrokeColor(context, 0.4f, 0.4f, 0.4f, 0.1f);
            CGContextMoveToPoint(context, 1, (i==0) ? y+5 : y);  
            CGContextAddLineToPoint(context, self.frame.size.width-1, (i==0) ? y+5 : y);            //top row, move down slightly
            CGContextStrokePath(context);
        }
        
    }
    
    
    //X Axis Scale Labels
    
    //background layer (blue box)
    CGContextSetLineWidth(context, 0.5);              
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:0. green:0 blue:0 alpha:1].CGColor);    //stroke of x scale
    CGRect rectangle = CGRectMake(0,CGRectGetMaxY(lineRect)-17,CGRectGetMaxX(lineRect)+1,17);  //dimensions of box
    CGContextAddRect(context, rectangle);
    CGContextStrokePath(context);

    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:(66/255.0f) green:(95/255.0f) blue:(116/255.0f) alpha:1].CGColor);    //bg color for box
    CGContextFillRect(context, rectangle);

    
    
    float margin = 5;   //This is the margin from the edge of the view to the graph line
    float div_width = ((CGRectGetMaxX(lineRect)-2*margin)/2)-29;    //width between text

    [[UIColor colorWithRed:1 green:1 blue:1 alpha:1] setFill];      //set scale text color
    

    
    //X Axis Labels (Only uses 3)
    int midDateCount = ([computedScale count]-1)/2;
    //NSLog(@"Graph Data: midDateCount : %d, computedScale: %@",midDateCount,computedScale);
    for (int i=0; i<=2; i++)
    {
        //Date Labels
        //NSString *x_label = [NSString stringWithFormat:@"2%d/02/2012",i];
        //NSLog(@"Scale- First Date %@",[computedScale objectAtIndex:0]);
        //NSLog(@"Scale- Mid   Date %@",[computedScale objectAtIndex:midDateCount]);       
        //NSLog(@"Scale- Last  Date %@",[computedScale objectAtIndex:[computedScale count]-1]);

        CGRect textFrame = CGRectMake(margin-5+i*div_width+3, self.frame.size.height-17,100,20);
        
        //DateFormatter for Dates
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        
        if (chartDays == 5 ) {
            [formatter setDateFormat: @"dd MMM"];
            if (i == 0 ) {
                NSString *x_label = [formatter stringFromDate:[computedScale objectAtIndex:0]];
                [x_label drawInRect:textFrame withFont:[[UIFont fontWithName:@"Avenir-Heavy" size:12] retain] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentLeft];   
  
            } else if (i == 1) {
                NSString *x_label = [formatter stringFromDate:[computedScale objectAtIndex:midDateCount]];
                    [x_label drawInRect:CGRectMake(0, self.frame.size.height-17,self.frame.size.width,self.frame.size.height) withFont:[[UIFont fontWithName:@"Avenir-Heavy" size:12] retain] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
                
            }else if (i == 2) {
                NSString *x_label = [formatter stringFromDate:[computedScale objectAtIndex:[computedScale count]-1]];

                    CGRect textFrame = CGRectMake(self.frame.size.width-103, self.frame.size.height-17,100,20);
                    [x_label drawInRect:textFrame withFont:[[UIFont fontWithName:@"Avenir-Heavy" size:12] retain] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentRight];


                
            } 
        } else if (chartDays == 1 ) {
            //NSLog(@"GMT Offset for Stock: %@",self.timeZone);
            [formatter setDateFormat: @"HH:mm"];
            NSTimeZone *timeZoneAbr = [NSTimeZone timeZoneForSecondsFromGMT:[self.timeZone intValue]]; //East Coast Oz is "gmtoffset:36000"
            [formatter setTimeZone:timeZoneAbr];

            
            if (i == 0 ) {
                //NSString *x_label = @"9am";
                //NSLog(@"should be: plannedMidTimeAdjusted: %@",plannedOpenTimeAdjusted);
                //NSString *x_label = [formatter stringFromDate:[computedScale objectAtIndex:0]];
                NSString *x_label = plannedOpenTimeAdjusted;
                [x_label drawInRect:textFrame withFont:[[UIFont fontWithName:@"Avenir-Heavy" size:12] retain] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentLeft];

            } else if (i== 1) {
                //NSString *x_label = @"12pm";
                //NSLog(@"should be: plannedMidTimeAdjusted: %@",plannedMidTimeAdjusted);
                //NSString *x_label = [formatter stringFromDate:[computedScale objectAtIndex:midDateCount]];
                NSString *x_label = plannedMidTimeAdjusted;
                    [x_label drawInRect:CGRectMake(0, self.frame.size.height-17,self.frame.size.width,self.frame.size.height) withFont:[[UIFont fontWithName:@"Avenir-Heavy" size:12] retain] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
               
                
            }else if (i== 2) {
                //NSString *x_label = @"4pm";
                //NSLog(@"should be: plannedCloseTimeAdjusted: %@",plannedCloseTimeAdjusted);
                //NSString *x_label = [formatter stringFromDate:[computedScale objectAtIndex:[computedScale count]-1]];
                NSString *x_label = plannedCloseTimeAdjusted;
                CGRect textFrame = CGRectMake(self.frame.size.width-103, self.frame.size.height-17,100,20);
                
                    [x_label drawInRect:textFrame withFont:[[UIFont fontWithName:@"Avenir-Heavy" size:12] retain] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentRight];
              
                
                
            } 
        } else {
            if (i == 0 ) {
                NSString *x_label = [computedScale objectAtIndex:0];
                
                    [x_label drawInRect:textFrame withFont:[[UIFont fontWithName:@"Avenir-Heavy" size:12] retain] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentLeft];
                  
                
                
            } else if (i== 1) {
                NSString *x_label = [computedScale objectAtIndex:midDateCount];
                
                 [x_label drawInRect:CGRectMake(0, self.frame.size.height-17,self.frame.size.width,self.frame.size.height) withFont:[[UIFont fontWithName:@"Avenir-Heavy" size:12] retain] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];   
                
                
            }else if (i== 2) {
                NSString *x_label = [computedScale objectAtIndex:[computedScale count]-1];
                
                    CGRect textFrame = CGRectMake(self.frame.size.width-103, self.frame.size.height-17,100,20);
                    [x_label drawInRect:textFrame withFont:[[UIFont fontWithName:@"Avenir-Heavy" size:12] retain] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentRight];
                
                
            } 
        }
        

    }
    


}


- (void)dealloc
{
	[data release];
	[computedData release];	
	[lineColor release];
	[highlightedLineColor release];
	
    [super dealloc];
}


@end
