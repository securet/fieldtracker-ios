//
//  MKForgotPasswordVC.h
//  Field Tracker
//
//  Created by User1 on 1/23/17.
//
//

#import <UIKit/UIKit.h>

@interface MKForgotPasswordVC : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *textFieldNewPwd;
@property (strong, nonatomic) IBOutlet UITextField *textFieldConfirmPwd;
@property (strong, nonatomic) IBOutlet UIImageView *bgImgVw;
@property (strong, nonatomic) IBOutlet UIButton *btnSubmit;

- (IBAction)onClickBack:(UIButton *)sender;
- (IBAction)onClickSubmit:(UIButton *)sender;

@end
