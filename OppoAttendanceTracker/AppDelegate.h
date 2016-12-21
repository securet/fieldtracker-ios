//
//  AppDelegate.h
//  OppoAttendanceTracker
//
//  Created by User1 on 12/20/16.
//
//

#import <UIKit/UIKit.h>
@import GoogleMaps;
@interface AppDelegate : UIResponder <UIApplicationDelegate,CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property  CLLocationManager *locationManager;

@end

