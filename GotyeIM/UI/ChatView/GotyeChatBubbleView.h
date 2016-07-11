//
//  GotyeChatBubbleCell.h
//  GotyeIM
//
//  Created by Peter on 14-10-17.
//  Copyright (c) 2014年 Gotye. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GotyeOCAPI.h"


#import "GotyeSettingManager.h"


#import "GotyeUIUtil.h"

#define kContentWidthMax    190
#define kBubbleMinHeight    40
#define kHeadIconSize       40
#define kTextFontSize       14

#define kGapBetweenBubbles  12
#define kDateTextHeight     36
#define kExtraTextHeight     20

#define kBubbleTopGap       12
#define kBubbleBottomGap    12
#define kBubbleCommaGap     21
#define kBubbleEndGap       14
#define kImageMaxHeight     80


@interface GotyeChatBubbleView : UIView

#define bubblePlayImageTag      10000
#define bubbleHeadButtonTag     10001
#define bubbleThumbImageTag     10002
#define bubbleMessageButtonTag  10003

+(NSInteger)getbubbleHeight:(GotyeOCMessage*)message target:(GotyeOCChatTarget*)chatTarget showDate:(BOOL)showDate;

+(UIView*)BubbleWithMessage:(GotyeOCMessage*)message target:(GotyeOCChatTarget*)chatTarget showDate:(BOOL)showDate;

@end
