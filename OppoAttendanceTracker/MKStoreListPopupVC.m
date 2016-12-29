//
//  MKStoreListPopupVC.m
//  Field Tracker
//
//  Created by User1 on 12/27/16.
//
//

#import "MKStoreListPopupVC.h"
#import "IQKeyboardManager.h"
@interface MKStoreListPopupVC ()
{
    NSMutableArray *arrayForStoreList;
    NSMutableArray*filterResultArray;
    NSMutableArray *searchArray;
    BOOL searchBarActive;
}
@end

@implementation MKStoreListPopupVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _tableVw.delegate = self;
    _tableVw.dataSource = self;
    _tableVw.tableFooterView=[[UIView alloc] init];
    [self getStores];
    
    self.searchBar.searchBarStyle       = UISearchBarStyleMinimal;
    self.searchBar.tintColor            = [UIColor blackColor];
    self.searchBar.barTintColor         = [UIColor blackColor];
    self.searchBar.delegate             = self;
    self.searchBar.placeholder          = @"Search here";
    self.searchBar.backgroundColor=[UIColor lightGrayColor];
    
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor blackColor]];
    
    
    [[IQKeyboardManager sharedManager] setEnableAutoToolbar:NO];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    // Do the search...
}
-(BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIColor blackColor],NSForegroundColorAttributeName,[UIColor blackColor],
    UITextAttributeTextShadowColor,[NSValue valueWithUIOffset:UIOffsetMake(0, -1)],UITextAttributeTextShadowOffset,nil] forState:UIControlStateNormal];
    searchBar.showsScopeBar = YES;
    [searchBar sizeToFit];
    [searchBar setShowsCancelButton:YES animated:YES];
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    searchBar.showsScopeBar = NO;
    [searchBar sizeToFit];
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
    return YES;
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text=@"";
//    self.lblForHelp.hidden=YES;
    searchBarActive = NO;
 
//    searchBar.showsScopeBar = NO;
//    [searchBar sizeToFit];
//    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];

    
    [_tableVw reloadData];
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    NSPredicate *resultPredicate    = [NSPredicate predicateWithFormat:@"self contains[c] %@", searchText];
    searchArray=[[NSMutableArray alloc] init];
    for (NSDictionary *dict in arrayForStoreList) {
        [searchArray addObject:[dict valueForKey:@"storeName"]];
    }
    
    
    filterResultArray  = [[searchArray filteredArrayUsingPredicate:resultPredicate] mutableCopy];
    
    if ([filterResultArray count] > 0)
    {
        NSLog(@"Search Data===%@",filterResultArray);
        
    }
    else
    {
        NSLog(@"Search Data===%@",filterResultArray);
//        self.lblForHelp.hidden=NO;
    }
    [self.tableVw reloadData];
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (searchText.length>0)
    {
        searchBarActive = YES;
        [self filterContentForSearchText:searchText
                                   scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                          objectAtIndex:[self.searchDisplayController.searchBar
                                                         selectedScopeButtonIndex]]];
    }
    else
    {
        // if text lenght == 0
        // we will consider the searchbar is not active
        searchBarActive = NO;
    }
}

#pragma mark -

#pragma mark - Get Store's


-(void)getStores{
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    httpClient.parameterEncoding = AFFormURLParameterEncoding;
    [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    NSString *str=[defaults valueForKey:@"BasicAuth"];
    
    
    [httpClient setDefaultHeader:@"Authorization" value:str];
    
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET"
                                                            path:@"/rest/s1/ft/stores/user/list"
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
        
       
        arrayForStoreList=[JSON objectForKey:@"userStores"];
        
        
        
        [_tableVw reloadData];
    }
     //==================================================ERROR
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         [DejalBezelActivityView removeView];
                                         NSLog(@"Error %@",[error description]);
                                     }];
    [operation start];
    
}
#pragma mark- UITableView

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (searchBarActive) {
        return filterResultArray.count;
    }
       return arrayForStoreList.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (cell == nil){
        cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
        //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if (searchBarActive) {
        cell.textLabel.text=[filterResultArray objectAtIndex:indexPath.row];
    }else{
        cell.textLabel.text=[[arrayForStoreList objectAtIndex:indexPath.row] valueForKey:@"storeName"];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
    
    NSString *storeName = cell.textLabel.text;
    NSInteger indexForStoreData;
    for (NSDictionary *dict in arrayForStoreList) {
        if ([[dict valueForKey:@"storeName"] isEqualToString:storeName]) {
            indexForStoreData=[arrayForStoreList indexOfObject:dict];
        }
    }
    
    [[MKSharedClass shareManager] setDictForStoreSelected:[arrayForStoreList objectAtIndex:indexForStoreData]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CloseView" object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectedStore" object:self];
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

- (IBAction)onClickBackBtn:(UIButton *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CloseView" object:self];
}
@end
