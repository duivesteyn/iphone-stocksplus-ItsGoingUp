/*
     File: ContentController.m 
 Abstract: The generic content controller superclass. Subclasses are created for supporting differing devices. 
  Version: 1.4 
  
 */

#import "ContentController.h"

@implementation ContentController

@synthesize contentList;

- (void)dealloc
{
    [contentList release];
    [super dealloc];
}

- (UIView *)view
{
    return nil; // subclasses need to override this with their own view property
}

@end
