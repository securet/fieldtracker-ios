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
}
@end

@implementation MKHomeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _lblUserName.text=[NSString stringWithFormat:@"Test"];
    _lblUserName.numberOfLines = 2;
    
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
}


-(void)viewWillAppear:(BOOL)animated{
    self.navigationController.navigationBarHidden = YES;
    self.navigationItem.hidesBackButton = YES;
    [self.navigationItem setHidesBackButton:YES];
}


#pragma mark - LocationManagaer

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

- (IBAction)onClickMyLocation:(UIButton *)sender {
    
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
@end
