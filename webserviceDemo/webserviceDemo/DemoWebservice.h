//
//  SuperCardWebserviceForAF.h
//  SuperCard
//
//  Created by ken on 15-1-27.
//  Copyright (c) 2015年 ken. All rights reserved.
//

#import "XGRequestBase.h"
#import "DemoResponse.h"
#import <CoreLocation/CoreLocation.h>

@interface DemoWebservice : XGRequestBase
@property(nonatomic,copy) NSString *cardID;
@property(nonatomic,readonly) NSString *session;

-(void)clearSession;

-(void)businessZones:(NSString*)city complete:(void(^)(DemoResponse*))result;

@end
