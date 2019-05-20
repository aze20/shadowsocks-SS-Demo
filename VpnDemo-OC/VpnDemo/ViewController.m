//
//  ViewController.m
//  VpnDemo
//
//  Created by admin on 2018/7/25.
//  Copyright © 2018年 admin. All rights reserved.
//

#import "ViewController.h"
#import "VpnManager.h"
#import <NetworkExtension/NetworkExtension.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *connectButton;

@property (nonatomic) VPNStatus status;

@property (nonatomic, strong)NETunnelProviderManager * manager;

@end

@implementation ViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.status = VPNStatus_off;

    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onVPNStatusChanged)
                                                 name:NEVPNStatusDidChangeNotification
                                               object:nil];
}
#pragma mark - eeeeeeee

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.status = [VpnManager sharedInstance].VPNStatus;
}

- (void)updateBtnStatus{
    switch (self.status) {
        case VPNStatus_connecting:
            [self.connectButton setTitle:@"connecting" forState:UIControlStateNormal];
            break;
            
        case VPNStatus_disconnecting:
            [self.connectButton setTitle:@"disconnect" forState:UIControlStateNormal];
            break;
            
        case VPNStatus_on:
            [self.connectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
            break;
            
        case VPNStatus_off:
            [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
    self.connectButton.enabled = [VpnManager sharedInstance].VPNStatus == VPNStatus_on||[VpnManager sharedInstance].VPNStatus == VPNStatus_off;
}

- (IBAction)touchBtn:(id)sender {
    
    if([VpnManager sharedInstance].VPNStatus == VPNStatus_off){
        [[VpnManager sharedInstance] connect];
    }else{
        [[VpnManager sharedInstance] disconnect];
    }
    
}


#pragma mark - 收到监听通知处理
- (void)onVPNStatusChanged{
    self.status = [VpnManager sharedInstance].VPNStatus;
}

#pragma mark - get/set
- (void)setStatus:(VPNStatus)status{
    _status = status;
    [self updateBtnStatus];
}




@end
