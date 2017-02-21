//
//  MKMoreVC.m
//  OppoAttendanceTracker
//
//  Created by User1 on 12/20/16.
//
//

#import "MKMoreVC.h"
#import "MKCustomCellForLeave.h"
#import <AVFoundation/AVFoundation.h>


@interface MKMoreVC ()<RSDFDatePickerViewDelegate,RSDFDatePickerViewDataSource>
{
    NSMutableArray *arrayForTableData;
    NSMutableArray *arrayForStoreList;
    NSMutableArray *arrayForPromoters;
    NSMutableArray *arrayForLeaveHistory;
    NSMutableArray *arrayForLeaveApprovalList;
    NSMutableArray *arrayForReportee;
    NSMutableArray *arrayForReporteeHistory;
    NSMutableArray *arrayForReporteeStatusData;
    
    NSInteger countForReporteeHistory;
    
    NSString *strForReporteeUserName;
    
    NSInteger countForLeaveData,pageNumberForLeave,indexValueForLeaveEdit,leaveApprovalListCount,pageNumberForLeaveApproval;
    BOOL isLeaveEditRNew;
    NSDictionary *dictForLeaveTypes;
    
    NSString *strForCurLatitude,*strForCurLongitude;
    
    BOOL isStartOrEndDate;
    
    NSInteger indexValueOfPromoterEdit;
    
    UIImage *imgToSend;
    
    NSString *stringForImagePurpose;
    
    NSString *strUserPhotoPath;
    NSString *strAadharIDPath;
    NSString *strAddressProofPath;
    NSString *storeIDForPromoterAdd;
    
    NSInteger arrayCountToCheck;
    NSInteger pageNumber;
    
    AVCaptureSession *captureSession;
    AVCaptureVideoPreviewLayer *videoPreviewLayer;
    AVCaptureStillImageOutput *stillImageOutput;
    
    NSString *leaveTypeEnumID,*leaveReasonEnumID;
    
    __weak IBOutlet RSDFDatePickerView *datePicker;
    
    NSString *roleType;
    
    BOOL isPromoterOrPromoterApprove;
}
@end

@implementation MKMoreVC
#pragma mark - View
- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSMutableDictionary *dict=[[defaults objectForKey:@"UserData"] mutableCopy];
    NSLog(@"%@",dict);
    
    roleType=[dict valueForKey:@"roleTypeId"];
    
    self.lblFName.text=[dict valueForKey:@"firstName"];
    self.lblLName.text=[dict valueForKey:@"lastName"];
    
    if (![roleType isEqualToString:@"FieldExecutiveOnPremise"] && ![roleType isEqualToString:@"FieldExecutiveOffPremise"]) {
        arrayForTableData=[[NSMutableArray alloc] initWithObjects:@"Stores",@"Promoters",@"Promoters Approval",@"Leaves",@"Leave Requisitions",@"Reporties",@"Contact Support",@"My Account",@"Change Password",@"Log Off", nil];
        [self getStores];
    }else{
        arrayForTableData=[[NSMutableArray alloc] initWithObjects:@"Leaves",@"Contact Support",@"My Account",@"Change Password",@"Log Off", nil];
    }
    
    arrayForStoreList=[[NSMutableArray alloc] init];
    arrayForPromoters=[[NSMutableArray alloc] init];
    arrayForLeaveHistory = [[NSMutableArray alloc] init];
    arrayForLeaveApprovalList=[[NSMutableArray alloc] init];
    
    pageNumberForLeave = 0;
    countForLeaveData = 0;
    
    leaveApprovalListCount=0;
    pageNumberForLeaveApproval=0;
    
    self.tableVw.delegate = self;
    self.tableVw.dataSource = self;
    self.tableVw.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.tableVw.tableFooterView=[[UIView alloc] init];
    self.tableVwForStore.tableFooterView =[[UIView alloc] init];
    self.tableVwForPromoters.tableFooterView =[[UIView alloc] init];
    self.tableVwForLeaveRqst.tableFooterView=[[UIView alloc] init];
    self.tableVwForLeaveApproval.tableFooterView=[[UIView alloc] init];
    self.tableVwForReporties.tableFooterView=[[UIView alloc] init];
    self.tableVwForReportiesHistory.tableFooterView=[[UIView alloc] init];
    self.tableVwForIndividualHistory.tableFooterView=[[UIView alloc] init];
    
    
    self.vwForPromoters.hidden = YES;
    self.vwForStore.hidden = YES;
    self.vwForLeaveRqst.hidden= YES;
    
    self.backBtn.hidden = YES;
    
    [self.btnAddStore addTarget:self action:@selector(onClickAddStore:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnAddPromoter addTarget:self action:@selector(onClickAddPromoter) forControlEvents:UIControlEventTouchUpInside];
    [self.btnLeaveRqst addTarget:self action:@selector(onClickLeaveRqst:) forControlEvents:UIControlEventTouchUpInside];
    
    self.vwForStoreAdd.hidden = YES;
    self.vwForPromoterAdd.hidden = YES;
    self.vwForLeaveRqstAdd.hidden = YES;
    self.vwForCamera.hidden = YES;
    self.vwForAccount.hidden = YES;
    self.vwForChangePwd.hidden = YES;
    self.vwForContact.hidden = YES;
    self.vwForCalendar.hidden = YES;
    self.vwForLeaveRequestForApproval.hidden = YES;
    self.vwForReporties.hidden = YES;
    self.vwForReportiesHistory.hidden = YES;
    self.vwForReportiesIndividualHistory.hidden = YES;
    
    self.cameraBtn.backgroundColor=[[UIColor lightGrayColor] colorWithAlphaComponent:0.4];
    self.cameraBtn.layer.cornerRadius = self.cameraBtn.frame.size.height/2;
    self.cameraBtn.layer.masksToBounds = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storeSelected) name:@"SelectedStore" object:nil];
    
    
    
    pageNumber=0;
    //rgb(84,138,176)
    //    UIColor *color=[UIColor colorWithRed:(84/255.0) green:(138/255.0) blue:(176/255.0) alpha:1.0];
    
    [self.tableVwForPromoters addFooterWithTarget:self action:@selector(refreshFooter) withIndicatorColor:TopColor];
    [self.tableVwForLeaveRqst addFooterWithTarget:self action:@selector(refreshFooterForLeave) withIndicatorColor:TopColor];
    [self.tableVwForReportiesHistory addFooterWithTarget:self action:@selector(refreshFooterForReportees) withIndicatorColor:TopColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkingInLocation:) name:@"LocationChecking" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(leaveTypeSelected:) name:@"LeaveTypeSelected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(leaveReasonSelected:) name:@"LeaveReasonSelected" object:nil];
    
    [self setupUIForAllViews];
}

-(void)viewWillAppear:(BOOL)animated{
    
    self.lblForStoreLocation.text=@"";
    [self changeLocationStatus:[[MKSharedClass shareManager] dictForCheckInLoctn]];
    [self disableMyAccountEdit];
    
    [self updateLocationManagerr];
    self.navigationController.navigationBarHidden = YES;
    self.navigationItem.hidesBackButton = YES;
    [self.navigationItem setHidesBackButton:YES];
    
    NSDate *now = [NSDate date];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"hh:mm a";
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    //NSLog(@"The Current Time is %@",[dateFormatter stringFromDate:now]);
    
    self.lblTime.text=[[dateFormatter stringFromDate:now] substringToIndex:[[dateFormatter stringFromDate:now] length]-3];
    self.lblAMOrPM.text=[[dateFormatter stringFromDate:now] substringFromIndex:[[dateFormatter stringFromDate:now] length]-2];
    
    if (![APPDELEGATE connected]) {
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"It appears you are not connected to internet" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
    if ([CLLocationManager locationServicesEnabled]) {
        
    }else{
        [[[UIAlertView alloc] initWithTitle:@""
                                    message:@"Please Enable GPS"
                                   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
    }
}

#pragma mark - ---
- (IBAction)onClickManagerPhoneNumber:(UIButton *)sender {
    
}

-(void)disableMyAccountEdit{
    
    /* if (ISself.IPHONEself.4) {
     self.heightConstraintForMyTextFieldAccount.constant = 30;
     self.textFieldMyName.font = [UIFont systemFontOfSize:15];
     self.textFieldMyNumber.font = [UIFont systemFontOfSize:15];
     self.textFieldMyEmail.font = [UIFont systemFontOfSize:15];
     self.textFieldMyStore.font = [UIFont systemFontOfSize:15];
     self.textVwMyAddress.font = [UIFont systemFontOfSize:15];
     self.textFieldMyManagerName.font = [UIFont systemFontOfSize:15];
     self.textFieldMyManagerEmailID.font = [UIFont systemFontOfSize:15];
     self.textFieldMyManagerMobileNumber.font = [UIFont systemFontOfSize:15];
     }*/
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSMutableDictionary *dict=[[defaults objectForKey:@"UserData"] mutableCopy];
    
    NSLog(@"User Data==========%@",dict);
    
    // [defaults setObject:dictForStoreDetails forKey:@"StoreData"];
    //storeName
    
    self.textFieldMyName.text=[NSString stringWithFormat:@"%@ %@",self.lblFName.text,self.lblLName.text];
    self.textFieldMyNumber.text = @"Mobile Number";
    self.textFieldMyEmail.text = [dict valueForKey:@"emailAddress"];
    self.textFieldMyStore.text = [[defaults objectForKey:@"StoreData"] valueForKey:@"storeName"];
    //StoreData
    
   
    
    if ([dict valueForKey:@"directions"]) {
        self.textVwMyAddress.text=[dict valueForKey:@"directions"];
    }else{
        self.textVwMyAddress.text=@"Address";
    }
    
    if ([dict valueForKey:@"contactNumber"]) {
        self.textFieldMyNumber.text = [dict valueForKey:@"contactNumber"];
    }
    
    if ([dict valueForKey:@"userPhotoPath"]) {
        NSString *str = [NSString stringWithFormat:@"http://ft.allsmart.in/uploads/uid/%@",[dict valueForKey:@"userPhotoPath"]];
        NSString *strSub = [str stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
        NSURL *imgUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@",strSub]];
        dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
        dispatch_async(q, ^{
            /* Fetch the image from the server... */
            NSData *data = [NSData dataWithContentsOfURL:imgUrl];
            UIImage *img = [[UIImage alloc] initWithData:data];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imgVwUser.image = img;
            });
        });
    }
    
    self.textFieldMyName.userInteractionEnabled = NO;
    self.textFieldMyNumber.userInteractionEnabled = NO;
    self.textFieldMyEmail.userInteractionEnabled = NO;
    self.textFieldMyStore.userInteractionEnabled = NO;
    self.textVwMyAddress.userInteractionEnabled = NO;
    self.textFieldMyManagerName.userInteractionEnabled = NO;
    self.textFieldMyManagerEmailID.userInteractionEnabled = NO;
    self.textFieldMyManagerMobileNumber.userInteractionEnabled = NO;
    
    
    if ([dict objectForKey:@"reportingPerson"]) {
        
        if ([[dict objectForKey:@"reportingPerson"] valueForKey:@"emailAddress"] && ![[[dict objectForKey:@"reportingPerson"] valueForKey:@"emailAddress"] isKindOfClass:[NSNull class]]) {
            self.textFieldMyManagerEmailID.text = [[dict objectForKey:@"reportingPerson"] valueForKey:@"emailAddress"];
        }
        
        if ([[dict objectForKey:@"reportingPerson"] valueForKey:@"contactNumber"]&& ![[[dict objectForKey:@"reportingPerson"] valueForKey:@"contactNumber"] isKindOfClass:[NSNull class]]) {
            self.textFieldMyManagerMobileNumber.text = [[dict objectForKey:@"reportingPerson"] valueForKey:@"contactNumber"];
        }
        
        
        NSString *firstName=[[dict objectForKey:@"reportingPerson"] valueForKey:@"firstName"];
        NSString *lastName=[[dict objectForKey:@"reportingPerson"] valueForKey:@"lastName"];
        
        
        self.textFieldMyManagerName.text=[NSString stringWithFormat:@"%@ %@",firstName,lastName];
        self.textFieldMyManagerName.userInteractionEnabled = NO;
        self.textFieldMyManagerEmailID.userInteractionEnabled = NO;
        self.textFieldMyManagerMobileNumber.userInteractionEnabled = NO;
    }
}

-(void)setupUIForAllViews{
    // For Store View
    
    if (IS_IPHONE_4) {
        self.heightOfTxtVwStoreAddress.constant = 50;
        self.txtVwStoreAddress.font = [UIFont systemFontOfSize:12];
    }else{
        self.heightOfTxtFieldStorName.constant = 40;
    }
    
    [self textFieldEdit:self.txtFieldStoreName];
    [self textFieldEdit:self.txtFieldSiteRadius];
    
    self.txtFieldSiteRadius.keyboardType = UIKeyboardTypeNumberPad;
    
    self.txtVwStoreAddress.layer.cornerRadius = 5;
    self.txtVwStoreAddress.layer.masksToBounds = YES;
    self.txtVwStoreAddress.keyboardType=UIKeyboardTypeASCIICapable;
    self.txtVwStoreAddress.backgroundColor =[[UIColor lightGrayColor] colorWithAlphaComponent:0.7];
    
    self.txtVwStoreAddress.autocorrectionType = UITextAutocorrectionTypeNo;
    
    self.btnGetLocation.layer.cornerRadius = 5;
    self.btnGetLocation.layer.masksToBounds = YES;
    
    [self addShadow:self.btnAdd];
    [self addShadow:self.btnCancel];
    
    [self.btnAdd addTarget:self action:@selector(onClickStoreAddToServer:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnCancel addTarget:self action:@selector(onClickCancel) forControlEvents:UIControlEventTouchUpInside];
    [self.btnGetLocation addTarget:self action:@selector(getLocation) forControlEvents:UIControlEventTouchUpInside];
    
    //For Promoter View
    [self addPromoterViewSetup];
    [self addShadow:self.btnAddStore];
    [self addShadow:self.btnAddPromoter];
    [self addShadow:self.btnLeaveRqst];
    
    //For Change Password
    [self textFieldEdit:self.textFieldCurrentPwd];
    [self textFieldEdit:self.textFieldNewPwd];
    [self textFieldEdit:self.textFieldConfirmNewPwd];
    [self addShadow:self.btnChangePwd];
    
    [self.btnChangePwd addTarget:self action:@selector(onClickChangePwd) forControlEvents:UIControlEventTouchUpInside];
    
    self.btnChangePwd.layer.cornerRadius = 5;
    self.btnChangePwd.layer.masksToBounds = YES;
    
    //Contact Support
    
    UITapGestureRecognizer *tapGestureRecognizerForOrgName = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(orgNameTapped)];
    tapGestureRecognizerForOrgName.numberOfTapsRequired = 1;
    [self.lblForOrgNameContact addGestureRecognizer:tapGestureRecognizerForOrgName];
    self.lblForOrgNameContact.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(emailIDTapped)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    [self.lblForEmailContact addGestureRecognizer:tapGestureRecognizer];
    self.lblForEmailContact.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tapGestureRecognizerForNum = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(phoneNumTapped)];
    tapGestureRecognizerForNum.numberOfTapsRequired = 1;
    [self.lblForPhoneContact addGestureRecognizer:tapGestureRecognizerForNum];
    self.lblForPhoneContact.userInteractionEnabled = YES;
    
    [self setupContactSupport];
    
    ///Leave Request Calendar
    
    datePicker.delegate = self;
    datePicker.dataSource = self;
    
    self.heightOfScrollVwForLeaveRqst.constant = 330;
    
    [self textFieldEdit:self.txtFieldStartDate];
    [self textFieldEdit:self.txtFieldEndDate];
    [self textFieldEdit:self.txtFieldLeaveType];
    [self textFieldEdit:self.txtFieldLeaveReason];
    
    self.txtFieldStartDate.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.3];
    self.txtFieldEndDate.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.3];
    self.txtFieldLeaveType.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.3];
    self.txtFieldLeaveReason.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.3];
    
    [self addShadow:self.btnLeaveRqstCancel];
    [self addShadow:self.btnLeaveRqstSubmit];
    
    self.txtFieldLeaveDescription.backgroundColor=[UIColor clearColor];
    self.txtFieldLeaveDescription.delegate = self;
    self.txtFieldLeaveDescription.keyboardType=UIKeyboardTypeASCIICapable;
    
    [self.txtFieldLeaveDescription addTarget:self action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    
    self.txtFieldLeaveComments.backgroundColor=[UIColor clearColor];
    self.txtFieldLeaveComments.delegate = self;
    self.txtFieldLeaveComments.keyboardType=UIKeyboardTypeASCIICapable;
    
    [self.txtFieldLeaveComments addTarget:self action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    
    
    [self.btnLeaveRqstCancel addTarget:self action:@selector(leaveRqstCancel:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnLeaveRqstSubmit addTarget:self action:@selector(leaveRequestSubmit:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnToday addTarget:self action:@selector(onClickToday) forControlEvents:UIControlEventTouchUpInside];
}
-(void)setupContactSupport{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Email:  "
                                                                             attributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone),NSForegroundColorAttributeName: [UIColor blackColor]}]];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:self.lblForEmailContact.text
                                                                             attributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                                                                                          NSBackgroundColorAttributeName: [UIColor clearColor]}]];
    //    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"tring"]];
    self.lblForEmailContact.attributedText = attributedString;
    
    NSMutableAttributedString *attributedStringForNumber = [[NSMutableAttributedString alloc] init];
    [attributedStringForNumber appendAttributedString:[[NSAttributedString alloc] initWithString:@"Phone:  "
                                                                                      attributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone),NSForegroundColorAttributeName: [UIColor blackColor]}]];
    
    [attributedStringForNumber appendAttributedString:[[NSAttributedString alloc] initWithString:self.lblForPhoneContact.text
                                                                                      attributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                                                                                                   NSBackgroundColorAttributeName: [UIColor clearColor]}]];
    //    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"tring"]];
    self.lblForPhoneContact.attributedText = attributedStringForNumber;
}

