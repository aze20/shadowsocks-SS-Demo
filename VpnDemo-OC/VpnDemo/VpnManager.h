//
//  VpnManager.h
//  VpnDemo
//
//  Created by admin on 2018/7/26.
//  Copyright © 2018年 admin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, VPNStatus){
    VPNStatus_off,
    VPNStatus_connecting,
    VPNStatus_on,
    VPNStatus_disconnecting,
};

@interface VpnManager : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic) VPNStatus VPNStatus;

- (void)connect;
- (void)disconnect;

@end
