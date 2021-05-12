 
/*
     File: main.m
 Abstract: Creates and launches the application. The MainWindow nib will be loaded and the application delegate object will be unarchived from it.
  Version: 1.4
 
 
 
*/

#import <UIKit/UIKit.h>

int main(int argc, char *argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, nil);
    [pool release];
    return retVal;
}
