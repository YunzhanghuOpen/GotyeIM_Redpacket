//
//  RedPacketUserConfig.m
//  GotyeIM
//
//  Created by 非夜 on 16/6/17.
//  Copyright © 2016年 Gotye. All rights reserved.
//

#import "RedPacketUserConfig.h"
#import "RedpacketNetworkHelper.h"
#import "YZHRedpacketBridge.h"
#import "RedpacketMessageModel.h"
#import "GotyeOCAPI.h"

static RedPacketUserConfig * ___shareRedPacketUserConfig___ = nil;

@interface RedPacketUserConfig()<YZHRedpacketBridgeDataSource>

@end

@implementation RedPacketUserConfig

+ (instancetype)sharedConfig {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ___shareRedPacketUserConfig___ = [[RedPacketUserConfig alloc] init];
        [YZHRedpacketBridge sharedBridge].dataSource = ___shareRedPacketUserConfig___;
    });
    return ___shareRedPacketUserConfig___;
}

- (void)configWithUserId:(NSString *)userId
{
    NSString *usb = self.redpacketUserInfo.userId;
    
    [RedpacketNetworkHelper getWithUrlString:@"https://rpv2.yunzhanghu.com/api/sign" parameters:@{@"duid":userId} success:^(NSDictionary *data) {
        NSString * sign = data[@"sign"];
        NSString * partner = data[@"partner"];
        NSString * userId = data[@"user_id"];
        long timestamp = [data[@"timestamp"] longValue];
        [[YZHRedpacketBridge sharedBridge] configWithSign:sign partner:partner appUserId:userId timeStamp:timestamp];
        
    } failure:^(NSError *error) {
        
    }];
}

#pragma mark - YZHRedpacketBridgeDataSource

/**
 *  获取当前用户登陆信息，YZHRedpacketBridgeDataSource
 */
- (RedpacketUserInfo *)redpacketUserInfo
{
    GotyeOCUser* loginUser = [GotyeOCAPI getLoginUser];

    RedpacketUserInfo *userInfo = [RedpacketUserInfo new];
    userInfo.userId = loginUser.name;
    userInfo.userNickname = loginUser.nickname;
    // 此处获取头像极为复杂，不知道亲加的工程师怎么想的
    userInfo.userAvatar = loginUser.icon.url;
    return userInfo;
}

@end
