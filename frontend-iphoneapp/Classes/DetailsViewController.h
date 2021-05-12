//
//  Created by Björn Sållarp on 2011-03-27.
//  NO Copyright 2010 MightyLittle Industries. NO rights reserved.
// 
//  Use this code any way you like. If you do like it, please
//  link to my blog and/or write a friendly comment. Thank you!
//
//  Read my blog @ http://blog.sallarp.com
//

#import <UIKit/UIKit.h>
#import "BSYahooFinance.h"


@interface DetailsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, YFStockDetailsLoaderDelegate> {
  

    UITableView *stockDetails;
    YFStockSymbol *symbol;
    YFStockDetailsLoader *detailsLoader;
    NSArray *detailKeys;
    
    
    IBOutlet UITextField *stockTicker;
    IBOutlet UITextField *stockDisplayName;
    IBOutlet UITextField *stockTargetPrice;
    IBOutlet UITextField *stockBuyPrice;
    IBOutlet UITextField *stockUnitsOwned;
    IBOutlet UISegmentedControl *stockSegmentOwnOrWatch;
    IBOutlet UIView *ownedStockOptionsView;
    IBOutlet UILabel  *currentPriceLabel;
    
    NSString *stockName;
    
    NSNumber *stockBid;
    NSNumber *stockLiveChange;
    NSNumber *stockLiveBid;
    NSNumber *stockLiveVolume;
    NSNumber *stockLiveMarketCap;    
    NSNumber *stockLiveOpen; 
    NSNumber *stockLiveLow;    
    NSNumber *stockLiveHigh; 
    NSNumber *stockLive52wHigh; 
    NSNumber *stockLive52wLow;     
    NSNumber *stockLivePE;
    NSNumber *stockLiveTime;    
    
    NSString *notificationsOn;
    NSString *notificationStr;
    
    //other
    int addedStockYet;
}

@property (nonatomic, retain) IBOutlet UITableView *stockDetails;
@property (nonatomic, retain) YFStockSymbol *stockSymbol;
-(IBAction)changeSeg;
-(NSString *) genRandStringLength: (int) len;

@end
