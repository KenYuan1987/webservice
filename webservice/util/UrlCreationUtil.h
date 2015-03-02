//
//  GJUtility.h
//  whiteSpace
//
//  Created by Ken on 13-2-26.
//  Copyright (c) 2013年 Ken. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface UrlCreationUtil : NSObject
+(NSString *)createMD5:(NSString *)sourceStr;
+(NSString*)getImei;
+(NSString*)getDeviceType;
+(NSString*)getDeviceName;
+(NSString*)getSystemVersion;
+(NSString*)getAppVersion;
+(NSString*)getServiceName;
+(NSString*)getServerPort;
+(NSString*)getHost;
@end
