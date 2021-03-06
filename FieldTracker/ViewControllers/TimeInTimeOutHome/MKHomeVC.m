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
    NSTimer *timerForShiftTime,*timerForLocation,*timerForClockTime;
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
    
    [self getUserInfo];
    [self getStoreDetails];
    [self checkAppVersion];
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSMutableDictionary *dict=[[defaults objectForKey:@"UserData"] mutableCopy];
    self.lblFName.text=[dict valueForKey:@"firstName"];
    self.lblLName.text=[dict valueForKey:@"lastName"];
    
    if ([dict valueForKey:@"userPhotoPath"]) {
        
        NSString *baseURL=APPDELEGATE.Base_URL;
        NSString *str = [NSString stringWithFormat:@"//%@/uploads/uid/%@",[dict valueForKey:@"userPhotoPath"],baseURL];
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
    
    self.bottomVw.layer.cornerRadius = 10;
    self.bottomVw.layer.masksToBounds = YES;
    
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
    
    self.lblStoreName.text=@"";
    self.vwForImgPreview.hidden = YES;
    
    if (IS_IPHONE_4) {
        self.heightOfImgPrvw.constant = 200;
        self.widthOfImgPrvw.constant = 200;
    }
    
    self.vwForTimer.hidden = YES;
    self.tableVwForTimeline.hidden = YES;
    self.vwForCamera.hidden = YES;
    self.backBtn.hidden = YES;
    self.vwForAgentData.hidden = YES;
    self.vwForAgentIndividualData.hidden = YES;
    
    self.cameraBtn.backgroundColor=[[UIColor lightGrayColor] colorWithAlphaComponent:0.4];
    self.cameraBtn.layer.cornerRadius = self.cameraBtn.frame.size.height/2;
    self.cameraBtn.layer.masksToBounds = YES;
    
    self.tableVwForTimeline.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableVwForTimeline.tableFooterView = [[UIView alloc] init];
    
    self.vwForTimer.backgroundColor=[[UIColor whiteColor] colorWithAlphaComponent:0.7];
    self.vwForManager.hidden = YES;
    
    if ([[dict valueForKey:@"roleTypeId"] isEqualToString:@"SalesExecutive"]){
        //        self.vwForManager.hidden = NO;
        //        self.tableVwForAgents.tableFooterView=[[UIView alloc] init];
        //        self.tableVwForAgents.delegate = self;
        //        self.tableVwForAgents.dataSource = self;
    }else{
        
    }
    
    [self checkStatus];
    [self startTimedTask];
    
    [self checkLocation];
    
    timerForLocation= [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(updateLocationBackground) userInfo:nil repeats:YES];
    timerForClockTime=[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(clockTimeUpdating) userInfo:nil repeats:YES];
    self.tabBarController.delegate=self;
    
    
    
}

-(void)viewWillAppear:(BOOL)animated{
    
    [self updateLocationManagerr];
    
    self.navigationController.navigationBarHidden = YES;
    self.navigationItem.hidesBackButton = YES;
    [self.navigationItem setHidesBackButton:YES];
    
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
    
    [self checkStatus];
    [self checkForOneTimeLogin];
}

-(void) tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController{
    if (tabBarController.selectedIndex == 2) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MoreTabSelected" object:nil];
    }else if (tabBarController.selectedIndex ==1){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HistoryTabSelected" object:nil];
    }
}

-(void)clockTimeUpdating{
    NSDate *timeNow = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"hh:mm a";
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    self.lblTime.text=[[dateFormatter stringFromDate:timeNow] substringToIndex:[[dateFormatter stringFromDate:timeNow] length]-3];
    self.lblAMOrPM.text=[[dateFormatter stringFromDate:timeNow] substringFromIndex:[[dateFormatter stringFromDate:timeNow] length]-2];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clockTimeUpdating" object:nil];
}
#pragma mark - 

