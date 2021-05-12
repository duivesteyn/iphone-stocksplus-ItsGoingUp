//
//  deStockLookup.m
//  ItsGoingUp
//
//  Created by Benjamin M. Duivesteyn on 18.02.10.
//  Copyright 2010 TBA. All rights reserved.
//

#import "deStockLookup.h"
#import "Reachability.h"
#import "RegexKitLite.h"


@implementation DeStockLookup

//stockName
//@synthesize  stockTargetProfit, stockBuyPrice, stockBuyVolume;
//@synthesize stockCurrent,stockCurrentMovement;

-(void)testAccessMethod{
	UIAlertView *baseAlert = [[UIAlertView alloc]  initWithTitle:@"Debug" message:@"Test Accessor Method Works!!!" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
	[baseAlert show];	
}

-(NSArray*)testArray{
	
	testArray = [NSArray arrayWithObjects:
                      [NSNumber numberWithFloat:2.0],
                      [NSNumber numberWithFloat:4.5],
                      [NSNumber numberWithFloat:5.2],
                      [NSNumber numberWithFloat:7.1],
                      [NSNumber numberWithFloat:2.3],
                      [NSNumber numberWithFloat:3.9],
                      [NSNumber numberWithFloat:1.2],
                      nil];
	return testArray;
}

-(void)testReturnMethod:(NSString *)stockString{ //wrong way around
//	NSString *temp = @"Hey";
//	return temp;
}



-(BOOL)checkInternet{
	//Test for Internet Connection
	NSLog(@"--------");NSLog(@"Testing Internet Connectivity");
	Reachability *r = [Reachability reachabilityWithHostName:@"finance.yahoo.com"];
	NetworkStatus internetStatus = [r currentReachabilityStatus];
	BOOL internet;
	if ((internetStatus != ReachableViaWiFi) && (internetStatus != ReachableViaWWAN)) {
		internet = NO;
	} else {
		internet = YES;
	}
	return internet;
}

//-(NSArray*)stockChartDownload:(NSString *)stock{
-(NSArray*) StockUpdateNew:(NSString *)stock{
	
	gotInternet = [self checkInternet];
	
	if (gotInternet==1)  {
		//Download Yahoo Finance Stock Info
		NSLog(@"----------");NSLog(@"StockUpdateNew");NSLog(@"Downloading Yahoo Finance Data ");
		
		NSString *downloadURL = @"http://download.finance.yahoo.com/d/quotes.csv?s=";
		NSString *string2 = stock;
		NSString *string3 = @"&f=sl1d1t1c1ohgv&e=.csv";
		
		downloadURL = [downloadURL stringByAppendingString:string2];
		downloadURL = [downloadURL stringByAppendingString:string3];
		
		NSLog(@"Data Download URL:%@",downloadURL);
		
		NSURL *url = [NSURL URLWithString:downloadURL];
		NSData *data = [NSData dataWithContentsOfURL:url];
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		//Save to File
		
		//Get a nicely formatted date to use in the filename
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy-MM-dd-HHmmss"];
		NSString* currentTime = [dateFormatter stringFromDate:[NSDate date]];
		[dateFormatter release];
		NSLog(@"Download time  is:%@",currentTime);
		currentTime = [currentTime stringByAppendingString:@".csv"];
		//Assign File
		NSString *appFile = [documentsDirectory stringByAppendingPathComponent:currentTime];
		[data writeToFile:appFile atomically:YES];
		
		
		NSString *fileString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];	
	
		//Parse the new CSV
		//Regex CSV Parsing
		NSString   *newlineRegex      = @"(?:\r\n|[\n\v\f\r\\x85\\p{Zl}\\p{Zp}])";
		NSString   *splitCSVLineRegex = @",(?=(?:(?:[^\"\\\\]*+|\\\\\")*\"(?:[^\"\\\\]*+|\\\\\")*\")*(?!(?:[^\"\\\\]*+|\\\\\")*\"(?:[^\"\\\\]*+|\\\\\")*$))";
		
		// Create a NSArray of every line in csvFileString.
		NSArray    *csvLinesArray     = [fileString componentsSeparatedByRegex:newlineRegex];
		
		// Create an id array to hold the comma split line results.
		id          splitLines[[csvLinesArray count]]; // C99 variable length array.
		NSUInteger  splitLinesIndex = 0UL;             // Index of next splitLines[] member.
		
		for(NSString *csvLineString in csvLinesArray) {                // ObjC 2 for…in loop.
			if([csvLineString isMatchedByRegex:@"^\\s*$"]) { continue; } // Skip empty lines.
			splitLines[splitLinesIndex++] = [csvLineString componentsSeparatedByRegex:splitCSVLineRegex];
		}
		
		// Gather up all the individual comma split results in to a single NSArray.
		NSArray *splitLinesArray = [NSArray arrayWithObjects:&splitLines[0] count:splitLinesIndex];
		stockCSVArray = [splitLinesArray objectAtIndex:0];	//take first array in splitLinesArray
		NSLog(@"----"); NSLog(@"stockCSVArray:%@",stockCSVArray);	
		return  stockCSVArray;
		
		
	} else	{		//not on internet
		
	//Do a nice update of the parameters from saved data.

	stockCSVArray = [NSArray arrayWithObjects:
				   @"\"BHP.AX\"",
				   @"41.000",
				   @"\"2/19/2010\"",
				   @"\"12:10am\"",
				   @"+0.070",
				   @"41.240",
				   @"41.390",
				   @"40.480",
				   [NSNumber numberWithFloat:16665631],
					 nil];
					 
			return stockCSVArray;
	}


}

