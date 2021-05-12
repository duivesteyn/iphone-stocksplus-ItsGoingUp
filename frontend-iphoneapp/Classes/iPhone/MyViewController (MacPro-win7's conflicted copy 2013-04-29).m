/*
     File: MyViewController.m 
 Abstract: The root view controller for the iPhone design of this app. 
  Version: 1.4 
  

 Copyright (C) 2011 bm All Rights Reserved. 
  
 */

#import "MyViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#include <math.h>
#import "Stock.h"
#import "JSONKit.h"
#import "ATMHud.h"
#import "ATMHudQueueItem.h"
#import "BSYahooFinance.h"
#import "deStockLookup.h"

@interface MyViewController()
@property (nonatomic, retain) YFStockDetailsLoader *detailsLoader;
@property (nonatomic, retain) NSArray *detailKeys;
@end


@implementation MyViewController

@synthesize pageNumberLabel, numberTitle, numberImage, stockDataScrollView,stockValueVar,notesTextArea;
@synthesize beizerPath;
@synthesize hud;
@synthesize sparkline;
@synthesize detailsLoader;
@synthesize detailKeys;


#pragma mark -
#pragma mark View Methods
// load the view nib and initialize the pageNumber ivar
- (id)initWithPageNumber:(int)page
{
    NSLog(@"Page Number %d", pageNumber);
    if ((self = [super initWithNibName:@"MyView" bundle:nil]))
    {
        pageNumber = page;
        [MTStatusBarOverlay sharedInstance].animation = MTStatusBarOverlayAnimationFallDown;
		[MTStatusBarOverlay sharedInstance].historyEnabled = YES;
		[MTStatusBarOverlay sharedInstance].delegate = self;
        
        //Get Data Array
        appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        contentArray = [appDelegate sendArray];
        liveDataArray = [appDelegate sendLiveArray];
        
        //Initialise Graph Array
        graphDataArrayX = [[NSMutableArray alloc] init];  //x and y lists
        graphDataArrayY = [[NSMutableArray alloc] init];  //x and y lists   
        
        [graphDataArrayX addObject:[NSNumber numberWithFloat: 0]];
        [graphDataArrayY addObject:[NSNumber numberWithFloat: 0]];
        
        operationQueue = [NSOperationQueue new];
        chartDataFromCacheAvailable = 0; //ensure this starts off as 0
        
   }
    return self;
}


-(void)viewWillAppear:(BOOL)animated{
    NSLog(@"Page Number %d", pageNumber);

    graphDataView.backgroundColor = [UIColor clearColor];
    
    //Number Formatting
    numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormatter setMaximumFractionDigits:2];  
    [numberFormatter setMinimumFractionDigits:2]; 
    
    stockName.text   = [[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Name"];
    stockTicker.text = [[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"];
    notesTextArea.text = [[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Notes"]; //Set Notes
    

    //Text Label Positioning
    float units = [[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Units"] floatValue];
    if (units == 0) {
        //rearranging units
        stockBuyTitle.text  = @"Volume";
        stockHoldValueTitle.text = @"Mkt Cap"; 
        stockValueChangeTitle.text =  @"Time";
        
        stockVolumeLabel.text = @"Buy";
        stockMktCapLabel.text = @"Hold Value";
        stockTimeLabel.text = @"Change";

        stockBuy.frame = CGRectMake(1, 204, 99, 29);
        stockHoldValue.frame = CGRectMake(111, 204, 99, 29);
        stockValueChange.frame = CGRectMake(212, 204, 99, 29);
        
        stockVolume.frame = CGRectMake(1, 81, 106, 29);
        stockMktCap.frame = CGRectMake(103, 81, 106, 29);
        stockTime.frame = CGRectMake(216, 81, 106, 29);
    } else {
        //normal places
        stockBuyTitle.text  = @"Buy";
        stockHoldValueTitle.text = @"Hold Value"; 
        stockValueChangeTitle.text =  @"Change";
        
        stockVolumeLabel.text = @"Volume";
        stockMktCapLabel.text = @"Mkt Cap";
        stockTimeLabel.text = @"Time";
        
        stockBuy.frame = CGRectMake(1, 81, 106, 29);
        stockHoldValue.frame = CGRectMake(103, 81, 106, 29);
        stockValueChange.frame = CGRectMake(216, 81, 106, 29);
        
        stockVolume.frame = CGRectMake(1, 204, 99, 29);
        stockMktCap.frame = CGRectMake(111, 204, 99, 29);
        stockTime.frame = CGRectMake(212, 204, 99, 29);
    }
    
    //Notification Switch Config
    NSString *var1 = [[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Notification"];
    NSLog(@"Read Notification Status: %@",var1);
    BOOL var2 = [var1 boolValue];     

    NSNumber *var3 = [NSNumber numberWithBool:var2];
    if ([var3 integerValue] == 1) { 
        notificationSwitch.on = TRUE;
        NSLog(@"Turning Notification Switch On %@",var1);
    } else {
        notificationSwitch.on = FALSE;
        NSLog(@"Turning Notification Switch Off %@",var1);
    }

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopActivityIndicator:) name:@"stopActivityIndicator" object:nil]; 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startActivityIndicator:) name:@"startActivityIndicator" object:nil]; 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noInternetMode:) name:@"noInternetMode" object:nil]; 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideNoInternetMode:) name:@"hideNoInternetMode" object:nil]; 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stockUpdate:) name:@"stockUpdate" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationAboutToSuspend:) name:@"applicationAboutToSuspend" object:nil];
    
    
    
    // Add a "textFieldDidChange" notification method to the text field control. This is for noticing changes in the alert price
	[notificationSetTargetPrice addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    
    [self updateViewTargetBar];     //Update the colored target bar
    [self updateViewDataFields];    //Update the stock data
    
    //[self updateStockData];         //Request Live Stock Data
    
}



-(void)viewDidAppear:(BOOL)animated {
    NSLog(@"Page Number %d: ViewDidAppear", pageNumber);
    
    //Disable Stock Target View Initially. This is later turned on/off
    stockTargetPriceView.userInteractionEnabled = NO;
    
    //Update Notification Options Screen
    [self notificationDataUpdate:nil];  //update Notification Text (needs to send nil data as selector
    
    //Show Progress Loading Chart HUD
    int showHUD = 1;
    if (showHUD) {
        hud = [[ATMHud alloc] initWithDelegate:self];
        [graphDataView addSubview:hud.view];
        
        //[hud setAccessoryPosition:3];
        [hud setCaption:@"Chart Loading"];
        [hud setActivity:NO];
        [hud hideAfter:2.0];       
        [hud show];
        
    } 
    
    //Check if Cached Chart Data Available. If so, load it! (getForCachedChartData)
    NSLog(@"Check if Chart Data already downloaded today!");
    [self getForCachedChartData];
    
    //Note: The below is disabled, as I dont want the constant setpoint reminders.
    //Side affect: Everytime a completed notification has occurred, it is resent again..really annoying. it needs rewriting at a minimum
    //Send Setup/Reminder Notification Set Point to Notification Server
    //This is designed to be the location where the server is first aware of the notification. It also serves as a reminder each time the user logs on
    //NSInvocationOperation *stockSetAnnounce = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(stockSetAnnounce) object:nil];
    //[operationQueue addOperation:stockSetAnnounce];     /* Add the operation to the queue */
    //[stockSetAnnounce release];

    
}

-(void)getForCachedChartData {
    //This method checks for available cache data for chart.
    //Checks for todays data only, must have last 365 days data
    //Execution Time: Early, before actual data lookup. It can save a data pull from Y!
    
    
    //Current Date in Str for Plist File Name
    NSDateFormatter* dateFormatterTwo = [[NSDateFormatter alloc] init];
    [dateFormatterTwo setDateFormat:@"yyyy-MM-dd"];
    NSString *dateStringNow = [dateFormatterTwo stringFromDate:[NSDate date]];
    
    //Check if data already downloaded from the net
    NSArray* cachePathArray = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* cachePath = [cachePathArray lastObject];
    NSString *dataStr = [NSString stringWithFormat:@"stockChartData-365-%@-%@.plist",dateStringNow,[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]];
    
    NSString* foofile = [cachePath stringByAppendingPathComponent:dataStr];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:foofile];
    
	if (fileExists == 1)  {
        NSLog(@"Graph Data already downloaded");
        chartDataFromCacheAvailable = 1;    //local dec that chart data is available!
		//Read in Data from plist
        NSArray* cachePathArray = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString* cachePath = [cachePathArray lastObject];
        NSString *dataStr = [NSString stringWithFormat:@"stockChartData-365-%@-%@.plist",dateStringNow,[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]];
        NSString *path = [cachePath stringByAppendingPathComponent:dataStr];
        
        //Define new array for data
        NSMutableDictionary *cachedGraphDict = [[NSMutableDictionary alloc] init];
        cachedGraphDict = [NSDictionary dictionaryWithContentsOfFile:path];	//fill array with cache data
        
        //NSLog(@"cachedGraphDict: OK");        
        NSMutableArray *graphData = [cachedGraphDict objectForKey:@"values"];
        NSMutableArray *scaleData = [cachedGraphDict objectForKey:@"dates"];
        self.sparkline.scaleData =   scaleData;    
        self.sparkline.data     =   graphData;
        
        [self hideGraphLoadingHud];
    }
}



