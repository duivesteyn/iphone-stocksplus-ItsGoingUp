/*
     File: MyViewController.h 
 Abstract: The root view controller for the iPhone design of this app. 
  Version: 1.4 

 Copyright (C) 2010 Apple Inc. All Rights Reserved. 
  
 */

#import <UIKit/UIKit.h>
#import "MTStatusBarOverlay.h"  //Nice overlay text in StatusBar
#import "PCLineChartView.h"
#import "ATMHudDelegate.h"
#import "CKSparkline.h"
#import "Reachability.h"
#import "BSYahooFinance.h"
#import "deStockLookup.h"


@class AppDelegate;
@class SparklineViewerViewController;
@class ATMHud;

@interface MyViewController : UIViewController <ATMHudDelegate,MTStatusBarOverlayDelegate,YFStockDetailsLoaderDelegate>
{
 	AppDelegate	*appDelegate;
    PCLineChartView *lineChartView;
    ATMHud *hud;    //progress HUD View
    CKSparkline *sparkline;
    
    UILabel *pageNumberLabel;
    int pageNumber;
    int notesPosition;
    int notesFirstRun;
    int targetViewPosition; //1=showing 0 = hidden
    int chartDataFromCacheAvailable;
    
    UILabel *numberTitle;
    UIImageView *numberImage;
    

    IBOutlet UIScrollView *stockDataScrollView;     //Scrollview
    IBOutlet UIImageView *headerImageView;
    IBOutlet UIView *graphUIViewInMainPage;     //UIView for Graph
    IBOutlet UIView *stockAndDataViewInMainPage; //Place for below View
    
    IBOutlet UIView *stockAndDataView;   //Parent View for Scrolling Stock Data View and Graph View 
    IBOutlet UIView *stockDataView; //Scrolling Advanced View
    IBOutlet UIView *graphDataView; //Graph View    
    IBOutlet UIView *graphDataBG; //Graph View  
    IBOutlet UIView *notesView; //Notes View    
    IBOutlet UITextView *notesTextArea; //Notes View    
    IBOutlet UIView *stockTargetPriceView; //Notes View
    IBOutlet UIView *chartView; //Chart View
    IBOutlet UIView *notesButtonView; //Chart View
    IBOutlet UIView *stockStatsView; //New 
    IBOutlet UILabel *stockName;
    IBOutlet UILabel *stockTicker;
    IBOutlet UILabel *stockValue;    
    IBOutlet UILabel *stockChange; 
    IBOutlet UILabel *stockTargetPrice;

    IBOutlet UIButton *stockTargetEditButton;


    IBOutlet UIImageView *stockColorTargetBar;
      
    
    NSMutableArray *contentArray;
    NSMutableDictionary *liveDataArray;
    
    //Stock Data View Components
    IBOutlet UILabel *stockOpen;
    IBOutlet UILabel *stockLow;
    IBOutlet UILabel *stockHigh;
    IBOutlet UILabel *stockVolume;
    IBOutlet UILabel *stockVolumeLabel;    
    IBOutlet UILabel *stock52wHigh;
    IBOutlet UILabel *stock52wLow;
    IBOutlet UILabel *stockPE;
    IBOutlet UILabel *stockMktCap;
    IBOutlet UILabel *stockMktCapLabel;     
    IBOutlet UILabel *stockTime;
    IBOutlet UILabel *stockTimeLabel;    
    //StockDataView - Calculated Results
    IBOutlet UILabel *stockHoldValue;
    IBOutlet UILabel *stockHoldValueTitle;
    IBOutlet UILabel *stockValueChange;
    IBOutlet UILabel *stockValueChangeTitle;
    IBOutlet UILabel *stockBuy;
    IBOutlet UILabel *stockBuyTitle;
    
    NSNumberFormatter *numberFormatter;
    NSDecimalNumber *stockValueVar;
    NSDecimalNumber *stockChangeVar;
    
    NSDecimalNumber *stockOpenVar;
    NSDecimalNumber *stockLowVar;
    NSDecimalNumber *stockHighVar;    
    NSDecimalNumber *stockBuyVar;
    NSDecimalNumber *stockHoldValueVar;
    NSDecimalNumber *stockChangeValueVar;
    NSDecimalNumber *stockUnitsVar;
    
    
    //Queue
    NSOperationQueue *operationQueue;
    
