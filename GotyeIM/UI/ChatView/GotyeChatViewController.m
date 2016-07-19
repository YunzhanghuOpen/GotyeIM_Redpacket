//
//  GotyeChatViewController.m
//  GotyeIM
//
//  Created by Peter on 14-10-16.
//  Copyright (c) 2014年 Gotye. All rights reserved.
//

#import "GotyeChatViewController.h"

#import "GotyeUIUtil.h"

#ifdef REDPACKET_AVALABLE

#import "RedPacketGotyeChatBubbleView.h"
#import "YZHRedpacketBridge.h"
#import "RedpacketViewControl.h"

#else

#import "GotyeChatBubbleView.h"

#endif

#import "GotyeLoadingView.h"
#import "GotyeOCAPI.h"
#import "GotyeSettingManager.h"

#import "GotyeGroupSettingController.h"
#import "GotyeChatRoomSettingController.h"
#import "GotyeRealTimeVoiceController.h"
#import "GotyeUserInfoController.h"

#import "GotyeChatTableViewCell.h"

#define BD_API_KEY @"oKUHg75KeH787zPesCSEAGPw"
#define BD_SECRET_KEY @"dIR5nZGZreIUZpfnMRmVDBbBDIGtZlLK"

static GotyeChatViewController *chatViewRetainForBDVR = nil;

@interface GotyeChatViewController () <

#ifdef REDPACKET_AVALABLE
GotyeOCDelegate,
RedpacketViewControlDelegate,
#endif

UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    GotyeOCChatTarget* chatTarget;
    
    NSString *talkingUserID;
    
    NSInteger playingRow;
    
    CGFloat keyboardHeight;
    CGFloat chatViewOriginY;
    CGFloat chatViewOffset;
    
    UIButton *largeImageView;
    
    NSArray *messageList;
    
    GotyeLoadingView *loadingView;
    BOOL haveMoreData;
    NSString *tempImagePath;
    
    GotyeOCMessage *decodingMessage;
    //BDVRRawDataRecognizer *rawDataRecognizer;
    
    NSInteger _indexRow;
    
    BOOL hasscrollView;
    
}

#ifdef REDPACKET_AVALABLE

/**
 *  发红包的控制器
 */
@property (nonatomic, strong)   RedpacketViewControl *viewControl;
@property (nonatomic,strong) NSMutableArray * groupUsersArray;
#endif

@end

@implementation GotyeChatViewController

@synthesize chatView, inputView, buttonVoice, buttonWrite, realtimeStartView, labelRealTimeStart, textInput, buttonRealTime, buttonSpeak, speakingView ;

#ifdef REDPACKET_AVALABLE

#pragma Delegate RedpacketViewControlDelegate

// 拼装RedpacketUserInfo by Message
- (RedpacketUserInfo *)profileEntityWith:(GotyeOCMessage *)model isSender:(BOOL)isSender{
    
    RedpacketUserInfo *userInfo = [RedpacketUserInfo new];
    userInfo.userAvatar = model.sender.icon.url;
    NSString *nickName = model.sender.name;
    userInfo.userNickname = nickName;
    if (userInfo.userId.length == 0) {
        userInfo.userId = model.sender.name;
    }
    userInfo.userAvatar = model.sender.icon.url;
    return userInfo;
}


- (RedpacketUserInfo *)fetchOpenRedpacketUserInfo:(NSString *)userId {
    
    RedpacketUserInfo *userInfo = nil;
    if (self.groupUsersArray.count == 0) {
        userInfo = [RedpacketUserInfo new];
        userInfo.userNickname = userId;
    }
    else{
        GotyeOCUser *tempUser = nil;
        for (GotyeOCUser *user in self.groupUsersArray) {
            if ([user.name isEqualToString:userId]) {
                tempUser = user;
                break;
            }
        }
        if (tempUser) {
            userInfo = [self profileEntityWith:tempUser];
        }else{
            userInfo = [RedpacketUserInfo new];
            userInfo.userNickname = userId;
        }
    }
    return userInfo;
}

// 要在此处根据userID获得用户昵称,和头像地址
- (RedpacketUserInfo *)profileEntityWith:(GotyeOCUser *)user
{
    RedpacketUserInfo *userInfo = [RedpacketUserInfo new];
    userInfo.userNickname = user.nickname ? user.nickname : user.name;
    userInfo.userAvatar = user.icon.url;
    userInfo.userId = user.name;
    return userInfo;
}
//定向红包
- (NSArray *)groupMemberList
{
    
    NSMutableArray *mArray = [[NSMutableArray alloc]init];
    
    for (GotyeOCUser *user in self.groupUsersArray) {
        //创建一个用户模型 并赋值
        RedpacketUserInfo *userInfo = [self profileEntityWith:user];
        BOOL msgFromSelf = [[GotyeOCAPI getLoginUser].name isEqualToString:userInfo.userId];
        if (msgFromSelf) {
            //定向红包 不能包含自己
        }else
        {
            [mArray addObject:userInfo];
        }
    }
    
    return mArray;
}


- (void)delToSelfPacketMessage:(GotyeOCMessage*)message{
    
    if (message == nil) {
        return;
    }
    
    GotyeOCUser* loginUser = [GotyeOCAPI getLoginUser];
    
    NSDictionary * ext = [self transformExtToDictionary:message];
    if ([RedpacketMessageModel isRedpacketRelatedMessage:ext]) {
        if ([RedpacketMessageModel isRedpacketTakenMessage:ext])    {
            // // 由于没有透传消息 如果群红包，A发的，A打开，others收到消息，others删除消息
            if ([ext[@"money_sender_id"] isEqualToString:ext[@"money_receiver_id"]]) {
                [GotyeOCAPI deleteMessage:chatTarget msg:message];
                return;
            }
            // 由于没有透传消息 如果群红包，A发的，B打开，other收到消息，除了A之外的others删除
            if (![ext[@"money_sender_id"] isEqualToString:loginUser.name]) {
                [GotyeOCAPI deleteMessage:chatTarget msg:message];
                return;
            }
        }
    }
}

