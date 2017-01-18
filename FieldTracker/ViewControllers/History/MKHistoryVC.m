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

    _lblNodata.hidden = YES;
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
    
    _lblForStoreLocation.text=@"";
    [self changeLocationStatus:[[MKSharedClass shareManager] dictForCheckInLoctn]];
    
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
    _tableVw.hidden = NO;
    _lblNodata.hidden = YES;
    
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
    
    if ([CLLocationManager locationServicesEnabled]) {
        
    }else{
        [[[UIAlertView alloc] initWithTitle:@""
                                    message:@"Please Enable GPS"
                                   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
    }
}

- (void)refreshFooter
{
    if(arrayCountToCheck > pageNumber){
        pageNumber++;
        
        [self getHistory];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableVw reloadData];
            [self.tableVw footerEndRefreshing];
            //        [self.tableVw removeFooter];
        });
    }else{
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
            cell.lblForTime.text= [self getTimeIndividual:[arrayForStatusData objectAtIndex:indexPath.row]];
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
    
    NSMutableArray *array=[[NSMutableArray alloc] init];
    NSInteger   hoursBetweenDates = 0;
    
    for (NSDictionary *dict in [[arrayForTableData objectAtIndex:indexPath.row] objectForKey:@"timeEntryList"]) {
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
            cell.lblTotalTime.text=[NSString stringWithFormat:@"--"];
        }
    }else{
        cell.lblTotalTime.text=[NSString stringWithFormat:@"--"];
    }

/*
    if (![[[array objectAtIndex:0] valueForKey:@"fromDate"] isKindOfClass:[NSNull class]]) {
        cell.lblInTime.text=[NSString stringWithFormat:@"Time In: %@",[self getTime:[[array objectAtIndex:0] valueForKey:@"fromDate"]]];
    }
    else{
        cell.lblInTime.text=[NSString stringWithFormat:@"Time In: --"];
    }
    
    if (![[[array lastObject] valueForKey:@"thruDate"] isKindOfClass:[NSNull class]] ) {
        cell.lblOutTime.text=[NSString stringWithFormat:@"Time Out: %@",[self getTime:[[array lastObject] valueForKey:@"thruDate"]]];
    }else{
        cell.lblOutTime.text=[NSString stringWithFormat:@"Time Out: --"];
    }
 
    
    if (![[[array lastObject] valueForKey:@"thruDate"] isKindOfClass:[NSNull class]] && ![[[array objectAtIndex:0] valueForKey:@"fromDate"] isKindOfClass:[NSNull class]])
    {
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
            _lblTotalTime.text=[NSString stringWithFormat:@"--"];
        }
    }else{
        cell.lblTotalTime.text=[NSString stringWithFormat:@"--"];
    }
    */
    
    return cell;
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

-(NSString*)getTime:(NSString*)strDate
{
    if ([strDate isKindOfClass:[NSNull class]]) {
        return @"--";
    }

    strDate = [strDate stringByReplacingOccurrencesOfString:@"T" withString:@" "];
    strDate = [strDate stringByReplacingOccurrencesOfString:@"+0000" withString:@" +0000"];
    strDate=[strDate substringFromIndex:11];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"HH:mm:ss xxxx";
    NSDate *date = [dateFormatter dateFromString:strDate];
    dateFormatter.dateFormat = @"hh:mm a";
    strDate = [dateFormatter stringFromDate:date];
    
//    NSLog (@"%@", strDate);
    
    return strDate;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (tableView == _tableVw) {
        _vwForIndividualItem.hidden = NO;
        _backBtn.hidden = NO;
        
        arrayForStatusData=[[NSMutableArray alloc] init];
        
        //arrayForStatusData=[[arrayForTableData objectAtIndex:indexPath.row] objectForKey:@"timeEntryList"];
        
        for (NSDictionary *dict in [[arrayForTableData objectAtIndex:indexPath.row] objectForKey:@"timeEntryList"]) {
            [arrayForStatusData addObject:[dict valueForKey:@"fromDate"]];
            [arrayForStatusData addObject:[dict valueForKey:@"thruDate"]];
        }
        
        arrayForStatusData = [self sortingArrayByDate:arrayForStatusData];
       
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
    
        if (![[arrayForStatusData objectAtIndex:0] isKindOfClass:[NSNull class]]) {
            newDateString = [self getTimeIndividual:[arrayForStatusData objectAtIndex:0]];
        }else{
            newDateString = @"--";
        }
        _lblTimeIn.text=[NSString stringWithFormat:@"Time In: %@",newDateString];
        
        if (![[arrayForStatusData lastObject] isKindOfClass:[NSNull class]]) {
            newDateString = [self getTimeIndividual:[arrayForStatusData lastObject]];
        }else{
            newDateString = @"--";
        }
        _lblTimeOut.text=[NSString stringWithFormat:@"Time Out: %@",newDateString];
        
        MKHistoryCustomCell *cell=(MKHistoryCustomCell*)[tableView cellForRowAtIndexPath:indexPath];
        _lblTotalTime.text = cell.lblTotalTime.text;
        
        /*
        NSArray *array=[[NSArray alloc] init];
        NSInteger   hoursBetweenDates = 0;
        
        array=[[arrayForTableData objectAtIndex:indexPath.row] objectForKey:@"timeEntryList"];
        
        NSString *firstViewd;
        
        firstViewd=[NSString stringWithFormat:@"%@",[[array objectAtIndex:0] valueForKey:@"fromDate"]];
        firstViewd = [firstViewd stringByReplacingOccurrencesOfString:@"T" withString:@" "];
        firstViewd = [firstViewd stringByReplacingOccurrencesOfString:@"+0000" withString:@" +0000"];
        
        NSString *lastViewedString;
        
        lastViewedString=[NSString stringWithFormat:@"%@",[[array lastObject] valueForKey:@"thruDate"]];
        lastViewedString = [lastViewedString stringByReplacingOccurrencesOfString:@"T" withString:@" "];
        lastViewedString = [lastViewedString stringByReplacingOccurrencesOfString:@"+0000" withString:@" +0000"];
        
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
        NSLog(@"Total Time: %@", timeString);
        
        if (hour<0) {
            _lblTotalTime.text=[NSString stringWithFormat:@"--"];
        }else{
            _lblTotalTime.text=timeString;
        }
        
        if ([timeString isEqualToString:@"0h 00m"]) {
            _lblTotalTime.text=[NSString stringWithFormat:@"--"];
        }         */
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
    NSLog(@"%@",[dict valueForKey:@"username"]);
    NSString *strPath=[NSString stringWithFormat:@"/rest/s1/ft/attendance/log/?username=%@&pageIndex=%li&pageSize=10",[dict valueForKey:@"username"],(long)pageNumber];
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
        
        NSLog(@"History Data====%@",JSON);
        
        arrayCountToCheck=[[JSON objectForKey:@"totalEntries"] integerValue];
        
        if (arrayCountToCheck == 0) {
            _lblNodata.hidden = NO;
            _tableVw.hidden = YES;
        }
        [_tableVw reloadData];
    }
     //==================================================ERROR
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         [DejalBezelActivityView removeView];
                                         
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
  
    }
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