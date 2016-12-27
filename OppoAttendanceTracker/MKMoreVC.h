//
//  MKMoreVC.h
//  OppoAttendanceTracker
//
//  Created by User1 on 12/20/16.
//
//
  
#import <UIKit/UIKit.h>
#import "MultiSelectSegmentedControl.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVBase.h>
#import <AVFoundation/AVFoundation.h>

@interface MKMoreVC : UIViewController<UITableViewDelegate,UITableViewDataSource,CLLocationManagerDelegate,UITextViewDelegate,MultiSelectSegmentedControlDelegate,UITextFieldDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>
{
    CLLocationManager *locationManager;
}

@property (weak, nonatomic) IBOutlet UILabel *lblFName;
@property (weak, nonatomic) IBOutlet UILabel *lblLName;
@property (strong, nonatomic) IBOutlet UILabel *lblTime;
@property (strong, nonatomic) IBOutlet UILabel *lblAMOrPM;

@property (strong, nonatomic) IBOutlet UITableView *tableVw;
@property (strong, nonatomic) IBOutlet UITableView *tableVwForStore;
@property (strong, nonatomic) IBOutlet UITableView *tableVwForPromoters;
@property (strong, nonatomic) IBOutlet UITableView *tableVwForLeaveRqst;

@property (strong, nonatomic) IBOutlet UIView *vwForStore;
@property (strong, nonatomic) IBOutlet UIView *vwForPromoters;
@property (strong, nonatomic) IBOutlet UIView *vwForLeaveRqst;


@property (strong, nonatomic) IBOutlet UIView *vwForStoreAdd;
@property (strong, nonatomic) IBOutlet UIView *vwForPromoterAdd;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollForPromoterAdd;


@property (strong, nonatomic) IBOutlet UIView *vwForLeaveRqstAdd;

@property (strong, nonatomic) IBOutlet UIButton *backBtn;

@property (strong, nonatomic) IBOutlet UIButton *btnAddStore;
@property (strong, nonatomic) IBOutlet UIButton *btnAddPromoter;
@property (strong, nonatomic) IBOutlet UIButton *btnLeaveRqst;

@property (strong, nonatomic) IBOutlet MultiSelectSegmentedControl *segmentControl;

- (IBAction)onClickBackBtn:(UIButton *)sender;


#pragma mark - IBOutlets For Add/Edit Store

@property (strong, nonatomic) IBOutlet UILabel *lblForEditStore;
@property (strong, nonatomic) IBOutlet UILabel *lblForLatLon;


@property (strong, nonatomic) IBOutlet UITextField *txtFieldStoreName;

@property (strong, nonatomic) IBOutlet UITextView *txtVwStoreAddress;


@property  (strong, nonatomic) IBOutlet UIButton *btnGetLocation;
@property (strong, nonatomic) IBOutlet UIButton *btnAdd;
@property (strong, nonatomic) IBOutlet UIButton *btnCancel;


@property (strong, nonatomic) IBOutlet UIButton *btnAddPromoterConfirm;
@property (strong, nonatomic) IBOutlet UIButton *btnCancelPromoterAdd;


#pragma mark - IBOutlets For Add/Edit Promoters

@property (strong, nonatomic) IBOutlet UITextField *txtFieldFNamePromoter;
@property (strong, nonatomic) IBOutlet UITextField *txtFieldLNamePromoter;
@property (strong, nonatomic) IBOutlet UITextField *txtFieldPhonePromoter;
@property (strong, nonatomic) IBOutlet UITextField *txtFieldEmailPromoter;
@property (strong, nonatomic) IBOutlet UITextField *txtFieldSEAsgnmntPromoter;
@property (strong, nonatomic) IBOutlet UITextField *txtFieldStoreAsgnmntPromoter;

@property (strong, nonatomic) IBOutlet UITextView *txtVwAddressPromoter;

@property (strong, nonatomic) IBOutlet UIButton *btnPhotoPromoter;
@property (strong, nonatomic) IBOutlet UIButton *btnAadharPromoter;
@property (strong, nonatomic) IBOutlet UIButton *btnAdressProofPromoter;




#pragma mark - IBOutlets For Leave Request

@property (strong, nonatomic) IBOutlet UIButton *btnLeaveRqstSubmit;
@property (strong, nonatomic) IBOutlet UIButton *btnLeaveRqstCancel;


@property (strong, nonatomic) IBOutlet UILabel *lblForNoOfDays;

@property (strong, nonatomic) IBOutlet UITextField *txtFieldStartDate;
@property (strong, nonatomic) IBOutlet UITextField *txtFieldEndDate;
@property (strong, nonatomic) IBOutlet UITextField *txtFieldLeaveType;
@property (strong, nonatomic) IBOutlet UITextField *txtFieldLeaveReason;

- (IBAction)onClickLeaveStartDate:(UIButton *)sender;
- (IBAction)onClickLeaveEndDate:(UIButton *)sender;


- (IBAction)onClickStorAssignment:(UIButton *)sender;

- (IBAction)onClickSEAssignment:(UIButton *)sender;
@end
