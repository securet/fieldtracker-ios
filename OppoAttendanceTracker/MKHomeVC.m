//
//  MKHomeVC.m
//  OppoAttendanceTracker
//
//  Created by User1 on 12/20/16.
//
//

#import "MKHomeVC.h"
#import <GoogleMaps/GoogleMaps.h>
@interface MKHomeVC ()
{
    IBOutlet GMSMapView *mapView;
    NSString *strForCurLatitude,*strForCurLongitude;
    NSMutableDictionary *dictForStoreDetails;
    UIImage *imgToSend;
    NSString *imgPathToSend;
    BOOL boolValueForInLocationOrNot;
}
@end

@implementation MKHomeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self getStoreDetails];
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSMutableDictionary *dict=[[defaults objectForKey:@"UserData"] mutableCopy];
    NSLog(@"%@",dict);
    _lblFName.text=[dict valueForKey:@"firstName"];
    _lblLName.text=[dict valueForKey:@"lastName"];
    
    
    _bottomVw.layer.cornerRadius = 10;
    _bottomVw.layer.masksToBounds = YES;
    
    [self updateLocationManagerr];
    
    CLLocationCoordinate2D coordinate = [self getLocation];
    
    strForCurLatitude = [NSString stringWithFormat:@"%f", coordinate.latitude];
    strForCurLongitude= [NSString stringWithFormat:@"%f", coordinate.longitude];
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:[strForCurLatitude doubleValue] longitude:[strForCurLongitude doubleValue] zoom:15];
    [mapView setCamera:camera];
//    mapView.myLocationEnabled = YES;
    mapView.delegate=self;
    
    
    // Build a circle for the GMSMapView
    GMSCircle *geoFenceCircle = [[GMSCircle alloc] init];
    geoFenceCircle.radius = 150; // Meters
    geoFenceCircle.position = coordinate; // Some CLLocationCoordinate2D position
    geoFenceCircle.fillColor = [UIColor colorWithWhite:0.7 alpha:0.5];
    geoFenceCircle.strokeWidth = 0.5;
    geoFenceCircle.strokeColor = [UIColor blueColor];
    geoFenceCircle.map = mapView; // Add it to the map.
    
    
    GMSMarker *markerCar = [[GMSMarker alloc] init];
    
    markerCar.icon=[UIImage imageNamed:@"location_marker"];
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:2.0];
    markerCar.position =  coordinate;
    [CATransaction commit];
    
    
    markerCar.map = mapView;
    _lblStoreName.text=@"";
    
    
    _vwForImgPreview.hidden = YES;
    
    if (IS_IPHONE_4) {
        _heightOfImgPrvw.constant = 200;
        _widthOfImgPrvw.constant = 200;
    }
}

