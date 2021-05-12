//
//  SummaryViewController.m
//  PageControl
//
//  Created by Ben Duivesteyn on 10.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SummaryViewController.h"
#import "PhoneContentController.h"
#import "UAirship.h"
#import "UAViewUtils.h"
#import "UAPush.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#include <CFNetwork/CFNetwork.h>

@implementation SummaryViewController


// load the view nib and initialize the pageNumber ivar
- (id)initWithPageNumber:(int)page
{
    NSLog(@"Page Number %d", pageNumber);
    if ((self = [super initWithNibName:@"SummaryView" bundle:nil]))
    {
        pageNumber = page;
    }
    return self;
}

- (void)dealloc
{
    [pageNumberLabel release];
    [numberTitle release];
    [numberImage release];
    
    [super dealloc];
}

// set the label and background color when the view has finished loading
- (void)viewDidLoad
{
    pageNumberLabel.text = [NSString stringWithFormat:@"Page %d", pageNumber + 1];
}

-(void)viewDidAppear:(BOOL)animated {
    NSLog(@"Page Number %d", pageNumber);
    
   // CustomStatusBar = [[CustomStatusBar alloc] initWithFrame:CGRectZero]; // Don't forget to release
}



#pragma mark -
#pragma mark Table view datasource and delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    
	static NSString *MyIdentifier = @"MyIdentifier";
	
	// Try to retrieve from the table view a now-unused cell with the given identifier.
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	
	// If no cell is available, create a new one using the given identifier.
	if (cell == nil) {
		// Use the default cell style.
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:MyIdentifier] autorelease];
	}
    
  
    
	
	// Set up the cell.
	NSString *textEntry = @"hi there";
	cell.textLabel.text = textEntry;
	
	return cell;
}


- (void)tableView:(UITableView *)thetableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    //Keep track of the row selected.
	selectedIndexPath = indexPath;
    
    
    [thetableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	//if (indexPath.row>2) return 90; else return 40;
    return 80;
}


-(IBAction)didPressEdit{
    //edit pressed
    
	//[super setEditing:editing animated:animated];
   // [tableView setEditing:editing animated:YES];
    if (tableView.editing) {
         [tableView setEditing:0 animated:YES];
    } else  [tableView setEditing:1 animated:YES];
   
	
	//Do not let the user add if the app is in edit mode.
	if (tableView.editing) {
		addButton.enabled = NO;}
	else addButton.enabled = YES;
    
   // PhoneContentController.ScrollView. blah = diabled? //doesntwork

}

-(IBAction)didPressAdd{
    //add
    NSLog(@"Pressed Add");
    NSString *token = [UAirship shared].deviceToken;
    NSLog(@"Device Token: %@",token);
    NSLog(@"------");  
    

    //Internet URL
    NSURL *url = [NSURL URLWithString:@"https:/itsgoingup.appspot.com/receive/registerdevice"];
    
    
    NSString *post =[[NSString alloc] initWithFormat:@"deviceToken=%@&canbeanything=%@",token,@"notused"];
    
    NSLog(post);
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    /* when we user https, we need to allow any HTTPS cerificates, so add the one line code,to tell teh NSURLRequest to accept any https certificate, i'm not sure about the security aspects
     */
    
    [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[url host]];
    
    NSError *error;
    NSURLResponse *response;
    NSData *urlData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSString *data=[[NSString alloc]initWithData:urlData encoding:NSUTF8StringEncoding];
    NSLog(@"%@",data);
    

    

    
    
    
    //WorkingGet
    //NSURLRequest *request =
    //[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://192.168.2.2:8080/receive/registerdevice"]];
    //[[NSURLConnection alloc] initWithRequest:request delegate:self];

    
}

- (IBAction)showInfo:(id)sender
{    
    AboutViewController *controller = [[AboutViewController alloc] initWithNibName:@"AboutView" bundle:nil];
    controller.delegate = self;
    
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:controller animated:YES];
    
    [controller release];
}

#pragma mark Management for About Page

- (void)aboutViewControllerDidFinish:(AboutViewController *)controller
{
    [self dismissModalViewControllerAnimated:YES];
}

@end