- (NSDictionary *)transformExtToDictionary:(GotyeOCMessage*)message{
    
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

- (void)configRedPacketChatViewController{
    self.groupUsersArray = [[NSMutableArray alloc] init];
    // 获取群组人数，如果是群组或者room
    
    if (chatTarget.type == GotyeChatTargetTypeRoom) {
        [GotyeOCAPI reqRoomMemberList:[GotyeOCRoom roomWithId:chatTarget.id] pageIndex :0];/// <对应回调GotyeOCDelegate::onGetRoomMemberList
    }
    if (chatTarget.type == GotyeChatTargetTypeGroup) {
        [GotyeOCAPI reqGroupMemberList :[GotyeOCGroup groupWithId:chatTarget.id] pageIndex:0];/// <对应回调GotyeOCDelegate::onGetRoomMemberList
    }
    
    /**
     红包功能的控制器， 产生用户单击红包后的各种动作
     */
    _viewControl = [[RedpacketViewControl alloc] init];
    //  需要当前的聊天窗口
    _viewControl.conversationController = self;
    _viewControl.delegate = self;
    
    //  需要当前聊天窗口的会话ID
    RedpacketUserInfo *userInfo = [RedpacketUserInfo new];
    userInfo.userId = chatTarget.name;
    
    if (chatTarget.type == GotyeChatTargetTypeRoom || chatTarget.type == GotyeChatTargetTypeGroup) {
        
        NSString * groupId = [NSString stringWithFormat:@"%lld",chatTarget.id];
        
        userInfo.userId = groupId;
        
    }
    
    _viewControl.converstationInfo = userInfo;
    
    __weak __typeof(self)weakSelf = self;
    
    
    //  用户抢红包和用户发送红包的回调
    [_viewControl setRedpacketGrabBlock:^(RedpacketMessageModel *messageModel) {
        //  发送通知到发送红包者处
        [weakSelf sendRedpacketHasBeenTaked:messageModel];
        
    } andRedpacketBlock:^(RedpacketMessageModel *model) {
        
        model.redpacket.redpacketOrgName = @"亲加红包";
        //  发送红包
        [weakSelf sendRedPacketMessage:model];
        
    }];
    
    // 同步Token
    [[YZHRedpacketBridge sharedBridge] reRequestRedpacketUserToken];
}

//  MARK: 发送红包消息
- (void)sendRedPacketMessage:(RedpacketMessageModel *)model
{
    NSDictionary *dic = [model redpacketMessageModelToDic];
    
    NSString *txt = [NSString stringWithFormat:@"[%@]%@", model.redpacket.redpacketOrgName, model.redpacket.redpacketGreeting];
    
    GotyeOCMessage* message = [GotyeOCMessage createTextMessage:chatTarget text:txt];
    
    NSData *extData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];
    
    NSString *extString = [[NSString alloc] initWithData:extData encoding:NSUTF8StringEncoding];
    
    message.extraText = extString;
    
    [GotyeOCAPI sendMessage:message];
    
    [self reloadHistorys:YES];
    
}

//  MARK: 发送红包被抢的消息
- (void)sendRedpacketHasBeenTaked:(RedpacketMessageModel *)messageModel
{
    NSString *currentUser = [GotyeOCAPI getLoginUser].name;
    NSString *senderId = messageModel.redpacketSender.userId;
    
    NSMutableDictionary *dic = [messageModel.redpacketMessageModelToDic mutableCopy];
    /**
     *  不推送
     */
    [dic setValue:@(YES) forKey:@"em_ignore_notification"];
    
    NSString *text = [NSString stringWithFormat:@"你领取了%@发的红包", messageModel.redpacketSender.userNickname];
    
    NSData *extData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];
    
    NSString *extString = [[NSString alloc] initWithData:extData encoding:NSUTF8StringEncoding];
    
    if (chatTarget.type == GotyeChatTargetTypeUser) {
        
        GotyeOCMessage* message = [GotyeOCMessage createTextMessage:chatTarget text:text];
        message.extraText = extString;
        [GotyeOCAPI sendMessage:message];
        [self reloadHistorys:YES];
        
    }
    else if(chatTarget.type == GotyeChatTargetTypeRoom || chatTarget.type == GotyeChatTargetTypeGroup){
        if ([senderId isEqualToString:currentUser]) {
            text = @"你领取了自己的红包";
            // 如果是群红包，这个红包被自己领了，则给自己发一条消息，同时在消息的接收处过滤出来这条消息（过滤方式，检测是否是红包消息，检测消息发送方和自己是不是同一个人，是同一个人则删除此消息）
            GotyeOCMessage* message = [GotyeOCMessage createTextMessage:chatTarget text:text];
            message.extraText = extString;
            [GotyeOCAPI sendMessage:message];
            [self reloadHistorys:YES];
            
        }else {
            GotyeOCMessage* message = [GotyeOCMessage createTextMessage:chatTarget text:text];
            message.extraText = extString;
            [GotyeOCAPI sendMessage:message];
            [self reloadHistorys:YES];
        }
    }
}

