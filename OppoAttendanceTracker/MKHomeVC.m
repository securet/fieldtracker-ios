//
//  MKHomeVC.m
//  OppoAttendanceTracker
//
//  Created by User1 on 12/20/16.
//
//

#import "MKHomeVC.h"
#import <GoogleMaps/GoogleMaps.h>
#import "MKIndividualHistoryCell.h"
#import <AVFoundation/AVFoundation.h>
@interface MKHomeVC ()
{
    IBOutlet GMSMapView *mapView;
    NSString *strForCurLatitude,*strForCurLongitude;
    NSMutableDictionary *dictForStoreDetails;
    UIImage *imgToSend;
    NSString *imgPathToSend;
    BOOL boolValueForInLocationOrNot;
    NSTimer *timerForShiftTime;
    NSMutableArray *arrayForStatusData;
    AVCaptureSession *captureSession;
    AVCaptureVideoPreviewLayer *videoPreviewLayer;
    AVCaptureStillImageOutput *stillImageOutput;
    
    CGFloat radiusForStore;
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
   // mapView.myLocationEnabled = YES;
    mapView.delegate=self;
    
    

    
    
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
    
    _vwForTimer.hidden = YES;
    _tableVwForTimeline.hidden = YES;
    _vwForCamera.hidden = YES;
    _backBtn.hidden = YES;
    
    
    _cameraBtn.backgroundColor=[[UIColor lightGrayColor] colorWithAlphaComponent:0.4];
    _cameraBtn.layer.cornerRadius = _cameraBtn.frame.size.height/2;
    _cameraBtn.layer.masksToBounds = YES;
    
    _tableVwForTimeline.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableVwForTimeline.tableFooterView = [[UIView alloc] init];
    
    _vwForTimer.backgroundColor=[[UIColor whiteColor] colorWithAlphaComponent:0.7];
    [self checkStatus];
    
       [self startTimedTask];
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
}

#pragma mark - Background Task

- (void)startTimedTask
{
    timerForShiftTime= [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkStatus) userInfo:nil repeats:YES];
}




-(void)startBackgroundTask{
    UIApplication*    app = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier task;
    task = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:task];
        task = UIBackgroundTaskInvalid;
    }];
    // Start the long-running task and return immediately.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Do the work associated with the task.
        NSLog(@"Started background task timeremaining = %f", [app backgroundTimeRemaining]);
        if ([APPDELEGATE connected]) {
            
            NSMutableArray *arrayForData=[[NSMutableArray alloc] init];
            arrayForData=[self getTimeLineData];
            for (NSDictionary *dict in arrayForData) {
                if ([[dict valueForKey:@"issend"] integerValue] == 0) {
                    [self postData:dict withIndex:[arrayForData indexOfObject:dict]];
                }
            }
        }
        
        [app endBackgroundTask:task];
        task = UIBackgroundTaskInvalid;
    });
}
#pragma mark-


/*
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
 }*/

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
        
        CLLocationDegrees latitude = [[dictForStoreDetails valueForKey:@"latitude"] doubleValue];
        CLLocationDegrees longitude =[[dictForStoreDetails valueForKey:@"longitude"] doubleValue];
        
        radiusForStore = [[dictForStoreDetails valueForKey:@"proximityRadius"] doubleValue];
        
        CLLocationCoordinate2D coordinate;
        coordinate.latitude = latitude;
        coordinate.longitude = longitude;
        
        // Build a circle for the GMSMapView
        GMSCircle *geoFenceCircle = [[GMSCircle alloc] init];
        geoFenceCircle.radius = radiusForStore; // Meters
        geoFenceCircle.position = coordinate; // Some CLLocationCoordinate2D position
        geoFenceCircle.fillColor = [UIColor colorWithWhite:0.7 alpha:0.5];
        geoFenceCircle.strokeWidth = 0.5;
        geoFenceCircle.strokeColor = [UIColor blueColor];
        geoFenceCircle.map = mapView; // Add it to the map.

