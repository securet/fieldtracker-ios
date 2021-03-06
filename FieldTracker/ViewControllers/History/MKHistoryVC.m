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

    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSMutableDictionary *dictForUserData=[[defaults objectForKey:@"UserData"] mutableCopy];
    self.lblFName.text=[dictForUserData valueForKey:@"firstName"];
    self.lblLName.text=[dictForUserData valueForKey:@"lastName"];

    if ([dictForUserData valueForKey:@"userPhotoPath"]) {
        NSString *baseURL=APPDELEGATE.Base_URL;
        NSString *str = [NSString stringWithFormat:@"//%@/uploads/uid/%@",[dictForUserData valueForKey:@"userPhotoPath"],baseURL];
        NSString *subStr = [str stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
        NSURL *imgUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@",subStr]];
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
    
    self.lblNodata.hidden = YES;
    self.tableVw.delegate = self;
    self.tableVw.dataSource = self;
    self.tableVw.tableFooterView = [[UIView alloc] init];
    self.tableVw.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    arrayForTableData=[[NSMutableArray alloc] init];
    
    self.tableVwForIndividual.delegate = self;
    self.tableVwForIndividual.dataSource = self;
    self.tableVwForIndividual.tableFooterView = [[UIView alloc] init];
    self.tableVwForIndividual.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.vwForIndividualItem.hidden = YES;
    self.backBtn.hidden = YES;
    
    pageNumber=0;
    [self.tableVw addFooterWithTarget:self action:@selector(refreshFooter) withIndicatorColor:TopColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkingInLocation:) name:@"LocationChecking" object:nil];
    
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(historyTabSelected) name:@"HistoryTabSelected" object:nil];
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clockTimeUpdating) name:@"clockTimeUpdating" object:nil];
}
-(void)viewWillAppear:(BOOL)animated{
    
    self.lblForStoreLocation.text=@"";
    [self changeLocationStatus:[[MKSharedClass shareManager] dictForCheckInLoctn]];
    
    self.navigationController.navigationBarHidden = YES;
    self.navigationItem.hidesBackButton = YES;
    [self.navigationItem setHidesBackButton:YES];
    
    self.tableVw.hidden = NO;
    self.lblNodata.hidden = YES;
    
    if (arrayForTableData.count<=0) {
        arrayForTableData=[[NSMutableArray alloc] init];
        pageNumber=0;
        [self getHistory];
    }
    
    [self.tableVw reloadData];
    
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
    
    [self clockTimeUpdating];
}

#pragma mark - 

-(void)historyTabSelected{
    self.vwForIndividualItem.hidden = YES;
    self.backBtn.hidden = YES;
}

-(void)clockTimeUpdating{
    
    NSDate *timeNow = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"hh:mm a";
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    self.lblTime.text=[[dateFormatter stringFromDate:timeNow] substringToIndex:[[dateFormatter stringFromDate:timeNow] length]-3];
    self.lblAMOrPM.text=[[dateFormatter stringFromDate:timeNow] substringFromIndex:[[dateFormatter stringFromDate:timeNow] length]-2];
}

-(void)checkingInLocation:(NSNotification*)notification{
    
    NSDictionary *userInfo = notification.userInfo;
    if ([[userInfo valueForKey:@"LocationStatus"] integerValue]==1) {
        self.imgVwForLocationIcon.image=[UIImage imageNamed:@"location_On"];
        self.lblForStoreLocation.textColor=[UIColor whiteColor];
    }else{
        self.imgVwForLocationIcon.image=[UIImage imageNamed:@"location_Off"];
        self.lblForStoreLocation.textColor=[UIColor darkGrayColor];
    }
    self.lblForStoreLocation.text=[userInfo valueForKey:@"StoreName"];
}

-(void)changeLocationStatus:(NSDictionary*)dictInfo{
    
    if ([[dictInfo valueForKey:@"LocationStatus"] integerValue]==1) {
        self.imgVwForLocationIcon.image=[UIImage imageNamed:@"location_On"];
        self.lblForStoreLocation.textColor=[UIColor whiteColor];
    }else{
        self.imgVwForLocationIcon.image=[UIImage imageNamed:@"location_Off"];
        self.lblForStoreLocation.textColor=[UIColor darkGrayColor];
    }
    self.lblForStoreLocation.text=[dictInfo valueForKey:@"StoreName"];
}