- (RedpacketMessageModel *)toRedpacketMessageModel:(GotyeOCMessage *)model
{
    RedpacketMessageModel *messageModel = [RedpacketMessageModel redpacketMessageModelWithDic:[self transformExtToDictionary:model]];
    BOOL isGroup = chatTarget.type == GotyeChatTargetTypeRoom | chatTarget.type == GotyeChatTargetTypeGroup;
    messageModel.redpacketReceiver.isGroup = isGroup;
    
    if (isGroup) {
        messageModel.redpacketSender = [self profileEntityWith:model isSender:YES];
        messageModel.toRedpacketReceiver = [self fetchOpenRedpacketUserInfo:messageModel.toRedpacketReceiver.userId];
    }else
    {
        messageModel.redpacketSender = [self profileEntityWith:model isSender:YES];
    }
    
    return messageModel;
}

-(void) onGetRoomMemberList:(GotyeStatusCode)code
                       room:(GotyeOCRoom*)room/// <请求的聊天室
                  pageIndex:(unsigned)pageIndex/// <请求时传入的页索引
          curPageMemberList:(NSArray*)curPageMemberList/// <当前页所对应的成员列表（全局变量）
              allMemberList:(NSArray*)allMemberList /// <获取到的累计所有成员表（全局变量）
{
    if (allMemberList.count > 0) {
        [self.groupUsersArray removeAllObjects];
        [self.groupUsersArray addObjectsFromArray:allMemberList];
    }
}

- (void)onGetGroupMemberList:(GotyeStatusCode)code group:(GotyeOCGroup*)group pageIndex:(unsigned int)pageIndex curPageMemberList:(NSArray*)curPageMemberList allMemberList:(NSArray*)allMemberList
{
    if (allMemberList.count > 0) {
        [self.groupUsersArray removeAllObjects];
        [self.groupUsersArray addObjectsFromArray:allMemberList];
    }
}

#endif

- (id)initWithTarget:(GotyeOCChatTarget*)target
{
    self = [self init];
    if(self)
    {
        chatTarget = target;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
#ifdef REDPACKET_AVALABLE
    [self configRedPacketChatViewController];
#endif
    
    // Do any additional setup after loading the view from its nib.
    switch (chatTarget.type) {
        case GotyeChatTargetTypeUser:
        {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                                      initWithImage:[UIImage imageNamed:@"nav_button_user"]
                                                      style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(targetUserClick:)];
            
            GotyeOCUser* user = [GotyeOCAPI getUserDetail:chatTarget forceRequest:NO];
            self.navigationItem.title = user.name;
        }
            break;
            
        case GotyeChatTargetTypeGroup:
        {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                                      initWithImage:[UIImage imageNamed:@"nav_button_user"]
                                                      style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(groupSettingClick:)];
            
            GotyeOCGroup* group = [GotyeOCAPI getGroupDetail:chatTarget forceRequest:NO];
            self.navigationItem.title = group.name;
        }
            break;
            
        case GotyeChatTargetTypeRoom:
        {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                                      initWithImage:[UIImage imageNamed:@"nav_button_user"]
                                                      style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(roomSettingClick:)];
            
            GotyeOCRoom* room = [GotyeOCAPI getRoomDetail:chatTarget forceRequest: NO];
            self.navigationItem.title = room.name;
        }
            break;
    }
    
    messageList = [GotyeOCAPI getMessageList:chatTarget more:chatTarget.type==GotyeChatTargetTypeRoom];
    
    loadingView = [[GotyeLoadingView alloc] init];
    loadingView.hidden = YES;
    haveMoreData = YES;
    
    buttonSpeak.exclusiveTouch = YES;
    buttonSpeak.multipleTouchEnabled = NO;
    
    speakingView.layer.cornerRadius = 20;
    speakingView.layer.masksToBounds = YES;
    speakingView.hidden = YES;
    
    hasscrollView = YES;
}

- (void)viewDidLayoutSubviews
{
    chatViewOriginY = chatView.frame.origin.y;
}

- (void)reloadHistorys:(BOOL)scrollToEnd
{
    playingRow = -1;
    messageList = [GotyeOCAPI getMessageList:chatTarget more:NO];
    
    [self.tableView reloadData];
    
    if(messageList.count > 0 && scrollToEnd)
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:messageList.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.view addSubview:chatView];
    if(self.isMovingToParentViewController)
    {
        chatView.frame = CGRectMake(0, self.view.frame.size.height - 50, ScreenWidth, 150);
        self.tableView.frame = CGRectMake(0, 0, ScreenWidth, chatView.frame.origin.y);
        //        UIView *footView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 50)];
        //        self.tableView.tableFooterView = footView;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exitChatProcesses) name:popToRootViewControllerNotification object:nil];
    }
    
    [GotyeOCAPI addListener:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHidden:) name:UIKeyboardWillHideNotification object:nil];
    
    [GotyeOCAPI activeSession:chatTarget];
    
    [self reloadHistorys:self.isMovingToParentViewController];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    if(self.isMovingFromParentViewController)
    {
        [self exitChatProcesses];
    }
}

