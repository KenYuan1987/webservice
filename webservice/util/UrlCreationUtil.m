//
//  GJUtility.m
//  whiteSpace
//
//  Created by Ken on 13-2-26.
//  Copyright (c) 2013年 Ken. All rights reserved.
//

#import "UrlCreationUtil.h"
#import <CommonCrypto/CommonDigest.h>
#import <sys/sysctl.h>
#import <sys/socket.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <netdb.h>
#import <arpa/inet.h>
#import <UIKit/UIKit.h>

#define webserviceKey @"Webservice config"
#define hostnameKey @"Host name"
#define serviceNameKey @"Service name"
#define portKey @"Port"


@implementation UrlCreationUtil

+(NSString *)createMD5:(NSString *)sourceStr
{
    const char*cStr =[sourceStr UTF8String];
    if(cStr == NULL) return nil;
    unsigned char result[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    return[NSString stringWithFormat:
           @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
           result[0], result[1], result[2], result[3],
           result[4], result[5], result[6], result[7],
           result[8], result[9], result[10], result[11],
           result[12], result[13], result[14], result[15]
           ];
}

+(NSString *) macaddress{
    
    static NSString *outstring;
    if(outstring) return outstring;
    int                 mib[6];
    size_t              len;
    char                *buf;
    unsigned char       *ptr;
    struct if_msghdr    *ifm;
    struct sockaddr_dl  *sdl;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1\n");
        return NULL;
    }
    
    if ((buf = malloc(len)) == NULL) {
        printf("Could not allocate memory. error!\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 2");
        free(buf);
        return NULL;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    outstring = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                 *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    free(buf);
    
    return outstring;
}

+ (NSString*)getImei
{
    static NSString *macAddressMD5String;
    if(!macAddressMD5String)
    {
        if([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)])
        {
            macAddressMD5String = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        }
        else
        {
            NSString *macAddress=[UrlCreationUtil macaddress];
            macAddressMD5String=[UrlCreationUtil createMD5:macAddress];
        }
    }
    return macAddressMD5String;
}

+(NSString*)getDeviceType
{
    static NSString *deviceType;
    if(!deviceType)
    {
        UIDevice *device=[UIDevice currentDevice];
        deviceType=device.localizedModel;
    }
    return deviceType;
}

+(NSString*)getDeviceName{
    static NSString *deviceName;
    if(!deviceName)
    {
        UIDevice *device=[UIDevice currentDevice];
        deviceName=device.name;
    }
    return deviceName;
}

+(NSString*)getSystemVersion
{
    static NSString *systemVersion;
    if(!systemVersion)
    {
        UIDevice *device=[UIDevice currentDevice];
        systemVersion=device.systemVersion;
    }
    return systemVersion;
}

+(NSString*)getAppVersion
{
    static NSString *appVersion;
    if(!appVersion)
    {
        NSBundle *bundle=[NSBundle mainBundle];
        NSDictionary *infoDic=[bundle infoDictionary];
        appVersion=[infoDic objectForKey:@"CFBundleVersion"];
    }
    return appVersion;
}

+(NSString*)getServiceName
{
    static NSString *serviceName;
    if(!serviceName)
    {
        NSDictionary *webserviceDic=[[NSBundle mainBundle]objectForInfoDictionaryKey:webserviceKey];
        serviceName=[webserviceDic objectForKey:serviceNameKey];
    }
    return serviceName;
}

+(NSString*)getHost{
    static NSString *host;
    if(!host)
    {
        NSDictionary *webserviceDic=[[NSBundle mainBundle]objectForInfoDictionaryKey:webserviceKey];
        host=[webserviceDic objectForKey:hostnameKey];
    }
    return host;
}

+(NSString*)getServerPort
{
    static NSString *port;
    if(!port)
    {
        NSDictionary *webserviceDic=[[NSBundle mainBundle]objectForInfoDictionaryKey:webserviceKey];
        port=[webserviceDic objectForKey:portKey];
    }
    return port;
}

@end