-(void)graphSlicer:(int)days{
    

    
    //Current Date in Str for Plist File Name
    NSDateFormatter* dateFormatterTwo = [[NSDateFormatter alloc] init];
    [dateFormatterTwo setDateFormat:@"yyyy-MM-dd"];
    NSString *dateStringNow = [dateFormatterTwo stringFromDate:[NSDate date]];
    
    //NSLog(@"Graph Data already downloaded");
    //chartDataFromCacheAvailable = 1;    //local dec that chart data is available!
    //Read in Data from plist
    NSArray* cachePathArray = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* cachePath = [cachePathArray lastObject];
    NSString *dataStr = [NSString stringWithFormat:@"stockChartData-365-%@-%@.plist",dateStringNow,[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]];
    NSString *path = [cachePath stringByAppendingPathComponent:dataStr];   
 
    //Define new array for data
    NSMutableDictionary *cachedGraphDict = [[NSMutableDictionary alloc] init];
    cachedGraphDict = [NSDictionary dictionaryWithContentsOfFile:path];	//fill array with cache data
    
    //NSLog(@"cachedGraphDict: OK");        
    NSMutableArray *graphData = [cachedGraphDict objectForKey:@"values"];
    NSMutableArray *scaleData = [cachedGraphDict objectForKey:@"dates"];
    NSLog(@"cachedGraphDict: %@",cachedGraphDict);
    
    int stockDataCount = [scaleData count];
    
    NSLog(@"Number of Data for Stock: %d",stockDataCount);
    
    
    if (days == 365) {
        //Set Sparkline data to 365 days
         
        self.sparkline.scaleData =  scaleData;    
        self.sparkline.data      =  graphData;
        
        if ([graphData count] == 0) {
            NSLog(@"Not enough data;");
            
            [graphDataView addSubview:hud.view];
            [hud hideAfter:2.0];           
            //[hud setAccessoryPosition:3];
            [hud setCaption:@"Not Enough Data"];
            [hud setActivity:NO];
            [hud show];
        }
        
    } else if (days == 180) {
        //Set Sparkline data to 180 days
        NSLog(@"in 180 days");
        NSArray *partialGraphData;
        NSArray *partialScaleData;        
        NSRange theRange;
        if ([graphData count] > 124) {
            theRange.location = [graphData count]-124;
            theRange.length = 124;
        }else {
            theRange.location = 0; 
            theRange.length = [graphData count];
            NSLog(@"Not enough data;");
  
            [graphDataView addSubview:hud.view];
            [hud hideAfter:2.0];           
            //[hud setAccessoryPosition:3];
            [hud setCaption:@"Not Enough Data"];
            [hud setActivity:NO];
            [hud show];
        };
        NSLog(@"theRange.location : %d  . theRange.length: %d",theRange.location,theRange.length);
        
        partialGraphData = [graphData subarrayWithRange:theRange];
        partialScaleData = [scaleData subarrayWithRange:theRange];
        
        self.sparkline.scaleData =  partialScaleData;    
        self.sparkline.data      =  partialGraphData;
        
    } else if (days == 30) {
        //Set Sparkline data to 30 days
        NSLog(@"in 30 days");        
        NSArray *partialGraphData;
        NSArray *partialScaleData;        
        NSRange theRange;
        if ([graphData count] > 23) {
            theRange.location = [graphData count]-23;
            theRange.length = 23;
        }else {
            theRange.location = 0; 
            theRange.length = [graphData count];
            NSLog(@"Not enough data;");

            [graphDataView addSubview:hud.view];
             [hud hideAfter:2.0];           
            //[hud setAccessoryPosition:3];
            [hud setCaption:@"Not Enough Data"];
            [hud setActivity:NO];
            [hud show];
            
        };

         NSLog(@"theRange.location : %d  . theRange.length: %d",theRange.location,theRange.length);       
        partialGraphData = [graphData subarrayWithRange:theRange];
        partialScaleData = [scaleData subarrayWithRange:theRange];
        
        self.sparkline.scaleData =  partialScaleData;    
        self.sparkline.data      =  partialGraphData;
        
    } else if (days == 90) {
        //Set Sparkline data to 90 days
             NSLog(@"in 90 days");    
        NSArray *partialGraphData;
        NSArray *partialScaleData;        
        NSRange theRange;
        if ([graphData count] > 60) {
            theRange.location = [graphData count]-60;
            theRange.length = 60;
        }else {
            theRange.location = 0; 
            theRange.length = [graphData count];
            NSLog(@"Not enough data;");
            
            [graphDataView addSubview:hud.view];
            [hud hideAfter:2.0];           
            //[hud setAccessoryPosition:3];
            [hud setCaption:@"Not Enough Data"];
            [hud setActivity:NO];
            [hud show];
        };


        NSLog(@"theRange.location : %d  . theRange.length: %d",theRange.location,theRange.length);   
        
        partialGraphData = [graphData subarrayWithRange:theRange];
        partialScaleData = [scaleData subarrayWithRange:theRange];
        NSLog(@"2 theRange.location : %d  . theRange.length: %d",theRange.location,theRange.length);   
        
        self.sparkline.scaleData =  partialScaleData;    
        self.sparkline.data      =  partialGraphData;
        
    } else if (days == 5) {        
        //This value should never be called
    }else if (days == 1) {
        //This value should never be called
    }
    
}

- (void)dealloc
{
    [pageNumberLabel release];
    [numberTitle release];
    [numberImage release];
    [sparkline release];
    [numberFormatter release];
    
    
    [super dealloc];
}

NSString* convertValueToStringWithMagnitude(float value) {
     if (value < 10000000)
        return [NSString stringWithFormat:@"%gK", roundf(value/1000)];
    else if (value < 10000000000)
        return [NSString stringWithFormat:@"%gM", roundf(value/1000000)];
    else
        return [NSString stringWithFormat:@"%gB", roundf(value/1000000000)];
}

#pragma mark -
#pragma mark Stock Updating
-(void)stockUpdate:(NSNotification *) notification {
    NSLog(@"in stockUpdate");
    [self updateStockData];
}

-(void)updateStockData{
    
    NSLog(@"Requesting Load of Stock: %@ (%@)",[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Name"],[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]);

    //Initiate Stock Updater (if not currently editing target (targetViewPosition=0 when not editing)
    if (targetViewPosition==0) {
        self.detailsLoader = [YFStockDetailsLoader loaderWithDelegate:self];
        [detailsLoader loadDetails:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]];
    } else  {
        NSLog(@"Skipping Update of %@ due to currently editing targetPrice ",[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]);
        [self localstopActivityIndicator];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];  
    }

    
}

