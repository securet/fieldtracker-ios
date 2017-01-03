//
//  MKHistoryVC.m
//  OppoAttendanceTracker
//
//  Created by User1 on 12/20/16.
//
//

#import "MKHistoryVC.h"
#import "MKHistoryCustomCell.h"
#import "MKIndividualHistoryCell.h"

@interface MKHistoryVC ()
{
    NSMutableArray *arrayForTableData;
    NSMutableArray *arrayForStatusData;
    NSInteger arrayCountToCheck;
    NSInteger pageNumber;
}
@end

@implementation MKHistoryVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSMutableDictionary *dict=[[defaults objectForKey:@"UserData"] mutableCopy];
    NSLog(@"%@",dict);
    _lblFName.text=[dict valueForKey:@"firstName"];
    _lblLName.text=[dict valueForKey:@"lastName"];
    
    _tableVw.delegate = self;
    _tableVw.dataSource = self;
    _tableVw.tableFooterView = [[UIView alloc] init];
    _tableVw.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    arrayForTableData=[[NSMutableArray alloc] init];
    
    _tableVwForIndividual.delegate = self;
    _tableVwForIndividual.dataSource = self;
    _tableVwForIndividual.tableFooterView = [[UIView alloc] init];
    _tableVwForIndividual.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    _vwForIndividualItem.hidden = YES;
    _backBtn.hidden = YES;
    
    pageNumber=0;
    [_tableVw addFooterWithTarget:self action:@selector(refreshFooter) withIndicatorColor:TopColor];
    
    //    [self getHistory];
    
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
    
    if (arrayForTableData.count<=0) {
        arrayForTableData=[[NSMutableArray alloc] init];
        pageNumber=0;
        [self getHistory];
    }
    
    [_tableVw reloadData];
    
    
    if (![APPDELEGATE connected]) {
        
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"Please check your connection" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)refreshFooter
{
    if(arrayCountToCheck >= 10)
    {
        pageNumber++;
        
        [self getHistory];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableVw reloadData];
            [self.tableVw footerEndRefreshing];
            //        [self.tableVw removeFooter];
        });
    }
    else
    {
        [self.tableVw footerEndRefreshing];
        [self.tableVw headerEndRefreshing];
    }
}

