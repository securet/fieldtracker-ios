//
//  MKHistoryVC.h
//  OppoAttendanceTracker
//
//  Created by User1 on 12/20/16.
//
//

#import <UIKit/UIKit.h>

@interface MKHistoryVC : UIViewController<UITableViewDelegate,UITableViewDataSource>


@property (strong, nonatomic) IBOutlet UIImageView *imgVwUser;


@property (weak, nonatomic) IBOutlet UILabel *lblFName;
@property (weak, nonatomic) IBOutlet UILabel *lblLName;
@property (strong, nonatomic) IBOutlet UILabel *lblTime;
@property (strong, nonatomic) IBOutlet UILabel *lblAMOrPM;

@property (strong, nonatomic) IBOutlet UILabel *lblNodata;

@property (strong, nonatomic) IBOutlet UITableView *tableVw;
@property (strong, nonatomic) IBOutlet UITableView *tableVwForIndividual;

@property (strong, nonatomic) IBOutlet UIView *vwForIndividualItem;
@property (strong, nonatomic) IBOutlet UIButton *backBtn;

@property (strong, nonatomic) IBOutlet UILabel *lblEntryDate;
@property (strong, nonatomic) IBOutlet UILabel *lblTimeIn;
@property (strong, nonatomic) IBOutlet UILabel *lblTimeOut;
@property (strong, nonatomic) IBOutlet UILabel *lblTotalTime;


@property (weak, nonatomic) IBOutlet UIImageView *imgVwForLocationIcon;
@property (weak, nonatomic) IBOutlet UILabel *lblForStoreLocation;

- (IBAction)onClickBackBtn:(UIButton *)sender;




@end