- (void)stockDetailsDidLoad:(YFStockDetailsLoader *)aDetailsLoader
{
    NSLog(@"Updated Stock Data Received for app stockDetailsDidLoad");
    //NSLog(@"detailsLoader: %@",aDetailsLoader.stockDetails.lastTradePriceOnly);
    
   // NSLog(@"%@", [contentArray objectAtIndex:pageNumber-1]);
    NSLog(@"Saving Stock Data: %@",notesTextArea.text);
    
    //Save downloaded data into LiveData.plist
    if (aDetailsLoader.stockDetails.lastTradePriceOnly != (id)[NSNull null])    [[liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]] setObject:aDetailsLoader.stockDetails.lastTradePriceOnly forKey:@"Last"];    //Check null
    if (aDetailsLoader.stockDetails.change  != (id)[NSNull null])               [[liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]] setObject:aDetailsLoader.stockDetails.change forKey:@"Change"];
    if (aDetailsLoader.stockDetails.open    != (id)[NSNull null])               [[liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]] setObject:aDetailsLoader.stockDetails.open forKey:@"Open"];
    if (aDetailsLoader.stockDetails.daysLow  != (id)[NSNull null])              [[liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]] setObject:aDetailsLoader.stockDetails.daysLow forKey:@"Low"];
    if (aDetailsLoader.stockDetails.daysHigh != (id)[NSNull null])              [[liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]] setObject:aDetailsLoader.stockDetails.daysHigh forKey:@"High"];
    if (aDetailsLoader.stockDetails.yearHigh != (id)[NSNull null])              [[liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]] setObject:aDetailsLoader.stockDetails.yearHigh forKey:@"52w high"];
    if (aDetailsLoader.stockDetails.yearLow  != (id)[NSNull null])              [[liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]] setObject:aDetailsLoader.stockDetails.yearLow forKey:@"52w low"];
    if (aDetailsLoader.stockDetails.PERatio  != (id)[NSNull null])              [[liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]] setObject:aDetailsLoader.stockDetails.PERatio forKey:@"pe"];
    if (aDetailsLoader.stockDetails.marketCapitalization  != (id)[NSNull null]) [[liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]] setObject:aDetailsLoader.stockDetails.marketCapitalization forKey:@"MktCap"];
    if (aDetailsLoader.stockDetails.volume  != (id)[NSNull null])               [[liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]] setObject:aDetailsLoader.stockDetails.volume forKey:@"Volume"];
    if (aDetailsLoader.stockDetails.lastTradeTime  != (id)[NSNull null])        [[liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]] setObject:aDetailsLoader.stockDetails.lastTradeTime forKey:@"Time"];

    //Stock Activity Indicator
    [self localstopActivityIndicator];
    
    //UPdate Stock Target Bar
    [self updateViewTargetBar];
    
    //Redraw Datafields
    [self updateViewDataFields];    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"stockUpdateComplete" object:nil];  //alert main stocks view that update is complete
    

    //Load Graph Data (Async) if the chart data is currently not available. this calls -> [self graphDataLoad]; 
    if (chartDataFromCacheAvailable != 1) {
        
        //Low Res Stock Data Download
        NSLog(@"CHART ASYNC: Data not found");
        NSInvocationOperation *operationGraphData = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(graphDataLoad) object:nil];
        [operationQueue addOperation:operationGraphData];     // Add the operation to the queue 
        [operationGraphData release]; 
    }
    
    //High Res Stock Data Download - 5 Day Data
    NSInvocationOperation *operationFiveDayData = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(highResolutionDataLookup) object:nil];
    [operationQueue addOperation:operationFiveDayData];     // Add the operation to the queue 
    [operationFiveDayData release]; 
    
    
    //High Res Stock Data Download - One Day Data
    NSInvocationOperation *operationOneDayData = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(highResolutionDataLookupOneDay) object:nil];
    [operationQueue addOperation:operationOneDayData];     // Add the operation to the queue 
    [operationOneDayData release]; 
    


}

- (void)stockDetailsDidFail:(YFStockDetailsLoader *)detailsLoader
{
    NSLog(@"FAIL!");
    [[MTStatusBarOverlay sharedInstance] hide];
}