#pragma mark- UITableView
//-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (tableView == _tableVwForIndividual) {
//        CGFloat ht;
//
//        if (indexPath.row==0) {
//            ht=50;
//        }else{
//            if (indexPath.row % 2 == 0) {
//                ht=35;
//            }else{
//                 ht=35;
//            }
//        }
//
//
//        if (indexPath.row==arrayForStatusData.count-1){
//            ht=50;
//        }
//        return ht;
//    }
//    return 81;
//}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == _tableVwForIndividual) {
        return arrayForStatusData.count;
    }
    return arrayForTableData.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    MKHistoryCustomCell *cell=[tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    //Individual View
    if (tableView == _tableVwForIndividual) {
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
    ////
    if (cell == nil) {
        
        cell=[[MKHistoryCustomCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    
    ///Date Parsing
    NSString *strDate=[[arrayForTableData objectAtIndex:indexPath.row]valueForKey:@"estimatedCompletionDate"];
    NSRange range = [strDate rangeOfString:@"T"];
    strDate=[strDate substringToIndex:NSMaxRange(range)-1];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *date = [dateFormatter dateFromString:strDate];
    [dateFormatter setDateFormat:@"dd-MMM-yyyy"];
    NSString *newDateString = [dateFormatter stringFromDate:date];
    cell.lblDate.text=newDateString;
    //////
    
    
    newDateString = [self getTime:[[arrayForTableData objectAtIndex:indexPath.row]valueForKey:@"estimatedStartDate"]];
    
    
    cell.lblInTime.text=[NSString stringWithFormat:@"Time In: %@",newDateString];
    
    newDateString = [self getTime:[[arrayForTableData objectAtIndex:indexPath.row]valueForKey:@"estimatedCompletionDate"]];
    cell.lblOutTime.text=[NSString stringWithFormat:@"Time Out: %@",newDateString];
    ////
    
    
    NSArray *array=[[NSArray alloc] init];
    NSInteger   hoursBetweenDates = 0;
    
    array=[[arrayForTableData objectAtIndex:indexPath.row] objectForKey:@"timeEntryList"];
    
    
    //    [self getTime:[arrayForStatusData objectAtIndex:0]];
    
    
    if (![[self getTime:[[array objectAtIndex:0] valueForKey:@"fromDate"]] isKindOfClass:[NSNull class]]) {
        
        cell.lblInTime.text=[NSString stringWithFormat:@"Time In: %@",[self getTime:[[array objectAtIndex:0] valueForKey:@"fromDate"]]];
    }else{
        cell.lblInTime.text=[NSString stringWithFormat:@"--"];
    }
    
    
    
    if (![[self getTime:[[array lastObject] valueForKey:@"thruDate"]] isKindOfClass:[NSNull class]]) {
        
        cell.lblOutTime.text=[NSString stringWithFormat:@"Time In: %@",[self getTime:[[array lastObject] valueForKey:@"thruDate"]]];
    }else{
        cell.lblOutTime.text=[NSString stringWithFormat:@"--"];
    }
    
    
    
    if (![[self getTime:[[array objectAtIndex:0] valueForKey:@"fromDate"]] isKindOfClass:[NSNull class]] && ![[self getTime:[[array lastObject] valueForKey:@"thruDate"]] isKindOfClass:[NSNull class]]){
        

    NSString *firstViewd;

        firstViewd=[NSString stringWithFormat:@"%@",[[array objectAtIndex:0] valueForKey:@"fromDate"]];
    
        
        firstViewd = [firstViewd stringByReplacingOccurrencesOfString:@"T" withString:@" "];
        firstViewd = [firstViewd stringByReplacingOccurrencesOfString:@"+0000" withString:@""];
        
        

    NSString *lastViewedString;
    
        lastViewedString=[NSString stringWithFormat:@"%@",[[array lastObject] valueForKey:@"thruDate"]];

        
        
        lastViewedString = [lastViewedString stringByReplacingOccurrencesOfString:@"T" withString:@" "];
        lastViewedString = [lastViewedString stringByReplacingOccurrencesOfString:@"+0000" withString:@""];
        
        
        
        [dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
    //            [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    NSDate *lastViewed = [dateFormatter dateFromString:lastViewedString];
    NSDate *now = [dateFormatter dateFromString:firstViewd];
    
    NSTimeInterval distanceBetweenDates = [lastViewed timeIntervalSinceDate:now];
    double minutesInAnHour = 60;
    hoursBetweenDates = hoursBetweenDates + (distanceBetweenDates / minutesInAnHour);
    
    
    int hour = hoursBetweenDates / 60;
    int min = hoursBetweenDates % 60;
    NSString *timeString = [NSString stringWithFormat:@"%dh %02dm", hour, min];
//    NSLog(@"Total Time: %@", timeString);
    
    if (hour<0) {
        cell.lblTotalTime.text=[NSString stringWithFormat:@"0h 0m"];
    }else{
        cell.lblTotalTime.text=timeString;
    }
    }else{
        cell.lblTotalTime.text=[NSString stringWithFormat:@"--"];
    }
    
    //    NSLog(@"=================%@",array);
    
    /*        for (NSDictionary *dict in array) {
    
    
    NSDictionary *dict = [array objectAtIndex:0];
    
    
    NSString *lastViewedString = [dict valueForKey:@"fromDate"];
    
    lastViewedString = [lastViewedString stringByReplacingOccurrencesOfString:@"T" withString:@" "];
    lastViewedString = [lastViewedString stringByReplacingOccurrencesOfString:@"+0000" withString:@""];
    // NSLog(@"Complete Date===%@",lastViewedString);
    
    
    
    
    NSDateFormatter *parsingFormatter = [NSDateFormatter new];
    [parsingFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    date = [parsingFormatter dateFromString:lastViewedString];
    //            NSLog(@"date: %@", date);
    
    NSDateFormatter *displayingFormatter = [NSDateFormatter new];
    [displayingFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    NSString *display = [displayingFormatter stringFromDate:date];
    //            NSLog(@"display: %@", display); // 2014-04-18T17:34:19
    
    
    NSLog(@"First Time In===%@",display);
    
    
    //////////////From Date
    // [NSString stringWithFormat:@"%@ %@",newDateString,strDate];
    
    NSString *firstViewd =display;
    
    
    
    dict=[array lastObject];
    
    lastViewedString = [dict valueForKey:@"thruDate"];
    
    lastViewedString = [lastViewedString stringByReplacingOccurrencesOfString:@"T" withString:@" "];
    lastViewedString = [lastViewedString stringByReplacingOccurrencesOfString:@"+0000" withString:@""];
    
    //            lastViewedString=[NSString stringWithFormat:@"%@ %@",newDateString,strDate];
    
    
    
    parsingFormatter = [NSDateFormatter new];
    [parsingFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    date = [parsingFormatter dateFromString:lastViewedString];
    //            NSLog(@"date: %@", date);
    
    displayingFormatter = [NSDateFormatter new];
    [displayingFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    display = [displayingFormatter stringFromDate:date];
    //            NSLog(@"display: %@", display); // 2014-04-18T17:34:19
    
    NSLog(@"First Time Out===%@",display);
    
    lastViewedString = display;
    
    
    [dateFormatter setDateFormat: @"yyyy-MM-dd hh:mm:ss"];
    //            [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    NSDate *lastViewed = [dateFormatter dateFromString:lastViewedString];
    NSDate *now = [dateFormatter dateFromString:firstViewd];
    
    NSTimeInterval distanceBetweenDates = [lastViewed timeIntervalSinceDate:now];
    double minutesInAnHour = 60;
    hoursBetweenDates = hoursBetweenDates + (distanceBetweenDates / minutesInAnHour);
    
    NSLog(@"Time: %i", hoursBetweenDates);
    
    //    }
    
    //    NSLog(@"Minutes BetweenDates: %d", hoursBetweenDates);
    
    */
    
   
    
    return cell;
}

-(NSString*)getTime:(NSString*)strDate
{
    //    strDate=[[arrayForTableData objectAtIndex:indexPath.row]valueForKey:@"estimatedCompletionDate"];
    
    
//    strDate = [strDate stringByReplacingOccurrencesOfString:@"T" withString:@" "];
//    strDate = [strDate stringByReplacingOccurrencesOfString:@"+0000" withString:@""];
//     NSLog(@"Complete Date===%@",strDate);
//
//    
    
    NSRange range=[strDate rangeOfString:@"T"];
    strDate=[strDate substringFromIndex:NSMaxRange(range)];
    range=[strDate rangeOfString:@"+"];
    
    NSString * timeZone=[strDate substringFromIndex:NSMaxRange(range)-1];
    strDate=[strDate substringToIndex:NSMaxRange(range)-1];
    strDate=[NSString stringWithFormat:@"%@ %@",strDate,timeZone];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss xxxx"];
    NSDate *date = [dateFormatter dateFromString:strDate];
    
    [dateFormatter setDateFormat:@"HH:mm"];
    //    newDateString = [dateFormatter stringFromDate:date];
    
    return [dateFormatter stringFromDate:date];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (tableView == _tableVw) {
        _vwForIndividualItem.hidden = NO;
        _backBtn.hidden = NO;
        
        arrayForStatusData=[[NSMutableArray alloc] init];
        
        //        arrayForStatusData=[[arrayForTableData objectAtIndex:indexPath.row] objectForKey:@"timeEntryList"];
        
        for (NSDictionary *dict in [[arrayForTableData objectAtIndex:indexPath.row] objectForKey:@"timeEntryList"]) {
            [arrayForStatusData addObject:[dict valueForKey:@"fromDate"]];
            [arrayForStatusData addObject:[dict valueForKey:@"thruDate"]];
        }
        
        NSLog(@"Status Array====%@",arrayForStatusData);
        [_tableVwForIndividual reloadData];
        
        [_tableVwForIndividual setContentOffset:CGPointZero animated:NO];
        
        ///Date Parsing
        NSString *strDate=[[arrayForTableData objectAtIndex:indexPath.row]valueForKey:@"estimatedCompletionDate"];
        NSRange range = [strDate rangeOfString:@"T"];
        strDate=[strDate substringToIndex:NSMaxRange(range)-1];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        NSDate *date = [dateFormatter dateFromString:strDate];
        [dateFormatter setDateFormat:@"dd-MMM-yyyy"];
        NSString *newDateString = [dateFormatter stringFromDate:date];
        _lblEntryDate.text=newDateString;
        //////
        
        //        newDateString = [self getTime:[[arrayForTableData objectAtIndex:indexPath.row]valueForKey:@"estimatedStartDate"]];
        newDateString = [self getTime:[arrayForStatusData objectAtIndex:0]];
        
        _lblTimeIn.text=[NSString stringWithFormat:@"Time In: %@",newDateString];
        
        //        newDateString = [self getTime:[[arrayForTableData objectAtIndex:indexPath.row]valueForKey:@"estimatedCompletionDate"]];
        //
        if (![[arrayForStatusData lastObject] isKindOfClass:[NSNull class]]) {
            newDateString = [self getTime:[arrayForStatusData lastObject]];
        }else{
            newDateString = @"--";
        }
        
        _lblTimeOut.text=[NSString stringWithFormat:@"Time Out: %@",newDateString];
        ////
        
     /*   ////////Calculating Hours and Minutes
        NSInteger hoursBetweenDates=0;
        NSString *lastViewedString = [[arrayForTableData objectAtIndex:indexPath.row]valueForKey:@"estimatedCompletionDate"];
        lastViewedString = [lastViewedString stringByReplacingOccurrencesOfString:@"T" withString:@" "];
        lastViewedString = [lastViewedString stringByReplacingOccurrencesOfString:@"+" withString:@" +"];
        // NSLog(@"Complete Date===%@",lastViewedString);
        
        NSString *startViewedString = [[arrayForTableData objectAtIndex:indexPath.row]valueForKey:@"estimatedStartDate"];
        startViewedString = [startViewedString stringByReplacingOccurrencesOfString:@"T" withString:@" "];
        startViewedString = [startViewedString stringByReplacingOccurrencesOfString:@"+" withString:@" +"];
        //    NSLog(@"Start Date===%@",startViewedString);
        
        [dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss zzz"];
        
        NSDate *lastViewed = [dateFormatter dateFromString:lastViewedString];
        NSDate *now = [dateFormatter dateFromString:startViewedString];
        NSTimeInterval distanceBetweenDates = [lastViewed timeIntervalSinceDate:now];
        double minutesInAnHour = 60;
        hoursBetweenDates = distanceBetweenDates / minutesInAnHour;
        int hour = hoursBetweenDates / 60;
        int min = hoursBetweenDates % 60;
        NSString *timeString = [NSString stringWithFormat:@"%dh %02dm", hour, min];
        //    NSLog(@"Time: %@", timeString);
        
        _lblTotalTime.text=timeString;
        
        if (![[arrayForStatusData lastObject] isKindOfClass:[NSNull class]]) {
            
        }else{
            _lblTotalTime.text = @"--";
        }
      */
        NSArray *array=[[NSArray alloc] init];
        NSInteger   hoursBetweenDates = 0;
        
        array=[[arrayForTableData objectAtIndex:indexPath.row] objectForKey:@"timeEntryList"];
        
        NSString *firstViewd;
        
        firstViewd=[NSString stringWithFormat:@"%@",[[array objectAtIndex:0] valueForKey:@"fromDate"]];
        firstViewd = [firstViewd stringByReplacingOccurrencesOfString:@"T" withString:@" "];
        firstViewd = [firstViewd stringByReplacingOccurrencesOfString:@"+0000" withString:@""];
        
        NSString *lastViewedString;
        
        lastViewedString=[NSString stringWithFormat:@"%@",[[array lastObject] valueForKey:@"thruDate"]];
        lastViewedString = [lastViewedString stringByReplacingOccurrencesOfString:@"T" withString:@" "];
        lastViewedString = [lastViewedString stringByReplacingOccurrencesOfString:@"+0000" withString:@""];
        
        [dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];

    
        NSDate *lastViewed = [dateFormatter dateFromString:lastViewedString];
        NSDate *now = [dateFormatter dateFromString:firstViewd];
        
        NSTimeInterval distanceBetweenDates = [lastViewed timeIntervalSinceDate:now];
        double minutesInAnHour = 60;
        hoursBetweenDates = hoursBetweenDates + (distanceBetweenDates / minutesInAnHour);
        
        int hour = hoursBetweenDates / 60;
        int min = hoursBetweenDates % 60;
        NSString *timeString = [NSString stringWithFormat:@"%dh %02dm", hour, min];
        NSLog(@"Total Time: %@", timeString);
        
        if (hour<0) {
            _lblTotalTime.text=[NSString stringWithFormat:@"0h 0m"];
        }else{
            _lblTotalTime.text=timeString;
        }
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
    
    
    NSString *strPath=[NSString stringWithFormat:@"/rest/s1/ft/attendance/log/?username=%@&pageIndex=%i&pageSize=10",[dict valueForKey:@"username"],pageNumber];
    
    NSLog(@"String Path for Get History===%@",strPath);
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
        
        //        arrayForTableData=[[JSON objectForKey:@"userTimeLog"] mutableCopy];
        NSMutableArray *array=[[JSON objectForKey:@"userTimeLog"] mutableCopy];
        for (NSDictionary *dict in array) {
            [arrayForTableData addObject:dict];
        }
        
        arrayCountToCheck=[[JSON objectForKey:@"userTimeLog"] count];
        
        [_tableVw reloadData];
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

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (IBAction)onClickBackBtn:(UIButton *)sender {
    _vwForIndividualItem.hidden = YES;
    _backBtn.hidden = YES;
}
@end
