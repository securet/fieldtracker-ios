//
//  MKMoreVC.h
//  OppoAttendanceTracker
//
//  Created by User1 on 12/20/16.
//
//
  
#import <UIKit/UIKit.h>

@interface MKMoreVC : UIViewController<UITableViewDelegate,UITableViewDataSource>


@property (strong, nonatomic) IBOutlet UITableView *tableVw;
@property (strong, nonatomic) IBOutlet UITableView *tableVwForStore;
@property (strong, nonatomic) IBOutlet UITableView *tableVwForPromoters;
@property (strong, nonatomic) IBOutlet UITableView *tableVwForLeaveRqst;

@property (strong, nonatomic) IBOutlet UIView *vwForStore;
@property (strong, nonatomic) IBOutlet UIView *vwForPromoters;
@property (strong, nonatomic) IBOutlet UIView *vwForLeaveRqst;

@property (strong, nonatomic) IBOutlet UIButton *backBtn;
- (IBAction)onClickBackBtn:(UIButton *)sender;

@end
