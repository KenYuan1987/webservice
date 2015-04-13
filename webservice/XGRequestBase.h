//
//  GJWebServiceBaseForAF.h
//  SuperCard
//
//  Created by ken on 15-1-27.
//  Copyright (c) 2015年 ken. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XGResponseBase.h"

@interface XGRequestBase : NSObject
@property(nonatomic,copy)NSString *httpMethod;//post get
@property(nonatomic,assign)NSUInteger timeoutSecond;
@property(nonatomic,assign)NSUInteger retryTime;

-(NSURL*)createUrlFor:(NSString*)method withJsonStr:(NSString*)jsonStr;//override point
-(NSDictionary*)preProcessParams:(NSDictionary*)dic forMethod:(NSString*)method;//override point
-(NSDictionary*)createReturnDataFromError:(NSError*)error;//override point
-(void)configRequest:(NSMutableURLRequest*)request;//override point
-(Class)responseClass:(NSString *)method;//override point

-(void)cancelAllRequest;
-(void)tryMyBestToLoad:(void(^)(void))webserviceCall;//一个app必须要load到的基本数据，可以考虑用这个来加载
-(NSOperation *)request:(NSString*)method withParams:(NSDictionary*)dic finish:(void(^)(XGResponseBase*))result;
-(NSOperation *)request:(NSString*)method withParams:(NSDictionary*)dic andTimeOut:(NSTimeInterval)timeout finish:(void(^)(XGResponseBase*))result;
@end
