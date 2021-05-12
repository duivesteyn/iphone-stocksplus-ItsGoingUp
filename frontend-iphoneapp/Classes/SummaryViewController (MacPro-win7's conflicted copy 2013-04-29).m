//
//  SummaryViewController.m
//  PageControl
//
//  Created by Ben Duivesteyn on 10.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SummaryViewController.h"
#import "PhoneContentController.h"
#import "UAirship.h"
 //UA// #import "UAViewUtils.h"
 //UA// #import "UAPush.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#include <CFNetwork/CFNetwork.h>
#import <QuartzCore/CoreAnimation.h>
#import <QuartzCore/QuartzCore.h> //For swiping up details
#import "AppDelegate.h"

#import <Twitter/Twitter.h>
#import "NSString+Helpers.h"

#import "Flurry.h"

#import "RootViewController.h"
#import "BSYahooFinance.h"



@implementation SummaryViewController

@synthesize lastAddedDate;

@synthesize contentView = _contentView; //iAd
@synthesize adBannerView = _adBannerView;//iAd
@synthesize bannerIsVisible = _adBannerViewIsVisible;//iAd

#define degreesToRadian(x) (M_PI * (x) / 180.0)

// load the view nib and initialize the pageNumber ivar
- (id)initWithPageNumber:(int)page
{
    NSLog(@"Page Number %d", pageNumber);
    if ((self = [super initWithNibName:@"SummaryView" bundle:nil]))
    {
        NSLog(@"SummaryView Init");
        pageNumber = page;
        
        //   NSLog(@"Pre: lastAddedDate: %@",lastAddedDate);
        NSDate *dateNow         = [NSDate date]; 
        lastAddedDate = [dateNow retain];
        NSLog(@"Init: lastAddedDate: %@",lastAddedDate);
        
        //    NSTimeInterval secondsBetween = [dateNow timeIntervalSinceDate:lastAddedDate];
        //    int secondsbetweenStockAdds = secondsBetween / 1;
        //    NSLog(@"There are %d seconds in between the two times.", secondsbetweenStockAdds);    


    }
    return self;
}

- (void)dealloc
{
  //  [pageNumberLabel release];
  //  [numberTitle release];
  //  [numberImage release];
    
    //iAd
    self.contentView = nil;
    self.adBannerView = nil;
    
    
    _refreshHeaderView = nil;
    [super dealloc];
}

// set the label and background color when the view has finished loading
- (void)viewDidLoad
{
    

    
    NSLog(@"in viewDidLoad SummaryView");
    //Datasetup from appDelegate
	//appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    tableView.backgroundView = nil;
    tableView.backgroundColor = [UIColor clearColor];
    pageNumberLabel.text = [NSString stringWithFormat:@"Page %d", pageNumber + 1];
    
    #if LITE
        NSString *hello = @"Hello, Lite Version!";
        liteEdition = 1;
    #else
        NSString *hello = @"Hello, Full Version!";
        liteEdition = 0;
    #endif
    NSLog(@"%@",hello);
    
    //UI
    CGColorRef darkColor = [[UIColor blackColor] colorWithAlphaComponent:.5f].CGColor;
    CGColorRef lightColor = [UIColor clearColor].CGColor;
    UIView *footerShadow = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 10)];     //Footer shadow
    
    CAGradientLayer *bottomShadow = [[[CAGradientLayer alloc] init] autorelease];
    bottomShadow.frame = CGRectMake(0,-1, self.view.frame.size.width+1, 10);
    bottomShadow.colors = [NSArray arrayWithObjects:(id)darkColor, (id)lightColor, nil];
    footerShadow.alpha = 0.6;
    [footerShadow.layer addSublayer:bottomShadow];
    tableView.tableFooterView = footerShadow;
    
    //Remove Seperator Lines
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    
    //Setup AboutView
    [self.view addSubview:aboutView];
    //aboutView.frame = CGRectMake(0, 460-25, 320, aboutView.frame.size.height);
    //adjusted for iPhone5+
    CGRect cgRect =[[UIScreen mainScreen] bounds];
    CGSize cgSize = cgRect.size;
    aboutView.frame = CGRectMake(0, cgSize.height-20-25, 320, aboutView.frame.size.height);
    
    
    //[aboutScroller addSubview:aboutAndDebugView];
    
    //Setup NSOperationQueue
    operationQueue = [NSOperationQueue new];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(addObject:) name: @"New Stock Added" object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(addLiveDataObject:) name: @"New Live Data" object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(closeApp:) name: @"closeApp" object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNoInternetBar:) name:@"showNoInternetBar" object:nil]; 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideNoInternetBar:) name:@"hideNoInternetBar" object:nil]; 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stockUpdateComplete:) name:@"stockUpdateComplete" object:nil]; 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationCallStocks:) name:@"UpdateStocks" object:nil]; 
    
    NSLog(@"finished viewDidLoad SummaryView");
    
    [MTStatusBarOverlay sharedInstance].historyEnabled = NO;    
    [MTStatusBarOverlay sharedInstance].detailViewMode = NO;
    
    
    //Setting Request - Stock Update Frequency 
    NSString *updateFrequency = [[NSUserDefaults standardUserDefaults] objectForKey:@"updatefrequency_stocks"];
    NSLog(@"Update Frequency Is: %@",updateFrequency);
    if (updateFrequency == nil) {
        updateFrequency = @"60";
        
        //Put default update to 60secs
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        [standardUserDefaults setObject:@"60" forKey:@"updatefrequency_stocks"];
        [standardUserDefaults synchronize];
    }
    
    //SEt a repeating timer
    NSTimer * timer = [NSTimer scheduledTimerWithTimeInterval:[updateFrequency integerValue] target:self selector:@selector(timerCallUpdateStocks) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    
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

-(void)viewWillAppear:(BOOL)animated{
    NSLog(@"in SummaryView viewWillAppear");
    //Get Data Array
	appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	contentArray = [appDelegate sendArray];
    liveDataArray = [appDelegate sendLiveArray];
    //NSLog(@"LIVE DATA: %@",liveDataArray);
    
    //Check Content Array NotificationIDs for empty objects. If empty, give a new one.
    //This is important, as the two default stocks for each user need to have unique IDs
    NSLog(@"viewWillAppear contentArray: %@",contentArray);
    
    if ([contentArray count] > 0) {
        NSString *notificationID = [[contentArray objectAtIndex:0] objectForKey:@"Notification ID"];
        NSLog(@"notificationID: %@",notificationID);
        if ([notificationID length] == 0)    {
            NSString *hexStr = [self genRandStringLength:12];
            [[contentArray objectAtIndex:0] setObject:hexStr forKey:@"Notification ID"];
            NSString *notificationIDUpdated = [[contentArray objectAtIndex:0] objectForKey:@"Notification ID"];        
            NSLog(@"notificationIDUpdated: %@",notificationIDUpdated);
            notificationID = [[contentArray objectAtIndex:0] objectForKey:@"Notification ID"];
            NSLog(@"notificationID: %@",notificationID);
        }
    }
    
    [self becomeFirstResponder];    //for shake to update
    NSLog(@"Finished viewWillAPpear");
    
    
    //Hide Follow Button if requested
    int followbuttondisabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"followbutton"];
    NSLog(@"dataresetQuery: %d",followbuttondisabled);
    if (followbuttondisabled) shareButton.hidden = YES;
    
    
    //If No stocks, add tooltip to add a new stock
    if ([contentArray count] == 0) {
        [self.view addSubview:helpTagNoStocks];
        helpTagNoStocks.frame = CGRectMake(0, 40, 320, 70);
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    } else if (helpTagNoStocks) {
        //if view is defined. remove view.
        [helpTagNoStocks removeFromSuperview];
    }
    
    //Remove Promostuff for full version
    #if LITE
        promoGetFullVersionText.hidden = NO;
    #else
    
    #endif
    
    

}


