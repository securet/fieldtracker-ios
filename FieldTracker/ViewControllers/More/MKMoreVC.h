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
#import <MessageUI/MessageUI.h>

@interface MKMoreVC : UIViewController<UITableViewDelegate,UITableViewDataSource,CLLocationManagerDelegate,UITextViewDelegate,MultiSelectSegmentedControlDelegate,UITextFieldDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,MFMailComposeViewControllerDelegate,UIAlertViewDelegate>
{
    CLLocationManager *locationManager;
}

@property (strong, nonatomic) IBOutlet UIImageView *imgVwUser;

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

@property (weak, nonatomic) IBOutlet UIImageView *imgVwForLocationIcon;
@property (weak, nonatomic) IBOutlet UILabel *lblForStoreLocation;

#pragma mark - IBOutlets For Add/Edit Store
@property (strong, nonatomic) IBOutlet UILabel *lblForEditStore;
@property (strong, nonatomic) IBOutlet UILabel *lblForLatLon;
@property (strong, nonatomic) IBOutlet UITextField *txtFieldStoreName;
@property (strong, nonatomic) IBOutlet UITextField *txtFieldSiteRadius;
@property (strong, nonatomic) IBOutlet UITextView *txtVwStoreAddress;
@property  (strong, nonatomic) IBOutlet UIButton *btnGetLocation;
@property (strong, nonatomic) IBOutlet UIButton *btnAdd;
@property (strong, nonatomic) IBOutlet UIButton *btnCancel;
@property (strong, nonatomic) IBOutlet UIButton *btnAddPromoterConfirm;
@property (strong, nonatomic) IBOutlet UIButton *btnCancelPromoterAdd;
@property (strong, nonatomic) IBOutlet UIButton *btnForStoreCamera;
@property (strong, nonatomic) IBOutlet UIButton *btnForStoreImage;


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightOfStoreCamera;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightOfTxtVwStoreAddress;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightOfTxtFieldStorName;

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
@property (strong, nonatomic) IBOutlet UIButton *btnForStoreAssignmtPopup;



@property (strong, nonatomic) IBOutlet UIView *vwForImgPreview;
@property (weak, nonatomic) IBOutlet UIButton *btnPhotoConfirm;
@property (weak, nonatomic) IBOutlet UIButton *btnPhotoRetake;

@property (strong, nonatomic) IBOutlet UIImageView *imgVwForPhotoPreview;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightOfImgPrvw;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthOfImgPrvw;



#pragma mark - IBOutlets For Leave Request
@property (strong, nonatomic) IBOutlet UIButton *btnLeaveStartDate;
@property (strong, nonatomic) IBOutlet UIButton *btnLeaveEndDate;
@property (strong, nonatomic) IBOutlet UIButton *btnLeaveType;
@property (strong, nonatomic) IBOutlet UIButton *btnLeaveReason;

@property (strong, nonatomic) IBOutlet UIButton *btnLeaveRqstSubmit;
@property (strong, nonatomic) IBOutlet UIButton *btnLeaveRqstCancel;
@property (strong, nonatomic) IBOutlet UILabel *lblForNoOfDays;
@property (strong, nonatomic) IBOutlet UITextField *txtFieldStartDate;
@property (strong, nonatomic) IBOutlet UITextField *txtFieldEndDate;
@property (strong, nonatomic) IBOutlet UITextField *txtFieldLeaveType;
@property (strong, nonatomic) IBOutlet UITextField *txtFieldLeaveReason;
@property (strong, nonatomic) IBOutlet UITextField *txtFieldLeaveDescription;
@property (strong, nonatomic) IBOutlet UITextField *txtFieldLeaveComments;
@property (strong, nonatomic) IBOutlet UIImageView *bottomImgForLeaveComments;

