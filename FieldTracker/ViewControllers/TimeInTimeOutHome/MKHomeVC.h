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

@interface MKHomeVC : UIViewController<CLLocationManagerDelegate,GMSMapViewDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,UIAlertViewDelegate,UITableViewDelegate,UITableViewDataSource>
{
    CLLocationManager *locationManager;
}

@property (strong, nonatomic) IBOutlet UIImageView *imgVwUser;

@property (strong, nonatomic) IBOutlet UIView *bottomVw;

@property (weak, nonatomic) IBOutlet UILabel *lblFName;
@property (weak, nonatomic) IBOutlet UILabel *lblLName;
@property (strong, nonatomic) IBOutlet UILabel *lblTime;
@property (strong, nonatomic) IBOutlet UILabel *lblAMOrPM;

@property (strong, nonatomic) IBOutlet UILabel *lblStoreName;
@property (weak, nonatomic) IBOutlet MKMapView *mapVw;

@property (strong, nonatomic) IBOutlet UIView *vwForImgPreview;
@property (weak, nonatomic) IBOutlet UIButton *btnPhotoConfirm;
@property (weak, nonatomic) IBOutlet UIButton *btnPhotoRetake;

@property (strong, nonatomic) IBOutlet UIImageView *imgVwForPhotoPreview;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightOfImgPrvw;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthOfImgPrvw;

@property (weak, nonatomic) IBOutlet UIImageView *imgVwForLocationIcon;
@property (weak, nonatomic) IBOutlet UILabel *lblForStoreLocation;

@property (strong, nonatomic) IBOutlet UILabel *lblTimeInStatus;

@property (strong, nonatomic) IBOutlet UIView *vwForTimer;
@property (strong, nonatomic) IBOutlet UITableView *tableVwForTimeline;
@property (strong, nonatomic) IBOutlet UILabel *lblForTimer;

@property (weak, nonatomic) IBOutlet UIImageView *imgVwForTimeline;

@property (strong, nonatomic) IBOutlet UIView *vwForCamera;
@property (strong, nonatomic) IBOutlet UIView *previewCamera;
@property (strong, nonatomic) IBOutlet UIButton *backBtn;
@property (strong, nonatomic) IBOutlet UIButton *cameraBtn;

#pragma mark - ViewForManager
@property (strong, nonatomic) IBOutlet UIView *vwForManager;
@property (strong, nonatomic) IBOutlet UITableView *tableVwForAgents;

@property (strong, nonatomic) IBOutlet UIView *vwForAgentData;
@property (strong, nonatomic) IBOutlet UITableView *tableVwForHistoryOfAgent;

@property (strong, nonatomic) IBOutlet UIView *vwForAgentIndividualData;
@property (strong, nonatomic) IBOutlet UITableView *tableVwIndividualHistory;


- (IBAction)onClickCamera:(UIButton *)sender;
- (IBAction)onClickBackBtn:(UIButton *)sender;


- (IBAction)onClickMyLocation:(UIButton *)sender;
- (IBAction)onClickTimeIn:(UIButton *)sender;
- (IBAction)onClickPhotoConfirmBtn:(UIButton *)sender;
- (IBAction)onClickRetakePhotoBtn:(UIButton *)sender;

@property NSEntityDescription *timeLineStatusEntity;
@property NSEntityDescription *timeLineDataEntity;
- (IBAction)onClickTimeline:(UIButton *)sender;

@end