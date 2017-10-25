//
//  SRKObject.m
//  SharkORM
//
//  Created by Adrian Herridge on 25/10/2017.
//  Copyright © 2017 Adrian Herridge. All rights reserved.
//

#import "SharkORM.h"
#import "SRKEntity+Private.h"
#import "SRKDefinitions.h"

@implementation SRKObject {
    id cachedPrimaryKeyValue;
}

@dynamic Id;

/* Primary Key Support */
- (id)Id {
    if (!cachedPrimaryKeyValue) {
        cachedPrimaryKeyValue = [self getField:SRK_DEFAULT_PRIMARY_KEY_NAME];
    }
    return cachedPrimaryKeyValue;
}

- (void)setId:(id)value {
    cachedPrimaryKeyValue = value;
    [self setFieldRaw:SRK_DEFAULT_PRIMARY_KEY_NAME value:value];
}

- (void)setCachedPrimaryKey:(id)key {
    cachedPrimaryKeyValue = key;
}

@end