- (void)exitChatProcesses
{
    [GotyeOCAPI stopPlay];
    
    [GotyeOCAPI removeListener:self];
    
    [GotyeOCAPI deactiveSession:chatTarget];
    if(chatTarget.type == GotyeChatTargetTypeRoom)
    {
        GotyeOCRoom* room = [GotyeOCRoom roomWithId:chatTarget.id];
        [GotyeOCAPI leaveRoom:room];
    }
    
    [GotyeOCAPI stopTalk];
    
    //rawDataRecognizer.delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) keyboardWillShown:(NSNotification*)notify
{
    [self moveTextViewForKeyBoard:notify up:YES];
}

- (void) keyboardWillHidden:(NSNotification*)notify
{
    [self moveTextViewForKeyBoard:notify up:NO];
    
    keyboardHeight = 0;
}

- (void) moveTextViewForKeyBoard:(NSNotification*)notify up:(BOOL)up
{
    NSDictionary *userInfo = [notify userInfo];
    
    // Get animation info from userInfo
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    
    CGRect keyboardEndFrame;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    
    
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    
    keyboardHeight = keyboardEndFrame.size.height;
    
    if(animationDuration > 0)
    {
        // Animate up or down
        [UIView beginAnimations:@"contentMove" context:nil];
        [UIView setAnimationDuration:animationDuration];
        [UIView setAnimationCurve:animationCurve];
        [UIView setAnimationBeginsFromCurrentState:YES];
    }
    
    //    CGRect newFrame = chatView.frame;
    
    if(!up)
        //        newFrame.origin.y = chatViewOriginY;
        chatViewOffset = 0;
    else
    {
        //        newFrame.origin.y = self.view.frame.size.height - keyboardHeight - 50;
        chatViewOffset = -keyboardHeight;
    }
    chatView.transform = CGAffineTransformMakeTranslation(0, chatViewOffset);
    //    chatView.frame = newFrame;
    
    if(animationDuration > 0)
    {
        [UIView commitAnimations];
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)sendClick:(UITextField *)sender
{
    [sender resignFirstResponder];
    
    if(sender.text.length <=0)
        return;
    
    GotyeOCMessage* msg = [GotyeOCMessage createTextMessage:chatTarget text:sender.text];
    [GotyeOCAPI sendMessage:msg];
    
    sender.text = @"";
    
    [self reloadHistorys:YES];
}

- (IBAction)voiceButtonClick:(id)sender
{
    
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
        [[AVAudioSession sharedInstance] performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
            if (granted) {
                [UIView beginAnimations:nil context:NULL];
                [UIView setAnimationDuration:0.2];
                
                buttonWrite.alpha = 1;
                buttonVoice.alpha = 0;
                inputView.frame = CGRectMake(inputView.frame.origin.x, -50, 320, 100);
                
                [UIView commitAnimations];
                
                [textInput resignFirstResponder];
                
            }
            else {
                NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
                CFShow((__bridge CFTypeRef)(infoDictionary));
                NSString *app_Name = [infoDictionary objectForKey:@"CFBundleDisplayName"];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:@""
                                                message:
                      [NSString stringWithFormat:@"%@需要访问您的麦克风。\n请启用麦克风-设置/隐私/麦克风", app_Name]
                                               delegate:nil
                                      cancelButtonTitle:@"确定"
                                      otherButtonTitles:nil]
                     show];
                });
            }
        }];
    }
    
    //    [UIView beginAnimations:nil context:NULL];
    //    [UIView setAnimationDuration:0.2];
    //
    //    buttonWrite.alpha = 1;
    //    buttonVoice.alpha = 0;
    //    inputView.frame = CGRectMake(inputView.frame.origin.x, -50, ScreenWidth, 100);
    //
    //    [UIView commitAnimations];
    //
    //    [textInput resignFirstResponder];
}

- (IBAction)writeButtonClick:(id)sender
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.2];
    
    buttonWrite.alpha = 0;
    buttonVoice.alpha = 1;
    inputView.frame = CGRectMake(inputView.frame.origin.x, 0, ScreenWidth, 100);
    
    [UIView commitAnimations];
}

- (IBAction)addButtonClick:(id)sender
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.2];
    
    //    CGRect frame = chatView.frame;
    //
    //    if(frame.origin.y < self.view.frame.size.height - 50)
    //        frame.origin.y = self.view.frame.size.height - 50;
    //    else
    //        frame.origin.y = self.view.frame.size.height - frame.size.height;
    //
    //    chatView.frame =frame;
    //    self.tableView.frame = CGRectMake(0, 0, ScreenWidth, chatView.frame.origin.y);
    
    if(chatViewOffset < 0)
        chatViewOffset = 0;
    else
        chatViewOffset = -100;
    
    chatView.transform = CGAffineTransformMakeTranslation(0, chatViewOffset);
    
    [UIView commitAnimations];
    
    buttonRealTime.hidden = ![GotyeOCAPI supportRealtime:chatTarget];
    
#ifdef REDPACKET_AVALABLE
    self.redPacketButton.hidden = NO;
#endif
    
    [textInput resignFirstResponder];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    NSData *jpgTempImage = [GotyeUIUtil ConpressImageToJPEGData:image maxSize:ImageFileSizeMax];
    tempImagePath = [[GotyeSettingManager defaultManager].settingDirectory stringByAppendingString:@"temp.jpg"];
    [jpgTempImage writeToFile:tempImagePath atomically:YES];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    GotyeOCMessage* msg = [GotyeOCMessage createImageMessage:chatTarget imagePath:tempImagePath];
    [GotyeOCAPI sendMessage:msg];
    [self reloadHistorys:YES];
}

- (IBAction)albumClick:(id)sender
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    imagePicker.delegate = self;
    
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    imagePicker.allowsEditing = YES;
    
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (IBAction)cameraButtonClick:(id)sender
{
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        buttonWrite.alpha = 0;//解决在显示“按住说话”时拍照返回时界面显示bug
        buttonVoice.alpha = 1;
        
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        
        imagePicker.delegate = self;
        
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePicker.videoQuality = UIImagePickerControllerQualityTypeLow;
        imagePicker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        imagePicker.allowsEditing = YES;
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
}

