## 亲加红包接入文档(iOS)

---

#### 亲加红包简介
1. 为 APP 提供了完整的收发红包以及账户体系，发红包支持支付宝和银行卡支付， 零钱可以提现。

2. 亲加官方版Demo已默认集成红包功能，可以直接下载试用。

#### SDK介绍
`RedpacketSDK`包含: 

* `RedpacketStaticLib`静态库提供，实现了红包收发流程和账号安全体系。 

* `RedpacketOpen`开源方式提供，实现了红包消息的展示

* `AliPay` 支付宝SDK

#### Step1. 导入SDK
 将红包库`RedpacketSDK`添加到工程里。

#### Step2. 首先注册红包Token

**@description:** 

* 在```GotyeLoginController.mm```中

```
- (void)onLogin:(GotyeStatusCode)code user:(GotyeOCUser *)user
{
    if(code == GotyeStatusCodeOK || code == GotyeStatusCodeOfflineLoginOK || code == GotyeStatusCodeReloginOK)
    {
#ifdef REDPACKET_AVALABLE
        //TODO: 注册获取Token，传入用户ID。注意：此处获取失败，则无法使用红包功能
        [[RedPacketUserConfig sharedConfig] configWithUserId:textUsername.text];
#endif
     ...
     ...
}
    
```
#### Step3. 支持支付宝
**@description:** 
* 在```GotyeAppDelegate.mm```引入```GotyeAppDelegate+Redpacket.h```
* 涉及到的方法

```
- (void)applicationDidBecomeActive:(UIApplication *)application
{
      ...
      ...
#ifdef REDPACKET_AVALABLE
    [self redpacketApplicationDidBecomeActive:application];
#endif
}

```
###### 添加支付宝回调Scheme
在info.plist文件中添加支付宝回调的URL Schemes `alipayredpacket`

* 选中要编译的项目，在右侧的窗口中选择Targets中的某个target, 右侧Bulid Setting旁边有一个info选项，打开后最下边有一个URLTypes，点击加号添加一个URLType， URL schemes 设为 `alipayredpacket` 即可。

###### 添加支付宝App Transport Security Settings

* [支付宝官方集成文档](https://doc.open.alipay.com/doc2/detail?treeId=59&articleId=103676&docType=1)

#### Step4. 处理聊天界面
**@description:** 

* 替代*ChatViewController*为*RedPacketChatViewController（带有红包功能的聊天窗口）* ，**建议全局搜索并替换，以免遗漏**

#### Step5. 处理会话界面
**@description:** 

* 替代*GotyeMessageViewController*为*RedPacketMessageViewController（带有红包功能的聊天窗口）* ，**建议全局搜索并替换，以免遗漏**

#### Step6. 零钱页

**@description:**

* '亲加红包版'的零钱页放在了`GotyeSettingViewController`页面里。

* 通过`[RedpacketViewControl changeMoneyController]`获取零钱页。

* 涉及到的方法

```
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ...
    ...
#ifdef REDPACKET_AVALABLE
    if(indexPath.section == 0 && indexPath.row == SettingUserTypeMax)
    {
        UIViewController *controller = [RedpacketViewControl changeMoneyController];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
        [self presentViewController:nav animated:YES completion:nil];
    }
#endif
    ...
    ...
}
```

```
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    ...
    ...
#ifdef REDPACKET_AVALABLE
    return SettingUserTypeMax + 1;
#endif
    return SettingUserTypeMax;
  }
    ...
    ...
}
```
#### Step7. App进入Active状态和用户退出时的对于红包SDK的操作
**@description:**

* App进入Active状态涉及的方法：

```
- (void)applicationDidBecomeActive:(UIApplication *)application {
...
#ifdef REDPACKET_AVALABLE
  [self redpacketApplicationDidBecomeActive:application];
#endif
}

```
* 用户退出涉及的方法：

```
- (void)onLogout:(GotyeStatusCode)code {
...
#ifdef REDPACKET_AVALABLE
    [[YZHRedpacketBridge sharedBridge] redpacketUserLoginOut];
#endif
...
#ifdef REDPACKET_AVALABLE
    [[YZHRedpacketBridge sharedBridge] redpacketUserLoginOut];
#endif
...
}
```
#### Step8. 阅读项目的忽略文件
**@description:**
* cd到工程目录下面
```
cd ~/Desktop/gotye3.0/
cat .gitignore
```
*从链接:[http://pan.baidu.com/s/1hrQqVnI](http://pan.baidu.com/s/1hrQqVnI) 密码:x4pr 下载 `libgotyeapi.a`放入`GotyeIM_Redpacket/GotyeIM/GotyeAPI/`目录下编译即可。

#### Step9. 可能发生的错误

* `RedPacketMessageViewController`报编译错误，注意此处需在`RedPacketMessageViewController.m`中引入`GotyeMessageViewController.h
`此处主要为了引入`GotyeMessageCell
`，因为亲加通讯云将`GotyeMessageCell`写入了`GotyeMessageViewController.h`内

* 某些方法找不到，请检查BulidSetting中 OtherLinkFlag的标记是否设置正确，如果缺省，还需添加`-Objc`

* 缺少类库，支付宝需要添加的类库 [支付宝类库](https://doc.open.alipay.com/doc2/detail?treeId=59&articleId=103676&docType=1)

* HTTP链接错误， App Transport Security Settings 是否配置了支付宝相关参数， 参考支付宝文档

* 缺少参数，如果每个接口都报缺少参数，则是Token没有获取到，请检查`YZHRedpacketBridge`中红包注册的方法是否实现，或者是否传入了正确的参数。 如果是发红包页面报缺少参数，请检查`YZHRedpacketBridge`中的dataSource是否实现


* 其它，此方案为亲加官方Demo的集成方案，并不完全实用所有情况，如有不适，还望变通实现。

---


