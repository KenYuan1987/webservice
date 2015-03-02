//
//  WsResult.m
//  ticket
//
//  Created by ken on 14-2-20.
//  Copyright (c) 2014年 ken. All rights reserved.
//

#import "DemoResponse.h"

//action：接口名称
//code：返回状态码
//reason：提示信息
//v：接口版本号
//data：返回数据

#define WebServiceActionKey @"action"
#define WebServicePayLoadKey @"data"
#define WebServiceMessageKey @"reason"
#define WebServiceVersionKey @"v"
#define WebServiceReturnCodeKey @"code"

#define failCode 4000
#define successCode 4001
#define timeoutCode 4002
#define sessionExpired 4003

NSString *SessionExpiredNotification = @"SessionExpiredNotification";
NSInteger const WsResultUserCancelErrorCode = NSURLErrorCancelled; //4 for asi

@implementation DemoResponse

-(id)initWithDictionary:(NSDictionary*)dic
{
    self = [super initWithDictionary:dic];
    if(self)
    {
        if(self.code == sessionExpired){
            [[NSNotificationCenter defaultCenter] postNotificationName:SessionExpiredNotification object:nil];
            NSLog(@"session expired");
        }
    }
    return self;
}

-(BOOL)checkResultReturnCode:(NSInteger)code
{
    if(code == successCode)
        return YES;
    else
        return NO;
}

@end
