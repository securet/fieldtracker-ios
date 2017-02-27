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
    
    //    self.txtFieldForEmail.text=@"anand@securet.in";
    //    self.txtFieldForPassword.text=@"test@1234";
    self.txtFieldForEmail.text=@"";
    self.txtFieldForPassword.text=@"";
    [self addPadding:self.txtFieldForEmail];
    [self addPadding:self.txtFieldForPassword];
    [self addPadding:self.txtFieldForDomainName];
    self.imgVwForLogo.image=[UIImage imageNamed:@""];
    self.btnLogin.layer.cornerRadius = 5;
    
    self.txtFieldForEmail.keyboardType = UIKeyboardTypeEmailAddress;
    
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
    
    if (txtField == self.txtFieldForEmail){
        imgVw.image=[UIImage imageNamed:@"email"];
    }else if (txtField == self.txtFieldForPassword){
        imgVw.image=[UIImage imageNamed:@"password"];
    }else if (txtField == self.txtFieldForDomainName){
        imgVw.image=[UIImage imageNamed:@"domain"];
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
    
    if (self.txtFieldForEmail.text.length>0 && self.txtFieldForPassword.text.length>0 && self.txtFieldForDomainName.text.length>0) {
        
        if ([self isValidEmail:self.txtFieldForEmail.text]) {
            
            if ([APPDELEGATE connected]) {
                [self login];
            }else{
                UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"It appears you are not connected to internet" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        }else{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please Enter Valid Email ID" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            self.txtFieldForEmail.text=@"";
        }
    }
    else{
        if (self.txtFieldForDomainName.text.length <= 0){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please Enter Domain Name" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }else if (self.txtFieldForEmail.text.length <= 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please Enter Email ID" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }else if (self.txtFieldForPassword.text.length <= 0){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please Enter Password" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }
}

- (IBAction)onClickForgotPassword:(UIButton *)sender {
    
    if (self.txtFieldForEmail.text.length > 0) {
        if ([self isValidEmail:self.txtFieldForEmail.text]) {
            
            [self forgotPassword];
            //            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            //            UIViewController *smallViewController = [storyboard instantiateViewControllerWithIdentifier:@"MKForgotPasswordVC"];
            //
            //            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            //                BIZPopupViewController *popupViewController = [[BIZPopupViewController alloc] initWithContentViewController:smallViewController contentSize:CGSizeMake(self.view.frame.size.width-100, self.view.frame.size.height/2+100)];
            //                [self presentViewController:popupViewController animated:NO completion:nil];
            //            }else{
            //                BIZPopupViewController *popupViewController = [[BIZPopupViewController alloc] initWithContentViewController:smallViewController contentSize:CGSizeMake(self.view.frame.size.width,self.view.frame.size.height)];
            //                [self presentViewController:popupViewController animated:NO completion:nil];
            //            }
        }else{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Email ID is not valid" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please Enter Email ID" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

-(void)forgotPassword{
    
    if ([APPDELEGATE connected]) {
        
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        NSURL * url = [NSURL URLWithString:APPDELEGATE.Base_URL];
        NSString *strAuthorization=[defaults valueForKey:@"BasicAuth"];
        
        AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
        httpClient.parameterEncoding = AFJSONParameterEncoding;
        [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [httpClient setDefaultHeader:@"Authorization" value:strAuthorization];
        
        NSDictionary * json;
        NSMutableURLRequest *request;
        
        json = @{@"userId":self.txtFieldForEmail.text
                 };
        request = [httpClient requestWithMethod:@"POST"
                                           path:@"/rest/s1/ft/resetPassword"
                                     parameters:json];
        NSLog(@"Json URL---POST===%@",json);
        
        //====================================================RESPONSE
        [DejalBezelActivityView activityViewForView:self.view];
        
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        }];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSError *error = nil;
            NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
            [DejalBezelActivityView removeView];
            NSLog(@"Forgot Password==%@ %ld",JSON,(long)[[operation response] statusCode]);
            if ([[operation response] statusCode] == 200) {
                UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:[JSON valueForKey:@"messages"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        }
         //==================================================ERROR
                                         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                             [DejalBezelActivityView removeView];
                                             NSLog(@"Error %@",[error description]);
                                             NSString *JSON = [[error userInfo] valueForKey:NSLocalizedRecoverySuggestionErrorKey] ;
                                             
                                             if (JSON.length>0) {
                                                 NSError *aerror = nil;
                                                 
                                                 NSDictionary *json = [NSJSONSerialization JSONObjectWithData: [JSON dataUsingEncoding:NSUTF8StringEncoding]
                                                                                                      options: NSJSONReadingMutableContainers
                                                                                                        error: &aerror];
                                                 NSLog(@"Error %@",json);
                                                 UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:[json valueForKey:@"errors"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                                 [alert show];
                                             }
                                             //You have already applied a leave
                                         }];
        [operation start];
    }else{
        
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"It appears you are not connected to internet" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
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
    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@",self.txtFieldForDomainName.text]];
    APPDELEGATE.Base_URL=[NSString stringWithFormat:@"http://%@",self.txtFieldForDomainName.text];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    httpClient.parameterEncoding = AFFormURLParameterEncoding;
    [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    NSString *str=[NSString stringWithFormat:@"%@:%@",self.txtFieldForEmail.text,self.txtFieldForPassword.text];
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
                    if (![key isEqualToString:@"reportingPerson"]) {
                        
                        if (![[[[JSON objectForKey:@"user"] objectAtIndex:0] objectForKey:key] isKindOfClass:[NSNull class]])
                            [prunedDictionary setObject:[[[JSON objectForKey:@"user"] objectAtIndex:0] objectForKey:key] forKey:key];
                    }
                }
                
                if ([[[JSON objectForKey:@"user"] objectAtIndex:0] objectForKey:@"reportingPerson"]) {
                    NSMutableDictionary *reportingPerson = [NSMutableDictionary dictionary];
                    for (NSString * key in [[[JSON objectForKey:@"user"] objectAtIndex:0] objectForKey:@"reportingPerson"]){
                        if (![key isEqualToString:@"reportingPerson"]) {
                            if (![[[[JSON objectForKey:@"user"] objectAtIndex:0] objectForKey:key] isKindOfClass:[NSNull class]])
                                [reportingPerson setObject:[[[JSON objectForKey:@"user"] objectAtIndex:0] objectForKey:key] forKey:key];
                        }
                    }
                    [prunedDictionary setObject:reportingPerson forKey:@"reportingPerson"];
                }
                
                //                [prunedDictionary setObject:[[[JSON objectForKey:@"user"] objectAtIndex:0] objectForKey:@"reportingPerson"] forKey:@"reportingPerson"];
                [defaults setObject:@"1" forKey:@"Is_Login"];
                [defaults setObject:prunedDictionary forKey:@"UserData"];
                [defaults setObject:self.txtFieldForDomainName.text forKey:@"Domain"];
                [defaults synchronize];
                
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                UITabBarController *rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"HomeRoot"];
                [[UIApplication sharedApplication].keyWindow setRootViewController:rootViewController];
            }else{
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"No account found" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        }else{
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"No account found" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
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
