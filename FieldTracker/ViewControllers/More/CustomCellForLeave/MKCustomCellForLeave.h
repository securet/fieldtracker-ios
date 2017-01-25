//
//  MKCustomCellForLeave.h
//  OppoAttendanceTracker
//
//  Created by User1 on 12/21/16.
//
//

#import <UIKit/UIKit.h>

@interface MKCustomCellForLeave : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *lblForNumOfDays;
@property (strong, nonatomic) IBOutlet UILabel *lblForStartDate;
@property (strong, nonatomic) IBOutlet UILabel *lblForEndDate;
@property (strong, nonatomic) IBOutlet UILabel *lblForTypeOfLeave;
@property (strong, nonatomic) IBOutlet UILabel *lblForStatusOfLeave;
@property (strong, nonatomic) IBOutlet UILabel *lblForName;

@end
