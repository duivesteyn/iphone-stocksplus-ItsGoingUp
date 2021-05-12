/**
 * Copyright (c) 2011 Muh Hon Cheng
 * Created by honcheng on 28/4/11.
 * 
 * Permission is hereby granted, free of charge, to any person obtaining 
 * a copy of this software and associated documentation files (the 
 * "Software"), to deal in the Software without restriction, including 
 * without limitation the rights to use, copy, modify, merge, publish, 
 * distribute, sublicense, and/or sell copies of the Software, and to 
 * permit persons to whom the Software is furnished to do so, subject 
 * to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be 
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT 
 * WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR 
 * PURPOSE AND NONINFRINGEMENT. IN NO EVENT 
 * SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR 
 * IN CONNECTION WITH THE SOFTWARE OR 
 * THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * 
 * @author 		Muh Hon Cheng <honcheng@gmail.com>
 * @copyright	2011	Muh Hon Cheng
 * @version
 * 
 */

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)


#import "PCLineChartView.h"
#import <QuartzCore/QuartzCore.h>
#import "MyViewController.h"

@implementation PCLineChartViewComponent
@synthesize title, points, colour, shouldLabelValues,page;


-(void) dealloc
{
    [points release];
    [colour release];
    [title release];
    [page release];
    [super dealloc];
}
@end

@implementation PCLineChartView
@synthesize components;
@synthesize interval, minValue, maxValue;
@synthesize xLabels;
@synthesize yLabelFont, xLabelFont, valueLabelFont, legendFont;
@synthesize autoscaleYAxis, numYIntervals;


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        NSLog(@"Called initWithFrame");
        [self setBackgroundColor:[UIColor clearColor]];
        interval = 20;
		maxValue = 100;
		//minValue = 0;
        numYIntervals = 4;
    
        yLabelFont = [[UIFont fontWithName:@"Avenir" size:12.0] retain];
        xLabelFont = [[UIFont fontWithName:@"Avenir" size:12.0] retain];
        valueLabelFont = [[UIFont fontWithName:@"Avenir" size:10] retain];
             
        
        xArray = [[NSMutableArray alloc] init];
        yArray = [[NSMutableArray alloc] init];
		
    }
    return self;
}


- (void)drawRect:(CGRect)rect
{   
    
   // NSLog(@"Called drawRect");
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(ctx);
    CGContextSetRGBFillColor(ctx, 1.0f, 1.0f, 1.0f, 1.0f);  //X and Y Axis Text Color
    
    int n_div;
    int power;
    float scale_min, scale_max, div_height;
    float top_margin = 38;
    float bottom_margin = 25;
	float x_label_height = 20;
  
    //Setup Scale
    autoscaleYAxis = 0;
    if (autoscaleYAxis) {
        scale_min = 0.0;
        power = floor(log10(maxValue/5)); 
        float increment = maxValue / (5 * pow(10,power));
        increment = (increment <= 5) ? ceil(increment) : 10;
        increment = increment * pow(10,power);
        scale_max = 5 * increment;
        self.interval = scale_max / numYIntervals;
    } else {
        scale_min = 30;
        scale_max = 50;
    }
    n_div = (scale_max-scale_min)/self.interval + 1;
    div_height = (self.frame.size.height-top_margin-bottom_margin-x_label_height)/(n_div-1);
    
    for (int i=0; i<n_div; i++)
    {
        float y_axis = scale_max - i*self.interval;
        int y = top_margin + div_height*i;
        CGRect textFrame = CGRectMake(320-25-2,y-8,25,20); //Frame for Y Axis Text Labels
        NSString *formatString = [NSString stringWithFormat:@"%%.%if", (power < 0) ? -power : 0];
        NSString *text = [NSString stringWithFormat:formatString, y_axis];
        [text drawInRect:textFrame withFont:yLabelFont lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentRight]; //Y Axis Text Labels
		
		// These are "grid" lines
        int gridlinesEnabled = 0;
        if (gridlinesEnabled==1) {
            CGContextSetLineWidth(ctx, 1);
            CGContextSetRGBStrokeColor(ctx, 0.4f, 0.4f, 0.4f, 0.1f);
            CGContextMoveToPoint(ctx, 30, y);
            CGContextAddLineToPoint(ctx, self.frame.size.width-30, y);
            CGContextStrokePath(ctx);
        }

    }
    
    float margin = 0;   //This is the margin from the edge of the view to the graph line
    float div_width = (self.frame.size.width-2*margin)/([self.xLabels count]-1);
    for (int i=0; i<[self.xLabels count]; i++)
    {
        int x = margin + div_width*i;
        NSString *x_label = [NSString stringWithFormat:@"%@", [self.xLabels objectAtIndex:i]];
        CGRect textFrame = CGRectMake(x-100, self.frame.size.height-x_label_height,200,x_label_height);
        [x_label drawInRect:textFrame
				   withFont:xLabelFont 
			  lineBreakMode:UILineBreakModeWordWrap 
				  alignment:UITextAlignmentCenter];
    }
    
	//CGColorRef shadowColor = [[UIColor lightGrayColor] CGColor];
    //CGContextSetShadowWithColor(ctx, CGSizeMake(0,-1), 1, shadowColor);

    for (PCLineChartViewComponent *component in self.components)
    {

        
	    NSLog(@"In page: %@",component.page);	

		for (int x_axis_index=0; x_axis_index<[component.points count]; x_axis_index++)
        {
            
            //loop through X's
            id object = [component.points objectAtIndex:x_axis_index];
			
            if (object!=[NSNull null] && object)
            {
                float value = [object floatValue];
				
				//CGContextSetStrokeColorWithColor(ctx, [component.colour CGColor]);
               // CGContextSetLineWidth(ctx, 1);
                
                int x = margin + div_width*x_axis_index;
                int y = top_margin + (scale_max-value)/self.interval*div_height;
                NSLog(@"x,y = %d,%d",x,y);
                [xArray addObject:[NSNumber numberWithInt:x]];
                [yArray addObject:[NSNumber numberWithInt:y]];
				//CGContextSetFillColorWithColor(ctx, [component.colour CGColor]);
            }
            
        }

        
    }

}

- (void)dealloc
{
    [components release];
    [xLabels release];
	self.yLabelFont = self.xLabelFont = self.valueLabelFont = self.legendFont = nil;
    [super dealloc];
}

@end
