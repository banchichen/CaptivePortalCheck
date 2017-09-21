//
//  CaptivePortalCheck.m
//  alishuju
//
//  Created by 谭真 on 2017/8/30.
//  Copyright © 2017年 Alibaba. All rights reserved.
//

#import "CaptivePortalCheck.h"
#import <WebKit/WebKit.h>
#import <SafariServices/SafariServices.h>

@interface CaptivePortalCheck()<WKNavigationDelegate,UIAlertViewDelegate>
@property (strong, nonatomic) WKWebView *webView;
@property (nonatomic, copy) void(^networkCheckComplection)(BOOL needAuthPassword);
@property (assign, nonatomic) BOOL needAlert;
/// 预期加载的url
@property (copy, nonatomic) NSURL *expectUrl;
/// 实际加载的url
@property (copy, nonatomic) NSURL *trueUrl;
@end

@implementation CaptivePortalCheck

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static CaptivePortalCheck *manager = nil;
    dispatch_once(&onceToken, ^{
        if (manager == nil) {
            manager = [[CaptivePortalCheck alloc] init];
            manager.expectUrl = [NSURL URLWithString:@"http://www.baidu.com"];
        }
    });
    return manager;
}

/// 检查当前wifi是否需要验证密码
- (void)checkIsWifiNeedAuthPasswordWithComplection:(void (^)(BOOL needAuthPassword))complection needAlert:(BOOL)needAlert {
    _needAlert = needAlert;
    _networkCheckComplection = complection;
    NSURLRequest *request = [NSURLRequest requestWithURL:self.expectUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20];
    [self.webView loadRequest:request];
}

- (WKWebView *)webView {
    if (!_webView) {
        _webView = [[WKWebView alloc] init];
        _webView.frame = CGRectZero;
        _webView.navigationDelegate = self;
    }
    return _webView;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    decisionHandler(WKNavigationActionPolicyAllow);
    
    self.trueUrl = navigationAction.request.URL;
    if (self.openTestMode) {
        // 测试用 这个url是上海花生地铁wifi的认证页，连上上海花生地铁wifi后，未认证时访问所有网页都会被重定向到该地址
        self.trueUrl= [NSURL URLWithString:@"http://portal.wifi8.com/wifiapp"];
    }
    if ([self.trueUrl.host containsString:@"baidu.com"]) {
        if (_networkCheckComplection) {
            _networkCheckComplection(NO);
            _networkCheckComplection = nil;
        }
    } else { // 网页被重定向到了self.trueUrl，wifi需要认证
        if (_networkCheckComplection) {
            _networkCheckComplection(YES);
            _networkCheckComplection = nil;
        }
        
        if (_needAlert) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"WI-FI认证提醒" message:@"检测到当前WI-FI需要认证才能使用，请尝试去认证网络" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"认证", nil];
            [alert show];
            _needAlert = NO;
        }
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // 认证网络
        CGFloat systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
        if (systemVersion >= 9.0 && systemVersion < 11.0) {
            // iOS11下，SFSafariViewController有些问题，页面会白屏...原因暂时未知，如果你知道求告知~
            SFSafariViewController *safariVc = [[SFSafariViewController alloc] initWithURL:self.trueUrl];
            UIViewController *currentVc = [UIApplication sharedApplication].delegate.window.rootViewController;
            if (currentVc.presentedViewController) {
                [currentVc.presentedViewController presentViewController:safariVc animated:YES completion:nil];
            } else if (currentVc) {
                [currentVc presentViewController:safariVc animated:YES completion:nil];
            }
        } else {
            if ([[UIApplication sharedApplication] canOpenURL:self.trueUrl]) {
                [[UIApplication sharedApplication] openURL:self.trueUrl];
            }
        }
    }
}
#pragma clang diagnostic pop

@end