    //Notification View
    IBOutlet UILabel *notificationText;
    IBOutlet UISwitch *notificationSwitch;
    IBOutlet UISegmentedControl *notificationAboveBelow;  
    IBOutlet UISegmentedControl *notificationRepeat;
    IBOutlet UITextField *notificationSetTargetPrice;    
       
    //Graph Data Dicts
    NSDictionary  *deStockLookupLoResData;
    NSDictionary  *deStockLookupHighResDataFiveDay;
    NSDictionary  *deStockLookupHighResDataOneDay;
    
    //Graph
    UIBezierPath *beizerPath;
    NSMutableArray *graphDataArrayX;
    NSMutableArray *graphDataArrayY;
    IBOutlet UIButton *buttonChartRange1D;
    IBOutlet UIButton *buttonChartRange5D;
    IBOutlet UIButton *buttonChartRange1M;
    IBOutlet UIButton *buttonChartRange3M;
    IBOutlet UIButton *buttonChartRange6M;
    IBOutlet UIButton *buttonChartRange1Y;   
    
    
    //No Internet VIew
    IBOutlet UIView *noInternetView;
    int noInternetConnection;
    
    //StockSetAnnounce
    NSString *notificationID; 
    NSString *stockTickerNew;
    NSString *stockSetPoint;                             
    NSString *aboveOrBelow;
    NSString *repeatPeriod;
    NSURL *postUrl;
    NSString *post;
    
    int verbose;
}


@property (nonatomic, retain) IBOutlet UILabel *pageNumberLabel;
@property (nonatomic, retain) IBOutlet UILabel *numberTitle;
@property (nonatomic, retain) IBOutlet UIImageView *numberImage;
@property (nonatomic, retain) IBOutlet UIScrollView *stockDataScrollView;
//@property (nonatomic, retain) IBOutlet UIView *graphDataView;
//@property (nonatomic, retain) IBOutlet UIView *stockDataView; //Graph View    
//@property (nonatomic, retain) IBOutlet UIView *notesView; //NOtes View 
@property (nonatomic, retain) IBOutlet UITextView *notesTextArea; //Notes View    
//@property (nonatomic, retain) IBOutlet UIView *stockAndDataViewInMainPage;
//@property (nonatomic, retain) IBOutlet UIView *UIViewstockAndDataView;
@property (nonatomic, retain) NSDecimalNumber *stockValueVar;

//Graph
@property (nonatomic, retain) ATMHud *hud;  //progress hud view
@property (nonatomic, retain) UIBezierPath *beizerPath;
@property (nonatomic, retain) IBOutlet CKSparkline *sparkline;
-(void)getForCachedChartData;
-(void)graphSlicer:(int)days;

NSString* convertValueToStringWithMagnitude(float distance);

- (id)initWithPageNumber:(int)page;
- (IBAction)notesPressed:(id)sender;
- (IBAction)editTargetPressed:(id)sender;
- (IBAction)notificationSwitchToggled:(id)sender;
- (void)updateViewDataFields;
- (void)updateViewTargetBar;

//Updating      
-(void)stopActivityIndicator:(NSNotification *) notification;
-(void)localstopActivityIndicator;
-(void)startActivityIndicator:(NSNotification *) notification;

//Stock Updating
-(void)stockUpdate:(NSNotification *) notification;
-(void)updateStockData;

-(void)notificationDataUpdate;

//No Internet View
-(void)noInternetMode:(NSNotification *) notification;
-(void)hideNoInternetMode:(NSNotification *) notification;
//Graph
-(void)graphLoading;
-(void)hideGraphLoadingHud;
-(void)graphDataLoad;

//Notification Updating
-(IBAction)notificationDataUpdate:(id)sender;


-(IBAction)chartButton1D:(id)sender;
-(IBAction)chartButton5D:(id)sender;
-(IBAction)chartButton1M:(id)sender;
-(IBAction)chartButton3M:(id)sender;
-(IBAction)chartButton1Y:(id)sender;


@end
