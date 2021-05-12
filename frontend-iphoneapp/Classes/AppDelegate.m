/*
     File: AppDelegate.m 
 Abstract: Application delegate for the universal PageControl sample (for both iPad and iPhone) 
  Version: 1.4 
  
 EVEN IF APPLE HAS BEEN ADVISED OF THE 
 POSSIBILITY OF SUCH DAMAGE. 
  
 Copyright (C) 2010 Apple Inc. All Rights Reserved. 
  
 */

#import "AppDelegate.h"
#import "ContentController.h"
#import <QuartzCore/CoreAnimation.h>
#import "Flurry.h"
#import "Reachability.h"
#import <BugSense-iOS/BugSenseController.h>    //BugSense Crash Reporting
#import "iRate.h"
#import "UATagUtils.h"  //Adds the Tagging feature in UrbanAirship! Device/Locale etc!!
#import <AVFoundation/AVFoundation.h>

@interface UINavigationController (MyCustomNavController)
@end

@implementation UINavigationController (MyCustomNavController)
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
@end

@implementation AppDelegate

@synthesize window, contentController;
@synthesize contentArray,liveDataArray;
@synthesize internetActive,hostActive;
@synthesize launchDictionary;

- (void)dealloc
{
    [window release];
    [contentController release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 
{
    NSString *nibTitle = @"PadContent";
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
	{
		nibTitle = @"PhoneContent";
    }
    NSLog(@"in didFinishLaunchingWithOptions");
    
    //Define Development/Production Mode
    //Uses special keys/servers
    int developmentMode = 0;

    
    //Check Data
    [self dataSetup];
    
    //Log Device / AppVersion
    NSString *deviceType = [UIDevice currentDevice].model;
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    NSLog(@"deviceType: %@ %@",deviceType,currSysVer);
    
    //Increment Build Number
    NSString* buildNumber = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CWBuildNumber"];
    NSLog(@"Executing Build %@",buildNumber);
    NSLog(@"UAirship Config now");
    
    //UA//Setup Push Notifications norgeapps@UrbanAirship - Init Airship launch options
    //Init Airship launch options
    NSMutableDictionary *takeOffOptions = [[[NSMutableDictionary alloc] init] autorelease];
    [takeOffOptions setValue:launchOptions forKey:UAirshipTakeOffOptionsLaunchOptionsKey];
    //Manual Set Airship Config in Code. I think this is better than including the PLIST File. (i.e. users dont get secret code).
    if (developmentMode == 1) {
        //Full Version, Development servers
        NSLog(@"UAirship Setup :Full Version Dev");
        airshipConfigOptions = [[[NSMutableDictionary alloc] init] autorelease];
        [airshipConfigOptions setValue:@"NO" forKey:@"APP_STORE_OR_AD_HOC_BUILD"];
        [airshipConfigOptions setValue:@"MxcROO8LTbKnnQUhzQlKkw" forKey:@"DEVELOPMENT_APP_KEY"];
        [airshipConfigOptions setValue:@"u0ernanoTwKHcSngm-f7pQ" forKey:@"DEVELOPMENT_APP_SECRET"];
    } else {
        //Full Version, Production servers
        NSLog(@"UAirship Setup :Full Version Production");
        airshipConfigOptions = [[[NSMutableDictionary alloc] init] autorelease];
        [airshipConfigOptions setValue:@"YES" forKey:@"APP_STORE_OR_AD_HOC_BUILD"];
        [airshipConfigOptions setValue:@"fT1X2BWKSWuO-_Fi41Gvmw" forKey:@"PRODUCTION_APP_KEY"];
        [airshipConfigOptions setValue:@"Q6BDEumPRKm1a2HaxZ6JqA" forKey:@"PRODUCTION_APP_SECRET"]; 
    }

    
    [takeOffOptions setValue:airshipConfigOptions forKey:UAirshipTakeOffOptionsAirshipConfigKey];
    
    NSLog(@"take off options: %@",takeOffOptions);
    // Create Airship singleton that's used to talk to Urban Airship servers.
    // Please populate AirshipConfig.plist with your info from http://go.urbanairship.com
    [UAirship takeOff:takeOffOptions];
    
    
    // Register for notifications
    [[UIApplication sharedApplication]
     registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                         UIRemoteNotificationTypeSound |
                                         UIRemoteNotificationTypeAlert)];
    
    
    //Show main window
    [[NSBundle mainBundle] loadNibNamed:nibTitle owner:self options:nil];
    [self.window addSubview:self.contentController.view];
	[window makeKeyAndVisible];

    //View Features - Disable Scrollview at specific times. SEt default to 0 (no locking)
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setInteger:0 forKey:@"scrollingNewPageLock"];
    [prefs synchronize];
    
    //Bugsense.com Error Reporting 
    NSString *lastAddedStock = [prefs stringForKey:@"LastAddedStockNoClearingForBugTracking"];
    NSDictionary *myBugSenseDictionary = [NSDictionary dictionaryWithObjectsAndKeys:contentArray, @"contentArray",lastAddedStock,@"Last Added Stock",nil];
    [BugSenseController sharedControllerWithBugSenseAPIKey:@"45c2e0f7" userDictionary:myBugSenseDictionary];
    
    //Check if Online/Offline
    launchDictionary = [[NSDictionary alloc] initWithDictionary:launchOptions];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:@"Recheck for internet access" object:nil];
    
    internetReachable = [[Reachability reachabilityForInternetConnection] retain];
    [internetReachable startNotifier];
    hostReachable = [[Reachability reachabilityWithHostName: @"www.yahoo.com"] retain];  // check if a pathway to a random host exists
    [hostReachable startNotifier];

    //NSLog(@"Registering for Notifications");    
    // Register for notifications
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];

    
    //NSLog(@"TODO: Set Notifier on arrival of internet connecting working again");
    application.applicationSupportsShakeToEdit = YES;
    
    //Register Flurry Analytics Data
    NSLog(@"Setting Up Flurry Analytics");
    [Flurry startSession:@"BLAMK6UBYQSBMFP77ZWM"];
    
    return YES;
}



