//
//  SummaryViewController.h
//  PageControl
//
//  Created by Ben Duivesteyn on 10.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AboutViewController.h"
#import "CustomStatusBar.h"

@interface SummaryViewController : UIViewController  <AboutViewControllerDelegate>
{
    UILabel *pageNumberLabel;
    int pageNumber;
    
    UILabel *numberTitle;
    UIImageView *numberImage;
    
    IBOutlet UITableView *tableView;
    IBOutlet UIButton *infoButton;
    IBOutlet UIBarButtonItem *settingsButton;
    IBOutlet UILabel  *lastUpdatedLabel;
    IBOutlet UIBarButtonItem *addButton;
    
    //TableVIew
    NSIndexPath *selectedIndexPath;

}

- (IBAction)showInfo:(id)sender;
- (id)initWithPageNumber:(int)page;
@end
