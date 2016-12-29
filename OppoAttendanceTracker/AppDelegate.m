//
//  AppDelegate.m
//  OppoAttendanceTracker
//
//  Created by User1 on 12/20/16.
//
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end







@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    _Base_URL=@"http://ft.allsmart.in";
    
    [GMSServices provideAPIKey:@"AIzaSyBuOTx1LZAltSaWE5ehj0p5XwzvrJeChdU"];
    
    [[UITabBar appearance] setTintColor:[UIColor blackColor]];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"topbar"] forBarMetrics:UIBarMetricsDefault];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    
    [_locationManager startUpdatingLocation];
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate=self;
    _locationManager.desiredAccuracy=kCLLocationAccuracyBest;
    _locationManager.distanceFilter=kCLDistanceFilterNone;
    
#ifdef __IPHONE_8_0
    //  if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8")) {
    // Use one or the other, not both. Depending on what you put in info.plist
    //[self.locationManager requestWhenInUseAuthorization];
    [_locationManager requestAlwaysAuthorization];
    //  }
#endif
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    
   

    NSInteger is_Login=[[defaults valueForKey:@"Is_Login"] integerValue];
    
    if (is_Login == 1) {
//        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//        UITabBarController *rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"HomeRoot"];
//        [[UIApplication sharedApplication].keyWindow setRootViewController:rootViewController];
        
         self.window.rootViewController =[self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"HomeRoot"];
    }else{
        
    }
    
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
