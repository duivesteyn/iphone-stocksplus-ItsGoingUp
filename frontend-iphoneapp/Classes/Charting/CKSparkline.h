#import <UIKit/UIKit.h>


@interface CKSparkline : UIView {
	BOOL selected;
	UIColor *lineColor;
	UIColor *highlightedLineColor;
	NSArray *data;
    NSArray *scaleData;
	NSArray *computedData;
    NSArray *computedScale; //de addon, keeping original terminology fort simplicity
    NSString *plannedOpenTimeAdjusted;
    NSString *plannedMidTimeAdjusted;
    NSString *plannedCloseTimeAdjusted;
	CGFloat lineWidth;
    int page;
    int highResData;
    NSMutableString *timeZone;
    float timeFraction;
    int chartDays;
    float minimum;
    float maximum;
}


@property (readonly) BOOL selected;
@property (nonatomic, retain) UIColor *lineColor;
@property (nonatomic, retain) UIColor *highlightedLineColor;
@property (nonatomic) CGFloat lineWidth;
@property (readonly) NSArray *data;
@property (nonatomic, retain) NSArray *scaleData;
@property (readonly) NSArray *computedData;
@property (readonly) NSArray *computedScale;
@property (nonatomic) int page;
@property (nonatomic) int highResData;
@property (nonatomic, retain) NSString *plannedOpenTimeAdjusted;
@property (nonatomic, retain) NSString *plannedCloseTimeAdjusted;
@property (nonatomic, retain) NSString *plannedMidTimeAdjusted;
@property (nonatomic, retain) NSMutableString *timeZone;
@property (nonatomic) float timeFraction;
@property (nonatomic) int chartDays;
@property (nonatomic) float minimum;
@property (nonatomic) float maximum;

- (void)initializeDefaults;
- (void)setSelected:(BOOL)isSelected;
- (void)setData:(NSArray *)newData;

@end