-(void)viewDidAppear:(BOOL)animated {
    NSLog(@"in viewDidAppear");
    NSLog(@"Page Number %d", pageNumber);
    NSMutableArray *arrayTemp = [appDelegate sendArray];
    NSLog(@"array: %@",arrayTemp);
    
    bannerNotShowing = 1;

   
    //Setup Pull down to refresh
    if (_refreshHeaderView == nil) {
		
		EGORefreshTableHeaderView *pulldownview = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - tableView.bounds.size.height, self.view.frame.size.width+1, tableView.bounds.size.height)];
		pulldownview.delegate = self;
		[tableView addSubview:pulldownview];
		_refreshHeaderView = pulldownview;
		//[view release];
		
	}
    
    // Gesture: Swipe About Field Down
    UISwipeGestureRecognizer *oneFingerSwipeDown = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(oneFingerSwipeDown:)] autorelease];
    [oneFingerSwipeDown setDirection:UISwipeGestureRecognizerDirectionDown];
    [[self view] addGestureRecognizer:oneFingerSwipeDown];
    
    // Gesture: Swipe About Field Up    
    UISwipeGestureRecognizer *oneFingerSwipeUp = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(oneFingerSwipeUp:)] autorelease];
    [oneFingerSwipeUp setDirection:UISwipeGestureRecognizerDirectionUp];
    [[self view] addGestureRecognizer:oneFingerSwipeUp];
    

    

    
    //Send Server UpdatedNotification Set Points (when time permits)
    //NSInvocationOperation *operationNotificationUpdateAndCheck = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(updateNotificationSetPoints) object:nil];
    //[operationQueue addOperation:operationNotificationUpdateAndCheck];     /* Add the operation to the queue */
    //[operationNotificationUpdateAndCheck release];
    
    
    //Send out NSNotification to alert PhoneContentController to PreLoad all pages (instead of doing it before the main summary page loads)
    NSLog(@"Sending Notification to Load additional Views");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadUpAdditionalViews" object:nil];
     NSLog(@"up to here2 ");   
    
    //do this at most every 14 seconds
    [self updateStockData];
    
    [self firstRunMessages];        //One time run messages (JB Warning, etc)
    
    //  update the last update date
	[_refreshHeaderView refreshLastUpdatedDate];
    
    
    //Consider setting up UrbanAirship Stuff Here (after mainview has loaded ok)

    
    //Set About View Version Text
    //NSString * buildNo = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBuildNumber"];
    aboutAppNameLabel.text =  [[NSString stringWithFormat:@"$CFBundleDisplayName $CFBundleVersion"] stringBySubstitutingInfoTokens];    
    //aboutVersionLabel.text =  [[NSString stringWithFormat:@"Stocksplusapp.com $CFBundleVersion b%@",buildNo] stringBySubstitutingInfoTokens];

    //Setting Request - DebugView (This bit not used/finished at all)
    //debugViewOn = [[NSUserDefaults standardUserDefaults] boolForKey:@"debugmode"];
    //NSLog(@"Debug View: %d",debugViewOn);
    //if (debugViewOn ==1) debugViewButton.hidden = NO;

    #if LITE    //The following section 
    
    //Note This works perfect. Ad isnt shown on first load. but is shown on next reload of this view!!!
    NSString *WelcomeShownBefore = [[NSUserDefaults standardUserDefaults] stringForKey:@"WelcomeDismissed"];
    if( [WelcomeShownBefore isEqualToString: @"1"]) [self createAdBannerView];   //Show an iAd. Gotta make some cash :) But don't show it on first launch
    
    #else

    #endif
    
    
    
	
    
}

