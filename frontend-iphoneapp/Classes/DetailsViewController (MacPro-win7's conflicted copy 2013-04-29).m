//
//  Created by Björn Sållarp on 2011-03-27.
//  NO Copyright 2010 MightyLittle Industries. NO rights reserved.
// 
//  Use this code any way you like. If you do like it, please
//  link to my blog and/or write a friendly comment. Thank you!
//
//  Read my blog @ http://blog.sallarp.com
//

#import "DetailsViewController.h"
#import "Flurry.h"


@interface DetailsViewController()
@property (nonatomic, retain) YFStockDetailsLoader *detailsLoader;
@property (nonatomic, retain) NSArray *detailKeys;
@end

@implementation DetailsViewController
@synthesize stockDetails;
@synthesize stockSymbol;
@synthesize detailsLoader;
@synthesize detailKeys;


#pragma mark - View lifecycle

- (void)viewDidLoad
{

    [super viewDidLoad];
    currentPriceLabel.text = @""; //clear this
}

-(void)viewWillAppear:(BOOL)animated{
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    ownedStockOptionsView.alpha = 0; //hide this section initially
    
    self.title = self.stockSymbol.symbol;
    self.detailsLoader = [YFStockDetailsLoader loaderWithDelegate:self];
    [self.detailsLoader loadDetails:self.stockSymbol.symbol];
    
    stockTargetPrice.keyboardType=UIKeyboardTypeDecimalPad;    //I want a decimal place in the keyboard
    stockBuyPrice.keyboardType=UIKeyboardTypeDecimalPad;    //I want a decimal place in the keyboar
    stockTicker.text = self.stockSymbol.symbol;
    
    //stockDisplayName.text = self.stockSymbol.name;
    //Shorten TExt if stockname is longer than 20chars
    if ([self.stockSymbol.name length]>20) {
        NSMutableString *string1 = [NSMutableString stringWithString: self.stockSymbol.name];
        NSString *string2;
        string2 = [string1 substringWithRange: NSMakeRange (0, 20)];
        
        NSLog (@"string2 = %@", string2);
        stockDisplayName.text = string2;
    } else {
        stockDisplayName.text = self.stockSymbol.name;
    }
    
    
    
    addedStockYet = 0;  //only add 1 stock at a time

       
}

- (void)viewDidAppear:(BOOL)animated
{

    [stockTargetPrice becomeFirstResponder];
    
    //Default for Stock Adding (do you want Notifications on by Default?)
    notificationsOn = 0;
    NSLog(@"viewDidAppear - Are Notifications set on by default? : %@",notificationsOn);
    
    
}


-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSLog(@"in shouldChangeCharactersInRange");
    
    if([string length]==0) return YES;
    
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




-(BOOL)textFieldShouldReturn:(UITextField*)textField;
{
    NSLog(@"in textFieldShouldReturn");
    NSInteger nextTag = textField.tag + 1;
    // Try to find next responder
    UIResponder* nextResponder = [textField.superview viewWithTag:nextTag];
    if (nextResponder) {
        // Found next responder, so set it.
        [nextResponder becomeFirstResponder];
    } else {
        // Not found, so remove keyboard.
        [textField resignFirstResponder];
    }
    return NO; // We do not want UITextField to insert line-breaks.
}


-(IBAction)done{
    
    
    NSLog(@"clicked done");
    
    //Toggle Mainview Scrolling:
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showNotesView" object:nil];
    

    //Setting Request - Notification Default Status - notificationsOn   //Removed in 1.5. Dont want stock notifications on by default
    //notificationsOn = [[NSUserDefaults standardUserDefaults] stringForKey:@"addstock_notification"];
    //NSLog(@"Notification Should be set on default: %@",notificationsOn);
    
    
    if ([stockTicker.text length] == 0) {
        //Alert Please add ticker and target price
        NSLog(@"No Ticker Inserted");
        UIAlertView *alert1 = [[UIAlertView alloc] initWithTitle:@"Enter Symbol" message:@"Please enter a Stock Symbol  \n (Yahoo! Format)." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert1 show];
        [alert1 release];
        
    } else if ([stockTargetPrice.text length] == 0) {
        UIAlertView *alert2 = [[UIAlertView alloc] initWithTitle:@"Enter Target Price" message:@"Please enter a Target Price for the stock." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert2 show];
        [alert2 release];
    } else 	{
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSString *lastAddedStock = [prefs stringForKey:@"LastAddedStock"];
        
        if (![lastAddedStock isEqualToString:stockTicker.text ]) {

            //NSLog(@"Most recent added stock is unique: %@, %@",lastAddedStock,stockTicker.text);
            
            if ([stockUnitsOwned.text length] == 0) {
                stockUnitsOwned.text = @"0";
                stockBuyPrice.text = @"0";
            }
            
            if ([notificationsOn isEqualToString:@"YES"]) notificationStr = @"1"; else notificationStr = @"0";      //updated in 1.5 to have default as OFF

            //Generate a Unique Notification ID for Serverside Notification Handling
            NSString *notificationID = [self genRandStringLength:12];
            
            //New Stock Dict Creation (must conform to current standard. "Buy Price"/Name/Notes/Notification/Symbol/"Target Price"/Units (updated in 1.5/Jan 2013 to include Above/Below/Repeats)

            NSMutableDictionary *dict1 = [[NSMutableDictionary alloc] initWithObjectsAndKeys:stockTicker.text, @"Symbol", stockTargetPrice.text, @"Target Price", stockBuyPrice.text, @"Buy Price", stockUnitsOwned.text, @"Units",notificationStr, @"Notification",stockDisplayName.text, @"Name", @"", @"Notes",notificationID, @"Notification ID", @"A", @"AboveOrBelow", @"No", @"Repeat Frequency", nil];
        
            //LiveData from Lookup
            NSMutableDictionary *liveData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:stockLiveChange, @"Change", stockLiveBid, @"Last", stockLiveVolume, @"Volume", stockLiveMarketCap, @"MktCap",stockLiveOpen, @"Open",stockLiveLow, @"Low", stockLiveHigh, @"High", stockLive52wHigh, @"52w high", stockLive52wLow, @"52w low", stockLivePE, @"pe",stockLiveTime,@"Time", nil];
        
            NSLog(@"New Live Data 1: %@",liveData);  
        
            //Package up nicely with symbol
            NSMutableDictionary *liveDataEncapsulated = [[NSMutableDictionary alloc] initWithObjectsAndKeys: liveData,@"Data",stockTicker.text,@"StockName",nil];
        
        
            //Analytics
            NSLog(@"Saving the following stock data: %@",dict1);  
            NSLog(@"New Live Data 2: %@",liveData);        
            //NSLog(@"New Live Data Encapsulated: %@",liveDataEncapsulated);
            [Flurry logEvent:@"New Stock Added" withParameters:dict1 timed:NO];
        
            //Send NSNotification with Data to App Data Manager
            [[NSNotificationCenter defaultCenter] postNotificationName: @"New Stock Added" object:dict1];
            [[NSNotificationCenter defaultCenter] postNotificationName: @"New Live Data" object:liveDataEncapsulated];


            //Eliminate Multiple Adding Bug (track last updated, dont allow same stock two times)
            NSLog(@"Popover Dismissed");
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setObject:stockTicker.text forKey:@"LastAddedStock"];
            [prefs setObject:stockTicker.text forKey:@"LastAddedStockNoClearingForBugTracking"];            
            // addedStockYet = 1;
            
            NSString *lastAddedStock = [prefs stringForKey:@"LastAddedStock"];
            NSLog(@"Just Added %@, %@",lastAddedStock,stockTicker.text);
            
            [self.navigationController dismissModalViewControllerAnimated:YES];
        } else {
            NSLog(@"This stock was last addded. Skipping Add");
            [self.navigationController dismissModalViewControllerAnimated:YES];            
        }
    }
    
    

    
    
}