//            GMSMarker *markerCar = [[GMSMarker alloc] init];
//            markerCar.icon=[UIImage imageNamed:@"location_marker"];
//            [CATransaction begin];
//            [CATransaction setAnimationDuration:2.0];
//            markerCar.position =  coordinate;
//            [CATransaction commit];
//            markerCar.map = mapView;
        [self startBackgroundTask];

        [self checkLocation];
    }
     //==================================================ERROR
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         //                                         [DejalBezelActivityView removeView];
                                         NSLog(@"Error %@",[error description]);
                                     }];
    [operation start];
}
#pragma mark _ UITableView
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return arrayForStatusData.count;
    
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    MKIndividualHistoryCell *cell=[tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil) {
        cell=[[MKIndividualHistoryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    /*
     ////Image Names
     dot_login
     dot_inlocation
     dot_outlocation
     dot_timeout
     */
    if (indexPath.row==0) {
        cell.imgVwForStatusIcon.image=[UIImage imageNamed:@"dot_login"];
        cell.lblForStatus.text=@"Time In";
        cell.centerConstraint.constant = 0;
        cell.imgVwForTopVerticalLine.hidden=YES;
        cell.imgVwForBtmVerticalLine.hidden=NO;
    }else{
        if (indexPath.row % 2 == 0) {
            cell.imgVwForStatusIcon.image=[UIImage imageNamed:@"dot_inlocation"];
            cell.lblForStatus.text=@"In location";
            cell.centerConstraint.constant = -5;
        }else{
            cell.centerConstraint.constant = 5;
            cell.imgVwForStatusIcon.image=[UIImage imageNamed:@"dot_outlocation"];
            cell.lblForStatus.text=@"Out of location";
        }
        cell.imgVwForTopVerticalLine.hidden=NO;
        cell.imgVwForBtmVerticalLine.hidden=NO;
    }
    
    if (indexPath.row==arrayForStatusData.count-1){
        cell.centerConstraint.constant = 0;
        cell.imgVwForStatusIcon.image=[UIImage imageNamed:@"dot_timeout"];
        cell.lblForStatus.text=@"Time Out";
        cell.imgVwForTopVerticalLine.hidden=NO;
        cell.imgVwForBtmVerticalLine.hidden=YES;
    }
    
    cell.imgVwForLine.backgroundColor=[UIColor lightGrayColor];
    
    if (![[arrayForStatusData objectAtIndex:indexPath.row] isKindOfClass:[NSNull class]]) {
        cell.lblForTime.text= [self getTime:[arrayForStatusData objectAtIndex:indexPath.row]];
    }else{
        cell.lblForTime.text=@"";
        cell.imgVwForStatusIcon.image=[UIImage imageNamed:@""];
        cell.lblForStatus.text=@"";
        cell.imgVwForLine.backgroundColor=[UIColor clearColor];
    }
    return cell;
}

-(NSString*)getTime:(NSString*)strDate
{
    //    strDate=[[arrayForTableData objectAtIndex:indexPath.row]valueForKey:@"estimatedCompletionDate"];
    
    NSRange range=[strDate rangeOfString:@"T"];
    strDate=[strDate substringFromIndex:NSMaxRange(range)];
    range=[strDate rangeOfString:@"+"];
    
    NSString * timeZone=[strDate substringFromIndex:NSMaxRange(range)-1];
    strDate=[strDate substringToIndex:NSMaxRange(range)-1];
    strDate=[NSString stringWithFormat:@"%@ %@",strDate,timeZone];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss xxxx"];
    NSDate *date = [dateFormatter dateFromString:strDate];
    
    [dateFormatter setDateFormat:@"hh:mm"];
    //    newDateString = [dateFormatter stringFromDate:date];
    
    return [dateFormatter stringFromDate:date];
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
    
   
    if (distance <= radiusForStore && distance >= 0){
        
        //        NSLog(@"You are within 100 meters (actually %.0f meters) of Store", distance);
        _imgVwForLocationIcon.image=[UIImage imageNamed:@"location_On"];
        _lblForStoreLocation.text=[dictForStoreDetails valueForKey:@"storeName"];
        _lblForStoreLocation.textColor=[UIColor whiteColor];
        [dictToSendLctnStatus setObject:@"1" forKey:@"LocationStatus"];
        storeName=[dictForStoreDetails valueForKey:@"storeName"];
        boolValueForInLocationOrNot = YES;
        
    }else{
        
        //        NSLog(@"You are not within 100 meters (actually %.0f meters) of Store", distance);
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
    
    if ([dictForStoreDetails valueForKey:@"address"]) {
        [dictToSendLctnStatus setObject:[dictForStoreDetails valueForKey:@"address"] forKey:@"StoreAddress"];
    }else{
        [dictToSendLctnStatus setObject:@"NA" forKey:@"StoreAddress"];
    }
    
    
    
    [[MKSharedClass shareManager] setDictForCheckInLoctn:dictToSendLctnStatus];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LocationChecking" object:self userInfo:dictToSendLctnStatus];
    
    NSDictionary *statusData=[self getStatus];
    
    
    
    NSMutableArray *arrayForTimeLine=[self getTimeLineData];
    
    NSDictionary *dictForBeforelast=[[NSDictionary alloc] init];
    
    if ([arrayForTimeLine count]>1) {
        dictForBeforelast=[arrayForTimeLine objectAtIndex:[arrayForTimeLine count]-2];
    }
    
    //     NSDictionary *timeLineData=[arrayForTimeLine lastObject];
    
    
    if ([[statusData valueForKey:@"status"] length]<=0) {
        
    }else if([[statusData valueForKey:@"status"] isEqualToString:@"TimeIn"]){
        
        if ([arrayForTimeLine count]>1) {
            if (boolValueForInLocationOrNot && [[dictForBeforelast valueForKey:@"comments"] isEqualToString:@"OutLocation"]) {
                [self saveDataIntoLocal:YES];
                
            }else if (!boolValueForInLocationOrNot && ([[dictForBeforelast valueForKey:@"comments"] isEqualToString:@"Time In"] || [[dictForBeforelast valueForKey:@"comments"] isEqualToString:@"InLocation"])){
                [self saveDataIntoLocal:YES];
            }
        }else if ([arrayForTimeLine count] ==1){
            [self saveDataIntoLocal:YES];
        }
        
    }else if([[statusData valueForKey:@"status"] isEqualToString:@"TimeOut"]){
        
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
        //mapView.myLocationEnabled = YES;
      
        GMSMarker *markerCar = [[GMSMarker alloc] init];
        markerCar.icon=[UIImage imageNamed:@"location_marker"];
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:5.0];
        markerCar.position =  coordinate;
        [CATransaction commit];
        markerCar.map = mapView;
        
        
        CLLocationDegrees latitude = [[dictForStoreDetails valueForKey:@"latitude"] doubleValue];
        CLLocationDegrees longitude =[[dictForStoreDetails valueForKey:@"longitude"] doubleValue];
        
//        CLLocationCoordinate2D coordinate;
        coordinate.latitude = latitude;
        coordinate.longitude = longitude;
        
        // Build a circle for the GMSMapView
        GMSCircle *geoFenceCircle = [[GMSCircle alloc] init];
        geoFenceCircle.radius = radiusForStore; // Meters
        geoFenceCircle.position = coordinate; // Some CLLocationCoordinate2D position
        geoFenceCircle.fillColor = [UIColor colorWithWhite:0.7 alpha:0.7];
        geoFenceCircle.strokeWidth = 1.5;
        geoFenceCircle.strokeColor = [UIColor blueColor];
        geoFenceCircle.map = mapView; // Add it to
        
        
    }else{
        UIAlertView *alertLocation=[[UIAlertView alloc]initWithTitle:@"" message:@"Please Enable Location Access" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertLocation show];
    }
    
    [self checkLocation];
    
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
    _backBtn.hidden = YES;
    
    NSDictionary *statusData=[self getStatus];
    
    NSString *strMsg;
    
    if ([[statusData valueForKey:@"status"] length]<=0) {
        strMsg=@"Confirm Time In";
    }else if([[statusData valueForKey:@"status"] isEqualToString:@"TimeIn"]){
        strMsg=@"Confirm Time Out";
    }else if([[statusData valueForKey:@"status"] isEqualToString:@"TimeOut"]){
        strMsg=@"Confirm Time In";
    }
    
    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:strMsg message:[NSString stringWithFormat:@"You are currently at %@",[dictForStoreDetails valueForKey:@"storeName"]] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Confirm", nil];
    [alert show];
    
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (buttonIndex == 1) {
        [self saveDataIntoLocal:NO];
        [self getTimeLineData];
    }
}

/*-(void)saveImageData:(NSString*)status{
 
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
 }*/


- (IBAction)onClickRetakePhotoBtn:(UIButton *)sender {
    [self openCamera];
}

-(void)openCamera{
    //    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    //    imagePickerController.delegate = self;
    //
    //    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
    //        imagePickerController.sourceType =UIImagePickerControllerSourceTypeCamera;
    //        imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    //
    //        UIView *cameraOverlayView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 100.0f, 5.0f, 100.0f, 35.0f)];
    //        [cameraOverlayView setBackgroundColor:[UIColor blackColor]];
    //        UIButton *emptyBlackButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 35.0f)];
    //        [emptyBlackButton setBackgroundColor:[UIColor blackColor]];
    //        [emptyBlackButton setEnabled:YES];
    //        [cameraOverlayView addSubview:emptyBlackButton];
    //
    //        imagePickerController.allowsEditing = YES;
    //        imagePickerController.showsCameraControls = YES;
    //        imagePickerController.delegate = self;
    //
    //        imagePickerController.cameraOverlayView = cameraOverlayView;
    //    }
    //    else{
    //        imagePickerController.sourceType =UIImagePickerControllerSourceTypePhotoLibrary;
    //    }
    //
    //    [self presentViewController:imagePickerController animated:YES completion:^{
    //
    //    }];
    
    
    NSError *error;
    
    AVCaptureDevice *captureDevice = [self frontFacingCamera];
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
    [videoPreviewLayer setFrame:_previewCamera.layer.bounds];
    [_previewCamera.layer addSublayer:videoPreviewLayer];
    [captureSession startRunning];
    
    self.tabBarController.tabBar.hidden =YES;
    
    _vwForCamera.hidden = NO;
    _backBtn.hidden = NO;
}


- (AVCaptureDevice *) frontFacingCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
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
    
    for (AVCaptureConnection *connection in [stillImageOutput connections])
    {
        for (AVCaptureInputPort *port in [connection inputPorts])
        {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] )
            {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection)
        {
            break;
        }
    }
    
    NSLog(@"About to request a capture from: %@", stillImageOutput);
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
     {
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         UIImage *image = [[UIImage alloc] initWithData:imageData];
         imgToSend=image;
         _vwForImgPreview.hidden = NO;
         _imgVwForPhotoPreview.image=imgToSend;
         _vwForCamera.hidden = YES;
     }];
    
    self.tabBarController.tabBar.hidden =NO;
    
}

