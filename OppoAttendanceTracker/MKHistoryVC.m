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
    
    
    
    _tableVwForIndividual.delegate = self;
    _tableVwForIndividual.dataSource = self;
    _tableVwForIndividual.tableFooterView = [[UIView alloc] init];
    _tableVwForIndividual.separatorStyle = UITableViewCellSeparatorStyleNone;

    
    
    
    _vwForIndividualItem.hidden = YES;
    _backBtn.hidden = YES;
    
    [self getHistory];
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
}
#pragma mark- UITableView

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == _tableVwForIndividual) {
        return 6;
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
            cell.lblForTime.text =@"10:40 am";
            cell.lblForStatus.text=@"Time In";
        }
        else if (indexPath.row==1){
            cell.imgVwForStatusIcon.image=[UIImage imageNamed:@"dot_inlocation"];
            cell.lblForTime.text =@"11:40 am";
            cell.lblForStatus.text=@"In location";
        }
        else if (indexPath.row==2){
            cell.imgVwForStatusIcon.image=[UIImage imageNamed:@"dot_outlocation"];
            cell.lblForTime.text =@"12:40 pm";
            cell.lblForStatus.text=@"Out of location";
        }
        else if (indexPath.row==3){
            cell.imgVwForStatusIcon.image=[UIImage imageNamed:@"dot_inlocation"];
            cell.lblForTime.text =@"02:40 pm";
            cell.lblForStatus.text=@"In location";
        }
        else if (indexPath.row==4){
            cell.imgVwForStatusIcon.image=[UIImage imageNamed:@"dot_outlocation"];
            cell.lblForTime.text =@"03:40 pm";
            cell.lblForStatus.text=@"Out of location";
        }
        else if (indexPath.row==5){
            cell.imgVwForStatusIcon.image=[UIImage imageNamed:@"dot_timeout"];
            cell.lblForTime.text =@"05:40 pm";
            cell.lblForStatus.text=@"Time Out";
        }



        
        
        return cell;
    }
    ////
    if (cell == nil) {
        
        cell=[[MKHistoryCustomCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    
    
    NSString *strDate=[[arrayForTableData objectAtIndex:indexPath.row]valueForKey:@"estimatedCompletionDate"];

    NSRange range = [strDate rangeOfString:@"T"];
    
    strDate=[strDate substringToIndex:NSMaxRange(range)-1];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-mm-dd"];
    NSDate *date = [dateFormatter dateFromString:strDate];
    
    
    
    NSDateFormatter *dateFormatter2 = [[NSDateFormatter alloc] init];
    [dateFormatter2 setDateFormat:@"dd-mm-yyyy"];
    NSString *newDateString = [dateFormatter2 stringFromDate:date];
    
   
    
    
cell.lblDate.text=newDateString;
    
    
    
    return cell;
}



-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (tableView == _tableVw) {
        _vwForIndividualItem.hidden = NO;
        _backBtn.hidden = NO;

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
    
    NSString *strPath=[NSString stringWithFormat:@"/rest/s1/ft/attendance/log/?username=anand@securet.in&pageIndex=0&pageSize=10"];
    
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
        
        NSLog(@"Store List==%@",JSON);
        arrayForTableData=[[JSON objectForKey:@"userTimeLog"] mutableCopy];
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