-(void)viewWillAppear:(BOOL)animated{
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
    
    if (![APPDELEGATE connected]) {
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"Please check your connection" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
    [self checkStatus];
    
//    NSLog(@"Image Data===%@",[self getImageData]);
    NSLog(@"Time Line Data===%lu",(unsigned long)[[self getTimeLineData] count]);
}

-(void)checkStatus{
    NSString *statusData=[self getStatus];
    
    if ([statusData length]<=0) {
        NSLog(@"No data found");
        _lblTimeInStatus.text=@"Time In";
    }else if([statusData isEqualToString:@"TimeIn"]){
        //TimeIn
        _lblTimeInStatus.text=@"Time Out";
    }else if([statusData isEqualToString:@"TimeOut"]){
        //TimeIn
        _lblTimeInStatus.text=@"Time In";
    }
}

-(NSMutableArray*)getImageData{
    NSError *error=nil;
    
    NSMutableArray *arrayOfData=[[NSMutableArray alloc] init];

    self.timeLineStatusEntity=[NSEntityDescription entityForName:@"ImageData" inManagedObjectContext:APPDELEGATE.managedObjectContext];
    NSFetchRequest * fr = [[NSFetchRequest alloc]init];
    [fr setEntity:self.timeLineStatusEntity];
    NSArray * result = [APPDELEGATE.managedObjectContext executeFetchRequest:fr error:&error];
    
    for (NSManagedObject * fetRec  in result) {
        NSMutableDictionary *dict=[[NSMutableDictionary alloc] init];
        //success userimage
        [dict setValue:[fetRec valueForKey:@"success"] forKey:@"success"];
        [dict setValue:[fetRec valueForKey:@"userimage"] forKey:@"userimage"];
        [arrayOfData addObject:dict];
    }
    
    return arrayOfData;
}

-(NSString*)getStatus{
    NSError *error=nil;
    
    NSString *statusData;
    
    self.timeLineStatusEntity=[NSEntityDescription entityForName:@"TimelineStatus" inManagedObjectContext:APPDELEGATE.managedObjectContext];
    NSFetchRequest * fr = [[NSFetchRequest alloc]init];
    [fr setEntity:self.timeLineStatusEntity];
    NSArray * result = [APPDELEGATE.managedObjectContext executeFetchRequest:fr error:&error];
    
    for (NSManagedObject * fetRec  in result) {
        statusData=[fetRec valueForKey:@"status"];
    }
    return statusData;
}

-(NSMutableArray*)getTimeLineData{
    
    NSError *error=nil;

    NSMutableArray *arrayOfData=[[NSMutableArray alloc] init];
    
    
    
    self.timeLineDataEntity=[NSEntityDescription entityForName:@"TimeLineData" inManagedObjectContext:APPDELEGATE.managedObjectContext];
    NSFetchRequest * fr = [[NSFetchRequest alloc]init];
    [fr setEntity:self.timeLineDataEntity];
    NSArray * result = [APPDELEGATE.managedObjectContext executeFetchRequest:fr error:&error];
    
    for (NSManagedObject * fetRec  in result) {
        NSMutableDictionary *dict=[[NSMutableDictionary alloc] init];
//actiontype clockdate comments latitude longitude productstoreid actionimage username issend
        [dict setValue:[fetRec valueForKey:@"username"] forKey:@"username"];
        [dict setValue:[fetRec valueForKey:@"actiontype"] forKey:@"actiontype"];
        [dict setValue:[fetRec valueForKey:@"clockdate"] forKey:@"clockdate"];
        [dict setValue:[fetRec valueForKey:@"comments"] forKey:@"comments"];
        [dict setValue:[fetRec valueForKey:@"latitude"] forKey:@"latitude"];
        [dict setValue:[fetRec valueForKey:@"longitude"] forKey:@"longitude"];
        [dict setValue:[fetRec valueForKey:@"productstoreid"] forKey:@"productstoreid"];
        [dict setValue:[fetRec valueForKey:@"actionimage"] forKey:@"actionimage"];
        [dict setValue:[fetRec valueForKey:@"issend"] forKey:@"issend"];
        [arrayOfData addObject:dict];
    }
    
    return arrayOfData;
}

-(void)getStoreDetails{
    
    dictForStoreDetails=[[NSMutableDictionary alloc] init];
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    
    NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    httpClient.parameterEncoding = AFFormURLParameterEncoding;
    [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    NSString *auth_String=[defaults valueForKey:@"BasicAuth"];
    
    
    [httpClient setDefaultHeader:@"Authorization" value:auth_String];
    NSMutableDictionary *dict=[[defaults objectForKey:@"UserData"] mutableCopy];
    
    
    NSString *urlPath=[NSString stringWithFormat:@"/rest/s1/ft/stores/%@",[dict valueForKey:@"partyId"]];
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET"
                                                            path:urlPath
                                                      parameters:nil];
    
    //====================================================RESPONSE
    //    [DejalBezelActivityView activityViewForView:self.view];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        
    }];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError *error = nil;
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
        
        //        [DejalBezelActivityView removeView];
        
        NSLog(@"Store Details==%@",JSON);
        
        dictForStoreDetails=[JSON mutableCopy];
        
        _lblStoreName.text=[dictForStoreDetails valueForKey:@"storeName"];
        
        [self checkLocation];
    }
     //==================================================ERROR
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         //                                         [DejalBezelActivityView removeView];
                                         NSLog(@"Error %@",[error description]);
                                     }];
    [operation start];
}

#pragma mark - LocationManagaer

//#pragma mark - Location Manager - Region Task Methods

