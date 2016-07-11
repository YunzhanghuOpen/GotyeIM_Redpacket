////
////  RedpacketChatViewController.m
////  GotyeIM
////
////  Created by 非夜 on 16/7/1.
////  Copyright © 2016年 Gotye. All rights reserved.
////
//
//#import "RedpacketChatViewController.h"
//#import "YZHRedpacketBridge.h"
//#import "RedpacketViewControl.h"
//
//@interface RedpacketChatViewController ()
///**
// *  发红包的控制器
// */
//@property (nonatomic, strong)   RedpacketViewControl *viewControl;
//@property (nonatomic) int groupCount;
//@end
//
//@implementation RedpacketChatViewController
//
//- (void)viewDidLoad {
//    [super viewDidLoad];
//    
//    [self configRedPacketChatViewController];
//
//    // Do any additional setup after loading the view.
//}
//
//- (IBAction)redpacketAction:(id)sender {
//    [super redpacketAction:sender];
//    if (chatTarget.type == GotyeChatTargetTypeUser) {
//        [self.viewControl presentRedPacketViewController];
//    }
//    else if(chatTarget.type == GotyeChatTargetTypeRoom || chatTarget.type == GotyeChatTargetTypeGroup){
//        [self.viewControl presentRedPacketMoreViewControllerWithCount:self.groupCount];
//    }
//}
//
//- (void)addButtonClick:(id)sender {
//    [super addButtonClick:sender];
//    self.redPacketButton.hidden = NO;
//}
//
//#pragma mark - Redpacket Private
//
//- (void)delToSelfPacketMessage:(GotyeOCMessage*)message{
//    
//    if (message == nil) {
//        return;
//    }
//    
//    GotyeOCUser* loginUser = [GotyeOCAPI getLoginUser];
//    
//    NSDictionary * ext = [self transformExtToDictionary:message];
//    if ([RedpacketMessageModel isRedpacketRelatedMessage:ext]) {
//        if ([RedpacketMessageModel isRedpacketTakenMessage:ext])    {
//            // 由于没有透传消息 如果群红包，A发的，A打开，others收到消息，others删除消息
//            if ([ext[@"money_sender_id"] isEqualToString:ext[@"money_receiver_id"]]) {
//                [GotyeOCAPI deleteMessage:chatTarget msg:message];
//                return;
//            }
//            // 由于没有透传消息 如果群红包，A发的，B打开，other收到消息，除了A之外的others删除
//            if (![ext[@"money_sender_id"] isEqualToString:loginUser.name]) {
//                [GotyeOCAPI deleteMessage:chatTarget msg:message];
//                return;
//            }
//        }
//    }
//}
//
//- (NSDictionary *)transformExtToDictionary:(GotyeOCMessage*)message{
//    
//    NSDictionary * dic = nil;
//    
//    NSData *data = [message getExtraData];//[NSData dataWithContentsOfFile:message.extra.path];
//    if(data != nil)
//    {
//        char * str = malloc(data.length + 1);
//        [data getBytes:str length:data.length];
//        str[data.length] = 0;
//        NSString *extraStr = [NSString stringWithUTF8String:str];
//        free(str);
//        NSData *jsonData = [extraStr dataUsingEncoding:NSUTF8StringEncoding];
//        NSError *err;
//        dic = [NSJSONSerialization
//               JSONObjectWithData:jsonData
//               options:NSJSONReadingMutableContainers
//               error:&err];
//    }
//    return dic;
//}
//
//- (void)configRedPacketChatViewController{
//    // 获取群组人数，如果是群组或者room
//    
//    if (chatTarget.type == GotyeChatTargetTypeRoom) {
//        [GotyeOCAPI reqRoomMemberList:[GotyeOCRoom roomWithId:chatTarget.id] pageIndex :0];/// <对应回调GotyeOCDelegate::onGetRoomMemberList
//    }
//    if (chatTarget.type == GotyeChatTargetTypeGroup) {
//        [GotyeOCAPI reqGroupMemberList :[GotyeOCGroup groupWithId:chatTarget.id] pageIndex:0];/// <对应回调GotyeOCDelegate::onGetRoomMemberList
//    }
//    
//    /**
//     红包功能的控制器， 产生用户单击红包后的各种动作
//     */
//    _viewControl = [[RedpacketViewControl alloc] init];
//    //  需要当前的聊天窗口
//    _viewControl.conversationController = self;
//    
//    //  需要当前聊天窗口的会话ID
//    RedpacketUserInfo *userInfo = [RedpacketUserInfo new];
//    userInfo.userId = chatTarget.name;
//    
//    if (chatTarget.type == GotyeChatTargetTypeRoom || chatTarget.type == GotyeChatTargetTypeGroup) {
//        
//        NSString * groupId = [NSString stringWithFormat:@"%lld",chatTarget.id];
//        
//        userInfo.userId = groupId;
//        
//    }
//    
//    _viewControl.converstationInfo = userInfo;
//    
//    __weak __typeof(self)weakSelf = self;
//    
//    
//    //  用户抢红包和用户发送红包的回调
//    [_viewControl setRedpacketGrabBlock:^(RedpacketMessageModel *messageModel) {
//        //  发送通知到发送红包者处
//        [weakSelf sendRedpacketHasBeenTaked:messageModel];
//        
//    } andRedpacketBlock:^(RedpacketMessageModel *model) {
//        
//        model.redpacket.redpacketOrgName = @"亲加红包";
//        //  发送红包
//        [weakSelf sendRedPacketMessage:model];
//        
//    }];
//    
//    // 同步Token
//    [[YZHRedpacketBridge sharedBridge] reRequestRedpacketUserToken];
//}
//
////  MARK: 发送红包消息
//- (void)sendRedPacketMessage:(RedpacketMessageModel *)model
//{
//    NSDictionary *dic = [model redpacketMessageModelToDic];
//    
//    NSString *txt = [NSString stringWithFormat:@"[%@]%@", model.redpacket.redpacketOrgName, model.redpacket.redpacketGreeting];
//    
//    GotyeOCMessage* message = [GotyeOCMessage createTextMessage:chatTarget text:txt];
//    
//    NSData *extData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];
//    
//    NSString *extString = [[NSString alloc] initWithData:extData encoding:NSUTF8StringEncoding];
//    
//    [message putExtraData: [extString UTF8String] len:strlen([extString UTF8String])];
//    
//    [GotyeOCAPI sendMessage:message];
//    
//    [self reloadHistorys:YES];
//    
//}
//
////  MARK: 发送红包被抢的消息
//- (void)sendRedpacketHasBeenTaked:(RedpacketMessageModel *)messageModel
//{
//    NSString *currentUser = [GotyeOCAPI getLoginUser].name;
//    NSString *senderId = messageModel.redpacketSender.userId;
//    
//    NSMutableDictionary *dic = [messageModel.redpacketMessageModelToDic mutableCopy];
//    /**
//     *  不推送
//     */
//    [dic setValue:@(YES) forKey:@"em_ignore_notification"];
//    
//    NSString *text = [NSString stringWithFormat:@"你领取了%@发的红包", messageModel.redpacketSender.userNickname];
//    
//    NSData *extData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];
//    
//    NSString *extString = [[NSString alloc] initWithData:extData encoding:NSUTF8StringEncoding];
//    
//    if (chatTarget.type == GotyeChatTargetTypeUser) {
//        
//        GotyeOCMessage* message = [GotyeOCMessage createTextMessage:chatTarget text:text];
//        [message putExtraData: [extString UTF8String] len:strlen([extString UTF8String])];
//        [GotyeOCAPI sendMessage:message];
//        [self reloadHistorys:YES];
//        
//    }
//    else if(chatTarget.type == GotyeChatTargetTypeRoom || chatTarget.type == GotyeChatTargetTypeGroup){
//        if ([senderId isEqualToString:currentUser]) {
//            text = @"你领取了自己的红包";
//            // 如果是群红包，这个红包被自己领了，则给自己发一条消息，同时在消息的接收处过滤出来这条消息（过滤方式，检测是否是红包消息，检测消息发送方和自己是不是同一个人，是同一个人则删除此消息）
//            GotyeOCMessage* message = [GotyeOCMessage createTextMessage:chatTarget text:text];
//            [message putExtraData: [extString UTF8String] len:strlen([extString UTF8String])];
//            [GotyeOCAPI sendMessage:message];
//            [self reloadHistorys:YES];
//            
//        }else {
//            GotyeOCMessage* message = [GotyeOCMessage createTextMessage:chatTarget text:text];
//            [message putExtraData: [extString UTF8String] len:strlen([extString UTF8String])];
//            [GotyeOCAPI sendMessage:message];
//            [self reloadHistorys:YES];
//        }
//    }
//}
//
//- (RedpacketMessageModel *)toRedpacketMessageModel:(GotyeOCMessage *)model
//{
//    RedpacketMessageModel *messageModel = [RedpacketMessageModel redpacketMessageModelWithDic:[self transformExtToDictionary:model]];
//    BOOL isGroup = chatTarget.type == GotyeChatTargetTypeRoom | chatTarget.type == GotyeChatTargetTypeGroup;
//    messageModel.redpacketReceiver.isGroup = isGroup;
//    
//    messageModel.redpacketSender.userAvatar = model.sender.icon.url;
//    
//    NSString *nickName = model.sender.name;
//    if (nickName.length == 0) {
//        nickName = model.sender.name;
//    }
//    messageModel.redpacketSender.userNickname = nickName;
//    if (messageModel.redpacketSender.userId.length == 0) {
//        messageModel.redpacketSender.userId = model.sender.name;
//    }
//    
//    return messageModel;
//}
//
//-(void) onGetRoomMemberList:(GotyeStatusCode)code
//                       room:(GotyeOCRoom*)room/// <请求的聊天室
//                  pageIndex:(unsigned)pageIndex/// <请求时传入的页索引
//          curPageMemberList:(NSArray*)curPageMemberList/// <当前页所对应的成员列表（全局变量）
//              allMemberList:(NSArray*)allMemberList /// <获取到的累计所有成员表（全局变量）
//{
//    self.groupCount = (int)curPageMemberList.count;
//}
//
//- (void)onGetGroupMemberList:(GotyeStatusCode)code group:(GotyeOCGroup*)group pageIndex:(unsigned int)pageIndex curPageMemberList:(NSArray*)curPageMemberList allMemberList:(NSArray*)allMemberList
//{
//    self.groupCount = (int)curPageMemberList.count;
//}
//
//- (void)didReceiveMemoryWarning {
//    [super didReceiveMemoryWarning];
//    // Dispose of any resources that can be recreated.
//}
//
///*
//#pragma mark - Navigation
//
//// In a storyboard-based application, you will often want to do a little preparation before navigation
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    // Get the new view controller using [segue destinationViewController].
//    // Pass the selected object to the new view controller.
//}
//*/
//
//@end
