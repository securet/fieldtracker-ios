//
//  MKMoreVC.m
//  OppoAttendanceTracker
//
//  Created by User1 on 12/20/16.
//
//

#import "MKMoreVC.h"
#import "MKCustomCellForLeave.h"
@interface MKMoreVC ()<HSDatePickerViewControllerDelegate>
{
    NSMutableArray *arrayForTableData;
    NSMutableArray *arrayForStoreList;
    NSMutableArray *arrayForPromoters;
    
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
    
}
@end

@implementation MKMoreVC
#pragma mark - View
- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSMutableDictionary *dict=[[defaults objectForKey:@"UserData"] mutableCopy];
    NSLog(@"%@",dict);
    _lblFName.text=[dict valueForKey:@"firstName"];
    _lblLName.text=[dict valueForKey:@"lastName"];
    
    arrayForTableData=[[NSMutableArray alloc] initWithObjects:@"Stores",@"Promoters",@"Leaves",@"Contact Support",@"Log Off", nil];
    
    arrayForStoreList=[[NSMutableArray alloc] init];
    arrayForPromoters=[[NSMutableArray alloc] init];
    
    _tableVw.delegate = self;
    _tableVw.dataSource = self;
    _tableVw.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    _tableVw.tableFooterView=[[UIView alloc] init];
    _tableVwForStore.tableFooterView =[[UIView alloc] init];
    _tableVwForPromoters.tableFooterView =[[UIView alloc] init];
    _tableVwForLeaveRqst.tableFooterView=[[UIView alloc] init];
    
    _vwForPromoters.hidden = YES;
    _vwForStore.hidden = YES;
    _vwForLeaveRqst.hidden= YES;
    
    _backBtn.hidden = YES;
    
    [_btnAddStore addTarget:self action:@selector(onClickAddStore:) forControlEvents:UIControlEventTouchUpInside];

    [_btnAddPromoter addTarget:self action:@selector(onClickAddPromoter:) forControlEvents:UIControlEventTouchUpInside];
    
    [_btnLeaveRqst addTarget:self action:@selector(onClickLeaveRqst:) forControlEvents:UIControlEventTouchUpInside];
    
    _vwForStoreAdd.hidden = YES;
    _vwForPromoterAdd.hidden = YES;
    _vwForLeaveRqstAdd.hidden = YES;
    
    [self addPromoterViewSetup];
    
    [self addShadow:_btnAddStore];
    [self addShadow:_btnAddPromoter];
    [self addShadow:_btnLeaveRqst];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storeSelected) name:@"SelectedStore" object:nil];
    
    [self getStores];
    
    
    pageNumber=0;
    //rgb(84,138,176)
//    UIColor *color=[UIColor colorWithRed:(84/255.0) green:(138/255.0) blue:(176/255.0) alpha:1.0];
    
    [_tableVwForPromoters addFooterWithTarget:self action:@selector(refreshFooter) withIndicatorColor:TopColor];
   
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkingInLocation:) name:@"LocationChecking" object:nil];

    [self changeLocationStatus:[[MKSharedClass shareManager] dictForCheckInLoctn]];

}


-(void)checkingInLocation:(NSNotification*)notification{
    
    NSDictionary *userInfo = notification.userInfo;
    NSLog(@"Notification In History==%@",userInfo);
    
    //    NSDictionary *dict=[userIn];
    
    if ([[userInfo valueForKey:@"LocationStatus"] integerValue]==1) {
        _imgVwForLocationIcon.image=[UIImage imageNamed:@"location_On"];
        _lblForStoreLocation.textColor=[UIColor whiteColor];
    }else{
        _imgVwForLocationIcon.image=[UIImage imageNamed:@"location_Off"];
        //        _lblForStoreLocation.text=@"Off site";
        _lblForStoreLocation.textColor=[UIColor darkGrayColor];
    }
    
    _lblForStoreLocation.text=[userInfo valueForKey:@"StoreName"];
}

-(void)changeLocationStatus:(NSDictionary*)dictInfo{
    
    if ([[dictInfo valueForKey:@"LocationStatus"] integerValue]==1) {
        _imgVwForLocationIcon.image=[UIImage imageNamed:@"location_On"];
        _lblForStoreLocation.textColor=[UIColor whiteColor];
    }else{
        _imgVwForLocationIcon.image=[UIImage imageNamed:@"location_Off"];
        //        _lblForStoreLocation.text=@"Off site";
        _lblForStoreLocation.textColor=[UIColor darkGrayColor];
    }
    
    _lblForStoreLocation.text=[dictInfo valueForKey:@"StoreName"];
}