- (void)checkLocation{
    
    NSMutableDictionary *dictToSendLctnStatus=[[NSMutableDictionary alloc] init];
    
    CLLocationDegrees latitude = [[dictForStoreDetails valueForKey:@"latitude"] doubleValue];
    CLLocationDegrees longitude =[[dictForStoreDetails valueForKey:@"longitude"] doubleValue];

    CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude
                                                          longitude:longitude];
    NSString *storeName=[dictForStoreDetails valueForKey:@"storeName"];
    CLLocationDistance distance = [location distanceFromLocation:locationManager.location];
        
        if (distance <= 100 && distance >= 0){
            
            NSLog(@"You are within 100 meters (actually %.0f meters) of Store", distance);
            _imgVwForLocationIcon.image=[UIImage imageNamed:@"location_On"];
            _lblForStoreLocation.text=[dictForStoreDetails valueForKey:@"storeName"];
            _lblForStoreLocation.textColor=[UIColor whiteColor];
            [dictToSendLctnStatus setObject:@"1" forKey:@"LocationStatus"];
            storeName=[dictForStoreDetails valueForKey:@"storeName"];
            boolValueForInLocationOrNot = YES;
        
        }else{
        
            NSLog(@"You are not within 100 meters (actually %.0f meters) of Store", distance);
            _imgVwForLocationIcon.image=[UIImage imageNamed:@"location_Off"];
            _lblForStoreLocation.text=@"Off site";
            _lblForStoreLocation.textColor=[UIColor darkGrayColor];
            [dictToSendLctnStatus setObject:@"0" forKey:@"LocationStatus"];
            storeName=@"Off site";
             boolValueForInLocationOrNot = NO;
        }
    
    if ([storeName length] <=0 || storeName  == nil) {
        storeName=@"Off site";
    }
    
    [dictToSendLctnStatus setObject:storeName forKey:@"StoreName"];
    
    [[MKSharedClass shareManager] setDictForCheckInLoctn:dictToSendLctnStatus];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LocationChecking" object:self userInfo:dictToSendLctnStatus];
    
    NSString *statusData=[self getStatus];
    
    if ([statusData length]<=0) {
        NSLog(@"Need to Time In");
    }else if([statusData isEqualToString:@"TimeIn"]){
        NSLog(@"Need to Time Out");
        
//        NSMutableDictionary *dictToSend=[self getTimeLineData];
        
//        NSLog(@"====%@",dictToSend);
        if (boolValueForInLocationOrNot == YES) {
            
        }else if (boolValueForInLocationOrNot == NO){
            
        }
    }else if([statusData isEqualToString:@"TimeOut"]){
        NSLog(@"Need to Time In");
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"Entered Region - %@", region.identifier);
    [self showRegionAlert:@"Entering Region" forRegion:region.identifier];
    [self checkLocation];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"Exited Region - %@", region.identifier);
    [self showRegionAlert:@"Exiting Region" forRegion:region.identifier];
    [self checkLocation];
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    NSLog(@"Started monitoring %@ region", region.identifier);
}

- (void) showRegionAlert:(NSString *)alertText forRegion:(NSString *)regionIdentifier {
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:alertText
                                                      message:regionIdentifier
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    [message show];
}

-(CLLocationCoordinate2D) getLocation{
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    [locationManager startUpdatingLocation];
    CLLocation *location = [locationManager location];
    CLLocationCoordinate2D coordinate = [location coordinate];
    return coordinate;
}

