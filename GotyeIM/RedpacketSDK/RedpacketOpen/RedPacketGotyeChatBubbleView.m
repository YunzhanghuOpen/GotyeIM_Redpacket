//
//  RedPacketGotyeChatBubbleView.m
//  GotyeIM
//
//  Created by 非夜 on 16/6/21.
//  Copyright © 2016年 Gotye. All rights reserved.
//

#import "RedPacketGotyeChatBubbleView.h"
#import "RedpacketMessageModel.h"

#define Layout(x) (x)

static CGFloat maxHeight = 120;
static CGFloat notiHeight = 30;

@implementation RedPacketGotyeChatBubbleView

+(NSInteger)getbubbleHeight:(GotyeOCMessage*)message target:(GotyeOCChatTarget*)chatTarget showDate:(BOOL)showDate{
    
    NSDictionary * ext = [self transformExtToDictionary:message];
    
    if (!ext) {
        return [super getbubbleHeight:message target:chatTarget showDate:showDate];
    }
    else{
        if ([RedpacketMessageModel isRedpacketRelatedMessage:ext]) {
            if ([RedpacketMessageModel isRedpacket:ext])    {
                if (showDate) {
                    return Layout(maxHeight) + kDateTextHeight;
                }
                return Layout(maxHeight);
            }else{
                if (showDate) {
                    return notiHeight + kDateTextHeight;
                }
                return notiHeight;
            }
        }
        else{
            return [super getbubbleHeight:message target:chatTarget showDate:showDate];
        }
    }
    
}

+(UIView*)BubbleWithMessage:(GotyeOCMessage*)message  target:(GotyeOCChatTarget*)chatTarget showDate:(BOOL)showDate
{
    NSDictionary * ext = [self transformExtToDictionary:message];
    
    if (!ext) {
        return [super BubbleWithMessage:message target:chatTarget showDate:showDate];
    }
    else{
        if ([RedpacketMessageModel isRedpacketRelatedMessage:ext]) {
            if ([RedpacketMessageModel isRedpacket:ext])    {
                return [self RedpacketBubbleWithMessage:message target:chatTarget showDate:showDate];
            }else{
                return [self RedpacketACKBubbleWithMessage:message target:chatTarget showDate:showDate];
            }
        }
        else{
            return [super BubbleWithMessage:message target:chatTarget showDate:showDate];
        }
    }
}

