//
//  RedPacketMessageViewController.h
//  GotyeIM
//
//  Created by 非夜 on 16/9/24.
//  Copyright © 2016年 Gotye. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GotyeContextMenuCell.h"
#import "GotyeContextMenuCell.h"
#import "GotyeContextMenuTableViewController.h"

@interface RedPacketMessageViewController : GotyeContextMenuTableViewController

@property(strong, nonatomic) IBOutlet UIView *viewNetworkFail;
@property(strong, nonatomic) IBOutlet UILabel *labelNetwork;

@end