-(BOOL)checkForOneTimeLogin{
    
    NSMutableArray *arrayData=[self getTimeLineData];
    NSMutableArray *arrayOfDates=[[NSMutableArray alloc] init];
    NSMutableArray *arrayOfUsernames=[[NSMutableArray alloc] init];
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSMutableDictionary *dictUserData=[[defaults objectForKey:@"UserData"] mutableCopy];
    
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    NSString *strCurrentTime=[dateFormatter stringFromDate:now];
    
    BOOL isLoginTodayAlready = false;
    
    for (NSDictionary*dict in arrayData) {
        if ([[dict valueForKey:@"actiontype"] isEqualToString:@"clockOut"]) {
            [arrayOfDates addObject:dict];
        }
    }
    
    if (arrayOfDates.count > 0) {
        for (NSDictionary*dict in arrayOfDates) {
            if ([[[dict valueForKey:@"clockdate"] substringToIndex:10] isEqualToString:strCurrentTime]){
                [arrayOfUsernames addObject:dict];
            }
        }
    }else{
        isLoginTodayAlready = NO;
    }
    
    if (arrayOfUsernames.count > 0) {
        for (NSDictionary*dict in arrayOfUsernames) {
            if ([[dict valueForKey:@"username"]  isEqualToString:[dictUserData valueForKey:@"username"]]){
                isLoginTodayAlready = YES;
            }
        }
    }else{
        isLoginTodayAlready = NO;
    }
    
    if (!isLoginTodayAlready) {
        _btnForTimeInOut.enabled = YES;
    }else{
        _btnForTimeInOut.enabled = NO;
         _lblTimeInStatus.text=@"Time In/Out done for today";
            self.bottomVw.image=[UIImage imageNamed:@""];
            self.bottomVw.backgroundColor=[UIColor lightGrayColor];
    }
    return isLoginTodayAlready;
}

#pragma mark - Check App Version

