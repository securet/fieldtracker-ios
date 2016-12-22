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
