//
//  WebserviceReachability.m
//  ticket
//
//  Created by ken on 14-3-19.
//  Copyright (c) 2014年 ken. All rights reserved.
//

#import "WebserviceReachability.h"
#import "UrlCreationUtil.h"
#import "Reachability.h"

@implementation WebserviceReachability
static Reachability *reach;

+(void)load{
    [[self webserviceReachability] startNotifier];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

+(void)didEnterForeground:(NSNotification *)notification{
    [[self webserviceReachability] startNotifier];
}

+(void)didEnterBackground:(NSNotification *)notification{
    [[self webserviceReachability] startNotifier];
}

+(Reachability*)webserviceReachability
{
    if (!reach) {
        NSAssert([[UrlCreationUtil getHost] length], @"info.plist没有加入webservice config,可参考例子<key>Webservice config</key><dict><key>Host name</key><string>supercards.xiaogu8.com</string><key>Port</key><string>80</string><key>Service name</key><string>mobile/api</string><key>Service name-dev</key><string>GuanJiaHuilinV2</string></dict>");
        reach=[Reachability reachabilityWithHostName: [UrlCreationUtil getHost]];
    }
    return reach;
}

+(BOOL)isWebserviceReachable
{
    return reach.currentReachabilityStatus != NotReachable;
}

@end
