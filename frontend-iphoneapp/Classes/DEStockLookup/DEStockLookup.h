//
//  deStockLookup.h
//  ItsGoingUp
//
//  Created by Benjamin M. Duivesteyn on 18.02.10.
//  Copyright 2010 TBA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"
#import "RegexKitLite.h"

@interface DeStockLookup : NSObject {

	
	//Got Internets?
	NSString *internetReachability;
	BOOL gotInternet;	
	
	float stockUpdate;	
	NSArray *testArray;
	NSArray *StockUpdateNew;
	NSArray	*stockChartDownloadDates;//array with stock history
	NSArray	*stockChartDownloadValues;//array with stock history	
	//Stock Output Table
	
	NSMutableArray *stockCSVArray;

	//Stock Chart
	NSArray *stockHistoryChart;	//array with stock history
	
	IBOutlet UILabel *labelTradingVolume;	
	
	int age;
	float answerToLife;


	int currentPrice;
	

}


//temp
-(void)testAccessMethod;
-(void)testReturnMethod:(NSString *)stockString;
-(int)age;
-(float)answerToLife;
-(NSArray*)testArray;

//stock lookup from y!
-(NSArray*)StockUpdateNew:(NSString *)stock;

//chart lookup from y!
//-(NSArray*)stockChartDownload;
-(NSDictionary*)stockChartDownload:(NSString *)stock;
//-(NSDictionary*)stockChartDownloadVersionTwo:(NSString *)stock;
-(NSDictionary*)stockChartDownloadVersionTwo:(NSString *)stock days:(int)days;
//test internet
-(BOOL)checkInternet;
@end