//currently not used
//-(void)fullVersionDetectedMessage{
//    NSLog(@"Full Version Detected");
//    UIAlertView *fullVersionInstalled = [[UIAlertView alloc] initWithTitle:@"Notice" message:@"Please launch the full version instead of the Lite app." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//    [fullVersionInstalled show];
//    [fullVersionInstalled release];
//}

-(void)firstRunMessages{

    //The following section 
    NSUserDefaults *Def = [NSUserDefaults standardUserDefaults];
    NSString *Ver = [Def stringForKey:@"Version"];
    NSString *CurVer = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
    NSLog(@"Checking First Run Messages - OldVer/CurVer -  %@ %@",Ver,CurVer);
    if(Ver == nil || [Ver compare:CurVer] != 0)
    {
        if(Ver == nil)
        {
            NSLog(@"First Run");
            //Run One Time Only Section
            
            
            NSLog(@"Showing Welcome Screen");
            [self.view addSubview:welcomeView];   

        }
        
        //Run once-per-upgrade code, if any
        [Def setObject:CurVer forKey:@"Version"];

        
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self resignFirstResponder];    //This is for Shake to Update
    [super viewWillDisappear:animated];
}



     

#pragma mark -
#pragma mark Update Stocks

-(void)timerCallUpdateStocks{
    NSLog(@"-----Timer Executed-----");
    [self updateStockData];
}

-(void)notificationCallStocks:(NSNotification *) notification {
    
    [self updateStockData];
}


-(void)updateStockData {
    
    //Register Last Update Time
    now = [NSDate date];
    
    NSLog(@"SummaryViewController: updateStockData");
    NSLog(@"noInternetConnection check: %d",noInternetConnection);
    if (noInternetConnection==0) {
        
        //Start Activity Indicators
        [[NSNotificationCenter defaultCenter] postNotificationName:@"startActivityIndicator" object:nil];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
        //Request Stock Update (goes to each MyViewController)
        [[NSNotificationCenter defaultCenter] postNotificationName:@"stockUpdate" object:nil];

       
        //Send local message
        if (bannerNotShowing){
            [[MTStatusBarOverlay sharedInstance] postMessage:@"Updating Stocks..."];
            [self performSelector:@selector(changeTextAnimatedFinish) withObject:nil afterDelay:2];  
        }

        
    } else  {
        //no internet!!!
    }

}

- (void)changeTextAnimated:(NSString *)text {
    [[MTStatusBarOverlay sharedInstance] postMessage:text animated:YES];
}

- (void)changeTextAnimatedFinish {
    [[MTStatusBarOverlay sharedInstance] hide];
}

-(void)stockUpdateComplete:(NSNotification *) notification{
    //stockUpdateComplete
    NSLog(@"in stockUpdateComplete");
    
    [tableView reloadData];
}

-(void)updateStockDataFinished{
    
    //NOtify Anything???
     [[MTStatusBarOverlay sharedInstance] hide];
    
    //Stop Activity Indicator
 //   [[NSNotificationCenter defaultCenter] postNotificationName:@"stopActivityIndicator" object:nil];    //UI ActivityIndicator
 //   [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];                            //UI ActivityIndicator
}






#pragma mark -
#pragma mark Data management


-(void)addObject: (NSNotification*)notification {
	NSLog(@"Adding New Object");

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *lastAddedStock = [prefs stringForKey:@"LastAddedStock"];
    NSLog(@"LastAddedStock: %@",lastAddedStock);
    NSLog(@"notification object: %@",[notification object]);
    NSString *newlyAddedStock = [[notification object] objectForKey:@"Symbol"];
    
    //Do this only 1 time in a row 
    if (![newlyAddedStock isEqualToString:lastAddedStock ]) {
        
    NSLog(@"Most recent added stock is unique: %@, %@",newlyAddedStock,lastAddedStock);
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setObject:newlyAddedStock forKey:@"LastAddedStock"];
        [prefs synchronize];



        //Add Object to content Array
        [contentArray addObject:[notification object]];
        
        //Reload SummaryViewController
        [tableView reloadData];       //do not enable this line. causes a bug!!! multiple adds
        
        //Send Notification to update views!! gjordt pa lor 24. mars
        [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadScrollView" object:nil];
    }



	
}

-(void)addLiveDataObject: (NSNotification*)notification {
	NSLog(@"SummaryViewController:addLiveDataObject - Adding Live Data");

    //Package up nicely with symbol    
    NSMutableDictionary *liveDataEncapsulated = [notification object];
    [liveDataArray setObject:[liveDataEncapsulated objectForKey:@"Data"] forKey:[liveDataEncapsulated objectForKey:@"StockName"]];

	//NSLog(@"liveDataArray: %@",liveDataArray);
    
}