+ (UIView *)RedpacketBubbleWithMessage:(GotyeOCMessage*)message  target:(GotyeOCChatTarget*)chatTarget showDate:(BOOL)showDate{
    
    
    
    //  MARK:__redbag
    //    @property (strong, nonatomic) UIImageView *redpacketIcon;
    //    @property (strong, nonatomic) UILabel *redpacketTitleLabel;
    //    @property (strong, nonatomic) UILabel *redpacketSubLabel;
    //    @property (strong, nonatomic) UILabel *redpacketNameLabel;
    //    @property (strong, nonatomic) UIImageView *redpacketCompanyIcon;
    
    BOOL msgFromSelf = [[GotyeOCAPI getLoginUser].name isEqualToString:message.sender.name];
    
    UIView *messageView = [[UIView alloc] initWithFrame:CGRectZero];
    messageView.backgroundColor = [UIColor clearColor];
    
    UIImageView *bubbleImageView;
    CGFloat messageXoffset = kBubbleCommaGap + 60;
    CGFloat messageYoffset = showDate ? kDateTextHeight : 0;
    CGFloat bubbleXoffset = 60;
    UIColor *textColor;
    
    if(msgFromSelf)
    {
        bubbleImageView = [[UIImageView alloc] initWithImage:[self imageWithName:@"RedpacketCellResource.bundle/redpacket_sender_bg"]];
        textColor = [UIColor whiteColor];
    }
    else
    {
        bubbleImageView = [[UIImageView alloc] initWithImage:[self imageWithName:@"RedpacketCellResource.bundle/redpacket_receiver_bg"]];
        textColor = [UIColor blackColor];
    }
    
    // 红包size
    CGSize size = CGSizeMake(Layout(180), Layout(75));
    //    if(size.width > kContentWidthMax)
    //    {
    //        size.height = kContentWidthMax * size.height / size.width;
    //        size.width = kContentWidthMax;
    //    }
    //    if(size.height > kImageMaxHeight)
    //    {
    //        size.width = kImageMaxHeight * size.width / size.height;
    //        size.height = kImageMaxHeight;
    //    }
    
    // 初始化红包subviews
    UIImageView * redpacketIcon = [UIImageView new];
    [redpacketIcon setImage:[UIImage imageNamed:@"RedpacketCellResource.bundle/redPacket_redPacktIcon"]];
    
    UILabel *redpacketTitleLabel = [UILabel new];
    redpacketTitleLabel.font = [UIFont systemFontOfSize:15.0f];
    redpacketTitleLabel.textColor = [UIColor whiteColor];
    redpacketTitleLabel.textAlignment = NSTextAlignmentLeft;
    
    UILabel * redpacketSubLabel = [UILabel new];
    redpacketSubLabel.font = [UIFont systemFontOfSize:12.0f];
    redpacketSubLabel.textColor = [UIColor whiteColor];
    redpacketSubLabel.textAlignment = NSTextAlignmentLeft;
    
    UILabel * redpacketNameLabel = [UILabel new];
    redpacketNameLabel.font = [UIFont systemFontOfSize:12.0f];
    redpacketNameLabel.textColor = rp_hexColor(rp_textColorGray);
    redpacketNameLabel.textAlignment = NSTextAlignmentLeft;
    
    UIImageView * redpacketCompanyIcon = [UIImageView new];
    [redpacketCompanyIcon setImage:[UIImage imageNamed:@"RedpacketCellResource.bundle/redPacket_yunAccount_icon"]];
    redpacketCompanyIcon.translatesAutoresizingMaskIntoConstraints = NO;
    
    redpacketIcon.frame = CGRectMake(Layout(12), Layout(18), Layout(26), Layout(34));
    redpacketTitleLabel.frame = CGRectMake(Layout(48), Layout(19), Layout(size.width - 20), Layout(15));
    redpacketSubLabel.frame = CGRectMake(Layout(48), Layout(40), Layout(size.width - 60), Layout(12));
    redpacketNameLabel.frame = CGRectMake(Layout(12), Layout(95 - 12 - 4), Layout(size.width - 12 - 12), Layout(12));
    redpacketCompanyIcon.frame = CGRectZero;
    
    [bubbleImageView addSubview:redpacketIcon];
    [bubbleImageView addSubview:redpacketTitleLabel];
    [bubbleImageView addSubview:redpacketSubLabel];
    [bubbleImageView addSubview:redpacketNameLabel];
    [bubbleImageView addSubview:redpacketCompanyIcon];
    
    // 给红包赋值
    NSDictionary * dict = [self transformExtToDictionary:message];
    
    //    NSString *str = [NSString stringWithFormat:@"%@",[dict valueForKey:RedpacketKeyRedpacketGreeting]];
    //    if (str.length > 10) {
    //        str = [str substringToIndex:8];
    //        str = [str stringByAppendingString:@"..."];
    //        redpacketTitleLabel.text = str;
    //    }else
    //    {
    redpacketTitleLabel.text = [dict valueForKey:RedpacketKeyRedpacketGreeting];
    //    }
    
    redpacketSubLabel.text = @"查看红包";
    redpacketNameLabel.text = [dict valueForKey:RedpacketKeyRedpacketOrgName];
    
    // 绘制气泡
    if(msgFromSelf)
    {
        messageXoffset = ScreenWidth - messageXoffset - size.width;
        bubbleXoffset = ScreenWidth - bubbleXoffset - kBubbleCommaGap - kBubbleEndGap - size.width;
    }
    
    bubbleImageView.frame = CGRectMake(bubbleXoffset, kGapBetweenBubbles / 2 + messageYoffset, size.width + kBubbleCommaGap + kBubbleEndGap, size.height + kBubbleTopGap + kBubbleEndGap);
    
    messageView.frame = CGRectMake(0.0f, 0.0f, ScreenWidth, bubbleImageView.frame.size.height + 2*kGapBetweenBubbles + messageYoffset);
    [messageView addSubview:bubbleImageView];
    
    
    //  头像图片
    GotyeOCUser* user = [GotyeOCAPI getUserDetail:message.sender forceRequest:NO];
    NSString *headpath = user.icon.path;
    UIImage *headImage = [GotyeUIUtil getHeadImage:headpath defaultIcon:@"head_icon_user"];
    
    UIButton *headImageView = [[UIButton alloc] initWithFrame:CGRectZero];
    headImageView.tag = bubbleHeadButtonTag;
    if(msgFromSelf)
    {
        headImageView.frame = CGRectMake(ScreenWidth - 55, /*kGapBetweenBubbles / 2 + */messageYoffset, kHeadIconSize, kHeadIconSize);
    }
    else
    {
        headImageView.frame = CGRectMake(15, /*kGapBetweenBubbles / 2 + */messageYoffset, kHeadIconSize, kHeadIconSize);
    }
    [headImageView setBackgroundImage:headImage forState:UIControlStateNormal];
    
    [messageView addSubview:headImageView];
    
    //  用户名
    NSDictionary *dic = [NSDictionary dictionary];
    dic = [[GotyeSettingManager defaultManager] getSetting:chatTarget.type targetID:[NSString stringWithFormat:@"%lld", chatTarget.id]];
    if ([dic[Setting_key_NickName] boolValue]) {
        
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(headImageView.frame.origin.x, kHeadIconSize+messageYoffset, kHeadIconSize, kGapBetweenBubbles)];
        nameLabel.text = message.sender.name;
        nameLabel.font = [UIFont systemFontOfSize:11];
        nameLabel.backgroundColor = [UIColor clearColor];
        nameLabel.textColor = [UIColor lightGrayColor];
        [messageView addSubview:nameLabel];
    }else {
        
    }
    //  时间
    if(showDate)
    {
        UILabel *dateText = [[UILabel alloc] initWithFrame:CGRectMake(0, kGapBetweenBubbles / 2, ScreenWidth, kDateTextHeight)];
        dateText.backgroundColor = [UIColor clearColor];
        dateText.textColor = [UIColor lightGrayColor];
        dateText.font = [UIFont systemFontOfSize:11];
        dateText.textAlignment = NSTextAlignmentCenter;
        dateText.text = [self getMessageDateString:[NSDate dateWithTimeIntervalSince1970:message.date]];
        [messageView addSubview:dateText];
    }
    
    //  状态
    NSString *stateString;
    if(message.status == GotyeMessageStatusSending)
        stateString = @"发送中";
    else if (message.status == GotyeMessageStatusSendingFailed)
        stateString = @"发送失败";
    
    if(stateString != nil)
    {
        CGRect frame;
        if(msgFromSelf)
        {
            frame = CGRectMake(0, bubbleImageView.frame.origin.y + bubbleImageView.frame.size.height / 2 - 8, bubbleImageView.frame.origin.x - 10, 16);
        }
        else
        {
            frame = CGRectMake(bubbleImageView.frame.origin.x + bubbleImageView.frame.size.width + 10, bubbleImageView.frame.origin.y + bubbleImageView.frame.size.height / 2 - 8, ScreenWidth - bubbleImageView.frame.origin.x - bubbleImageView.frame.size.width - 10, 16);
        }
        
        UILabel *stateText = [[UILabel alloc] initWithFrame:frame];
        stateText.backgroundColor = [UIColor clearColor];
        stateText.textColor = [UIColor lightGrayColor];
        stateText.font = [UIFont systemFontOfSize:11];
        stateText.textAlignment = msgFromSelf ? NSTextAlignmentRight : NSTextAlignmentLeft;
        stateText.text = stateString;
        [messageView addSubview:stateText];
    }
    
    return messageView;
}

