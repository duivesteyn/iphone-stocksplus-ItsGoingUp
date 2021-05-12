//
//  SimpleCar.h
//  CarApp
//
//  Created by Mark Douma on 6/3/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Stock : NSObject {
    NSString* stockTicker;
    NSString* stockTargetPrice;
    NSString* stockBuyPrice;
    NSString* stockUnits;
}

// set methods
//- (void) setVin:   (NSNumber*)newVin;
//- (void) setMake:  (NSString*)newMake;
//- (void) setModel: (NSString*)newModel;

// convenience method
//- (void) setMake: (NSString*)newMake
//        andModel: (NSString*)newModel;

// get methods
//- (NSString*) make;
//- (NSString*) model;
//- (NSNumber*) vin;

@end
