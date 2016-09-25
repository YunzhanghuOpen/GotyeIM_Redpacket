//
//  GotyeAppDelegate+Redpacket.m
//  GotyeIM
//
//  Created by 非夜 on 16/7/6.
//  Copyright © 2016年 Gotye. All rights reserved.
//

#import "AlipaySDK.h"
#import "GotyeAppDelegate+Redpacket.h"
#import "RedpacketOpenConst.h"

@implementation GotyeAppDelegate (Redpacket)

- (void)redpacketApplicationDidBecomeActive:(UIApplication *)application {

  [[NSNotificationCenter defaultCenter]
      postNotificationName:RedpacketAlipayNotifaction
                    object:nil];
}

// NOTE: 9.0之前使用的API接口
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {

  if ([url.host isEqualToString:@"safepay"]) {
    //跳转支付宝钱包进行支付，处理支付结果
    [[AlipaySDK defaultService]
        processOrderWithPaymentResult:url
                      standbyCallback:^(NSDictionary *resultDic) {
                        [[NSNotificationCenter defaultCenter]
                            postNotificationName:RedpacketAlipayNotifaction
                                          object:resultDic];
                      }];
  }
  return YES;
}

// NOTE: 9.0以后使用新API接口
- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<NSString *, id> *)options {
  if ([url.host isEqualToString:@"safepay"]) {
    //跳转支付宝钱包进行支付，处理支付结果
    [[AlipaySDK defaultService]
        processOrderWithPaymentResult:url
                      standbyCallback:^(NSDictionary *resultDic) {
                        [[NSNotificationCenter defaultCenter]
                            postNotificationName:RedpacketAlipayNotifaction
                                          object:resultDic];
                      }];
  }
  return YES;
}

@end