- (IBAction)realtimeClick:(id)sender
{
    if(chatTarget.type == GotyeChatTargetTypeRoom && [GotyeOCAPI supportRealtime:chatTarget])
    {
        if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
            [[AVAudioSession sharedInstance] performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                if (granted) {
                    GotyeRealTimeVoiceController *viewController = [[GotyeRealTimeVoiceController alloc] initWithRoomID:(unsigned)chatTarget.id talkingID:talkingUserID];
                    [self.navigationController pushViewController:viewController animated:YES];
                }
                else {
                    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
                    CFShow((__bridge CFTypeRef)(infoDictionary));
                    NSString *appName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[[UIAlertView alloc] initWithTitle:@""
                                                    message:
                          [NSString stringWithFormat:@"%@需要访问您的麦克风。\n请启用麦克风-设置/隐私/麦克风", appName]
                                                   delegate:nil
                                          cancelButtonTitle:@"确定"
                                          otherButtonTitles:nil]
                         show];
                    });
                }
            }];
        }
        //        GotyeRealTimeVoiceController *viewController = [[GotyeRealTimeVoiceController alloc] initWithRoomID:(unsigned)chatTarget.id talkingID:talkingUserID];
        //        [self.navigationController pushViewController:viewController animated:YES];
    }
}

- (IBAction)redpacketAction:(id)sender {
#ifdef REDPACKET_AVALABLE
    if (chatTarget.type == GotyeChatTargetTypeUser) {
        [self.viewControl presentRedPacketViewController];
    }
    else if(chatTarget.type == GotyeChatTargetTypeRoom || chatTarget.type == GotyeChatTargetTypeGroup){
        [self.viewControl presentRedPacketMoreViewControllerWithGroupMemberArray:self.groupUsersArray];
    }
    
#endif
    
    
}

-(IBAction)speakButtonDown:(id)sender
{
    if(talkingUserID == nil)
        [GotyeOCAPI stopPlay];
    
    if([GotyeOCAPI startTalk:chatTarget mode:GotyeWhineModeDefault realtime:NO maxDuration:60*1000] == GotyeStatusCodeWaitingCallback)
    {
        speakingView.hidden = NO;
    }
    
    //    self.navigationController.view.userInteractionEnabled = NO;
}

-(IBAction)speakButtonUp:(id)sender
{
    [GotyeOCAPI stopTalk];
    
    [self reloadHistorys:YES];
    
    speakingView.hidden = YES;
    
    //    self.navigationController.view.userInteractionEnabled = YES;
}

-(void)messageClick:(UIButton*)button
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag inSection:0];
    
    GotyeOCMessage* message = messageList[indexPath.row];
    
    //    [GotyeOCAPI report: 1 content:@"涉及暴力" message: message];
    
    switch (message.type) {
        case GotyeMessageTypeAudio:
        {
            if(talkingUserID != nil)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                                message:@"正在实时语音中"
                                                               delegate:nil
                                                      cancelButtonTitle:@"确定"
                                                      otherButtonTitles:nil, nil];
                [alert show];
                return;
                
            }
            else if(playingRow == button.tag)
            {
                [GotyeOCAPI stopPlay];
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                UIImageView *voiceImage = (UIImageView*)[cell viewWithTag:bubblePlayImageTag];
                [voiceImage stopAnimating];
                playingRow = -1;
            }
            else
            {
                if(message.media.status!=GotyeMediaStatusDownloading && ![[NSFileManager defaultManager] fileExistsAtPath:message.media.path])
                {
                    [GotyeOCAPI downloadMediaInMessage:message];
                    [self reloadHistorys:NO];
                    break;
                }
                
                status s = [GotyeOCAPI playMessage:message];
                if(s == GotyeStatusCodeOK)
                {
                    [self onPlayStop];
                    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                    UIImageView *voiceImage = (UIImageView*)[cell viewWithTag:bubblePlayImageTag];
                    [voiceImage startAnimating];
                    playingRow = indexPath.row;
                }
            }
        }
            break;
            
        case GotyeMessageTypeImage:
        {
            if(largeImageView!=nil)
                break;
            
            if(message.media.status!=GotyeMediaStatusDownloading && ![[NSFileManager defaultManager] fileExistsAtPath:message.media.pathEx])
            {
                [GotyeOCAPI downloadMediaInMessage:message];
                [self reloadHistorys:NO];
                break;
            }
            
            UIImage *image = [UIImage imageWithContentsOfFile:message.media.pathEx];
            
            if(image != nil)
            {
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                UIImageView *thumbImageView = (UIImageView*)[cell viewWithTag:bubbleThumbImageTag];
                CGPoint transCenter = [thumbImageView.superview convertPoint:thumbImageView.center toView:self.view];
                
                largeImageView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
                [largeImageView addTarget:self action:@selector(largeImageClose:) forControlEvents:UIControlEventTouchUpInside];
                
                CGSize imgSize = CGSizeMake(image.size.width / 2, image.size.height / 2);
                if(imgSize.width > self.view.frame.size.width)
                {
                    imgSize.height = self.view.frame.size.width * imgSize.height / imgSize.width;
                    imgSize.width = self.view.frame.size.width;
                }
                if(imgSize.height > self.view.frame.size.height)
                {
                    imgSize.width = self.view.frame.size.height * imgSize.width / imgSize.height;
                    imgSize.height = self.view.frame.size.height;
                }
                image = [GotyeUIUtil scaleImage:image toSize:CGSizeMake(imgSize.width*2, imgSize.height*2)];
                
                UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, imgSize.width, imgSize.height)];
                //                imageView.contentMode = UIViewContentModeScaleAspectFit;
                imageView.image = image;
                imageView.center = largeImageView.center;
                
                [largeImageView addSubview:imageView];
                [self.view addSubview:largeImageView];
                
                CGAffineTransform transform = CGAffineTransformMakeTranslation(transCenter.x - imageView.center.x, transCenter.y - imageView.center.y);
                transform = CGAffineTransformScale(transform, thumbImageView.frame.size.width / imageView.frame.size.width, thumbImageView.frame.size.height / imageView.frame.size.height);
                
                largeImageView.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
                imageView.transform = transform;
                
                [UIView beginAnimations:nil context:NULL];
                [UIView setAnimationDuration:0.3];
                
                largeImageView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
                imageView.transform = CGAffineTransformIdentity;
                
                [UIView commitAnimations];
            }
        }
            break;
            
        default:
            break;
    }
}

