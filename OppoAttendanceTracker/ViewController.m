//
//  ViewController.m
//  OppoAttendanceTracker
//
//  Created by User1 on 12/20/16.
//
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self addPadding:_txtFieldForEmail];
    [self addPadding:_txtFieldForPassword];
    
    _btnLogin.layer.cornerRadius = 5;
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.navigationItem setHidesBackButton:YES];
    self.navigationController.navigationBarHidden = YES;
}

#pragma mark - AddPadding

-(void)addPadding:(UITextField*)txtField
{
    
    txtField.delegate = self;
    
    txtField.keyboardType=UIKeyboardTypeASCIICapable;
    
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 20)];
    txtField.leftView = paddingView;
    txtField.leftViewMode = UITextFieldViewModeAlways;
    txtField.layer.cornerRadius=5;

    UIImageView *imgVw=[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
    
    if (txtField == _txtFieldForEmail)
    {
            imgVw.image=[UIImage imageNamed:@"email"];
    }
    else if (txtField == _txtFieldForPassword)
    {
            imgVw.image=[UIImage imageNamed:@"password"];
    }
    
    imgVw.contentMode = UIViewContentModeScaleAspectFit;
    txtField.rightView=imgVw;
    txtField.rightViewMode=UITextFieldViewModeAlways;
}

#pragma mark - TextField 

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([textField isFirstResponder])
    {
        if ([[[textField textInputMode] primaryLanguage] isEqualToString:@"emoji"] || ![[textField textInputMode] primaryLanguage])
        {
            return NO;
        }
    }
    return YES;
}

#pragma mark -
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onClickLogin:(UIButton *)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UITabBarController *rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"HomeRoot"];
    [[UIApplication sharedApplication].keyWindow setRootViewController:rootViewController];
}
@end