-(void)closeApp: (NSNotification*)notification {
	
	NSLog(@"in closeApp");

	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *pathContentArray2 = [documentsDirectory stringByAppendingPathComponent:@"LiveData.plist"];
	[liveDataArray writeToFile:pathContentArray2 atomically:YES];
     NSLog(@"Saved Live DAta to LiveData.plist");
    
    //Save clientData array to plist for future use
	NSString *pathContentArray = [documentsDirectory stringByAppendingPathComponent:@"Stocks.plist"];
    NSLog(@"contentArray: %@",contentArray);
	[contentArray writeToFile:pathContentArray atomically:YES];
    NSLog(@"Saved ContentArray to Stocks.plist");
    

}





#pragma mark -
#pragma mark Table view datasource and delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

//- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	//return @"Some footer text";
//}



- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    //Hide About View if shown
    NSLog(@"Hiding About View - Scrolling");
    [self hideAboutView];
    
     
}


- (NSInteger)tableView:(UITableView *)tableview numberOfRowsInSection:(NSInteger)section {

    NSLog(@"numberOfRowsinSection: %d",[contentArray count]);
	return [contentArray count];

}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


- (void)tableView:(UITableView *)tableView  moveRowAtIndexPath:(NSIndexPath *)fromIndexPath 
      toIndexPath:(NSIndexPath *)toIndexPath 
{
    NSLog(@"move from:%d to:%d", fromIndexPath.row, toIndexPath.row);


}

// Override to prevent indentation of cells in editing mode (in theory)
- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

// Select the editing style of each cell
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Do not allow inserts / deletes

    return UITableViewCellEditingStyleDelete;
}



// Ability to Delete a Stock
- (void)tableView:(UITableView *)aTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
	//Deleting Row
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
		NSLog(@"Deleting Row at Index %d",indexPath.row);
		[contentArray  removeObjectAtIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		
        //[tableView setEditing:0 animated:YES];  //Stop Editing
        //  //      addButton.enabled = YES;
        
        //Send Notification to update views!! gjordt pa lor 24. mars
        [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadScrollView" object:[NSArray arrayWithObject:indexPath]];
        
		
    }
}



- (UITableViewCell *)tableView:(UITableView *)tableview cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    
	static NSString *MyIdentifier = @"MyIdentifier";
	
	// Try to retrieve from the table view a now-unused cell with the given identifier.
	UITableViewCell *cell = [tableview dequeueReusableCellWithIdentifier:MyIdentifier];
	
	// If no cell is available, create a new one using the given identifier.
	if (cell == nil) {
		// Use the default cell style.
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:MyIdentifier] autorelease];

        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.editingAccessoryType = UITableViewCellAccessoryNone;
        
        //Cell Selection Color
        UIView *bgColorView = [[UIView alloc] init];
        [bgColorView setBackgroundColor:[UIColor colorWithRed:(0.356) green:(0.356) blue:(0.356) alpha:1]];
        [cell setSelectedBackgroundView:bgColorView];
        [bgColorView release];
        
        
        //Indentation Code.
		cell.indentationLevel = 1;
		cell.indentationWidth = 10;

        
        //Cell Icon		
		CGRect frame; frame.origin.x = 5; frame.origin.y = 5; frame.size.height = 32; frame.size.width = 32;
		UIImageView *imgLabel = [[UIImageView alloc] initWithFrame:frame];
		imgLabel.tag = 1000;
		[cell.contentView addSubview:imgLabel];
		[imgLabel release];
        

        //Label - Stock Value
		UILabel *labelStockPrice = [[UILabel alloc] initWithFrame:CGRectMake(190, 11, 105, 40)];
        labelStockPrice.backgroundColor = [UIColor clearColor];
        labelStockPrice.font = [UIFont boldSystemFontOfSize:20];
		labelStockPrice.tag = 101;
        labelStockPrice.textAlignment = UITextAlignmentRight;
		[cell.contentView addSubview:labelStockPrice];
        labelStockPrice.highlightedTextColor = [UIColor whiteColor];
        labelStockPrice.AutoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin);
		[labelStockPrice release];

        //Label - Stock Change
		UILabel *labelStockPriceChange = [[UILabel alloc] initWithFrame:CGRectMake(labelStockPrice.frame.origin.x-50, 40, labelStockPrice.frame.size.width+50, 20)];
        labelStockPriceChange.backgroundColor = [UIColor clearColor];
        labelStockPriceChange.font = [UIFont systemFontOfSize:14];
        labelStockPriceChange.textColor = [UIColor grayColor];
        labelStockPriceChange.textAlignment = UITextAlignmentRight;
		labelStockPriceChange.tag = 102;
        labelStockPriceChange.highlightedTextColor = [UIColor whiteColor];
		[cell.contentView addSubview:labelStockPriceChange];
        labelStockPriceChange.AutoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin);
		[labelStockPriceChange release];
        
        //Cell UI 
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tableview_cell_bg.png"]];
   
        //Cell UI - Corner Green Triangle (Notification Hit)
        UIImageView * corner = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width-24, 0, 24 , 24)];

        corner.tag = 103;
        [cell.contentView addSubview:corner];
        [corner release];
        
	}
    
    //NumberFormatting
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormatter setMaximumFractionDigits:2];  
    [numberFormatter setMinimumFractionDigits:2]; 
    [numberFormatter setLocale:[NSLocale currentLocale]];
    
    //Cell Contents	
    //Stock Name
    cell.textLabel.text = [[contentArray objectAtIndex:indexPath.row] objectForKey:@"Name"] ;
    
    //Stock Symbol
    cell.detailTextLabel.text = [[contentArray objectAtIndex:indexPath.row] objectForKey:@"Symbol"] ;

    
    //Stock Price Cells
    UILabel *stockPrice = (UILabel *)[cell viewWithTag:101];
    UILabel *stockPriceChange = (UILabel *)[cell viewWithTag:102];
    NSDecimalNumber *stock2 = [[liveDataArray objectForKey:[[contentArray objectAtIndex:indexPath.row] objectForKey:@"Symbol"]] objectForKey:@"Last"];
    NSDecimalNumber *change2 = [[liveDataArray objectForKey:[[contentArray objectAtIndex:indexPath.row] objectForKey:@"Symbol"]] objectForKey:@"Change"];
    
    float relativeChange = [change2 floatValue] / [stock2 floatValue];
    
    
    if ([liveDataArray objectForKey:[[contentArray objectAtIndex:indexPath.row] objectForKey:@"Symbol"]]) {

        //Set Stock Price Label
        NSString *stockPriceLast = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:[stock2 floatValue]]];
        stockPrice.text = [NSString stringWithFormat:@"%@",stockPriceLast];
    
        //Set Stock change // Percentage Change
        NSString *formattedOutputpart1 = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:[change2 floatValue]]];
        [numberFormatter setNumberStyle:NSNumberFormatterPercentStyle];
        NSString *formattedOutput = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:relativeChange]];
        
        if ([change2 floatValue]>=0) {
            stockPriceChange.text = [NSString stringWithFormat:@"+%@ (+%@)",formattedOutputpart1,formattedOutput];       
        } else  
            stockPriceChange.text = [NSString stringWithFormat:@"%@ (%@)",formattedOutputpart1,formattedOutput];   
        
    } else {
        stockPrice.text = @"";
        stockPriceChange.text = @"";
    }
    
	//If Stock is Currently over Target, Insert the corner green arrow
    if ([stock2 floatValue] >= [[[contentArray objectAtIndex:indexPath.row] objectForKey:@"Target Price"] floatValue]) {
        NSLog(@"Current Price (%f) is Greater than Target (%f) - Adding Green Corner Triangle",[stock2 floatValue],[[[contentArray objectAtIndex:indexPath.row] objectForKey:@"Target Price"] floatValue]);

        UIImageView *corner = (UIImageView *)[cell viewWithTag:103];  
        UIImageView *cornerView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"img-tableviewrow-corner-targethit.png"]];
        [corner addSubview:cornerView];
    }
    

	return cell;
}
                                      
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
   [[cell textLabel] setBackgroundColor:[UIColor clearColor]];
   [[cell detailTextLabel] setBackgroundColor:[UIColor clearColor]];
}

