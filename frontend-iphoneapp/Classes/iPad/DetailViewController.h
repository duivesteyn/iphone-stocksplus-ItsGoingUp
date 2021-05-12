/*
     File: DetailViewController.h
 Abstract: A view controller used for displaying a grid of Tile views for the iPad.
  Version: 1.4
 
 
 
 */

#import <UIKit/UIKit.h>
#import "PadContentController.h"
#import "Tile.h"

#define TILE_ROWS    2
#define TILE_COLUMNS 3
#define TILE_COUNT   (TILE_ROWS * TILE_COLUMNS)

@class DetailPopoverViewController;

@interface DetailViewController : UIViewController <UIPopoverControllerDelegate>
{
    UINavigationBar *navBar;
    
    NSArray *contentList;
    
    UIPopoverController *popoverController;
    DetailPopoverViewController *popoverViewController;
	
	CGRect savedPopoverRect;
    
@private
    CGRect tileFrame[TILE_COUNT];
    Tile* tileForFrame[TILE_COUNT];
}

@property (nonatomic, retain) IBOutlet UINavigationBar *navBar;

@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, retain) DetailPopoverViewController *popoverViewController;

@property (nonatomic, retain) NSArray *contentList;

@end