-(NSDictionary*)stockChartDownload:(NSString *)stock {
//Note, in Stocks+ I have already enabled the fileExist check, so it is actually pointless here. Left in for future use of DEStockLookup
    
    //CUrent Date in Str for Plist File Name
    NSDateFormatter* dateFormatterTwo = [[NSDateFormatter alloc] init];
    [dateFormatterTwo setDateFormat:@"yyyy-MM-dd"];
    NSString *dateStringNow = [dateFormatterTwo stringFromDate:[NSDate date]];
    //Check if data already downloaded from the net
    NSArray* cachePathArray = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* cachePath = [cachePathArray lastObject];
    NSString *dataStr = [NSString stringWithFormat:@"stockChartData-365-%@-%@.plist",dateStringNow,stock];
    
    NSString* foofile = [cachePath stringByAppendingPathComponent:dataStr];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:foofile];
    
	if (fileExists != 1)  {
		//Download Yahoo Finance Stock Info
		NSLog(@"Download Yahoo Finance Historical Data (-(void)stockChartDownload)");
		
		NSString *string1 = @"http://ichart.finance.yahoo.com/table.csv?s=";
		NSString *string2 = stock;	//Input into Method
		NSString *string3 = @"&g=d&ignore=.csv";
		
		float daysback = 365;										//70 days into the past
		NSDate *today = [NSDate date];											//todays date
		NSDate *newDate = [[NSDate date] addTimeInterval:-3600*24*daysback];	//set old date
		
		//put into a,b,c d,e,f
		//a=00&b=15&c=2010&d=01&e=15&f=2010
		//for full URL: http://ichart.finance.yahoo.com/table.csv?s=AAPL&a=00&b=15&c=2010&d=01&e=15&f=2010&g=d&ignore=.csv
		
		NSLog(@"todays date (formatted) %@",today);
		NSLog(@"lastmonths date (formatted) %@",newDate);
		NSDateFormatter *dateFormatdd = [[NSDateFormatter alloc] init];
		NSDateFormatter *dateFormatMM = [[NSDateFormatter alloc] init];
		NSDateFormatter *dateFormatyyyy = [[NSDateFormatter alloc] init];
		
		[dateFormatdd setDateFormat:@"dd"];
		[dateFormatMM setDateFormat:@"MM"];
		[dateFormatyyyy setDateFormat:@"yyyy"];
		
		NSString *yahooatemp = [dateFormatMM stringFromDate:today];
		int yahooatemp2 = [yahooatemp intValue]-1;
		NSString *yahooa = [NSString stringWithFormat:@"%d", yahooatemp2];
		if (yahooa.length==1) {
			yahooa = [NSString stringWithFormat:@"0%d", yahooatemp2];
		}
		
		NSString *yahoob = [dateFormatdd stringFromDate:today];
		NSString *yahooc = [dateFormatyyyy stringFromDate:today];
		
		NSString *yahoodtemp = [dateFormatMM stringFromDate:newDate];
		int yahoodtemp2 = [yahoodtemp intValue]-1;
		NSString *yahood = [NSString stringWithFormat:@"%d", yahoodtemp2];
		if (yahood.length==1) {
			yahood = [NSString stringWithFormat:@"0%d", yahoodtemp2];
		}
		
		NSString *yahooe = [dateFormatdd stringFromDate:newDate];
		NSString *yahoof = [dateFormatyyyy stringFromDate:newDate];
		
		NSString *dateString = [NSString stringWithFormat:@"&a=%@&b=%@&c=%@", yahood, yahooe, yahoof];
		NSString *dateString2 = [NSString stringWithFormat:@"&d=%@&e=%@&f=%@", yahooa, yahoob, yahooc];	
		NSLog(@"todays date (formatted) %@",dateString);
		NSLog(@"lastmonths date (formatted) %@",dateString2);
		
		NSString *downloadURL = [NSString stringWithFormat:@"%@%@%@%@%@", string1, string2, dateString,dateString2, string3];
		NSLog(@"Data Download URL:%@",downloadURL);
		
		NSURL *url = [NSURL URLWithString:downloadURL];
		NSData *data = [NSData dataWithContentsOfURL:url];
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		//Save to File
		
		//Get a nicely formatted date to use in the filename
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyyMM-dd-HHmmss"];
		NSString* currentTime = [dateFormatter stringFromDate:[NSDate date]];
		[dateFormatter release];
		currentTime = [currentTime stringByAppendingString:@".csv"];
		NSString *filename = [@"ichart-" stringByAppendingString:currentTime];
		
		//Assign File
		NSString *appFile = [documentsDirectory stringByAppendingPathComponent:filename];
		[data writeToFile:appFile atomically:YES];
		NSString *fileString = [NSString stringWithContentsOfURL:url 
														encoding:NSUTF8StringEncoding error:nil];
		//Parse the new CSV
		//Regex CSV Parsing
		NSString   *newlineRegex      = @"(?:\r\n|[\n\v\f\r\\x85\\p{Zl}\\p{Zp}])";
		NSString   *splitCSVLineRegex = @",(?=(?:(?:[^\"\\\\]*+|\\\\\")*\"(?:[^\"\\\\]*+|\\\\\")*\")*(?!(?:[^\"\\\\]*+|\\\\\")*\"(?:[^\"\\\\]*+|\\\\\")*$))";
		
		// Create a NSArray of every line in csvFileString.
		NSArray    *csvLinesArray     = [fileString componentsSeparatedByRegex:newlineRegex];
		
		// Create an id array to hold the comma split line results.
		id          splitLines[[csvLinesArray count]]; // C99 variable length array.
		NSUInteger  splitLinesIndex = 0UL;             // Index of next splitLines[] member.
		
		for(NSString *csvLineString in csvLinesArray) {                // ObjC 2 for…in loop.
			if([csvLineString isMatchedByRegex:@"^\\s*$"]) { continue; } // Skip empty lines.
			splitLines[splitLinesIndex++] = [csvLineString componentsSeparatedByRegex:splitCSVLineRegex];
		}
		
		// Gather up all the individual comma split results in to a single NSArray.
		NSArray *splitLinesArray = [NSArray arrayWithObjects:&splitLines[0] count:splitLinesIndex];
		
		//NSLog(@"%@",splitLinesArray);		//works
		NSLog(@"---------------");	
		
		NSMutableArray *arrayDates = [NSMutableArray array];
		NSMutableArray *arrayValues = [NSMutableArray array];
		NSString *temp;
		NSString *temp2;
		NSString *temp3;
        
        NSString *temp3d = @"";
        NSString *temp3m = @"";
        NSString *temp3y = @"";    
        
		for (int i=1; i<[splitLinesArray count]; i++) {
            temp = [[splitLinesArray objectAtIndex: i]  objectAtIndex:6];
			[arrayValues addObject:temp];
            
            temp2 = [[splitLinesArray objectAtIndex: i]  objectAtIndex:0];
            temp2 = [temp2 stringByReplacingOccurrencesOfString:@"-" withString:@"/"];
            
            temp3y = [temp2 substringToIndex:4];
            temp3d = [temp2 substringFromIndex:8];     
            temp3m = [[temp2 substringToIndex:7] substringFromIndex:5];
            
            temp3 = [NSString stringWithFormat:@"%@/%@/%@",temp3d,temp3m,temp3y];
			[arrayDates addObject:temp3];  
            
            //format - 2012/04/02 -> 02/04/2012
            //NSLog(@"temp2 -> temp3: %@ -> %@",temp2, temp3);
		}
        
        stockChartDownloadDates = [[arrayDates reverseObjectEnumerator] allObjects];
        stockChartDownloadValues = [[arrayValues reverseObjectEnumerator] allObjects];   
        
        //Change from just Close Value, to full data array (6 apr. 2012)
        //stockChartDownload = [[array2 reverseObjectEnumerator] allObjects];

        NSMutableDictionary *graphDict = [[NSMutableDictionary alloc] init];
        [graphDict setObject:stockChartDownloadDates forKey:@"dates"];
        [graphDict setObject:stockChartDownloadValues forKey:@"values"];
        

        //[dateFormatterTwo release];
        
        //Set Actual Filename
        NSArray* cachePathArray = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString* cachePath = [cachePathArray lastObject];
        NSString *dataStr = [NSString stringWithFormat:@"stockChartData-365-%@-%@.plist",dateStringNow,stock];
        NSString *path = [cachePath stringByAppendingPathComponent:dataStr];
        [graphDict writeToFile:path atomically:YES];
        
        return graphDict;

	} else {
        
        NSLog(@"Graph Data already downloaded");
		//Read in Data from plist
        NSArray* cachePathArray = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString* cachePath = [cachePathArray lastObject];
        NSString *dataStr = [NSString stringWithFormat:@"stockChartData-365-%@-%@.plist",dateStringNow,stock];
        NSString *path = [cachePath stringByAppendingPathComponent:dataStr];
        
        //Define new array for data
        NSMutableDictionary *cachedGraphDict = [[NSMutableDictionary alloc] init];
        cachedGraphDict = [NSDictionary dictionaryWithContentsOfFile:path];	//fill array with cache data

        NSLog(@"cachedGraphDict: OK");        
        return  cachedGraphDict;       

	}
	

}

