//
//  Route.m
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import "Route.h"
#import "CSVParser.h"
#import "FMDatabase.h"
#import "Util.h"

@interface Route ()
{
    FMDatabase *db;
}

@end

@implementation Route

- (id) initWithDB:(FMDatabase *)fmdb
{
    self = [super init];
	if (self)
	{
		db = fmdb;
	}
	return self;
}

- (void)addRoute:(Route *)route
{
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            return;
        }
    }
    
    [db executeUpdate:@"INSERT into routes(route_color,route_text_color,route_url,route_long_name,route_type,route_id,route_short_name) values(?, ?, ?, ?, ?, ?, ?)",
     route.routeColorHex,
     route.routeTextColorHex,
     route.routeUrl,
     route.routeLongName,
     route.routeType,
     route.routeId,
     route.routeShortName];
    
    if ([db hadError]) {
        NSLog(@"Route Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
}

- (void)cleanupAndCreate
{
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            return;
        }
    }
    
    //Drop table if it exists
    NSString *drop = @"DROP TABLE IF EXISTS routes";
    
    [db executeUpdate:drop];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
    
    //Create table
    NSString *create = @"CREATE TABLE 'routes' ('route_url' varchar(255) DEFAULT NULL, 'route_color' varchar(255) DEFAULT NULL, 'route_text_color' varchar(255) DEFAULT NULL, 'route_long_name' varchar(255) DEFAULT NULL,'route_type' int(2) DEFAULT NULL, 'route_id' varchar(11) NOT NULL, 'route_short_name' varchar(50) DEFAULT NULL, PRIMARY KEY ('route_id'))";
    
    [db executeUpdate:create];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
}

- (void)receiveRecord:(NSDictionary *)aRecord
{
    Route *routeRecord = [[Route alloc] init];
    routeRecord.routeId = aRecord[@"route_id"];
    routeRecord.routeLongName = [aRecord[@"route_long_name"] capitalizedString];
    routeRecord.routeShortName = [aRecord[@"route_short_name"] capitalizedString];
    routeRecord.routeType = aRecord[@"route_type"];
    routeRecord.routeColorHex = aRecord[@"route_color"];
    routeRecord.routeTextColorHex = aRecord[@"route_text_color"];
    routeRecord.routeUrl = aRecord[@"route_url"];
    
    [self addRoute:routeRecord];
}

+ (NSArray *)getAllRoutes
{
    
    NSMutableArray *routes = [[NSMutableArray alloc] init];
    
    FMDatabase *localdb = [FMDatabase databaseWithPath:[Util getDatabasePath]];
    
    [localdb setShouldCacheStatements:YES];
    if (![localdb open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return nil;
    }
    
    NSString *query = @"select * FROM routes";
    
    FMResultSet *rs = [localdb executeQuery:query];
    while ([rs next]) {
        // just print out what we've got in a number of formats.
        NSMutableDictionary *route = [[NSMutableDictionary alloc] init];
        route[@"route_id"] = [rs objectForColumnName:@"route_id"];
        route[@"route_long_name"] = [rs objectForColumnName:@"route_long_name"];
        route[@"route_short_name"] = [rs objectForColumnName:@"route_short_name"];
        route[@"route_color"] = [rs objectForColumnName:@"route_color"];
        route[@"route_text_color"] = [rs objectForColumnName:@"route_text_color"];
        route[@"route_url"] = [rs objectForColumnName:@"route_url"];
        
        [routes addObject:route];
    }
    // close the result set.
    [rs close];
    [localdb close];
    
    return routes;
}

+ (NSArray *)getAllRoutesForStops
{
    
    NSMutableArray *routes = [[NSMutableArray alloc] init];
    
    FMDatabase *localdb = [FMDatabase databaseWithPath:[Util getDatabasePath]];
    
    [localdb setShouldCacheStatements:YES];
    if (![localdb open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return nil;
    }
    
    NSString *query = @"select routes.route_short_name, trips.route_id, trips.trip_headsign, trips.trip_id FROM routes, trips WHERE trips.route_id=routes.route_id";
    
    FMResultSet *rs = [localdb executeQuery:query];
    while ([rs next]) {
        // just print out what we've got in a number of formats.
        NSMutableDictionary *route = [[NSMutableDictionary alloc] init];
        route[@"route_id"] = [rs objectForColumnName:@"route_id"];
        route[@"trip_headsign"] = [rs objectForColumnName:@"trip_headsign"];
        route[@"trip_id"] = [rs objectForColumnName:@"trip_id"];
        route[@"route_short_name"] = [rs objectForColumnName:@"route_short_name"];
        
        
        [routes addObject:route];
        
    }
    // close the result set.
    [rs close];
    [localdb close];
    
    return routes;
}

@end