// Method Generates a random string in hex code
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
#pragma mark Change Segement

-(IBAction)changeSeg{
	if(stockSegmentOwnOrWatch.selectedSegmentIndex == 0){
		NSLog(@"seg 0");
        
        [UIView beginAnimations:@"Fade" context:nil];
        [UIView setAnimationDuration:0.3];
        ownedStockOptionsView.alpha = 0;
        currentPriceLabel.frame = CGRectMake(10, 100, 300, 29);
        [UIView commitAnimations];
        stockBuyPrice.text = @"";
        stockUnitsOwned.text = @"";
        if ([stockTicker.text length]>0)   [stockTargetPrice becomeFirstResponder];
        
	}
	if(stockSegmentOwnOrWatch.selectedSegmentIndex == 1){
		NSLog(@"seg 1");        
        [UIView beginAnimations:@"Fade" context:nil];
        [UIView setAnimationDuration:0.3];
        ownedStockOptionsView.alpha = 1;
        currentPriceLabel.frame = CGRectMake(10, 160, 300, 29);
        [UIView commitAnimations];
        if (([stockTicker.text length]>0) && ([stockTargetPrice.text length]>0))           [stockBuyPrice becomeFirstResponder];
    
    }
}



#pragma mark - YFStockDetailsLoader delegate methods