-(void)updateLocationManagerr{
    [locationManager startUpdatingLocation];
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate=self;
    locationManager.desiredAccuracy=kCLLocationAccuracyBest;
    locationManager.distanceFilter=kCLDistanceFilterNone;
//#ifdef __IPHONE_8_0
    [locationManager requestAlwaysAuthorization];
//#endif
    [locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation{
    
    strForCurLatitude=[NSString stringWithFormat:@"%f",newLocation.coordinate.latitude];
    strForCurLongitude=[NSString stringWithFormat:@"%f",newLocation.coordinate.longitude];
    
//    [self showingCurrentLocation];
    [self checkLocation];
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error{
    NSLog(@"didFailWithError: %@", error);
}

#pragma mark -

- (void)mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position{
   
}
-(void)mapViewDidFinishTileRendering:(GMSMapView *)mapView{
    //TAKE THE SCREENSHOT HERE
    
}
- (void) mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position{
    
   
}

#pragma mark -

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)onClickMyLocation:(UIButton *)sender {
    [self showingCurrentLocation];
}


-(void)showingCurrentLocation{
    [mapView clear];
    
    if ([CLLocationManager locationServicesEnabled]){
        CLLocationCoordinate2D coordinate;
        coordinate.latitude=[strForCurLatitude doubleValue];
        coordinate.longitude=[strForCurLongitude doubleValue];
        GMSCameraUpdate *updatedCamera = [GMSCameraUpdate setTarget:coordinate zoom:15];
        [mapView animateWithCameraUpdate:updatedCamera];
        
        
        GMSCircle *geoFenceCircle = [[GMSCircle alloc] init];
        geoFenceCircle.radius = 150; // Meters
        geoFenceCircle.position = coordinate; // Some CLLocationCoordinate2D position
        geoFenceCircle.fillColor = [UIColor colorWithWhite:0.7 alpha:0.5];
        geoFenceCircle.strokeWidth = 0.5;
        geoFenceCircle.strokeColor = [UIColor blueColor];
        geoFenceCircle.map = mapView; // Add it to the map.
        
        //        GMSMarker *markerCar = [GMSMarker markerWithPosition:coordinate];
        //        markerCar.appearAnimation = YES;
        //        markerCar.icon = [UIImage imageNamed:@"location_marker"];//pin_car_driver
        //        markerCar.map = mapView;
        
        GMSMarker *markerCar = [[GMSMarker alloc] init];
        markerCar.icon=[UIImage imageNamed:@"location_marker"];
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:5.0];
        markerCar.position =  coordinate;
        [CATransaction commit];
        
        
        markerCar.map = mapView;
        
    }else{
        UIAlertView *alertLocation=[[UIAlertView alloc]initWithTitle:@"" message:@"Please Enable Location Access" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertLocation show];
    }

}

- (IBAction)onClickTimeIn:(UIButton *)sender {
    
    if (boolValueForInLocationOrNot){
            [self openCamera];
    }else{
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Not at store location" message:@"Please go to the store location and try again!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (IBAction)onClickPhotoConfirmBtn:(UIButton *)sender {
    
    _vwForImgPreview.hidden = YES;

    
    NSString *statusData=[self getStatus];
    
    NSString *strMsg;
    
    if ([statusData length]<=0) {
        strMsg=@"Confirm Time In";
    }else if([statusData isEqualToString:@"TimeIn"]){
        strMsg=@"Confirm Time Out";
    }else if([statusData isEqualToString:@"TimeOut"]){
       strMsg=@"Confirm Time In";
    }
    
    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:strMsg message:[NSString stringWithFormat:@"You are currently at %@",[dictForStoreDetails valueForKey:@"storeName"]] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Confirm", nil];
    [alert show];
    
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
//    NSLog(@"Clicked Button Index===%i",buttonIndex);
    if (buttonIndex == 1) {
//        if ([APPDELEGATE connected]) {
//            [self postImageDataToServer];
//        }else{
//            [self saveImageData:@"0"];
//        }
        [self saveDataIntoLocal];
        
        [self getTimeLineData];
        
//        NSLog(@"Time Line Data===%@",[self getTimeLineData]);
    }
}
/// Save Image If Network is not available
-(void)saveImageData:(NSString*)status{
    
     NSError *error = nil;
    self.timeLineStatusEntity = [NSEntityDescription entityForName:@"ImageData" inManagedObjectContext:APPDELEGATE.managedObjectContext];
    error=nil;
    NSManagedObject * imageManagedObject = [[NSManagedObject alloc]initWithEntity:self.timeLineStatusEntity insertIntoManagedObjectContext:APPDELEGATE.managedObjectContext];
     //success userimage
    [imageManagedObject setValue:status forKey:@"success"];
    
    if ([status isEqualToString:@"0"]) {
    ///Converting Image To string and saving
        NSString *imgData=[UIImagePNGRepresentation(imgToSend) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
         [imageManagedObject setValue:imgData forKey:@"userimage"];
    
    }else{
        [imageManagedObject setValue:@"success" forKey:@"userimage"];
    }
    
    [imageManagedObject.managedObjectContext save:&error];
    
    [self saveDataIntoLocal];
}

-(void)saveDataIntoLocal{
    
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    
    NSMutableDictionary *dict=[[defaults objectForKey:@"UserData"] mutableCopy];
    
    NSLog(@"User Name===%@",[dict valueForKey:@"username"]);
    
    NSString *userName=[dict valueForKey:@"username"];
    NSString *productStoreId=[dictForStoreDetails valueForKey:@"productStoreId"];
    
    NSDate *now = [NSDate date];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    NSLog(@"The Current Time is %@",[dateFormatter stringFromDate:now]);
    
    NSString *strCurrentTime=[dateFormatter stringFromDate:now];
    
    NSString *actionType;
    NSString *comments;
    
    NSString *statusData=[self getStatus];
    
    if ([statusData length]<=0) {
        comments=@"Time In";
        actionType=@"clockIn";
    }else if([statusData isEqualToString:@"TimeIn"]){
        comments=@"Time Out";
        actionType=@"clockOut";
    }else if([statusData isEqualToString:@"TimeOut"]){
        comments=@"Time In";
        actionType=@"clockIn";
    }
    
      NSString *imgData=[UIImagePNGRepresentation(imgToSend) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    
    NSDictionary * json = @{@"username":userName,
                            @"clockDate":strCurrentTime,
                            @"workEffortTypeEnumId":@"WetAvailable",
                            @"purposeEnumId":@"WepAttendance",
                            @"comments":comments,
                            @"productStoreId":productStoreId,
                            @"actionType":actionType,
                            @"actionImage":imgData,
                            @"latitude":strForCurLatitude,
                            @"longitude":strForCurLongitude,
                            @"issend":@"0",
                            };
    
    
    
  //  actiontype clockdate comments latitude longitude productstoreid actionimage username
    
    NSError *error = nil;
    self.timeLineDataEntity = [NSEntityDescription entityForName:@"TimeLineData" inManagedObjectContext:APPDELEGATE.managedObjectContext];
    error=nil;
    NSManagedObject * timelineManagedObject = [[NSManagedObject alloc]initWithEntity:self.timeLineDataEntity insertIntoManagedObjectContext:APPDELEGATE.managedObjectContext];
    //success userimage
    [timelineManagedObject setValue:[json valueForKey:@"actionType"] forKey:@"actiontype"];
    [timelineManagedObject setValue:[json valueForKey:@"clockDate"] forKey:@"clockdate"];
    [timelineManagedObject setValue:[json valueForKey:@"comments"] forKey:@"comments"];
    [timelineManagedObject setValue:[json valueForKey:@"latitude"] forKey:@"latitude"];
    [timelineManagedObject setValue:[json valueForKey:@"longitude"] forKey:@"longitude"];
    [timelineManagedObject setValue:[json valueForKey:@"productStoreId"] forKey:@"productstoreid"];
    [timelineManagedObject setValue:[json valueForKey:@"actionImage"] forKey:@"actionimage"];
    [timelineManagedObject setValue:[json valueForKey:@"username"] forKey:@"username"];
    [timelineManagedObject setValue:[json valueForKey:@"issend"] forKey:@"issend"];
    [timelineManagedObject.managedObjectContext save:&error];
    
    
    
    self.timeLineStatusEntity = [NSEntityDescription entityForName:@"TimelineStatus" inManagedObjectContext:APPDELEGATE.managedObjectContext];
    error=nil;
    NSManagedObject * karthikManagedObject = [[NSManagedObject alloc]initWithEntity:self.timeLineStatusEntity insertIntoManagedObjectContext:APPDELEGATE.managedObjectContext];
    
    if ([statusData length]<=0) {
        [karthikManagedObject setValue:[NSString stringWithFormat:@"TimeIn"] forKey:@"status"];
    }else if([statusData isEqualToString:@"TimeIn"]){
        [karthikManagedObject setValue:[NSString stringWithFormat:@"TimeOut"] forKey:@"status"];
    }else if([statusData isEqualToString:@"TimeOut"]){
        [karthikManagedObject setValue:[NSString stringWithFormat:@"TimeIn"] forKey:@"status"];
    }
    
    [karthikManagedObject.managedObjectContext save:&error];
    
    [self checkStatus];
}

- (IBAction)onClickRetakePhotoBtn:(UIButton *)sender {
    [self openCamera];
}

-(void)openCamera{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        imagePickerController.sourceType =UIImagePickerControllerSourceTypeCamera;
        imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        
        UIView *cameraOverlayView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 100.0f, 5.0f, 100.0f, 35.0f)];
        [cameraOverlayView setBackgroundColor:[UIColor blackColor]];
        UIButton *emptyBlackButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 35.0f)];
        [emptyBlackButton setBackgroundColor:[UIColor blackColor]];
        [emptyBlackButton setEnabled:YES];
        [cameraOverlayView addSubview:emptyBlackButton];
        
        imagePickerController.allowsEditing = YES;
        imagePickerController.showsCameraControls = YES;
        imagePickerController.delegate = self;
        
        imagePickerController.cameraOverlayView = cameraOverlayView;
    }
    else{
        imagePickerController.sourceType =UIImagePickerControllerSourceTypePhotoLibrary;
    }

    [self presentViewController:imagePickerController animated:YES completion:^{
        
    }];
}
#pragma mark - ImagePickerDelegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    if([info valueForKey:UIImagePickerControllerOriginalImage]==nil){
        NSLog(@"Image Not Available");
    }
    else    {
        imgToSend=[info valueForKey:UIImagePickerControllerOriginalImage];
        _vwForImgPreview.hidden = NO;
        _imgVwForPhotoPreview.image=imgToSend;
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
                       [_params setObject:@"Time_Line" forKey:@"purpose"];
                       
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
                       NSData *imageData = UIImageJPEGRepresentation(imgToSend, 0.4);
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
                                              
                                              if ([jsonData objectForKey:@"savedFilename"]){
                                                  imgPathToSend=[jsonData valueForKey:@"savedFilename"];
                                                  [self timeLineUpdating];
                                              }
                                          }
                                          [DejalBezelActivityView removeView];
                                      });
                   });
}
#pragma mark - Time Line Update
-(void)timeLineUpdating
{
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    httpClient.parameterEncoding = AFFormURLParameterEncoding;
    [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    NSString *str=[defaults valueForKey:@"BasicAuth"];
    
    NSMutableDictionary *dict=[[defaults objectForKey:@"UserData"] mutableCopy];
    
    NSLog(@"User Name===%@",[dict valueForKey:@"username"]);
    
    NSString *userName=[dict valueForKey:@"username"];
    NSString *productStoreId=[dictForStoreDetails valueForKey:@"productStoreId"];
    
    NSDate *now = [NSDate date];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    NSLog(@"The Current Time is %@",[dateFormatter stringFromDate:now]);

    NSString *strCurrentTime=[dateFormatter stringFromDate:now];
    
    
    [httpClient setDefaultHeader:@"Authorization" value:str];
    
    //{"username":"anand@securet.in","clockDate":"2016-12-10 18:40:00","workEffortTypeEnumId":"WetAvailable","purposeEnumId":"WepAttendance","comments":"Clocking out now from ameerpet","productStoreId":"100051","actionType":"clockOut",'actionImage":"test.jpg","latitude":"15.00","longitude":"19.00"}
    
    // messages = "Successfully Clocked In!\n";
    //messages = "Successfully Clocked out!\n";
    
    NSString *actionType;
    NSString *comments;
    
    NSString *statusData=[self getStatus];
    
    if ([statusData length]<=0) {
        comments=@"Time In";
        actionType=@"clockIn";
    }else if([statusData isEqualToString:@"TimeIn"]){
        comments=@"Time Out";
        actionType=@"clockOut";
    }else if([statusData isEqualToString:@"TimeOut"]){
        comments=@"Time In";
        actionType=@"clockIn";
    }
    
    NSDictionary * json = @{@"username":userName,
                            @"clockDate":strCurrentTime,
                            @"workEffortTypeEnumId":@"WetAvailable",
                            @"purposeEnumId":@"WepAttendance",
                            @"comments":comments,
                            @"productStoreId":productStoreId,
                            @"actionType":actionType,
                            @"actionImage":imgPathToSend,
                            @"latitude":strForCurLatitude,
                            @"longitude":strForCurLongitude,
                            };
    
    NSLog(@"Time Line Data To Send====%@",json);
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST"
                                           path:@"/rest/s1/ft/attendance/log"
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
        NSLog(@"Add Store Successfully==%@",JSON);
        
        
//        self.timeLineStatusEntity = [NSEntityDescription entityForName:@"TimelineStatus" inManagedObjectContext:APPDELEGATE.managedObjectContext];
//        error=nil;
//        NSManagedObject * karthikManagedObject = [[NSManagedObject alloc]initWithEntity:self.timeLineStatusEntity insertIntoManagedObjectContext:APPDELEGATE.managedObjectContext];
//        
//        if ([[JSON valueForKey:@"messages"] containsString:@"Clocked In"]) {
//            [karthikManagedObject setValue:[NSString stringWithFormat:@"TimeIn"] forKey:@"status"];
//        }else if ([[JSON valueForKey:@"messages"] containsString:@"Clocked out"]){
//            [karthikManagedObject setValue:[NSString stringWithFormat:@"TimeOut"] forKey:@"status"];
//        }
//        
//        [karthikManagedObject.managedObjectContext save:&error];
        imgPathToSend=@"";
        [self checkStatus];
        
    }
     //==================================================ERROR
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         [DejalBezelActivityView removeView];
                                         NSLog(@"Error %@",[error description]);
                                     }];
    [operation start];
}

#pragma mark -
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