+ (UIView *)RedpacketACKBubbleWithMessage:(GotyeOCMessage*)message  target:(GotyeOCChatTarget*)chatTarget showDate:(BOOL)showDate{
    
    UIView *messageView = [[UIView alloc] initWithFrame:CGRectZero];
    messageView.backgroundColor = [UIColor clearColor];
    
    UIView * backView = [[UIView alloc] init];
    backView.backgroundColor = rp_hexColor(rp_backGroundColorGray);
    [messageView addSubview:backView];
    
    // 此处需要处理红包ACK消息
    NSString * packetACK = nil;
    
    // 如果是红包别人领了，则调整已拆红包回执消息
    packetACK = [self handleMessage:message];
    
    UILabel * titleLabel = [UILabel new];
    CGRect frame = [packetACK boundingRectWithSize:CGSizeMake(200,20) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12]} context:nil];
    titleLabel.font = [UIFont systemFontOfSize:12];
    titleLabel.textColor = rp_hexColor(rp_textColorGray);
    titleLabel.frame = CGRectMake(10 + 7 * 2, 0, frame.size.width + 7, 20);
    [backView addSubview:titleLabel];
    titleLabel.text = packetACK;
    
    backView.frame = CGRectMake((ScreenWidth - frame.size.width - 7 * 2 - 10 - 10 - 7) / 2 , 5, frame.size.width + 7 * 2 + 10 + 7, 20);
    backView.layer.cornerRadius = 3.0f;
    backView.layer.masksToBounds = YES;
    [messageView addSubview:backView];
    
    UIImageView * icon = [[UIImageView alloc] initWithFrame:CGRectMake(7, 3, 10, 14)];
    [icon setImage:[UIImage imageNamed:@"RedpacketCellResource.bundle/redpacket_smallIcon"]];
    [backView addSubview:icon];
    //    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backViewTaped)];
    //    [self.backView addGestureRecognizer:tap];
    messageView.frame = CGRectMake(0.0f, 0.0f, ScreenWidth, backView.frame.size.height + 10);
    //  时间
    if(showDate)
    {
        UILabel *dateText = [[UILabel alloc] initWithFrame:CGRectMake(0, kGapBetweenBubbles / 2, ScreenWidth, kDateTextHeight)];
        dateText.backgroundColor = [UIColor clearColor];
        dateText.textColor = [UIColor lightGrayColor];
        dateText.font = [UIFont systemFontOfSize:11];
        dateText.textAlignment = NSTextAlignmentCenter;
        dateText.text = [self getMessageDateString:[NSDate dateWithTimeIntervalSince1970:message.date]];
        [messageView addSubview:dateText];
        
        backView.frame = CGRectMake(backView.frame.origin.x, 36, backView.frame.size.width, backView.frame.size.height);
        messageView.frame = CGRectMake(0.0f, 0.0f, ScreenWidth, backView.frame.size.height + 36 + 10);
    }
    
    return messageView;
}