-(void)checkAppVersion{
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
    NSString *auth_String=[defaults valueForKey:@"BasicAuth"];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    httpClient.parameterEncoding = AFFormURLParameterEncoding;
    [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [httpClient setDefaultHeader:@"Authorization" value:auth_String];
    
    NSString *urlPath=[NSString stringWithFormat:@"/rest/s1/ft/checkForceUpdate?operatingSystemId=IOS"];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET"
                                                            path:urlPath
                                                      parameters:nil];
    //====================================================RESPONSE
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
    }];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError *error = nil;
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
        
        NSDictionary* infoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString* currentVersion = infoDictionary[@"CFBundleShortVersionString"];
        if (![[JSON valueForKey:@"appVersion"] isEqualToString:currentVersion] && [[JSON valueForKey:@"forceUpdate"] isEqualToString:@"Y"]){
            UIAlertView *alertView=[[UIAlertView alloc]initWithTitle:@"Update" message:[JSON valueForKey:@"message"] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Update",nil];
            alertView.tag=200;
            [alertView show];
        }
    }
     //==================================================ERROR
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         NSLog(@"Error %@",[error description]);
                                     }];
    [operation start];
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
#pragma mark - Get User Info
-(void)getUserInfo{
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
    NSString *auth_String=[defaults valueForKey:@"BasicAuth"];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    httpClient.parameterEncoding = AFFormURLParameterEncoding;
    [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [httpClient setDefaultHeader:@"Authorization" value:auth_String];
    
    NSString *urlPath=[NSString stringWithFormat:@"/rest/s1/ft/user"];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET"
                                                            path:urlPath
                                                      parameters:nil];
    //====================================================RESPONSE
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
    }];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError *error = nil;
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
        
        
        if ([[JSON objectForKey:@"user"] isKindOfClass:[NSArray class]]) {
            if ([[JSON objectForKey:@"user"] count]>0)
            {
                NSMutableDictionary *filteredDictionary = [NSMutableDictionary dictionary];
                for (NSString * key in [[[JSON objectForKey:@"user"] objectAtIndex:0] allKeys]){
                    if (![key isEqualToString:@"reportingPerson"]) {
                        
                        if (![[[[JSON objectForKey:@"user"] objectAtIndex:0] objectForKey:key] isKindOfClass:[NSNull class]])
                            [filteredDictionary setObject:[[[JSON objectForKey:@"user"] objectAtIndex:0] objectForKey:key] forKey:key];
                    }
                }
                
                if ([[[JSON objectForKey:@"user"] objectAtIndex:0] objectForKey:@"reportingPerson"]) {
                    NSMutableDictionary *reportingPerson = [NSMutableDictionary dictionary];
                    
                    for (NSString * key in [[[JSON objectForKey:@"user"] objectAtIndex:0] objectForKey:@"reportingPerson"]){
                        
                        if (![key isEqualToString:@"reportingPerson"]) {
                            
                            if (![[[[[JSON objectForKey:@"user"] objectAtIndex:0] objectForKey:@"reportingPerson"] valueForKey:key] isKindOfClass:[NSNull class]])
                                
                                [reportingPerson setObject:[[[[JSON objectForKey:@"user"] objectAtIndex:0] objectForKey:@"reportingPerson"] valueForKey:key] forKey:key];
                        }
                    }
                    [filteredDictionary setObject:reportingPerson forKey:@"reportingPerson"];
                }
                [defaults setObject:filteredDictionary forKey:@"UserData"];
                NSLog(@"USER Data====%@",filteredDictionary);
                [self getStoreDetails];
            }
        }
    }
     //==================================================ERROR
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         NSLog(@"Error %@",[error description]);
                                     }];
    [operation start];
}

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
        self.lblStoreName.text=[dictForStoreDetails valueForKey:@"storeName"];
        CLLocationDegrees latitude = [[dictForStoreDetails valueForKey:@"latitude"] doubleValue];
        CLLocationDegrees longitude =[[dictForStoreDetails valueForKey:@"longitude"] doubleValue];
        radiusForStore = [[dictForStoreDetails valueForKey:@"proximityRadius"] doubleValue];
        
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        [defaults setObject:dictForStoreDetails forKey:@"StoreData"];
        //storeName
        CLLocationCoordinate2D coordinate;
        coordinate.latitude = latitude;
        coordinate.longitude = longitude;
        
        if ([[dict valueForKey:@"onPremise"] isEqualToString:@"Y"]) {
            // Build a circle for the GMSMapView
            GMSCircle *geoFenceCircle = [[GMSCircle alloc] init];
            geoFenceCircle.radius = radiusForStore; // Meters
            geoFenceCircle.position = coordinate; // Some CLLocationCoordinate2D position
            geoFenceCircle.fillColor = [UIColor colorWithWhite:0.7 alpha:0.7];
            geoFenceCircle.strokeWidth = 1.5;
            geoFenceCircle.strokeColor = [UIColor blueColor];
            geoFenceCircle.map = mapView; // Add it to Map
        }
        
        [self startBackgroundTask];
        [self checkLocation];
        
        //if ([[dict valueForKey:@"onPremise"] isEqualToString:@"Y"]) {
        CLCircularRegion *circularRegion=[[CLCircularRegion alloc]initWithCenter:coordinate radius:radiusForStore identifier:@"Region"];
        circularRegion.notifyOnEntry=YES;
        circularRegion.notifyOnExit=YES;
        locationManager.delegate=self;
        [locationManager startMonitoringForRegion:circularRegion];
        //}
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
    
    if (tableView == self.tableVwForAgents) {
        return 10;
    }
    if (tableView == self.tableVwForHistoryOfAgent) {
        return 10;
    }
    if (tableView == self.tableVwIndividualHistory) {
        return 10;
    }
    return arrayForStatusData.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (tableView == self.tableVwForAgents) {
        MKAgentListCell *cell=[tableView dequeueReusableCellWithIdentifier:@"Cell"];
        if (cell==nil) {
            cell=[[MKAgentListCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    
    if (tableView == self.tableVwForHistoryOfAgent) {
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
    
    if (tableView == self.tableVwIndividualHistory) {
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
    
    if (tableView == self.tableVwForAgents) {
        self.vwForAgentData.hidden = NO;
        self.backBtn.hidden = NO;
        self.tableVwForHistoryOfAgent.delegate = self;
        self.tableVwForHistoryOfAgent.dataSource = self;
        [self.tableVwForHistoryOfAgent reloadData];
    }
    
    if (tableView == self.tableVwForHistoryOfAgent) {
        self.vwForAgentIndividualData.hidden = NO;
        self.tableVwIndividualHistory.delegate = self;
        self.tableVwIndividualHistory.dataSource = self;
        [self.tableVwIndividualHistory reloadData];
    }
}

-(NSString*)getTimeIndividual:(NSString*)strDate{
    
    if ([strDate isKindOfClass:[NSNull class]]) {
        return @"--";
    }
    
    NSString *strDateChange=strDate;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss Z";
    NSDate *dateFromString = [dateFormatter dateFromString:strDateChange];
    dateFormatter.dateFormat = @"hh:mm a";
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    strDateChange = [dateFormatter stringFromDate:dateFromString];
    return strDateChange;
}

-(NSString*)getTime:(NSString*)strDate{
    
    NSRange range=[strDate rangeOfString:@"T"];
    strDate=[strDate substringFromIndex:NSMaxRange(range)];
    range=[strDate rangeOfString:@"+"];
    
    NSString * timeZone=[strDate substringFromIndex:NSMaxRange(range)-1];
    strDate=[strDate substringToIndex:NSMaxRange(range)-1];
    strDate=[NSString stringWithFormat:@"%@ %@",strDate,timeZone];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss xxxx"];
    NSDate *dateFromString = [dateFormatter dateFromString:strDate];
    [dateFormatter setDateFormat:@"hh:mm a"];
    return [dateFormatter stringFromDate:dateFromString];
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
        
        CLLocationCoordinate2D coordinate = [self getLocation];
        CLLocation *userLocation= [[CLLocation alloc] initWithLatitude:coordinate.latitude
                                                             longitude:coordinate.longitude];
        CLLocationDistance distance = [location distanceFromLocation:userLocation];
        
        radiusForStore = [[dictForStoreDetails valueForKey:@"proximityRadius"] doubleValue];
        
        if (distance <= radiusForStore && distance >= 0){
            
            if ([self.lblForStoreLocation.text isEqualToString:@"Off site"]) {
                UILocalNotification *notification = [[UILocalNotification alloc] init];
                notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
                notification.alertBody = @"Entering To Store Region !";
                notification.timeZone = [NSTimeZone defaultTimeZone];
                notification.soundName = UILocalNotificationDefaultSoundName;
                [[UIApplication sharedApplication] scheduleLocalNotification:notification];
            }
            
            self.imgVwForLocationIcon.image=[UIImage imageNamed:@"location_On"];
            self.lblForStoreLocation.text=[dictForStoreDetails valueForKey:@"storeName"];
            self.lblForStoreLocation.textColor=[UIColor whiteColor];
            [dictToSendLctnStatus setObject:@"1" forKey:@"LocationStatus"];
            storeName= [dictForStoreDetails valueForKey:@"storeName"];
            boolValueForInLocationOrNot = YES;
            self.lblStoreName.text=storeName;
            
        }else{
            
            if (![self.lblForStoreLocation.text isEqualToString:@"Off site"]) {
                
                UILocalNotification *notification = [[UILocalNotification alloc] init];
                notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
                notification.alertBody = @"Exiting From Store Region !";
                notification.timeZone = [NSTimeZone defaultTimeZone];
                notification.soundName = UILocalNotificationDefaultSoundName;
                [[UIApplication sharedApplication] scheduleLocalNotification:notification];
            }
            
            self.imgVwForLocationIcon.image=[UIImage imageNamed:@"location_Off"];
            self.lblForStoreLocation.text=@"Off site";
            self.lblForStoreLocation.textColor=[UIColor darkGrayColor];
            [dictToSendLctnStatus setObject:@"0" forKey:@"LocationStatus"];
            storeName=@"Off site";
            boolValueForInLocationOrNot = NO;
            self.lblStoreName.text=@"(Not at location)";
        }
        
        NSMutableDictionary *dict=[[defaults objectForKey:@"UserData"] mutableCopy];
        
        if ([[dict valueForKey:@"onPremise"] isEqualToString:@"N"]) {
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
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"Exited Region - %@", region.identifier);
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
        prevCurrLocation=newLocation.coordinate;
    }
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
}
- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error{
}

#pragma mark -

- (void)mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position{
}

-(void)mapViewDidFinishTileRendering:(GMSMapView *)mapView{
    
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
      
        strForCurLatitude = [NSString stringWithFormat:@"%f", coordinate.latitude];
        strForCurLongitude= [NSString stringWithFormat:@"%f", coordinate.longitude];
        
        GMSCameraUpdate *updatedCamera = [GMSCameraUpdate setTarget:coordinate zoom:15];
        [mapView animateWithCameraUpdate:updatedCamera];
        mapView.myLocationEnabled = YES;
        
        CLLocationDegrees latitude = [[dictForStoreDetails valueForKey:@"latitude"] doubleValue];
        CLLocationDegrees longitude =[[dictForStoreDetails valueForKey:@"longitude"] doubleValue];
        coordinate.latitude = latitude;
        coordinate.longitude = longitude;
        
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        NSMutableDictionary *dict=[[defaults objectForKey:@"UserData"] mutableCopy];
        
        if ([[dict valueForKey:@"onPremise"] isEqualToString:@"Y"]) {
            GMSCircle *geoFenceCircle = [[GMSCircle alloc] init];
            geoFenceCircle.radius = radiusForStore; // Meters
            geoFenceCircle.position = coordinate; // Some CLLocationCoordinate2D position
            geoFenceCircle.fillColor = [UIColor colorWithWhite:0.7 alpha:0.7];
            geoFenceCircle.strokeWidth = 1.5;
            geoFenceCircle.strokeColor = [UIColor blueColor];
            geoFenceCircle.map = mapView;
        }
    }else{
        UIAlertView *alertLocation=[[UIAlertView alloc]initWithTitle:@"" message:@"Please Enable Location Access" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertLocation show];
    }
}

- (IBAction)onClickTimeIn:(UIButton *)sender {
    
    if ([APPDELEGATE connected]) {
        if (boolValueForInLocationOrNot){
            
            if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]){
                if (![self checkForOneTimeLogin]) {
                    [self openCamera];
                }
            }else{
                UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"No Camera" message:@"Camera Is Not Available" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
            
        }else{
            UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Not at store location" message:@"Please go to the store location and try again!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }else{
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"It appears you are not connected to internet!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (IBAction)onClickPhotoConfirmBtn:(UIButton *)sender {
    
    self.vwForImgPreview.hidden = YES;
    self.backBtn.hidden = YES;
    
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
    alert.tag=100;
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView.tag == 200) {
        if (buttonIndex == 1) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/geotag-photos-pro-2/id1008694552?mt=8"]];
        }
    }else{
        if (buttonIndex == 1) {
            [self saveDataIntoLocal:NO];
            [self getTimeLineData];
            [self checkForOneTimeLogin];
        }
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
    
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]){
        [self openCamera];
    }
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
    [videoPreviewLayer setFrame:self.previewCamera.layer.bounds];
    [self.previewCamera.layer addSublayer:videoPreviewLayer];
    [captureSession startRunning];
    
    self.tabBarController.tabBar.hidden =YES;
    self.vwForCamera.hidden = NO;
    self.backBtn.hidden = NO;
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
    
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error){
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
        UIImage *image = [[UIImage alloc] initWithData:imageData];
        imgToSend=image;
        self.vwForImgPreview.hidden = NO;
        self.imgVwForPhotoPreview.image=imgToSend;
        self.vwForCamera.hidden = YES;
    }];
    
    self.tabBarController.tabBar.hidden =NO;
}

