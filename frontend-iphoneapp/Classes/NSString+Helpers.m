//
//  NSString+Helpers.m
//  SavingGoal
//
//  Created by Ben Michael on 15.03.10.
//  Copyright 2010 de. All rights reserved.
//

#import "NSString+Helpers.h"

@implementation NSString (Helpers)

- (NSString *) stringBySubstitutingInfoTokens
{
	NSMutableString *tmpString = [NSMutableString stringWithString:self];
	NSScanner *scanner = [NSScanner scannerWithString:self];
	
	NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
	
	
	while (![scanner isAtEnd])
	{
		if ([scanner scanString:@"$" intoString:nil])
		{
			NSString *tokenName;
			
			if ([scanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&tokenName])
			{
				id value = [infoDict objectForKey:tokenName];
				
				if (value && [value isKindOfClass:[NSString class]])
				{
					[tmpString replaceOccurrencesOfString:[@"$" stringByAppendingString:tokenName] withString:value options:NSLiteralSearch range:NSMakeRange(0, [tmpString length])];
				}
			}
		}
		
		[scanner scanUpToString:@"$" intoString:nil];
	}
	
	return [NSString stringWithString:tmpString];
}
@end