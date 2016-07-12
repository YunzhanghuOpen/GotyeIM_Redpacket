//
//  RedpacketNetworkHelper.h
//  GotyeIM
//
//  Created by 非夜 on 16/6/16.
//  Copyright © 2016年 Gotye. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^CompletioBlock)(NSDictionary *dic, NSURLResponse *response, NSError *error);
typedef void (^SuccessBlock)(NSDictionary *data);
typedef void (^FailureBlock)(NSError *error);

@interface RedpacketNetworkHelper : NSObject<NSURLSessionDelegate>

/**
 *  get请求
 */
+ (void)getWithUrlString:(NSString *)url parameters:(id)parameters success:(SuccessBlock)successBlock failure:(FailureBlock)failureBlock;

/**
 * post请求
 */
+ (void)postWithUrlString:(NSString *)url parameters:(id)parameters success:(SuccessBlock)successBlock failure:(FailureBlock)failureBlock;

@end