#pragma mark - NSNotifications


-(void)leaveTypeSelected:(NSNotification*)userInfo{
    self.txtFieldLeaveType.text=[userInfo.userInfo valueForKey:@"description"];
    NSLog(@"%@",userInfo.userInfo);
    leaveTypeEnumID=[userInfo.userInfo valueForKey:@"enumId"];
}

-(void)leaveReasonSelected:(NSNotification*)userInfo{
    self.txtFieldLeaveReason.text=[userInfo.userInfo valueForKey:@"description"];
    NSLog(@"%@",userInfo.userInfo);
    leaveReasonEnumID=[userInfo.userInfo valueForKey:@"enumId"];
}

#pragma mark - Change Password

-(void)onClickChangePwd
{
    [self.view endEditing:YES];
    
    if ([APPDELEGATE connected]) {
        
        if (self.textFieldCurrentPwd.text.length > 0 && self.textFieldNewPwd.text.length>0 && self.textFieldConfirmNewPwd.text.length>0) {
            
            if ([self.textFieldNewPwd.text isEqualToString:self.textFieldConfirmNewPwd.text]) {
                NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
                NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
                
                AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
                httpClient.parameterEncoding = AFFormURLParameterEncoding;
                [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
                
                NSString *str=[defaults valueForKey:@"BasicAuth"];
                
                [httpClient setDefaultHeader:@"Authorization" value:str];
                //{"oldPassword":"test@123","newPassword":"test@1234","newPasswordVerify":"test@1234"}
                NSDictionary * json = @{@"oldPassword":self.textFieldCurrentPwd.text,
                                        @"newPassword":self.textFieldNewPwd.text,
                                        @"newPasswordVerify":self.textFieldConfirmNewPwd.text,
                                        };
                NSMutableURLRequest *request;
                
                request = [httpClient requestWithMethod:@"PUT"
                                                   path:@"/rest/s1/ft/user/changePassword"
                                             parameters:json];
                
                //====================================================RESPONSE
                [DejalBezelActivityView activityViewForView:self.view];
                
                AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
                [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
                    
                }];
                [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                    NSError *error = nil;
                    NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
                    [DejalBezelActivityView removeView];
                    NSLog(@"Password was changed Successfully==%@",JSON);
                    
                    [[[UIAlertView alloc] initWithTitle:@"Password updated successfully !"
                                                message:@""
                                               delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                    NSMutableDictionary *dict=[[defaults objectForKey:@"UserData"] mutableCopy];
                    NSLog(@"User Name===%@",[dict valueForKey:@"username"]);
                    NSString *userName=[dict valueForKey:@"username"];
                    
                    NSString *str=[NSString stringWithFormat:@"%@:%@",userName,self.textFieldNewPwd.text];
                    NSString *auth_String;
                    NSData *nsdata = [str dataUsingEncoding:NSUTF8StringEncoding];
                    NSString *base64Encoded = [nsdata base64EncodedStringWithOptions:0];
                    auth_String=[NSString stringWithFormat:@"Basic %@",base64Encoded];
                    [defaults setObject:auth_String forKey:@"BasicAuth"];
                    
                    self.vwForChangePwd.hidden=YES;
                    self.textFieldCurrentPwd.text=@"";
                    self.textFieldNewPwd.text=@"";
                    self.textFieldConfirmNewPwd.text=@"";
                }
                 //==================================================ERROR
                                                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                     [DejalBezelActivityView removeView];
                                                     NSError *jsonError;
                                                     NSData *objectData = [[[error userInfo] objectForKey:NSLocalizedRecoverySuggestionErrorKey] dataUsingEncoding:NSUTF8StringEncoding];
                                                     NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                                                                          options:NSJSONReadingMutableContainers
                                                                                                            error:&jsonError];
                                                     
                                                     NSString *strError=[json valueForKey:@"errors"];
                                                     [[[UIAlertView alloc] initWithTitle:@""
                                                                                 message:strError
                                                                                delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                                                 }];
                [operation start];
                
            }else{
                [[[UIAlertView alloc] initWithTitle:@"Password was doesn't match"
                                            message:@""
                                           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                self.textFieldConfirmNewPwd.text=@"";
                self.textFieldNewPwd.text=@"";
            }
        }else{
            [[[UIAlertView alloc] initWithTitle:@"Please Enter All Fields"
                                        message:@""
                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        }
    }else{
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"It appears you are not connected to internet" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - Contact Support

-(void)getContactSupport{
    if ([APPDELEGATE connected]) {
        
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
        NSString *strAuthorization=[defaults valueForKey:@"BasicAuth"];
        
        AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
        // httpClient.parameterEncoding = AFJSONParameterEncoding;
        [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [httpClient setDefaultHeader:@"Authorization" value:strAuthorization];
        
        NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET"
                                                                path:@"http://ft.allsmart.in/rest/s1/ft/customerSupportInfo"
                                                          parameters:nil];
        //====================================================RESPONSE
        [DejalBezelActivityView activityViewForView:self.view];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        }];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSError *error = nil;
            NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
            [DejalBezelActivityView removeView];
            NSLog(@"Contact Support==%@",JSON);
            
            if ([[JSON objectForKey:@"userObj"] valueForKey:@"emailAddress"]) {
                if (![[[JSON objectForKey:@"userObj"] valueForKey:@"emailAddress"] isKindOfClass:[NSNull class]]) {
                    self.lblForEmailContact.text=[[JSON objectForKey:@"userObj"] valueForKey:@"emailAddress"];
                }
            }
            
            if ([[JSON objectForKey:@"userObj"] valueForKey:@"contactNumber"]) {
                if (![[[JSON objectForKey:@"userObj"] valueForKey:@"contactNumber"] isKindOfClass:[NSNull class]]) {
                    self.lblForPhoneContact.text=[[JSON objectForKey:@"userObj"] valueForKey:@"contactNumber"];
                }
            }
            
            [self setupContactSupport];
            
        }
         //==================================================ERROR
                                         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                             [DejalBezelActivityView removeView];
                                             NSLog(@"Error %@",[error description]);
                                             
                                             NSError *jsonError;
                                             NSData *objectData = [[[error userInfo] objectForKey:NSLocalizedRecoverySuggestionErrorKey] dataUsingEncoding:NSUTF8StringEncoding];
                                             
                                             if (objectData != nil) {
                                                 
                                                 NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                                                                      options:NSJSONReadingMutableContainers
                                                                                                        error:&jsonError];
                                                 
                                                 NSString *strError=[json valueForKey:@"errors"];
                                                 [[[UIAlertView alloc] initWithTitle:@""
                                                                             message:strError
                                                                            delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                                             }
                                             
                                         }];
        [operation start];
    }else{
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"It appears you are not connected to internet" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

-(void)orgNameTapped{
    
    NSString *string=[NSString stringWithFormat:@"%@",self.lblForOrgNameContact.attributedText.string];
    if (string.length > 0){
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.allsmart.in/"]];
    }
}

-(void)emailIDTapped{
    
    NSString *string=[NSString stringWithFormat:@"%@",self.lblForEmailContact.attributedText.string];
    
    if ([self isValidEmail:[string substringFromIndex:8]]){
        //send mail
        if ([MFMailComposeViewController canSendMail]){
            [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil] setTintColor:[UIColor whiteColor]];
            MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
            controller.mailComposeDelegate = self;
            [controller setSubject:@""];
            NSArray *toRecipents = [NSArray arrayWithObjects:[string substringFromIndex:8],nil];
            [controller setToRecipients:toRecipents];
            NSString *message =@"";
            [controller setMessageBody:message isHTML:YES];
            [self presentViewController:controller animated:YES completion:NULL];
        }else{
            [[[UIAlertView alloc] initWithTitle:@"Your device is not configured for sending email"
                                        message:@"Please configure your mail account in iphone's setting"
                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        }
    }
}

-(void)phoneNumTapped{
    //    NSString *phNo = self.lblForPhoneContact.text;
    
    NSString *string=[NSString stringWithFormat:@"%@",self.lblForPhoneContact.attributedText.string];
    NSURL *phoneUrl = [NSURL URLWithString:[NSString  stringWithFormat:@"telprompt:%@",[string substringFromIndex:8]]];
    if ([[UIApplication sharedApplication] canOpenURL:phoneUrl]) {
        [[UIApplication sharedApplication] openURL:phoneUrl];
    } else{
        UIAlertView* calert = [[UIAlertView alloc]initWithTitle:@"Alert" message:@"Call facility is not available!!!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [calert show];
    }
}
#pragma mark - MFMailComposeDelegate


- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}
#pragma mark -

-(void)checkingInLocation:(NSNotification*)notification{
    
    @try {
        NSDictionary *userInfo = notification.userInfo;
      //  NSLog(@"Notification In History==%@",userInfo);
        
        //    NSDictionary *dict=[userIn];
        
        if ([[userInfo valueForKey:@"LocationStatus"] integerValue]==1) {
            self.imgVwForLocationIcon.image=[UIImage imageNamed:@"location_On"];
            self.lblForStoreLocation.textColor=[UIColor whiteColor];
        }else{
            self.imgVwForLocationIcon.image=[UIImage imageNamed:@"location_Off"];
            //        self.lblForStoreLocation.text=@"Off site";
            self.lblForStoreLocation.textColor=[UIColor darkGrayColor];
        }
        // self.textVwMyAddress.text=[userInfo valueForKey:@"StoreAddress"];
        self.lblForStoreLocation.text=[userInfo valueForKey:@"StoreName"];
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
    }
    @finally {
        //        NSLog(@"Char at index %d cannot be found", index);
        //        NSLog(@"Max index is: %d", [test length]-1);
    }
}

-(void)changeLocationStatus:(NSDictionary*)dictInfo{
    
    if ([[dictInfo valueForKey:@"LocationStatus"] integerValue]==1) {
        self.imgVwForLocationIcon.image=[UIImage imageNamed:@"location_On"];
        self.lblForStoreLocation.textColor=[UIColor whiteColor];
    }else{
        self.imgVwForLocationIcon.image=[UIImage imageNamed:@"location_Off"];
        //self.lblForStoreLocation.text=@"Off site";
        self.lblForStoreLocation.textColor=[UIColor darkGrayColor];
    }
    
    self.lblForStoreLocation.text=[dictInfo valueForKey:@"StoreName"];
}

- (void)refreshFooter
{
    if(arrayCountToCheck > pageNumber){
        
        pageNumber++;
        
        [self getPromoters];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableVwForPromoters reloadData];
            [self.tableVwForPromoters footerEndRefreshing];
            //        [self.tableVw removeFooter];
        });
    }else{
        [self.tableVwForPromoters footerEndRefreshing];
        [self.tableVwForPromoters headerEndRefreshing];
    }
}

-(void)storeSelected{
    NSDictionary *dict=[[NSMutableDictionary alloc] init];
    dict=[[MKSharedClass shareManager] dictForStoreSelected];
    NSLog(@"Selected Store Details===%@",dict);
    self.txtFieldStoreAsgnmntPromoter.text=[dict valueForKey:@"storeName"];
    self.txtFieldSEAsgnmntPromoter.text=[NSString stringWithFormat:@"%@ %@",self.lblFName.text,self.lblLName.text];
    storeIDForPromoterAdd=[dict valueForKey:@"productStoreId"];
    
    NSLog(@"Selected Store ID===%@",storeIDForPromoterAdd);
}

-(void)addShadow:(UIButton*)btn{
    btn.layer.shadowColor = [UIColor lightGrayColor].CGColor;
    btn.layer.shadowOffset = CGSizeMake(1, 1);
    btn.layer.shadowOpacity = 1;
    btn.layer.shadowRadius = 1.0;
}

#pragma mark - TextField Delegate
-(void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField == self.txtFieldStoreName || textField == self.txtFieldSiteRadius) {
        [self enableAddNewStoreBtn];
    }else if (textField == self.txtFieldStoreAsgnmntPromoter){
    }
}

-(void)textFieldDidBeginEditing:(UITextField *)textField{
    if (textField == self.txtFieldStoreAsgnmntPromoter){
    }
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    
    if (textField == self.txtFieldStoreAsgnmntPromoter || textField == self.txtFieldSEAsgnmntPromoter){
        return NO;
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if ([textField isFirstResponder]){
        if ([[[textField textInputMode] primaryLanguage] isEqualToString:@"emoji"] || ![[textField textInputMode] primaryLanguage]){
            return NO;
        }
    }
    return YES;
}

-(void)textFieldEdit:(UITextField*)txtField{
    txtField.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.7];
    txtField.keyboardType=UIKeyboardTypeASCIICapable;
    
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 20)];
    txtField.leftView = paddingView;
    txtField.leftViewMode = UITextFieldViewModeAlways;
    txtField.layer.cornerRadius=5;
    txtField.delegate=self;
    txtField.autocorrectionType = UITextAutocorrectionTypeNo;
    
    [txtField addTarget:self action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
}
#pragma mark - TextView Delegate

-(void)textViewDidBeginEditing:(UITextView *)textView
{
    if (textView== self.txtVwStoreAddress && [textView.text isEqualToString:@"Store Address"]){
        textView.text=@"";
    }else if (textView== self.txtVwAddressPromoter && [textView.text isEqualToString:@"Address"]){
        textView.text=@"";
    }
}

-(void)textViewDidEndEditing:(UITextView *)textView
{
    if (textView== self.txtVwStoreAddress && self.txtVwStoreAddress.text.length<=0){
        textView.text=@"Store Address";
    }else{
        [self enableAddNewStoreBtn];
    }
    
    if (textView== self.txtVwAddressPromoter && self.txtVwAddressPromoter.text.length<=0){
        textView.text=@"Address";
    }
}

#pragma mark - Add StoreView

-(void)setUpForAddStore:(NSInteger)indexValue{
    
    self.txtVwStoreAddress.delegate = self;
    
    self.txtVwStoreAddress.text=@"Store Address";
    self.backBtn.hidden=YES;
    self.lblForLatLon.text=@"";
    self.lblForLatLon.textAlignment = NSTextAlignmentCenter;
    
    if ([[MKSharedClass shareManager] valueForStoreEditVC] == 1){
        self.lblForEditStore.text=@"Add Store";
        [self.btnAdd setTitle:@"Add" forState:UIControlStateNormal];
        
        self.btnAdd.enabled = NO;
        self.btnAdd.alpha = 0.6;
        self.btnAdd.backgroundColor=[[UIColor lightGrayColor] colorWithAlphaComponent:0.6];
        self.txtFieldStoreName.text=@"";
        self.txtFieldSiteRadius.text=@"";
        
    }else if ([[MKSharedClass shareManager] valueForStoreEditVC] == 0){
        
        self.lblForEditStore.text=@"Edit Store";
        [self.btnAdd setTitle:@"Edit" forState:UIControlStateNormal];
        self.btnAdd.backgroundColor=[[UIColor blueColor] colorWithAlphaComponent:0.6];
        self.btnAdd.enabled = YES;
        self.btnAdd.alpha = 1.0;
        
        self.txtVwStoreAddress.text=[[arrayForStoreList objectAtIndex:indexValue] valueForKey:@"address"];
        self.txtFieldStoreName.text=[[arrayForStoreList objectAtIndex:indexValue] valueForKey:@"storeName"];
        self.txtFieldSiteRadius.text=[NSString stringWithFormat:@"%i",[[[arrayForStoreList objectAtIndex:indexValue] valueForKey:@"proximityRadius"] integerValue]];
        
        self.lblForLatLon.text=[NSString stringWithFormat:@"Lat: %@ | Lon: %@",[[arrayForStoreList objectAtIndex:indexValue] valueForKey:@"latitude"],[[arrayForStoreList objectAtIndex:indexValue] valueForKey:@"longitude"]];
        strForCurLatitude=[[arrayForStoreList objectAtIndex:indexValue] valueForKey:@"latitude"];
        strForCurLongitude=[[arrayForStoreList objectAtIndex:indexValue] valueForKey:@"longitude"];
        self.btnAdd.tag=indexValue;
    }
}

-(void)enableAddNewStoreBtn
{
    if ([[MKSharedClass shareManager] valueForStoreEditVC] == 1){
        if (self.txtFieldStoreName.text.length>0&&self.txtVwStoreAddress.text.length>0&&self.txtFieldSiteRadius.text.length>0&& ![self.txtVwStoreAddress.text isEqualToString:@"Store Address"]) {
            self.btnAdd.enabled = YES;
            self.btnAdd.alpha = 1;
            self.btnAdd.backgroundColor=[[UIColor darkGrayColor] colorWithAlphaComponent:1];
        }else{
            self.btnAdd.enabled = NO;
            self.btnAdd.alpha = 0.6;
            self.btnAdd.backgroundColor=[[UIColor lightGrayColor] colorWithAlphaComponent:0.6];
        }
    }
}

-(void)onClickStoreAddToServer:(UIButton*)sender
{
    if ([APPDELEGATE connected]) {
        
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
        
        AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
        httpClient.parameterEncoding = AFFormURLParameterEncoding;
        [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
        
        NSString *str=[defaults valueForKey:@"BasicAuth"];
        
        [httpClient setDefaultHeader:@"Authorization" value:str];
        //{"storeName":"OPPO Tirumalgherry","address":"Via Rest API","latitude":100.00,"longitude":100.00,"proximityRadius":200}
        NSDictionary * json = @{@"storeName":self.txtFieldStoreName.text,
                                @"address":self.txtVwStoreAddress.text,
                                @"latitude":strForCurLatitude,
                                @"longitude":strForCurLongitude,
                                @"proximityRadius":self.txtFieldSiteRadius.text,
                                };
        NSMutableURLRequest *request;
        if ([[MKSharedClass shareManager] valueForStoreEditVC] == 1){
            request = [httpClient requestWithMethod:@"POST"
                                               path:@"/rest/s1/ft/stores"
                                         parameters:json];
        }else if ([[MKSharedClass shareManager] valueForStoreEditVC] == 0){
            
            NSString *strPath=[NSString stringWithFormat:@"/rest/s1/ft/stores/%@",[[arrayForStoreList objectAtIndex:sender.tag] valueForKey:@"productStoreId"]];
            request = [httpClient requestWithMethod:@"PUT"
                                               path:strPath
                                         parameters:json];
        }
        
        //====================================================RESPONSE
        [DejalBezelActivityView activityViewForView:self.view];
        
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            
        }];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSError *error = nil;
            NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
            [DejalBezelActivityView removeView];
            NSLog(@"Add Store Successfully==%@",JSON);
            
            self.vwForStoreAdd.hidden = YES;
            self.backBtn.hidden=NO;
            
            if ([[MKSharedClass shareManager] valueForStoreEditVC] == 1){
                if ([[[JSON objectForKey:@"productStoreId"] valueForKey:@"productStoreId"] integerValue]>0) {
                    //                self.vwForStoreAdd.hidden = YES;
                    //                self.backBtn.hidden=NO;
                    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Success" message:@"Store Added Successfully" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                }
            }else if ([[MKSharedClass shareManager] valueForStoreEditVC] == 0){
                UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Success" message:@"Store Edited Successfully" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        }
         //==================================================ERROR
                                         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                             [DejalBezelActivityView removeView];
                                             NSLog(@"Error %@",[error description]);
                                         }];
        [operation start];
    }else{
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"It appears you are not connected to internet" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

-(void)onClickCancel{
    self.vwForStoreAdd.hidden = YES;
    self.backBtn.hidden=NO;
}

-(void)getLocation{
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    [locationManager startUpdatingLocation];
    CLLocation *location = [locationManager location];
    CLLocationCoordinate2D coordinate = [location coordinate];
    //    NSLog(@"Lat:%f Lon:%f",coordinate.latitude,coordinate.longitude);
    //    return coordinate;
    strForCurLatitude=[NSString stringWithFormat:@"%f",coordinate.latitude];
    strForCurLongitude=[NSString stringWithFormat:@"%f",coordinate.longitude];
    [self getAddress];
}

-(void)getAddress
{
    NSString *url = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/directions/json?origin=%f,%f&destination=%f,%f&sensor=false",[strForCurLatitude floatValue], [strForCurLongitude floatValue], [strForCurLatitude floatValue], [strForCurLongitude floatValue]];
    
    NSString *str = [NSString stringWithContentsOfURL:[NSURL URLWithString:url] encoding:NSUTF8StringEncoding error:nil];
    if (str.length>0){
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding] options: NSJSONReadingMutableContainers
                                                               error: nil];
        
        NSDictionary *getRoutes = [JSON valueForKey:@"routes"];
        NSDictionary *getLegs = [getRoutes valueForKey:@"legs"];
        NSArray *getAddress = [getLegs valueForKey:@"end_address"];
        //        NSLog(@"Map Location=====%@",JSON);
        if (getAddress.count!=0){
            //            self.textVwForAddress.text=[[getAddress objectAtIndex:0]objectAtIndex:0];
            //            CGRect frame = self.textVwForAddress.frame;
            //            frame.size.height = self.textVwForAddress.contentSize.height;
            //            self.textVwForAddress.frame=frame;
            //            NSLog(@"Address==%@",[[getAddress objectAtIndex:0]objectAtIndex:0]);
            self.lblForLatLon.text=[NSString stringWithFormat:@"Lat: %f | Lon: %f",[strForCurLatitude floatValue],[strForCurLongitude floatValue]];
            
            self.txtVwStoreAddress.text=[[getAddress objectAtIndex:0]objectAtIndex:0];
            
            if (self.txtFieldStoreName.text.length>0 && self.txtFieldSiteRadius.text.length>0) {
                [self enableAddNewStoreBtn];
            }
        }
    }
}

