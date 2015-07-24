//
//  Route.h
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;
#import "FMDatabase.h"

@interface Route : NSObject

@property (nonatomic, strong) NSString * routeLongName;
@property (nonatomic, strong) NSNumber * routeType;
@property (nonatomic, strong) NSString * routeId;
@property (nonatomic, strong) NSString * routeShortName;
@property (nonatomic, strong) NSString * agencyId;
@property (nonatomic, strong) NSString * routeColorHex;
@property (nonatomic, strong) NSString * routeTextColorHex;
@property (nonatomic, strong) NSString * routeUrl;

- (void)addRoute:(Route *)route;
- (id)initWithDB:(FMDatabase *)fmdb;
- (void)cleanupAndCreate;
- (void)receiveRecord:(NSDictionary *)aRecord;
+ (NSArray *)getAllRoutes;
+ (NSArray *)getAllRoutesForStops;

@end
