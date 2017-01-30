//
//  MKAgentListCell.h
//  Field Tracker
//
//  Created by User1 on 1/24/17.
//
//

#import <UIKit/UIKit.h>

@interface MKAgentListCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *lblFieldAgentName;
@property (weak, nonatomic) IBOutlet UILabel *lblStoreLocation;
@property (weak, nonatomic) IBOutlet UILabel *lblStatus;

@end
