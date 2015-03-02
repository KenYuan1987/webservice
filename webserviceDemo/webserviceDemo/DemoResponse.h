//
//  WsResult.h
//  ticket
//
//  Created by ken on 14-2-20.
//  Copyright (c) 2014年 ken. All rights reserved.
//

#import "XGResponseBase.h"

@interface DemoResponse : XGResponseBase
-(id)initWithDictionary:(NSDictionary*)dic;

extern NSString *SessionExpiredNotification;

extern NSInteger const WsResultUserCancelErrorCode;
@end