@property (strong, nonatomic) IBOutlet UIView *vwForCalendar;
@property (strong, nonatomic) IBOutlet UILabel *lblForDateStartEnd;
@property (strong, nonatomic) IBOutlet UIButton *btnToday;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightOfScrollVwForLeaveRqst;
- (IBAction)onClickType:(UIButton *)sender;
- (IBAction)onClickReason:(UIButton *)sender;

#pragma mark - Camera View
@property (strong, nonatomic) IBOutlet UIView *vwForCamera;
@property (strong, nonatomic) IBOutlet UIView *previewCamera;
@property (strong, nonatomic) IBOutlet UIButton *cameraBtn;

#pragma mark - My Account View
@property (strong, nonatomic) IBOutlet UIView *vwForAccount;
@property (strong, nonatomic) IBOutlet UITextField *textFieldMyName;
@property (strong, nonatomic) IBOutlet UITextField *textFieldMyNumber;
@property (strong, nonatomic) IBOutlet UITextField *textFieldMyEmail;
@property (strong, nonatomic) IBOutlet UITextField *textFieldMyStore;
@property (strong, nonatomic) IBOutlet UITextField *textFieldMyManagerName;
@property (strong, nonatomic) IBOutlet UITextField *textFieldMyManagerEmailID;
@property (strong, nonatomic) IBOutlet UITextField *textFieldMyManagerMobileNumber;

@property (strong, nonatomic) IBOutlet UITextView *textVwMyAddress;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightConstraintForMyTextFieldAccount;
- (IBAction)onClickManagerPhoneNumber:(UIButton *)sender;

#pragma mark - Change Password
@property (strong, nonatomic) IBOutlet UIView *vwForChangePwd;
@property (strong, nonatomic) IBOutlet UITextField *textFieldCurrentPwd;
@property (strong, nonatomic) IBOutlet UITextField *textFieldNewPwd;
@property (strong, nonatomic) IBOutlet UITextField *textFieldConfirmNewPwd;
@property (strong, nonatomic) IBOutlet UIButton *btnChangePwd;

#pragma mark - Contact Support
@property (strong, nonatomic) IBOutlet UIView *vwForContact;
@property (strong, nonatomic) IBOutlet UIImageView *imgVwLogoConatact;
@property (strong, nonatomic) IBOutlet UILabel *lblForEmailContact;
@property (strong, nonatomic) IBOutlet UILabel *lblForPhoneContact;
@property (strong, nonatomic) IBOutlet UILabel *lblForOrgNameContact;

#pragma mark - Leave Requisitions ( i.e for approval )
@property (strong, nonatomic) IBOutlet UIView *vwForLeaveRequestForApproval;
@property (strong, nonatomic) IBOutlet UITableView *tableVwForLeaveApproval;

#pragma mark - Reporties
@property (strong, nonatomic) IBOutlet UIView *vwForReporties;
@property (strong, nonatomic) IBOutlet UIView *vwForReportiesHistory;
@property (strong, nonatomic) IBOutlet UIView *vwForReportiesIndividualHistory;
@property (strong, nonatomic) IBOutlet UITableView *tableVwForReporties;
@property (strong, nonatomic) IBOutlet UITableView *tableVwForReportiesHistory;
@property (strong, nonatomic) IBOutlet UITableView *tableVwForIndividualHistory;
@property (strong, nonatomic) IBOutlet UILabel *lblEntryDate;
@property (strong, nonatomic) IBOutlet UILabel *lblTimeIn;
@property (strong, nonatomic) IBOutlet UILabel *lblTimeOut;
@property (strong, nonatomic) IBOutlet UILabel *lblTotalTime;

- (IBAction)onClickToggle:(UIButton *)sender;

- (IBAction)onClickCamera:(UIButton *)sender;

- (IBAction)onClickLeaveStartDate:(UIButton *)sender;
- (IBAction)onClickLeaveEndDate:(UIButton *)sender;

- (IBAction)onClickStorAssignment:(UIButton *)sender;
- (IBAction)onClickSEAssignment:(UIButton *)sender;
@end
