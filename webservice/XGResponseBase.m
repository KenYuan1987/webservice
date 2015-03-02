//
//  WsResult.m
//  ticket
//
//  Created by ken on 14-2-20.
//  Copyright (c) 2014年 ken. All rights reserved.
//

#import "XGResponseBase.h"
NSString *const WebserviceErrorDomain = @"WebserviceErrorDomain";
@implementation XGResponseBase

- (void)preprocessData
{
    if([_rawData isKindOfClass:[NSArray class]])
    {
        _arrayData = _rawData;
    }
    else if([_rawData isKindOfClass:[NSDictionary class]])
    {
        _mapData = _rawData;
    }
}

-(id)initWithDictionary:(NSDictionary*)dic
{
    self = [super init];
    if(self)
    {
        _version = [dic valueForKeyPath:[self responseVersionKeyPath]];
        _method = [dic valueForKeyPath:[self responseMethodKeyPath]];
        _rawData = [dic valueForKeyPath:[self responseRawDataKeyPath]];
        _msg = [dic valueForKeyPath:[self responseMsgKeyPath]];
        _code = [[dic valueForKeyPath:[self responseCodeKeyPath]] integerValue];
        if([self checkResultReturnCode:_code])
            _isSuccess = YES;
        else
            _isSuccess = NO;
        if(_isSuccess)
        {
            [self preprocessData];
        }else{
            _error = [NSError errorWithDomain:WebserviceErrorDomain code:_code userInfo:@{NSLocalizedFailureReasonErrorKey:_msg}];
        }
    }
    return self;
}

-(BOOL)checkResultReturnCode:(NSInteger)code
{
    return YES;
}

-(NSString *)responseMethodKeyPath{
    return @"action";
}

-(NSString *)responseRawDataKeyPath{
    return @"data";
}

-(NSString *)responseVersionKeyPath{
    return @"version";
}

-(NSString *)responseMsgKeyPath{
    return @"msg";
}

-(NSString *)responseCodeKeyPath{
    return @"code";
}

@end
