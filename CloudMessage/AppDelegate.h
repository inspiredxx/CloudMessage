//
//  AppDelegate.h
//  CloudMessage
//
//  Created by SoftwareLab on 13-7-6.
//  Copyright (c) 2013年 SoftwareLab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MosquittoClient.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>
{
    MosquittoClient *mosquittoClient;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UITabBarController *tabBarController;
@property (readonly) MosquittoClient *mosquittoClient;

@end
