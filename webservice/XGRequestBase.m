//
//  GJWebServiceBaseForAF.m
//  SuperCard
//
//  Created by ken on 15-1-27.
//  Copyright (c) 2015年 ken. All rights reserved.
//

#import "XGRequestBase.h"
#import "AFNetworking.h"
#import "WebserviceReachability.h"
#import "Reachability.h"

#define identifyKey @"identifyKey"
#define completeBlockKey @"completeBlock"

@interface XGRequestBase()
@property(nonatomic,strong) AFHTTPRequestOperationManager *manager;
@property(nonatomic,strong) id webReachabilityObserver;
@end

@implementation XGRequestBase

-(id)init
{
    self=[super init];
    if(self)
    {
        self.manager = [AFHTTPRequestOperationManager manager];
        if (![WebserviceReachability isWebserviceReachable]) {
            self.manager.operationQueue.suspended = YES;
        }
        self.webReachabilityObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kReachabilityChangedNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            if ([WebserviceReachability isWebserviceReachable]) {
                self.manager.operationQueue.suspended = NO;
            }else{
                self.manager.operationQueue.suspended = YES;
            }
        }];
        _httpMethod=@"POST";
        _timeoutSecond=20;
        _retryTime = 0;
    }
    return self;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self.webReachabilityObserver];
}

#pragma mark before requesting

-(NSString*)jsonStringFromDictionary:(NSDictionary*)dic
{
    NSString *jsonstring;
    if(dic)
        jsonstring = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
    else
        jsonstring = @"";
    return jsonstring;
}

-(NSURL*)createUrlFor:(NSString*)method withJsonStr:(NSString*)jsonStr
{
    return nil;
}

-(NSDictionary*)createReturnDataFromError:(NSError*)error{
    return nil;
}

#pragma mark requesting
-(NSDictionary*)preProcessParams:(NSDictionary*)dic forMethod:(NSString*)method
{
    return dic;
}

-(void)request:(NSString*)method withParams:(NSDictionary*)dic complete:(void(^)(NSDictionary*))block
{
    NSDictionary *userInfo=[NSDictionary dictionaryWithObjectsAndKeys:block,completeBlockKey, nil];
    [self addRequestToQueueWithParams:dic userInfo:userInfo forMethod:method];
}

-(void)addRequestToQueueWithParams:(NSDictionary*)paramDic userInfo:(NSDictionary*)info forMethod:(NSString*)method
{
    NSDictionary *filteredDic=[self preProcessParams:paramDic forMethod:method];
    NSString *paramJsonStr=[self jsonStringFromDictionary:filteredDic];
    [self addRequestToQueueWithParamString:paramJsonStr userInfo:info forMethod:method];
}

-(void)addRequestToQueueWithParamString:(NSString*)paramJsonStr userInfo:(NSDictionary*)info forMethod:(NSString*)method
{
    [self addRequestToQueueWithParamString:paramJsonStr userInfo:info forMethod:method leftRetryTime:_retryTime];
}

-(void)addRequestToQueueWithParamString:(NSString*)paramJsonStr userInfo:(NSDictionary*)info forMethod:(NSString*)method leftRetryTime:(NSUInteger)leftRetryTime{
    NSURL *url=[self createUrlFor:method withJsonStr:paramJsonStr];
    NSMutableURLRequest *request=[[NSMutableURLRequest alloc]initWithURL:url];
    [self configRequest:request];
    [request setHTTPMethod:_httpMethod];
    [request setHTTPBody:[paramJsonStr dataUsingEncoding:NSUTF8StringEncoding]];
    //request.shouldAttemptPersistentConnection=YES;
    request.timeoutInterval=_timeoutSecond;
    AFHTTPRequestOperation *operation = [self.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self handleResult:responseObject withUserinfo:info];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (leftRetryTime > 0) {
            [self addRequestToQueueWithParamString:paramJsonStr userInfo:info forMethod:method leftRetryTime:_retryTime - 1];
        }else{
            [self handleResult:error withUserinfo:info];
        }
    }];
    operation.responseSerializer.acceptableContentTypes = [operation.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    operation.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
    operation.securityPolicy.allowInvalidCertificates = YES;
    [self.manager.operationQueue addOperation:operation];
}

-(void)configRequest:(NSMutableURLRequest*)request{
    
}

-(Class)responseClass:(NSString *)method{
    return [XGResponseBase class];
}

-(void)request:(NSString*)method withParams:(NSDictionary*)dic finish:(void(^)(XGResponseBase*))result
{
    [self request:method withParams:dic complete:^(NSDictionary *dic) {
        if(result)
        {
            Class responseClz = [self responseClass:method];
            NSAssert([responseClz isSubclassOfClass:[XGResponseBase class]], @"必须是XGResponseBase或其子类");
            result([[responseClz alloc] initWithDictionary:dic]);
        }
    }];
}

-(void)request:(NSString*)method withParams:(NSDictionary*)dic andTimeOut:(NSTimeInterval)timeout finish:(void(^)(XGResponseBase*))result{
    @synchronized(self){
        NSUInteger originalTimeOut = _timeoutSecond;
        _timeoutSecond = timeout;
        [self request:method withParams:dic finish:result];
        _timeoutSecond = originalTimeOut;
    }
}

#pragma mark after requesting

-(NSDictionary*)preProcessResponse:(id)responseObject
{
    NSError *error;
    NSDictionary *jsonDic;
    if ([responseObject isKindOfClass:[NSError class]]) {
        error = responseObject;
    }else if ([responseObject isKindOfClass:[NSDictionary class]]){
        jsonDic = responseObject;
    }
    if(error)
    {
        jsonDic = [self createReturnDataFromError:error];
    }
    return jsonDic;
}

-(void)handleResult:(id)responseObjectOrError withUserinfo:(NSDictionary*)userinfo
{
    NSDictionary *result = [self preProcessResponse:responseObjectOrError];
    void(^block)(NSDictionary*) =[userinfo objectForKey:completeBlockKey];
    if(block)
        block(result);
}

-(void)cancelAllRequest
{
    [self.manager.operationQueue cancelAllOperations];
}

-(void)tryMyBestToLoad:(void(^)(void))webserviceCall{
    @synchronized(self){
        if (!webserviceCall) {
            return;
        }
        NSUInteger originalRetryTime = _retryTime;
        _retryTime = INT_MAX;
        webserviceCall();
        _retryTime = originalRetryTime;
    }
}
@end