- (void)refreshFooter
{
    if(arrayCountToCheck >= 10)
    {
        
        pageNumber++;
        
        [self getPromoters];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_tableVwForPromoters reloadData];
            [_tableVwForPromoters footerEndRefreshing];
            //        [self.tableVw removeFooter];
        });
    }
    else
    {
        [_tableVwForPromoters footerEndRefreshing];
        [_tableVwForPromoters headerEndRefreshing];
    }
}
-(void)storeSelected
{
    NSDictionary *dict=[[NSMutableDictionary alloc] init];
    dict=[[MKSharedClass shareManager] dictForStoreSelected];
    NSLog(@"Selected Store Details===%@",dict);
    
    _txtFieldStoreAsgnmntPromoter.text=[dict valueForKey:@"storeName"];
    _txtFieldSEAsgnmntPromoter.text=[NSString stringWithFormat:@"%@ %@",_lblFName.text,_lblLName.text];
    
    storeIDForPromoterAdd=[dict valueForKey:@"productStoreId"];
    
    NSLog(@"Selected Store ID===%@",storeIDForPromoterAdd);
}

-(void)addShadow:(UIButton*)btn{
    btn.layer.shadowColor = [UIColor lightGrayColor].CGColor;
    btn.layer.shadowOffset = CGSizeMake(1, 1);
    btn.layer.shadowOpacity = 1;
    btn.layer.shadowRadius = 1.0;
}


-(void)viewWillAppear:(BOOL)animated{
    
    [self updateLocationManagerr];
    self.navigationController.navigationBarHidden = YES;
    self.navigationItem.hidesBackButton = YES;
    [self.navigationItem setHidesBackButton:YES];
    
    NSDate *now = [NSDate date];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"hh:mm a";
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    NSLog(@"The Current Time is %@",[dateFormatter stringFromDate:now]);
    
    _lblTime.text=[[dateFormatter stringFromDate:now] substringToIndex:[[dateFormatter stringFromDate:now] length]-3];
    
    _lblAMOrPM.text=[[dateFormatter stringFromDate:now] substringFromIndex:[[dateFormatter stringFromDate:now] length]-2];
}