//Called only when everything is registering correctly!
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {

    // Set some commonly used tags by OR'ing UATagType values
    NSArray *tags = [UATagUtils createTags:
                     (UATagTypeTimeZoneAbbreviation
                      | UATagTypeLanguage
                      | UATagTypeCountry
                      | UATagTypeDeviceType)];
    
    userInfoForServers = [[NSMutableDictionary alloc] initWithObjectsAndKeys:tags, @"tags", nil];
    
    
    // Updates the device token and registers the token with UA
    // https://docs.urbanairship.com/display/DOCS/Server:+Tag+API
    NSLog(@"Feedback in didRegisterForRemoteNotificationsWithDeviceToken");
    [[UAirship shared] registerDeviceToken:deviceToken withExtraInfo:userInfoForServers];
    
    //Load up Announce
    //Connect to IGU Server to give deviceID / Announce
    NSInvocationOperation *operationBackendRegisterAnnounce = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(backendRegisterAnnounce) object:nil];

    //Setup NSOperationQueue
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:operationBackendRegisterAnnounce];     /* Add the operation to the queue */
    [operationBackendRegisterAnnounce release];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err { 
    NSString *str = [NSString stringWithFormat: @"Error: %@", err];
    NSLog(@"Error:%@",str);   
    //UALOG(@"Failed To Register For Remote Notifications With Error: %@", error);
}



+ (void)initialize
{
    NSLog(@"in initialize");
    
    [iRate sharedInstance].appStoreID = 532859388; //configure and init iRate    http://mobile.tutsplus.com/tutorials/iphone/ios-quick-tip-adding-app-store-stars-with-irate/
    [iRate sharedInstance].debug = NO;  //IN LAUNCH 1.0 THIS WAS SET TO YES
    [iRate sharedInstance].usesUntilPrompt = 100;
    [iRate sharedInstance].daysUntilPrompt = 60;
}



- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    //some old v1.0 adding hack
    [self resetDuplicateStockPreventer];
    
    //Ensure Internet is OK
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:@"Recheck for internet access" object:nil];
    
    internetReachable = [[Reachability reachabilityForInternetConnection] retain];
    [internetReachable startNotifier];
    hostReachable = [[Reachability reachabilityWithHostName: @"www.yahoo.com"] retain];  // check if a pathway to a random host exists
    [hostReachable startNotifier];
}


-(NSMutableArray*) sendArray {
	
	return contentArray;
}

-(NSMutableDictionary*) sendLiveArray {
	
	 return liveDataArray ;
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    //Handle Notifications Locally when they arrive in Foreground
    
    // Get application state for iOS4.x+ devices, otherwise assume active
    UIApplicationState appState = UIApplicationStateActive;
    if ([application respondsToSelector:@selector(applicationState)]) appState = application.applicationState;
    
    
    // "_" = "2TPjrn6FEeKVJBT+tdMgpg";
    // aps =     {
    //     alert = "Stock: BHP is above your target 39.50. BHP is currently 41.2 (ex msg).";
    //     sound = "elevatorting.caf";
    // };
    

    //Handling recieving notification when application is open
    NSLog(@"Received Notification! Data: %@",userInfo);
    NSDictionary *pushData = [userInfo objectForKey:@"aps"];
    NSLog(@"Data: %@",pushData);

    
    //get data from notification
    NSString *notificationMessage = [pushData objectForKey:@"alert"];
    NSString *notificationSound = [pushData objectForKey:@"sound"];
    NSLog(@"notificationMessage: %@ notificationSound: %@",notificationMessage,notificationSound);

    //Play Alert Sound and Display UIAlertView
    AVAudioPlayer *audioPlayer;
    NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath],notificationSound]];
    NSError *error;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Stocks+ Alert" message:notificationMessage delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    audioPlayer.numberOfLoops = 0;
    
    [audioPlayer play];
    [alert show];
    
    
    
 //UA//     [[UAPush shared] handleNotification:userInfo applicationState:appState];
 //UA//     [[UAPush shared] resetBadge]; // zero badge after push received

}

