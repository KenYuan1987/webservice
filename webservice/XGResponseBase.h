//
//  WsResult.h
//  ticket
//
//  Created by ken on 14-2-20.
//  Copyright (c) 2014年 ken. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XGResponseBase : NSObject
-(id)initWithDictionary:(NSDictionary*)dic;
@property(nonatomic,readonly) BOOL isRqSuccess;//网络请求成功，但不代表业务执行成功
@property(nonatomic,readonly) BOOL isOpSuccess;//业务执行成功
@property(nonatomic,readonly) NSInteger code;
@property(nonatomic,readonly,copy) NSString *method;
@property(nonatomic,readonly,copy) NSString *version;
@property(nonatomic,readonly,copy) NSString *msg;
@property(nonatomic,readonly,strong) NSError *error;

@property(nonatomic,readonly,copy) NSArray *arrayData;
@property(nonatomic,readonly,copy) NSDictionary *mapData;
@property(nonatomic,readonly,copy) id rawData;

-(NSString *)responseMethodKeyPath;//override point
-(NSString *)responseRawDataKeyPath;//override point
-(NSString *)responseVersionKeyPath;//override point
-(NSString *)responseMsgKeyPath;//override point
-(NSString *)responseCodeKeyPath;//override point
-(BOOL)checkResultReturnCode:(NSInteger)code;//override point

extern NSString *const WebserviceErrorDomain;
extern NSString *const WebserviceRequestFailKey;//自行组装dictionary时设置此key为YES代表网络请求失败，isRqSuccess==NO
@end
