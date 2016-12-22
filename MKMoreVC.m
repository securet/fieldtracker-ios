//
//  MKMoreVC.m
//  OppoAttendanceTracker
//
//  Created by User1 on 12/20/16.
//
//

#import "MKMoreVC.h"
#import "MKCustomCellForLeave.h"
@interface MKMoreVC ()
{
    NSMutableArray *arrayForTableData;
    NSMutableArray *arrayForStoreList;
    NSMutableArray *arrayForPromoters;
    NSString *strForCurLatitude,*strForCurLongitude;
}
@end

@implementation MKMoreVC
#pragma mark - View
- (void)viewDidLoad {
    [super viewDidLoad];
    
    

    arrayForTableData=[[NSMutableArray alloc] initWithObjects:@"Stores",@"Promoters",@"Leaves",@"Contact Support",@"Log Off", nil];
    
    
    arrayForStoreList=[[NSMutableArray alloc] initWithObjects:@"OPPOBHPL",@"OPPOAPNG",@"OPPOTTFL",@"OPPOTRRD",@"OPPOBBGF", nil];
    
    arrayForPromoters=[[NSMutableArray alloc] initWithObjects:@"Anand",@"Vikram",@"Pawan",@"Vijay",@"Pramod", nil];
    
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
    
}

-(void)viewWillAppear:(BOOL)animated
{
    
    [self updateLocationManagerr];
    self.navigationController.navigationBarHidden = YES;
    self.navigationItem.hidesBackButton = YES;
    [self.navigationItem setHidesBackButton:YES];
}

#pragma mark - Add StoreView


-(void)textViewDidBeginEditing:(UITextView *)textView
{
    if (textView== _txtVwStoreAddress && [textView.text isEqualToString:@"Store Address"])
    {
        textView.text=@"";
    }
}


-(void)textViewDidEndEditing:(UITextView *)textView
{
    if (textView== _txtVwStoreAddress && _txtVwStoreAddress.text.length<=0)
    {
        textView.text=@"Store Address";
    }
}

-(void)setUpForAddStore
{
    
    _txtVwStoreAddress.delegate = self;
    
    _txtVwStoreAddress.text=@"Store Address";
    _backBtn.hidden=YES;
    _lblForLatLon.text=@"";
    _lblForLatLon.textAlignment = NSTextAlignmentCenter;
    
    if ([[MKSharedClass shareManager] valueForStoreEditVC] == 1)
    {
        _lblForEditStore.text=@"Add Store";
        [_btnAdd setTitle:@"Add" forState:UIControlStateNormal];
        
        _btnAdd.enabled = NO;
        _btnAdd.alpha = 0.6;
        _btnAdd.backgroundColor=[[UIColor lightGrayColor] colorWithAlphaComponent:0.6];
    }
    else if ([[MKSharedClass shareManager] valueForStoreEditVC] == 0)
    {
        _lblForEditStore.text=@"Edit Store";
        [_btnAdd setTitle:@"Edit" forState:UIControlStateNormal];
        _btnAdd.backgroundColor=[[UIColor blueColor] colorWithAlphaComponent:0.6];
    }
    
    
    
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
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"CloseView" object:self];
    
    _vwForStoreAdd.hidden = YES;
    _backBtn.hidden=NO;
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
#pragma mark - Add Store

-(void)onClickAddStore:(UIButton*)btn
{
    [[MKSharedClass shareManager] setValueForStoreEditVC:1];
    [self goToStorePopup];
   
//    NSLog(@"On Click Add Store");
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


-(void)onClickAddPromoter:(UIButton*)btn
{
//    NSLog(@"On Click Add Promoter");
    
    _segmentControl.delegate = self;
    [_btnCancelPromoterAdd addTarget:self action:@selector(onClickCancelOfAddPromoter) forControlEvents:UIControlEventTouchUpInside];
    _vwForPromoterAdd.hidden = NO;
    _backBtn.hidden = YES;
}


-(void)onClickCancelOfAddPromoter
{
    _vwForPromoterAdd.hidden = YES;
    _backBtn.hidden = NO;
}

#pragma mark - Leave Rqst

-(void)onClickLeaveRqst:(UIButton*)btn
{
//        NSLog(@"On Click Leave Request");
}



#pragma mark- UITableView

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    if (tableView==_tableVwForStore) {
        return arrayForStoreList.count;
    }
    else if (tableView == _tableVwForPromoters)
    {
        return arrayForPromoters.count;
    }
    else if (tableView == _tableVwForLeaveRqst)
    {
        return 4;
    }
    return arrayForTableData.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"Cell"];

    
    if (tableView == _tableVwForLeaveRqst) {
        
        MKCustomCellForLeave *cellLeave=[tableView dequeueReusableCellWithIdentifier:@"Cell"];
        
        
        if (cellLeave == nil) {
            cellLeave=[[MKCustomCellForLeave alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        }
        
        cellLeave.selectionStyle = UITableViewCellSelectionStyleNone;
        return cellLeave;
    }
    
    
    if (cell == nil)
    {
        cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (tableView == _tableVwForStore)
    {
        cell.textLabel.text=[arrayForStoreList objectAtIndex:indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
    }
    else if (tableView == _tableVwForPromoters)
    {
        cell.textLabel.text=[arrayForPromoters objectAtIndex:indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if (tableView == _tableVw)
    {
           cell.textLabel.text=[arrayForTableData objectAtIndex:indexPath.row];
        
    }
 
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (tableView == _tableVw)
    {
        
    if (indexPath.row == 4)
    {
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UITabBarController *rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"MainRoot"];
        [[UIApplication sharedApplication].keyWindow setRootViewController:rootViewController];
    }
    else if (indexPath.row ==0)
    {
        _vwForStore.hidden =NO;
        _backBtn.hidden = NO;
        _tableVwForStore.delegate = self;
        _tableVwForStore.dataSource = self;
        [_tableVwForStore reloadData];
        
    }
    else if (indexPath.row ==1)
    {
        _vwForPromoters.hidden =NO;
        _backBtn.hidden = NO;
        _tableVwForPromoters.delegate = self;
        _tableVwForPromoters.dataSource = self;
        [_tableVwForPromoters reloadData];
    }
    else if (indexPath.row ==2)
    {
        _vwForLeaveRqst.hidden =NO;
        _backBtn.hidden = NO;
        _tableVwForLeaveRqst.delegate = self;
        _tableVwForLeaveRqst.dataSource = self;
        [_tableVwForLeaveRqst reloadData];
    }

        
    }
    else if (tableView == _tableVwForStore)
    {
        [[MKSharedClass shareManager] setValueForStoreEditVC:0];
        [self goToStorePopup];
    }
}


-(void)goToStorePopup
{
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

    [self setUpForAddStore];
    _vwForStoreAdd.hidden = NO;
    
    
    
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

- (IBAction)onClickBackBtn:(UIButton *)sender
{
    if (![_vwForStore isHidden])
    {
        _vwForStore.hidden= YES;
    }
    else if (![_vwForPromoters isHidden])
    {
        _vwForPromoters.hidden= YES;
    }
    else if (![_vwForLeaveRqst isHidden])
    {
        _vwForLeaveRqst.hidden =YES;
    }
    _backBtn.hidden = YES;
}
@end