-(NSDictionary*)stockChartDownloadVersionTwo:(NSString *)stock days:(int)dayData {
    //This loookup is a new data source/API I found. The link is:
    //http://chartapi.finance.yahoo.com/instrument/1.0/AAPL/chartdata;type=quote;range=1d/csv/
    //ItsGoingUp Implementation, is 1D and 5D only
    //This class is not for 1m, 3m, 6m or 12m

    //Download Yahoo Finance Stock Info
    NSLog(@"Download Yahoo Finance Historical Data Version 2 - chartapi.finance.yahoo.com Data: %@, %d",stock,dayData);
    //For good data. 1 day -> '1d' 
    //               5 day -> '5d'  
    //               14days > '2w'

    
    NSString *string1 = @"http://chartapi.finance.yahoo.com/instrument/1.0/";
    NSString *string2 = stock;	//Input into Method
    NSString *string3 = @"/chartdata;type=quote;range=";    
    NSString *string4 = [NSString stringWithFormat:@"%d",dayData];       //number of days/weeks to lookup
    NSString *string5 = @"d";
    NSString *string6 = @"/csv/";
    
    //Download URL
    NSString *downloadURL = [NSString stringWithFormat:@"%@%@%@%@%@%@", string1, string2, string3,string4, string5,string6];
    NSLog(@"new download URL: %@",downloadURL);
    //for full URL: http://chartapi.finance.yahoo.com/instrument/1.0/AAPL/chartdata;type=quote;range=1d/csv/
    

    NSURL *url = [NSURL URLWithString:downloadURL];
    //NSData *data = [NSData dataWithContentsOfURL:url];
    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //NSString *documentsDirectory = [paths objectAtIndex:0];
    
    
    //Get a nicely formatted date to use in the filename
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMM-dd-HHmmss"];
    NSString* currentTime = [dateFormatter stringFromDate:[NSDate date]];
    [dateFormatter release];
    currentTime = [currentTime stringByAppendingString:@".csv"];
    //NSString *filename = [@"ichartv2-" stringByAppendingString:currentTime];

    //Assign File
    //NSString *appFile = [documentsDirectory stringByAppendingPathComponent:filename];
    //[data writeToFile:appFile atomically:YES];    //writes data to datadir
    
    NSString *fileString = [NSString stringWithContentsOfURL:url  encoding:NSUTF8StringEncoding error:nil]; //actua download data
    //Parse the new CSV
    //Regex CSV Parsing
    NSString   *newlineRegex      = @"(?:\r\n|[\n\v\f\r\\x85\\p{Zl}\\p{Zp}])";
    NSString   *splitCSVLineRegex = @",(?=(?:(?:[^\"\\\\]*+|\\\\\")*\"(?:[^\"\\\\]*+|\\\\\")*\")*(?!(?:[^\"\\\\]*+|\\\\\")*\"(?:[^\"\\\\]*+|\\\\\")*$))";
    
    // Create a NSArray of every line in csvFileString.
    NSArray    *csvLinesArray     = [fileString componentsSeparatedByRegex:newlineRegex];
    
    // Create an id array to hold the comma split line results.
    id          splitLines[[csvLinesArray count]]; // C99 variable length array.
    NSUInteger  splitLinesIndex = 0UL;             // Index of next splitLines[] member.
    
    for(NSString *csvLineString in csvLinesArray) {                // ObjC 2 for…in loop.
        if([csvLineString isMatchedByRegex:@"^\\s*$"]) { continue; } // Skip empty lines.
        splitLines[splitLinesIndex++] = [csvLineString componentsSeparatedByRegex:splitCSVLineRegex];
    }
    
    // Gather up all the individual comma split results in to a single NSArray.
    NSArray *splitLinesArray = [NSArray arrayWithObjects:&splitLines[0] count:splitLinesIndex];
    
    //NSLog(@"%@",splitLinesArray);		//works
    NSLog(@"---------------");	
    
    
    
    NSMutableArray *arrayDates = [NSMutableArray array];
    NSMutableArray *arrayValues = [NSMutableArray array];
    NSMutableArray *arrayDebug = [NSMutableArray array];
    
    NSString *temp0;
    NSString *temp;
    NSString *temp2;
  
    //NSLog(@"[splitLinesArray count] : %d",[splitLinesArray count]);
    //NSLog(@"[splitLinesArray objectAtIndex: 0] %@", [splitLinesArray objectAtIndex: 0]);
    
    //Create Debug Data array (lines 0-14 or 0-20 of API Call)
    int startLine = 0;
    if (dayData == 14) startLine = 15; else startLine = 20; //have correct start line depending on data type
    
    for (int i=0; i<startLine; i++) {
        temp0 = [splitLinesArray objectAtIndex: i];
        [arrayDebug addObject:temp0];
    }
    
    //NSLog(@"Debug Array: %@",arrayDebug);
    
    //Find Timezone:
    NSString *stockTimeZone = [[[arrayDebug  objectAtIndex:5] objectAtIndex:0] substringFromIndex:10];    //Get the Timezone in GMT Offset Mode
    NSArray *stockTimeStampOpenClose = [arrayDebug  objectAtIndex:7];    //Get the Open and Close time of the Stock Data (TimeStamp from the API)
    //Create Values and Dates Array
    for (int i=startLine; i<[splitLinesArray count]; i++) {
        
        temp = [[splitLinesArray objectAtIndex: i]  objectAtIndex:1];
        [arrayValues addObject:temp];
        
        temp2 = [[splitLinesArray objectAtIndex: i]  objectAtIndex:0];
        
        if ([string5 isEqualToString:@"d"]) {
            NSDate *stockDate = [NSDate dateWithTimeIntervalSince1970:[temp2 intValue]];
            [arrayDates addObject:stockDate];
            
        } else {
            
            //NSDate *stockDate = [NSDate dateWithTimeIntervalSince1970:[temp2 intValue]];
            
            //NSString *dateStr = @"Tue, 25 May 2010 12:53:58 +0000";
            //20110411
            NSString *dateStr = temp2;  // 20110411
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];  // Convert string to date object
            [dateFormat setDateFormat:@"yyyyMMdd"];
            NSDate *date = [dateFormat dateFromString:dateStr]; 
            [dateFormat release];
            
            //NSLog(@"TODO: Fix up this date when not in day mode");
            [arrayDates addObject:date];
            
        }

        //NSLog(@"stockDate: %@",stockDate);

        //[arrayDates addObject:temp2];

    }

    //Change from just Close Value, to full data array (6 apr. 2012)
    stockChartDownloadDates = [[arrayDates reverseObjectEnumerator] allObjects];
    stockChartDownloadValues = [[arrayValues reverseObjectEnumerator] allObjects];      
    //This data needs to be re-reversed. it needs to reversed at least once, so i do it twice (order is OK)
    stockChartDownloadDates = [[stockChartDownloadDates reverseObjectEnumerator] allObjects];
    stockChartDownloadValues = [[stockChartDownloadValues reverseObjectEnumerator] allObjects];   
    
    NSMutableDictionary *graphDict = [[NSMutableDictionary alloc] init];
    [graphDict setObject:stockChartDownloadDates forKey:@"dates"];
    [graphDict setObject:stockChartDownloadValues forKey:@"values"];
    [graphDict setObject:stockTimeZone forKey:@"time zone"];
    [graphDict setObject:stockTimeStampOpenClose forKey:@"stockTimeStampOpenClose"];
    
   // NSLog(@"graphDict: %@",graphDict);
    
    //[dateFormatterTwo release];
    
    //If 5 day data, save data into a plist for later reading
    //NSArray* cachePathArray = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
   // NSString* cachePath = [cachePathArray lastObject];
   // NSString *dataStr = [NSString stringWithFormat:@"stockChartData-5-%@-%@.plist",@"now",stock];
   // NSString *path = [cachePath stringByAppendingPathComponent:dataStr];
   // [graphDict writeToFile:path atomically:YES];
    
    NSLog(@"Finished Executing stockChartDownloadVersionTwo");
    
    return graphDict; 
 
}
    

- (float)answerToLife{
	answerToLife = 42;
	return answerToLife;
}



- (int)age{
	age = 23;
	return age;
}


@end
