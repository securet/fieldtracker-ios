//
//  MKAddStoreVC.m
//  OppoAttendanceTracker
//
//  Created by User1 on 12/22/16.
//
//

#import "MKAddStoreVC.h"

@interface MKAddStoreVC ()
{
    NSString *strForCurLatitude,*strForCurLongitude;
}
@end

@implementation MKAddStoreVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    [self updateLocationManagerr];
    
    

    
    _lblForLatLon.text=@"";
    _lblForLatLon.textAlignment = NSTextAlignmentCenter;
    
    if ([[MKSharedClass shareManager] valueForStoreEditVC] == 1)
    {
        _lblForEditStore.text=@"Add Store";
        [_btnAdd setTitle:@"Add" forState:UIControlStateNormal];
        
        _btnAdd.enabled = NO;
        _btnAdd.alpha = 0.6;
    }
    else if ([[MKSharedClass shareManager] valueForStoreEditVC] == 0)
    {
        _lblForEditStore.text=@"Edit Store";
        [_btnAdd setTitle:@"Edit" forState:UIControlStateNormal];
        _btnAdd.backgroundColor=[[UIColor blueColor] colorWithAlphaComponent:0.6];
    }
    
    

    
    self.view.layer.cornerRadius = 10;
    self.view.layer.masksToBounds = YES;
    self.view.clipsToBounds = YES;
    
    
    _txtFieldStoreName.layer.cornerRadius = 5;
    _txtFieldStoreName.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.7];
    _txtFieldStoreName.keyboardType=UIKeyboardTypeASCIICapable;
    
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 20)];
    _txtFieldStoreName.leftView = paddingView;
    _txtFieldStoreName.leftViewMode = UITextFieldViewModeAlways;
    
    
    
    _txtVwStoreAddress.layer.cornerRadius = 5;
    _txtVwStoreAddress.layer.masksToBounds = YES;
    
    _txtVwStoreAddress.backgroundColor =[[UIColor lightGrayColor] colorWithAlphaComponent:0.7];
    
    
    _btnGetLocation.layer.cornerRadius = 5;
    _btnGetLocation.layer.masksToBounds = YES;

    
    
    _btnAdd.layer.shadowColor = [UIColor lightGrayColor].CGColor;
    _btnAdd.layer.shadowOffset = CGSizeMake(1, 1);
    _btnAdd.layer.shadowOpacity = 1;
    _btnAdd.layer.shadowRadius = 1.0;
    
    
    
    
    _btnCancel.layer.shadowColor = [UIColor lightGrayColor].CGColor;
    _btnCancel.layer.shadowOffset = CGSizeMake(1, 1);
    _btnCancel.layer.shadowOpacity = 1;
    _btnCancel.layer.shadowRadius = 1.0;
    
    
    [_btnCancel addTarget:self action:@selector(onClickCancel) forControlEvents:UIControlEventTouchUpInside];
    
    [_btnGetLocation addTarget:self action:@selector(getLocation) forControlEvents:UIControlEventTouchUpInside];
} 


-(void)onClickCancel
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CloseView" object:self];
}


-(void)getLocation
{
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
    if (str.length>0)
    {
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding] options: NSJSONReadingMutableContainers
                                                               error: nil];
        
        NSDictionary *getRoutes = [JSON valueForKey:@"routes"];
        NSDictionary *getLegs = [getRoutes valueForKey:@"legs"];
        NSArray *getAddress = [getLegs valueForKey:@"end_address"];
        //        NSLog(@"Map Location=====%@",JSON);
        if (getAddress.count!=0)
        {
//            self.textVwForAddress.text=[[getAddress objectAtIndex:0]objectAtIndex:0];
//            
//            CGRect frame = self.textVwForAddress.frame;
//            frame.size.height = self.textVwForAddress.contentSize.height;
//            self.textVwForAddress.frame=frame;
            
            NSLog(@"Address==%@",[[getAddress objectAtIndex:0]objectAtIndex:0]);
            
            _lblForLatLon.text=[NSString stringWithFormat:@"Lat: %f | Lon: %f",[strForCurLatitude floatValue],[strForCurLongitude floatValue]];
            
            _txtVwStoreAddress.text=[[getAddress objectAtIndex:0]objectAtIndex:0];
        }
    }
}

-(void)updateLocationManagerr
{
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
           fromLocation:(CLLocation *)oldLocation
{
    strForCurLatitude=[NSString stringWithFormat:@"%f",newLocation.coordinate.latitude];
    strForCurLongitude=[NSString stringWithFormat:@"%f",newLocation.coordinate.longitude];
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

@end
