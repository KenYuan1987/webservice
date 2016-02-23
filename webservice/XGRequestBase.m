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
@property(nonatomic,strong) AFHTTPSessionManager *manager;
@property(nonatomic,strong) AFHTTPSessionManager *bestManager;//革命性的优化
@property(nonatomic,strong) id webReachabilityObserver;
@property(nonatomic,assign) BOOL inBestMode;
@end

@implementation XGRequestBase

-(id)init
{
    self=[super init];
    if(self)
    {
        self.manager = [AFHTTPSessionManager manager];
        if (![WebserviceReachability isWebserviceReachable]) {
            self.bestManager.operationQueue.suspended = YES;
        }
        self.webReachabilityObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kReachabilityChangedNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            if ([WebserviceReachability isWebserviceReachable]) {
                self.bestManager.operationQueue.suspended = NO;
            }else{
                self.bestManager.operationQueue.suspended = YES;
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

-(NSURLSessionDataTask *)request:(NSString*)method withParams:(NSDictionary*)dic complete:(void(^)(NSDictionary*))block
{
    NSDictionary *userInfo=[NSDictionary dictionaryWithObjectsAndKeys:block,completeBlockKey, nil];
    return [self requestWithParams:dic userInfo:userInfo forMethod:method];
}

-(NSURLSessionDataTask *)requestWithParams:(NSDictionary*)paramDic userInfo:(NSDictionary*)info forMethod:(NSString*)method
{
    NSDictionary *filteredDic = [self preProcessParams:paramDic forMethod:method];
    NSString *paramJsonStr;
    if(!filteredDic || [NSJSONSerialization isValidJSONObject:filteredDic]) {
        paramJsonStr = [self jsonStringFromDictionary:filteredDic];
    } else {
        NSAssert([self.httpMethod isEqualToString:@"POST"], @"要上传数据类型肯定是用POST了");
        return [self multiPartRequestWithParam:filteredDic userInfo:info forMethod:method];
    }
    return [self addRequestToQueueWithParamString:paramJsonStr userInfo:info forMethod:method];
}


-(NSURLSessionDataTask *)multiPartRequestWithParam:(NSDictionary *)params userInfo:(NSDictionary *)info forMethod:(NSString *)method{
    return  [self addMultiPartRequestToQueueWithParam:params userInfo:info forMethod:method leftRetryTime:_retryTime];
}

-(void)constructFormData:(id<AFMultipartFormData>)formData withParams:(NSDictionary *)formDataParams and:(AFHTTPSessionManager *)currentManager {
    for (NSString *key in formDataParams){
        if ([formDataParams[key] isKindOfClass:[UIImage class]]) {
            [formData appendPartWithFileData:UIImageJPEGRepresentation(formDataParams[key],1) name:key fileName:@"temp.jpg" mimeType:@"image/jpeg"];
        } else if ([formDataParams[key] isKindOfClass:[NSURL class]]) {
            NSError *err;
            [formData appendPartWithFileURL:formDataParams[key] name:key error:&err];
        }
        else if([formDataParams[key] isKindOfClass:[NSArray class]]){
            NSArray *arrayParam = formDataParams[key];
            if ([arrayParam count] > 0 && [arrayParam[0] isKindOfClass:[UIImage class]]) {
                for(int i = 0;i < [arrayParam count];i++){
                    [formData appendPartWithFileData:UIImageJPEGRepresentation(arrayParam[0],1) name:key fileName:[NSString stringWithFormat:@"temp%d.jpg",i] mimeType:@"image/jpeg"];
                }
            } else if ([arrayParam count] > 0 && [arrayParam[0] isKindOfClass:[NSURL class]]) {
                for(int i = 0;i < [arrayParam count];i++){
                    NSError *err;
                    [formData appendPartWithFileURL:arrayParam[i] name:key error:&err];
                }
            }
            else
                [formData appendPartWithFormData:[[formDataParams[key] description] dataUsingEncoding:currentManager.requestSerializer.stringEncoding] name:key];
        }
    }
}

-(NSURLSessionDataTask *)addMultiPartRequestToQueueWithParam:(NSDictionary *)params userInfo:(NSDictionary *)info forMethod:(NSString *)method leftRetryTime:(NSUInteger)leftRetryTime{
    NSURL *url=[self createUrlFor:method withJsonStr:nil];
    NSMutableDictionary *formDataParams = [NSMutableDictionary new];
    NSMutableDictionary *plainStrParams = [NSMutableDictionary new];
    for (NSString *key in params) {
        if ([params[key] isKindOfClass:[NSString class]]
            || [params[key] isKindOfClass:[NSNumber class]]
            || [params[key] isKindOfClass:[NSNull class]]) {
            [plainStrParams setObject:params[key] forKey:key];
        }else{
            [formDataParams setObject:params[key] forKey:key];
        }
    }
    AFHTTPSessionManager *currentManager;
    if (self.inBestMode) {
        currentManager = self.bestManager;
    }else{
        currentManager = self.manager;
    }
    
    NSError *serializationError = nil;
    
    NSMutableURLRequest *request = [currentManager.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:[url absoluteString] parameters:plainStrParams constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [self constructFormData:formData withParams:formDataParams and:currentManager];
    } error:&serializationError];
    if (serializationError) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
        dispatch_async(currentManager.completionQueue ?: dispatch_get_main_queue(), ^{
            [self handleResult:serializationError withUserinfo:info];
        });
#pragma clang diagnostic pop
        return nil;
    }
    [self configRequest:request];
    NSURLSessionDataTask *task = [currentManager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            if (leftRetryTime > 0) {
                [self addMultiPartRequestToQueueWithParam:params userInfo:info forMethod:method leftRetryTime:_retryTime - 1];
            }else{
                NSData *errData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
                NSLog(@"%@",[[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding]);
                [self handleResult:error withUserinfo:info];
            }
        } else {
            [self handleResult:responseObject withUserinfo:info];
        }
    }];
    [task resume];
    return task;
}

