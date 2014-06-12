//
//  User.h
//  CloudMessage
//
//  Created by SoftwareLab on 13-7-6.
//  Copyright (c) 2013年 SoftwareLab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject

+ (id)sharedUser;
+ (NSString *)getUid;
+ (NSArray *)subscriptionListData;
+ (void)setSubscriptionLIstData:(NSArray *)data;
+ (NSDictionary *)runtimeData;
+ (void)setRuntimeData:(id)data forKey:(NSString *)key;
+ (BOOL)isNeedToRefreshSubscription;
+ (void)setSubscriptionRefresh:(BOOL)refresh;
- (void)getMySubscription;
+ (void)insertMessageInfoBySn:(NSInteger) sn message:(NSDictionary *)message;
+ (NSMutableArray *)getMessageInfoByLimit:(NSInteger)limit offset:(NSInteger)offset;
+ (NSMutableArray *)getMessageInfoByRid:(NSString *)rid;
+ (void)insertMessageContent:(NSDictionary *)data;
+ (NSDictionary *)getMessageContentByMid:(NSString *)mid;
+ (void)updateMessageContentByMid:(NSString *) mid forField:(NSString *)field withValue:(NSString *)value;
+ (void)emptyDataBase;
+ (void)deleteMessageByMid:(NSString *)mid;
+ (NSArray *)getMessageCount;//读取消息数、未读数

@end
