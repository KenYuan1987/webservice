//
//  SuperCardWebserviceForAF.m
//  SuperCard
//
//  Created by ken on 15-1-27.
//  Copyright (c) 2015年 ken. All rights reserved.
//

#import "DemoWebservice.h"
#import "UrlCreationUtil.h"

#define sessionKey @"SCARD_SESSION"

@interface DemoWebservice()
@property(nonatomic,readwrite) NSString *session;
@end

@implementation DemoWebservice
-(id)init
{
    self=[super init];
    if(self)
    {
       
    }
    return self;
}

-(Class)responseClass:(NSString *)method{
    return [DemoResponse class];
}

-(NSDictionary*)createReturnDataFromError:(NSError *)error
{
    if(error){
        if (error.code == NSURLErrorCancelled) {
            return [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%ld",(long)NSURLErrorCancelled],@"code",@"用户中途取消",@"reason", @YES,WebserviceRequestFailKey,nil];
        }else if (error.code == NSURLErrorUserCancelledAuthentication){
            return [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%ld",(long)NSURLErrorUserCancelledAuthentication],@"code",@"网络繁忙,请稍后再试",@"reason", @YES,WebserviceRequestFailKey,nil];
        }
        else{
            return [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%ld",(long)error.code],@"code",error.userInfo[NSLocalizedDescriptionKey],@"reason", @YES,WebserviceRequestFailKey,nil];
        }
    }else{
        return [NSDictionary dictionaryWithObjectsAndKeys:@"0",@"code",@"未知网络错误",@"reason", @YES,WebserviceRequestFailKey,nil];
    }
}

-(NSURL*)createUrlFor:(NSString*)method withJsonStr:(NSString*)jsonStr
{
    //NSString *port=[GJUtility getServerPort];
    NSString *rootUrl=[UrlCreationUtil getHost];
    NSString *serviceName=[UrlCreationUtil getServiceName];
    NSString *urlStr=[NSString stringWithFormat:@"https://%@/%@/%@",rootUrl,serviceName,method];
    NSString *encodeUrlStr=[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url=[NSURL URLWithString:encodeUrlStr];
    return url;
}

-(NSDictionary*)preProcessParams:(NSDictionary*)dic forMethod:(NSString*)method
{
    return dic;
}

-(void)configRequest:(NSMutableURLRequest*)request{
    //    DeviceId：			imei号
    //    Model：			机型
    //    Product：			产品名
    //    Device：			设备名
    //    Board：				主板类型
    //    ProtocolVersion：	协议版本号
    //    CardId：			卡号（如果是未登录状态，该内容为空）
    [request addValue:[UrlCreationUtil getImei] forHTTPHeaderField:@"DeviceId"];
    [request addValue:[UrlCreationUtil getDeviceType] forHTTPHeaderField:@"Model"];
    [request addValue:[UrlCreationUtil getDeviceType] forHTTPHeaderField:@"Product"];
    [request addValue:[UrlCreationUtil getDeviceName] forHTTPHeaderField:@"Device"];
    [request addValue:[UrlCreationUtil getSystemVersion] forHTTPHeaderField:@"Board"];
    [request addValue:@"0" forHTTPHeaderField:@"ProtocolVersion"];
    [request addValue:self.cardID forHTTPHeaderField:@"CardId"];

    NSString *session = self.session;
    if([session length])
        [request addValue:session forHTTPHeaderField:@"SCARD_SESSION"];
//    [request setValidatesSecureCertificate:YES];
//    [request setClientCertificateIdentity:nil];
}

static NSString *_staticCardID = @"";
-(NSString*)cardID{
    return _staticCardID;
}

-(void)setCardID:(NSString*)cardID{
    _staticCardID = cardID;
}

-(NSString*)session{
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[self createUrlFor:@"noMethod" withJsonStr:nil]];
    NSHTTPCookie *cookie;
    for (cookie in cookies) {
        if([cookie.name isEqualToString:sessionKey])
            _session = cookie.value;
    }
    return _session;
}

-(void)clearSession{
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[self createUrlFor:@"noMethod" withJsonStr:nil]];
    NSHTTPCookie *cookie;
    for (cookie in cookies) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
}

#pragma mark - interface

-(NSOperation *)businessZones:(NSString*)city complete:(void(^)(DemoResponse*))result{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:city,@"city", nil];
    return [self request:@"default/businessZones" withParams:params finish:^(XGResponseBase *r) {
        if (result) {
            result((DemoResponse *)r);
        }
    }];
}

@end
