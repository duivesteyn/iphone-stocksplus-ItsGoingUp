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
#import "iAd/ADBannerView.h"

@class AppDelegate, AddViewController, RootViewController;


@interface SummaryViewController : UIViewController  <EGORefreshTableHeaderDelegate,UINavigationBarDelegate,YFStockDetailsLoaderDelegate,ADBannerViewDelegate>
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
    IBOutlet UIButton *infoButton;
    IBOutlet UIBarButtonItem *settingsButton;
    IBOutlet UIButton *elevatorButton;
    IBOutlet UILabel  *lastUpdatedLabel;
    IBOutlet UIBarButtonItem *addButton;
    IBOutlet UIView *aboutView;
    IBOutlet UILabel  *aboutVersionLabel; 
    IBOutlet UILabel  *aboutAppNameLabel;

    IBOutlet UIBarButtonItem *editButton;

    IBOutlet UIView *helpTagNoStocks; //help tag - add new stock
    
    //TableVIew
    NSIndexPath *selectedIndexPath;
    NSMutableArray *contentArray;
    NSMutableDictionary *liveDataArray;
    //
    
    EGORefreshTableHeaderView *_refreshHeaderView;
	BOOL _reloading;
    
    //About/Debug Scroller
    IBOutlet UIView *debugView;
    IBOutlet UIButton *debugbutton;
    
    NSOperationQueue *operationQueue;    //operation queue
    
    UINavigationController *addNavigationController;    
    
    IBOutlet UIButton *showArrow;
    int noInternetConnection;
    
    //seting
    int debugViewOn;
    IBOutlet UIButton *debugViewButton;
    
    //Promo
    IBOutlet UIButton *promoGetFullVersionText;
    IBOutlet UIButton *promoGetItNowButton;
    IBOutlet UIView *promoGetAppView;
    IBOutlet UIButton  *promoDownloadButton;  
    IBOutlet UIButton *promoNoThanksButton;
    IBOutlet UIImageView *promothreeView;
    IBOutlet UILabel *promothreeLabel;
    
    IBOutlet UIButton *shareButton;
    
    //iAd
    UIView *_contentView;
    id _adBannerView;
    BOOL _adBannerViewIsVisible;
    
    //Allow adding only every 5 seconds
    NSDate *now ;
    NSDate *lastUpdate;
    NSDate *lastAddedDate;
    
    //Welcome Screen 
    IBOutlet UIView *welcomeView;
    IBOutlet UIButton *welcomeScreenStartButton;
    
}

@property (nonatomic, retain) IBOutlet NSDate *lastAddedDate;

- (IBAction)showAboutView:(id)sender;
- (IBAction)showDebugView:(id)sender;
- (id)initWithPageNumber:(int)page;

-(void)fullVersionDetectedMessage;
-(void)firstRunMessages;
-(void)timerCallUpdateStocks;

//pulldowntorefresh
- (void)reloadTableViewDataSource;
- (void)doneLoadingTableViewData;

-(void)updateStockData;
-(void)updateStockDataFinished;

//Email Reply / Social
- (IBAction)browserCallToAction;
- (IBAction)twitterCallToAction;
- (IBAction)facebookCallToAction;
-(void)launchMailAppOnDevice;
- (IBAction)presentEmailFeedback;
-(void)displayComposerSheetFeedback;
-(void)hideAboutView;


//Promo
-(IBAction)promoGetFullVersionPressed:(id)sender;
-(IBAction)promoDownloadFull:(id)sender;
-(IBAction)promoClose:(id)sender;

-(IBAction)twitterFollow:(id)sender;
- (void) openTwitterAppForFollowingUser:(NSString *)twitterUserName;

//iAd
@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) id adBannerView;
@property (nonatomic) BOOL bannerIsVisible;
- (void)createAdBannerView;
    
    
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
