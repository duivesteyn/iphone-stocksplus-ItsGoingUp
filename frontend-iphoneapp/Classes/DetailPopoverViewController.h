/*
     File: DetailPopoverViewController.h
 Abstract: View controller responsible for drawing iPad number content in a popover.
  Version: 1.4
 
 
 
 */

#import <UIKit/UIKit.h>

@interface DetailPopoverViewController : UIViewController
{
    UIImageView *numberImage;
    UILabel *numberLabel;
    UITextView *numberDetail;
}

@property (nonatomic, retain) IBOutlet UIImageView *numberImage;
@property (nonatomic, retain) IBOutlet UILabel *numberLabel;
@property (nonatomic, retain) IBOutlet UITextView *numberDetail;

@end
