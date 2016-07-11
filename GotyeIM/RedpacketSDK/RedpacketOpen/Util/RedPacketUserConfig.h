//
//  RedPacketUserConfig.h
//  GotyeIM
//
//  Created by 非夜 on 16/6/17.
//  Copyright © 2016年 Gotye. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RedPacketUserConfig : NSObject

+ (instancetype)sharedConfig;

- (void)configWithUserId:(NSString *)userId;


@end
