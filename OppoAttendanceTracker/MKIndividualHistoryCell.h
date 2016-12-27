//
//  MKIndividualHistoryCell.h
//  OppoAttendanceTracker
//
//  Created by User1 on 12/26/16.
//
//

#import <UIKit/UIKit.h>

@interface MKIndividualHistoryCell : UITableViewCell


@property (strong, nonatomic) IBOutlet UILabel *lblForTime;
@property (strong, nonatomic) IBOutlet UILabel *lblForStatus;

@property (strong, nonatomic) IBOutlet UIImageView *imgVwForStatusIcon;

@end
