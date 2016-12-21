//
//  MKHomeVC.h
//  OppoAttendanceTracker
//
//  Created by User1 on 12/20/16.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import <CoreLocation/CoreLocation.h>
#import <GoogleMaps/GoogleMaps.h>

@interface MKHomeVC : UIViewController<CLLocationManagerDelegate,GMSMapViewDelegate>
{
    CLLocationManager *locationManager;
}
@property (strong, nonatomic) IBOutlet UIView *bottomVw;

@property (weak, nonatomic) IBOutlet UILabel *lblUserName;
@property (weak, nonatomic) IBOutlet MKMapView *mapVw;
- (IBAction)onClickMyLocation:(UIButton *)sender;
@end