- (IBAction)onClickBackBtn:(UIButton *)sender {
    
    _backBtn.hidden = YES;
    
    if (![_vwForCamera isHidden]) {
        if (![_vwForImgPreview isHidden]) {
            _backBtn.hidden = NO;
        }
        _vwForCamera.hidden = YES;
    }else if (![_vwForImgPreview isHidden]){
        _vwForImgPreview.hidden = YES;
        imgToSend=nil;
    }
    self.tabBarController.tabBar.hidden =NO;
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

-(void)postImageDataToServer:(NSDictionary*)dictToSend
                   withIndes:(NSInteger)indexValue
{
    if ([[dictToSend valueForKey:@"actionimage"] isEqualToString:@"img"]) {
        imgPathToSend=@"img";
        [self timeLineUpdating:dictToSend withIndex:indexValue];
    }else{
        
        
        //    [DejalBezelActivityView activityViewForView:self.view];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^
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
                           [request setTimeoutInterval:50];
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
                           
                           
                           
                           NSString *base64Encoded = [dictToSend valueForKey:@"actionimage"];
                           
                           NSData *imageData = [[NSData alloc] initWithBase64EncodedString:base64Encoded options:NSDataBase64DecodingIgnoreUnknownCharacters];
                           
                           
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
                                                      [self timeLineUpdating:dictToSend withIndex:indexValue];
                                                  }
                                              }
                                              //                                          [DejalBezelActivityView removeView];
                                          });
                       });
    }
}
-(void)postData:(NSDictionary*)dictToSend
      withIndex:(NSInteger)indexValue{
    
    
    if ([[dictToSend valueForKey:@"actionimage"] isEqualToString:@"img"]) {
        imgPathToSend=@"img";
        [self timeLineUpdating:dictToSend withIndex:indexValue];
    }else{
        
        
        //    [DejalBezelActivityView activityViewForView:self.view];
        
        
        
        // Dictionary that holds post parameters. You can set your post parameters that your server accepts or programmed to accept.
        NSMutableDictionary* _params = [[NSMutableDictionary alloc] init];
        [_params setObject:@"Time_Line" forKey:@"purpose"];
        
        // the boundary string : a random string, that will not repeat in post data, to separate post data fields.
        NSString *BoundaryConstant = @"----------V2ymHFg03ehbqgZCaKO6jy";
        
        // string constant for the post parameter 'snapshotFile'. My server uses this name: `snapshotFile`. Your's may differ
        NSString* FileParamConstant = @"snapshotFile";
        
        // the server url to which the image (or the media) is uploaded. Use your server url here
        
        NSString *stringURL=[NSString stringWithFormat:@"%@/apps/ft/Requests/uploadImage",APPDELEGATE.Base_URL];
        NSURL* requestURL = [NSURL URLWithString:stringURL];
        
        // create request
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        [request setHTTPShouldHandleCookies:NO];
        [request setTimeoutInterval:50];
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
        NSString *base64Encoded = [dictToSend valueForKey:@"actionimage"];
        
        NSData *imageData = [[NSData alloc] initWithBase64EncodedString:base64Encoded options:NSDataBase64DecodingIgnoreUnknownCharacters];
        
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
        
        // NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
        
        
        [request setHTTPBody:body];
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
        
        [[session dataTaskWithRequest:request
                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *requestError) {
                        NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
                        
                        if (requestError) {
                            NSLog(@"Request error occurred: %@", requestError);
                        }
                        //if communication was successful
                        NSLog(@"Response code %i", [HTTPResponse statusCode]);
                        NSInteger success = 1;
                        NSError *serializeError = nil;
                        NSDictionary *jsonData = [NSJSONSerialization
                                                  JSONObjectWithData:data
                                                  options:NSJSONReadingMutableContainers
                                                  error:&serializeError];
                        success = [jsonData[@"ERROR"] integerValue];
                        
                        if (serializeError) {
                            NSLog(@"JSON serialize error occurred: %@", serializeError);
                        }
                        
                        if ([jsonData objectForKey:@"savedFilename"]){
                            imgPathToSend=[jsonData valueForKey:@"savedFilename"];
                            [self timeLineUpdating:dictToSend withIndex:indexValue];
                        }
                        
                    }]
         resume];
        
    }
    
}
#pragma mark - Database Handling

