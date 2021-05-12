/*
     File: PhoneContentController.m 
 Abstract: Content controller used to manage the iPhone user interface for this app. 
  Version: 1.4custom
BMD Notes: I have modified the original file to load the views in NSOperation queues. I have disabled loadingviews whilst scrolling (as an optimisation). This change might cause an error, I have commented these changes as //bmd14c

 */

#import "PhoneContentController.h"
#import "AppDelegate.h"
#import "MyViewController.h"
#import "SummaryViewController.h"


static NSString *NameKey = @"nameKey";
static NSString *ImageKey = @"imageKey";


@interface ContentController (PrivateMethods)
- (void)loadScrollViewWithPage:(int)page;
- (void)scrollViewDidScroll:(UIScrollView *)sender;
@end 


@implementation PhoneContentController

@synthesize scrollView, pageControl, viewControllers;

- (void)awakeFromNib
{
    NSLog(@"in PhoneContentController: awakeFromNib");

    //Set Number of Pages (+1)
	appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];  
    contentArray = [appDelegate sendArray];
    
  	// load our data from a plist file inside our app bundle
    NSString *path = [[NSBundle mainBundle] pathForResource:@"content_iPhone" ofType:@"plist"];
    self.contentList = [NSArray arrayWithContentsOfFile:path];
    
    //SEtup Notification REminders
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNotesView:) name:@"showNotesView" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNotesViewForceEnable:) name:@"showNotesViewForceEnable" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadUpAdditionalViews:) name:@"loadUpAdditionalViews" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollLeft:) name:@"scrollLeft" object:nil];    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadScrollView:) name:@"reloadScrollView" object:nil]; 
    
    [self viewsSetup];

}



-(void)viewsSetup{

    NSLog(@"numberOfRowsinSection: %d",[contentArray count]);
    kNumberOfPages = [contentArray count]+1;    
    
    // view controllers are created lazily
    // in the meantime, load the array with placeholders which will be replaced on demand
    NSMutableArray *controllers = [[NSMutableArray alloc] init];
    for (unsigned i = 0; i < kNumberOfPages; i++)
    {
		[controllers addObject:[NSNull null]];
    }
    self.viewControllers = controllers;
    [controllers release];
    
    // a page is the width of the scroll view
    scrollView.pagingEnabled = YES;
    scrollView.bounces = NO;
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * kNumberOfPages, scrollView.frame.size.height);
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.scrollsToTop = NO;
    scrollView.delegate = self;
    // scrollView.scrollEnabled = NO;  // To disable scrollview use this: 
    
    pageControl.numberOfPages = kNumberOfPages;
    pageControl.currentPage = 0;
    
     
    //Load Views
    int tempLoadingVersion = 1; //use 1 for old (bad) loading type, use 2.0 for new . THis is written this way to prevent running it in simulator
    if (tempLoadingVersion == 1) {
        
        [self loadScrollViewWithPage:0]; //1.0 Load Style
        
    } else if (tempLoadingVersion == 2) {
        
        //This is my 2.0 version of pre-loading up pages. It uses NSOperation, as opposed to loading up a new page, mid-scroll (that was slow)
        [self loadScrollViewWithPage:0]; //Load first page directly, the rest non-directly.
        
        for (int i = 1; i < kNumberOfPages; i++) {
            
            /* Operation Queue init (autorelease) */
            [self loadScrollViewWithPage:i];
            
        }
        
        
    }
    
    scrollViewEnabled = 1;  
    
}

- (void)reloadScrollView:(NSNotification *) notification;
{
    //Reloading View
    //   [self viewsSetup];          //OLD Method: This worked to refresh all the information, but is pretty heavy/crude. A simpler selection is possibl,

    //Check Notification Data to see if this is a delete signal
    NSArray *obj = [notification object];
    if (obj) {
        NSLog(@"Received Delete Signal: Object: %@",obj);
        int row = [[obj objectAtIndex:0] row];
        NSLog(@"delete at index: %d",row);
        //[self viewsSetup];
        [self updateScrollViewOnDeleteStock:row];
    }   else {
        NSLog(@"Stock Added, Updating Views");
        [self updateScrollViewOnAddStock];
    }


}


-(void)updateScrollViewOnAddStock {
    NSLog(@"testing in here: updateScrollViewOnAddStock");
    

    //Update Page Count
    int oldkNumberOfPages = kNumberOfPages;  //variable used to check if page added or deleted
    kNumberOfPages = [contentArray count]+1;
    
    NSLog(@"old k : %d, new k: %d",oldkNumberOfPages,kNumberOfPages);

        //Setup View controllers
        //NSLog(@"Pre: self.viewControllers: %@",self.viewControllers);
        NSMutableArray *controllers = [[NSMutableArray alloc] init];
        controllers = self.viewControllers;
        //NSLog(@"Post: self.viewControllers: %@",controllers);
        [controllers addObject:[NSNull null]];
        self.viewControllers = controllers;


    //ScrollView Updated Setting
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * kNumberOfPages, scrollView.frame.size.height);
    pageControl.numberOfPages = kNumberOfPages;
    
    //PreLoad View
    [self loadScrollViewWithPage:kNumberOfPages];
    
}

