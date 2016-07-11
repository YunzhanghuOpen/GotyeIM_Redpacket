//
//  RedPacketGotyeChatBubbleView.h
//  GotyeIM
//
//  Created by 非夜 on 16/6/21.
//  Copyright © 2016年 Gotye. All rights reserved.
//

#import "GotyeChatBubbleView.h"

@interface RedPacketGotyeChatBubbleView : GotyeChatBubbleView

+(NSInteger)getbubbleHeight:(GotyeOCMessage*)message target:(GotyeOCChatTarget*)chatTarget showDate:(BOOL)showDate;

@end