#pragma mark - TextField Delegate
-(void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == _txtFieldStoreName) {
        [self enableAddNewStoreBtn];
    }else if (textField == _txtFieldStoreAsgnmntPromoter){
        
    }
}
-(void)textFieldDidBeginEditing:(UITextField *)textField{
    
    if (textField == _txtFieldStoreAsgnmntPromoter){
        
    }
    
}
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    
    if (textField == _txtFieldStoreAsgnmntPromoter || textField == _txtFieldSEAsgnmntPromoter){
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

#pragma mark - TextView Delegate

-(void)textViewDidBeginEditing:(UITextView *)textView
{
    if (textView== _txtVwStoreAddress && [textView.text isEqualToString:@"Store Address"]){
        textView.text=@"";
    }else if (textView== _txtVwAddressPromoter && [textView.text isEqualToString:@"Address"]){
        textView.text=@"";
    }
}


-(void)textViewDidEndEditing:(UITextView *)textView
{
    if (textView== _txtVwStoreAddress && _txtVwStoreAddress.text.length<=0){
        textView.text=@"Store Address";
    }else{
        [self enableAddNewStoreBtn];
    }
    
    if (textView== _txtVwAddressPromoter && _txtVwAddressPromoter.text.length<=0){
        textView.text=@"Address";
    }
}



#pragma mark - Add StoreView




-(void)setUpForAddStore:(NSInteger)indexValue{
    
    _txtVwStoreAddress.delegate = self;
    
    _txtVwStoreAddress.text=@"Store Address";
    _backBtn.hidden=YES;
    _lblForLatLon.text=@"";
    _lblForLatLon.textAlignment = NSTextAlignmentCenter;
    
    if ([[MKSharedClass shareManager] valueForStoreEditVC] == 1){
        _lblForEditStore.text=@"Add Store";
        [_btnAdd setTitle:@"Add" forState:UIControlStateNormal];
        
        _btnAdd.enabled = NO;
        _btnAdd.alpha = 0.6;
        _btnAdd.backgroundColor=[[UIColor lightGrayColor] colorWithAlphaComponent:0.6];
        _txtFieldStoreName.text=@"";
    }else if ([[MKSharedClass shareManager] valueForStoreEditVC] == 0){
        _lblForEditStore.text=@"Edit Store";
        [_btnAdd setTitle:@"Edit" forState:UIControlStateNormal];
        _btnAdd.backgroundColor=[[UIColor blueColor] colorWithAlphaComponent:0.6];
        _btnAdd.enabled = YES;
        _btnAdd.alpha = 1.0;
        
        _txtVwStoreAddress.text=[[arrayForStoreList objectAtIndex:indexValue] valueForKey:@"address"];
        _txtFieldStoreName.text=[[arrayForStoreList objectAtIndex:indexValue] valueForKey:@"storeName"];
        
        _lblForLatLon.text=[NSString stringWithFormat:@"Lat: %@ | Lon: %@",[[arrayForStoreList objectAtIndex:indexValue] valueForKey:@"latitude"],[[arrayForStoreList objectAtIndex:indexValue] valueForKey:@"longitude"]];
        strForCurLatitude=[[arrayForStoreList objectAtIndex:indexValue] valueForKey:@"latitude"];
        strForCurLongitude=[[arrayForStoreList objectAtIndex:indexValue] valueForKey:@"longitude"];
        _btnAdd.tag=indexValue;
    }
    
    [self textFieldEdit:_txtFieldStoreName];
    
    _txtVwStoreAddress.layer.cornerRadius = 5;
    _txtVwStoreAddress.layer.masksToBounds = YES;
    _txtVwStoreAddress.keyboardType=UIKeyboardTypeASCIICapable;
    _txtVwStoreAddress.backgroundColor =[[UIColor lightGrayColor] colorWithAlphaComponent:0.7];
    
    
    _txtVwStoreAddress.autocorrectionType = UITextAutocorrectionTypeNo;
    
    _btnGetLocation.layer.cornerRadius = 5;
    _btnGetLocation.layer.masksToBounds = YES;
    
    [self addShadow:_btnAdd];
    [self addShadow:_btnCancel];
    
    [_btnAdd addTarget:self action:@selector(onClickStoreAddToServer:) forControlEvents:UIControlEventTouchUpInside];
    
    [_btnCancel addTarget:self action:@selector(onClickCancel) forControlEvents:UIControlEventTouchUpInside];
    
    [_btnGetLocation addTarget:self action:@selector(getLocation) forControlEvents:UIControlEventTouchUpInside];
}


-(void)enableAddNewStoreBtn
{
    
    if ([[MKSharedClass shareManager] valueForStoreEditVC] == 1){
        if (_txtFieldStoreName.text.length>0&&_txtVwStoreAddress.text.length>0) {
            _btnAdd.enabled = YES;
            _btnAdd.alpha = 1;
            _btnAdd.backgroundColor=[[UIColor darkGrayColor] colorWithAlphaComponent:1];
        }
        else{
            _btnAdd.enabled = NO;
            _btnAdd.alpha = 0.6;
            _btnAdd.backgroundColor=[[UIColor lightGrayColor] colorWithAlphaComponent:0.6];
        }
    }
}
-(void)onClickStoreAddToServer:(UIButton*)sender
{
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    httpClient.parameterEncoding = AFFormURLParameterEncoding;
    [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    NSString *str=[defaults valueForKey:@"BasicAuth"];
    
    
    [httpClient setDefaultHeader:@"Authorization" value:str];
    
    //{"storeName":"OPPO Tirumalgherry","address":"Via Rest API","latitude":100.00,"longitude":100.00,"proximityRadius":200}
    
    NSDictionary * json = @{@"storeName":_txtFieldStoreName.text,
                            @"address":_txtVwStoreAddress.text,
                            @"latitude":strForCurLatitude,
                            @"longitude":strForCurLongitude,
                            };
    
    NSMutableURLRequest *request;
    
    
    
    if ([[MKSharedClass shareManager] valueForStoreEditVC] == 1){
        request = [httpClient requestWithMethod:@"POST"
                                           path:@"/rest/s1/ft/stores"
                                     parameters:json];
        
    }
    else if ([[MKSharedClass shareManager] valueForStoreEditVC] == 0){
        
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
        
        _vwForStoreAdd.hidden = YES;
        _backBtn.hidden=NO;
        
        if ([[MKSharedClass shareManager] valueForStoreEditVC] == 1){
            if ([[JSON objectForKey:@"productStoreId"] integerValue]>0) {
                //                _vwForStoreAdd.hidden = YES;
                //                _backBtn.hidden=NO;
                UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Success" message:@"Store Added Successfully" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
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
    
    
}
-(void)onClickCancel{
    //    [[NSNotificationCenter defaultCenter] postNotificationName:@"CloseView" object:self];
    
    _vwForStoreAdd.hidden = YES;
    _backBtn.hidden=NO;
}


-(void)getLocation{
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    [locationManager startUpdatingLocation];
    CLLocation *location = [locationManager location];
    CLLocationCoordinate2D coordinate = [location coordinate];
    
    
    NSLog(@"Lat:%f Lon:%f",coordinate.latitude,coordinate.longitude);
    
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
            //
            //            CGRect frame = self.textVwForAddress.frame;
            //            frame.size.height = self.textVwForAddress.contentSize.height;
            //            self.textVwForAddress.frame=frame;
            
            NSLog(@"Address==%@",[[getAddress objectAtIndex:0]objectAtIndex:0]);
            
            _lblForLatLon.text=[NSString stringWithFormat:@"Lat: %f | Lon: %f",[strForCurLatitude floatValue],[strForCurLongitude floatValue]];
            
            _txtVwStoreAddress.text=[[getAddress objectAtIndex:0]objectAtIndex:0];
            
            if (_txtFieldStoreName.text.length>0) {
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
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    httpClient.parameterEncoding = AFFormURLParameterEncoding;
    [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    NSString *str=[defaults valueForKey:@"BasicAuth"];
    
    
    [httpClient setDefaultHeader:@"Authorization" value:str];
    
    
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
        
        [_tableVwForStore reloadData];
    }
     //==================================================ERROR
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         [DejalBezelActivityView removeView];
                                         NSLog(@"Error %@",[error description]);
                                     }];
    [operation start];
    
}



#pragma mark - Add Store

-(void)onClickAddStore:(UIButton*)btn{
    [[MKSharedClass shareManager] setValueForStoreEditVC:1];
    [self goToStorePopup:0];
    
    //    NSLog(@"On Click Add Store");
}

#pragma mark - Get Promoters


-(void)getPromoters{
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    httpClient.parameterEncoding = AFFormURLParameterEncoding;
    [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    NSString *str=[defaults valueForKey:@"BasicAuth"];
    
    
    [httpClient setDefaultHeader:@"Authorization" value:str];
    
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
        
//        arrayForPromoters=[[JSON objectForKey:@"requestList"] mutableCopy];
        
        for (NSDictionary *dict in array) {
            [arrayForPromoters addObject:dict];
        }
        
        arrayCountToCheck=[[JSON objectForKey:@"requestList"] count];
        
        [_tableVwForPromoters reloadData];
    }
     //==================================================ERROR
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         [DejalBezelActivityView removeView];
                                         NSLog(@"Error %@",[error description]);
                                     }];
    [operation start];
    
}


#pragma mark - Add Promoter

-(void)multiSelect:(MultiSelectSegmentedControl *)multiSelectSegmentedControl didChangeValue:(BOOL)selected atIndex:(NSUInteger)index {
    
    if (selected) {
        NSLog(@"multiSelect with tag %i selected button at index: %i", multiSelectSegmentedControl.tag, index);
    } else {
        NSLog(@"multiSelect with tag %i deselected button at index: %i", multiSelectSegmentedControl.tag, index);
    }
    
    NSLog(@"selected: '%@'", [multiSelectSegmentedControl.selectedSegmentTitles componentsJoinedByString:@","]);
}


-(void)onClickAddPromoter:(UIButton*)btn{
    //    NSLog(@"On Click Add Promoter");
    
    [self promoterDetails:YES];
}

-(void)promoterDetails:(BOOL)isAddOrEdit{
    
    _segmentControl.delegate = self;
    [_btnCancelPromoterAdd addTarget:self action:@selector(onClickCancelOfAddPromoter) forControlEvents:UIControlEventTouchUpInside];
    _btnAddPromoterConfirm.tag=isAddOrEdit;
    [_btnAddPromoterConfirm addTarget:self action:@selector(addPromoter:) forControlEvents:UIControlEventTouchUpInside];
    _vwForPromoterAdd.hidden = NO;
    _backBtn.hidden = YES;
    
    if (!isAddOrEdit) {
        [_btnAddPromoterConfirm setTitle:@"Edit" forState:UIControlStateNormal];
        NSString *jsonString = [[arrayForPromoters objectAtIndex:indexValueOfPromoterEdit] objectForKey:@"requestJson"];
        NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
//        NSLog(@"Promoters List==%@",[json objectForKey:@"requestInfo"]);
        
        _txtFieldFNamePromoter.text=[[json objectForKey:@"requestInfo"] valueForKey:@"firstName"];
        _txtFieldLNamePromoter.text=[[json objectForKey:@"requestInfo"] valueForKey:@"lastName"];
        _txtFieldEmailPromoter.text=[[json objectForKey:@"requestInfo"] valueForKey:@"emailId"];
        _txtFieldPhonePromoter.text=[[json objectForKey:@"requestInfo"] valueForKey:@"phone"];
        _txtVwAddressPromoter.text=[[json objectForKey:@"requestInfo"] valueForKey:@"address"];
        
        NSString *productStoreId=[[json objectForKey:@"requestInfo"] objectForKey:@"productStoreId"];
        
        for (NSDictionary *dict in arrayForStoreList) {
            if ([[dict valueForKey:@"productStoreId"] isEqualToString:productStoreId]) {
                _txtFieldStoreAsgnmntPromoter.text=[dict valueForKey:@"storeName"];
            }
            
            _txtFieldSEAsgnmntPromoter.text=[NSString stringWithFormat:@"%@ %@",_lblFName.text,_lblLName.text];
            
            
            strAadharIDPath=[[json objectForKey:@"requestInfo"] objectForKey:@"aadharIdPath"];;
            strUserPhotoPath=[[json objectForKey:@"requestInfo"] objectForKey:@"userPhoto"];;
            strAddressProofPath=[[json objectForKey:@"requestInfo"] objectForKey:@"addressIdPath"];
            storeIDForPromoterAdd=productStoreId;
        }
        
    }else{
        strAadharIDPath=@"";
        strUserPhotoPath=@"";
        strAddressProofPath=@"";
        [_btnAddPromoterConfirm setTitle:@"Add" forState:UIControlStateNormal];
        _txtFieldFNamePromoter.text=@"";
        _txtFieldLNamePromoter.text=@"";
        _txtFieldEmailPromoter.text=@"";
        _txtFieldPhonePromoter.text=@"";
        _txtVwAddressPromoter.text=@"Address";
    }
}

-(void)addPromoterViewSetup{
    [self textFieldEdit:_txtFieldFNamePromoter];
    [self textFieldEdit:_txtFieldLNamePromoter];
    [self textFieldEdit:_txtFieldEmailPromoter];
    [self textFieldEdit:_txtFieldPhonePromoter];
    [self textFieldEdit:_txtFieldSEAsgnmntPromoter];
    [self textFieldEdit:_txtFieldStoreAsgnmntPromoter];
    
    _txtVwAddressPromoter.text=@"Address";
    _txtVwAddressPromoter.layer.cornerRadius = 5;
    _txtVwAddressPromoter.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.7];
    _txtVwAddressPromoter.keyboardType=UIKeyboardTypeASCIICapable;
    _txtVwAddressPromoter.delegate = self;
    _txtVwAddressPromoter.autocorrectionType = UITextAutocorrectionTypeNo;
    
    _btnPhotoPromoter.layer.cornerRadius = 5;
    _btnPhotoPromoter.layer.masksToBounds = YES;
    
    _btnPhotoPromoter.tag=100;
    
    _btnAadharPromoter.layer.cornerRadius = 5;
    _btnAadharPromoter.layer.masksToBounds =YES;
    _btnAadharPromoter.tag = 200;
    
    _btnAdressProofPromoter.layer.cornerRadius = 5;
    _btnAdressProofPromoter.layer.masksToBounds =YES;
    _btnAdressProofPromoter.tag=300;
    
    [self addShadow:_btnAddPromoterConfirm];
    [self addShadow:_btnCancelPromoterAdd];
    
    [_btnPhotoPromoter addTarget:self action:@selector(openCamera:) forControlEvents:UIControlEventTouchUpInside];
    [_btnAadharPromoter addTarget:self action:@selector(openCamera:) forControlEvents:UIControlEventTouchUpInside];
    [_btnAdressProofPromoter addTarget:self action:@selector(openCamera:) forControlEvents:UIControlEventTouchUpInside];
}

-(void)textFieldEdit:(UITextField*)txtField{
    txtField.layer.cornerRadius = 5;
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

-(void)onClickCancelOfAddPromoter{
    _vwForPromoterAdd.hidden = YES;
    _backBtn.hidden = NO;
}
-(void)addPromoter:(UIButton*)sender
{
    if (sender.tag == 1 || sender.tag == 0) {
        
        if (_txtFieldFNamePromoter.text.length>0&&_txtFieldLNamePromoter.text.length>0&&_txtFieldEmailPromoter.text.length>0&&_txtVwAddressPromoter.text.length>0&&_txtFieldStoreAsgnmntPromoter.text.length>0&& (![[_txtVwAddressPromoter text] isEqualToString:@"Address"])) {
            
       if ([self isValidEmail:_txtFieldEmailPromoter.text]) {
        
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
        
        AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
        httpClient.parameterEncoding = AFFormURLParameterEncoding;
        [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
        
        NSString *str=[defaults valueForKey:@"BasicAuth"];
        
        [httpClient setDefaultHeader:@"Authorization" value:str];
        
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
                                       @"firstName":_txtFieldFNamePromoter.text,
                                       @"lastName":_txtFieldLNamePromoter.text,
                                       @"phone":_txtFieldPhonePromoter.text,
                                       @"address":_txtVwAddressPromoter.text,
                                       @"emailId":_txtFieldEmailPromoter.text,
                                       @"productStoreId":storeIDForPromoterAdd,
                                       @"statusId":@"ReqSubmitted",
                                       @"requestTypeEnumId":@"RqtAddPromoter",
                                       @"aadharIdPath":strAadharIDPath,
                                       @"userPhoto":strUserPhotoPath,
                                       @"addressIdPath":strAddressProofPath,
                                       @"description":@"Requesting new Promoter",
                                       };
               request = [httpClient requestWithMethod:@"POST"
                                                  path:@"/rest/s1/ft/request/promoter"
                                            parameters:json];
           }else if (sender.tag == 0){
               
               NSString *rqstID=[[arrayForPromoters objectAtIndex:indexValueOfPromoterEdit] objectForKey:@"requestId"];
               NSDictionary * json = @{@"requestType":@"RqtAddPromoter",
                                       @"firstName":_txtFieldFNamePromoter.text,
                                       @"lastName":_txtFieldLNamePromoter.text,
                                       @"phone":_txtFieldPhonePromoter.text,
                                       @"address":_txtVwAddressPromoter.text,
                                       @"emailId":_txtFieldEmailPromoter.text,
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
            NSLog(@"Add Store Successfully==%@",JSON);
            
            
            _vwForPromoterAdd.hidden = YES;
            _backBtn.hidden = NO;
            
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
           _txtFieldEmailPromoter.text=@"";
       }

    }else{
            UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"Please Enter All Details" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
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
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.delegate = self;
        
        imagePickerController.sourceType =UIImagePickerControllerSourceTypeCamera;
        
        if (sender.tag == 100) {
           imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
            
            UIView *cameraOverlayView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 100.0f, 5.0f, 100.0f, 35.0f)];
            [cameraOverlayView setBackgroundColor:[UIColor blackColor]];
            UIButton *emptyBlackButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 35.0f)];
            [emptyBlackButton setBackgroundColor:[UIColor blackColor]];
            [emptyBlackButton setEnabled:YES];
            [cameraOverlayView addSubview:emptyBlackButton];
            imagePickerController.allowsEditing = YES;
            imagePickerController.showsCameraControls = YES;
            imagePickerController.cameraOverlayView = cameraOverlayView;
        }else if (sender.tag == 200){
            imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        }else if (sender.tag == 300){
            imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        }
        
        [self presentViewController:imagePickerController animated:YES completion:^{
            
        }];
    }
}