-(void)saveDataIntoLocal:(BOOL)fromInLoctnOrOutLoctn{
    
    NSError *error = nil;
    
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
    //    NSString *statusData;
    NSDictionary * dictData=[self getStatus];
    
    if ([[dictData valueForKey:@"status"] length]<=0) {
        comments=@"Time In";
        actionType=@"clockIn";
    }else if([[dictData valueForKey:@"status"] isEqualToString:@"TimeIn"]){
        
        if (fromInLoctnOrOutLoctn) {
            
            if (boolValueForInLocationOrNot) {
                comments=@"InLocation";
                actionType=@"clockIn";
            }else{
                comments=@"OutLocation";
                actionType=@"clockOut";
            }
            
        }else{
            comments=@"Time Out";
            actionType=@"clockOut";
        }
    }else if([[dictData valueForKey:@"status"] isEqualToString:@"TimeOut"]){
        comments=@"Time In";
        actionType=@"clockIn";
    }
    
    NSString *imgData;
    if (imgToSend == nil || imgPathToSend == nil) {
        imgData=@"img";
    }else{
        imgData=[UIImagePNGRepresentation(imgToSend) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    }
    
    
    if (productStoreId.length>0) {
        
    
    
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
    
    
    
    //    NSLog(@"Saved Data====%@",json);
    
    //  actiontype clockdate comments latitude longitude productstoreid actionimage username
    
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
    
    error = nil;
    
    dictData=[self getStatus];
    
    self.timeLineStatusEntity = [NSEntityDescription entityForName:@"TimelineStatus" inManagedObjectContext:APPDELEGATE.managedObjectContext];
    
    NSManagedObject * karthikManagedObject = [[NSManagedObject alloc]initWithEntity:self.timeLineStatusEntity insertIntoManagedObjectContext:APPDELEGATE.managedObjectContext];
    
    if ([[dictData valueForKey:@"status"] length]<=0) {
        [karthikManagedObject setValue:[NSString stringWithFormat:@"TimeIn"] forKey:@"status"];
        [karthikManagedObject setValue:[NSString stringWithFormat:@"Time In"] forKey:@"comments"];
        
    }else if([[dictData valueForKey:@"status"] isEqualToString:@"TimeIn"]){
        
        if (([[dictData valueForKey:@"comments"] isEqualToString:@"Time In"] || [[dictData valueForKey:@"comments"] isEqualToString:@"Time Out"]) && fromInLoctnOrOutLoctn) {
            
            if (boolValueForInLocationOrNot) {
                [karthikManagedObject setValue:[NSString stringWithFormat:@"Time In"] forKey:@"comments"];
            }else{
                [karthikManagedObject setValue:[NSString stringWithFormat:@"Time Out"] forKey:@"comments"];
            }
            
            [karthikManagedObject setValue:[NSString stringWithFormat:@"TimeIn"] forKey:@"status"];
            
        }else{
            
            [karthikManagedObject setValue:[NSString stringWithFormat:@"TimeOut"] forKey:@"status"];
        }
        
    }else if([[dictData valueForKey:@"status"] isEqualToString:@"TimeOut"]){
        
        [karthikManagedObject setValue:[NSString stringWithFormat:@"TimeIn"] forKey:@"status"];
        [karthikManagedObject setValue:[NSString stringWithFormat:@"Time In"] forKey:@"comments"];
    }
    
    [karthikManagedObject setValue:strCurrentTime forKey:@"time"];
    [karthikManagedObject.managedObjectContext save:&error];
    
    
    imgPathToSend=@"";
    imgToSend=nil;
    [self checkStatus];
    
    
    [self startBackgroundTask];
    
    [self startTimedTask];
        
    }
}

-(NSDictionary*)getStatus{
    NSError *error=nil;
    
    NSString *statusData;
    
    self.timeLineStatusEntity=[NSEntityDescription entityForName:@"TimelineStatus" inManagedObjectContext:APPDELEGATE.managedObjectContext];
    NSFetchRequest * fr = [[NSFetchRequest alloc]init];
    [fr setEntity:self.timeLineStatusEntity];
    NSArray * result = [APPDELEGATE.managedObjectContext executeFetchRequest:fr error:&error];
    
    NSMutableDictionary *dict=[[NSMutableDictionary alloc] init];
    
    for (NSManagedObject * fetRec  in result) {
        statusData=[fetRec valueForKey:@"status"];
        [dict setValue:statusData forKey:@"status"];
        
        statusData=[fetRec valueForKey:@"comments"];
        [dict setValue:statusData forKey:@"comments"];
        
        
        statusData=[fetRec valueForKey:@"time"];
        [dict setValue:statusData forKey:@"time"];
    }
    
    
    //    NSLog(@"Status Data====%@",dict);
    if ([dict valueForKey:@"status"]) {
        if ([[dict valueForKey:@"status"] isEqualToString:@"TimeOut"]) {
            timerForShiftTime=nil;
            [timerForShiftTime invalidate];
        }
    }
    
    return dict;
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
    
    //    for (NSDictionary*dict in arrayOfData) {
    //        NSLog(@"User Name===%@",[dict valueForKey:@"username"]);
    //        NSLog(@"User Name===%@",[dict valueForKey:@"actiontype"]);
    //        NSLog(@"clockdate===%@",[dict valueForKey:@"clockdate"]);
    //        NSLog(@"comments===%@",[dict valueForKey:@"comments"]);
    //        NSLog(@"latitude===%@",[dict valueForKey:@"latitude"]);
    //        NSLog(@"longitude===%@",[dict valueForKey:@"longitude"]);
    //        NSLog(@"productstoreid===%@",[dict valueForKey:@"productstoreid"]);
    //        NSLog(@"issend===%@",[dict valueForKey:@"issend"]);
    //    }
    
    return arrayOfData;
}

-(void)updateDatabase:(NSInteger)index{
    
    NSArray* response;
    
    NSError *error=nil;
    
    NSManagedObjectContext *managedObjectContext = APPDELEGATE.managedObjectContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"TimeLineData"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(issend == issend)"];
    
    [fetchRequest setPredicate:predicate];
    
    response = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    
    [[response objectAtIndex:index] setValue:@"1" forKey:@"issend"];
    [managedObjectContext save:&error];
}


-(void)checkStatus{
    NSDictionary *statusData=[self getStatus];
    
    if ([[statusData valueForKey:@"status"] length]<=0) {
        _lblTimeInStatus.text=@"Time In";
        _vwForTimer.hidden=YES;
        timerForShiftTime=nil;
        [timerForShiftTime invalidate];
    }else if([[statusData valueForKey:@"status"] isEqualToString:@"TimeIn"]){
        _lblTimeInStatus.text=@"Time Out";
        _vwForTimer.hidden=NO;
        
        //        NSLog(@"Last Time Updated==%@",[statusData valueForKey:@"time"]);
        [self getTimerForTimeIn:[statusData valueForKey:@"time"]];
        
    }else if([[statusData valueForKey:@"status"] isEqualToString:@"TimeOut"]){
        _lblTimeInStatus.text=@"Time In";
        _vwForTimer.hidden=YES;
        timerForShiftTime=nil;
        [timerForShiftTime invalidate];
    }
}


-(void)getTimerForTimeIn:(NSString*)time{
    
    NSString *firstViewd;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    NSDate *now = [NSDate date];
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    firstViewd=[dateFormatter stringFromDate:now];
    
    
    
    NSString *lastViewedString;
    lastViewedString=time;
    
    NSInteger   hoursBetweenDates = 0;
    
    [dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
    NSDate *lastViewed = [dateFormatter dateFromString:lastViewedString];
    now = [dateFormatter dateFromString:firstViewd];
    NSTimeInterval distanceBetweenDates = [now timeIntervalSinceDate:lastViewed];
    double minutesInAnHour = 60;
    hoursBetweenDates = (distanceBetweenDates / minutesInAnHour);
    
    int hour = hoursBetweenDates / 60;
    int min = hoursBetweenDates % 60;
    
    int sec = [[firstViewd substringFromIndex:17] intValue] - [[lastViewedString substringFromIndex:17] intValue];
    if ([[firstViewd substringFromIndex:17] intValue] > [[lastViewedString substringFromIndex:17] intValue]) {
        sec = [[firstViewd substringFromIndex:17] intValue] - [[lastViewedString substringFromIndex:17] intValue];
    }
    else{
        sec = [[lastViewedString substringFromIndex:17] intValue] - [[firstViewd substringFromIndex:17] intValue];
        sec = 59 - sec;
    }
    
    NSString *timeString = [NSString stringWithFormat:@"%02d:%02d:%02d", hour, min, sec];
    
    _lblForTimer.text=timeString;
    _lblForTimer.textAlignment= NSTextAlignmentCenter;
    //    NSLog(@"Time Started==%@",timeString);
}

#pragma mark - Time Line Update
-(void)timeLineUpdating:(NSDictionary*)dataToSend
              withIndex:(NSInteger)indexValue
{
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    httpClient.parameterEncoding = AFFormURLParameterEncoding;
    [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    NSString *str=[defaults valueForKey:@"BasicAuth"];
    
    NSMutableDictionary *dict=[[defaults objectForKey:@"UserData"] mutableCopy];
    
    NSLog(@"User Name===%@",[dict valueForKey:@"username"]);
    
    //    NSString *userName=[dict valueForKey:@"username"];
    //    NSString *productStoreId=[dictForStoreDetails valueForKey:@"productStoreId"];
    
    //    NSDate *now = [NSDate date];
    //
    //    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    //    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    //    NSLog(@"The Current Time is %@",[dateFormatter stringFromDate:now]);
    //
    //    NSString *strCurrentTime=[dateFormatter stringFromDate:now];
    
    
    [httpClient setDefaultHeader:@"Authorization" value:str];
    
    //{"username":"anand@securet.in","clockDate":"2016-12-10 18:40:00","workEffortTypeEnumId":"WetAvailable","purposeEnumId":"WepAttendance","comments":"Clocking out now from ameerpet","productStoreId":"100051","actionType":"clockOut",'actionImage":"test.jpg","latitude":"15.00","longitude":"19.00"}
    
    // messages = "Successfully Clocked In!\n";
    //messages = "Successfully Clocked out!\n";
    
    
    /*
     
     NSLog(@"User Name===%@",[dict valueForKey:@"username"]);
     NSLog(@"User Name===%@",[dict valueForKey:@"actiontype"]);
     NSLog(@"clockdate===%@",[dict valueForKey:@"clockdate"]);
     NSLog(@"comments===%@",[dict valueForKey:@"comments"]);
     NSLog(@"latitude===%@",[dict valueForKey:@"latitude"]);
     NSLog(@"longitude===%@",[dict valueForKey:@"longitude"]);
     NSLog(@"productstoreid===%@",[dict valueForKey:@"productstoreid"]);
     NSLog(@"issend===%@",[dict valueForKey:@"issend"]);
     
     */
    //    NSString *actionType;
    //    NSString *comments;
    //
    //    NSString *statusData=[self getStatus];
    //
    //    if ([statusData length]<=0) {
    //        comments=@"Time In";
    //        actionType=@"clockIn";
    //    }else if([statusData isEqualToString:@"TimeIn"]){
    //        comments=@"Time Out";
    //        actionType=@"clockOut";
    //    }else if([statusData isEqualToString:@"TimeOut"]){
    //        comments=@"Time In";
    //        actionType=@"clockIn";
    //    }
    
    if (imgPathToSend.length<=0||imgPathToSend == nil) {
        imgPathToSend=@"img";
    }
    
    NSString *username=[dataToSend valueForKey:@"username"];
    
    NSString *productStoreId=[dataToSend valueForKey:@"productstoreid"];
    
    NSString *strCurrentTime=[dataToSend valueForKey:@"clockdate"];
    
    NSString *comments=[dataToSend valueForKey:@"comments"];
    
    NSString *actionType=[dataToSend valueForKey:@"actiontype"];
    
    NSString *latitude=[dataToSend valueForKey:@"latitude"];
    
    NSString *longitude=[dataToSend valueForKey:@"longitude"];
    
    
    NSDictionary * json = @{@"username":username,
                            @"clockDate":strCurrentTime,
                            @"workEffortTypeEnumId":@"WetAvailable",
                            @"purposeEnumId":@"WepAttendance",
                            @"comments":comments,
                            @"productStoreId":productStoreId,
                            @"actionType":actionType,
                            @"actionImage":imgPathToSend,
                            @"latitude":latitude,
                            @"longitude":longitude,
                            };
    
    NSLog(@"Time Line Data To Send====%@",json);
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST"
                                                            path:@"/rest/s1/ft/attendance/log"
                                                      parameters:json];
    
    //====================================================RESPONSE
    //    [DejalBezelActivityView activityViewForView:self.view];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        
    }];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError *error = nil;
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
        
        [DejalBezelActivityView removeView];
        NSLog(@"Add Store Successfully==%@",JSON);
        
        
        [self updateDatabase:indexValue];
        imgPathToSend=@"";
    }
     //==================================================ERROR
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         NSLog(@"Error %@",[error description]);
                                         [self updateDatabase:indexValue];
                                     }];
    [operation start];
}