- (void)tableView:(UITableView *)thetableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    //Keep track of the row selected.
	selectedIndexPath = indexPath;
    NSLog(@"Pressed row at indexpath %d",indexPath.row);
    
    //Send Notification to Scroll (left/right :) )
    NSLog(@"Sending Notification to Load additional Views");
    NSDictionary* dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:indexPath.row] forKey:@"index"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"scrollLeft" object:self userInfo:dict];
    
    [thetableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	//if (indexPath.row>2) return 90; else return 40;
    return 80;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animate{
        NSLog(@"Now here Edit");    

}

-(IBAction)didPressAdd{
    
    NSLog(@"Pressed Add");    
    
    if (liteEdition ==1 && [contentArray count] >= 3) {     //lite Edition Limit of 3!!!
        NSLog(@"Hit Stock Limit");
        [self promoGetFullVersionPressed:@"3limit"];
        
        //Flurry (has hit stock limit)
        [Flurry logEvent:@"Lite - Hit Stock Limit"];
        
    } else  {
        RootViewController *tbvc2 = [[RootViewController alloc] initWithNibName:@"RootViewController" bundle:nil];
        UINavigationController *controller = [[UINavigationController alloc] initWithRootViewController:tbvc2];
        [self presentModalViewController:controller animated:YES];    
        
        //Disabling Mainview Scrolling:
        [[NSNotificationCenter defaultCenter] postNotificationName:@"showNotesView" object:nil];
    }

}
    

-(IBAction)didPressEdit{

     NSLog(@"Pressed Edit");   
	//[super setEditing:editing animated:animated];
   // [tableView setEditing:editing animated:YES];
    if (tableView.editing) {
        //editButton.i
        //editButton.style = UIBarButtonItemStyleDone;
        [tableView setEditing:0 animated:YES];
    } else  {
        [tableView setEditing:1 animated:YES];   
    }
   
	
	//Do not let the user add if the app is in edit mode.
	if (tableView.editing) {
		addButton.enabled = NO;
    } else addButton.enabled = YES;
    


}




-(IBAction)didPressSettings{
    NSLog(@"Pressed Settings");   

}

-(IBAction)showAndHideAboutView:(id)sender{
    
    //adjustment for iPhone5+ Screen Resolution
    CGRect cgRect =[[UIScreen mainScreen] bounds];
    CGSize cgSize = cgRect.size;
    
    if (aboutView.frame.origin.y >= cgSize.height-20-25) {
        [UIView beginAnimations:@"Move IN About Data" context:nil];
        [UIView setAnimationDuration:0.3];
        aboutView.frame = CGRectMake(0, cgSize.height-20-aboutView.frame.size.height, 320, aboutView.frame.size.height);
        
        CGAffineTransform landscapeTransform = CGAffineTransformMakeRotation(degreesToRadian(180));
        [showArrow setTransform:landscapeTransform];
        
        [UIView commitAnimations];
    } else  {
        [self hideAboutView];
    }
    
}

- (IBAction)showAboutView:(id)sender{
        NSLog(@"Pressed Elevator Button - Sliding in About View");   

    //adjustment for iPhone5+ Screen Resolution
    CGRect cgRect =[[UIScreen mainScreen] bounds];
    CGSize cgSize = cgRect.size;
    
    
    if (aboutView.frame.origin.y >= cgSize.height-20-25) {
        [UIView beginAnimations:@"Move IN About Data" context:nil];
        [UIView setAnimationDuration:0.3];
        aboutView.frame = CGRectMake(0, cgSize.height-20-aboutView.frame.size.height, 320, aboutView.frame.size.height);

        CGAffineTransform landscapeTransform = CGAffineTransformMakeRotation(degreesToRadian(180));
        [showArrow setTransform:landscapeTransform];

        [UIView commitAnimations];
            
        //Also update stocks
        //[self updateStockData];
    } else  {
        [self hideAboutView];
    }
    
    
    
}


-(void)hideAboutView{
    
    //adjustment for iPhone5+ Screen Resolution
    CGRect cgRect =[[UIScreen mainScreen] bounds];
    CGSize cgSize = cgRect.size;
       
    NSLog(@"Hiding About View - Scrolling");
    if (aboutView.frame.origin.y < cgSize.height-20-25) {
        [UIView beginAnimations:@"Move Out About Data" context:nil];
        [UIView setAnimationDuration:0.3];
        aboutView.frame = CGRectMake(0, cgSize.height-20-25, 320, aboutView.frame.size.height);
        
        CGAffineTransform landscapeTransform = CGAffineTransformMakeRotation(degreesToRadian(0));
        [showArrow setTransform:landscapeTransform];
        [UIView commitAnimations];
    }
}



- (IBAction)showDebugView:(id)sender{

    BOOL doesContain;
    doesContain = [aboutView.subviews containsObject:debugView];
    
    if (doesContain) {
        [debugView removeFromSuperview];
    } else {
        
    [aboutView addSubview:debugView];
    debugView.frame = CGRectMake(0, 26, 320, 69);
    }
    
}

#pragma mark -
#pragma mark Shake To Update
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if ( event.subtype == UIEventSubtypeMotionShake )
    {
        // Put in code here to handle shake
        NSLog(@"Shake Detected.");
        [self updateStockData];
    }
    
    if ( [super respondsToSelector:@selector(motionEnded:withEvent:)] )
        [super motionEnded:motion withEvent:event];
}

