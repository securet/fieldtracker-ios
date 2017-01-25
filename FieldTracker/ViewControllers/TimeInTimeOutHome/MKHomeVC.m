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
#import <QuartzCore/CAAnimation.h>
#import <AVFoundation/AVFoundation.h>
#import "MKAgentListCell.h"
#import "MKForgotPasswordVC.h"
#import "MKHistoryCustomCell.h"
@interface MKHomeVC ()
{
    IBOutlet GMSMapView *mapView;
    NSString *strForCurLatitude,*strForCurLongitude;
    NSMutableDictionary *dictForStoreDetails;
    UIImage *imgToSend;
    NSString *imgPathToSend;
    BOOL boolValueForInLocationOrNot;
    NSTimer *timerForShiftTime,*timerForLocation;
    NSMutableArray *arrayForStatusData,*arrayForAgents;
    AVCaptureSession *captureSession;
    AVCaptureVideoPreviewLayer *videoPreviewLayer;
    AVCaptureStillImageOutput *stillImageOutput;
    CGFloat radiusForStore;
    CLLocationCoordinate2D prevCurrLocation;
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
                _imgVwUser.image = img;
            });
        });
    }

    _bottomVw.layer.cornerRadius = 10;
    _bottomVw.layer.masksToBounds = YES;
    
    [self updateLocationManagerr];
    
    CLLocationCoordinate2D coordinate = [self getLocation];
    
    strForCurLatitude = [NSString stringWithFormat:@"%f", coordinate.latitude];
    strForCurLongitude= [NSString stringWithFormat:@"%f", coordinate.longitude];
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:coordinate.latitude longitude:coordinate.longitude zoom:15];
    [mapView setCamera:camera];
   mapView.myLocationEnabled = YES;
    mapView.delegate=self;

//    GMSMarker *markerCar = [[GMSMarker alloc] init];
//    markerCar.icon=[UIImage imageNamed:@"location_marker"];
//    [CATransaction begin];
//    [CATransaction setAnimationDuration:2.0];
//    markerCar.position =  coordinate;
//    [CATransaction commit];
//    markerCar.map = mapView;
    
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
    _vwForAgentData.hidden = YES;
    _vwForAgentIndividualData.hidden = YES;
    
    
    _cameraBtn.backgroundColor=[[UIColor lightGrayColor] colorWithAlphaComponent:0.4];
    _cameraBtn.layer.cornerRadius = _cameraBtn.frame.size.height/2;
    _cameraBtn.layer.masksToBounds = YES;
    
    _tableVwForTimeline.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableVwForTimeline.tableFooterView = [[UIView alloc] init];
    
    _vwForTimer.backgroundColor=[[UIColor whiteColor] colorWithAlphaComponent:0.7];
    
    _vwForManager.hidden = YES;
    
    if ([[dict valueForKey:@"roleTypeId"] isEqualToString:@"SalesExecutive"]){
        
        _vwForManager.hidden = NO;
        _tableVwForAgents.tableFooterView=[[UIView alloc] init];
        _tableVwForAgents.delegate = self;
        _tableVwForAgents.dataSource = self;

    }else{
        
    }
    
    [self checkStatus];
    [self startTimedTask];
    
    [self checkLocation];
    timerForLocation= [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(updateLocationBackground) userInfo:nil repeats:YES];
}

