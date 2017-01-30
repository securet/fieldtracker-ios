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
    
    //    _txtFieldForEmail.text=@"anand@securet.in";
    //    _txtFieldForPassword.text=@"test@1234";
    _txtFieldForEmail.text=@"";
    _txtFieldForPassword.text=@"";
    [self addPadding:_txtFieldForEmail];
    [self addPadding:_txtFieldForPassword];
    
    _btnLogin.layer.cornerRadius = 5;
    
    _txtFieldForEmail.keyboardType = UIKeyboardTypeEmailAddress;
    
    if (![APPDELEGATE connected]) {
        
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"It appears you are not connected to internet" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [self.navigationItem setHidesBackButton:YES];
    self.navigationController.navigationBarHidden = YES;
}

#pragma mark - AddPadding

-(void)addPadding:(UITextField*)txtField{
    
    txtField.delegate = self;
    
    txtField.keyboardType=UIKeyboardTypeASCIICapable;
    
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 20)];
    txtField.leftView = paddingView;
    txtField.leftViewMode = UITextFieldViewModeAlways;
    txtField.layer.cornerRadius=5;
    
    UIImageView *imgVw=[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    
    if (txtField == _txtFieldForEmail){
        imgVw.image=[UIImage imageNamed:@"email"];
    }
    else if (txtField == _txtFieldForPassword){
        imgVw.image=[UIImage imageNamed:@"password"];
    }
    
    imgVw.contentMode = UIViewContentModeScaleAspectFit;
    txtField.rightView=imgVw;
    txtField.rightViewMode=UITextFieldViewModeAlways;
    
    
    [txtField addTarget:self action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
}

#pragma mark - TextField

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if ([textField isFirstResponder]){
        if ([[[textField textInputMode] primaryLanguage] isEqualToString:@"emoji"] || ![[textField textInputMode] primaryLanguage]){
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

- (IBAction)onClickLogin:(UIButton *)sender{
    
    if (_txtFieldForEmail.text.length>0 && _txtFieldForPassword.text.length>0) {
        
        if ([self isValidEmail:_txtFieldForEmail.text]) {
            
            if ([APPDELEGATE connected]) {
                [self login];
            }else{
                UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"It appears you are not connected to internet" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        }else{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please Enter Valid Email ID" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            _txtFieldForEmail.text=@"";
        }
    }
    else{
        
        if (_txtFieldForEmail.text.length <= 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please Enter Email ID" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else if (_txtFieldForPassword.text.length <= 0){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please Enter Password" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }
}

- (IBAction)onClickForgotPassword:(UIButton *)sender {
    
    if (_txtFieldForEmail.text.length > 0) {
        if ([self isValidEmail:_txtFieldForEmail.text]) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            UIViewController *smallViewController = [storyboard instantiateViewControllerWithIdentifier:@"MKForgotPasswordVC"];
            
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
                BIZPopupViewController *popupViewController = [[BIZPopupViewController alloc] initWithContentViewController:smallViewController contentSize:CGSizeMake(self.view.frame.size.width-100, self.view.frame.size.height/2+100)];
                [self presentViewController:popupViewController animated:NO completion:nil];
            }else{
                BIZPopupViewController *popupViewController = [[BIZPopupViewController alloc] initWithContentViewController:smallViewController contentSize:CGSizeMake(self.view.frame.size.width,self.view.frame.size.height)];
                [self presentViewController:popupViewController animated:NO completion:nil];
            }
        }else{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Email ID is not valid" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please Enter Email ID" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
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

-(void)login{
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    
    NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    httpClient.parameterEncoding = AFFormURLParameterEncoding;
    [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    NSString *str=[NSString stringWithFormat:@"%@:%@",_txtFieldForEmail.text,_txtFieldForPassword.text];
    
    NSString *auth_String;
    
    NSData *nsdata = [str
                      dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *base64Encoded = [nsdata base64EncodedStringWithOptions:0];
    
    auth_String=[NSString stringWithFormat:@"Basic %@",base64Encoded];
    
    [defaults setObject:auth_String forKey:@"BasicAuth"];
    [httpClient setDefaultHeader:@"Authorization" value:auth_String];
    
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET"
                                                            path:@"/rest/s1/ft/user"
                                                      parameters:nil];
    
    //====================================================RESPONSE
    [DejalBezelActivityView activityViewForView:self.view];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        
    }];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError *error = nil;
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
        NSLog(@"User Data===%@",JSON);
        
        [DejalBezelActivityView removeView];
        
        if ([[JSON objectForKey:@"user"] isKindOfClass:[NSArray class]]) {
            if ([[JSON objectForKey:@"user"] count]>0)
            {
                NSMutableDictionary *prunedDictionary = [NSMutableDictionary dictionary];
                for (NSString * key in [[[JSON objectForKey:@"user"] objectAtIndex:0] allKeys]){
                    
                    if (![[[[JSON objectForKey:@"user"] objectAtIndex:0] objectForKey:key] isKindOfClass:[NSNull class]])
                        [prunedDictionary setObject:[[[JSON objectForKey:@"user"] objectAtIndex:0] objectForKey:key] forKey:key];
                }
                
                [defaults setObject:@"1" forKey:@"Is_Login"];
                [defaults setObject:prunedDictionary forKey:@"UserData"];
                [defaults synchronize];
                
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                UITabBarController *rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"HomeRoot"];
                [[UIApplication sharedApplication].keyWindow setRootViewController:rootViewController];
            }else{
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Not account found" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        }else{
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Not account found" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }
     //==================================================ERROR
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         [DejalBezelActivityView removeView];
                                         NSLog(@"%i====Error %@",[operation.response statusCode],[error description]);
//                                         
//                                         if([operation.response statusCode] == 401)
//                                         {
//                                             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Not account found" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//                                             [alert show];
//                                         }
                                         NSError *jsonError;
                                         NSData *objectData = [[[error userInfo] objectForKey:NSLocalizedRecoverySuggestionErrorKey] dataUsingEncoding:NSUTF8StringEncoding];
                                         
                                         if (objectData != nil) {
                                             
                                             NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                                                                  options:NSJSONReadingMutableContainers
                                                                                                    error:&jsonError];
                                             
                                             NSString *strError=[json valueForKey:@"errors"];
                                             [[[UIAlertView alloc] initWithTitle:@""
                                                                         message:strError
                                                                        delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                                         }
                                     }];
    [operation start];
    
}



- (NSString*)encodeStringTo64:(NSString*)fromString
{
    NSData *plainData = [fromString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64String;
    if ([plainData respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
        base64String = [plainData base64EncodedStringWithOptions:kNilOptions];  // iOS 7+
    } else {
        base64String = [plainData base64Encoding];                              // pre iOS7
    }
    
    return base64String;
}
@end
