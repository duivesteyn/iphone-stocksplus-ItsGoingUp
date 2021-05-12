//
//  Created by Björn Sållarp on 2011-03-27.
//  NO Copyright 2010 MightyLittle Industries. NO rights reserved.
// 
//  Use this code any way you like. If you do like it, please
//  link to my blog and/or write a friendly comment. Thank you!
//
//  Read my blog @ http://blog.sallarp.com
//

#import "RootViewController.h"
#import "DetailsViewController.h"

@interface RootViewController()
@property (nonatomic, retain) YFStockSymbolSearch *symbolSearch;
@property (nonatomic, retain) NSArray *stockSymbols;
@end

@implementation RootViewController
@synthesize symbolsSearchView;
@synthesize searchBar;
@synthesize symbolSearch;
@synthesize stockSymbols;

- (void)viewDidLoad
{

    self.symbolSearch = [YFStockSymbolSearch symbolSearchWithDelegate:self];
    [super viewDidLoad];
    
    self.title = @"Add Stock";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];


}

-(void)viewWillAppear:(BOOL)animated    {
    
    //UI
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1]; 
    self.navigationController.toolbar.tintColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1]; 
    
    
    
}

-(void)viewDidAppear:(BOOL)animated{
    
    [searchBar becomeFirstResponder];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)stockDataScrollView
{
    //NSLog(@"Started Scrolling");
    [searchBar resignFirstResponder];
}

#pragma mark - YFStockSymbolSearch delegate methods

- (void)symbolSearchDidFinish:(YFStockSymbolSearch *)symbolFinder
{
    NSLog(@"in symbolSearchDidFinish");
    self.stockSymbols = symbolFinder.symbols;
    [self.symbolsSearchView reloadData];
}

- (void)symbolSearchDidFail:(YFStockSymbolSearch *)symbolFinder
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Search failed" 
                                                    message:[symbolFinder.error localizedDescription] 
                                                   delegate:nil 
                                          cancelButtonTitle:@"OK" 
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

#pragma mark - UISearchBar delegate methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
        NSLog(@"in searchBar");
    
    if (searchText != nil && [searchText length] > 0) {
        [self.symbolSearch findSymbols:searchText];
    }
    else {
        self.stockSymbols = nil;
        [self.symbolsSearchView reloadData];
    }
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar
{
    [aSearchBar resignFirstResponder];
}

-(IBAction)cancel{
    NSLog(@"Hit Cancel");
    
    //Toggle Mainview Scrolling:
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showNotesView" object:nil];
 
    
    [self.navigationController dismissModalViewControllerAnimated:YES];
}


#pragma mark - UITableView delegate methods
// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.stockSymbols != nil  && [self.stockSymbols count] > 0) {
        return [self.stockSymbols count];
    }

    return 4;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if (self.stockSymbols == nil && indexPath.row == 2) {
        cell.textLabel.text = @"Start typing in the search box to find stocks!";
        cell.textLabel.font = [UIFont systemFontOfSize:16.0];
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.textLabel.textColor = [UIColor lightGrayColor];
    }
    else if ([self.stockSymbols count] == 0 && indexPath.row == 2) {
        cell.textLabel.text = @"No stocks match your search";
        cell.textLabel.font = [UIFont systemFontOfSize:16.0];
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.textLabel.textColor = [UIColor lightGrayColor];
    }
    else if ([self.stockSymbols count] > 0) {
        cell.textLabel.textColor = [UIColor blackColor];
        YFStockSymbol *symbol = [self.stockSymbols objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", symbol.name, symbol.symbol];
        cell.textLabel.textAlignment = UITextAlignmentLeft;
        cell.textLabel.font = [UIFont systemFontOfSize:18.0];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    else {
        cell.textLabel.text = @"";
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.searchBar resignFirstResponder];
    
    NSLog(@"[self.stockSymbols count]: %d",[self.stockSymbols count]);
    
    if ([self.stockSymbols count] != 0) {       //THis check fixes the bhp.ac, click on text bug
        YFStockSymbol *symbol = [self.stockSymbols objectAtIndex:indexPath.row];
        
        if (symbol) {
            NSLog(@"symbol: %@",symbol);
            DetailsViewController *detailViewController = [[DetailsViewController alloc] initWithNibName:@"DetailsViewController" bundle:nil];
            detailViewController.stockSymbol = [self.stockSymbols objectAtIndex:indexPath.row];
            [self.navigationController pushViewController:detailViewController animated:YES];
            [detailViewController release];
        }
        
        [self.symbolsSearchView deselectRowAtIndexPath:indexPath animated:YES];
    }

}


#pragma mark - Memory management
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)dealloc
{
    [self.symbolSearch cancel];
    
    self.stockSymbols = nil;
    self.symbolSearch = nil;
    self.symbolsSearchView = nil;
    self.searchBar = nil;
    [super dealloc];
}

@end
