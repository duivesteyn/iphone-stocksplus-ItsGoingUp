/*
     File: PhoneContentController.h 
 Abstract: Content controller used to manage the iPhone user interface for this app. 
  Version: 1.4 

 Copyright (C) 2010 Apple Inc. All Rights Reserved. 
  
 */

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "ContentController.h"
#import "MyViewController.h"

@class AppDelegate;


@interface PhoneContentController : ContentController <UIScrollViewDelegate>
{   
 	AppDelegate	*appDelegate;
    
    UIScrollView *scrollView;
	UIPageControl *pageControl;
    NSMutableArray *viewControllers;
    
    // To be used when scrolls originate from the UIPageControl
    BOOL pageControlUsed;
    
    NSMutableArray *contentArray;
    NSMutableDictionary *liveDataArray;
    NSUInteger kNumberOfPages;
    
    
    int scrollViewEnabled;
    
    //Scrolling
    float w;
    
    
}

@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UIPageControl *pageControl;

@property (nonatomic, retain) NSMutableArray *viewControllers;

-(void)viewsSetup;

- (IBAction)changePage:(id)sender;
-(void)showNotesView:(id)sender;
-(void)loadUpAdditionalViews:(NSNotification *) notification;
- (void)reloadScrollView:(UIScrollView *)sender;
-(void)updateScrollViewOnAddStock;
-(void)updateScrollViewOnDeleteStock:(int)rowRemoved;

@end