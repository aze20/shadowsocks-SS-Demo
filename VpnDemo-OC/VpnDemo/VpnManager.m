//
//  VpnManager.m
//  VpnDemo
//
//  Created by admin on 2018/7/26.
//  Copyright © 2018年 admin. All rights reserved.
//

#import "VpnManager.h"
#import <NetworkExtension/NetworkExtension.h>

@interface VpnManager()

@property (nonatomic, assign) BOOL observerAdded;

@end

@implementation VpnManager

#pragma mark - set/get
- (void)setVPNStatus:(VPNStatus)VPNStatus{
    _VPNStatus = VPNStatus;
    if (VPNStatus == VPNStatus_off) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kProxyServiceVPNStatusNotification" object:nil];
    }
//    else {
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"kProxyServiceVPNStatusNotification" object:nil];
//    }
}

+ (instancetype)sharedInstance{
    static VpnManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[VpnManager alloc] init];
    });
    return manager;
}

- (instancetype)init{
    if (self = [super init]) {
        __weak typeof(self) weakself = self;
        [self loadProviderManager:^(NETunnelProviderManager *manager) {
            
            [weakself updateVPNStatus:manager];
        }];
        
        [self addVPNStatusObserver];
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - exposed method
- (void)connect{
    
    [self loadAndCreatePrividerManager:^(NETunnelProviderManager *manager) {
        if (!manager) {
            return ;
        }
        NSError *error;
        [manager.connection startVPNTunnelWithOptions:@{} andReturnError:&error];
        if (error) {
            NSLog(@"start error");
        }else{
            NSLog(@"rsssss");
        }
    }];
    
}





- (void)disconnect{
    [self loadProviderManager:^(NETunnelProviderManager *manager) {
        [manager.connection stopVPNTunnel];
    }];
}

#pragma mark - private method

- (void)loadProviderManager:(void(^)(NETunnelProviderManager *manager))pm{
    
    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
        if (managers.count > 0) {
            pm(managers.firstObject);
            return ;
        }
        return pm(nil);
    }];
}

- (NETunnelProviderManager *)createProviderManager{
    
    NETunnelProviderManager *manager = [[NETunnelProviderManager alloc] init];
    NETunnelProviderProtocol *conf = [[NETunnelProviderProtocol alloc] init];
    conf.serverAddress = @"name";
    manager.protocolConfiguration = conf;
    manager.localizedDescription = @"mine";
    return manager;
}

- (void)loadAndCreatePrividerManager:(void(^)(NETunnelProviderManager *manager))compelte{
    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
        NETunnelProviderManager *manager = [[NETunnelProviderManager alloc] init];
        if (managers.count>0) {
            manager = managers.firstObject;
            if (managers.count>1) {
                for (NETunnelProviderManager* manager in managers) {
                    [manager removeFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                        if (error == nil) {
                            NSLog(@"remove dumplicate VPN config successful!");
                        }else{
                            NSLog(@"remove dumplicate VPN config failed with %@", error);
                        }
                    }];
                }
            }
        }else{
            manager = [self createProviderManager];
        }
        manager.enabled = YES;
        
        //set rule config
        NSMutableDictionary *conf = @{}.mutableCopy;
        /*        encryption = "aes-256-cfb";
         hashType = 2;
         id = 1;
         ip = "103.56.55.98";
         name = "cy-ss";
         obfs = tls;
         pac = 1;
         passWord = 159357;
         port = 17165;
         protocol = "<null>";
         status = 1;
         {"id":"1","ip":"103.56.55.98","port":"17165","userName":"null","passWord":"159357","hashType":"2","pac":"1","name":"cy-ss","status":"1","protocol":null,"obfs":"tls","encryption":"aes-256-cfb"}}
         userName = null;*/
#warning - need conf
        conf[@"ss_address"] = @"103.56.55.98";
        conf[@"ss_port"] = @18044;         //  number
        conf[@"ss_method"] = @"AES256CFB"; //  nopo'-' 看Extension中的枚举类设定 否则引发fatal error
        conf[@"ss_password"] = @"159357";
        conf[@"ymal_conf"] = [self getRuleConf];
        
        NETunnelProviderProtocol *orignConf = (NETunnelProviderProtocol *)manager.protocolConfiguration;
        orignConf.providerConfiguration = conf;
        manager.protocolConfiguration = orignConf;
        
        //save vpn
        [manager saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
            if (error == nil) {
                //注意这里保存配置成功后，一定要再次load，否则会导致后面StartVPN出异常
                [manager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                    if (error == nil) {
                        NSLog(@"save vpn success");
                        compelte(manager);return;
                    }
                    compelte(nil);return;
                }];
            }else{
                compelte(nil);return;
            }
        }];
    }];
}

- (NSString *)getRuleConf{
    NSString * Path = [[NSBundle mainBundle] pathForResource:@"NEKitRule" ofType:@"conf"];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:Path]];
    
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}


#pragma mark - tool

- (void)updateVPNStatus:(NEVPNManager *)manager{
    switch (manager.connection.status) {
        case NEVPNStatusConnected:
            self.VPNStatus = VPNStatus_on;
            break;
        case NEVPNStatusConnecting:
            self.VPNStatus = VPNStatus_connecting;
            break;
        case NEVPNStatusReasserting:
            self.VPNStatus = VPNStatus_connecting;
            break;
        case NEVPNStatusDisconnecting:
            self.VPNStatus = VPNStatus_disconnecting;
            break;
        case NEVPNStatusDisconnected:
            self.VPNStatus = VPNStatus_off;
            break;
        case NEVPNStatusInvalid:
            self.VPNStatus = VPNStatus_off;
            break;
        default:
            break;
    }
}

- (void)addVPNStatusObserver{
    if (self.observerAdded) {
        return;
    }

    [self loadProviderManager:^(NETunnelProviderManager *manager) {
        if (manager) {
            self.observerAdded = true;
            [[NSNotificationCenter defaultCenter] addObserverForName:NEVPNStatusDidChangeNotification
                                                              object:manager.connection
                                                               queue:[NSOperationQueue mainQueue]
                                                          usingBlock:^(NSNotification * _Nonnull note) {
                                                              [self updateVPNStatus:manager];
                                                          }];
        }
    }];
}

@end