-(void)applicationWillEnterForeground:(UIApplication *)application{
	NSLog(@"Restored from Background!");	
    
    //Recheck for internet access
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"Recheck for internet access" object:nil];
    
    //Update Stocks
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateStocks" object:nil];

    
    //General Resets 
    //Reset Duplicate Stock adding preventer 
    [self resetDuplicateStockPreventer];
    //REset Scrolling lock (in case of bug that caused user to close app)
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"showNotesViewForceEnable" object:nil];
    
    //Reset App Badge Number to ''
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

-(void)applicationWillResignActive:(UIApplication *)application {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"applicationAboutToSuspend" object:nil];
}

-(void)resetDuplicateStockPreventer{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:@"" forKey:@"LastAddedStock"];
    [prefs synchronize];
}

- (void)applicationDidEnterBackground:(UIApplication *)application{
	NSLog(@"Entering Background!");	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"closeApp" object:nil];
	
    [self resetDuplicateStockPreventer];

}


- (void)applicationWillTerminate:(UIApplication *)application {
    //UA
    [UAirship land];
    
    //Save Client Data
    [[NSNotificationCenter defaultCenter] postNotificationName: @"closeApp" object:nil];
}

- (void)failIfSimulator {
    if ([[[UIDevice currentDevice] model] compare:@"iPhone Simulator"] == NSOrderedSame) {
        UIAlertView *someError = [[UIAlertView alloc] initWithTitle:@"Notice"
                                                            message:@"You will not be able to recieve push notifications in the simulator."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        
        [someError show];
        [someError release];
    }
}

#pragma mark -
#pragma mark Notification Server Announce

//Announce that app is online. send POST data to notification server to add to DB
-(void)backendRegisterAnnounce {
    NSLog(@"sending backendRegisterAnnounce to server");
    NSString *token = [UAirship shared].deviceToken;
    NSLog(@"Device Token: %@",token);
    NSLog(@"------");  
    
    
    NSString *deviceType = [UIDevice currentDevice].model;
    NSString *deviceVersion = [[UIDevice currentDevice] systemVersion];
    NSLog(@"deviceType: %@ %@",deviceType,deviceVersion);
    
    //Internet URL
    NSURL *url = [NSURL URLWithString:@"https://itsgoingup.appspot.com/receive/registerdevice"];
    NSString *post =[[NSString alloc] initWithFormat:@"deviceToken=%@&deviceType=%@&deviceVersion=%@&canbeanything=%@",token,deviceType,deviceVersion,@"notused"];
    
    NSLog(@"%@",post);
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
    [request setURL:url];
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
    NSLog(@"%@",data);

    
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {

    [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

#pragma mark -
#pragma mark Internet Check

- (void) checkNetworkStatus:(NSNotification *)notice
{
    // called after network status changes
   // NSLog(@"in checkNetworkStatus");
    NetworkStatus internetStatus = [internetReachable currentReachabilityStatus];
    switch (internetStatus)
    
    {
        case NotReachable:
        {
            //NSLog(@"The internet is down.");
            self.internetActive = NO;
            
            break;
            
        }
        case ReachableViaWiFi:
        {
            //NSLog(@"The internet is working via WIFI.");
            self.internetActive = YES;
            
            break;
            
        }
        case ReachableViaWWAN:
        {
            //NSLog(@"The internet is working via WWAN.");
            self.internetActive = YES;
            
            break;
            
        }
    }
    
    NetworkStatus hostStatus = [hostReachable currentReachabilityStatus];
    switch (hostStatus)
    
    {
        case NotReachable:
        {
            //NSLog(@"A gateway to the host server is down.");
            self.hostActive = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"noInternetMode" object:nil]; //<- This is crashing
            
            break;
            
        }
        case ReachableViaWiFi:
        {
            //NSLog(@"A gateway to the host server is working via WIFI.");
            self.hostActive = YES;

            break;
            
        }
        case ReachableViaWWAN:
        {
            //NSLog(@"A gateway to the host server is working via WWAN.");
            self.hostActive = YES;
            break;
            
        }
            
        if (self.hostActive == YES) {

            //Any iCloud stuff here?
            //NSLog(@"TODO: iCloud Settings and Data Sync Here!!!");
        } else  {

            //Send NS Notification to all views to goto noInternetMode
            NSLog(@"No Internet Detected");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"noInternetMode" object:nil]; //<- This was crashing

        }
            
    }
    
    //NSLog(@"Internet? : %d",self.hostActive);
    if (self.hostActive == 1) {
        //Send notification that the internet is back
        
        //Send Notification to Show data again on MyViewController
        [[NSNotificationCenter defaultCenter] postNotificationName:@"hideNoInternetMode" object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"hideNoInternetBar" object:nil];        
    } else  {
        NSLog(@"No internet detected (2)");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"noInternetMode" object:nil]; //<- This was crashing    
        [[NSNotificationCenter defaultCenter] postNotificationName:@"showNoInternetBar" object:nil];   
        
    }

}

#pragma mark -
#pragma mark Data

-(void)dataSetup{
	
    //If Setting in place to reset all data, do so!
    //Workes Great, written 5. apr. 09:23!
    
    //Setting Request - Reset All Data
    int dataresetQuery = [[NSUserDefaults standardUserDefaults] boolForKey:@"datareset"];
    NSLog(@"dataresetQuery: %d",dataresetQuery);
    
    if (dataresetQuery==1) {
        
        //delete clientDAta
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
        NSString *documentsDirectoryPath = [paths objectAtIndex:0];
        NSString *fileToDelete = [documentsDirectoryPath stringByAppendingPathComponent:@"Stocks.plist"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:fileToDelete error:NULL];
        
        //delete liveData
        NSString *fileToDeleteTwo = [documentsDirectoryPath stringByAppendingPathComponent:@"LiveData.plist"];
        [fileManager removeItemAtPath:fileToDeleteTwo error:NULL];  
        
        
        //delete 
        NSArray* cachePathArray = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString* cachePath = [cachePathArray lastObject];
        NSArray *cacheFiles = [fileManager contentsOfDirectoryAtPath:cachePath error:NULL];
        for (NSString *file in cacheFiles) {
            [fileManager removeItemAtPath:[cachePath stringByAppendingPathComponent:file] error:NULL];
        }
        
        //Put setting back to 'off'
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        [standardUserDefaults setObject:@"NO" forKey:@"datareset"];
        [standardUserDefaults synchronize];
        
    } 
    
	
	[self checkAndCreateDatabase];
	
	//Plist Content Setup
	NSString *databaseName = @"Stocks.plist";
	// Get the path to the documents directory and append the databaseName
	NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDir = [documentPaths objectAtIndex:0];
	plistPath = [documentsDir stringByAppendingPathComponent:databaseName];
	contentArray = [[NSMutableArray arrayWithContentsOfFile:plistPath]  retain];
	NSLog(@"Content Array Loaded: %@",contentArray);
    
    
	//Setup LiveData Dictionary
	plistPath = [documentsDir stringByAppendingPathComponent:@"LiveData.plist"];	
	//NSLog(@"plistPath2 %@", plistPath);
	liveDataArray = [[NSMutableDictionary dictionaryWithContentsOfFile:plistPath]  retain];	
	NSLog(@"liveDataArray: %@",liveDataArray);
}

-(void) checkAndCreateDatabase{
	// Check if the SQL database has already been saved to the users phone, if not then copy it over
	BOOL success;
	BOOL success2;
	
	NSString *databaseName = @"Stocks.plist";
	// Get the path to the documents directory and append the databaseName
	NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDir = [documentPaths objectAtIndex:0];
	NSString *databasePath = [documentsDir stringByAppendingPathComponent:databaseName];
	//Modified for initial data - Will become useless over time
	NSString *liveDataPath = [documentsDir stringByAppendingPathComponent:@"LiveData.plist"];
	
	//if (1) NSLog(@"databasePath: %@",databasePath);
	
	
	// Create a FileManager object, we will use this to check the status
	// of the database and to copy it over if required
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	// Check if the database has already been created in the users filesystem
	success  = [fileManager fileExistsAtPath:databasePath];
	success2 = [fileManager fileExistsAtPath:liveDataPath]; 
	// If the database already exists then return without doing anything
	if(success && success2) return;
	
	
	// If not then proceed to copy the database from the application to the users filesystem
	
	// Get the path to the database in the application package
	NSString *databasePathFromApp = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:databaseName];
	NSString *databasePathFromApp2 = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"LiveData.plist"];
	
	// Copy the database from the package to the users filesystem
	[fileManager copyItemAtPath:databasePathFromApp toPath:databasePath error:nil];
	[fileManager copyItemAtPath:databasePathFromApp2 toPath:liveDataPath error:nil];	
	[fileManager release];
    
	
}



@end
