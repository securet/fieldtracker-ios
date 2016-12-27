//
//  MKHistoryCustomCell.h
//  OppoAttendanceTracker
//
//  Created by User1 on 12/20/16.
//
//

#import <UIKit/UIKit.h>

@interface MKHistoryCustomCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *lblDate;
@property (strong, nonatomic) IBOutlet UILabel *lblInTime;
@property (strong, nonatomic) IBOutlet UILabel *lblOutTime;
@property (strong, nonatomic) IBOutlet UILabel *lblTotalTime;

@end