- (void)refreshFooter{
    if(arrayCountToCheck > pageNumber){
        pageNumber++;
        [self getHistory];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableVw reloadData];
            [self.tableVw footerEndRefreshing];
        });
    }else{
        [self.tableVw footerEndRefreshing];
        [self.tableVw headerEndRefreshing];
    }
}

#pragma mark- UITableView

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableVwForIndividual) {
        return arrayForStatusData.count;
    }
    return arrayForTableData.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    MKHistoryCustomCell *cell=[tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    //Individual View
    if (tableView == self.tableVwForIndividual) {
        MKIndividualHistoryCell *cell=[tableView dequeueReusableCellWithIdentifier:@"Cell"];
        if (cell == nil) {
            cell=[[MKIndividualHistoryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        /*
         ////Image Names
         dot_login rgb(48,174,242)
         dot_inlocation rgb(78,242,48)
         dot_outlocation  rgb(242,105,48)
         dot_timeout rgb(90,90,90)
         */
        
        cell.imgVwForStatusIcon.layer.cornerRadius = cell.imgVwForStatusIcon.frame.size.height/2;
        cell.imgVwForStatusIcon.layer.masksToBounds = YES;
        
        if (indexPath.row==0) {
            cell.imgVwForStatusIcon.image=[UIImage imageNamed:@""];
            cell.imgVwForStatusIcon.backgroundColor=[UIColor colorWithRed:(48/255.0) green:(174/255.0) blue:(242/255.0) alpha:1.0];
            
            cell.lblForStatus.text=@"Time In";
            cell.centerConstraint.constant = 0;
            cell.imgVwForTopVerticalLine.hidden=YES;
            cell.imgVwForBtmVerticalLine.hidden=NO;
        }else{
            if (indexPath.row % 2 == 0) {
                cell.imgVwForStatusIcon.image=[UIImage imageNamed:@""];
                cell.imgVwForStatusIcon.backgroundColor=[UIColor colorWithRed:(78/255.0) green:(242/255.0) blue:(48/255.0) alpha:1.0];
                
                cell.lblForStatus.text=@"In location";
                cell.centerConstraint.constant = -2;
            }else{
                cell.centerConstraint.constant = 2;
                cell.imgVwForStatusIcon.image=[UIImage imageNamed:@""];
                 cell.imgVwForStatusIcon.backgroundColor=[UIColor colorWithRed:(242/255.0) green:(105/255.0) blue:(48/255.0) alpha:1.0];
                cell.lblForStatus.text=@"Out of location";
            }
            cell.imgVwForTopVerticalLine.hidden=NO;
            cell.imgVwForBtmVerticalLine.hidden=NO;
        }
        
        if (indexPath.row==arrayForStatusData.count-1 && arrayForStatusData.count > 1){
            cell.centerConstraint.constant = 0;
            cell.imgVwForStatusIcon.image=[UIImage imageNamed:@""];
             cell.imgVwForStatusIcon.backgroundColor=[UIColor colorWithRed:(90/255.0) green:(90/255.0) blue:(90/255.0) alpha:1.0];
            
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
            cell.imgVwForStatusIcon.backgroundColor=[UIColor clearColor];
        }
        return cell;
    }
  
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
    
    
    NSMutableArray *arrayForTime=[[NSMutableArray alloc] init];
    NSInteger   hoursBetweenDates = 0;
    
    if ([[[arrayForTableData objectAtIndex:indexPath.row]objectForKey:@"timeEntryList"] isKindOfClass:[NSArray class]]) {
        
        if ([[[arrayForTableData objectAtIndex:indexPath.row]objectForKey:@"timeEntryList"] count]>0) {
        
            for (NSDictionary *dict in [[arrayForTableData objectAtIndex:indexPath.row] objectForKey:@"timeEntryList"]) {
                [arrayForTime addObject:[dict valueForKey:@"fromDate"]];
                [arrayForTime addObject:[dict valueForKey:@"thruDate"]];
            }
            
            arrayForTime =  [self sortingArrayByDate:arrayForTime];
            
            if (![[arrayForTime objectAtIndex:0] isKindOfClass:[NSNull class]]) {
                cell.lblInTime.text=[NSString stringWithFormat:@"Time In: %@",[self getTimeIndividual:[arrayForTime objectAtIndex:0] ]];
            }
            else{
                cell.lblInTime.text=[NSString stringWithFormat:@"Time In: --"];
            }
            
            if (![[arrayForTime lastObject]  isKindOfClass:[NSNull class]] ) {
                cell.lblOutTime.text=[NSString stringWithFormat:@"Time Out: %@",[self getTimeIndividual:[arrayForTime lastObject] ]];
            }else{
                cell.lblOutTime.text=[NSString stringWithFormat:@"Time Out: --"];
            }
            
            if (![[arrayForTime objectAtIndex:0] isKindOfClass:[NSNull class]] && ![[arrayForTime lastObject] isKindOfClass:[NSNull class]]){
                
                NSString *firstViewd;
                firstViewd=[NSString stringWithFormat:@"%@",[arrayForTime objectAtIndex:0]];
                NSString *lastViewedString;
                lastViewedString=[NSString stringWithFormat:@"%@",[arrayForTime lastObject]];
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
            
                if (hour<0) {
                    cell.lblTotalTime.text=[NSString stringWithFormat:@"--"];
                }else{
                    cell.lblTotalTime.text=timeString;
                }
                if ([timeString isEqualToString:@"0h 00m"]) {
                    cell.lblTotalTime.text=[NSString stringWithFormat:@"0h 01m"];
                }
            }else{
                cell.lblTotalTime.text=[NSString stringWithFormat:@"--"];
            }
        }else{
            cell.lblTotalTime.text=[NSString stringWithFormat:@"--"];
            cell.lblInTime.text=[NSString stringWithFormat:@"Time In: --"];
            cell.lblOutTime.text=[NSString stringWithFormat:@"Time Out: --"];
        }
    }else{
        cell.lblTotalTime.text=[NSString stringWithFormat:@"--"];
        cell.lblInTime.text=[NSString stringWithFormat:@"Time In: --"];
        cell.lblOutTime.text=[NSString stringWithFormat:@"Time Out: --"];
    }
    return cell;
}

-(NSString*)getTimeIndividual:(NSString*)strDate
{
    if ([strDate isKindOfClass:[NSNull class]]) {
        return @"--";
    }

    NSString *strDateChange=strDate;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss Z";
//    NSDateFormatter *dateFormatter1 = [[NSDateFormatter alloc] init];
//    dateFormatter1.dateFormat = @"yyyy-MM-dd HH:mm:ss Z";
//    NSDate *daate=[dateFormatter1 dateFromString:strDateChange];
//    NSTimeZone *tz = [NSTimeZone localTimeZone];
//    NSInteger seconds = [tz secondsFromGMTForDate:daate];
//    daate = [NSDate dateWithTimeInterval: seconds sinceDate: daate];
    
    NSDate *dateFromString = [dateFormatter dateFromString:strDateChange];
    dateFormatter.dateFormat = @"hh:mm a";
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:[NSTimeZone localTimeZone].secondsFromGMT];
    strDateChange = [dateFormatter stringFromDate:dateFromString];
   
    return strDateChange;
}

-(NSString*)getTime:(NSString*)strDate{
    
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
    
    if (tableView == self.tableVw) {
        self.vwForIndividualItem.hidden = NO;
        self.backBtn.hidden = NO;
        
        arrayForStatusData=[[NSMutableArray alloc] init];
        
        //arrayForStatusData=[[arrayForTableData objectAtIndex:indexPath.row] objectForKey:@"timeEntryList"];
        
        for (NSDictionary *dict in [[arrayForTableData objectAtIndex:indexPath.row] objectForKey:@"timeEntryList"]) {
            [arrayForStatusData addObject:[dict valueForKey:@"fromDate"]];
            [arrayForStatusData addObject:[dict valueForKey:@"thruDate"]];
        }
        
        arrayForStatusData = [self sortingArrayByDate:arrayForStatusData];
        
        [self.tableVwForIndividual reloadData];
        [self.tableVwForIndividual setContentOffset:CGPointZero animated:NO];
        
        ///Date Parsing
        NSString *strDate=[[arrayForTableData objectAtIndex:indexPath.row]valueForKey:@"estimatedCompletionDate"];
        NSRange range = [strDate rangeOfString:@"T"];
        strDate=[strDate substringToIndex:NSMaxRange(range)-1];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        NSDate *date = [dateFormatter dateFromString:strDate];
        [dateFormatter setDateFormat:@"dd-MMM-yyyy"];
        NSString *newDateString = [dateFormatter stringFromDate:date];
        self.lblEntryDate.text=newDateString;
        //////
        
        if ([arrayForStatusData count]>0) {
            if (![[arrayForStatusData objectAtIndex:0] isKindOfClass:[NSNull class]]) {
                newDateString = [self getTimeIndividual:[arrayForStatusData objectAtIndex:0]];
            }else{
                newDateString = @"--";
            }
            
            self.lblTimeIn.text=[NSString stringWithFormat:@"Time In: %@",newDateString];
            
            if (![[arrayForStatusData lastObject] isKindOfClass:[NSNull class]]) {
                newDateString = [self getTimeIndividual:[arrayForStatusData lastObject]];
            }else{
                newDateString = @"--";
            }
            
            self.lblTimeOut.text=[NSString stringWithFormat:@"Time Out: %@",newDateString];
        }else{
            self.lblTimeIn.text=[NSString stringWithFormat:@"Time In: --"];
            self.lblTimeOut.text=[NSString stringWithFormat:@"Time Out: --"];
        }
        MKHistoryCustomCell *cell=(MKHistoryCustomCell*)[tableView cellForRowAtIndexPath:indexPath];
        self.lblTotalTime.text = cell.lblTotalTime.text;
        
    }
}

-(NSMutableArray*)sortingArrayByDate:(NSMutableArray*)array{
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ssZ"];
    NSMutableArray *tempArray = [NSMutableArray array];
  
    NSMutableArray *arrayForNullValues=[[NSMutableArray alloc] init];
    
    for (NSString *dateString in array) {
        NSInteger indexValue=[array indexOfObject:dateString];
        if (![dateString isKindOfClass:[NSNull class]]){
            NSString *str=dateString;
            str = [str stringByReplacingOccurrencesOfString:@"T" withString:@" "];
            str = [str stringByReplacingOccurrencesOfString:@"+0000" withString:@" +0000"];
            NSDate *date = [formatter dateFromString:str];
            [tempArray addObject:date];
        }else{
            [arrayForNullValues addObject:[NSString stringWithFormat:@"%i",indexValue]];
        }
    }
    
    [tempArray sortUsingComparator:^NSComparisonResult(NSDate *date1, NSDate *date2) {
        return [date2 compare:date1];
    }];
    
    tempArray =[[[tempArray reverseObjectEnumerator] allObjects] mutableCopy];
    NSMutableArray *correctOrderStringArray = [NSMutableArray array];
    
    for (NSDate *date in tempArray) {
        [correctOrderStringArray addObject:date.description];
    }
    
    for (NSString *str in arrayForNullValues){
        NSInteger indexValue=[str integerValue];
        [correctOrderStringArray insertObject:[NSNull null] atIndex:indexValue];
    }
    
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
        NSString *strPath=[NSString stringWithFormat:@"/rest/s1/ft/attendance/log?username=%@&pageIndex=%li&pageSize=10",[dict valueForKey:@"username"],(long)pageNumber];
        
        NSString *strURL=[strPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        strURL=[strURL stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
        
        NSLog(@"String Path for Get History===%@",strURL);
        NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET"
                                                                path:strURL
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
                self.lblNodata.hidden = NO;
                self.tableVw.hidden = YES;
            }
            
            if (array.count <= 0) {
                arrayCountToCheck=0;
            }
            [self.tableVw reloadData];
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
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"It appears you are not connected to internet" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
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
    self.vwForIndividualItem.hidden = YES;
    self.backBtn.hidden = YES;
}

- (IBAction)onClickToggle:(UIButton *)sender {
    self.vwForIndividualItem.hidden = YES;
    self.backBtn.hidden = YES;
}
@end