- (IBAction)onClickBackBtn:(UIButton *)sender {
    
    self.backBtn.hidden = YES;
    
    if (![self.vwForCamera isHidden]) {
        if (![self.vwForImgPreview isHidden]) {
            self.backBtn.hidden = NO;
        }
        self.vwForCamera.hidden = YES;
    }else if (![self.vwForImgPreview isHidden]){
        self.vwForImgPreview.hidden = YES;
        imgToSend=nil;
    }
    
    if (![self.vwForAgentData isHidden]) {
        if (![self.vwForAgentIndividualData isHidden]) {
            self.vwForAgentIndividualData.hidden=YES;
            self.backBtn.hidden = NO;
        }else{
            self.vwForAgentData.hidden=YES;
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
        self.vwForImgPreview.hidden = NO;
        self.imgVwForPhotoPreview.image=imgToSend;
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
                        
                        if ([jsonData objectForKey:@"savedFilename"] || ([HTTPResponse statusCode] == 200)){
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
    NSDate *timeNow = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ssZ";
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
   
    NSString *strCurrentTime=[dateFormatter stringFromDate:timeNow];
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
               // actionType=@"clockIn";
                 actionType=@"InLocation";
            }else{
                comments=@"OutLocation";
               // actionType=@"clockOut";
                 actionType=@"OutLocation";
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
    if (imgToSend == nil) {
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
    
    NSMutableDictionary *dictForStatus=[[NSMutableDictionary alloc] init];

    for (NSManagedObject * fetRec  in result) {
        statusData=[fetRec valueForKey:@"status"];
        [dictForStatus setValue:statusData forKey:@"status"];
        statusData=[fetRec valueForKey:@"comments"];
        [dictForStatus setValue:statusData forKey:@"comments"];
        statusData=[fetRec valueForKey:@"time"];
        [dictForStatus setValue:statusData forKey:@"time"];
    }
    if ([dictForStatus valueForKey:@"status"]) {
        if ([[dictForStatus valueForKey:@"status"] isEqualToString:@"TimeOut"]) {
            timerForShiftTime=nil;
            [timerForShiftTime invalidate];
        }
    }
    return dictForStatus;
}

-(NSMutableArray*)getTimeLineData{
    
    NSError *error=nil;
    
    NSMutableArray *arrayOfTimelineData=[[NSMutableArray alloc] init];
    
    self.timeLineDataEntity=[NSEntityDescription entityForName:@"TimeLineData" inManagedObjectContext:APPDELEGATE.managedObjectContext];
    NSFetchRequest * fr = [[NSFetchRequest alloc]init];
    [fr setEntity:self.timeLineDataEntity];
    
    NSArray * result = [APPDELEGATE.managedObjectContext executeFetchRequest:fr error:&error];
    
    for (NSManagedObject * fetRec  in result) {
        NSMutableDictionary *dictTimelineData=[[NSMutableDictionary alloc] init];
        //actiontype clockdate comments latitude longitude productstoreid actionimage username issend
        [dictTimelineData setValue:[fetRec valueForKey:@"username"] forKey:@"username"];
        [dictTimelineData setValue:[fetRec valueForKey:@"actiontype"] forKey:@"actiontype"];
        [dictTimelineData setValue:[fetRec valueForKey:@"clockdate"] forKey:@"clockdate"];
        [dictTimelineData setValue:[fetRec valueForKey:@"comments"] forKey:@"comments"];
        [dictTimelineData setValue:[fetRec valueForKey:@"latitude"] forKey:@"latitude"];
        [dictTimelineData setValue:[fetRec valueForKey:@"longitude"] forKey:@"longitude"];
        [dictTimelineData setValue:[fetRec valueForKey:@"productstoreid"] forKey:@"productstoreid"];
        [dictTimelineData setValue:[fetRec valueForKey:@"actionimage"] forKey:@"actionimage"];
        [dictTimelineData setValue:[fetRec valueForKey:@"issend"] forKey:@"issend"];
        [arrayOfTimelineData addObject:dictTimelineData];
    }
    //        for (NSDictionary*dict in arrayOfData) {
    //            NSLog(@"User Name===%@",[dict valueForKey:@"username"]);
    //            NSLog(@"User Name===%@",[dict valueForKey:@"actiontype"]);
    //            NSLog(@"clockdate===%@",[dict valueForKey:@"clockdate"]);
    //            NSLog(@"comments===%@",[dict valueForKey:@"comments"]);
    //            NSLog(@"latitude===%@",[dict valueForKey:@"latitude"]);
    //            NSLog(@"longitude===%@",[dict valueForKey:@"longitude"]);
    //            NSLog(@"productstoreid===%@",[dict valueForKey:@"productstoreid"]);
    //            NSLog(@"issend===%@",[dict valueForKey:@"issend"]);
    //        }
    return arrayOfTimelineData;
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
        if (![self checkForOneTimeLogin]) {
            self.lblTimeInStatus.text=@"Time In";
            self.bottomVw.image=[UIImage imageNamed:@"topbar"];
            self.bottomVw.backgroundColor=[UIColor clearColor];
        }else{
            self.lblTimeInStatus.text=@"Time In/Out done for today";
            self.bottomVw.image=[UIImage imageNamed:@""];
            self.bottomVw.backgroundColor=[UIColor lightGrayColor];
        }
        self.vwForTimer.hidden=YES;
        timerForShiftTime=nil;
        [timerForShiftTime invalidate];
        
    }else if([[statusData valueForKey:@"status"] isEqualToString:@"TimeIn"]){
        self.bottomVw.image=[UIImage imageNamed:@"topbar"];
        self.lblTimeInStatus.text=@"Time Out";
        self.vwForTimer.hidden=NO;
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        NSString *strTime=[defaults objectForKey:@"TimeIn"];
        [self getTimerForTimeIn:strTime];
        // [self getTimerForTimeIn:[statusData valueForKey:@"time"]];
    }else if([[statusData valueForKey:@"status"] isEqualToString:@"TimeOut"]){
        if (![self checkForOneTimeLogin]) {
             self.lblTimeInStatus.text=@"Time In";
            self.bottomVw.image=[UIImage imageNamed:@"topbar"];
            self.bottomVw.backgroundColor=[UIColor clearColor];
        }else{
             self.lblTimeInStatus.text=@"Time In/Out done for today";
            self.bottomVw.image=[UIImage imageNamed:@""];
            self.bottomVw.backgroundColor=[UIColor lightGrayColor];
            
        }
        self.vwForTimer.hidden=YES;
        timerForShiftTime=nil;
        [timerForShiftTime invalidate];
    }
}

-(void)getTimerForTimeIn:(NSString*)time{
    
    NSString *firstViewd;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    NSDate *timeNow = [NSDate date];
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ssZ";
    //    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    firstViewd=[dateFormatter stringFromDate:timeNow];
    
    NSString *lastViewedString;
    time = [time stringByReplacingOccurrencesOfString:@"T" withString:@" "];
    
    lastViewedString=time;
    NSInteger   hoursBetweenDates = 0;
    [dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ssZ"];
    NSDate *lastViewed = [dateFormatter dateFromString:lastViewedString];
    timeNow = [dateFormatter dateFromString:firstViewd];
    NSTimeInterval distanceBetweenDates = [timeNow timeIntervalSinceDate:lastViewed];
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
    
    self.lblForTimer.text=timeString;
    self.lblForTimer.textAlignment= NSTextAlignmentCenter;
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
    if ([self.tableVwForTimeline isHidden]) {
        [self getHistory];
        self.tableVwForTimeline.hidden = NO;
        self.imgVwForTimeline.image=[UIImage imageNamed:@"Timer_Off"];
    }else{
        self.tableVwForTimeline.hidden = YES;
        self.imgVwForTimeline.image=[UIImage imageNamed:@"Timer_On"];
    }
}
#pragma mark - Get History

-(void)getHistory
{
    if ([APPDELEGATE connected]) {
        
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
        NSString *strAuthorization=[defaults valueForKey:@"BasicAuth"];
        
        AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
        httpClient.parameterEncoding = AFFormURLParameterEncoding;
        [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [httpClient setDefaultHeader:@"Authorization" value:strAuthorization];
        
        NSMutableDictionary *dict=[[defaults objectForKey:@"UserData"] mutableCopy];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd";
        
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
            
            for (NSDate *date in tempArray) {
                [correctOrderStringArray addObject:date.description];
            }
            
            arrayForStatusData = [correctOrderStringArray mutableCopy];
            self.tableVwForTimeline.delegate= self;
            self.tableVwForTimeline.dataSource = self;
            [self.tableVwForTimeline reloadData];
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

@end