//
//  ViewController.m
//  WifiCheck
//
//  Created by 谭真 on 2017/9/5.
//  Copyright © 2017年 Alibaba. All rights reserved.
//

#import "ViewController.h"
#import "CaptivePortalCheck.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *checkResultLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)testModeSwitchValueChanged:(UISwitch *)sender {
    [CaptivePortalCheck sharedInstance].openTestMode = sender.isOn;
}

- (IBAction)checkWifiBtnClick:(UIButton *)sender {
    self.checkResultLabel.text = @"认证中...";
    // TODO 如果当前网络状态不是WIFI，则无需检查
    [[CaptivePortalCheck sharedInstance] checkIsWifiNeedAuthPasswordWithComplection:^(BOOL needAuthPassword) {
        self.checkResultLabel.text = needAuthPassword ? @"验证结果：需要认证" : @"验证结果：无需认证";
    } needAlert:YES];
}

@end