- (void)stockDetailsDidLoad:(YFStockDetailsLoader *)aDetailsLoader
{    
    self.detailKeys = [aDetailsLoader.stockDetails.detailsDictionary allKeys];
    
    
    [self.stockDetails reloadData];
    self.navigationItem.rightBarButtonItem.enabled = YES;

    //Get Other Live Data
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterNoStyle];    
    
    //
    NSString *noDataAvailableFillString = @"-";
    
    stockLiveChange    =  ([[self.detailsLoader.stockDetails.detailsDictionary objectForKey:@"Change"] retain]               != [NSNull null]) ? [[self.detailsLoader.stockDetails.detailsDictionary objectForKey:@"Change"] retain] : noDataAvailableFillString;     
    stockLiveBid       =  ([[self.detailsLoader.stockDetails.detailsDictionary objectForKey:@"LastTradePriceOnly"] retain]   != [NSNull null]) ? [[self.detailsLoader.stockDetails.detailsDictionary objectForKey:@"LastTradePriceOnly"] retain] : noDataAvailableFillString;     
    stockLiveVolume    =  ([[self.detailsLoader.stockDetails.detailsDictionary objectForKey:@"Volume"] retain]               != [NSNull null]) ? [[self.detailsLoader.stockDetails.detailsDictionary objectForKey:@"Volume"] retain] : noDataAvailableFillString;  
    stockLiveMarketCap =  ([[self.detailsLoader.stockDetails.detailsDictionary objectForKey:@"MarketCapitalization"] retain] != [NSNull null]) ? [[self.detailsLoader.stockDetails.detailsDictionary objectForKey:@"MarketCapitalization"] retain] : noDataAvailableFillString ;  
    stockLiveOpen      =  ([[self.detailsLoader.stockDetails.detailsDictionary objectForKey:@"Open"] retain]                 != [NSNull null]) ? [[self.detailsLoader.stockDetails.detailsDictionary objectForKey:@"Open"] retain] : noDataAvailableFillString ;  
    stockLiveLow       =  ([[self.detailsLoader.stockDetails.detailsDictionary objectForKey:@"DaysLow"] retain]              != [NSNull null]) ? [[self.detailsLoader.stockDetails.detailsDictionary objectForKey:@"DaysLow"] retain] : noDataAvailableFillString;  
    stockLiveHigh      =  ([[self.detailsLoader.stockDetails.detailsDictionary objectForKey:@"DaysHigh"] retain]             != [NSNull null]) ? [[self.detailsLoader.stockDetails.detailsDictionary objectForKey:@"DaysHigh"] retain] : noDataAvailableFillString;  
    stockLive52wHigh   =  ([[self.detailsLoader.stockDetails.detailsDictionary objectForKey:@"YearHigh"] retain]             != [NSNull null]) ? [[self.detailsLoader.stockDetails.detailsDictionary objectForKey:@"YearHigh"] retain] : noDataAvailableFillString;  
    stockLive52wLow    =  ([[self.detailsLoader.stockDetails.detailsDictionary objectForKey:@"YearLow"] retain]              != [NSNull null]) ? [[self.detailsLoader.stockDetails.detailsDictionary objectForKey:@"YearLow"] retain] : noDataAvailableFillString;  
    stockLivePE        =  ([[self.detailsLoader.stockDetails.detailsDictionary objectForKey:@"PERatio"] retain]              != [NSNull null]) ? [[self.detailsLoader.stockDetails.detailsDictionary objectForKey:@"PERatio"] retain] : noDataAvailableFillString;  
    stockLiveTime      =  ([[self.detailsLoader.stockDetails.detailsDictionary objectForKey:@"LastTradeTime"] retain]        != [NSNull null]) ? [[self.detailsLoader.stockDetails.detailsDictionary objectForKey:@"LastTradeTime"] retain] : noDataAvailableFillString;     
    
    
    NSLog(@"Stock Details did Load:");
    NSLog(@"self.detailsLoader.stockDetails.detailsDictionary: %@",self.detailsLoader.stockDetails.detailsDictionary);
    NSLog(@"Stock Details: stockLiveChange %@",stockLiveChange);
    NSLog(@"Stock Details: stockLiveBid %@",stockLiveBid);
    NSLog(@"Stock Details: stockLiveVolume %@",stockLiveVolume);
    NSLog(@"Stock Details: stockLiveMarketCap %@",stockLiveMarketCap);
    NSLog(@"Stock Details: stockLiveOpen %@",stockLiveOpen);
    NSLog(@"Stock Details: stockLiveLow %@",stockLiveLow);
    NSLog(@"Stock Details: stockLiveHigh %@",stockLiveHigh);
    NSLog(@"Stock Details: stockLive52wHigh %@",stockLive52wHigh);
    NSLog(@"Stock Details: stockLive52wLow %@",stockLive52wLow);
    NSLog(@"Stock Details: stockLivePE %@",stockLivePE);
    
    //Show Current Price
    currentPriceLabel.text = [NSString stringWithFormat:@"The current price is: %@",stockLiveBid];

    
}

