//
//  MKMoreVC.m
//  OppoAttendanceTracker
//
//  Created by User1 on 12/20/16.
//
//

#import "MKMoreVC.h"

@interface MKMoreVC ()
{
    NSMutableArray *arrayForTableData;
}
@end

@implementation MKMoreVC
#pragma mark - View
- (void)viewDidLoad {
    [super viewDidLoad];
    
    

    arrayForTableData=[[NSMutableArray alloc] initWithObjects:@"Stores",@"Promoters",@"Leaves",@"Contact Support",@"Log Off", nil];
    
    
    _tableVw.delegate = self;
    _tableVw.dataSource = self;
    _tableVw.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableVw.tableFooterView=[[UIView alloc] init];
}

-(void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = YES;
    self.navigationItem.hidesBackButton = YES;
    [self.navigationItem setHidesBackButton:YES];
}




#pragma mark- UITableView

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return arrayForTableData.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (cell == nil) {
        
        cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text=[arrayForTableData objectAtIndex:indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 4)
    {
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UITabBarController *rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"MainRoot"];
        [[UIApplication sharedApplication].keyWindow setRootViewController:rootViewController];
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

@end
