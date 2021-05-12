//
//  SummaryViewController.h
//  PageControl
//
//  Created by Ben Duivesteyn on 10.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTStatusBarOverlay.h"  //Nice overlay text in StatusBar
#import <QuartzCore/CoreAnimation.h>
#import "EGORefreshTableHeaderView.h"
//About Page headers
#import <MessageUI/MessageUI.h>
#import "NSString+Helpers.h"
#import "BSYahooFinance.h"
#import "iRate.h"


@class AppDelegate, AddViewController, RootViewController;


@interface SummaryViewController : UIViewController  <EGORefreshTableHeaderDelegate,UINavigationBarDelegate,YFStockDetailsLoaderDelegate>
{
 	AppDelegate	*appDelegate;

    int liteEdition;
    int bannerNotShowing;
    
    IBOutlet UIView *noInternetView;
    UIView *noInternetBar;
        
    UILabel *pageNumberLabel;
    int pageNumber;
    
    UILabel *numberTitle;
    UIImageView *numberImage;
    
    IBOutlet UITableView *tableView;
    IBOutlet UIBarButtonItem *settingsButton;
    IBOutlet UIButton *elevatorButton;
    IBOutlet UILabel  *lastUpdatedLabel;
    IBOutlet UIBarButtonItem *addButton;
    IBOutlet UIView *aboutView;
    IBOutlet UILabel  *aboutVersionLabel; 
    IBOutlet UILabel  *aboutAppNameLabel;

    IBOutlet UIBarButtonItem *editButton;
    
    //TableVIew
    NSIndexPath *selectedIndexPath;
    NSMutableArray *contentArray;
    NSMutableDictionary *liveDataArray;
    //
    
    EGORefreshTableHeaderView *_refreshHeaderView;
	BOOL _reloading;
    
    NSOperationQueue *operationQueue;    //operation queue
    
    UINavigationController *addNavigationController;    
    
    IBOutlet UIButton *showArrow;
    int noInternetConnection;   
    IBOutlet UIButton *shareButton;

    
    //Allow adding only every 5 seconds
    NSDate *now ;
    NSDate *lastUpdate;
    NSDate *lastAddedDate;
    
    //Welcome Screen 
    IBOutlet UIView *welcomeView;
    IBOutlet UIButton *welcomeScreenStartButton;
    
    //Optimization
    NSDate *startDateforCodeExecutionTiming;
    
}

@property (nonatomic, retain) IBOutlet NSDate *lastAddedDate;

- (IBAction)showAboutView:(id)sender;

- (id)initWithPageNumber:(int)page;

-(void)fullVersionDetectedMessage;
-(void)firstRunMessages;
-(void)timerCallUpdateStocks;

//pulldowntorefresh
- (void)reloadTableViewDataSource;
- (void)doneLoadingTableViewData;

-(void)updateStockData;

//Email Reply / Social
- (IBAction)browserCallToAction;
- (IBAction)twitterCallToAction;
- (IBAction)facebookCallToAction;
-(void)launchMailAppOnDevice;
- (IBAction)presentEmailFeedback;
-(void)displayComposerSheetFeedback;
-(void)hideAboutView;


-(IBAction)twitterFollow:(id)sender;
- (void) openTwitterAppForFollowingUser:(NSString *)twitterUserName;

    
//DataLoading
- (void)stockDetailsDidLoad:(YFStockDetailsLoader *)detailsLoader;
- (void)stockDetailsDidFail:(YFStockDetailsLoader *)detailsLoader;
- (void)changeTextAnimatedFinish;
-(void)showNoInternetBar:(NSNotification *) notification;
-(void)hideNoInternetBar:(NSNotification *) notification;
- (void)testLoadDetailsAsynchronous:(NSString *)stock;

-(void)notificationCallStocks:(NSNotification *) notification ;

//Welcome
-(IBAction)hideWelcomeScreen:(id)sender;

@end
