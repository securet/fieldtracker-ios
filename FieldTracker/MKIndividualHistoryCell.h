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
@property (strong, nonatomic) IBOutlet UIImageView *imgVwForLine;

@property (strong, nonatomic) IBOutlet UIImageView *imgVwForTopVerticalLine;
@property (strong, nonatomic) IBOutlet UIImageView *imgVwForBtmVerticalLine;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *centerConstraint;
@end
