//
//  Agency.m
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import "Agency.h"
#import "CSVParser.h"
#import "FMDatabase.h"
#import "Util.h"

@interface Agency ()
{
    FMDatabase *db;
}

@end

@implementation Agency

- (id)initWithDB:(FMDatabase *)fmdb
{
    self = [super init];
	if (self)
	{
		db = fmdb;
	}
	return self;
}

- (void)addAgency:(Agency *)agency
{
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            return;
        }
    }
    
    [db executeUpdate:@"INSERT into agency(agency_name, agency_timezone, agency_url) values(?, ?, ?)",
                        agency.agencyName,
                        agency.agencyTimezone,
                        agency.agencyUrl];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
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
    NSString *dropAgency = @"DROP TABLE IF EXISTS agency";
    
    [db executeUpdate:dropAgency];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
    
    //Create table
    NSString *createAgency = @"CREATE TABLE 'agency' ('agency_url' varchar(255) DEFAULT NULL, 'agency_name' varchar(255) DEFAULT NULL, 'agency_timezone' varchar(50) DEFAULT NULL, PRIMARY KEY ('agency_name'))";
    
    [db executeUpdate:createAgency];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
}

- (void)receiveRecord:(NSDictionary *)aRecord
{
    
    Agency *agencyRecord = [[Agency alloc] init];
    agencyRecord.agencyName = aRecord[@"agency_name"];
    agencyRecord.agencyTimezone = aRecord[@"agency_timezone"];
    agencyRecord.agencyUrl = aRecord[@"agency_url"];
    
    [self addAgency:agencyRecord];
}



@end
