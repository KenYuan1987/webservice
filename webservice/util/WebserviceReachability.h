//
//  WebserviceReachability.h
//  ticket
//
//  Created by ken on 14-3-19.
//  Copyright (c) 2014年 ken. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>


@interface WebserviceReachability : NSObject
+(BOOL)isWebserviceReachable;

#undef ONCE_REACH_WEBSERVICE
#define ONCE_REACH_WEBSERVICE(__doSomething,__stopUntil)\
if([WebserviceReachability isWebserviceReachable])\
{\
    __doSomething;\
}\
else\
{\
    __block id observer = [[NSNotificationCenter defaultCenter] addObserverForName:kReachabilityChangedNotification object:nil queue:nil usingBlock:^(NSNotification *note) {\
    Reachability *reach = (Reachability*)note.object;\
    if(reach.currentReachabilityStatus != NotReachable)\
    {\
        if(__stopUntil)\
            [[NSNotificationCenter defaultCenter]removeObserver:observer];\
        __doSomething;\
        }\
    }];\
}\


@end
