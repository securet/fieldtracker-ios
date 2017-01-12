//
//  MKStoreListPopupVC.h
//  Field Tracker
//
//  Created by User1 on 12/27/16.
//
//

#import <UIKit/UIKit.h>

@interface MKStoreListPopupVC : UIViewController<UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate,UISearchDisplayDelegate>
@property (strong, nonatomic) IBOutlet UILabel *lblForHeader;
@property (strong, nonatomic) IBOutlet UITableView *tableVw;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
- (IBAction)onClickBackBtn:(UIButton *)sender;
@end