- (BOOL)canBecomeFirstResponder
{ return YES; }



#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

//Pull down to refresh
- (void)reloadTableViewDataSource{
	
	//  should be calling your tableviews data source model to reload
	//  put here just for demo
	_reloading = YES;
    
    [self updateStockData];
	
}

- (void)doneLoadingTableViewData{
	
	//  model should call this when its done loading
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:tableView];
	
}

#pragma mark -
#pragma mark About Page - Email Web Twitter, Support
- (IBAction)browserCallToAction{
    NSLog(@"browser Call to Action");
    
    //Flurry
    [Flurry logEvent:@"Pressed Browser Button"];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://www.stocksplusapp.com/?ref=inApp"]];
}


- (IBAction)twitterCallToAction{
    NSLog(@"twitter Call to Action");
    
    //Flurry
    [Flurry logEvent:@"Pressed Tweet Button"];
    
    // Create the view controller
    TWTweetComposeViewController *twitter = [[TWTweetComposeViewController alloc] init];
    
    // Optional: set an image, url and initial text
    //[twitter addImage:[UIImage imageNamed:@"iOSDevTips.png"]];
    [twitter addURL:[NSURL URLWithString:[NSString stringWithString:@"http://stocksplusapp.com"]]];
    [twitter setInitialText:@"Hi @stocksplus "];
    
    // Show the controller
    [self presentModalViewController:twitter animated:YES];
    
    // Called when the tweet dialog has been closed
    twitter.completionHandler = ^(TWTweetComposeViewControllerResult result) 
    {
        //  NSString *title = @"Tweet Status";
        NSString *msg; 
        
        if (result == TWTweetComposeViewControllerResultCancelled)
            msg = @"Tweet compostion was canceled.";
        else if (result == TWTweetComposeViewControllerResultDone)
            msg = @"Tweet composition completed.";
        
        // Show alert to see how things went...
        //UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        //[alertView show];
        //NSLog("@Twitter Module: %@",msg);
        // Dismiss the controller
        [self dismissModalViewControllerAnimated:YES];
    };
}

- (IBAction)facebookCallToAction{
    NSLog(@"Facebook Call to Action");
    
    //Flurry
    [Flurry logEvent:@"Pressed Facebook Button"];
    
    //Open FB
    NSURL *url = [NSURL URLWithString:@"fb://profile/StocksPlus"];
    [[UIApplication sharedApplication] openURL:url];
}

-(IBAction)twitterFollow:(id)sender{
    //Show twitter follow
    
    //Flurry
    [Flurry logEvent:@"Pressed Twitter Follow"];

    
    [self openTwitterAppForFollowingUser:@"stocksplus"];
    
    
}