#pragma mark -
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)onClickTimeline:(UIButton *)sender {
    if ([_tableVwForTimeline isHidden]) {
        [self getHistory];
        _tableVwForTimeline.hidden = NO;
        _imgVwForTimeline.image=[UIImage imageNamed:@"Timer_Off"];
    }else{
        _tableVwForTimeline.hidden = YES;
        _imgVwForTimeline.image=[UIImage imageNamed:@"Timer_On"];
    }
}
#pragma mark - Get History

-(void)getHistory
{
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    httpClient.parameterEncoding = AFFormURLParameterEncoding;
    [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    NSString *str=[defaults valueForKey:@"BasicAuth"];
    
    [httpClient setDefaultHeader:@"Authorization" value:str];
    
    
    NSMutableDictionary *dict=[[defaults objectForKey:@"UserData"] mutableCopy];
    NSLog(@"%@",[dict valueForKey:@"username"]);
    
    
    NSString *strPath=[NSString stringWithFormat:@"/rest/s1/ft/attendance/log/?username=%@&pageIndex=0&pageSize=1",[dict valueForKey:@"username"]];
    
    NSLog(@"String Path for Get History===%@",strPath);
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
        
        
        //        arrayForTableData=[[JSON objectForKey:@"userTimeLog"] mutableCopy];
        NSMutableArray *array=[[JSON objectForKey:@"userTimeLog"] mutableCopy];
        
        
        arrayForStatusData=[[NSMutableArray alloc] init];
        
        //        arrayForStatusData=[[arrayForTableData objectAtIndex:indexPath.row] objectForKey:@"timeEntryList"];
        
        for (NSDictionary *dict in [[array firstObject] objectForKey:@"timeEntryList"]) {
            [arrayForStatusData addObject:[dict valueForKey:@"fromDate"]];
            [arrayForStatusData addObject:[dict valueForKey:@"thruDate"]];
        }
        
        _tableVwForTimeline.delegate= self;
        _tableVwForTimeline.dataSource = self;
        [_tableVwForTimeline reloadData];
    }
     //==================================================ERROR
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         [DejalBezelActivityView removeView];
                                         NSLog(@"Error %@",[error description]);
                                     }];
    [operation start];
}


@end