-(void)updateLocationManagerr{
    [locationManager startUpdatingLocation];
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate=self;
    locationManager.desiredAccuracy=kCLLocationAccuracyBest;
    locationManager.distanceFilter=kCLDistanceFilterNone;
    
#ifdef __IPHONE_8_0
    //  if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8")) {
    // Use one or the other, not both. Depending on what you put in info.plist
    //[self.locationManager requestWhenInUseAuthorization];
    [locationManager requestAlwaysAuthorization];
    //  }
#endif
    
    [locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation{
    strForCurLatitude=[NSString stringWithFormat:@"%f",newLocation.coordinate.latitude];
    strForCurLongitude=[NSString stringWithFormat:@"%f",newLocation.coordinate.longitude];
}
#pragma mark - Get Store's

-(void)getStores{
    
    if ([APPDELEGATE connected]) {
        
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
        NSString *strAuthorization=[defaults valueForKey:@"BasicAuth"];
        
        AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
        httpClient.parameterEncoding = AFFormURLParameterEncoding;
        [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [httpClient setDefaultHeader:@"Authorization" value:strAuthorization];
        
        NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET"
                                                                path:@"/rest/s1/ft/stores/user/list"
                                                          parameters:nil];
        //====================================================RESPONSE
        [DejalBezelActivityView activityViewForView:self.view];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        }];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSError *error = nil;
            NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
            [DejalBezelActivityView removeView];
            NSLog(@"Store List==%@",JSON);
            arrayForStoreList=[JSON objectForKey:@"userStores"];
            [self.tableVwForStore reloadData];
        }
         //==================================================ERROR
                                         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                             [DejalBezelActivityView removeView];
                                             NSLog(@"Error %@",[error description]);
                                             
                                             NSError *jsonError;
                                             NSData *objectData = [[[error userInfo] objectForKey:NSLocalizedRecoverySuggestionErrorKey] dataUsingEncoding:NSUTF8StringEncoding];
                                             
                                             if (objectData != nil) {
                                                 
                                                 NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                                                                      options:NSJSONReadingMutableContainers
                                                                                                        error:&jsonError];
                                                 
                                                 NSString *strError=[json valueForKey:@"errors"];
                                                 [[[UIAlertView alloc] initWithTitle:@""
                                                                             message:strError
                                                                            delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                                             }
                                             
                                         }];
        [operation start];
    }else{
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"It appears you are not connected to internet" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}


#pragma mark - Add Store

-(void)onClickAddStore:(UIButton*)btn{
    [[MKSharedClass shareManager] setValueForStoreEditVC:1];
    [self goToStorePopup:0];
    
    //    NSLog(@"On Click Add Store");
}

#pragma mark - Get Promoters
-(void)getPromotersApproval{
    
    if ([APPDELEGATE connected]) {
        
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
        NSString *strAuthorization=[defaults valueForKey:@"BasicAuth"];
        
        AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
        httpClient.parameterEncoding = AFFormURLParameterEncoding;
        [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [httpClient setDefaultHeader:@"Authorization" value:strAuthorization];
        
        NSString *strPath=[NSString stringWithFormat:@"/rest/s1/ft/request/promoter/approvalRequests?pageIndex=%i&pageSize=10",pageNumber];
        NSLog(@"String Path for Get Promoters==%@",strPath);
        NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET"
                                                                path:strPath
                                                          parameters:nil];
        
        //====================================================RESPONSE
        
        if (pageNumber==0) {
            [DejalBezelActivityView activityViewForView:self.view];
        }
        
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
        [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            
        }];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSError *error = nil;
            NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
            
            if (pageNumber==0) {
                [DejalBezelActivityView removeView];
            }
            
            NSMutableArray *array=[[JSON objectForKey:@"requestList"] mutableCopy];
            
            //arrayForPromoters=[[JSON objectForKey:@"requestList"] mutableCopy];
            
            for (NSDictionary *dict in array) {
                [arrayForPromoters addObject:dict];
            }
            NSLog(@"Promoter List===%@",JSON);
            arrayCountToCheck=[[JSON objectForKey:@"totalEntries"] integerValue];
            [self.tableVwForPromoters reloadData];
        }
         //==================================================ERROR
                                         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                             [DejalBezelActivityView removeView];
                                             NSLog(@"Error %@",[error description]);
                                             NSError *jsonError;
                                             NSData *objectData = [[[error userInfo] objectForKey:NSLocalizedRecoverySuggestionErrorKey] dataUsingEncoding:NSUTF8StringEncoding];
                                             
                                             if (objectData != nil) {
                                                 
                                                 NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                                                                      options:NSJSONReadingMutableContainers
                                                                                                        error:&jsonError];
                                                 
                                                 NSString *strError=[json valueForKey:@"errors"];
                                                 [[[UIAlertView alloc] initWithTitle:@""
                                                                             message:strError
                                                                            delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                                             }
                                             
                                         }];
        [operation start];
    }else{
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"It appears you are not connected to internet" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

-(void)getPromoters{
    
    if ([APPDELEGATE connected]) {
        
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
        NSString *strAuthorization=[defaults valueForKey:@"BasicAuth"];
        
        AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
        httpClient.parameterEncoding = AFFormURLParameterEncoding;
        [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [httpClient setDefaultHeader:@"Authorization" value:strAuthorization];
        
        NSString *strPath=[NSString stringWithFormat:@"/rest/s1/ft/request/promoter/list?pageIndex=%i&pageSize=10",pageNumber];
        NSLog(@"String Path for Get Promoters==%@",strPath);
        NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET"
                                                                path:strPath
                                                          parameters:nil];
        
        //====================================================RESPONSE
        
        if (pageNumber==0) {
            [DejalBezelActivityView activityViewForView:self.view];
        }
        
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
        [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            
        }];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSError *error = nil;
            NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
            
            if (pageNumber==0) {
                [DejalBezelActivityView removeView];
            }
            
            NSMutableArray *array=[[JSON objectForKey:@"requestList"] mutableCopy];
            
            //arrayForPromoters=[[JSON objectForKey:@"requestList"] mutableCopy];
            
            for (NSDictionary *dict in array) {
                [arrayForPromoters addObject:dict];
            }
            NSLog(@"Promoter List===%@",JSON);
            arrayCountToCheck=[[JSON objectForKey:@"totalEntries"] integerValue];
            [self.tableVwForPromoters reloadData];
        }
         //==================================================ERROR
                                         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                             [DejalBezelActivityView removeView];
                                             NSLog(@"Error %@",[error description]);
                                             NSError *jsonError;
                                             NSData *objectData = [[[error userInfo] objectForKey:NSLocalizedRecoverySuggestionErrorKey] dataUsingEncoding:NSUTF8StringEncoding];
                                             
                                             if (objectData != nil) {
                                                 
                                                 NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                                                                      options:NSJSONReadingMutableContainers
                                                                                                        error:&jsonError];
                                                 
                                                 NSString *strError=[json valueForKey:@"errors"];
                                                 [[[UIAlertView alloc] initWithTitle:@""
                                                                             message:strError
                                                                            delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                                             }
                                             
                                         }];
        [operation start];
    }else{
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"It appears you are not connected to internet" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}


#pragma mark - Add Promoter

-(void)multiSelect:(MultiSelectSegmentedControl *)multiSelectSegmentedControl didChangeValue:(BOOL)selected atIndex:(NSUInteger)index {
    
    if (selected) {
        //        NSLog(@"multiSelect with tag %i selected button at index: %i", multiSelectSegmentedControl.tag, index);
    } else {
        //        NSLog(@"multiSelect with tag %i deselected button at index: %i", multiSelectSegmentedControl.tag, index);
    }
    NSLog(@"selected: '%@'", [multiSelectSegmentedControl.selectedSegmentTitles componentsJoinedByString:@","]);
}


-(void)onClickAddPromoter{
    
    for (UIView *subview in [self.btnPhotoPromoter subviews]) {
        if([subview isKindOfClass:[JSBadgeView class]]){
            [subview removeFromSuperview];
        }
    }
    
    for (UIView *subview in [self.btnAadharPromoter subviews]) {
        if([subview isKindOfClass:[JSBadgeView class]]){
            [subview removeFromSuperview];
        }
    }
    
    for (UIView *subview in [self.btnAdressProofPromoter subviews]) {
        if([subview isKindOfClass:[JSBadgeView class]]){
            [subview removeFromSuperview];
        }
    }
    
    [self promoterDetails:YES];
}

-(void)promoterDetails:(BOOL)isAddOrEdit{
    
    for (UIView *subview in [self.btnPhotoPromoter subviews]) {
        if([subview isKindOfClass:[JSBadgeView class]]){
            [subview removeFromSuperview];
        }
    }
    
    for (UIView *subview in [self.btnAadharPromoter subviews]) {
        if([subview isKindOfClass:[JSBadgeView class]]){
            [subview removeFromSuperview];
        }
    }
    
    for (UIView *subview in [self.btnAdressProofPromoter subviews]) {
        if([subview isKindOfClass:[JSBadgeView class]]){
            [subview removeFromSuperview];
        }
    }
    
    self.segmentControl.delegate = self;
    [self.btnCancelPromoterAdd addTarget:self action:@selector(onClickCancelOfAddPromoter) forControlEvents:UIControlEventTouchUpInside];
    self.btnAddPromoterConfirm.tag=isAddOrEdit;
    [self.btnAddPromoterConfirm addTarget:self action:@selector(addPromoter:) forControlEvents:UIControlEventTouchUpInside];
    self.vwForPromoterAdd.hidden = NO;
    self.backBtn.hidden = YES;
    
    if (!isAddOrEdit) {
        
        if (![[[arrayForPromoters objectAtIndex:indexValueOfPromoterEdit] valueForKey:@"statusId"] isKindOfClass:[NSNull class]]) {
            NSString *promoterStatus=[[arrayForPromoters objectAtIndex:indexValueOfPromoterEdit] valueForKey:@"statusId"];
            
            if ([promoterStatus containsString:@"Completed"]) {
                [self disablePromoterView];
            }else if ([promoterStatus containsString:@"Submitted"] || [promoterStatus containsString:@"Rejected"]){
                [self enablePromoterView];
            }
            if (!isPromoterOrPromoterApprove) {
                [self disablePromoterView];
            }
        }
        
        //[self.btnAddPromoterConfirm setTitle:@"Edit" forState:UIControlStateNormal];
        
        NSString *jsonString = [[arrayForPromoters objectAtIndex:indexValueOfPromoterEdit] objectForKey:@"requestJson"];
        NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        NSLog(@"Promoters List==%@",[json objectForKey:@"requestInfo"]);
        
        self.txtFieldFNamePromoter.text=[[json objectForKey:@"requestInfo"] valueForKey:@"firstName"];
        self.txtFieldLNamePromoter.text=[[json objectForKey:@"requestInfo"] valueForKey:@"lastName"];
        self.txtFieldEmailPromoter.text=[[json objectForKey:@"requestInfo"] valueForKey:@"emailId"];
        self.txtFieldPhonePromoter.text=[[json objectForKey:@"requestInfo"] valueForKey:@"phone"];
        self.txtVwAddressPromoter.text=[[json objectForKey:@"requestInfo"] valueForKey:@"address"];
        
        NSString *productStoreId=[[json objectForKey:@"requestInfo"] objectForKey:@"productStoreId"];
        self.txtFieldStoreAsgnmntPromoter.text=@"";
        self.txtFieldSEAsgnmntPromoter.text=@"";
        for (NSDictionary *dict in arrayForStoreList) {
            if ([[dict valueForKey:@"productStoreId"] isEqualToString:productStoreId]) {
                self.txtFieldStoreAsgnmntPromoter.text=[dict valueForKey:@"storeName"];
                self.txtFieldSEAsgnmntPromoter.text=[NSString stringWithFormat:@"%@ %@",self.lblFName.text,self.lblLName.text];
            }
        }
        
        strAadharIDPath=[[json objectForKey:@"requestInfo"] objectForKey:@"aadharIdPath"];;
        strUserPhotoPath=[[json objectForKey:@"requestInfo"] objectForKey:@"userPhoto"];;
        strAddressProofPath=[[json objectForKey:@"requestInfo"] objectForKey:@"addressIdPath"];
        storeIDForPromoterAdd=productStoreId;
        
    }else{
        [self enablePromoterView];
        strAadharIDPath=@"";
        strUserPhotoPath=@"";
        strAddressProofPath=@"";
        [self.btnAddPromoterConfirm setTitle:@"Add" forState:UIControlStateNormal];
        [self.btnCancelPromoterAdd setTitle:@"Cancel" forState:UIControlStateNormal];
        
        self.txtFieldPhonePromoter.keyboardType=UIKeyboardTypePhonePad;
        self.txtFieldFNamePromoter.text=@"";
        self.txtFieldLNamePromoter.text=@"";
        self.txtFieldEmailPromoter.text=@"";
        self.txtFieldPhonePromoter.text=@"";
        self.txtVwAddressPromoter.text=@"Address";
        self.txtFieldSEAsgnmntPromoter.text=@"";
        self.txtFieldStoreAsgnmntPromoter.text=@"";
        self.btnAddPromoterConfirm.backgroundColor=[UIColor grayColor];
    }
}
-(void)disablePromoterView{
    
    self.txtFieldFNamePromoter.userInteractionEnabled = NO;
    self.txtFieldLNamePromoter.userInteractionEnabled = NO;
    self.txtFieldEmailPromoter.userInteractionEnabled = NO;
    self.txtFieldPhonePromoter.userInteractionEnabled = NO;
    self.txtFieldSEAsgnmntPromoter.userInteractionEnabled = NO;
    self.txtFieldStoreAsgnmntPromoter.userInteractionEnabled = NO;
    self.txtVwAddressPromoter.userInteractionEnabled = NO;
    self.segmentControl.userInteractionEnabled = NO;
    self.btnAddPromoterConfirm.userInteractionEnabled = NO;
    self.btnAdressProofPromoter.userInteractionEnabled = NO;
    self.btnAadharPromoter.userInteractionEnabled = NO;
    self.btnPhotoPromoter.userInteractionEnabled = NO;
    self.btnForStoreAssignmtPopup.userInteractionEnabled = NO;
    
    if (![[[arrayForPromoters objectAtIndex:indexValueOfPromoterEdit] valueForKey:@"statusId"] isKindOfClass:[NSNull class]]) {
        NSString *promoterStatus=[[arrayForPromoters objectAtIndex:indexValueOfPromoterEdit] valueForKey:@"statusId"];
        
        if ([promoterStatus containsString:@"Completed"]) {
            [self.btnAddPromoterConfirm setTitle:@"Edit" forState:UIControlStateNormal];
            [self.btnCancelPromoterAdd setTitle:@"Cancel" forState:UIControlStateNormal];
            self.btnAddPromoterConfirm.alpha = 0.2;
            self.btnAddPromoterConfirm.backgroundColor=[UIColor grayColor];
            //btnCancelPromoterAdd
            //             [self enablePromoterView];
            
        }else if ([promoterStatus containsString:@"Submitted"] || [promoterStatus containsString:@"Rejected"]){
            self.backBtn.hidden = NO;
            
            //85,160,248
            self.btnAddPromoterConfirm.backgroundColor=[UIColor colorWithRed:(85/255.0) green:(160/255.0) blue:(248/255.0) alpha:1.0];
            [self.btnAddPromoterConfirm setTitle:@"Approve" forState:UIControlStateNormal];
            [self.btnCancelPromoterAdd setTitle:@"Reject" forState:UIControlStateNormal];
            
            self.btnAddPromoterConfirm.alpha = 1;
            self.btnAddPromoterConfirm.userInteractionEnabled = YES;
            //btnCancelPromoterAdd
        }
    }
}