-(void)updateScrollViewOnDeleteStock:(int)rowRemoved {
    
    NSLog(@"in updateScrollViewOnDeleteStock, rowRemoved: %d",rowRemoved); 
    NSLog(@"numberOfRowsinSection: %d",[contentArray count]);
    kNumberOfPages = [contentArray count]+1;    
    
    // view controllers are created lazily
    // in the meantime, load the array with placeholders which will be replaced on demand
    NSMutableArray *controllers = [[NSMutableArray alloc] init];
    for (unsigned i = 0; i < kNumberOfPages; i++)
    {
		[controllers addObject:[NSNull null]];
    }
    self.viewControllers = controllers;
    [controllers release];
    
    // a page is the width of the scroll view
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * kNumberOfPages, scrollView.frame.size.height);  
    pageControl.numberOfPages = kNumberOfPages;
    
    //Load Views
    [self loadScrollViewWithPage:0]; //1.0 Load Style

    NSLog(@"in updateScrollViewOnDeleteStock - stage4");

}


-(void)loadUpAdditionalViews:(NSNotification *) notification {
    for (int i = 1; i < kNumberOfPages; i++) {
        NSLog(@"in loadUpAdditionalViews - Loading Additional Views Behind the scenes");
        /* Operation Queue init (autorelease) */
        [self loadScrollViewWithPage:i];
        
    }    
}


- (void)dealloc
{
    [viewControllers release];
    [scrollView release];
    [pageControl release];
    
    [super dealloc];
}

- (UIView *)view
{
    return self.scrollView;
}

- (void)loadScrollViewWithPage:(int)page
{

    if (page < 0)
        return;
    if (page >= kNumberOfPages)
        return;
    if (page==0) {
        // replace the placeholder if necessary
        MyViewController *controller = [viewControllers objectAtIndex:page];
        if ((NSNull *)controller == [NSNull null])
        {
            controller = [[SummaryViewController alloc] initWithPageNumber:page];
            [viewControllers replaceObjectAtIndex:page withObject:controller];
            [controller release];
        }
        
        // add the controller's view to the scroll view
        if (controller.view.superview == nil)
        {
            CGRect frame = scrollView.frame;
            frame.origin.x = frame.size.width * page;
            frame.origin.y = 0;
            controller.view.frame = frame;
            [scrollView addSubview:controller.view];
            
            //NSDictionary *numberItem = [self.contentList objectAtIndex:page];
            //controller.numberImage.image = [UIImage imageNamed:[numberItem valueForKey:ImageKey]];
            //controller.numberTitle.text = [numberItem valueForKey:NameKey];
        }
    } else {
        // replace the placeholder if necessary
        MyViewController *controller = [viewControllers objectAtIndex:page];
        if ((NSNull *)controller == [NSNull null])
        {
            controller = [[MyViewController alloc] initWithPageNumber:page];
            [viewControllers replaceObjectAtIndex:page withObject:controller];
            [controller release];
        }
        
        // add the controller's view to the scroll view
        if (controller.view.superview == nil)
        {
            CGRect frame = scrollView.frame;
            frame.origin.x = frame.size.width * page;
            frame.origin.y = 0;
            controller.view.frame = frame;
            [scrollView addSubview:controller.view];

        }
    }
    


}



- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    // We don't want a "feedback loop" between the UIPageControl and the scroll delegate in
    // which a scroll event generated from the user hitting the page control triggers updates from
    // the delegate method. We use a boolean to disable the delegate logic when the page control is used.
    if (pageControlUsed)
    {
        // do nothing - the scroll was initiated from the page control, not the user dragging
        return;
    }
	
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    pageControl.currentPage = page;
    
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    [self loadScrollViewWithPage:page - 1];
    [self loadScrollViewWithPage:page];
    [self loadScrollViewWithPage:page + 1]; //bmd14c
    

    // A possible optimization would be to unload the views+controllers which are no longer visible
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
       
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    
    //Check for first scroll
    //Show help scroll window before first scroll
    //NSLog(@"Will Detect Scroll Here");
    //Decided not to implement
}


-(void)scrollLeft:(NSNotification *) notification{

    //Specify Scroll Distance
    w = 320;
    
    int pass = [[[notification userInfo] valueForKey:@"index"] intValue]+1;
    NSLog(@"Recived Scroll Notification - Scrolling to the Right int: %d",pass);    
    
    CGPoint scrollPoint = scrollView.contentOffset;
    scrollPoint.x= scrollPoint.x+(w*pass);
    if(scrollPoint.x >= scrollView.contentSize.width -(scrollView.frame.size.width -100)  || scrollPoint.x <= -scrollView.frame.size.width +924)
    {
        w *= -1;
    }
    [scrollView setContentOffset:scrollPoint animated:YES];
}
    


-(void)showNotesViewForceEnable:(id)sender {
    NSLog(@"Starting Scrollview. Forced");

        scrollView.scrollEnabled = YES; 
        scrollViewEnabled = 1;
    
}

-(void)showNotesView:(id)sender {
    NSLog(@"Halting Scrollview.");
    
    //attempt to completely stop the scrollview
    if (scrollViewEnabled == 1) {
        scrollView.scrollEnabled = NO;
        scrollViewEnabled = 0;
    } else {
        scrollView.scrollEnabled = YES; 
        scrollViewEnabled = 1;
    }
    
}

// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    //pageControlUsed = NO;

}

- (IBAction)changePage:(id)sender
{
    int page = pageControl.currentPage;
	
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    //[self loadScrollViewWithPage:page - 1]; //bmd14c
    [self loadScrollViewWithPage:page];
    //[self loadScrollViewWithPage:page + 1]; //bmd14c
    
	// update the scroll view to the appropriate page
    CGRect frame = scrollView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
    [scrollView scrollRectToVisible:frame animated:YES];
    
	// Set the boolean used when scrolls originate from the UIPageControl. See scrollViewDidScroll: above.
    pageControlUsed = YES;
}

@end
