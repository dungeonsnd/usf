//
//  AppDelegate.m
//  CurlT
//
//  Created by jeffery on 16/3/9.
//  Copyright © 2016年 jeffery. All rights reserved.
//

#import "AppDelegate.h"

#import "USFHttpTool.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        NSString *url =@"https://raw.githubusercontent.com/curl/curl/master/docs/examples/getinmemory.c";
        
//        NSString *url =@"sohu.com";
        
        NSMutableString *result;
        NSMutableString *out_errstr;
        
        USFHttpTool *ustHttpTool =[[USFHttpTool alloc]init];
        NSInteger res =[ustHttpTool HttpGet:url result:&result out_errstr:&out_errstr];
        NSLog(@"res=%ld",(long)res);
        
        NSLog(@"result=%lu",(unsigned long)[result length]);
        NSLog(@"out_errstr=%@",out_errstr);
    
    });
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