//MEthod from : www.cocoanetics.com/2010/02/making-a-follow-us-on-twitter-button/
- (void) openTwitterAppForFollowingUser:(NSString *)twitterUserName
{
	UIApplication *app = [UIApplication sharedApplication];
    
    // Tweetbot:  tapbots.com/blog/development/tweetbot-url-scheme
	NSURL *tweetbotURL = [NSURL URLWithString:[NSString stringWithFormat:@"tweetbot:///user_profile/%@", twitterUserName]];
	if ([app canOpenURL:tweetbotURL])
	{
		[app openURL:tweetbotURL];
		return;
    }
    // TwitterOfficial: 
	NSURL *twitterOfficialURL = [NSURL URLWithString:[NSString stringWithFormat:@"twitter://user?screen_name=%@", twitterUserName]];
	if ([app canOpenURL:twitterOfficialURL])
	{
		[app openURL:twitterOfficialURL];
		return;
	}
    // Tweetie: http://developer.atebits.com/tweetie-iphone/protocol-reference/
	NSURL *tweetieURL = [NSURL URLWithString:[NSString stringWithFormat:@"tweetie://user?screen_name=%@", twitterUserName]];
	if ([app canOpenURL:tweetieURL])
	{
		[app openURL:tweetieURL];
		return;
	}
    
    // Echofon: http://echofon.com/twitter/iphone/guide.html
	NSURL *echofonURL = [NSURL URLWithString:[NSString stringWithFormat:@"echofon:///user_timeline?%@", twitterUserName]];
	if ([app canOpenURL:echofonURL])
	{
		[app openURL:echofonURL];
		return;
	}
    
	// --- Fallback: Mobile Twitter in Safari
	NSURL *safariURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://mobile.twitter.com/%@", twitterUserName]];
	[app openURL:safariURL];
}




- (IBAction)presentEmailFeedback{
    
    //Flurry
    [Flurry logEvent:@"Pressed Email Button"];
    
	// This sample can run on devices running iPhone OS 2.0 or later  
	// The MFMailComposeViewController class is only available in iPhone OS 3.0 or later. 
	// So, we must verify the existence of the above class and provide a workaround for devices running 
	// earlier versions of the iPhone OS. 
	// We display an email composition interface if MFMailComposeViewController exists and the device can send emails.
	// We launch the Mail application on the device, otherwise.
	
	Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
	if (mailClass != nil)
	{
		// We must always check whether the current device is configured for sending emails
		if ([mailClass canSendMail])
		{
			[self displayComposerSheetFeedback];
		}
		else
		{
			[self launchMailAppOnDevice];
		}
	}
	else
	{
		[self launchMailAppOnDevice];
	}
    
}

#pragma mark Feedback Email

-(void)displayComposerSheetFeedback 
{
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
	
#if LITE
    [picker setSubject:@"Stocks+ Lite Feedback"];
#else
    [picker setSubject:@"Stocks+ Feedback"];
#endif
	
	
	
	// Set up recipients
	NSArray *toRecipients = [NSArray arrayWithObject:@"stocksplus@norgeapps.com"]; 
    
	[picker setToRecipients:toRecipients];
	
	
    
	// Fill out the email body text
	NSString *emailBody = @"Your Feedback Here";
	[picker setMessageBody:emailBody isHTML:NO];
	
	[self presentModalViewController:picker animated:YES];
    [picker release];
}


// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
	//message.hidden = NO;
	
	// Notifies users about errors associated with the interface
	switch (result)
	{
		case MFMailComposeResultCancelled:
			NSLog(@"Result: canceled");
			break;
		case MFMailComposeResultSaved:
			NSLog(@"Result: saved");
			break;
		case MFMailComposeResultSent:
			NSLog(@"Result: sent");
			break;
		case MFMailComposeResultFailed:
			NSLog(@"Result: failed");
			break;
		default:
			NSLog(@"Result: not sent");
			break;
	}
	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Workaround

// Launches the Mail application on the device.
-(void)launchMailAppOnDevice
{
	NSString *recipients = @"mailto:stocksplus@norgeapps.com&subject= Stocks+ Feedback";
	NSString *body = @"&body=Insert Feedback Here";
	
	NSString *email = [NSString stringWithFormat:@"%@%@", recipients, body];
	email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
}

#pragma mark -
#pragma mark NoInternet Bar
-(void)showNoInternetBar:(NSNotification *) notification {   

    NSLog(@"in showNoInternetBar");
        
    noInternetConnection = 1;
    
    addButton.enabled = NO;
    editButton.enabled = NO;
    
    noInternetBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 24)];     //Footer shadow
    [noInternetBar addSubview:noInternetView];
    tableView.tableHeaderView = noInternetBar;
    
    [[MTStatusBarOverlay sharedInstance] hide];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"stopActivityIndicator" object:nil];    //UI ActivityIndicator
    
    //Scroll to top
    [tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}

-(void)hideNoInternetBar:(NSNotification *) notification {   
    
    NSLog(@"in hideNoInternetBar");
    
    noInternetConnection = 0;
    
    addButton.enabled  = YES;
    editButton.enabled = YES;   
    
    [noInternetBar removeFromSuperview];
    tableView.tableHeaderView = nil;
    [tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];    //Scroll to top

    
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



//-----------------

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{	
	
	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
	
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	
	[self reloadTableViewDataSource];
	[self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:3.0];
	
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	
	return _reloading; // should return if data source model is reloading
	
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	
	return [NSDate date]; // should return date data source was last changed
	
}

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	_refreshHeaderView=nil;
}