-(void)updateViewDataFields{
    
    //Updates all labels in view
    //This bit written on 24th December in Australia!
    if ([liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]]) {
        NSLog(@"Live Data Found. Reading from plist");
        
        [numberFormatter setMaximumFractionDigits:2];
        
        //Set Top Price and Change
        stockValueVar = [[liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]] objectForKey:@"Last"];
        NSString *stockPriceFormatted = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:[stockValueVar floatValue]]];
        stockValue.text = [NSString stringWithFormat:@"%@",stockPriceFormatted];
        
        stockChangeVar = [[liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]] objectForKey:@"Change"];
        NSString *formattedstockChangeVar = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:[stockChangeVar floatValue]]];
        
        float relativeChange = [stockChangeVar floatValue] / [stockValueVar floatValue];
        [numberFormatter setNumberStyle:NSNumberFormatterPercentStyle];
        NSString *relativeChangeRounded = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:relativeChange]];
        [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle]; //change it back again
        
        if ([stockChangeVar floatValue]>=0) {     
            stockChange.text = [NSString stringWithFormat:@"%@ (%@)",formattedstockChangeVar,relativeChangeRounded];
        } else {
            stockChange.text = [NSString stringWithFormat:@"%@ (%@)",formattedstockChangeVar,relativeChangeRounded];
        }

        
        //Set The detailed view stock data
        stockOpenVar = [[liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]] objectForKey:@"Open"];
        float stockOpenVarFloat = [stockOpenVar floatValue];
        stockOpen.text = [NSString stringWithFormat:@"%.2f",stockOpenVarFloat];  
        
        stockLowVar = [[liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]] objectForKey:@"Low"]; 
        float stockLowVarFloat = [stockLowVar floatValue];
        stockLow.text = [NSString stringWithFormat:@"%.2f",stockLowVarFloat]; 
        
        stockHighVar = [[liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]] objectForKey:@"High"]; 
        float stockHighVarFloat = [stockHighVar floatValue];
        stockHigh.text = [NSString stringWithFormat:@"%.2f",stockHighVarFloat]; 
        
        //Volume
        NSString *stockVolumeVar = [[liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]] objectForKey:@"Volume"];
        float stockVolumeVarfloat = [stockVolumeVar floatValue];
        NSString *stockVolumeVarStr = convertValueToStringWithMagnitude(stockVolumeVarfloat);
        //NSLog(@"Stock Volume: %f -> %@",[stockVolumeVar floatValue],stockVolumeVarStr);
        stockVolume.text = [NSString stringWithFormat:@"%@",stockVolumeVarStr]; 
        
        //MktCap
        NSDecimalNumber *stockMktCapVar = [[liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]] objectForKey:@"MktCap"];
        //float stockMktCapfloat = [stockMktCapVar floatValue]; 
       // NSString *stockMktCapStrVar = convertValueToStringWithMagnitude(stockMktCapfloat);
        //NSLog(@"Stock Mkt Cap: %f -> %@",stockMktCapfloat,stockMktCapStrVar); 
        stockMktCap.text = [NSString stringWithFormat:@"%@",stockMktCapVar];
        
        //52w low/high
        NSString *stock52wlowVar = [[liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]] objectForKey:@"52w low"];
        stock52wLow.text = [NSString stringWithFormat:@"%@",stock52wlowVar];  
        NSString *stock52whighVar = [[liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]] objectForKey:@"52w high"];
        stock52wHigh.text = [NSString stringWithFormat:@"%@",stock52whighVar]; 
        
        //PE
        NSString *stockPEvar = [[liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]] objectForKey:@"pe"];
        stockPE.text = [NSString stringWithFormat:@"%@",stockPEvar];  
        
        //Date
        NSDate *stockTimeVar = [[liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]] objectForKey:@"Time"];
        stockTime.text = [NSString stringWithFormat:@"%@",stockTimeVar];  
        
        //Buy Amount
        NSString *buy = [[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Buy Price"];
        stockBuy.text = ([buy intValue] == 0) ?  @"-": [numberFormatter stringFromNumber:[NSNumber numberWithFloat:[buy floatValue]]];

        
        //Hold Value
        float units = [[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Units"] floatValue];
        float holdValue = units * [stockValueVar floatValue];
        if (holdValue >5000) { [numberFormatter setMaximumFractionDigits:0]; }else [numberFormatter setMaximumFractionDigits:2];  
        if (holdValue > 25000) {
            NSString *conversionStr = convertValueToStringWithMagnitude(holdValue);
            NSLog(@"Stock Volume: %f -> %f",[conversionStr floatValue],holdValue);
            stockHoldValue.text = [NSString stringWithFormat:@"%@",conversionStr]; 
        } else  stockHoldValue.text = ([buy intValue] == 0) ?  @"-": [numberFormatter stringFromNumber:[NSNumber numberWithInt:holdValue]]; 
        [numberFormatter setMaximumFractionDigits:2];
        
        
        
        //Value Change
        //The following gives total change since purchase -> (Last - Buy) * units       
         float lifetimeChangeCalc = units * ([stockValueVar floatValue] - [buy floatValue]);
        NSLog(@"changeValue = units %f * (stockValueVar %@ - stockBuyVar %@)",units,stockValueVar,buy);

        if (holdValue > 25000 || abs(lifetimeChangeCalc)>25000) {
            NSString *conversionStr = convertValueToStringWithMagnitude(lifetimeChangeCalc);
            NSLog(@"Stock Volume: %f -> %f",[conversionStr floatValue],lifetimeChangeCalc);
            
            stockValueChange.text = (lifetimeChangeCalc > 0) ? [NSString stringWithFormat:@"+%@",conversionStr] : [NSString stringWithFormat:@"%@",conversionStr]; 
            
        } else  stockValueChange.text = ([buy intValue] == 0) ?  @"-": [numberFormatter stringFromNumber:[NSNumber numberWithInt:lifetimeChangeCalc]]; 
        
        
        //The Following Gives Todays Change
        // float changeValue = units * [stockChangeVar floatValue];
        // stockValueChange.text = ([buy intValue] == 0) ?  @"-": [numberFormatter stringFromNumber:[NSNumber numberWithInt:changeValue]];         

        
    } else {
        NSLog(@"MyViewController:updateViewDataFields:%@ - Live Data Not Found. Need to Create Data",[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]);
        
        NSString *noDataString = @"-";
        
        NSMutableDictionary *liveData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:noDataString, @"Change", noDataString, @"Last", noDataString, @"Volume", noDataString, @"MktCap",noDataString, @"Open",noDataString, @"Low", noDataString, @"High", noDataString, @"52w high", noDataString, @"52w low", noDataString, @"pe",noDataString,@"Time", nil];
        
        NSMutableDictionary *liveDataEncapsulated = [[NSMutableDictionary alloc] initWithObjectsAndKeys: liveData,@"Data",[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"],@"StockName",nil];
        [liveDataArray setObject:[liveDataEncapsulated objectForKey:@"Data"] forKey:[liveDataEncapsulated objectForKey:@"StockName"]];
        

        
        stockValue.text = noDataString;
        stockChange.text = noDataString;
        stockOpen.text = noDataString;
        stockLow.text = noDataString;
        stockHigh.text = noDataString;
        stockVolume.text = noDataString;
        stockMktCap.text = noDataString;
        stock52wLow.text = noDataString;
        stock52wHigh.text = noDataString;
        stockPE.text = noDataString;
        stockTime.text = noDataString;
        stockHoldValue.text = noDataString;
        stockValueChange.text = noDataString;
        stockBuy.text = noDataString;
        
        //[self updateStockData];
    }
    
    //Chart update
    //[self setNeedsDisplay:YES];
    NSLog(@"TODO: Update Chart on Stock UPdate"); //The above line a great start..but the updated stock data is also required...once in, just call setNeedsDisplay:YES
    


}

-(void)updateViewTargetBar{

    
    //Display  Above/Below Setting (Note needs to gracefully handle no entry. This code added in 1.5 as bug correction)
    NSString *aboveOrBelowFromContentArray = [[contentArray objectAtIndex:pageNumber-1] objectForKey:@"AboveOrBelow"];    
    if ([aboveOrBelowFromContentArray isEqualToString:@"B"]) {
        notificationAboveBelow.selectedSegmentIndex = 1;
    } else notificationAboveBelow.selectedSegmentIndex = 0;
    
    //Get Correct Repeat Setting (This code added in 1.5 as bug correction)
    NSString *repeatFrequencyFromContentArray = [[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Repeat Frequency"];
    NSLog(@"repeatFrequencyFromContentArray: %@",repeatFrequencyFromContentArray);
    if ([repeatFrequencyFromContentArray isEqualToString:@"D"]) {
        notificationRepeat.selectedSegmentIndex = 1;
    } else if ([repeatFrequencyFromContentArray isEqualToString:@"W"]) {
        notificationRepeat.selectedSegmentIndex = 2;
    } else {
        notificationRepeat.selectedSegmentIndex = 0;
    }
    

    
    [self targetBarText];
}
-(void)targetBarText{

    
    //Set Simple Floats for TargetBar Logic
    NSString *stockTargetPriceFromContentArray = [[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Target Price"];
    float targetPrice = [stockTargetPriceFromContentArray floatValue];
    
    float targetbarBuy = [[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Buy Price"] floatValue];
    NSDecimalNumber *stockValueVar21 = [[liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]] objectForKey:@"Last"];
    float targetbarCurrentPrice = [stockValueVar21 floatValue];
    
    //Set Target Bar Image/Color
    UIImage *targetBarImage = [UIImage imageNamed: @"wrapping-correction-grey.png"];
    UIImage *targetBarImageEditButton = [UIImage imageNamed:@"button-edit-grey.png"];
    
    //First Check Data Availability
    if ([liveDataArray objectForKey:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]]) {
        

        
        //Need to add in support for alerts below a target price
        NSLog(@"bughunt here: %@",[contentArray objectAtIndex:pageNumber-1]);
        if (notificationAboveBelow.selectedSegmentIndex == 0) {
            
            if (targetbarCurrentPrice >= targetPrice) {
                NSLog(@"TargetBar: Current Stock is Above Target Price");
                targetBarImage = [UIImage imageNamed: @"wrapping-correction-green.png"];                             //Bar is Green
                targetBarImageEditButton = [UIImage imageNamed: @"button-edit-green.png"];                           //Bar is Green
                stockTargetPrice.text =  (targetPrice >=100) ? [NSMutableString stringWithFormat:@"Stock Price Above Target: %.0f", targetPrice] : [NSMutableString stringWithFormat:@"Stock Price Above Target: %.2f", targetPrice];
                
            } else if (targetbarBuy <= targetbarCurrentPrice) {
                NSLog(@"TargetBar: Current Stock is Between Buy Price and Sell Target");
                targetBarImage = [UIImage imageNamed: @"wrapping-correction-yellow.png"];                             //Bar is Yellow
                targetBarImageEditButton = [UIImage imageNamed: @"button-edit-yellow.png"];                           //Bar is Yellow
                stockTargetPrice.text =  (targetPrice >=100) ? [NSMutableString stringWithFormat:@"Target Price: %.0f", targetPrice] : [NSMutableString stringWithFormat:@"Target Price: %.2f", targetPrice];
            } else if (targetbarCurrentPrice < targetbarBuy) {
                NSLog(@"TargetBar: Current Stock is Below Buy Price");
                targetBarImage = [UIImage imageNamed: @"wrapping-correction-red.png"];                                //Bar is Red
                targetBarImageEditButton = [UIImage imageNamed: @"button-edit-red.png"];                              //Bar is Red
                stockTargetPrice.text =  (targetPrice >=100) ? [NSMutableString stringWithFormat:@"Stock Price Below Buy. Target: %.0f", targetPrice] : [NSMutableString stringWithFormat:@"Stock Price Below Buy. Target: %.2f", targetPrice];
            }
            
        } else if (notificationAboveBelow.selectedSegmentIndex == 1) {
            //do some stuff for BELOW MODE
            
            if (targetbarCurrentPrice > targetPrice) {
                NSLog(@"TargetBar: Current Stock Price is greater than Target Price");
                targetBarImage = [UIImage imageNamed: @"wrapping-correction-red.png"];                             //Bar is Red
                targetBarImageEditButton = [UIImage imageNamed: @"button-edit-red.png"];                           //Bar is Red
                stockTargetPrice.text =  (targetPrice >=100) ? [NSMutableString stringWithFormat:@"Stock Above Target: %.0f", targetPrice] : [NSMutableString stringWithFormat:@"S Above Target: %.2f", targetPrice];
                
            } else if (targetbarCurrentPrice <= targetPrice) {
                NSLog(@"TargetBar: Current Stock is Below Target Price");
                targetBarImage = [UIImage imageNamed: @"wrapping-correction-green.png"];                                //Bar is Green
                targetBarImageEditButton = [UIImage imageNamed: @"button-edit-green.png"];                              //Bar is Green
                stockTargetPrice.text =  (targetPrice >=100) ? [NSMutableString stringWithFormat:@"Stock Below Target: %.0f", targetPrice] : [NSMutableString stringWithFormat:@"Stock Below Target: %.2f", targetPrice];
            }
        }
        
    } else {
        //Data Fail - No Color Change Needed
        stockTargetPrice.text =  [NSMutableString stringWithFormat:@"Target Price: %@", stockTargetPriceFromContentArray];
        NSLog(@"TargetBar: No information on Live Data Available - Using Grey Bar");
    }
    
    [stockColorTargetBar setImage:targetBarImage];  //set the targetbar background image/color
    [stockTargetEditButton setBackgroundImage:targetBarImageEditButton forState:UIControlStateNormal];
    
    //Set Target Editing TextArea
    notificationSetTargetPrice.text = [NSMutableString stringWithFormat:@"%@", stockTargetPriceFromContentArray];
    
   // [targetBarImage release];
   // [targetBarImageEditButton release];
    
}

#pragma mark -
#pragma mark Notification View
- (IBAction)notificationSwitchToggled:(id)sender {
    
    [self notificationDataUpdate:nil];  //update notification text
    
    //Note, when the edit/done button is pressed the notificatio will be disabled.
    //That is a better place to remove the push notification than here. (see stockAnnounceTurnOff)
}



-(IBAction)notificationDataUpdate:(id)sender {
    
    NSString *targetPrice = notificationSetTargetPrice.text;
    int aboveBelow = notificationAboveBelow.selectedSegmentIndex;
    NSString *aboveBelowTxt;
    if (aboveBelow==0) aboveBelowTxt = @"Above"; else aboveBelowTxt = @"Below";
    
    NSLog(@"Notification Data Changed for: %@, %@ %@",[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"],aboveBelowTxt,targetPrice);
    
    
    //Above/Below Request Data Storage
    if (notificationAboveBelow.selectedSegmentIndex == 0) {
        [[contentArray objectAtIndex:pageNumber-1] setObject:@"A" forKey:@"AboveOrBelow"];
    } else if (notificationAboveBelow.selectedSegmentIndex == 1) {
        [[contentArray objectAtIndex:pageNumber-1] setObject:@"B" forKey:@"AboveOrBelow"];
    }
    
    
    //Repeat Functionality Data Switch (added in V1.5)
    if (notificationRepeat.selectedSegmentIndex == 0) {
        [[contentArray objectAtIndex:pageNumber-1] setObject:@"No" forKey:@"Repeat Frequency"];    
    } else if (notificationRepeat.selectedSegmentIndex == 1) {
        [[contentArray objectAtIndex:pageNumber-1] setObject:@"D" forKey:@"Repeat Frequency"];
    } else if (notificationRepeat.selectedSegmentIndex == 2) {
        [[contentArray objectAtIndex:pageNumber-1] setObject:@"W" forKey:@"Repeat Frequency"];
    }
    
    

    //Notification Value Change
    if (notificationSwitch.on == YES) {
        NSLog(@"Notification Switch is on");
        
        //Set Notification bit to on
        [[contentArray objectAtIndex:pageNumber-1] setObject:@"1" forKey:@"Notification"];
         
        //Notifications Enabled
        if (notificationAboveBelow.selectedSegmentIndex==0) {
            //Above Mode
            notificationText.text = [NSString stringWithFormat:@"A notification will arrive when the stock is above %@",targetPrice];
        } else {
            notificationText.text = [NSString stringWithFormat:@"A notification will arrive when the stock is below %@",targetPrice];   //below notification            
        }
        
    } else if  (notificationSwitch.on == NO) {
        
        //Set Notification bit to off
        [[contentArray objectAtIndex:pageNumber-1] setObject:@"0" forKey:@"Notification"];
        
        notificationText.text = [NSString stringWithFormat:@"Notifications for %@ are Off",[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]];
        NSLog(@" notificationText.text %@",notificationText.text);
        
    }
    
    [self targetBarText];

}

-(void)applicationAboutToSuspend:(NSNotification*)notification {

    
    //Hide Edit Target View, if left open, when closing the app.
    NSLog(@"in applicationAboutToSuspend - Removing bottom view");
    BOOL noteCheck = [notificationSetTargetPrice isFirstResponder];
    //NSLog(@"noteCheck: %d",noteCheck);
    if (noteCheck == 1) {
        [self editTargetPressed:nil];
    }
}

-(IBAction)editTargetPressed:(id)sender{
    
    NSLog(@"Pressed Edit Target Button");  
    int distanceToMoveDown = stockTargetPriceView.frame.size.height-1;
    
    //If Currently Hidden
    if (targetViewPosition == 0) {        
        [UIView beginAnimations:@"Slide Down Target View" context:NULL];
        [UIView setAnimationDuration:0.4];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationFinished:finished:context:)];    
        stockTargetPriceView.frame = CGRectMake(0, stockTargetPriceView.frame.origin.y+distanceToMoveDown, stockTargetPriceView.frame.size.width, stockTargetPriceView.frame.size.height);
        stockStatsView.frame = CGRectMake(0, stockStatsView.frame.origin.y+distanceToMoveDown, stockStatsView.frame.size.width, stockStatsView.frame.size.height);
        chartView.frame = CGRectMake(0, chartView.frame.origin.y+distanceToMoveDown, chartView.frame.size.width, chartView.frame.size.height);
        notesButtonView.frame = CGRectMake(0, notesButtonView.frame.origin.y+distanceToMoveDown, notesButtonView.frame.size.width, notesButtonView.frame.size.height);
        notesView.frame = CGRectMake(0, notesView.frame.origin.y+distanceToMoveDown, notesView.frame.size.width, notesView.frame.size.height);
        
        targetViewPosition = 1;  //set bit noting that it is in position 1   
        
        stockTargetPriceView.userInteractionEnabled = YES;
        stockTargetEditButton.userInteractionEnabled = NO; //Disable this until the box fully loads (fixes bug where keyboard is kept up)

        [UIView commitAnimations];
     
        [stockTargetEditButton setTitle:@"done" forState:UIControlStateNormal];     //Change Text
        
        
    //If Currently Shown        
    } else  {
        [UIView beginAnimations:@"Slide Back Up Target View" context:nil];
        [UIView setAnimationDuration:0.4f];
        stockTargetPriceView.frame = CGRectMake(0, stockTargetPriceView.frame.origin.y-distanceToMoveDown, stockTargetPriceView.frame.size.width, stockTargetPriceView.frame.size.height);
        stockStatsView.frame  = CGRectMake(0, stockStatsView.frame.origin.y-distanceToMoveDown, stockStatsView.frame.size.width, stockStatsView.frame.size.height);
        chartView.frame  = CGRectMake(0, chartView.frame.origin.y-distanceToMoveDown, chartView.frame.size.width, chartView.frame.size.height);
        notesButtonView.frame  = CGRectMake(0, notesButtonView.frame.origin.y-distanceToMoveDown, notesButtonView.frame.size.width, notesButtonView.frame.size.height);
        notesView.frame = CGRectMake(0, notesView.frame.origin.y-distanceToMoveDown, notesView.frame.size.width, notesView.frame.size.height);
        [UIView commitAnimations];
        
        targetViewPosition = 0;                         //set bit noting that it is in position 1 
        
        stockTargetPriceView.userInteractionEnabled = NO;
        
        [notificationSetTargetPrice resignFirstResponder];
        
        [[contentArray objectAtIndex:pageNumber-1] setObject:notificationSetTargetPrice.text forKey:@"Target Price"];
        [self updateViewTargetBar];
        
        [stockTargetEditButton setTitle:@"edit" forState:UIControlStateNormal];     //Change Text
        
        //Send Updated Notification Set Point to Notification Server
        NSInvocationOperation *stockSetAnnounce = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(stockSetAnnounce) object:nil];
        [operationQueue addOperation:stockSetAnnounce];     /* Add the operation to the queue */
        [stockSetAnnounce release];
    }
    
    
    //Disabling Mainview Scrolling:
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showNotesView" object:nil];
    
}

  


// Method Generates a random string of Hex
// stackoverflow.com/questions/2633801/generate-a-random-alphanumeric-string-in-cocoa
-(NSString *) genRandStringLength: (int) len {
    NSString *letters = @"ABCDEF0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
    }
    
    return randomString;
}

#pragma mark -
#pragma mark Notification Server Calls

//Set Stock Set Point Data to Server via Post
//Extended: This will also allow the disabling of notifications (by sending high setpoint of 99999) from notificationSwitch
-(void)stockSetAnnounce {
    
    NSLog(@"------"); 
    NSLog(@"in stockSetAnnounce - Registering Stock Notification Update");  
    NSLog(@"Notification Switch: %d",notificationSwitch.on);
    NSString *token = [UAirship shared].deviceToken;
    NSLog(@"Device Token: %@",token);
    NSString *tokenUcase = [token uppercaseString];

    notificationID    = [[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Notification ID"];   //unique notificationID - 12 digits
    stockTickerNew    = [[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"];       //Stock Ticker "BHP.AX"
    
    if (notificationSwitch.on == TRUE) {
        //Parameter Data

        //Convert stockSetPoint to 'American' Decimal System, It does not accept a comma
        NSNumberFormatter *currencyFormatter = [[NSNumberFormatter alloc] init];
        NSNumber *stockSetPointNumber     = [currencyFormatter numberFromString:notificationSetTargetPrice.text];
        stockSetPoint = [NSString stringWithFormat:@"%@",stockSetPointNumber];
        [currencyFormatter release];
        
        aboveOrBelow      = (notificationAboveBelow.selectedSegmentIndex == 0) ? @"A" : @"B";        //aboveOrBelow = A/B
        repeatPeriod      = (notificationRepeat.selectedSegmentIndex==0) ? @"No" : (notificationRepeat.selectedSegmentIndex==1) ? @"D" : @"W";  //repeat = No/Hr/D/W
        
        //Setup POST Data
        //Designed for API Version 1.09
        postUrl = [NSURL URLWithString:@"https://itsgoingup.appspot.com/receive/setnotification"];
        post =[[NSString alloc] initWithFormat:@"notificationID=%@&deviceToken=%@&ticker=%@&setPoint=%@&aboveOrBelow=%@&repeat=%@",notificationID,tokenUcase,stockTickerNew,stockSetPoint,aboveOrBelow,repeatPeriod];
    } 
    
    if (notificationSwitch.on == FALSE) {
        NSLog(@"Notification Disabled Case");
        
        //Setup POST Data
        //Designed for API Version 1.09
        postUrl = [NSURL URLWithString:@"https://itsgoingup.appspot.com/receive/setnotification"];
        post =[[NSString alloc] initWithFormat:@"notificationID=%@&deviceToken=%@&delete=1",notificationID,tokenUcase];
    }
    
    
    NSLog(@"%@",post);
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
    [request setURL:postUrl];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    /* when we use https, we need to allow any HTTPS cerificates, so add the one line code, to tell the NSURLRequest to accept any https certificate, i'm not sure about the security aspects (doh)
     */
    
    NSError *error;
    NSURLResponse *response;
    NSData *urlData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSString *data=[[NSString alloc]initWithData:urlData encoding:NSUTF8StringEncoding];
    NSLog(@"------"); 
    NSLog(@"%@",data);
    NSLog(@"------"); 
}


-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSLog(@"in shouldChangeCharactersInRange");

    
    if([string length]==0){
        return YES;
    }
    
    //Validate Character Entry
    NSCharacterSet *myCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789,."];
    for (int i = 0; i < [string length]; i++) {
        unichar c = [string characterAtIndex:i];
        
        if ([myCharSet characterIsMember:c]) {
            
            //now check if string already has 1 decimal mark
            NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
            NSArray *sepPeriod = [newString componentsSeparatedByString:@"."];
            NSArray *sepComma = [newString componentsSeparatedByString:@","];   
            NSLog(@"sepPeriod: %@ sepComma: %@" ,sepPeriod ,sepComma );            
            NSLog(@"sepPeriod: %d sepComma: %d" ,[sepPeriod count],[sepComma count]);
            int totalDecimals = [sepComma count] + [sepPeriod count];
            NSLog(@"totalDecimals: %d",totalDecimals);
            if(totalDecimals>3) return NO ; else {
                return YES;
            }
        }
    }
    
    return NO;
}


- (void)textFieldDidChange:(UITextField *)textField{
    NSLog(@"in textFieldDidChange");
    [self notificationDataUpdate:nil];  //update notification text
}


#pragma mark -
#pragma mark No Internet Support

-(void)noInternetMode:(NSNotification *) notification {
        NSLog(@"stockAndDataView.frame: %f, %f, %f, %f",stockAndDataView.frame.origin.x,stockAndDataView.frame.origin.y,stockAndDataView.frame.size.width,stockAndDataView.frame.size.height);
        NSLog(@"No InternetMode enabled"); 
        //Show/Hide SummaryView No Internet View
        [[NSNotificationCenter defaultCenter] postNotificationName:@"showNoInternetBar" object:nil];
    
             [stockAndDataView addSubview:noInternetView];
     
             noInternetView.frame = CGRectMake(0, -69, noInternetView.frame.size.width, noInternetView.frame.size.height);
             stockAndDataView.frame = CGRectMake(0, 69, stockAndDataView.frame.size.width, stockAndDataView.frame.size.height); 
       
             //Show Notes View
             [self.view addSubview: notesView];   
             notesView.frame = CGRectMake(0,164, 320, notesView.frame.size.height+200);
             notesFirstRun = 1;
             noInternetConnection = 1;
    
    
}

-(void)hideNoInternetMode:(NSNotification *) notification {
    
    NSLog(@"View:%@ - in hideNoInternetMode",[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]);
    [noInternetView removeFromSuperview];
    noInternetConnection = 0;    

    stockAndDataView.frame = CGRectMake(0, 0, stockAndDataView.frame.size.width, stockAndDataView.frame.size.height); 

    //Hide Notes now        
    [UIView beginAnimations:@"Move Notes" context:nil];
    [UIView setAnimationDuration:0.5];
    notesView.frame = CGRectMake(0, 480-20-25, 320, notesView.frame.size.height );
    [UIView commitAnimations];
    notesPosition = 0;
    [notesTextArea resignFirstResponder];
    
}






// set the label and background color when the view has finished loading
- (void)viewDidLoad
{
    notesPosition = 0;                  //0 is down, 1 means up, 2 means full screen and editing with keyboard
    notesFirstRun = 0;

    //iPhone 5+ Support (4" Screens)
    CGRect cgRect =[[UIScreen mainScreen] bounds];
    CGSize cgSize = cgRect.size;
    NSLog(@"GCSize: %f,%f",cgSize.width,cgSize.height);
    

    //load in Stock data into Scroll View
    [self.view insertSubview:stockTargetPriceView belowSubview:headerImageView]; //put this behind the header view so it can slide down stealthly
    stockTargetPriceView.frame = CGRectMake(stockTargetPriceView.frame.origin.x, stockAndDataView.frame.origin.y - 53, stockTargetPriceView.frame.size.width, stockTargetPriceView.frame.size.height); //Set Frame Start slightly above screen. Looks Better when shown.
    
    
    //Set Viewsize for stockAndDataViewInMainPage view
    [self.view addSubview:stockStatsView];
    stockStatsView.frame = CGRectMake(0, 95, stockStatsView.frame.size.width, 145);
    
    //If you want to have the Stock Details Section bigger, adn the chart smaller uncomment the following:
    //if (cgSize.height == 568) {
    //    stockStatsView.frame = CGRectMake(0, 95, stockStatsView.frame.size.width, 265); //if iPhone is 4" model, expand middle Stock Details Section
    //    stockDataScrollView.frame = CGRectMake(0, 25, stockStatsView.frame.size.width, 240);
    //}

    //Display Seperated NotesButton into StockAndDataView (always at bottom)
    [self.view addSubview:notesButtonView];
    notesButtonView.frame = CGRectMake(0,cgSize.height-notesButtonView.frame.size.height-20, 320, notesButtonView.frame.size.height);
    
    //Display Seperated ChartView into StockAndDataView (height based on being between stockStatsView and notesButtonView)
    [self.view addSubview:chartView];
    chartView.frame = CGRectMake(0, stockStatsView.frame.origin.y+stockStatsView.frame.size.height, 320, notesButtonView.frame.origin.y-stockStatsView.frame.origin.y-stockStatsView.frame.size.height+1);

    

    [stockDataScrollView addSubview:stockDataView];
    [stockDataScrollView setContentSize:CGSizeMake(stockDataView.frame.size.width, stockDataView.frame.size.height)];
    [stockDataScrollView setScrollEnabled:YES];
    [graphUIViewInMainPage addSubview:graphDataBG]; //add Graph Views (one for BG Stock, other for line/scale data)
    
    // Gestures
    // One finger, swipe up
    UISwipeGestureRecognizer *oneFingerSwipeUp = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(oneFingerSwipeUp:)] autorelease];
    [oneFingerSwipeUp setDirection:UISwipeGestureRecognizerDirectionUp];
    [[self view] addGestureRecognizer:oneFingerSwipeUp];
    

	// One finger, swipe down
    UISwipeGestureRecognizer *oneFingerSwipeDown = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(oneFingerSwipeDown:)] autorelease];
    [oneFingerSwipeDown setDirection:UISwipeGestureRecognizerDirectionDown];
    [[self view] addGestureRecognizer:oneFingerSwipeDown];

    notificationSetTargetPrice.keyboardType=UIKeyboardTypeDecimalPad;    //I want a decimal place in the keyboard
    
    //Set Default View (this code moved from viewDidAppear)
    [self chartButton1D:nil]; 


    
}
   

- (void)scrollViewWillBeginDragging:(UIScrollView *)stockDataScrollView
{
    //Tried 2 versions, version 1 is still more reliable
    int version = 1;
    
    if (version==2) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"showNotesView" object:nil];
    } else {
        //in here: set a bit, to stop global side to side scrolling (This disables the previous circular movement of 2 scrollviews)
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setInteger:1 forKey:@"scrollingNewPageLock"];
        [prefs synchronize];
        NSLog(@"Started Dragging: locking sideways scrolling");
    }


}

// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidScroll:(UIScrollView *)stockDataScrollView
{
    //Tried 2 versions, version 1 is still more reliable
    int version = 1;
    
    if (version==2) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"showNotesView" object:nil];
    } else {    //flip the bit back
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        int value = 0;
        [prefs setInteger:value forKey:@"scrollingNewPageLock"];
        [prefs synchronize];
        //NSLog(@"Stopped Dragging: unlocking sideways scrolling.");
    }

}