#pragma mark - ImagePickerDelegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    if([info valueForKey:UIImagePickerControllerOriginalImage]==nil)
    {
    }
    else
    {
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
                       
                       // Dictionary that holds post parameters. You can set your post parameters that your server accepts or programmed to accept.
                           NSMutableDictionary* _params = [[NSMutableDictionary alloc] init];
                       [_params setObject:stringForImagePurpose forKey:@"purpose"];
                       
                       // the boundary string : a random string, that will not repeat in post data, to separate post data fields.
                       NSString *BoundaryConstant = @"----------V2ymHFg03ehbqgZCaKO6jy";
                       
                       // string constant for the post parameter 'file'. My server uses this name: `file`. Your's may differ
                       NSString* FileParamConstant = @"snapshotFile";
                       
                       // the server url to which the image (or the media) is uploaded. Use your server url here
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
                                              }else if ([stringForImagePurpose isEqualToString:@"aadharId"]){
                                                  strAadharIDPath=[jsonData valueForKey:@"savedFilename"];
                                              }else if ([stringForImagePurpose isEqualToString:@"addressProof"]){
                                                  strAddressProofPath=[jsonData valueForKey:@"savedFilename"];
                                              }
                                          }
                                          [DejalBezelActivityView removeView];
                                      });
                       
                       
                   });
    
}
#pragma mark - Leave Rqst

