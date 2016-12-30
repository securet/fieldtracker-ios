//
//  AppDelegate.h
//  OppoAttendanceTracker
//
//  Created by User1 on 12/20/16.
//
//


#import <UIKit/UIKit.h>


#define APPDELEGATE ((AppDelegate*)[[UIApplication sharedApplication] delegate])

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_5 (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 568.0f)
#define IS_IPHONE_6 (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 667.0f)
#define IS_IPHONE_6P (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 736.0f)
#define IS_IPHONE_4 (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height < 568.0f)

#define TopColor [UIColor colorWithRed:(84/255.0) green:(138/255.0) blue:(176/255.0) alpha:1.0]

@import GoogleMaps;
@interface AppDelegate : UIResponder <UIApplicationDelegate,CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property  CLLocationManager *locationManager;


@property NSString *Base_URL;

+(AppDelegate *)sharedAppDelegate;
- (BOOL)connected;


@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory; // nice to have to reference files for core data




@end

