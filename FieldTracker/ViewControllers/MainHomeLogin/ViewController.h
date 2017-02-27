//
//  ViewController.h
//  OppoAttendanceTracker
//
//  Created by User1 on 12/20/16.
//
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UITextFieldDelegate>


@property (strong,nonatomic) IBOutlet UITextField *txtFieldForEmail;
@property (strong, nonatomic) IBOutlet UITextField *txtFieldForPassword;
@property (strong, nonatomic) IBOutlet UITextField *txtFieldForDomainName;

@property (strong, nonatomic) IBOutlet UIButton *btnLogin;
@property (strong, nonatomic) IBOutlet UIButton *btnForgotPwd;
@property (strong, nonatomic) IBOutlet UIImageView *imgVwForLogo;
@property (strong, nonatomic) IBOutlet UIImageView *imgVwForDeveloperLogo;

- (IBAction)onClickLogin:(UIButton *)sender;
- (IBAction)onClickForgotPassword:(UIButton *)sender;

@end

