/*
     File: AppDelegate.h 
 Abstract: Application delegate for the universal PageControl sample (for both iPad and iPhone) 
  Version: 1.4 

 */

#import <UIKit/UIKit.h>
#import "MTStatusBarOverlay.h"  //Nice overlay text in StatusBar
#import "Reachability.h"
#import "UAirship.h"
#import "UAPush.h"


@class ContentController;
@class Reachability;

@interface AppDelegate : NSObject <UIApplicationDelegate>
{
	UIWindow *window;
    ContentController *contentController;
    
    //Plist
	NSMutableDictionary* plistDict;
	NSString* plistPath;
	NSMutableArray *contentArray;
	NSMutableDictionary *liveDataArray;
    
    NSDictionary *userInfoForServers;
    
    int internetConnectivity;   //temp
    BOOL internetActive; //allocated for internet available
    BOOL hostActive;
    Reachability* internetReachable;
    Reachability* hostReachable;
    NSDictionary *launchDictionary;
    
    NSMutableDictionary *airshipConfigOptions;

}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet ContentController *contentController;
@property (nonatomic, retain) NSMutableArray *contentArray;
@property (nonatomic, retain) NSMutableDictionary *liveDataArray;
@property (nonatomic) BOOL internetActive;
@property (nonatomic) BOOL hostActive;
@property (nonatomic, retain) NSDictionary *launchDictionary;

-(void)checkAndCreateDatabase;
-(void)dataSetup;
-(NSString *) genRandStringLength: (int) len;

-(NSMutableArray*) sendArray;
-(NSMutableDictionary*) sendLiveArray;

//Reachability
  - (void) checkNetworkStatus:(NSNotification *)notice;
@end