+ (NSString*)getMessageDateString:(NSDate*)messageDate
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale systemLocale]];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm"];
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:messageDate];
    NSDate *msgDate = [cal dateFromComponents:components];
    
    components = [cal components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
    NSDate *today = [cal dateFromComponents:components];
    
    if([today isEqualToDate:msgDate])
        [formatter setDateFormat:@"HH:mm"];
    
    components.day -= 1;
    NSDate *yestoday = [cal dateFromComponents:components];
    
    if([yestoday isEqualToDate:msgDate])
        [formatter setDateFormat:@"昨天 HH:mm"];
    
    return [formatter stringFromDate:messageDate];
}

+ (NSDictionary *)transformExtToDictionary:(GotyeOCMessage*)message{
    
    NSDictionary * dic = nil;
    
    NSData *data = [message getExtraData];//[NSData dataWithContentsOfFile:message.extra.path];
    if(data != nil)
    {
        char * str = malloc(data.length + 1);
        [data getBytes:str length:data.length];
        str[data.length] = 0;
        NSString *extraStr = [NSString stringWithUTF8String:str];
        free(str);
        NSData *jsonData = [extraStr dataUsingEncoding:NSUTF8StringEncoding];
        NSError *err;
        dic = [NSJSONSerialization
               JSONObjectWithData:jsonData
               options:NSJSONReadingMutableContainers
               error:&err];
    }
    return dic;
}

+ (UIImage *)imageWithName:(NSString *)name;
{
    UIImage *nam = [UIImage imageNamed:name];
    CGFloat w = nam.size.width * 0.5;
    CGFloat h = nam.size.height * 0.8;
    //图像放大
    return [nam resizableImageWithCapInsets:UIEdgeInsetsMake(h, w, h, w)];
}

+ (NSString *)handleMessage:(GotyeOCMessage*)message{
    
    NSDictionary *dict = [self transformExtToDictionary:message];
    if ([RedpacketMessageModel isRedpacketTakenMessage:dict]) {

        NSString *senderID = [dict valueForKey:RedpacketKeyRedpacketSenderId];
        NSString *receiverID = [dict valueForKey:RedpacketKeyRedpacketReceiverId];
        //  标记为已读
        if ([senderID isEqualToString:[GotyeOCAPI getLoginUser].name] && ![receiverID isEqualToString:[GotyeOCAPI getLoginUser].name]){
            /**
             *  当前用户是红包发送者。
             */
            NSString *text = [NSString stringWithFormat:@"%@领取了你的红包",receiverID];
            return text;
        }
        else{
            return message.text;

        }
    }
    else{
        return message.text;
    }
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

@end