- (void)largeImageClose:(id)sender
{
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         largeImageView.alpha = 0;
                     }
                     completion:^(BOOL finished){
                         if (finished){
                             [largeImageView removeFromSuperview];
                             largeImageView = nil;
                         }
                     }
     ];
}

- (void)groupSettingClick:(id)sender
{
    GotyeGroupSettingController *viewController = [[GotyeGroupSettingController alloc] initWithTarget:[GotyeOCAPI getGroupDetail:chatTarget forceRequest:NO]];
    [GotyeOCAPI stopPlay];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)roomSettingClick:(id)sender
{
    GotyeChatRoomSettingController *viewController = [[GotyeChatRoomSettingController alloc] initWithTarget:[GotyeOCAPI getRoomDetail:chatTarget forceRequest: NO]];
    [GotyeOCAPI stopPlay];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)targetUserClick:(id)sender
{
    GotyeUserInfoController *viewController = [[GotyeUserInfoController alloc] initWithTarget:[GotyeOCAPI getUserDetail:chatTarget forceRequest:NO] groupID:0];
    [GotyeOCAPI stopPlay];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)userClick:(UIButton*)sender
{
    GotyeOCMessage* message = messageList[sender.tag];
    
    GotyeUserInfoController *viewController = [[GotyeUserInfoController alloc] initWithTarget:[GotyeOCAPI getUserDetail:message.sender forceRequest:NO] groupID:0];
    [GotyeOCAPI stopPlay];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(loadingView.hidden && scrollView.contentOffset.y < -20 && hasscrollView)
    {
        
        hasscrollView = NO;
        
        loadingView.frame = CGRectMake(0, -40, ScreenWidth, 40);
        [scrollView insertSubview:loadingView atIndex:0];
        loadingView.hidden = NO;
        [loadingView showLoading:haveMoreData];
        
        if(haveMoreData)
        {
            NSInteger lastCount = messageList.count;
            messageList = [GotyeOCAPI getMessageList:chatTarget more:YES];
            //            messageList = [GotyeOCAPI getMessageList:chatTarget more:NO];
            
            if(chatTarget.type != GotyeChatTargetTypeRoom)
            {
                if(lastCount == messageList.count)
                {
                    haveMoreData = NO;
                    hasscrollView = YES;
                    
                    [loadingView showLoading:haveMoreData];
                }
                else
                {
                    CGFloat lastOffsetY = self.tableView.contentOffset.y;
                    CGFloat lastContentHeight = self.tableView.contentSize.height;
                    
                    loadingView.hidden = YES;
                    [self reloadHistorys:NO];
                    hasscrollView = YES;
                    
                    CGFloat newOffsetY = self.tableView.contentSize.height - lastContentHeight + lastOffsetY;
                    
                    [self.tableView scrollRectToVisible:CGRectMake(0, newOffsetY, ScreenHeight, self.tableView.frame.size.height) animated:NO];
                }
            }else {
                
            }
        }
    }
    
}

#pragma mark - Gotye UI delegates

- (void)onSendMessage:(GotyeStatusCode)code message:(GotyeOCMessage*)message
{
    
    [self reloadHistorys:YES];
    
    if(message.type == GotyeMessageTypeImage)
    {
        [[NSFileManager defaultManager] removeItemAtPath:tempImagePath  error:nil];
        tempImagePath = nil;
    }
}

- (void)onReceiveMessage:(GotyeOCMessage*)message downloadMediaIfNeed:(bool *)downloadMediaIfNeed
{
#ifdef REDPACKET_AVALABLE
    [self delToSelfPacketMessage:message];
#endif
    [self reloadHistorys:YES];
    
    *downloadMediaIfNeed = true;
}

- (void)onGetMessageList:(GotyeStatusCode)code msglist:(NSArray *)msgList downloadMediaIfNeed:(bool *)downloadMediaIfNeed
{
#ifdef REDPACKET_AVALABLE
    
    @autoreleasepool {
        for (GotyeOCMessage * msg in msgList) {
            [self delToSelfPacketMessage:msg];
        }
    }
#endif
    
    //    if(chatTarget.type == GotyeChatTargetTypeRoom)
    //    {
    CGFloat lastOffsetY = self.tableView.contentOffset.y;
    CGFloat lastContentHeight = self.tableView.contentSize.height;
    
    [self reloadHistorys:NO];
    
    CGFloat newOffsetY = self.tableView.contentSize.height - lastContentHeight + lastOffsetY;
    
    [self.tableView scrollRectToVisible:CGRectMake(0, newOffsetY, ScreenHeight, self.tableView.frame.size.height) animated:NO];
    //    }
    
    *downloadMediaIfNeed = true;
    
    hasscrollView = YES;
    
    loadingView.hidden = YES;
    haveMoreData = (msgList.count > 0);
}

- (void)onDownloadMediaInMessage:(GotyeStatusCode)code message:(GotyeOCMessage*)message
{
    [self reloadHistorys:NO];
}

- (void)onUserDismissGroup:(GotyeOCGroup*)group user:(GotyeOCUser*)user
{
    if(group.id == chatTarget.id && chatTarget.type == GotyeChatTargetTypeGroup)
    {
        [GotyeOCAPI deleteSession:group alsoRemoveMessages: NO];
        [GotyeUIUtil popToRootViewControllerForNavgaion:self.navigationController animated:YES];
    }
}