- (void)stockDetailsDidFail:(YFStockDetailsLoader *)aDetailsLoader
{
    NSLog(@"ERROR: stockDetailsDidFail. Entered Stock: %@",self.stockSymbol.symbol);
    
    //Send Problem Ticker to Flurry
    [Flurry logError:@"Invalid Stock Added" message:self.stockSymbol.symbol exception:nil];
    
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Lookup Problem" 
                                                    message:[aDetailsLoader.error localizedDescription] 
                                                   delegate:nil 
                                          cancelButtonTitle:@"OK" 
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

#pragma mark - UITableView delegate methods
// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.detailKeys != nil) {
        return [self.detailKeys count];
    }
    
    return 4;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    if (self.detailsLoader.stockDetails == nil && indexPath.row == 2) {
        cell.textLabel.text = @"Retrieving details, please wait...";
        cell.textLabel.font = [UIFont systemFontOfSize:14.0];
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.textLabel.textColor = [UIColor lightGrayColor];
    }
    else if ([self.detailKeys count] > 0) {
        cell.textLabel.textColor = [UIColor blackColor];
        NSString *str = [self.detailsLoader.stockDetails.detailsDictionary objectForKey:[self.detailKeys objectAtIndex:indexPath.row]];
        if (![[NSNull null] isEqual:str]) {
            cell.detailTextLabel.text = str;             
        }
        else {
            cell.detailTextLabel.text = @"N/A";
        }
        cell.textLabel.text = [self.detailKeys objectAtIndex:indexPath.row];
        cell.textLabel.textAlignment = UITextAlignmentLeft;
        cell.textLabel.font = [UIFont systemFontOfSize:18.0];
    }
    else {
        cell.textLabel.text = @"";
    }
    
    return cell;
}



#pragma mark - Memory management
- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [self.detailsLoader cancel];
    
    self.detailKeys = nil;
    self.detailsLoader = nil;
    self.stockSymbol = nil;
    self.stockDetails = nil;
    [super dealloc];
}

@end
