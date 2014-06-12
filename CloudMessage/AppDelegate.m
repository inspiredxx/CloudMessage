//
//  AppDelegate.m
//  CloudMessage
//
//  Created by SoftwareLab on 13-7-6.
//  Copyright (c) 2013年 SoftwareLab. All rights reserved.
//

#import "AppDelegate.h"

#import "LoginViewController.h"
#import "MyMessage.h"
#import "MySubscription.h"
#import "SubscriptionList.h"
#import "Setup.h"
#import "getMacAddress.h"

@implementation AppDelegate

@synthesize mosquittoClient;

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    
    //mqtt初始化
    NSString *clientId = [NSString stringWithFormat:@"marquette_%@", getMacAddress()];
//    NSString *clientId = [NSString stringWithFormat:@"inspiredxx"];
	NSLog(@"Client ID: %@", clientId);
    mosquittoClient = [[MosquittoClient alloc] initWithClientId:clientId];
    
    MyMessage *myMessage = [[[MyMessage alloc] initWithNibName:@"MyMessage" bundle:nil] autorelease];
    MySubscription *mySubscription = [[[MySubscription alloc] initWithNibName:@"MySubscription" bundle:nil] autorelease];
    SubscriptionList *subscriptionList = [[[SubscriptionList alloc] initWithNibName:@"SubscriptionList" bundle:nil] autorelease];
    Setup *setup = [[[Setup alloc] initWithNibName:@"Setup" bundle:nil] autorelease];
    myMessage.title = @"最新资讯";
    mySubscription.title = @"我的订阅";
    subscriptionList.title = @"订阅列表";
    setup.title = @"设置";
    UINavigationController *navc1 = [[[UINavigationController alloc] initWithRootViewController:myMessage] autorelease];
    UINavigationController *navc2 = [[[UINavigationController alloc] initWithRootViewController:mySubscription] autorelease];
    UINavigationController *navc3 = [[[UINavigationController alloc] initWithRootViewController:subscriptionList] autorelease];
    UINavigationController *navc4 = [[[UINavigationController alloc] initWithRootViewController:setup] autorelease];
    
//    navc1.navigationBar.barStyle = UIBarStyleBlackTranslucent;
//    navc2.navigationBar.barStyle = UIBarStyleBlackTranslucent;
//    navc3.navigationBar.barStyle = UIBarStyleBlackTranslucent;
//    navc4.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    
    self.tabBarController = [[[UITabBarController alloc] init] autorelease];
    self.tabBarController.viewControllers = [NSArray arrayWithObjects:navc1, navc2, navc3, navc4, nil];
    
    [mosquittoClient setDelegate:myMessage];
    
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
}
*/

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
}
*/

@end