-(void)onClickLeaveRqst:(UIButton*)btn{
    //        NSLog(@"On Click Leave Request");
    _backBtn.hidden = YES;
    _vwForLeaveRqstAdd.hidden = NO;
    
    
    
    [self textFieldEdit:_txtFieldStartDate];
    [self textFieldEdit:_txtFieldEndDate];
    [self textFieldEdit:_txtFieldLeaveType];
    
    [self addShadow:_btnLeaveRqstCancel];
    [self addShadow:_btnLeaveRqstSubmit];
    
    _txtFieldLeaveReason.backgroundColor=[UIColor clearColor];
    _txtFieldLeaveReason.delegate = self;
    
    
    [_txtFieldLeaveReason addTarget:self action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    [_btnLeaveRqstCancel addTarget:self action:@selector(leaveRqstCancel) forControlEvents:UIControlEventTouchUpInside];
}

-(void)leaveRqstCancel{
    _backBtn.hidden = NO;
    _vwForLeaveRqstAdd.hidden = YES;
}

-(void)leaveRqstEdit{
    
}


#pragma mark- UITableView

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    if (tableView==_tableVwForStore) {
        return arrayForStoreList.count;
    }else if (tableView == _tableVwForPromoters){
        return arrayForPromoters.count;
    }else if (tableView == _tableVwForLeaveRqst){
        return 4;
    }
    return arrayForTableData.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    
    if (tableView == _tableVwForLeaveRqst){
        MKCustomCellForLeave *cellLeave=[tableView dequeueReusableCellWithIdentifier:@"Cell"];
        
        if (cellLeave == nil) {
            cellLeave=[[MKCustomCellForLeave alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        }
        
        cellLeave.selectionStyle = UITableViewCellSelectionStyleNone;
        return cellLeave;
    }
    
    if (cell == nil){
        cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (tableView == _tableVwForStore){
        cell.textLabel.text=[[arrayForStoreList objectAtIndex:indexPath.row] valueForKey:@"storeName"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if (tableView == _tableVwForPromoters){
        NSString *jsonString = [[arrayForPromoters objectAtIndex:indexPath.row] objectForKey:@"requestJson"];
        NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
//        NSLog(@"Promoters List==%@",[json objectForKey:@"requestInfo"]);
        
        cell.textLabel.text=[NSString stringWithFormat:@"%@ %@",[[json objectForKey:@"requestInfo"] valueForKey:@"firstName"],[[json objectForKey:@"requestInfo"] valueForKey:@"lastName"]];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if (tableView == _tableVw){
        cell.textLabel.text=[arrayForTableData objectAtIndex:indexPath.row];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (tableView == _tableVw){
        if (indexPath.row == 4){
            
            
             NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
            
            [defaults setObject:@"0" forKey:@"Is_Login"];
            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            UITabBarController *rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"MainRoot"];
            [[UIApplication sharedApplication].keyWindow setRootViewController:rootViewController];
            
        }else if (indexPath.row ==0){
            [self getStores];
            _vwForStore.hidden =NO;
            _backBtn.hidden = NO;
            _tableVwForStore.delegate = self;
            _tableVwForStore.dataSource = self;
            [_tableVwForStore reloadData];
            
        }else if (indexPath.row ==1){
            [self getPromoters];
            _vwForPromoters.hidden =NO;
            _backBtn.hidden = NO;
            _tableVwForPromoters.delegate = self;
            _tableVwForPromoters.dataSource = self;
            [_tableVwForPromoters reloadData];
        }else if (indexPath.row ==2){
            _vwForLeaveRqst.hidden =NO;
            _backBtn.hidden = NO;
            _tableVwForLeaveRqst.delegate = self;
            _tableVwForLeaveRqst.dataSource = self;
            [_tableVwForLeaveRqst reloadData];
        }
        
    }else if (tableView == _tableVwForStore){
        [[MKSharedClass shareManager] setValueForStoreEditVC:0];
        [self goToStorePopup:indexPath.row];
    }
    else if (tableView == _tableVwForPromoters){
        indexValueOfPromoterEdit=indexPath.row;
        [self promoterDetails:NO];
        
    }
}


-(void)goToStorePopup:(NSInteger)indexValue{
    //    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    //    UIViewController *smallViewController = [storyboard instantiateViewControllerWithIdentifier:@"AddStoreVC"];
    //
    //    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    //    {
    //        BIZPopupViewController *popupViewController = [[BIZPopupViewController alloc] initWithContentViewController:smallViewController contentSize:CGSizeMake(self.view.frame.size.width-100, self.view.frame.size.height/2+200)];
    //        [self presentViewController:popupViewController animated:NO completion:nil];
    //    }
    //    else
    //    {
    //
    //        BIZPopupViewController *popupViewController = [[BIZPopupViewController alloc] initWithContentViewController:smallViewController contentSize:CGSizeMake(self.view.frame.size.width-50, self.view.frame.size.height-100)];
    //        [self presentViewController:popupViewController animated:NO completion:nil];
    //    }
    
    [self setUpForAddStore:indexValue];
    _vwForStoreAdd.hidden = NO;
    
}


#pragma mark - HSDatePickerViewControllerDelegate
- (void)hsDatePickerPickedDate:(NSDate *)date{
    
    NSDateFormatter *dateFormater = [NSDateFormatter new];
    dateFormater.dateFormat = @"dd/MM/yyyy";
    
    NSString *dateTime= [dateFormater stringFromDate:date];
    
    NSLog(@"Selected Time====%@",dateTime);
    
    self.tabBarController.tabBar.hidden =NO;
    
    
    if (isStartOrEndDate) {
        _txtFieldStartDate.text=dateTime;
    }
    else{
        _txtFieldEndDate.text = dateTime;
    }
    
    
    
    if (_txtFieldStartDate.text.length > 0 && _txtFieldEndDate.text.length > 0){
        NSString *start = _txtFieldStartDate.text;
        NSString *end = _txtFieldEndDate.text;
        
        NSDateFormatter *f = [[NSDateFormatter alloc] init];
        [f setDateFormat:@"dd/MM/yyyy"];
        NSDate *startDate = [f dateFromString:start];
        NSDate *endDate = [f dateFromString:end];
        
        NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                            fromDate:startDate
                                                              toDate:endDate
                                                             options:0];
        
        NSLog(@"Number Of Days===%i",[components day]);
        
        _lblForNoOfDays.textAlignment =NSTextAlignmentCenter;
        
        if ([components day] > 0){
            _lblForNoOfDays.text=[NSString stringWithFormat:@"%i",[components day]+1];
        }
    }
    
}

-(void)hasCancelDatePicking{
    self.tabBarController.tabBar.hidden =NO;
}
//optional
- (void)hsDatePickerDidDismissWithQuitMethod:(HSDatePickerQuitMethod)method {
    NSLog(@"Picker did dismiss with %lu", (unsigned long)method);
    
}

//optional
- (void)hsDatePickerWillDismissWithQuitMethod:(HSDatePickerQuitMethod)method {
    NSLog(@"Picker will dismiss with %lu", (unsigned long)method);
    //    self.tabBarController.tabBar.hidden =NO;
}
#pragma mark -

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

- (IBAction)onClickBackBtn:(UIButton *)sender{
    if (![_vwForStore isHidden]){
        _vwForStore.hidden= YES;
    }
    else if (![_vwForPromoters isHidden]){
        _vwForPromoters.hidden= YES;
    }
    else if (![_vwForLeaveRqst isHidden]){
        _vwForLeaveRqst.hidden =YES;
    }
    _backBtn.hidden = YES;
}
- (IBAction)onClickLeaveStartDate:(UIButton *)sender{
    isStartOrEndDate = YES;
    self.tabBarController.tabBar.hidden =YES;
    HSDatePickerViewController *hsdpvc = [HSDatePickerViewController new];
    hsdpvc.delegate = self;
    [self presentViewController:hsdpvc animated:YES completion:nil];
}

- (IBAction)onClickLeaveEndDate:(UIButton *)sender{
    isStartOrEndDate = NO;
    self.tabBarController.tabBar.hidden =YES;
    HSDatePickerViewController *hsdpvc = [HSDatePickerViewController new];
    hsdpvc.delegate = self;
    [self presentViewController:hsdpvc animated:YES completion:nil];
}
#pragma mark - Popup Store List
- (IBAction)onClickStorAssignment:(UIButton *)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *smallViewController = [storyboard instantiateViewControllerWithIdentifier:@"MKStoreListPopupVC"];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        BIZPopupViewController *popupViewController = [[BIZPopupViewController alloc] initWithContentViewController:smallViewController contentSize:CGSizeMake(self.view.frame.size.width-100, self.view.frame.size.height/2+100)];
        [self presentViewController:popupViewController animated:NO completion:nil];
    }
    else
    {
        
        BIZPopupViewController *popupViewController = [[BIZPopupViewController alloc] initWithContentViewController:smallViewController contentSize:CGSizeMake(self.view.frame.size.width-50, self.view.frame.size.height-100)];
        [self presentViewController:popupViewController animated:NO completion:nil];
    }
    
}

- (IBAction)onClickSEAssignment:(UIButton *)sender {
}
@end