-(void)viewWillAppear:(BOOL)animated{
    
//    NSDictionary *pref = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.apple.timed"];
//    BOOL autotime = [[pref objectForKey:@"TMAutomaticTimeEnabled"] boolValue];
//    NSLog(@"Automatic time is %@", autotime ? @"enabled" : @"disabled");
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
    
    if (![APPDELEGATE connected]) {
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"Please check your connection" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
    if ([CLLocationManager locationServicesEnabled]) {
        
    }else{
        [[[UIAlertView alloc] initWithTitle:@""
                                    message:@"Please Enable GPS"
                                delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
    }
}

#pragma mark - Background Task

-(void)updateLocationBackground{
    
    CLLocationCoordinate2D coordinate=[self getLocation];
    strForCurLatitude=[NSString stringWithFormat:@"%f",coordinate.latitude];
    strForCurLongitude=[NSString stringWithFormat:@"%f",coordinate.longitude];
    [self checkLocation];
}

- (void)startTimedTask{
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
        NSLog(@"Started background task");
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
//#pragma mark-
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

#pragma mark - StoreDetails

-(void)getStoreDetails{
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
    NSString *auth_String=[defaults valueForKey:@"BasicAuth"];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    httpClient.parameterEncoding = AFFormURLParameterEncoding;
    [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [httpClient setDefaultHeader:@"Authorization" value:auth_String];
    
    NSMutableDictionary *dict=[[defaults objectForKey:@"UserData"] mutableCopy];
    NSString *urlPath=[NSString stringWithFormat:@"/rest/s1/ft/stores/%@",[dict valueForKey:@"productStoreId"]];
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
        
        dictForStoreDetails=[[NSMutableDictionary alloc] init];

        NSLog(@"Store Details==%@",JSON);
        dictForStoreDetails=[JSON mutableCopy];
        _lblStoreName.text=[dictForStoreDetails valueForKey:@"storeName"];
        CLLocationDegrees latitude = [[dictForStoreDetails valueForKey:@"latitude"] doubleValue];
        CLLocationDegrees longitude =[[dictForStoreDetails valueForKey:@"longitude"] doubleValue];
        radiusForStore = [[dictForStoreDetails valueForKey:@"proximityRadius"] doubleValue];
        
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        [defaults setObject:dictForStoreDetails forKey:@"StoreData"];
        //storeName
        CLLocationCoordinate2D coordinate;
        coordinate.latitude = latitude;
        coordinate.longitude = longitude;
        
        // Build a circle for the GMSMapView
        GMSCircle *geoFenceCircle = [[GMSCircle alloc] init];
        geoFenceCircle.radius = radiusForStore; // Meters
        geoFenceCircle.position = coordinate; // Some CLLocationCoordinate2D position
        geoFenceCircle.fillColor = [UIColor colorWithWhite:0.7 alpha:0.7];
        geoFenceCircle.strokeWidth = 1.5;
        geoFenceCircle.strokeColor = [UIColor blueColor];
        geoFenceCircle.map = mapView; // Add it to Map
        
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
#pragma mark - UITableView
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    if (tableView == _tableVwForAgents) {
        return 10;
    }
    if (tableView == _tableVwForHistoryOfAgent) {
        return 10;
    }
    if (tableView == _tableVwIndividualHistory) {
        return 10;
    }
    return arrayForStatusData.count;
}
 
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (tableView == _tableVwForAgents) {
        MKAgentListCell *cell=[tableView dequeueReusableCellWithIdentifier:@"Cell"];
        if (cell==nil) {
            cell=[[MKAgentListCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    
    if (tableView == _tableVwForHistoryOfAgent) {
        MKHistoryCustomCell *cell=[tableView dequeueReusableCellWithIdentifier:@"Cell"];
        if (cell==nil) {
            cell=[[MKHistoryCustomCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }

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
    
    cell.imgVwForLine.backgroundColor=[UIColor lightGrayColor];
    
    
    if (tableView == _tableVwIndividualHistory) {
         cell.lblForTime.text=@"06:30 AM";
        
        
        if (indexPath.row==9){
            cell.centerConstraint.constant = 0;
            cell.imgVwForStatusIcon.image=[UIImage imageNamed:@"dot_timeout"];
            cell.lblForStatus.text=@"Time Out";
            cell.imgVwForTopVerticalLine.hidden=NO;
            cell.imgVwForBtmVerticalLine.hidden=YES;
        }
        
    }else{

        if (![[arrayForStatusData objectAtIndex:indexPath.row] isKindOfClass:[NSNull class]]) {
            cell.lblForTime.text= [self getTimeIndividual:[arrayForStatusData objectAtIndex:indexPath.row]];
        }else{
            cell.lblForTime.text=@"";
            cell.imgVwForStatusIcon.image=[UIImage imageNamed:@""];
            cell.lblForStatus.text=@"";
            cell.imgVwForLine.backgroundColor=[UIColor clearColor];
        }
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (tableView == _tableVwForAgents) {
        _vwForAgentData.hidden = NO;
        _backBtn.hidden = NO;
        _tableVwForHistoryOfAgent.delegate = self;
        _tableVwForHistoryOfAgent.dataSource = self;
        [_tableVwForHistoryOfAgent reloadData];
    }
    
    if (tableView == _tableVwForHistoryOfAgent) {
        _vwForAgentIndividualData.hidden = NO;
        _tableVwIndividualHistory.delegate = self;
        _tableVwIndividualHistory.dataSource = self;
        [_tableVwIndividualHistory reloadData];
    }
}

-(NSString*)getTimeIndividual:(NSString*)strDate
{
    if ([strDate isKindOfClass:[NSNull class]]) {
        return @"--";
    }

    NSString *strDateChange=strDate;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss Z";
    NSDate *date_1 = [dateFormatter dateFromString:strDateChange];
    dateFormatter.dateFormat = @"hh:mm a";
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    strDateChange = [dateFormatter stringFromDate:date_1];
    return strDateChange;
}

-(NSString*)getTime:(NSString*)strDate
{
    
    NSRange range=[strDate rangeOfString:@"T"];
    strDate=[strDate substringFromIndex:NSMaxRange(range)];
    range=[strDate rangeOfString:@"+"];
    
    NSString * timeZone=[strDate substringFromIndex:NSMaxRange(range)-1];
    strDate=[strDate substringToIndex:NSMaxRange(range)-1];
    strDate=[NSString stringWithFormat:@"%@ %@",strDate,timeZone];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss xxxx"];
    NSDate *date_1 = [dateFormatter dateFromString:strDate];
    
    [dateFormatter setDateFormat:@"hh:mm a"];
    
    return [dateFormatter stringFromDate:date_1];
}
#pragma mark - LocationManagaer

//#pragma mark - Location Manager - Region Task Methods

- (void)checkLocation{
    
    [[MKSharedClass shareManager] setDictForCheckInLoctn:nil];
    
    dictForStoreDetails=[[NSMutableDictionary alloc] init];
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"StoreData"] != nil){
        
        dictForStoreDetails=[[defaults objectForKey:@"StoreData"] mutableCopy];
        
        NSMutableDictionary *dictToSendLctnStatus=[[NSMutableDictionary alloc] init];
        CLLocationDegrees latitude = [[dictForStoreDetails valueForKey:@"latitude"] doubleValue];
        CLLocationDegrees longitude =[[dictForStoreDetails valueForKey:@"longitude"] doubleValue];
        CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude
                                                          longitude:longitude];
        NSString *storeName=[dictForStoreDetails valueForKey:@"storeName"];
        
//        CLLocationCoordinate2D coordinate = [self getLocation];
//        CLLocation *userLocation= [[CLLocation alloc] initWithLatitude:coordinate.latitude
//                                                             longitude:coordinate.longitude];
        CLLocationDistance distance = [location distanceFromLocation:mapView.myLocation];
         radiusForStore = [[dictForStoreDetails valueForKey:@"proximityRadius"] doubleValue];
        
        //SalesExecutive
        //FieldExecutiveOnPremise
        //FieldExectiveOffPremise
        
        if (distance <= radiusForStore && distance >= 0){
            _imgVwForLocationIcon.image=[UIImage imageNamed:@"location_On"];
            _lblForStoreLocation.text=[dictForStoreDetails valueForKey:@"storeName"];
            _lblForStoreLocation.textColor=[UIColor whiteColor];
            [dictToSendLctnStatus setObject:@"1" forKey:@"LocationStatus"];
            storeName= [dictForStoreDetails valueForKey:@"storeName"];
            boolValueForInLocationOrNot = YES;
            _lblStoreName.text=storeName;
        }else{
            _imgVwForLocationIcon.image=[UIImage imageNamed:@"location_Off"];
            _lblForStoreLocation.text=@"Off site";
            _lblForStoreLocation.textColor=[UIColor darkGrayColor];
            [dictToSendLctnStatus setObject:@"0" forKey:@"LocationStatus"];
            storeName=@"Off site";
            boolValueForInLocationOrNot = NO;
            _lblStoreName.text=@"(Not at location)";
        }
        
        NSMutableDictionary *dict=[[defaults objectForKey:@"UserData"] mutableCopy];

        if ([[dict valueForKey:@"roleTypeId"] isEqualToString:@"SalesExecutive"] || [[dict valueForKey:@"roleTypeId"] isEqualToString:@"FieldExectiveOffPremise"]) {
            boolValueForInLocationOrNot = YES;
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
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"Entered Region - %@", region.identifier);
    [self showRegionAlert:@"Entering Region" forRegion:region.identifier];
//    [self checkLocation];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"Exited Region - %@", region.identifier);
    [self showRegionAlert:@"Exiting Region" forRegion:region.identifier];
//    [self checkLocation];
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
    locationManager.allowsBackgroundLocationUpdates = YES;
     [locationManager requestAlwaysAuthorization];
    if([locationManager respondsToSelector:@selector(allowsBackgroundLocationUpdates)]){
        [locationManager setAllowsBackgroundLocationUpdates:YES];
    }
    [locationManager startUpdatingLocation];
    CLLocation *location = [locationManager location];
    CLLocationCoordinate2D coordinate = [location coordinate];
    return coordinate;
}

-(void)updateLocationManagerr{
   
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate=self;
    locationManager.desiredAccuracy=kCLLocationAccuracyBest;
    locationManager.distanceFilter=kCLDistanceFilterNone;
    //#ifdef __IPHONE_8_0
    [locationManager requestAlwaysAuthorization];
    //#endif
     locationManager.allowsBackgroundLocationUpdates = YES;
    if([locationManager respondsToSelector:@selector(allowsBackgroundLocationUpdates)]){
        [locationManager setAllowsBackgroundLocationUpdates:YES];
    }
    
    [locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation{
    
    strForCurLatitude=[NSString stringWithFormat:@"%f",newLocation.coordinate.latitude];
    strForCurLongitude=[NSString stringWithFormat:@"%f",newLocation.coordinate.longitude];
    [self checkLocation];
    
    if (newLocation.coordinate.latitude == prevCurrLocation.latitude && newLocation.coordinate.longitude == prevCurrLocation.longitude){
        
    }else{

        [self showingCurrentLocation];
//        [mapView_ clear];
//        mapView_.delegate=self;
//        marker = [[GMSMarker alloc] init];
//        [CATransaction begin];
//        [CATransaction setAnimationDuration:2.0];
//        marker.position = current;
//        [CATransaction commit];
//        marker.icon = [UIImage imageNamed:@"pin_driver"];
//        marker.map = mapView_;
        prevCurrLocation=newLocation.coordinate;
    }
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
//    NSLog(@"Location Updates====%@,%@",strForCurLatitude,strForCurLongitude);
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
- (IBAction)onClickMyLocation:(UIButton *)sender {
    
    if ([CLLocationManager locationServicesEnabled]) {
        [self showingCurrentLocation];
    }else{
        [[[UIAlertView alloc] initWithTitle:@""
                                    message:@"Please Enable GPS"
                                   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
    }
}

-(void)showingCurrentLocation{
    [mapView clear];
    
    if ([CLLocationManager locationServicesEnabled]){
        CLLocationCoordinate2D coordinate;
        coordinate.latitude=[strForCurLatitude doubleValue];
        coordinate.longitude=[strForCurLongitude doubleValue];
        
        CLLocation* gps = [[CLLocation alloc]
                           initWithLatitude:coordinate.latitude
                           longitude:coordinate.longitude];
        NSDate* now = gps.timestamp;
        
        strForCurLatitude = [NSString stringWithFormat:@"%f", coordinate.latitude];
        strForCurLongitude= [NSString stringWithFormat:@"%f", coordinate.longitude];
        
        NSLog(@"Time Got From GPS===%@",[self getTimeIndividual:now.description]);
        GMSCameraUpdate *updatedCamera = [GMSCameraUpdate setTarget:coordinate zoom:15];
        [mapView animateWithCameraUpdate:updatedCamera];
        mapView.myLocationEnabled = YES;
        
        //CLLocationCoordinate2D coordinate=mapView.myLocation;
//        GMSMarker *markerCar = [[GMSMarker alloc] init];
//        markerCar.icon=[UIImage imageNamed:@"location_marker"];
//        [CATransaction begin];
//        [CATransaction setAnimationDuration:5.0];
//        markerCar.position =  coordinate;
//        [CATransaction commit];
//        markerCar.map = mapView;
        
        CLLocationDegrees latitude = [[dictForStoreDetails valueForKey:@"latitude"] doubleValue];
        CLLocationDegrees longitude =[[dictForStoreDetails valueForKey:@"longitude"] doubleValue];
        
//        CLLocationCoordinate2D coordinate;
        coordinate.latitude = latitude;
        coordinate.longitude = longitude;
        
        GMSCircle *geoFenceCircle = [[GMSCircle alloc] init];
        geoFenceCircle.radius = radiusForStore; // Meters
        geoFenceCircle.position = coordinate; // Some CLLocationCoordinate2D position
        geoFenceCircle.fillColor = [UIColor colorWithWhite:0.7 alpha:0.7];
        geoFenceCircle.strokeWidth = 1.5;
        geoFenceCircle.strokeColor = [UIColor blueColor];
        geoFenceCircle.map = mapView;
        
    }else{
        UIAlertView *alertLocation=[[UIAlertView alloc]initWithTitle:@"" message:@"Please Enable Location Access" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertLocation show];
    }
}

- (IBAction)onClickTimeIn:(UIButton *)sender {
    
    if ([APPDELEGATE connected]) {
        if (boolValueForInLocationOrNot){
            [self openCamera];
        }else{
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Not at store location" message:@"Please go to the store location and try again!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        }
    }else{
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"It appears there is no internet conection!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
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
   
    NSError *error;
    AVCaptureDevice *captureDevice = [self frontFacingCamera];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (!input){
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
    
    for (AVCaptureConnection *connection in [stillImageOutput connections]){
        for (AVCaptureInputPort *port in [connection inputPorts]){
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ){
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection){
            break;
        }
    }
    
    NSLog(@"About to request a capture from: %@", stillImageOutput);
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error){
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
    
    if (![_vwForAgentData isHidden]) {
        
        if (![_vwForAgentIndividualData isHidden]) {
            _vwForAgentIndividualData.hidden=YES;
            _backBtn.hidden = NO;
        }else{
            _vwForAgentData.hidden=YES;
        }
    }
    
    
    self.tabBarController.tabBar.hidden =NO;
}

#pragma mark - ImagePickerDelegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    if([info valueForKey:UIImagePickerControllerOriginalImage]==nil){
        NSLog(@"Image Not Available");
    }else{
        imgToSend=[info valueForKey:UIImagePickerControllerOriginalImage];
        _vwForImgPreview.hidden = NO;
        _imgVwForPhotoPreview.image=imgToSend;
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void)postImageDataToServer:(NSDictionary*)dictToSend
                   withIndes:(NSInteger)indexValue{
    
    if ([[dictToSend valueForKey:@"actionimage"] isEqualToString:@"img"]) {
        imgPathToSend=@"img";
        [self timeLineUpdating:dictToSend withIndex:indexValue];
    }else{

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
                           NSMutableDictionary* _params = [[NSMutableDictionary alloc] init];
                           [_params setObject:@"Time_Line" forKey:@"purpose"];
                           
                           NSString *BoundaryConstant = @"----------V2ymHFg03ehbqgZCaKO6jy";
                           NSString* FileParamConstant = @"snapshotFile";
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
                           [request setHTTPBody:body];
                           NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[body length]];
                           [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
                           [request setURL:requestURL];
                           
                           dispatch_async(dispatch_get_main_queue(), ^{
                               
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
                                              //[DejalBezelActivityView removeView];
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
       
        NSMutableDictionary* _params = [[NSMutableDictionary alloc] init];
        [_params setObject:@"Time_Line" forKey:@"purpose"];
        NSString *BoundaryConstant = @"----------V2ymHFg03ehbqgZCaKO6jy";
        NSString* FileParamConstant = @"snapshotFile";
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
        NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[body length]];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setURL:requestURL];
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
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ssZ";
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSString *tzName = [timeZone name];
    
    NSLog(@"The Current Time is %@====%@",[dateFormatter stringFromDate:now],tzName);
    NSString *strCurrentTime=[dateFormatter stringFromDate:now];
    strCurrentTime = [strCurrentTime stringByReplacingOccurrencesOfString:@" " withString:@"T"];
    
    NSString *actionType;
    NSString *comments;
    //    NSString *statusData;
    NSDictionary * dictData=[self getStatus];
    
    if ([[dictData valueForKey:@"status"] length]<=0) {
        comments=@"Time In";
        actionType=@"clockIn";
        [defaults setObject:strCurrentTime forKey:@"TimeIn"];
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
        [defaults setObject:strCurrentTime forKey:@"TimeIn"];
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
   
   // NSMutableArray *arrayForStatus=[[NSMutableArray alloc] init];
    
    for (NSManagedObject * fetRec  in result) {
        //NSMutableDictionary *dicting=[[NSMutableDictionary alloc] init];
        statusData=[fetRec valueForKey:@"status"];
        [dict setValue:statusData forKey:@"status"];
        statusData=[fetRec valueForKey:@"comments"];
        [dict setValue:statusData forKey:@"comments"];
        statusData=[fetRec valueForKey:@"time"];
        [dict setValue:statusData forKey:@"time"];
//        dicting=[dict mutableCopy];
//        [arrayForStatus addObject:dicting];
    }
    
    //NSLog(@"arrayForStatus====%@",arrayForStatus);
    
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
        
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        NSString *strTime=[defaults objectForKey:@"TimeIn"];
        [self getTimerForTimeIn:strTime];
       // [self getTimerForTimeIn:[statusData valueForKey:@"time"]];
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
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ssZ";
//    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    firstViewd=[dateFormatter stringFromDate:now];
    
    NSString *lastViewedString;
    time = [time stringByReplacingOccurrencesOfString:@"T" withString:@" "];
    
    lastViewedString=time;
    NSInteger   hoursBetweenDates = 0;
    [dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ssZ"];
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
}

#pragma mark - Time Line Update
-(void)timeLineUpdating:(NSDictionary*)dataToSend
              withIndex:(NSInteger)indexValue
{
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
     NSString *strAuthorization=[defaults valueForKey:@"BasicAuth"];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    httpClient.parameterEncoding = AFFormURLParameterEncoding;
    [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [httpClient setDefaultHeader:@"Authorization" value:strAuthorization];
    
   // NSMutableDictionary *dict=[[defaults objectForKey:@"UserData"] mutableCopy];
//    NSLog(@"User Name===%@",[dict valueForKey:@"username"]);
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
    //    NSString *statusData=[self getStatus];
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
                                         NSLog(@"Error %@",[error userInfo]);
                                        // [self updateDatabase:indexValue];
                                         
                                         NSError *jsonError;
                                         NSData *objectData = [[[error userInfo] objectForKey:NSLocalizedRecoverySuggestionErrorKey] dataUsingEncoding:NSUTF8StringEncoding];
                                         
                                         if (objectData != nil) {
                                             
                                             NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                                                                  options:NSJSONReadingMutableContainers
                                                                                                    error:&jsonError];
                                             
                                             NSString *strError=[json valueForKey:@"errors"];
                                             if ([strError containsString:@"You cannot clock in twice"]) {
                                                 [self updateDatabase:indexValue];
                                             }
                                         }
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
    NSString *strAuthorization=[defaults valueForKey:@"BasicAuth"];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    httpClient.parameterEncoding = AFFormURLParameterEncoding;
    [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [httpClient setDefaultHeader:@"Authorization" value:strAuthorization];
    
    NSMutableDictionary *dict=[[defaults objectForKey:@"UserData"] mutableCopy];
    NSLog(@"%@",[dict valueForKey:@"username"]);
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
//    NSLog(@"The Current Time is %@",[dateFormatter stringFromDate:now]);
    //estimatedStartDate=2016-12-11 00:00:00&estimatedCompletionDate=2016-12-11 23:50:59
//    NSString *startDate=[NSString stringWithFormat:@"estimatedStartDate=%@ 00:00:00",[dateFormatter stringFromDate:now]];
//    NSString *endDate=[NSString stringWithFormat:@"estimatedCompletionDate=%@ 23:50:59",[dateFormatter stringFromDate:now]];
    NSString *strPath=[NSString stringWithFormat:@"/rest/s1/ft/attendance/log/?username=%@&pageIndex=0&pageSize=1",[dict valueForKey:@"username"]];
    NSLog(@"String Path for Get History===%@",strPath);
    NSString *strURL=[strPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    strURL=[strURL stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET"
                                                            path:strURL
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
      
        NSMutableArray *array=[[JSON objectForKey:@"userTimeLog"] mutableCopy];
        arrayForStatusData=[[NSMutableArray alloc] init];
        for (NSDictionary *dict in [[array firstObject] objectForKey:@"timeEntryList"]) {
            [arrayForStatusData addObject:[dict valueForKey:@"fromDate"]];
            [arrayForStatusData addObject:[dict valueForKey:@"thruDate"]];
        }
        
        [arrayForStatusData removeObjectIdenticalTo:[NSNull null]];
        // create the date formatter with the correct format
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss xxxx"];
        NSMutableArray *tempArray = [NSMutableArray array];
        // fast enumeration of the array
        for (NSString *dateString in arrayForStatusData) {
            if (![dateString isKindOfClass:[NSNull class]]) {
                NSString *str=dateString;
                str = [str stringByReplacingOccurrencesOfString:@"T" withString:@" "];
                str = [str stringByReplacingOccurrencesOfString:@"+0000" withString:@" +0000"];
                NSDate *date_1 = [formatter dateFromString:str];
                [tempArray addObject:date_1.description];
            }
        }
        // sort the array of dates
        [tempArray sortUsingComparator:^NSComparisonResult(NSDate *date1, NSDate *date2) {
            // return date2 compare date1 for descending. Or reverse the call for ascending.
            return [date2 compare:date1];
        }];

        tempArray =[[[tempArray reverseObjectEnumerator] allObjects] mutableCopy];
        
        NSMutableArray *correctOrderStringArray = [NSMutableArray array];
        
        for (NSDate *date_1 in tempArray) {
      //      NSString *dateString = [formatter stringFromDate:date_1];
            [correctOrderStringArray addObject:date_1.description];
        }
        
        arrayForStatusData = [correctOrderStringArray mutableCopy];
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