-(NSURLSessionDataTask *)addRequestToQueueWithParamString:(NSString*)paramJsonStr userInfo:(NSDictionary*)info forMethod:(NSString*)method
{
    return [self addRequestToQueueWithParamString:paramJsonStr userInfo:info forMethod:method leftRetryTime:_retryTime];
}

-(NSURLSessionDataTask *)addRequestToQueueWithParamString:(NSString*)paramJsonStr userInfo:(NSDictionary*)info forMethod:(NSString*)method leftRetryTime:(NSUInteger)leftRetryTime{
    NSURL *url=[self createUrlFor:method withJsonStr:paramJsonStr];
    NSMutableURLRequest *request=[[NSMutableURLRequest alloc]initWithURL:url];
    [self configRequest:request];
    [request setHTTPMethod:_httpMethod];
    if ([_httpMethod isEqualToString:@"POST"]) {
        [request setHTTPBody:[paramJsonStr dataUsingEncoding:NSUTF8StringEncoding]];
    }
    request.timeoutInterval=_timeoutSecond;
    NSURLSessionDataTask *task = [self.manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            if (leftRetryTime > 0) {
                [self addRequestToQueueWithParamString:paramJsonStr userInfo:info forMethod:method leftRetryTime:_retryTime - 1];
            }else{
                [self handleResult:error withUserinfo:info];
            }
        } else {
            [self handleResult:responseObject withUserinfo:info];
        }
    }];
    [task resume];
    return task;
}

-(void)configRequest:(NSMutableURLRequest*)request{
    
}

-(Class)responseClass:(NSString *)method{
    return [XGResponseBase class];
}

-(NSURLSessionDataTask *)request:(NSString*)method withParams:(NSDictionary*)dic finish:(void(^)(XGResponseBase*))result
{
    return [self request:method withParams:dic complete:^(NSDictionary *dic) {
        if(result)
        {
            Class responseClz = [self responseClass:method];
            NSAssert([responseClz isSubclassOfClass:[XGResponseBase class]], @"必须是XGResponseBase或其子类");
            result([[responseClz alloc] initWithDictionary:dic]);
        }
    }];
}

-(NSURLSessionDataTask *)request:(NSString*)method withParams:(NSDictionary*)dic andTimeOut:(NSTimeInterval)timeout finish:(void(^)(XGResponseBase*))result{
    @synchronized(self){
        NSUInteger originalTimeOut = _timeoutSecond;
        _timeoutSecond = timeout;
        NSURLSessionDataTask *op = [self request:method withParams:dic finish:result];
        _timeoutSecond = originalTimeOut;
        return op;
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
    [self.bestManager.operationQueue cancelAllOperations];
}

-(void)tryMyBestToLoad:(void(^)(void))webserviceCall{
    @synchronized(self){
        if (!webserviceCall) {
            return;
        }
        if (!_bestManager) {
            _bestManager = [AFHTTPSessionManager manager];
        }
        NSUInteger originalRetryTime = _retryTime;
        _retryTime = INT_MAX;
        self.inBestMode = YES;
        webserviceCall();
        self.inBestMode = NO;
        _retryTime = originalRetryTime;
    }
}
@end