#pragma mark
#pragma mark Chart 


-(void)hideGraphLoadingHud {
    //NSLog(@"Hide Hud Issued");
    //[hud hide];
    [hud.view removeFromSuperview];
}

-(void)highResolutionDataLookup{
    
    //High Resolution Minute by Minute Data Lookup! (This is version 2 of the stocklookup method)
    DeStockLookup * deStockLookup = [[DeStockLookup alloc] init];
    deStockLookupHighResDataFiveDay =  [deStockLookup stockChartDownloadVersionTwo:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"] days:5];
    //NSLog(@"deOutput v2 highResolutionDataLookup: %@",deStockLookupHighResDataFiveDay);
    
    buttonChartRange5D.userInteractionEnabled = YES;
    
    NSLog(@"Finished Executing highResolutionDataLookup");
}

-(void)highResolutionDataLookupOneDay{
    
    //High Resolution Minute by Minute Data Lookup! (This is version 2 of the stocklookup method)
    DeStockLookup * deStockLookup = [[DeStockLookup alloc] init];
    deStockLookupHighResDataOneDay =  [deStockLookup stockChartDownloadVersionTwo:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"] days:1];
    //NSLog(@"deOutput v2 highResolutionDataLookup: %@",deStockLookupHighResDataOneDay);

    buttonChartRange1D.userInteractionEnabled = YES;
    NSLog(@"High Res Data now available");
    [self chartButton1D:nil];   //selects 1D (This is a strange selection, but as the default is 1D, it just updates the screen once loaded
    
    NSLog(@"Finished Executing highResolutionDataLookupOneDay");
}

-(void)graphDataLoad{
    
    //Get Data from DEStockLookup and insert into chart
    DeStockLookup * deStockLookup = [[DeStockLookup alloc] init];
    deStockLookupLoResData =  [deStockLookup stockChartDownload:[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Symbol"]];
    NSMutableArray *graphData = [deStockLookupLoResData objectForKey:@"values"];
    NSMutableArray *scaleData = [deStockLookupLoResData objectForKey:@"dates"];
    self.sparkline.scaleData =   scaleData;    
    self.sparkline.data     =   graphData;

    [self hideGraphLoadingHud]; //hide hud
    NSLog(@"Finished Executing graphDataLoad");
    
    //Example Usage of Chart - note, graphData no longer needs to be NSNumbers (just NSStrings)
    //------------------------------------------------------------------------
    
    /*
     NSArray *graphData = [NSArray arrayWithObjects:
     [NSNumber numberWithFloat:1 + (arc4random() % (300 - 1))],
     [NSNumber numberWithFloat:1 + (arc4random() % (300 - 1))],
     [NSNumber numberWithFloat:1 + (arc4random() % (300 - 1))],
     [NSNumber numberWithFloat:1 + (arc4random() % (300 - 1))],
     [NSNumber numberWithFloat:1 + (arc4random() % (300 - 1))],
     [NSNumber numberWithFloat:1 + (arc4random() % (300 - 1))],
     [NSNumber numberWithFloat:1 + (arc4random() % (300 - 1))],
     nil];    
     
     NSArray *scaleData = [NSArray arrayWithObjects:
     @"01/06/2011",
     @"02/06/2011",
     @"03/06/2011",
     @"04/06/2011",
     @"05/06/2011",
     @"06/06/2011",
     @"07/06/2011",
     nil];  
     
     
     NSLog(@"graphData:11  %@",graphData);
     NSLog(@"scaleData:11  %@",scaleData); 
     
     self.sparkline.scaleData =   scaleData;    
     self.sparkline.data     =   graphData;
     */

}



-(IBAction)chartButton1D:(id)sender{
    NSLog(@"chartButton1D");
    
    [hud.view removeFromSuperview]; //If HUD already shown, remove it.
    
    //Setup CKSparkline Chart
    self.sparkline.highResData = 2;
    self.sparkline.chartDays = 1;
    NSMutableArray *graphData = [deStockLookupHighResDataOneDay objectForKey:@"values"];
    NSMutableArray *scaleData = [deStockLookupHighResDataOneDay objectForKey:@"dates"];
    NSMutableString *stockTimeZone =   [deStockLookupHighResDataOneDay objectForKey:@"time zone"];
    NSMutableArray *stockTimeStampOpenClose =   [deStockLookupHighResDataOneDay objectForKey:@"stockTimeStampOpenClose"];
    
    
    //Stock Time Stamps
    //-----------------
    //This calculation is used to scale the data view, to best represent incomplete 1D data (like yahoo finance does)
    //-----------------
    //Setup Date Formatter
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];       //DateFormatter for Dates
    [formatter setDateFormat: @"HH:mm"];
    NSTimeZone *timeZoneAbr = [NSTimeZone timeZoneForSecondsFromGMT:[stockTimeZone intValue]]; //East Coast Oz is "gmtoffset:36000"
    [formatter setTimeZone:timeZoneAbr];   

    //Planned Open Time
    NSString *plannedOpenTime = [[stockTimeStampOpenClose objectAtIndex:0] substringFromIndex:10];    //get end time (from array)
    //NSLog(@"Stock plannedOpenTime: %@ (unix time)",plannedOpenTime);
    NSDate *plannedOpenTimeInDate = [NSDate dateWithTimeIntervalSince1970:[plannedOpenTime intValue]]; //get end time from unix format to a NSDate  
    //NSLog(@"Stock TimeStamp: %@",plannedOpenTimeInDate);          
    NSString *plannedOpenTimeAdjusted = [formatter stringFromDate:plannedOpenTimeInDate];
    NSLog(@"Stock plannedOpenTimeAdjusted: %@",plannedOpenTimeAdjusted);                
    //Planned Close Time
    NSString *plannedCloseTime = [stockTimeStampOpenClose objectAtIndex:1];    //get end time (from array)
    //NSLog(@"Stock plannedCloseTime: %@ (unix time)",plannedCloseTime);            
    NSDate *plannedCloseTimeInDate = [NSDate dateWithTimeIntervalSince1970:[plannedCloseTime intValue]]; //get end time from unix format to a NSDate
    //NSLog(@"Stock TimeStamp: %@",plannedCloseTimeInDate);          
    NSString *plannedCloseTimeAdjusted = [formatter stringFromDate:plannedCloseTimeInDate];
    NSLog(@"Stock plannedCloseTimeAdjusted: %@",plannedCloseTimeAdjusted);    
    //Latest Time
    NSDate *currentDate = [scaleData objectAtIndex:[scaleData count]-1];         
    NSString *currentDateAdjusted = [formatter stringFromDate:currentDate];
    NSLog(@"Stock currentDate and currentDateAdjusted: %@,%@",currentDate,currentDateAdjusted);    
    
    int midDate = [plannedOpenTime intValue] /2 + [plannedCloseTime intValue] /2;
    NSDate *midDateStockOpenClose = [NSDate dateWithTimeIntervalSince1970:midDate]; //get end time from unix format to a NSDate
    NSString *midDateStockOpenCloseAdjusted = [formatter stringFromDate:midDateStockOpenClose]; 
    NSLog(@"Mid Date: %@",midDateStockOpenCloseAdjusted);
    
    //Get difference between open and close times           YYY seconds
    NSTimeInterval secondsBetweenOpenAndClose = [plannedCloseTimeInDate timeIntervalSinceDate:plannedOpenTimeInDate];
    //Get difference between current time and open time     ZZZ seconds  
    NSTimeInterval secondsBetweenOpenAndNow = [currentDate timeIntervalSinceDate:plannedOpenTimeInDate]; //Now means, last data piece received
    //Calc
    float percentageOfDayThatStockDataIsAvailable = secondsBetweenOpenAndNow / secondsBetweenOpenAndClose;    //The percentage of time the market has been open is: ZZZ/YYY. ZZZ>=YYY . :)
    NSLog(@"Time Diffs: %f, %f. Day Percent %.0f",secondsBetweenOpenAndClose,secondsBetweenOpenAndNow,percentageOfDayThatStockDataIsAvailable);
    
    //NSLog(@"Number of items in graphData for %@: %d",[[contentArray objectAtIndex:pageNumber-1] objectForKey:@"Name"],[graphData count]);
    self.sparkline.scaleData =  scaleData;    
    self.sparkline.data      =  graphData;
    self.sparkline.timeZone  =  stockTimeZone;                              //gmtoffset, not actually timezone
    self.sparkline.plannedOpenTimeAdjusted = plannedOpenTimeAdjusted;
    self.sparkline.plannedMidTimeAdjusted = midDateStockOpenCloseAdjusted;
    self.sparkline.plannedCloseTimeAdjusted = plannedCloseTimeAdjusted;     //timestamp, open close time
    self.sparkline.timeFraction = percentageOfDayThatStockDataIsAvailable;

    
    buttonChartRange1D.selected = YES;
    buttonChartRange5D.selected = NO;
    buttonChartRange3M.selected = NO;
    buttonChartRange1M.selected = NO;    
    buttonChartRange6M.selected = NO;
    buttonChartRange1Y.selected = NO;  
}

-(IBAction)chartButton5D:(id)sender{
    NSLog(@"chartButton5D");
    
    [hud.view removeFromSuperview]; //If HUD already shown, remove it.

   // [self highResolutionDataLookup];
    self.sparkline.highResData = 2;
    self.sparkline.chartDays = 5;
    
    NSMutableArray *graphData = [deStockLookupHighResDataFiveDay objectForKey:@"values"];
    NSMutableArray *scaleData = [deStockLookupHighResDataFiveDay objectForKey:@"dates"];
    self.sparkline.scaleData =  scaleData;    
    self.sparkline.data     =   graphData;
    
    buttonChartRange5D.selected = YES;
    buttonChartRange1D.selected = NO;
    buttonChartRange3M.selected = NO;
    buttonChartRange1M.selected = NO;    
    buttonChartRange6M.selected = NO;
    buttonChartRange1Y.selected = NO;  

}


-(IBAction)chartButton1M:(id)sender{
    
        [hud.view removeFromSuperview]; //If HUD already shown, remove it.
    
    NSLog(@"chartButton1M"); 
    
    self.sparkline.highResData = 0;
    self.sparkline.chartDays = 30;
    [self graphSlicer:30];
    
    buttonChartRange1M.selected = YES;
    buttonChartRange1D.selected = NO;
    buttonChartRange5D.selected = NO;
    buttonChartRange3M.selected = NO;   
    buttonChartRange6M.selected = NO;
    buttonChartRange1Y.selected = NO;  

}


-(IBAction)chartButton3M:(id)sender{
    
        [hud.view removeFromSuperview]; //If HUD already shown, remove it.
    NSLog(@"chartButton3M"); 
    
    self.sparkline.highResData = 0;
    self.sparkline.chartDays = 90;
    [self graphSlicer:90];

    buttonChartRange3M.selected = YES;
    buttonChartRange1D.selected = NO;
    buttonChartRange5D.selected = NO;
    buttonChartRange1M.selected = NO;    
    buttonChartRange6M.selected = NO;
    buttonChartRange1Y.selected = NO;  
    
}

-(IBAction)chartButton6M:(id)sender{
    NSLog(@"chartButton6M");   
    
    self.sparkline.highResData = 0;
    self.sparkline.chartDays = 180;
    [self graphSlicer:180];
    
    buttonChartRange6M.selected = YES;
    buttonChartRange1D.selected = NO;
    buttonChartRange5D.selected = NO;
    buttonChartRange3M.selected = NO;
    buttonChartRange1M.selected = NO;    
    buttonChartRange1Y.selected = NO;  

}

-(IBAction)chartButton1Y:(id)sender{
    NSLog(@"chartButton1Y");  
    
    self.sparkline.highResData = 0;
    self.sparkline.chartDays = 365;
    [self graphSlicer:365];
    
    buttonChartRange1Y.selected = YES;
    buttonChartRange1D.selected = NO;
    buttonChartRange5D.selected = NO;
    buttonChartRange3M.selected = NO;
    buttonChartRange1M.selected = NO;    
    buttonChartRange6M.selected = NO;

}

-(void)startActivityIndicator:(NSNotification *) notification {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];  
}

-(void)stopActivityIndicator:(NSNotification *) notification {
    [self localstopActivityIndicator];
}
-(void)localstopActivityIndicator{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}


#pragma mark -
#pragma mark Notes
//This Method Handles the notes view
//notesPosition = 0; //0 is down, 1 means up, 2 means full screen and editing with keyboard
- (IBAction)notesPressed:(id)sender
{
    NSLog(@"Pressed Notes Section notesPosition: %d", notesPosition);  
    
    //adjustment for iPhone5+ Screen Resolution
    CGRect cgRect =[[UIScreen mainScreen] bounds];
    CGSize cgSize = cgRect.size;
    
    
    //If notes not yet ran, add the real notes view, but dont run this code again.
    if (notesFirstRun == 0) {
        [self.view addSubview: notesView];   
        notesView.frame = CGRectMake(0, cgSize.height-20-25, 320, notesView.frame.size.height);
        notesFirstRun = 1;
    }
    
    if (notesPosition == 0) {        
        [UIView beginAnimations:@"Move Notes" context:nil];
        [UIView setAnimationDuration:0.3];
        if (noInternetConnection == 1) {
            //no nothing :) dont move!!!!
            [notesTextArea becomeFirstResponder];
        } else {
            notesView.frame = CGRectMake(0, 245-5, 320, notesView.frame.size.height); 
            notesPosition = 1;  //set bit noting that it is in position 1    
            }
        [UIView commitAnimations];

        
        
    } else if (notesPosition == 1) {
        //move this thing back down        
        [UIView beginAnimations:@"Move Notes" context:nil];
        [UIView setAnimationDuration:0.3];
        notesView.frame = CGRectMake(0, cgSize.height-20-25, 320, notesView.frame.size.height );
        notesPosition = 0;
        [UIView commitAnimations];

        
    } else if (notesPosition == 2) {
 
        //move this thing back down        
        [UIView beginAnimations:@"Move Notes" context:nil];
        [UIView setAnimationDuration:0.5];
        if (noInternetConnection == 1) {
            
                notesView.frame = CGRectMake(0,164, 320, notesView.frame.size.height+200);
        } else  {
                notesView.frame = CGRectMake(0, cgSize.height-20-25, 320, notesView.frame.size.height );
        }
        
        [UIView commitAnimations];
        notesPosition = 0;
        [notesTextArea resignFirstResponder];
        
        //Enable/Disable Mainview Scrolling:
        [[NSNotificationCenter defaultCenter] postNotificationName:@"showNotesView" object:nil];
        
    }
    
    //Save note into content
    NSLog(@"%@", [contentArray objectAtIndex:pageNumber-1]);
    NSLog(@"Saving Note Text: %@",notesTextArea.text);
    [[contentArray objectAtIndex:pageNumber-1] setObject:notesTextArea.text forKey:@"Notes"];
    
}



 //Move Notification Box Down Animation Complete
- (void)animationFinished:(NSString*)animationID finished:(BOOL)finished context:(void *)context {
	[notificationSetTargetPrice becomeFirstResponder];
    stockTargetEditButton.userInteractionEnabled = YES; //Re-Enable. Fixes a small bug
}


- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    
    NSLog(@"Notes Section under editing: %d", notesPosition);  
    [UIView beginAnimations:@"Move Notes" context:nil];
    [UIView setAnimationDuration:0.3];
    notesView.frame = CGRectMake(0, 0, 320, notesView.frame.size.height);
    [UIView commitAnimations];
    notesPosition = 2;
    
    //Disabling Mainview Scrolling:
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showNotesView" object:nil];

    return YES;
    
}


           

/*--------------------------------------------------------------
 * One finger, swipe up
 *-------------------------------------------------------------*/
- (void)oneFingerSwipeUp:(UISwipeGestureRecognizer *)recognizer 
{ 
    CGPoint point = [recognizer locationInView:[self view]];
    NSLog(@"Swipe up - start location: %f,%f", point.x, point.y);
    
    /* 
    //If swipe was around where notes starts (and notes is elevated, reduce it down)    
    if (point.y > notesView.frame.origin.y) {  
        if (noInternetConnection == 0) {
            if (notesPosition == 0) {
                [UIView beginAnimations:@"Move Notes" context:nil];
                [UIView setAnimationDuration:0.3];
                notesView.frame = CGRectMake(0, 240, 320, notesView.frame.size.height); 
                [UIView commitAnimations];
                notesPosition = 1;  //set bit noting that it is in position 1        
            }
        }

    } 
     */
    
    //If swipe was around where notes starts (and notes is elevated, reduce it down)    
    if (point.y > notesView.frame.origin.y) { 
        [self notesPressed:nil];
    }
}

/*--------------------------------------------------------------
 * One finger, swipe down
 *-------------------------------------------------------------*/
- (void)oneFingerSwipeDown:(UISwipeGestureRecognizer *)recognizer 
{ 
    CGPoint point = [recognizer locationInView:[self view]];
    NSLog(@"Swipe down - start location: %f,%f", point.x, point.y);
    
    /*
    //If swipe was around where notes starts (and notes is elevated, reduce it down)
    if (point.y > notesView.frame.origin.y - 30) {      
        if (noInternetConnection == 0) {
            if (notesPosition == 1) {
                //move this thing back down        
                [UIView beginAnimations:@"Move Notes" context:nil];
                [UIView setAnimationDuration:0.3];
                notesView.frame = CGRectMake(0, 436, 320, notesView.frame.size.height);
                [UIView commitAnimations];
                notesPosition = 0;
            }
    }
    }
     
     */
    
    //If swipe was around where notes starts (and notes is elevated, reduce it down)
    if (point.y > notesView.frame.origin.y - 30) {    
            [self notesPressed:nil];
    }
    
}

//==================================================================
#pragma mark -
#pragma mark MTStatusBarOverlay Delegate Methods
//==================================================================

- (void)statusBarOverlayDidHide {
	NSLog(@"Overlay did hide");
}

- (void)statusBarOverlayDidSwitchFromOldMessage:(NSString *)oldMessage toNewMessage:(NSString *)newMessage {
	NSLog(@"Overlay switched from '%@' to '%@'", oldMessage, newMessage);
}

- (void)statusBarOverlayDidClearMessageQueue:(NSArray *)messageQueue {
	NSLog(@"Overlay cleared messages from queue: %@", messageQueue);
}




- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}



@end
