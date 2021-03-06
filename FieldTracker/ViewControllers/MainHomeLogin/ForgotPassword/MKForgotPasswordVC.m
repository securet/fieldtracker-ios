//
//  MKForgotPasswordVC.m
//  Field Tracker
//
//  Created by User1 on 1/23/17.
//
//

#import "MKForgotPasswordVC.h"

@interface MKForgotPasswordVC ()

@end

@implementation MKForgotPasswordVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor clearColor];
    
//    self.bgImgVw.layer.cornerRadius=5;
//    self.bgImgVw.layer.masksToBounds = YES;

    self.btnSubmit.layer.cornerRadius=5;
    self.btnSubmit.layer.masksToBounds = YES;
    
    [self addPadding:_textFieldNewPwd];
    [self addPadding:_textFieldConfirmPwd];
}

#pragma mark - AddPadding

-(void)addPadding:(UITextField*)txtField{
    
    //txtField.delegate = self;
    
    txtField.keyboardType=UIKeyboardTypeASCIICapable;
    
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 20)];
    txtField.leftView = paddingView;
    txtField.leftViewMode = UITextFieldViewModeAlways;
    txtField.layer.cornerRadius=5;
    
    UIImageView *imgVw=[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    imgVw.image=[UIImage imageNamed:@"password"];
    imgVw.contentMode = UIViewContentModeScaleAspectFit;
    txtField.rightView=imgVw;
    txtField.rightViewMode=UITextFieldViewModeAlways;
    
    [txtField addTarget:self action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)onClickBack:(UIButton *)sender {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CloseView" object:self];
}

- (IBAction)onClickSubmit:(UIButton *)sender {
    [self.view endEditing:YES];
//    if (_textFieldNewPwd.text.length>0 ) {
    
        if ([APPDELEGATE connected]) {
        
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CloseView" object:self];
            }else{
                UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"It appears you are not connected to internet" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
//        }else{
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please Enter All Fields" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//            [alert show];
//        }
}

-(BOOL)isValidEmail:(NSString *)checkString
{
    BOOL stricterFilter = NO;
    NSString *stricterFilterString = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
    NSString *laxString = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}


@end