- (void)onUserKickedFromGroup:(GotyeOCGroup*)group kicked:(GotyeOCUser*)kicked actor:(GotyeOCUser*)actor
{
    GotyeOCUser* myself = [GotyeOCAPI getLoginUser];
    if ([myself.name isEqualToString:kicked.name]) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"您已被群主移出该群！" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
        [alert show];
        [self performSelector:@selector(dismissAlert:) withObject:alert afterDelay:1.0];
        [GotyeOCAPI deleteSession:group alsoRemoveMessages:NO];
    }else {
        
    }
    
}

- (void)dismissAlert:(UIAlertView *)alert
{
    if (alert) {
        [alert dismissWithClickedButtonIndex:[alert cancelButtonIndex] animated:YES];
        
        [GotyeUIUtil popToRootViewControllerForNavgaion:self.navigationController animated:YES];
    }
}

- (void)onPlayStop
{
    for(UITableViewCell* cell in self.tableView.visibleCells)
    {
        UIImageView *voiceImage = (UIImageView*)[cell viewWithTag:bubblePlayImageTag];
        [voiceImage stopAnimating];
    }
    
    playingRow = -1;
    
    talkingUserID = nil;
    [realtimeStartView removeFromSuperview];
}

- (void)onRealPlayStart:(GotyeStatusCode)code speaker:(GotyeOCUser*)speaker room:(GotyeOCRoom*)room
{
    talkingUserID = speaker.name;
    
    labelRealTimeStart.text = [NSString stringWithFormat:@"%@发起了实时对讲", talkingUserID];
    
    [self.view addSubview:realtimeStartView];
    realtimeStartView.hidden = NO;
}

- (void)onStopTalk:(GotyeStatusCode)code realtime:(bool)realtime message:(GotyeOCMessage*)message cancelSending:(bool *)cancelSending
{
    if(code == GotyeStatusCodeVoiceTooShort)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:@"录音时间太短"
                                                       delegate:nil
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
    speakingView.hidden = YES;
    
    *cancelSending = YES;
    if (code == GotyeStatusCodeOK) {
        
        if(message.text && message.text.length > 0){
            //        const char* cstring = [message.text UTF8String];
            //        [message putExtraData: cstring len: strlen(cstring)];
            message.extraText = message.text;
        }
        
        [GotyeOCAPI sendMessage: message];
    }
    //*cancelSending = YES;
    //[GotyeOCAPI decodeAudioMessage:message];
}

- (void)onDecodeMessage:(GotyeStatusCode)code message:(GotyeOCMessage *)message
{
    if(decodingMessage != nil)
    {
        [GotyeOCAPI sendMessage:message];
        return;
    }
    
    decodingMessage = message;
    /*
     if(rawDataRecognizer == nil)
     {
     // 设置开发者信息，必须修改API_KEY和SECRET_KEY为在百度开发者平台申请得到的值，否则示例不能工作
     [[BDVoiceRecognitionClient sharedInstance] setApiKey:BD_API_KEY withSecretKey:BD_SECRET_KEY];
     // 设置是否需要语义理解，只在搜索模式有效
     [[BDVoiceRecognitionClient sharedInstance] setConfig:@"nlu" withFlag:YES];
     
     // 数据识别
     rawDataRecognizer = [[BDVRRawDataRecognizer alloc] initRecognizerWithSampleRate:8000 property:EVoiceRecognitionPropertyInput delegate:self];
     }
     
     int status = [rawDataRecognizer startDataRecognition];
     if (status == EVoiceRecognitionStartWorking) {
     //启动发送数据线程
     //    [self sendAudioThread];
     
     chatViewRetainForBDVR = self;
     
     [NSThread detachNewThreadSelector:@selector(sendAudioThread) toTarget:self withObject:nil];
     }*/
}

//音频流识别按钮响应函数
- (void)sendAudioThread
{
    /*
     NSLog(@"sendAudioThread[IN]");
     
     int hasReadFileSize = 0;
     //从文件中读取音频
     int sizeToRead = 8000 * 0.080 * 16 / 8;
     while (YES) {
     NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:decodingMessage.media.pathEx];
     [fileHandle seekToFileOffset:hasReadFileSize];
     NSData* data = [fileHandle readDataOfLength:sizeToRead];
     [fileHandle closeFile];
     hasReadFileSize += [data length];
     if ([data length]>0)
     {
     [rawDataRecognizer sendDataToRecognizer:data];
     }
     else
     {
     [rawDataRecognizer allDataHasSent];
     break;
     }
     }
     */
    NSLog(@"sendAudioThread[OUT]");
}
/*
 - (void)VoiceRecognitionClientWorkStatus:(int) aStatus obj:(id)aObj
 {
 switch (aStatus)
 {
 case EVoiceRecognitionClientWorkStatusFinish:
 {
 NSMutableString *tmpString;
 if ([[BDVoiceRecognitionClient sharedInstance] getRecognitionProperty] != EVoiceRecognitionPropertyInput)
 {
 NSMutableArray *audioResultData = (NSMutableArray *)aObj;
 tmpString = [[NSMutableString alloc] initWithString:@""];
 
 for (int i=0; i<[audioResultData count]; i++)
 {
 [tmpString appendFormat:@"%@\r\n",[audioResultData objectAtIndex:i]];
 }
 }
 else
 {
 tmpString = [[NSMutableString alloc] initWithString:@""];
 for (NSArray *result in aObj)
 {
 NSDictionary *dic = [result objectAtIndex:0];
 NSString *candidateWord = [[dic allKeys] objectAtIndex:0];
 [tmpString appendString:candidateWord];
 }
 }
 
 NSDictionary *resultDic = [tmpString objectFromJSONString];
 NSArray *resultArray = [resultDic objectForKey:@"item"];
 NSString *resultString = [resultArray objectAtIndex:0];
 
 if(resultString != nil && ![resultString isEqualToString:@""])
 {
 const char* str = [resultString cStringUsingEncoding:NSUTF8StringEncoding];
 [decodingMessage putExtraData:(void*)str len:strlen(str)];
 }
 
 [GotyeOCAPI sendMessage:decodingMessage];
 decodingMessage = nil;
 
 NSLog(@"识别完成");
 
 break;
 }
 case EVoiceRecognitionClientWorkStatusFlushData:
 {
 //            NSMutableString *tmpString = [[NSMutableString alloc] initWithString:@""];
 //
 //            [tmpString appendFormat:@"%@",[aObj objectAtIndex:0]];
 //
 //            break;
 }
 case EVoiceRecognitionClientWorkStatusReceiveData:
 {
 //            if ([[BDVoiceRecognitionClient sharedInstance] getRecognitionProperty] == EVoiceRecognitionPropertyInput)
 //            {
 //                NSString *tmpString = [self composeInputModeResult:aObj];
 //
 //            }
 
 break;
 }
 case EVoiceRecognitionClientWorkStatusEnd:
 {
 break;
 }
 default:
 {
 break;
 }
 }
 }
 
 - (void)VoiceRecognitionClientErrorStatus:(int) aStatus subStatus:(int)aSubStatus
 {
 [GotyeOCAPI sendMessage:decodingMessage];
 decodingMessage = nil;
 }
 */