/*--------------------------------------------------------------
 * One finger, swipe down
 *-------------------------------------------------------------*/
- (void)oneFingerSwipeDown:(UISwipeGestureRecognizer *)recognizer 
{ 
    CGPoint point = [recognizer locationInView:[self view]];
    NSLog(@"Swipe down - start location: %f,%f", point.x, point.y);
    
    //If swipe was around where notes starts (and notes is elevated, reduce it down)
    if (point.y > aboutView.frame.origin.y - 30) [self showAboutView:nil];
    

}


/*--------------------------------------------------------------
 * One finger, swipe up
 *-------------------------------------------------------------*/
- (void)oneFingerSwipeUp:(UISwipeGestureRecognizer *)recognizer 
{ 
    CGPoint point = [recognizer locationInView:[self view]];
    NSLog(@"Swipe up - start location: %f,%f", point.x, point.y);

    if (point.y > aboutView.frame.origin.y) [self showAboutView:nil];

}
#pragma mark -
#pragma mark Promo

-(IBAction)promoGetFullVersionPressed:(id)sender{
    
    //Flurry
    [Flurry logEvent:@"Lite - Get Full Version Pressed"];
    
    NSLog(@"getFullVersionPressed");
    if (sender == @"3limit") {
        NSLog(@"ack. 3 stock limit!");
        promothreeView.hidden = NO;
        promothreeLabel.hidden = NO;
    }

    
    promoGetAppView.alpha = 0;
    [self.view addSubview:promoGetAppView];    
    [UIView animateWithDuration:1.0 delay:0.0 options: UIViewAnimationCurveEaseIn animations:^{promoGetAppView.alpha = 1.0;} completion:nil];
    
    

    promoGetAppView.frame = CGRectMake(0, 0, 320, promoGetAppView.frame.size.height); 
    
   
    
    //Disable Navigationbar

    
}

-(IBAction)promoDownloadFull:(id)sender{
    
    //Flurry
    [Flurry logEvent:@"Lite - Sent to Appstore"];
    
    NSLog(@"in promoDownloadFull - Go to the appstore! Monetization!"); 
    //see http://stackoverflow.com/questions/433907/how-to-link-to-apps-on-the-app-store 
    
    //otherwise use:http://itunes.apple.com/us/app/ocarina/id293053479?mt=8
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms://itunes.com/apps/stocksplus"]];
    
}


-(IBAction)promoClose:(id)sender{
     NSLog(@"promoClose"); 
    
    //Flurry
    [Flurry logEvent:@"Lite - Promo View Closed"];
    
        [UIView animateWithDuration:1.0 delay:0.0 options: UIViewAnimationCurveEaseOut animations:^{promoGetAppView.alpha = 0.0;} completion:^(BOOL finished){ 
            [promoGetAppView removeFromSuperview];
            promothreeView.hidden = YES;
            promothreeLabel.hidden = YES;
        } ];

}

#pragma mark -
#pragma mark iAd

- (void)bannerViewDidLoadAd:(ADBannerView *)banner 
{ 
    if (!self.bannerIsVisible) 
    { 
        [UIView beginAnimations:@"animateAdBannerOn" context:NULL]; 
        // Assumes the banner view is just off the bottom of the screen. 
      //  banner.frame = CGRectOffset(banner.frame, 0, -banner.frame.size.height+25); 
        banner.frame = CGRectMake(0, self.view.frame.size.height-50-25, 320, 50);
        [UIView commitAnimations]; 
        self.bannerIsVisible = YES; 
    } 
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    if (self.bannerIsVisible)
    {
        [UIView beginAnimations:@"animateAdBannerOff" context:NULL];
        // Assumes the banner view is placed at the bottom of the screen.
        banner.frame = CGRectOffset(banner.frame, 0, banner.frame.size.height);
        [UIView commitAnimations];
        self.bannerIsVisible = NO;
    }
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    NSLog(@"Banner view is beginning an ad action");
    
    bannerNotShowing = 0;
    
    if (willLeave)
    {
        // insert code here to suspend any services that might conflict with the advertisement
    }
    return 1;
}

- (void)createAdBannerView {
    Class classAdBannerView = NSClassFromString(@"ADBannerView");
    if (classAdBannerView != nil) {
        self.adBannerView = [[[classAdBannerView alloc] initWithFrame:CGRectZero] autorelease];
        [_adBannerView setDelegate:self];
        
        [self.view addSubview:_adBannerView ];  
        [self.view bringSubviewToFront:aboutView];
        [_adBannerView setFrame:CGRectMake(0, self.view.frame.size.height, 320, 50)]; // somewhere offscreen, in the direction you want it to appear from
  
        
    }
}

//Welcome
-(IBAction)hideWelcomeScreen:(id)sender{
    NSLog(@"made it to IBAction - hideWelcomeScreen");

    //The following section 
    [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"WelcomeDismissed"];    

    [UIView animateWithDuration:1.0 delay:0.0 options: UIViewAnimationCurveEaseOut animations:^{welcomeView.alpha = 0.0;} completion:^(BOOL finished){ 
        [welcomeView removeFromSuperview];
        welcomeView.hidden = YES;
    } ];
}

@end