-(void)enablePromoterView{
    self.txtFieldFNamePromoter.userInteractionEnabled = YES;
    self.txtFieldLNamePromoter.userInteractionEnabled = YES;
    self.txtFieldEmailPromoter.userInteractionEnabled = YES;
    self.txtFieldPhonePromoter.userInteractionEnabled = YES;
    self.txtFieldSEAsgnmntPromoter.userInteractionEnabled = YES;
    self.txtFieldStoreAsgnmntPromoter.userInteractionEnabled = YES;
    self.txtVwAddressPromoter.userInteractionEnabled = YES;
    self.segmentControl.userInteractionEnabled = YES;
    self.btnAddPromoterConfirm.userInteractionEnabled = YES;
    self.btnAdressProofPromoter.userInteractionEnabled = YES;
    self.btnAadharPromoter.userInteractionEnabled = YES;
    self.btnPhotoPromoter.userInteractionEnabled = YES;
    self.btnForStoreAssignmtPopup.userInteractionEnabled = YES;
    
    [self.btnAddPromoterConfirm setTitle:@"Edit" forState:UIControlStateNormal];
    [self.btnCancelPromoterAdd setTitle:@"Cancel" forState:UIControlStateNormal];
    self.btnAddPromoterConfirm.alpha = 0.8;
    self.btnAddPromoterConfirm.backgroundColor=[UIColor grayColor];
}
-(void)addPromoterViewSetup{
    [self textFieldEdit:self.txtFieldFNamePromoter];
    [self textFieldEdit:self.txtFieldLNamePromoter];
    [self textFieldEdit:self.txtFieldEmailPromoter];
    [self textFieldEdit:self.txtFieldPhonePromoter];
    [self textFieldEdit:self.txtFieldSEAsgnmntPromoter];
    [self textFieldEdit:self.txtFieldStoreAsgnmntPromoter];
    
    self.txtFieldEmailPromoter.keyboardType = UIKeyboardTypeEmailAddress;
    
    self.txtVwAddressPromoter.text=@"Address";
    self.txtVwAddressPromoter.layer.cornerRadius = 5;
    self.txtVwAddressPromoter.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.7];
    self.txtVwAddressPromoter.keyboardType=UIKeyboardTypeASCIICapable;
    self.txtVwAddressPromoter.delegate = self;
    self.txtVwAddressPromoter.autocorrectionType = UITextAutocorrectionTypeNo;
    
    //    self.btnPhotoPromoter.layer.cornerRadius = 5;
    //    self.btnPhotoPromoter.layer.masksToBounds = YES;
    self.btnPhotoPromoter.tag=100;
    
    //    self.btnAadharPromoter.layer.cornerRadius = 5;
    //    self.btnAadharPromoter.layer.masksToBounds =YES;
    self.btnAadharPromoter.tag = 200;
    
    //    self.btnAdressProofPromoter.layer.cornerRadius = 5;
    //    self.btnAdressProofPromoter.layer.masksToBounds =YES;
    self.btnAdressProofPromoter.tag=300;
    
    [self addShadow:self.btnAddPromoterConfirm];
    [self addShadow:self.btnCancelPromoterAdd];
    
    [self.btnAdressProofPromoter setTitle:@"" forState:UIControlStateNormal];
    [self.btnAdressProofPromoter setImage:[UIImage imageNamed:@"id-card72"] forState:UIControlStateNormal];
    
    [self.btnPhotoPromoter addTarget:self action:@selector(openCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnAadharPromoter addTarget:self action:@selector(openCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnAdressProofPromoter addTarget:self action:@selector(openCamera:) forControlEvents:UIControlEventTouchUpInside];
}

-(void)onClickCancelOfAddPromoter{
    
    if ([self.btnCancelPromoterAdd.titleLabel.text isEqualToString:@"Reject"]) {
        [self promoterApproveOrReject:NO];
    }else{
        self.vwForPromoterAdd.hidden = YES;
        self.backBtn.hidden = NO;
    }
}

-(void)addPromoter:(UIButton*)sender
{
    if ([APPDELEGATE connected]) {
        
        if ((sender.tag == 1 || sender.tag == 0) && ![sender.titleLabel.text isEqualToString:@"Approve"]) {
            
            if (self.txtFieldFNamePromoter.text.length>0&&self.txtFieldLNamePromoter.text.length>0&&self.txtFieldEmailPromoter.text.length>0&&self.txtVwAddressPromoter.text.length>0&&self.txtFieldStoreAsgnmntPromoter.text.length>0&& (![[self.txtVwAddressPromoter text] isEqualToString:@"Address"])) {
                
                if ([self isValidEmail:self.txtFieldEmailPromoter.text]) {
                    
                    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
                    NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
                    NSString *strAuthorization=[defaults valueForKey:@"BasicAuth"];
                    
                    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
                    httpClient.parameterEncoding = AFFormURLParameterEncoding;
                    [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
                    [httpClient setDefaultHeader:@"Authorization" value:strAuthorization];
                    
                    //{"requestType":"RqtAddPromoter", "firstName":"James", "lastName":"Managalam","phone":"11111111","address":"eh hai address","emailId":"james@allsmart.in","productStoreId":"100000","statusId":"ReqSubmitted","requestTypeEnumId":"RqtAddPromoter","aadharIdPath":"/img/","userPhoto":"/img/","addressIdPath":"/img/"}
                    /*
                     @"aadharIdPath":strAadharIDPath,
                     @"userPhoto":strUserPhotoPath,
                     @"addressIdPath":strAddressProofPath,
                     */
                    
                    if ([strAadharIDPath length]<=0||strAadharIDPath == nil) {
                        strAadharIDPath=@"/img/";
                    }
                    if ([strUserPhotoPath length]<=0||strUserPhotoPath == nil){
                        strUserPhotoPath=@"/img/";
                    }
                    if ([strAddressProofPath length]<=0||strAddressProofPath == nil){
                        strAddressProofPath=@"/img/";
                    }
                    
                    NSMutableURLRequest *request;
                    
                    if (sender.tag == 1){
                        NSDictionary * json = @{@"requestType":@"RqtAddPromoter",
                                                @"firstName":self.txtFieldFNamePromoter.text,
                                                @"lastName":self.txtFieldLNamePromoter.text,
                                                @"phone":self.txtFieldPhonePromoter.text,
                                                @"address":self.txtVwAddressPromoter.text,
                                                @"emailId":self.txtFieldEmailPromoter.text,
                                                @"productStoreId":storeIDForPromoterAdd,
                                                @"statusId":@"ReqSubmitted",
                                                @"requestTypeEnumId":@"RqtAddPromoter",
                                                @"aadharIdPath":strAadharIDPath,
                                                @"userPhoto":strUserPhotoPath,
                                                @"addressIdPath":strAddressProofPath,
                                                @"description":@"Requesting new Promoter",
                                                @"organizationId":@"ORG_OPPO",
                                                };
                        request = [httpClient requestWithMethod:@"POST"
                                                           path:@"/rest/s1/ft/request/promoter"
                                                     parameters:json];
                    }else if (sender.tag == 0){
                        
                        NSString *rqstID=[[arrayForPromoters objectAtIndex:indexValueOfPromoterEdit] objectForKey:@"requestId"];
                        NSDictionary * json = @{@"requestType":@"RqtAddPromoter",
                                                @"firstName":self.txtFieldFNamePromoter.text,
                                                @"lastName":self.txtFieldLNamePromoter.text,
                                                @"phone":self.txtFieldPhonePromoter.text,
                                                @"address":self.txtVwAddressPromoter.text,
                                                @"emailId":self.txtFieldEmailPromoter.text,
                                                @"productStoreId":storeIDForPromoterAdd,
                                                @"statusId":@"ReqSubmitted",
                                                @"requestTypeEnumId":@"RqtAddPromoter",
                                                @"aadharIdPath":strAadharIDPath,
                                                @"userPhoto":strUserPhotoPath,
                                                @"addressIdPath":strAddressProofPath,
                                                @"description":@"Requesting new Promoter",
                                                @"requestId":rqstID,
                                                };
                        
                        NSString *strEditPath=[NSString stringWithFormat:@"/rest/s1/ft/request/promoter/%@", rqstID];
                        request = [httpClient requestWithMethod:@"PUT"
                                                           path:strEditPath
                                                     parameters:json];
                    }
                    
                    //====================================================RESPONSE
                    [DejalBezelActivityView activityViewForView:self.view];
                    
                    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
                    
                    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
                        
                    }];
                    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                        NSError *error = nil;
                        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
                        
                        [DejalBezelActivityView removeView];
                        NSLog(@"Add Promoter Successfully==%@",JSON);
                        
                        self.vwForPromoterAdd.hidden = YES;
                        self.backBtn.hidden = NO;
                        
                        if (sender.tag == 1){
                            if ([JSON objectForKey:@"request"]) {
                                UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Success" message:@"Promoter Added Successfully" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                [alert show];
                            }
                        }else if (sender.tag == 0){
                            if ([JSON objectForKey:@"request"]) {
                                UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Success" message:@"Promoter Edited Successfully" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                [alert show];
                            }
                        }
                    }
                     //==================================================ERROR
                                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                         [DejalBezelActivityView removeView];
                                                         NSLog(@"Error %@",[error description]);
                                                     }];
                    [operation start];
                }else{
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please Enter Valid Email Id" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                    self.txtFieldEmailPromoter.text=@"";
                }
                
            }else{
                UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"Please Enter All Details" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        }else if([sender.titleLabel.text isEqualToString:@"Approve"]){
            
            [self promoterApproveOrReject:YES];
        }
    }else{
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"It appears you are not connected to internet" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

-(void)promoterApproveOrReject:(BOOL)isApprove{
    
    NSString *requestID;
    
    if ([APPDELEGATE connected]) {
        
        if (![[[arrayForPromoters objectAtIndex:indexValueOfPromoterEdit] valueForKey:@"requestId"] isKindOfClass:[NSNull class]]) {
            requestID=[[arrayForPromoters objectAtIndex:indexValueOfPromoterEdit] valueForKey:@"requestId"];
            NSLog(@"Request ID===%@",requestID);
        }
        
        if (self.txtFieldFNamePromoter.text.length>0&&self.txtFieldLNamePromoter.text.length>0&&self.txtFieldEmailPromoter.text.length>0&&self.txtVwAddressPromoter.text.length>0&&self.txtFieldStoreAsgnmntPromoter.text.length>0&& (![[self.txtVwAddressPromoter text] isEqualToString:@"Address"])) {
            
            if ([self isValidEmail:self.txtFieldEmailPromoter.text]) {
                
                NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
                NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
                NSString *strAuthorization=[defaults valueForKey:@"BasicAuth"];
                
                AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
                httpClient.parameterEncoding = AFFormURLParameterEncoding;
                [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
                [httpClient setDefaultHeader:@"Authorization" value:strAuthorization];
                
                //{"requestId":"100562"}
                
                NSDictionary * json = @{@"requestId":requestID,};
                //100768
                NSString *strPath=[NSString stringWithFormat:@"/rest/s1/ft/request/promoter/reject"];
                //rest/s1/ft/request/promoter/approve
                //rest/s1/ft/request/promoter/reject
                
                if (isApprove) {
                    strPath=[NSString stringWithFormat:@"/rest/s1/ft/request/promoter/approve"];
                }
                
                NSLog(@"Json Request==%@,%@",strPath,json);
                NSMutableURLRequest *request = [httpClient requestWithMethod:@"PUT"
                                                                        path:strPath
                                                                  parameters:json];
                
                
                //====================================================RESPONSE
                [DejalBezelActivityView activityViewForView:self.view];
                
                AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
                
                [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
                    
                }];
                [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                    NSError *error = nil;
                    NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
                    
                    [DejalBezelActivityView removeView];
                    NSLog(@"Promoter Acceptance==%@",JSON);
                    
                    if (isApprove) {
                        [[[UIAlertView alloc] initWithTitle:@""
                                                    message:@"promoter approved successfully"
                                                   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                    }else{
                        [[[UIAlertView alloc] initWithTitle:@""
                                                    message:@"promoter rejected successfully"
                                                   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                    }
                    
                    self.vwForPromoterAdd.hidden = YES;
                    self.backBtn.hidden = NO;
                    
                }
                 //==================================================ERROR
                                                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                     [DejalBezelActivityView removeView];
                                                     NSLog(@"Error %@",[error description]);
                                                     
                                                     NSError *jsonError;
                                                     NSData *objectData = [[[error userInfo] objectForKey:NSLocalizedRecoverySuggestionErrorKey] dataUsingEncoding:NSUTF8StringEncoding];
                                                     
                                                     if (objectData != nil) {
                                                         
                                                         NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                                                                              options:NSJSONReadingMutableContainers
                                                                                                                error:&jsonError];
                                                         
                                                         NSString *strError=[json valueForKey:@"errors"];
                                                         [[[UIAlertView alloc] initWithTitle:@""
                                                                                     message:strError
                                                                                    delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                                                     }
                                                     
                                                 }];
                [operation start];
            }else{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please Enter Valid Email Id" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
                self.txtFieldEmailPromoter.text=@"";
            }
            
        }else{
            UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"Please Enter All Details" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }else{
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"It appears you are not connected to internet" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

-(BOOL)isValidEmail:(NSString *)checkString
{
    BOOL stricterFilter = NO;
    NSString *stricterFilterString = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
    NSString *laxString = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}
#pragma mark - Open Camera

-(void)openCamera:(UIButton*)sender{
    
    if (sender.tag == 100) {
        stringForImagePurpose=@"userPhoto";
    }else if (sender.tag == 200){
        stringForImagePurpose=@"aadharId";
    }else if (sender.tag == 300){
        stringForImagePurpose=@"addressProof";
    }
    //userPhoto aadharId addressProof
    //    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    //    {
    //        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    //        imagePickerController.delegate = self;
    //
    //        imagePickerController.sourceType =UIImagePickerControllerSourceTypeCamera;
    
    if (sender.tag == 100) {
        //           imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        //
        //            UIView *cameraOverlayView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 100.0f, 5.0f, 100.0f, 35.0f)];
        //            [cameraOverlayView setBackgroundColor:[UIColor blackColor]];
        //            UIButton *emptyBlackButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 35.0f)];
        //            [emptyBlackButton setBackgroundColor:[UIColor blackColor]];
        //            [emptyBlackButton setEnabled:YES];
        //            [cameraOverlayView addSubview:emptyBlackButton];
        //            imagePickerController.allowsEditing = YES;
        //            imagePickerController.showsCameraControls = YES;
        //            imagePickerController.cameraOverlayView = cameraOverlayView;
    }else if (sender.tag == 200){
        //            imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    }else if (sender.tag == 300){
        //            imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    }
    //        [self presentViewController:imagePickerController animated:YES completion:^{
    //
    //        }];
    //    }
    NSError *error;
    AVCaptureDevice *captureDevice ;
    if (sender.tag == 100) {
        captureDevice   = [self frontFacingCamera];
    }else if (sender.tag == 200 || sender.tag == 300){
        captureDevice = [self rearFacingCamera];
    }
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (!input)
    {
        NSLog(@"%@", [error localizedDescription]);
    }
    
    // Initialize the captureSession object.
    captureSession = [[AVCaptureSession alloc] init];
    // Set the input device on the capture session.
    [captureSession addInput:input];
    
    // Setup the still image file output
    AVCaptureStillImageOutput *newStillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    AVVideoCodecJPEG, AVVideoCodecKey,
                                    nil];
    [newStillImageOutput setOutputSettings:outputSettings];
    
    if ([captureSession canAddOutput:newStillImageOutput]) {
        [captureSession addOutput:newStillImageOutput];
    }
    //    [self setStillImageOutput:newStillImageOutput];
    stillImageOutput = newStillImageOutput;
    videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
    [videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [videoPreviewLayer setFrame:self.previewCamera.layer.bounds];
    [self.previewCamera.layer addSublayer:videoPreviewLayer];
    [captureSession startRunning];
    self.tabBarController.tabBar.hidden =YES;
    self.vwForCamera.hidden = NO;
    self.backBtn.hidden = NO;
}

- (AVCaptureDevice *)frontFacingCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

- (AVCaptureDevice *)rearFacingCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (IBAction)onClickCamera:(UIButton *)sender {
    
    AVCaptureConnection *videoConnection = nil;
    
    for (AVCaptureConnection *connection in [stillImageOutput connections]){
        for (AVCaptureInputPort *port in [connection inputPorts])        {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] )            {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection)        {
            break;
        }
    }
    
    NSLog(@"About to request a capture from: %@", stillImageOutput);
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error){
        
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
        UIImage *image = [[UIImage alloc] initWithData:imageData];
        imgToSend=image;
        self.vwForCamera.hidden = YES;
        self.backBtn.hidden = YES;
        [self postImageDataToServer];
    }];
    
    self.tabBarController.tabBar.hidden =NO;
}

#pragma mark - ImagePickerDelegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    if([info valueForKey:UIImagePickerControllerOriginalImage]==nil)
    {
    }else{
        imgToSend=[info valueForKey:UIImagePickerControllerOriginalImage];
        [self postImageDataToServer];
        //        [self setImage:[info valueForKey:UIImagePickerControllerOriginalImage]];
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}


-(void)postImageDataToServer
{
    
    [DejalBezelActivityView activityViewForView:self.view];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                   {
                       NSMutableDictionary* _params = [[NSMutableDictionary alloc] init];
                       [_params setObject:stringForImagePurpose forKey:@"purpose"];
                       NSString *BoundaryConstant = @"----------V2ymHFg03ehbqgZCaKO6jy";
                       NSString* FileParamConstant = @"snapshotFile";
                       NSString *stringURL=[NSString stringWithFormat:@"%@/apps/ft/Requests/uploadImage",APPDELEGATE.Base_URL];
                       NSURL* requestURL = [NSURL URLWithString:stringURL];
                       // create request
                       NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
                       [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
                       [request setHTTPShouldHandleCookies:NO];
                       [request setTimeoutInterval:30];
                       [request setHTTPMethod:@"POST"];
                       
                       // set Content-Type in HTTP header
                       NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", BoundaryConstant];
                       [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
                       
                       NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
                       NSString *str=[defaults valueForKey:@"BasicAuth"];
                       [request setValue:str forHTTPHeaderField:@"Authorization"];
                       
                       // post body
                       NSMutableData *body = [NSMutableData data];
                       
                       // add params (all params are strings)
                       for (NSString *param in _params) {
                           [body appendData:[[NSString stringWithFormat:@"--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
                           [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", param] dataUsingEncoding:NSUTF8StringEncoding]];
                           [body appendData:[[NSString stringWithFormat:@"%@\r\n", [_params objectForKey:param]] dataUsingEncoding:NSUTF8StringEncoding]];
                       }
                       
                       // add image data
                       NSData *imageData = UIImageJPEGRepresentation(imgToSend, 0.5);
                       if (imageData) {
                           [body appendData:[[NSString stringWithFormat:@"--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
                           [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"snapshotFile.png\"\r\n", FileParamConstant] dataUsingEncoding:NSUTF8StringEncoding]];
                           [body appendData:[@"Content-Type: pplication/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                           [body appendData:imageData];
                           [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
                       }
                       
                       [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
                       // setting the body of the post to the reqeust
                       [request setHTTPBody:body];
                       // set the content-length
                       NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[body length]];
                       [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
                       // set URL
                       [request setURL:requestURL];
                       
                       dispatch_async(dispatch_get_main_queue(), ^
                                      {
                                          [request setHTTPBody:body];
                                          [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                          NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
                                          NSError *serializeError = nil;
                                          
                                          if (returnData){
                                              NSDictionary *jsonData = [NSJSONSerialization
                                                                        JSONObjectWithData:returnData
                                                                        options:NSJSONReadingMutableContainers
                                                                        error:&serializeError];
                                              NSLog(@"print response after image post : %@",jsonData);
                                              //userPhoto aadharId addressProof
                                              if ([stringForImagePurpose isEqualToString:@"userPhoto"]) {
                                                  strUserPhotoPath=[jsonData valueForKey:@"savedFilename"];
                                                  JSBadgeView *badgeView = [[JSBadgeView alloc] initWithParentView:self.btnPhotoPromoter alignment:JSBadgeViewAlignmentTopRight];
                                                  badgeView.badgeText = [NSString stringWithFormat:@" "];
                                                  
                                              }else if ([stringForImagePurpose isEqualToString:@"aadharId"]){
                                                  strAadharIDPath=[jsonData valueForKey:@"savedFilename"];
                                                  JSBadgeView *badgeView = [[JSBadgeView alloc] initWithParentView:self.btnAadharPromoter alignment:JSBadgeViewAlignmentTopRight];
                                                  badgeView.badgeText = [NSString stringWithFormat:@" "];
                                                  
                                              }else if ([stringForImagePurpose isEqualToString:@"addressProof"]){
                                                  strAddressProofPath=[jsonData valueForKey:@"savedFilename"];
                                                  JSBadgeView *badgeView = [[JSBadgeView alloc] initWithParentView:self.btnAdressProofPromoter alignment:JSBadgeViewAlignmentTopRight];
                                                  badgeView.badgeText = [NSString stringWithFormat:@" "];
                                              }
                                          }
                                          [DejalBezelActivityView removeView];
                                      });
                   });
}
#pragma mark - Leave Request List For Approval


-(void)getLeaveListForApproval
{
    
    if ([APPDELEGATE connected]) {
        
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
        NSString *strAuthorization=[defaults valueForKey:@"BasicAuth"];
        
        AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
        httpClient.parameterEncoding = AFFormURLParameterEncoding;
        [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [httpClient setDefaultHeader:@"Authorization" value:strAuthorization];
        
        NSString *strPath=[NSString stringWithFormat:@"/rest/s1/ft/leaves/requisitions"];
        NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET"
                                                                path:strPath
                                                          parameters:nil];
        //====================================================RESPONSE
        
        [DejalBezelActivityView activityViewForView:self.view];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            
        }];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSError *error = nil;
            NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
            [DejalBezelActivityView removeView];
            
            leaveApprovalListCount = [[JSON valueForKey:@"totalEntries"] integerValue];
            
            if ([[JSON objectForKey:@"employeeLeavesList"] isKindOfClass:[NSArray class]]) {
                if ([[JSON objectForKey:@"employeeLeavesList"] count]>0) {
                    
                    arrayForLeaveApprovalList=[[JSON objectForKey:@"employeeLeavesList"] mutableCopy];
                    
                    //                for (NSDictionary *dict in [JSON objectForKey:@"employeeLeavesList"]) {
                    //                    [arrayForLeaveApprovalList addObject:dict];
                    //                }
                }
            }
            [self.tableVwForLeaveApproval reloadData];
            NSLog(@"Leave List==%@",arrayForLeaveApprovalList);
        }
         //==================================================ERROR
                                         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                             [DejalBezelActivityView removeView];
                                             NSLog(@"Error %@",[error description]);
                                             NSError *jsonError;
                                             NSData *objectData = [[[error userInfo] objectForKey:NSLocalizedRecoverySuggestionErrorKey] dataUsingEncoding:NSUTF8StringEncoding];
                                             
                                             if (objectData != nil) {
                                                 
                                                 NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                                                                      options:NSJSONReadingMutableContainers
                                                                                                        error:&jsonError];
                                                 
                                                 NSString *strError=[json valueForKey:@"errors"];
                                                 [[[UIAlertView alloc] initWithTitle:@""
                                                                             message:strError
                                                                            delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                                             }
                                             
                                         }];
        [operation start];
    }else{
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"It appears you are not connected to internet" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - Leave Rqst

-(void)enableLeaveRequestFields{
    self.heightOfScrollVwForLeaveRqst.constant = 330;
    self.btnLeaveStartDate.userInteractionEnabled = YES;
    self.btnLeaveEndDate.userInteractionEnabled = YES;
    self.btnLeaveType.userInteractionEnabled = YES;
    self.btnLeaveReason.userInteractionEnabled = YES;
    self.txtFieldLeaveDescription.userInteractionEnabled = YES;
    self.txtFieldLeaveComments.userInteractionEnabled = NO;
    self.txtFieldLeaveComments.hidden=YES;
    self.bottomImgForLeaveComments.hidden = YES;
}

-(void)disableLeaveRequestFields{
    self.heightOfScrollVwForLeaveRqst.constant = 380;
    self.btnLeaveStartDate.userInteractionEnabled = NO;
    self.btnLeaveEndDate.userInteractionEnabled = NO;
    self.btnLeaveType.userInteractionEnabled = NO;
    self.btnLeaveReason.userInteractionEnabled = NO;
    self.txtFieldLeaveDescription.userInteractionEnabled = NO;
    self.txtFieldLeaveComments.userInteractionEnabled = YES;
    self.txtFieldLeaveComments.hidden=NO;
    self.bottomImgForLeaveComments.hidden = NO;
}

-(void)leaveRequestEdit:(NSInteger)indexValue{
    
    NSString *startDate=[[[arrayForLeaveHistory objectAtIndex:indexValue]valueForKey:@"fromDate"] substringToIndex:10];
    
    
    NSString *endDate=[[[arrayForLeaveHistory objectAtIndex:indexValue]valueForKey:@"thruDate"] substringToIndex:10];
    
    
    if (![[[arrayForLeaveHistory objectAtIndex:indexValue]valueForKey:@"fromDate"] isKindOfClass:[NSNull class]]) {
        startDate=[self convertLeaveDate:[[arrayForLeaveHistory objectAtIndex:indexValue]valueForKey:@"fromDate"]];
    }
    
    if (![[[arrayForLeaveHistory objectAtIndex:indexValue]valueForKey:@"thruDate"] isKindOfClass:[NSNull class]]) {
        endDate=[self convertLeaveDate:[[arrayForLeaveHistory objectAtIndex:indexValue]valueForKey:@"thruDate"]];
    }
    
    startDate=[startDate substringToIndex:10];
    endDate=[endDate substringToIndex:10];
    
    self.txtFieldStartDate.text=[NSString stringWithFormat:@"%@",startDate];
    self.txtFieldEndDate.text=[NSString stringWithFormat:@"%@",endDate];
    
    
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    [f setDateFormat:@"yyyy-MM-dd"];
    NSDate *start = [f dateFromString:startDate];
    NSDate *end = [f dateFromString:endDate];
    
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                        fromDate:start
                                                          toDate:end
                                                         options:0];
    if ([components day] >= 0){
        self.lblForNoOfDays.text=[NSString stringWithFormat:@"%i",[components day]+1];
    }
    self.txtFieldLeaveDescription.text=[[arrayForLeaveHistory objectAtIndex:indexValue] valueForKey:@"description"];
}


-(void)getLeaveType:(NSUInteger)indexValue{
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
    NSString *strAuthorization=[defaults valueForKey:@"BasicAuth"];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    httpClient.parameterEncoding = AFFormURLParameterEncoding;
    [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [httpClient setDefaultHeader:@"Authorization" value:strAuthorization];
    
    NSString *strPath=@"/rest/s1/ft/leaves/types";
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET"
                                                            path:strPath
                                                      parameters:nil];
    
    //====================================================RESPONSE
    [DejalBezelActivityView activityViewForView:self.view];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
    }];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError *error = nil;
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
        [DejalBezelActivityView removeView];
        dictForLeaveTypes=[[NSDictionary alloc] init];
        dictForLeaveTypes=JSON;
        NSLog(@"Leave Types===%@",dictForLeaveTypes);
        
        if ([arrayForLeaveHistory count] > 0)
        {
 
            NSString *strLeaveType=[[arrayForLeaveHistory objectAtIndex:indexValue] valueForKey:@"leaveTypeEnumId"];
         for (NSDictionary *dict in [dictForLeaveTypes objectForKey:@"leaveTypeEnumId"]) {
            if ([strLeaveType isEqualToString:[dict valueForKey:@"enumId"]]) {
                self.txtFieldLeaveType.text=[dict valueForKey:@"description"];
                leaveTypeEnumID=[dict valueForKey:@"enumId"];
            }
        }
        NSString *strLeaveReason=[[arrayForLeaveHistory objectAtIndex:indexValue] valueForKey:@"leaveReasonEnumId"];
        
        for (NSDictionary *dict in [dictForLeaveTypes objectForKey:@"leaveReasonEnumId"]) {
            if ([strLeaveReason isEqualToString:[dict valueForKey:@"enumId"]]) {
                self.txtFieldLeaveReason.text=[dict valueForKey:@"description"];
                leaveReasonEnumID=[dict valueForKey:@"enumId"];
            }
        }
            
        }else{
            [self.tableVwForLeaveRqst reloadData];
        }
    }
     //==================================================ERROR
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         [DejalBezelActivityView removeView];
                                         NSLog(@"Error %@",[error description]);
                                     }];
    [operation start];
}


- (void)refreshFooterForLeave
{
    if(pageNumberForLeave < countForLeaveData){
        pageNumberForLeave++;
        [self getMyLeaveHistory];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableVwForLeaveRqst reloadData];
            [self.tableVwForLeaveRqst footerEndRefreshing];
            //        [self.tableVw removeFooter];
        });
    }else{
        [self.tableVwForLeaveRqst footerEndRefreshing];
        [self.tableVwForLeaveRqst headerEndRefreshing];
    }
}

-(void)getMyLeaveHistory
{
    if ([APPDELEGATE connected]) {
        
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
        NSString *strAuthorization=[defaults valueForKey:@"BasicAuth"];
        
        AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
        httpClient.parameterEncoding = AFFormURLParameterEncoding;
        [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [httpClient setDefaultHeader:@"Authorization" value:strAuthorization];
        
        NSString *strPath=[NSString stringWithFormat:@"/rest/s1/ft/leaves/my/list?pageIndex=%i&pageSize=10",pageNumberForLeave];
        NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET"
                                                                path:strPath
                                                          parameters:nil];
        //====================================================RESPONSE
        if (pageNumberForLeave == 0) {
            [DejalBezelActivityView activityViewForView:self.view];
        }
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            
        }];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSError *error = nil;
            NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
            
            if (pageNumberForLeave == 0) {
                [DejalBezelActivityView removeView];
            }
            
            countForLeaveData = [[JSON valueForKey:@"totalEntries"] integerValue];
            
            if ([[JSON objectForKey:@"employeeLeavesList"] isKindOfClass:[NSArray class]]) {
                if ([[JSON objectForKey:@"employeeLeavesList"] count]>0) {
                    
                    for (NSDictionary *dict in [JSON objectForKey:@"employeeLeavesList"]) {
                        [arrayForLeaveHistory addObject:dict];
                    }
                }
            }
            [self.tableVwForLeaveRqst reloadData];
            NSLog(@"Leave List==%@",arrayForLeaveHistory);
        }
         //==================================================ERROR
                                         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                             [DejalBezelActivityView removeView];
                                             NSLog(@"Error %@",[error description]);
                                             NSError *jsonError;
                                             NSData *objectData = [[[error userInfo] objectForKey:NSLocalizedRecoverySuggestionErrorKey] dataUsingEncoding:NSUTF8StringEncoding];
                                             
                                             if (objectData != nil) {
                                                 
                                                 NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                                                                      options:NSJSONReadingMutableContainers
                                                                                                        error:&jsonError];
                                                 
                                                 NSString *strError=[json valueForKey:@"errors"];
                                                 [[[UIAlertView alloc] initWithTitle:@""
                                                                             message:strError
                                                                            delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                                             }
                                             
                                         }];
        [operation start];
    }else{
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"It appears you are not connected to internet" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}
-(void)onClickToday{
    [datePicker scrollToToday:YES];
}

-(void)leaveRequestSubmit:(UIButton*)sender{
    //{"leaveTypeEnumId":"EltEarned","leaveReasonEnumId":"ElrMedical","description":"Hau hona","fromDate":"2017-01-20","thruDate":"2017-01-25","organizationId":"ORG_OPPO"}
    ///rest/s1/ft/leaves
    
    if (![sender.titleLabel.text isEqualToString:@"Approve"]) {
        
        if (self.txtFieldStartDate.text.length>0 && self.txtFieldEndDate.text.length>0&&self.txtFieldLeaveReason.text.length>0 && self.txtFieldLeaveType.text.length>0 && self.txtFieldLeaveDescription.text.length>0) {
            
            NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
            NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
            NSString *strAuthorization=[defaults valueForKey:@"BasicAuth"];
            
            AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
            httpClient.parameterEncoding = AFJSONParameterEncoding;
            [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
            [httpClient setDefaultHeader:@"Authorization" value:strAuthorization];
            
            NSDictionary * json;
            NSMutableURLRequest *request;
            
            
            NSDate *now = [NSDate date];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ssZ";
            [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
            NSTimeZone *timeZone = [NSTimeZone localTimeZone];
            NSString *tzName = [timeZone name];
            
          //  NSLog(@"The Current Time is %@====%@",[dateFormatter stringFromDate:now],tzName);
            NSString *strCurrentTime=[dateFormatter stringFromDate:now];
            strCurrentTime = [strCurrentTime stringByReplacingOccurrencesOfString:@" " withString:@"T"];
            
            
            NSLog(@"%@",[strCurrentTime substringFromIndex:10]);
            
            NSString *strStartDate=[NSString stringWithFormat:@"%@%@",self.txtFieldStartDate.text,[strCurrentTime substringFromIndex:10]];
            NSString *strEndDate=[NSString stringWithFormat:@"%@%@",self.txtFieldEndDate.text,[strCurrentTime substringFromIndex:10]];
            
            
            if (isLeaveEditRNew) {
                json = @{@"leaveTypeEnumId":leaveTypeEnumID,
                         @"leaveReasonEnumId":leaveReasonEnumID,
                         @"description":self.txtFieldLeaveDescription.text,
                         @"fromDate":strStartDate,
                         @"thruDate":strEndDate,
                         @"organizationId":@"ORG_OPPO",
                         };
                
                request = [httpClient requestWithMethod:@"POST"
                                                   path:@"/rest/s1/ft/leaves"
                                             parameters:json];
                
                NSLog(@"Json URL---POST===%@",json);
            }else if (!isLeaveEditRNew){
                
                NSString *partyRelationshipId=[[arrayForLeaveHistory objectAtIndex:indexValueForLeaveEdit] valueForKey:@"partyRelationshipId"];
                
                json = @{@"leaveTypeEnumId":leaveTypeEnumID,
                         @"leaveReasonEnumId":leaveReasonEnumID,
                         @"description":self.txtFieldLeaveDescription.text,
                         @"fromDate":strStartDate,
                         @"thruDate":strEndDate,
                         @"partyRelationshipId":partyRelationshipId,
                         };
                
                request = [httpClient requestWithMethod:@"PUT"
                                                   path:@"/rest/s1/ft/leaves"
                                             parameters:json];
                NSLog(@"Json URL---PUT===%@",json);
            }
            
            //====================================================RESPONSE
            [DejalBezelActivityView activityViewForView:self.view];
            
            AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
            [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            }];
            [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSError *error = nil;
                NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
                [DejalBezelActivityView removeView];
                NSLog(@"Leave Request==%@ %ld",JSON,(long)[[operation response] statusCode]);
                
                self.backBtn.hidden = NO;
                self.vwForLeaveRqstAdd.hidden = YES;
                if ([JSON objectForKey:@"employeeLeave"] && isLeaveEditRNew) {
                    
                    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Success" message:@"Leave requested successfully" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                }else{
                    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Success" message:@"Leave edited successfully" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                }
            }
             //==================================================ERROR
                                             failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 [DejalBezelActivityView removeView];
                                                 NSLog(@"Error %@",[error description]);
                                                 NSString *JSON = [[error userInfo] valueForKey:NSLocalizedRecoverySuggestionErrorKey] ;
                                                 
                                                 if (JSON.length>0) {
                                                     
                                                     NSError *aerror = nil;
                                                     NSDictionary *json = [NSJSONSerialization JSONObjectWithData: [JSON dataUsingEncoding:NSUTF8StringEncoding]
                                                                                                          options: NSJSONReadingMutableContainers
                                                                                                            error: &aerror];
                                                     
                                                     NSLog(@"Error %@",json);
                                                     
                                                     if ([[operation response] statusCode] == 500) {
                                                         UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:[json valueForKey:@"errors"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                                         [alert show];
                                                     }
                                                     
                                                     if (isLeaveEditRNew) {
                                                         
                                                     }
                                                 }
                                                 //You have already applied a leave
                                             }];
            [operation start];
        }else{
            UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"Please Enter All Details" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }else if ([sender.titleLabel.text isEqualToString:@"Approve"]){
        [self approveOrRejectLeave:@"Y"];
    }
}

-(void)onClickLeaveRqst:(UIButton*)btn{
    //        NSLog(@"On Click Leave Request");
    [self enableLeaveRequestFields];
    [self.btnLeaveRqstSubmit setTitle:@"Submit" forState:UIControlStateNormal];
    [self.btnLeaveRqstCancel setTitle:@"Cancel" forState:UIControlStateNormal];
    self.backBtn.hidden = YES;
    self.vwForLeaveRqstAdd.hidden = NO;
    
    isLeaveEditRNew=YES;
    [self emptyLeaveRequestFields];
}

-(void)emptyLeaveRequestFields{
    self.lblForNoOfDays.text = 0;
    self.txtFieldStartDate.text=@"";
    self.txtFieldEndDate.text=@"";
    self.txtFieldLeaveType.text=@"";
    self.txtFieldLeaveReason.text=@"";
    self.txtFieldLeaveDescription.text=@"";
}
-(void)leaveRqstCancel:(UIButton*)sender{
    
    if (![sender.titleLabel.text isEqualToString:@"Reject"]) {
        self.backBtn.hidden = NO;
        self.vwForLeaveRqstAdd.hidden = YES;
    }else if([sender.titleLabel.text isEqualToString:@"Reject"]){
        [self approveOrRejectLeave:@"N"];
    }
}

-(void)leaveRqstEdit{
    
}

- (IBAction)onClickLeaveStartDate:(UIButton *)sender{
    
    self.lblForDateStartEnd.text=@"Pick a Start Date";
    self.backBtn.hidden = NO;
    isStartOrEndDate = YES;
    self.vwForCalendar.hidden = NO;
}

- (IBAction)onClickLeaveEndDate:(UIButton *)sender{
    self.lblForDateStartEnd.text=@"Pick an End Date";
    self.backBtn.hidden = NO;
    isStartOrEndDate = NO;
    self.vwForCalendar.hidden = NO;
}

- (void)hasDatePickerPickedDate:(NSDate *)date{
    
    NSDateFormatter *dateFormater = [NSDateFormatter new];
    dateFormater.dateFormat = @"yyyy-MM-dd";
    
    NSString *dateTime= [dateFormater stringFromDate:date];
    NSLog(@"Selected Time====%@",dateTime);
    self.tabBarController.tabBar.hidden =NO;
    
    if (isStartOrEndDate) {
        self.txtFieldStartDate.text=dateTime;
    }
    else{
        self.txtFieldEndDate.text = dateTime;
    }
    
    if (self.txtFieldStartDate.text.length > 0 && self.txtFieldEndDate.text.length > 0){
        NSString *start = self.txtFieldStartDate.text;
        NSString *end = self.txtFieldEndDate.text;
        
        NSDateFormatter *f = [[NSDateFormatter alloc] init];
        [f setDateFormat:@"yyyy-MM-dd"];
        NSDate *startDate = [f dateFromString:start];
        NSDate *endDate = [f dateFromString:end];
        
        NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                            fromDate:startDate
                                                              toDate:endDate
                                                             options:0];
        // NSLog(@"Number Of Days===%i",[components day]);
        self.lblForNoOfDays.textAlignment =NSTextAlignmentCenter;
        if ([components day] >= 0){
            self.lblForNoOfDays.text=[NSString stringWithFormat:@"%i",[components day]+1];
        }
    }
    
    self.vwForCalendar.hidden = YES;
    self.backBtn.hidden = YES;
}


-(void)approveOrRejectLeave:(NSString*)status{
    
    if ([APPDELEGATE connected]) {
        
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
        NSString *strAuthorization=[defaults valueForKey:@"BasicAuth"];
        
        AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
        httpClient.parameterEncoding = AFJSONParameterEncoding;
        [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [httpClient setDefaultHeader:@"Authorization" value:strAuthorization];
        
        NSDictionary * json;
        NSMutableURLRequest *request;
        
        NSDate *now = [NSDate date];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ssZ";
        [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
        NSTimeZone *timeZone = [NSTimeZone localTimeZone];
        NSString *tzName = [timeZone name];
        
       // NSLog(@"The Current Time is %@====%@",[dateFormatter stringFromDate:now],tzName);
        NSString *strCurrentTime=[dateFormatter stringFromDate:now];
        strCurrentTime = [strCurrentTime stringByReplacingOccurrencesOfString:@" " withString:@"T"];
        
        NSLog(@"%@",[strCurrentTime substringFromIndex:10]);
        
        //    NSString *strStartDate=[NSString stringWithFormat:@"%@%@",self.txtFieldStartDate.text,[strCurrentTime substringFromIndex:10]];
        //    NSString *strEndDate=[NSString stringWithFormat:@"%@%@",self.txtFieldEndDate.text,[strCurrentTime substringFromIndex:10]];
        
        NSString *strStartDate=[NSString stringWithFormat:@"%@",self.txtFieldStartDate.text];
        NSString *strEndDate=[NSString stringWithFormat:@"%@",self.txtFieldEndDate.text];
        
        NSString *partyRelationshipId=[[arrayForLeaveHistory objectAtIndex:indexValueForLeaveEdit] valueForKey:@"partyRelationshipId"];
        
        json = @{@"leaveTypeEnumId":leaveTypeEnumID,
                 @"leaveReasonEnumId":leaveReasonEnumID,
                 @"description":self.txtFieldLeaveDescription.text,
                 @"fromDate":strStartDate,
                 @"thruDate":strEndDate,
                 @"partyRelationshipId":partyRelationshipId,
                 @"leaveApproved":status
                 };
        //{"partyRelationshipId" : "100153",  "fromDate" : "1484245800000", "thruDate" : "2017-01-14", "leaveTypeEnumId" : "EltEarned", "leaveReasonEnumId" : "ElrMedical", "leaveApproved" : "Y", "description" : "Test" }
        request = [httpClient requestWithMethod:@"PUT"
                                           path:@"/rest/s1/ft/updateLeave"
                                     parameters:json];
        NSLog(@"Json URL---PUT===%@",json);
        //====================================================RESPONSE
        [DejalBezelActivityView activityViewForView:self.view];
        
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        }];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSError *error = nil;
            NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
            [DejalBezelActivityView removeView];
            NSLog(@"Leave Request==%@ %ld",JSON,(long)[[operation response] statusCode]);
            if ([[operation response] statusCode] == 200) {
                UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:[json valueForKey:@"messages"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
            self.backBtn.hidden = NO;
            self.vwForLeaveRqstAdd.hidden = YES;
        }
         //==================================================ERROR
                                         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                             [DejalBezelActivityView removeView];
                                             NSLog(@"Error %@",[error description]);
                                             NSString *JSON = [[error userInfo] valueForKey:NSLocalizedRecoverySuggestionErrorKey] ;
                                             
                                             if (JSON.length>0) {
                                                 
                                                 NSError *aerror = nil;
                                                 NSDictionary *json = [NSJSONSerialization JSONObjectWithData: [JSON dataUsingEncoding:NSUTF8StringEncoding]
                                                                                                      options: NSJSONReadingMutableContainers
                                                                                                        error: &aerror];
                                                 NSLog(@"Error %@",json);
                                                 //                                             if ([[operation response] statusCode] == 500) {
                                                 UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:[json valueForKey:@"errors"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                                 [alert show];
                                                 if (isLeaveEditRNew) {
                                                     
                                                 }
                                             }
                                             //You have already applied a leave
                                         }];
        [operation start];
    }else{
        
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"It appears you are not connected to internet" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - Custom Calendar
// Returns YES if the date should be highlighted or NO if it should not.
- (BOOL)datePickerView:(RSDFDatePickerView *)view shouldHighlightDate:(NSDate *)date
{
    return YES;
}

// Returns YES if the date should be selected or NO if it should not.
- (BOOL)datePickerView:(RSDFDatePickerView *)view shouldSelectDate:(NSDate *)date
{
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = 1;
    
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    NSDate *nextDate = [theCalendar dateByAddingComponents:dayComponent toDate:date options:0];
    NSString *selectedDate=[nextDate description];
    //    NSLog(@"%@", [selectedDate substringToIndex:10]);
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *string = [formatter stringFromDate:[NSDate date]];
    NSDate *date1= [formatter dateFromString:[selectedDate substringToIndex:10]];
    NSDate *currentDate = [formatter dateFromString:string];
    NSComparisonResult result = [date1 compare:currentDate];
    if(result == NSOrderedDescending){
        //        NSLog(@"Selected Date is greater than current Date");
        [self hasDatePickerPickedDate:date];
        return YES;
    }else if(result == NSOrderedAscending){
        //        NSLog(@"Selected Date  is earlier than current date");
        return NO;
    }
    else{
        //        NSLog(@"dates are the same");
        [self hasDatePickerPickedDate:date];
        return YES;
    }
    return YES;
}

// Prints out the selected date.
- (void)datePickerView:(RSDFDatePickerView *)view didSelectDate:(NSDate *)date
{
    //    NSLog(@"%@", [date description]);
}

// Returns YES if the date should be marked or NO if it should not.
- (BOOL)datePickerView:(RSDFDatePickerView *)view shouldMarkDate:(NSDate *)date
{
    // The date is an `NSDate` object without time components.
    // So, we need to use dates without time components.
    NSCalendar *calendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    NSDateComponents *todayComponents = [calendar components:unitFlags fromDate:[NSDate date]];
    NSDate *today = [calendar dateFromComponents:todayComponents];
    return [date isEqual:today];
}
// Returns the color of the default mark image for the specified date.
- (UIColor *)datePickerView:(RSDFDatePickerView *)view markImageColorForDate:(NSDate *)date
{
    if (arc4random() % 2 == 0) {
        return [UIColor grayColor];
    } else {
        return [UIColor greenColor];
    }
}

// Returns the mark image for the specified date.
- (UIImage *)datePickerView:(RSDFDatePickerView *)view markImageForDate:(NSDate *)date
{
    if (arc4random() % 2 == 0) {
        return [UIImage imageNamed:@"img_gray_mark"];
    } else {
        return [UIImage imageNamed:@"img_green_mark"];
    }
}

#pragma mark - Leave Dates Converted
-(NSString*)convertLeaveDate:(NSString*)dateChange{
    
    dateChange=[dateChange stringByReplacingOccurrencesOfString:@"T" withString:@" "];
    dateChange=[dateChange stringByReplacingOccurrencesOfString:@"+0000" withString:@" +0000"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss Z";
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    NSDate *daate=[dateFormatter dateFromString:dateChange];
    
    NSTimeZone *tz = [NSTimeZone localTimeZone];
    NSInteger seconds = [tz secondsFromGMTForDate:daate];
    daate = [NSDate dateWithTimeInterval: seconds sinceDate: daate];
    dateChange=[NSString stringWithFormat:@"%@",daate];
    
    return dateChange;
}


#pragma mark- UITableView

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    if (tableView==self.tableVwForStore) {
        return arrayForStoreList.count;
    }else if (tableView == self.tableVwForPromoters){
        return arrayForPromoters.count;
    }else if (tableView == self.tableVwForLeaveRqst){
        return arrayForLeaveHistory.count;
    }else if (tableView == self.tableVwForLeaveApproval){
        return arrayForLeaveApprovalList.count;
    }else if (tableView == self.tableVwForReporties) {
        return arrayForReportee.count;
    }else if (tableView == self.tableVwForReportiesHistory) {
        return arrayForReporteeHistory.count;
    }else if (tableView == self.tableVwForIndividualHistory){
        return arrayForReporteeStatusData.count;
    }
    return arrayForTableData.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (tableView == self.tableVwForReporties) {
        MKAgentListCell *cell=[tableView dequeueReusableCellWithIdentifier:@"Cell"];
        if (cell==nil) {
            cell=[[MKAgentListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        
        if ([[arrayForReportee objectAtIndex:indexPath.row] valueForKey:@"userFullName"]) {
            if (![[[arrayForReportee objectAtIndex:indexPath.row] valueForKey:@"userFullName"] isKindOfClass:[NSNull class]]) {
                cell.lblFieldAgentName.text=[[arrayForReportee objectAtIndex:indexPath.row] valueForKey:@"userFullName"];
            }
        }
        cell.lblStoreLocation.text=@"";
        if ([[arrayForReportee objectAtIndex:indexPath.row] objectForKey:@"locations"]) {
            if (![[[arrayForReportee objectAtIndex:indexPath.row] objectForKey:@"locations"] isKindOfClass:[NSNull class]]) {
                cell.lblStoreLocation.text=[[[arrayForReportee objectAtIndex:indexPath.row] objectForKey:@"locations"] objectAtIndex:0];
            }
        }
        
        cell.lblStatus.text=@"";
        return cell;
    }
    
    if (tableView == self.tableVwForReportiesHistory) {
        
        MKHistoryCustomCell *cell=[tableView dequeueReusableCellWithIdentifier:@"Cell"];
        
        if (cell==nil) {
            cell=[[MKHistoryCustomCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        
        NSMutableArray *array=[[NSMutableArray alloc] init];
        NSInteger   hoursBetweenDates = 0;
        
        ///Date Parsing
        NSString *strDate=[[arrayForReporteeHistory objectAtIndex:indexPath.row]valueForKey:@"estimatedCompletionDate"];
        NSRange range = [strDate rangeOfString:@"T"];
        strDate=[strDate substringToIndex:NSMaxRange(range)-1];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        NSDate *date = [dateFormatter dateFromString:strDate];
        [dateFormatter setDateFormat:@"dd-MMM-yyyy"];
        NSString *newDateString = [dateFormatter stringFromDate:date];
        cell.lblDate.text=newDateString;
        
        
        if ([[[arrayForReporteeHistory objectAtIndex:indexPath.row]objectForKey:@"timeEntryList"] isKindOfClass:[NSArray class]]) {
            
            if ([[[arrayForReporteeHistory objectAtIndex:indexPath.row]objectForKey:@"timeEntryList"] count]>0) {
                
                for (NSDictionary *dict in [[arrayForReporteeHistory objectAtIndex:indexPath.row] objectForKey:@"timeEntryList"]) {
                    [array addObject:[dict valueForKey:@"fromDate"]];
                    [array addObject:[dict valueForKey:@"thruDate"]];
                }
                
                array =  [self sortingArrayByDate:array];
                
                if (![[array objectAtIndex:0] isKindOfClass:[NSNull class]]) {
                    cell.lblInTime.text=[NSString stringWithFormat:@"Time In: %@",[self getTimeIndividual:[array objectAtIndex:0] ]];
                }
                else{
                    cell.lblInTime.text=[NSString stringWithFormat:@"Time In: --"];
                }
                
                if (![[array lastObject]  isKindOfClass:[NSNull class]] ) {
                    cell.lblOutTime.text=[NSString stringWithFormat:@"Time Out: %@",[self getTimeIndividual:[array lastObject] ]];
                }else{
                    cell.lblOutTime.text=[NSString stringWithFormat:@"Time Out: --"];
                }
                
                if (![[array objectAtIndex:0] isKindOfClass:[NSNull class]] && ![[array lastObject] isKindOfClass:[NSNull class]]){
                    
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    
                    NSString *firstViewd;
                    firstViewd=[NSString stringWithFormat:@"%@",[array objectAtIndex:0]];
                    NSString *lastViewedString;
                    lastViewedString=[NSString stringWithFormat:@"%@",[array lastObject]];
                    [dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss xxxx"];
                    NSDate *lastViewed = [dateFormatter dateFromString:lastViewedString];
                    NSDate *now = [dateFormatter dateFromString:firstViewd];
                    NSTimeInterval distanceBetweenDates = [lastViewed timeIntervalSinceDate:now];
                    double minutesInAnHour = 60;
                    hoursBetweenDates = hoursBetweenDates + (distanceBetweenDates / minutesInAnHour);
                    int hour = hoursBetweenDates / 60;
                    int min = hoursBetweenDates % 60;
                    hour=abs(hour);
                    min = abs(min);
                    NSString *timeString = [NSString stringWithFormat:@"%dh %02dm", hour, min];
                    //    NSLog(@"Total Time: %@", timeString);
                    if (hour<0) {
                        cell.lblTotalTime.text=[NSString stringWithFormat:@"--"];
                    }else{
                        cell.lblTotalTime.text=timeString;
                    }
                    if ([timeString isEqualToString:@"0h 00m"]) {
                        cell.lblTotalTime.text=[NSString stringWithFormat:@"0h 01m"];
                    }
                }else{
                    cell.lblTotalTime.text=[NSString stringWithFormat:@"--"];
                }
            }else{
                cell.lblTotalTime.text=[NSString stringWithFormat:@"--"];
                cell.lblInTime.text=[NSString stringWithFormat:@"Time In: --"];
                cell.lblOutTime.text=[NSString stringWithFormat:@"Time Out: --"];
            }
        }else{
            cell.lblTotalTime.text=[NSString stringWithFormat:@"--"];
            cell.lblInTime.text=[NSString stringWithFormat:@"Time In: --"];
            cell.lblOutTime.text=[NSString stringWithFormat:@"Time Out: --"];
        }
        
        return cell;
    }
    
    if (tableView == self.tableVwForIndividualHistory) {
        MKIndividualHistoryCell *cell=[tableView dequeueReusableCellWithIdentifier:@"Cell"];
        if (cell == nil) {
            cell=[[MKIndividualHistoryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        /*
         ////Image Names
         dot_login rgb(48,174,242)
         dot_inlocation rgb(78,242,48)
         dot_outlocation  rgb(242,105,48)
         dot_timeout rgb(90,90,90)
         */
        
        cell.imgVwForStatusIcon.layer.cornerRadius = cell.imgVwForStatusIcon.frame.size.height/2;
        cell.imgVwForStatusIcon.layer.masksToBounds = YES;
        
        if (indexPath.row==0) {
            cell.imgVwForStatusIcon.image=[UIImage imageNamed:@""];
            cell.imgVwForStatusIcon.backgroundColor=[UIColor colorWithRed:(48/255.0) green:(174/255.0) blue:(242/255.0) alpha:1.0];
            
            cell.lblForStatus.text=@"Time In";
            cell.centerConstraint.constant = 0;
            cell.imgVwForTopVerticalLine.hidden=YES;
            cell.imgVwForBtmVerticalLine.hidden=NO;
        }else{
            if (indexPath.row % 2 == 0) {
                cell.imgVwForStatusIcon.image=[UIImage imageNamed:@""];
                cell.imgVwForStatusIcon.backgroundColor=[UIColor colorWithRed:(78/255.0) green:(242/255.0) blue:(48/255.0) alpha:1.0];
                
                cell.lblForStatus.text=@"In location";
                cell.centerConstraint.constant = -2;
            }else{
                cell.centerConstraint.constant = 2;
                cell.imgVwForStatusIcon.image=[UIImage imageNamed:@""];
                cell.imgVwForStatusIcon.backgroundColor=[UIColor colorWithRed:(242/255.0) green:(105/255.0) blue:(48/255.0) alpha:1.0];
                cell.lblForStatus.text=@"Out of location";
            }
            cell.imgVwForTopVerticalLine.hidden=NO;
            cell.imgVwForBtmVerticalLine.hidden=NO;
        }
        
        if (indexPath.row==arrayForReporteeStatusData.count-1){
            cell.centerConstraint.constant = 0;
            cell.imgVwForStatusIcon.image=[UIImage imageNamed:@""];
            cell.imgVwForStatusIcon.backgroundColor=[UIColor colorWithRed:(90/255.0) green:(90/255.0) blue:(90/255.0) alpha:1.0];
            
            cell.lblForStatus.text=@"Time Out";
            cell.imgVwForTopVerticalLine.hidden=NO;
            cell.imgVwForBtmVerticalLine.hidden=YES;
        }
        
        cell.imgVwForLine.backgroundColor=[UIColor lightGrayColor];
        
        if (![[arrayForReporteeStatusData objectAtIndex:indexPath.row] isKindOfClass:[NSNull class]]) {
            cell.lblForTime.text= [self getTimeIndividual:[arrayForReporteeStatusData objectAtIndex:indexPath.row]];
        }else{
            cell.lblForTime.text=@"";
            cell.imgVwForStatusIcon.image=[UIImage imageNamed:@""];
            cell.lblForStatus.text=@"";
            cell.imgVwForLine.backgroundColor=[UIColor clearColor];
        }
        
        
        return cell;
    }
    
    if (tableView == self.tableVwForLeaveRqst || tableView == self.tableVwForLeaveApproval){
        
        MKCustomCellForLeave *cellLeave=[tableView dequeueReusableCellWithIdentifier:@"Cell"];
        if (cellLeave == nil) {
            cellLeave=[[MKCustomCellForLeave alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        }
        cellLeave.selectionStyle = UITableViewCellSelectionStyleNone;
        
        NSString *startDate;
        NSString *endDate;
        NSString *strLeaveApprove;
        
        if (tableView == self.tableVwForLeaveApproval){
            
            if (![[[arrayForLeaveApprovalList objectAtIndex:indexPath.row]valueForKey:@"fromDate"] isKindOfClass:[NSNull class]]) {
                startDate=[self convertLeaveDate:[[arrayForLeaveApprovalList objectAtIndex:indexPath.row]valueForKey:@"fromDate"]];
            }
            
            if (![[[arrayForLeaveApprovalList objectAtIndex:indexPath.row]valueForKey:@"thruDate"] isKindOfClass:[NSNull class]]) {
                endDate=[self convertLeaveDate:[[arrayForLeaveApprovalList objectAtIndex:indexPath.row]valueForKey:@"thruDate"]];
            }
            
            startDate=[startDate substringToIndex:10];
            endDate=[endDate substringToIndex:10];
            
            cellLeave.lblForTypeOfLeave.text=@"";
            strLeaveApprove=[[arrayForLeaveApprovalList objectAtIndex:indexPath.row] valueForKey:@"leaveApproved"];
            
            NSString *strFirstName;
            if (![[[arrayForLeaveApprovalList objectAtIndex:indexPath.row] valueForKey:@"firstName"] isKindOfClass:[NSNull class]]) {
                strFirstName=[[arrayForLeaveApprovalList objectAtIndex:indexPath.row] valueForKey:@"firstName"];
            }
            
            NSString *strLastName;
            if (![[[arrayForLeaveApprovalList objectAtIndex:indexPath.row] valueForKey:@"lastName"] isKindOfClass:[NSNull class]]) {
                strLastName=[[arrayForLeaveApprovalList objectAtIndex:indexPath.row] valueForKey:@"lastName"];
            }
            
            cellLeave.lblForName.text=[NSString stringWithFormat:@"%@ %@",strFirstName,strLastName];
            
        }else{
            
            
            if (![[[arrayForLeaveHistory objectAtIndex:indexPath.row]valueForKey:@"fromDate"] isKindOfClass:[NSNull class]]) {
                startDate=[self convertLeaveDate:[[arrayForLeaveHistory objectAtIndex:indexPath.row]valueForKey:@"fromDate"]];
            }
            
            if (![[[arrayForLeaveHistory objectAtIndex:indexPath.row]valueForKey:@"thruDate"] isKindOfClass:[NSNull class]]) {
                endDate=[self convertLeaveDate:[[arrayForLeaveHistory objectAtIndex:indexPath.row]valueForKey:@"thruDate"]];
            }
            
            startDate=[startDate substringToIndex:10];
            endDate=[endDate substringToIndex:10];
            
            cellLeave.lblForTypeOfLeave.text=[NSString stringWithFormat:@"%@",[[[arrayForLeaveHistory objectAtIndex:indexPath.row] valueForKey:@"leaveReasonEnumId"] substringFromIndex:3]];
            
            for (NSDictionary *dict in [dictForLeaveTypes objectForKey:@"leaveReasonEnumId"]){
                if ([[[arrayForLeaveHistory objectAtIndex:indexPath.row] valueForKey:@"leaveReasonEnumId"] isEqualToString:[dict valueForKey:@"enumId"]]) {
                    cellLeave.lblForTypeOfLeave.text=[dict valueForKey:@"description"];
                }
            }
            
            strLeaveApprove=[[arrayForLeaveHistory objectAtIndex:indexPath.row] valueForKey:@"leaveApproved"];
        }
        
        if (![strLeaveApprove isKindOfClass:[NSNull class]]) {
            if ([strLeaveApprove isEqualToString:@"Y"]) {
                cellLeave.lblForStatusOfLeave.text=@"Approved";
            }
        }else{
            cellLeave.lblForStatusOfLeave.text=@"Pending";
        }
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        NSDate *date = [dateFormatter dateFromString:startDate];
        [dateFormatter setDateFormat:@"dd/MM/yyyy"];
        NSString *newDateString = [dateFormatter stringFromDate:date];
        cellLeave.lblForStartDate.text=[NSString stringWithFormat:@"From: %@",newDateString];
        
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        date = [dateFormatter dateFromString:endDate];
        [dateFormatter setDateFormat:@"dd/MM/yyyy"];
        newDateString = [dateFormatter stringFromDate:date];
        cellLeave.lblForEndDate.text=[NSString stringWithFormat:@"To: %@",newDateString];
        
        NSDateFormatter *f = [[NSDateFormatter alloc] init];
        [f setDateFormat:@"yyyy-MM-dd"];
        NSDate *start = [f dateFromString:startDate];
        NSDate *end = [f dateFromString:endDate];
        
        NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                            fromDate:start
                                                              toDate:end
                                                             options:0];
        if ([components day] >= 0){
            if ([components day] == 0) {
                cellLeave.lblForNumOfDays.text=[NSString stringWithFormat:@"%i Day",[components day]+1];
            }else{
                cellLeave.lblForNumOfDays.text=[NSString stringWithFormat:@"%i Days",[components day]+1];
            }
        }
        
        return cellLeave;
    }
    
    if (tableView == self.tableVwForStore){
        //Store List
        if (cell == nil){
            cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        }
        cell.textLabel.text=[[arrayForStoreList objectAtIndex:indexPath.row] valueForKey:@"storeName"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if (tableView == self.tableVwForPromoters){
        // Prpomoter List
        
        MKAgentListCell *cell=[tableView dequeueReusableCellWithIdentifier:@"Cell"];
        
        if (cell == nil){
            cell=[[MKAgentListCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        }
        NSString *jsonString = [[arrayForPromoters objectAtIndex:indexPath.row] objectForKey:@"requestJson"];
        NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        cell.lblFieldAgentName.text=[NSString stringWithFormat:@"%@ %@",[[json objectForKey:@"requestInfo"] valueForKey:@"firstName"],[[json objectForKey:@"requestInfo"] valueForKey:@"lastName"]];
        
        if (![[[arrayForPromoters objectAtIndex:indexPath.row] valueForKey:@"statusId"] isKindOfClass:[NSNull class]]) {
            
            NSString *promoterStatus=[[arrayForPromoters objectAtIndex:indexPath.row] valueForKey:@"statusId"];
            
            if ([promoterStatus containsString:@"Completed"]) {
                //Completed
                cell.lblStatus.text=@"Approved";
            }else if ([promoterStatus containsString:@"Submitted"]){
                //Submitted
                cell.lblStatus.text=@"Pending";
            }else if ([promoterStatus containsString:@"Rejected"]){
                //Rejected
                cell.lblStatus.text=@"Rejected";
            }
        }
        
        NSString *productStoreId=[[json objectForKey:@"requestInfo"] objectForKey:@"productStoreId"];
        
        for (NSDictionary *dict in arrayForStoreList) {
            if ([[dict valueForKey:@"productStoreId"] isEqualToString:productStoreId]) {
                cell.lblStoreLocation.text=[dict valueForKey:@"storeName"];
            }
        }
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    else if (tableView == self.tableVw){
        
        if (cell == nil){
            cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        }
        cell.textLabel.text=[arrayForTableData objectAtIndex:indexPath.row];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (tableView == self.tableVw){
        //arrayForTableData=[[NSMutableArray alloc] initWithObjects:@"Stores",@"Promoters",@"Leaves",@"Leave Requisitions",@"Contact Support",@"My Account",@"Change Password",@"Log Off", nil];
        
        UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
        
        if ([cell.textLabel.text isEqualToString:@"Log Off"]){
            
            //            [[MKSharedClass shareManager] setDictForCheckInLoctn:nil];
            //            NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
            //            [defaults removeObjectForKey:@"UserData"];
            //            [defaults removeObjectForKey:@"StoreData"];
            //            [defaults setObject:@"0" forKey:@"Is_Login"];
            //            [defaults synchronize];
            //            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            //            UIViewController *rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"MainRoot"];
            //            [[UIApplication sharedApplication].keyWindow setRootViewController:rootViewController];
            
            UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"Are You Sure Want To Log Off ?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
            alert.tag = 1001;
            [alert show];
            
            return;
            
        }else if ([cell.textLabel.text isEqualToString:@"Stores"]){
            [self getStores];
            self.vwForStore.hidden =NO;
            self.backBtn.hidden = NO;
            self.tableVwForStore.delegate = self;
            self.tableVwForStore.dataSource = self;
            [self.tableVwForStore reloadData];
            
        }else if ([cell.textLabel.text isEqualToString:@"Promoters"]){
            
            isPromoterOrPromoterApprove=YES;
            arrayForPromoters=[[NSMutableArray alloc] init];
            pageNumber = 0;
            [self getPromoters];
            self.vwForPromoters.hidden =NO;
            self.backBtn.hidden = NO;
            self.tableVwForPromoters.delegate = self;
            self.tableVwForPromoters.dataSource = self;
            [self.tableVwForPromoters reloadData];
            
        }else if ([cell.textLabel.text isEqualToString:@"Promoters Approval"]){
            
            isPromoterOrPromoterApprove=NO;
            arrayForPromoters=[[NSMutableArray alloc] init];
            pageNumber = 0;
            [self getPromotersApproval];
            self.vwForPromoters.hidden =NO;
            self.backBtn.hidden = NO;
            self.tableVwForPromoters.delegate = self;
            self.tableVwForPromoters.dataSource = self;
            [self.tableVwForPromoters reloadData];
        }
        else if ([cell.textLabel.text isEqualToString:@"Leaves"]){
            
            arrayForLeaveHistory=[[NSMutableArray alloc] init];
            pageNumberForLeave = 0;
            [self getLeaveType:0];
            [self getMyLeaveHistory];
            self.vwForLeaveRqst.hidden =NO;
            self.backBtn.hidden = NO;
            self.tableVwForLeaveRqst.delegate = self;
            self.tableVwForLeaveRqst.dataSource = self;
            [self.tableVwForLeaveRqst reloadData];
            [self enableLeaveRequestFields];
            
            [self.btnLeaveRqstSubmit setTitle:@"Submit" forState:UIControlStateNormal];
            [self.btnLeaveRqstCancel setTitle:@"Cancel" forState:UIControlStateNormal];
            
        }else if ([cell.textLabel.text isEqualToString:@"Reporties"]){
            arrayForReportee=[[NSMutableArray alloc] init];
            [self getReportee];
            self.vwForReporties.hidden = NO;
            self.backBtn.hidden = NO;
            self.tableVwForReporties.delegate=self;
            self.tableVwForReporties.dataSource=self;
            [self.tableVwForReporties reloadData];
        }
        else if ([cell.textLabel.text isEqualToString:@"My Account"]){
            self.vwForAccount.hidden =NO;
            self.backBtn.hidden = NO;
        }else if ([cell.textLabel.text isEqualToString:@"Change Password"]){
            self.vwForChangePwd.hidden =NO;
            self.backBtn.hidden = NO;
        }else if ([cell.textLabel.text isEqualToString:@"Contact Support"]){
            [self getContactSupport];
            self.vwForContact.hidden =NO;
            self.backBtn.hidden = NO;
        }else if ([cell.textLabel.text isEqualToString:@"Leave Requisitions"]){
            
            [self getLeaveListForApproval];
            
            self.vwForLeaveRequestForApproval.hidden = NO;
            self.tableVwForLeaveApproval.delegate = self;
            self.tableVwForLeaveApproval.dataSource = self;
            [self.tableVwForLeaveApproval reloadData];
            self.backBtn.hidden = NO;
            
        }
    }else if (tableView == self.tableVwForStore){
        [[MKSharedClass shareManager] setValueForStoreEditVC:0];
        [self goToStorePopup:indexPath.row];
    }
    else if (tableView == self.tableVwForPromoters){
        indexValueOfPromoterEdit=indexPath.row;
        [self promoterDetails:NO];
    }else if (tableView == self.tableVwForLeaveRqst){
        
        NSString *strLeaveApprove=[[arrayForLeaveHistory objectAtIndex:indexPath.row] valueForKey:@"leaveApproved"];
        
        if ([strLeaveApprove isKindOfClass:[NSNull class]]) {
            
            [self emptyLeaveRequestFields];
            [self getLeaveType:indexPath.row];
            indexValueForLeaveEdit=indexPath.row;
            self.backBtn.hidden = YES;
            self.vwForLeaveRqstAdd.hidden = NO;
            isLeaveEditRNew=NO;
            [self leaveRequestEdit:indexPath.row];
            
        }
    }else if (tableView == self.tableVwForLeaveApproval){
        indexValueForLeaveEdit=indexPath.row;
        self.txtFieldLeaveComments.text=@"";
        arrayForLeaveHistory=arrayForLeaveApprovalList;
        [self emptyLeaveRequestFields];
        [self getLeaveType:indexPath.row];
        self.backBtn.hidden = NO;
        self.vwForLeaveRqstAdd.hidden = NO;
        [self.btnLeaveRqstSubmit setTitle:@"Approve" forState:UIControlStateNormal];
        [self.btnLeaveRqstCancel setTitle:@"Reject" forState:UIControlStateNormal];
        [self leaveRequestEdit:indexPath.row];
        [self disableLeaveRequestFields];
    }else if (tableView == self.tableVwForReporties){
        
        strForReporteeUserName=[[arrayForReportee objectAtIndex:indexPath.row] valueForKey:@"username"];
        arrayForReporteeHistory=[[NSMutableArray alloc] init];
        pageNumber = 0;
        self.tableVwForReportiesHistory.delegate=self;
        self.tableVwForReportiesHistory.dataSource=self;
        [self getReporteeHistory];
        
        
    }else if(tableView == self.tableVwForReportiesHistory){
        
        arrayForReporteeStatusData=[[NSMutableArray alloc] init];
        
        for (NSDictionary *dict in [[arrayForReporteeHistory objectAtIndex:indexPath.row] objectForKey:@"timeEntryList"])
        {
            [arrayForReporteeStatusData addObject:[dict valueForKey:@"fromDate"]];
            [arrayForReporteeStatusData addObject:[dict valueForKey:@"thruDate"]];
        }
        
        arrayForReporteeStatusData = [self sortingArrayByDate:arrayForReporteeStatusData];
        
        [self.tableVwForIndividualHistory reloadData];
        [self.tableVwForIndividualHistory setContentOffset:CGPointZero animated:NO];
        
        ///Date Parsing
        NSString *strDate=[[arrayForReporteeHistory objectAtIndex:indexPath.row]valueForKey:@"estimatedCompletionDate"];
        NSRange range = [strDate rangeOfString:@"T"];
        strDate=[strDate substringToIndex:NSMaxRange(range)-1];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        NSDate *date = [dateFormatter dateFromString:strDate];
        [dateFormatter setDateFormat:@"dd-MMM-yyyy"];
        NSString *newDateString = [dateFormatter stringFromDate:date];
        self.lblEntryDate.text=newDateString;
        //////
        
        if ([arrayForReporteeStatusData count]>0) {
            if (![[arrayForReporteeStatusData objectAtIndex:0] isKindOfClass:[NSNull class]]) {
                newDateString = [self getTimeIndividual:[arrayForReporteeStatusData objectAtIndex:0]];
            }else{
                newDateString = @"--";
            }
            
            self.lblTimeIn.text=[NSString stringWithFormat:@"Time In: %@",newDateString];
            
            if (![[arrayForReporteeStatusData lastObject] isKindOfClass:[NSNull class]]) {
                newDateString = [self getTimeIndividual:[arrayForReporteeStatusData lastObject]];
            }else{
                newDateString = @"--";
            }
            
            self.lblTimeOut.text=[NSString stringWithFormat:@"Time Out: %@",newDateString];
        }else{
            self.lblTimeIn.text=[NSString stringWithFormat:@"Time In: --"];
            self.lblTimeOut.text=[NSString stringWithFormat:@"Time Out: --"];
        }
        MKHistoryCustomCell *cell=(MKHistoryCustomCell*)[tableView cellForRowAtIndexPath:indexPath];
        self.lblTotalTime.text = cell.lblTotalTime.text;
        
        self.vwForReportiesIndividualHistory.hidden=NO;
        self.tableVwForIndividualHistory.delegate=self;
        self.tableVwForIndividualHistory.dataSource=self;
        [self.tableVwForIndividualHistory reloadData];
        
    }
}

-(void)goToStorePopup:(NSInteger)indexValue{
    [self setUpForAddStore:indexValue];
    self.vwForStoreAdd.hidden = NO;
}

#pragma mark -

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    
    if (alertView.tag == 1001) {
        
        if (buttonIndex == 0) {
        }else if (buttonIndex == 1){
            
            [[MKSharedClass shareManager] setDictForCheckInLoctn:nil];
            NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
            [defaults removeObjectForKey:@"UserData"];
            [defaults removeObjectForKey:@"StoreData"];
            [defaults setObject:@"0" forKey:@"Is_Login"];
            //            [defaults synchronize];
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            UIViewController *rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"MainRoot"];
            [[UIApplication sharedApplication].keyWindow setRootViewController:rootViewController];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */


#pragma mark - Reportees

- (void)refreshFooterForReportees
{
    if(pageNumber < countForReporteeHistory){
        pageNumber++;
        [self getReporteeHistory];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableVwForReportiesHistory reloadData];
            [self.tableVwForReportiesHistory footerEndRefreshing];
            //        [self.tableVw removeFooter];
        });
    }else{
        [self.tableVwForReportiesHistory footerEndRefreshing];
        [self.tableVwForReportiesHistory headerEndRefreshing];
    }
}
-(void)getReportee{
    if ([APPDELEGATE connected]) {
        
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
        NSString *strAuthorization=[defaults valueForKey:@"BasicAuth"];
        
        AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
        httpClient.parameterEncoding = AFFormURLParameterEncoding;
        [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [httpClient setDefaultHeader:@"Authorization" value:strAuthorization];
        
        NSString *strPath=[NSString stringWithFormat:@"/rest/s1/ft/user/reportees"];
        // NSLog(@"String Path for Get Promoters==%@",strPath);
        NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET"
                                                                path:strPath
                                                          parameters:nil];
        
        //====================================================RESPONSE
        
        //        if (pageNumber==0) {
        [DejalBezelActivityView activityViewForView:self.view];
        //        }
        
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
        [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            
        }];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSError *error = nil;
            NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
            
            //            if (pageNumber==0) {
            [DejalBezelActivityView removeView];
            //             }
            
            arrayForReportee=[[JSON objectForKey:@"reporteeList"] mutableCopy];
            
            //            arrayForReportee=array;
            
            [self.tableVwForReporties reloadData];
            NSLog(@"Reportee List===%@",arrayForReportee);
        }
         //==================================================ERROR
                                         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                             [DejalBezelActivityView removeView];
                                             NSLog(@"Error %@",[error description]);
                                             NSError *jsonError;
                                             NSData *objectData = [[[error userInfo] objectForKey:NSLocalizedRecoverySuggestionErrorKey] dataUsingEncoding:NSUTF8StringEncoding];
                                             
                                             if (objectData != nil) {
                                                 
                                                 NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                                                                      options:NSJSONReadingMutableContainers
                                                                                                        error:&jsonError];
                                                 
                                                 NSString *strError=[json valueForKey:@"errors"];
                                                 [[[UIAlertView alloc] initWithTitle:@""
                                                                             message:strError
                                                                            delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                                             }
                                             
                                         }];
        [operation start];
    }else{
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"It appears you are not connected to internet" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
}
-(void)getReporteeHistory{
    
    if ([APPDELEGATE connected]) {
        
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
        NSString *strAuthorization=[defaults valueForKey:@"BasicAuth"];
        
        AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
        httpClient.parameterEncoding = AFJSONParameterEncoding;
        [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [httpClient setDefaultHeader:@"Authorization" value:strAuthorization];
        
        ///rest/s1/ft/attendance/${username}/log?pageIndex&pageSize=10&estimatedStartDate=2016-12-11 00:00:00&estimatedCompletionDate=2016-12-11 23:50:59
        //reportee/log?username=
        NSString *strPath=[NSString stringWithFormat:@"/rest/s1/ft/attendance/reportee/log?username=%@&pageIndex=%li&pageSize=10",strForReporteeUserName,(long)pageNumber];
        
       
        NSString *strURL=[strPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        strURL=[strURL stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
        
        
        NSString *urlEncoded = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef)strPath,NULL,(CFStringRef)@"+",kCFStringEncodingUTF8));
        NSLog(@"Encoded String===%@",urlEncoded);
        
        
        NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET"
                                                                path:urlEncoded
                                                          parameters:nil];
        
        //====================================================RESPONSE
        
        if (pageNumber==0) {
            [DejalBezelActivityView activityViewForView:self.view];
        }
        
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
        [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            
        }];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSError *error = nil;
            NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
            
            if (pageNumber==0) {
                [DejalBezelActivityView removeView];
            }
            
            NSLog(@"Reportee History===%@",JSON);
            
            if ([[JSON valueForKey:@"totalEntries"] integerValue] == 0) {
                self.vwForReportiesHistory.hidden = YES;
                [[[UIAlertView alloc] initWithTitle:@""
                                            message:@"There is no log history. The user didn't logged yet."
                                           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
            }else{
                self.vwForReportiesHistory.hidden = NO;
                
                NSMutableArray *array=[[JSON objectForKey:@"userTimeLog"] mutableCopy];
                for (NSDictionary *dict in array) {
                    [arrayForReporteeHistory addObject:dict];
                }
                
                countForReporteeHistory = [[JSON objectForKey:@"totalEntries"] integerValue];;
                
                [self.tableVwForReportiesHistory reloadData];
            }
        }
         //==================================================ERROR
                                         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                             [DejalBezelActivityView removeView];
                                             NSLog(@"Error %@",[error description]);
                                             NSError *jsonError;
                                             NSData *objectData = [[[error userInfo] objectForKey:NSLocalizedRecoverySuggestionErrorKey] dataUsingEncoding:NSUTF8StringEncoding];
                                             
                                             if (objectData != nil) {
                                                 
                                                 NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                                                                      options:NSJSONReadingMutableContainers
                                                                                                        error:&jsonError];
                                                 
                                                 NSString *strError=[json valueForKey:@"errors"];
                                                 [[[UIAlertView alloc] initWithTitle:@""
                                                                             message:strError
                                                                            delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                                             }
                                             
                                         }];
        [operation start];
    }else{
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"It appears you are not connected to internet" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
}

-(NSMutableArray*)sortingArrayByDate:(NSMutableArray*)array{
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ssZ"];
    NSMutableArray *tempArray = [NSMutableArray array];
    // fast enumeration of the array
    for (NSString *dateString in array) {
        if (![dateString isKindOfClass:[NSNull class]]){
            NSString *str=dateString;
            str = [str stringByReplacingOccurrencesOfString:@"T" withString:@" "];
            str = [str stringByReplacingOccurrencesOfString:@"+0000" withString:@" +0000"];
            NSDate *date = [formatter dateFromString:str];
            [tempArray addObject:date];
        }
    }
    // NSLog(@"%@", tempArray);
    // sort the array of dates
    [tempArray sortUsingComparator:^NSComparisonResult(NSDate *date1, NSDate *date2) {
        // return date2 compare date1 for descending. Or reverse the call for ascending.
        return [date2 compare:date1];
    }];
    
    tempArray =[[[tempArray reverseObjectEnumerator] allObjects] mutableCopy];
    NSMutableArray *correctOrderStringArray = [NSMutableArray array];
    for (NSDate *date_1 in tempArray) {
        //        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        //        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss xxxx"];
        //        NSString *dateString = [formatter stringFromDate:date_1];
        [correctOrderStringArray addObject:date_1.description];
    }
    //  NSLog(@"%@", correctOrderStringArray);
    return correctOrderStringArray;
}
-(NSString*)getTimeIndividual:(NSString*)strDate
{
    if ([strDate isKindOfClass:[NSNull class]]) {
        return @"--";
    }
    //   NSLog(@"Time===%@",strDate);
    NSString *strDateChange=strDate;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss Z";
    NSDateFormatter *dateFormatter1 = [[NSDateFormatter alloc] init];
    dateFormatter1.dateFormat = @"yyyy-MM-dd HH:mm:ss Z";
    NSDate *daate=[dateFormatter1 dateFromString:strDateChange];
    
    NSTimeZone *tz = [NSTimeZone localTimeZone];
    NSInteger seconds = [tz secondsFromGMTForDate:daate];
    daate = [NSDate dateWithTimeInterval: seconds sinceDate: daate];
    
    /* NSTimeZone *timeZone = [NSTimeZone localTimeZone];
     NSString *tzName = [timeZone name];
     NSLog(@"Time Zone===%@",daate.description);
     
     if (![tzName containsString:@"Asia"]) {
     NSDateFormatter * format = [[NSDateFormatter alloc] init];
     [format setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
     NSDate * dateTemp = [format dateFromString:strDateChange];
     [format setDateFormat:@"hh:mm a"];
     NSTimeZone *currentTimeZone = [NSTimeZone localTimeZone];
     NSTimeZone *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
     NSInteger currentGMTOffset = [currentTimeZone secondsFromGMTForDate:dateTemp];
     NSInteger gmtOffset = [utcTimeZone secondsFromGMTForDate:dateTemp];
     NSTimeInterval gmtInterval = currentGMTOffset - gmtOffset;
     NSDate *destinationDate = [[NSDate alloc] initWithTimeInterval:gmtInterval sinceDate:dateTemp];
     NSString *dateStr = [format stringFromDate:destinationDate];
     NSLog(@"Converted Time===%@",dateStr);
     return dateStr;
     }*/
    
    NSDate *date_1 = [dateFormatter dateFromString:strDateChange];
    dateFormatter.dateFormat = @"hh:mm a";
    //    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:[NSTimeZone localTimeZone].secondsFromGMT];
    strDateChange = [dateFormatter stringFromDate:date_1];
    
    //    NSLog(@"Converted Time===%@",strDateChange);
    return strDateChange;
}
#pragma mark - Back Button
- (IBAction)onClickBackBtn:(UIButton *)sender{
    
    self.backBtn.hidden = YES;
    
    if (![self.vwForStore isHidden]){
        self.vwForStore.hidden= YES;
    }
    else if (![self.vwForPromoters isHidden]){
        if (![self.vwForCamera isHidden]){
            //            self.backBtn.hidden = NO;
            self.tabBarController.tabBar.hidden =NO;
            self.vwForCamera.hidden = YES;
        }else if (![self.vwForPromoterAdd isHidden]){
            self.vwForPromoterAdd.hidden = YES;
            self.backBtn.hidden = NO;
        }else{
            self.vwForPromoters.hidden= YES;
        }
    }
    else if (![self.vwForLeaveRqst isHidden]){
        if (![self.vwForCalendar isHidden]) {
            
            self.vwForCalendar.hidden = YES;
            
        }else{
            
            self.vwForLeaveRqst.hidden =YES;
        }
    }else if (![self.vwForCamera isHidden]){
        
        self.vwForCamera.hidden = YES;
        
    }else if (![self.vwForAccount isHidden]){
        
        self.vwForAccount.hidden=YES;
        
    }else if (![self.vwForChangePwd isHidden]){
        
        self.vwForChangePwd.hidden=YES;
        self.textFieldCurrentPwd.text=@"";
        self.textFieldNewPwd.text=@"";
        self.textFieldConfirmNewPwd.text=@"";
        
    }else if (![self.vwForContact isHidden]){
        
        self.vwForContact.hidden=YES;
    }else if (![self.vwForLeaveRequestForApproval isHidden]){
        if (![self.vwForLeaveRqstAdd isHidden]) {
            if (![self.vwForCalendar isHidden]) {
                self.vwForCalendar.hidden = YES;
                self.backBtn.hidden = NO;
            }else{
                self.vwForLeaveRqstAdd.hidden = YES;
                self.backBtn.hidden = NO;
            }
        }else{
            self.vwForLeaveRequestForApproval.hidden = YES;
        }
    }else if (![self.vwForReporties isHidden]){
        if (![self.vwForReportiesHistory isHidden]) {
            if (![self.vwForReportiesIndividualHistory isHidden]) {
                self.vwForReportiesIndividualHistory.hidden = YES;
            }else{
                self.vwForReportiesHistory.hidden = YES;
            }
            self.backBtn.hidden = NO;
        }else{
            self.vwForReporties.hidden = YES;
        }
    }
}

#pragma mark -

#pragma mark - Popup Store List
- (IBAction)onClickStorAssignment:(UIButton *)sender {
    [[MKSharedClass shareManager] setPopupViewDifferentiate:1];
    [self popupView];
}

- (IBAction)onClickSEAssignment:(UIButton *)sender {
}

- (IBAction)onClickType:(UIButton *)sender {
    [[MKSharedClass shareManager] setPopupViewDifferentiate:2];
    [self popupView];
}

- (IBAction)onClickReason:(UIButton *)sender {
    [[MKSharedClass shareManager] setPopupViewDifferentiate:3];
    [self popupView];
}

-(void)popupView{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *smallViewController = [storyboard instantiateViewControllerWithIdentifier:@"MKStoreListPopupVC"];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        BIZPopupViewController *popupViewController = [[BIZPopupViewController alloc] initWithContentViewController:smallViewController contentSize:CGSizeMake(self.view.frame.size.width-100, self.view.frame.size.height/2+100)];
        [self presentViewController:popupViewController animated:NO completion:nil];
    }else{
        BIZPopupViewController *popupViewController = [[BIZPopupViewController alloc] initWithContentViewController:smallViewController contentSize:CGSizeMake(self.view.frame.size.width-50, self.view.frame.size.height-100)];
        [self presentViewController:popupViewController animated:NO completion:nil];
    }
}
@end