-(void) onReport:(GotyeStatusCode)code message:(GotyeOCMessage*)message;
{
    if (code == GotyeStatusCodeOK) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"举报成功" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
    }
}
#pragma mark - table delegate & data

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return messageList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GotyeOCMessage* message = messageList[indexPath.row];
    
    BOOL showDate = NO;
    if(indexPath.row == 0)
        showDate = YES;
    else
    {
        GotyeOCMessage* lastmessage = messageList[indexPath.row - 1];
        if(message.date - lastmessage.date > 300)
            showDate = YES;
    }
    
#ifdef REDPACKET_AVALABLE
    
    return [RedPacketGotyeChatBubbleView getbubbleHeight:message target:chatTarget showDate:showDate];
    
#else
    
    return [GotyeChatBubbleView getbubbleHeight:message target:chatTarget showDate:showDate];
    
#endif
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *MessageCellIdentifier = @"MessageCellIdentifier";
    
    GotyeChatTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MessageCellIdentifier];
    if(cell == nil)
    {
        cell = [[GotyeChatTableViewCell alloc] init];
    }
    
    for (UIView *view in [cell.contentView subviews]) {
        [view removeFromSuperview];
    }
    
    GotyeOCMessage* message = messageList[indexPath.row];
    
    BOOL showDate = NO;
    if(indexPath.row == 0)
        showDate = YES;
    else
    {
        GotyeOCMessage* lastmessage = messageList[indexPath.row - 1];
        if(message.date - lastmessage.date > 300)
            showDate = YES;
    }
    
#ifdef REDPACKET_AVALABLE
    UIView *bubble = [RedPacketGotyeChatBubbleView BubbleWithMessage:message target:chatTarget showDate:showDate];
    
#else
    
    UIView *bubble = [GotyeChatBubbleView BubbleWithMessage:message target:chatTarget showDate:showDate];
    
#endif
    
    
    UIButton *msgButton = (UIButton *)[(UIButton*)bubble viewWithTag:bubbleMessageButtonTag];
    msgButton.tag = indexPath.row;
    [msgButton addTarget:self action:@selector(messageClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [cell.contentView addSubview:bubble];
    
    if(playingRow == indexPath.row)
    {
        UIImageView *voiceImage = (UIImageView*)[cell viewWithTag:bubblePlayImageTag];
        [voiceImage startAnimating];
    }
    
    UIButton *headButton = (UIButton*)[cell viewWithTag:bubbleHeadButtonTag];
    headButton.tag = indexPath.row;
    [headButton addTarget:self action:@selector(userClick:) forControlEvents:UIControlEventTouchUpInside];
    
    cell.backgroundColor = [UIColor clearColor];
    
    cell.didSelectedCell = ^(id sender){
        GotyeOCMessage *mess = [[GotyeOCMessage alloc] init];
        mess = messageList[_indexRow];
        [GotyeOCAPI report:0 content:@"fff" message:mess];
    };
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (playingRow == indexPath.row) {
        
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            UIImageView *voiceImage = (UIImageView*)[cell viewWithTag:bubblePlayImageTag];
            [voiceImage startAnimating];
        });
        
    }else {
#ifdef REDPACKET_AVALABLE
        
        GotyeOCMessage* message = messageList[indexPath.row];
        NSDictionary *dict = [self transformExtToDictionary:message];
        
        if ([RedpacketMessageModel isRedpacket:dict]) {
            [self.viewControl redpacketCellTouchedWithMessageModel:[self toRedpacketMessageModel:message]];
            
        }else {
            
        }
#endif
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UIMenuController *menu=[UIMenuController sharedMenuController];
    UIMenuItem *flag = [[UIMenuItem alloc] initWithTitle:@"举报"action:@selector(test:)];
    [menu setMenuItems:[NSArray arrayWithObjects:flag, nil]];
    [[UIMenuController sharedMenuController] update];
    _indexRow = indexPath.row;
    return YES;
}
- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(test:)){
        return YES;
    }  else {
        return NO;
    }
}

//- (BOOL)canBecomeFirstResponder
//{
//    return YES;
//}
//- (BOOL)becomeFirstResponder {
//    return YES;
//}
//
- (void)test:(id)sender {
    
}
//
//-(BOOL)canPerformAction:(SEL)action withSender:(id)sender
//{
//    if(action ==@selector(test:)){
//
//        return YES;
//    }
//    return [super canPerformAction:action withSender:sender];
//}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    
}
@end
