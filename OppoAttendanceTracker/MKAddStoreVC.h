//
//  MKAddStoreVC.h
//  OppoAttendanceTracker
//
//  Created by User1 on 12/22/16.
//
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface MKAddStoreVC : UIViewController<CLLocationManagerDelegate>
{
    CLLocationManager *locationManager;
}

@property (strong, nonatomic) IBOutlet UILabel *lblForEditStore;
@property (strong, nonatomic) IBOutlet UILabel *lblForLatLon;


@property (strong, nonatomic) IBOutlet UITextField *txtFieldStoreName;

@property (strong, nonatomic) IBOutlet UITextView *txtVwStoreAddress;


@property  (strong, nonatomic) IBOutlet UIButton *btnGetLocation;
@property (strong, nonatomic) IBOutlet UIButton *btnAdd;
@property (strong, nonatomic) IBOutlet UIButton *btnCancel;




@end
