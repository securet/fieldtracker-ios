//
//  MKAPICall.m
//  Field Tracker
//
//  Created by User1 on 3/20/17.
//
//

#import "MKAPICall.h"

@implementation MKAPICall

+(NSDictionary*)getRequest:(NSString*)methodType
                   forPath:(NSString*)path
             forParameters:(NSDictionary*)jsonInput{
    NSDictionary *dictionaryData=[[NSDictionary alloc] init];
    return dictionaryData;
}


+(NSDictionary*)getLogin:(NSString*)methodType
                 forPath:(NSString*)path
             forUserName:(NSString*)userName
             forPassword:(NSString*)password
               forDomain:(NSString*)domainName{
    
    NSDictionary *dictionaryData=[[NSDictionary alloc] init];
//    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
//    
//    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@",domainName]];
//    
//    APPDELEGATE.Base_URL=[NSString stringWithFormat:@"http://%@",domainName];
//    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
//    httpClient.parameterEncoding = AFFormURLParameterEncoding;
//    [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
//    NSString *str=[NSString stringWithFormat:@"%@:%@",userName,password];
//    NSString *auth_String;
//    NSData *nsdata = [str
//                      dataUsingEncoding:NSUTF8StringEncoding];
//    
//    NSString *base64Encoded = [nsdata base64EncodedStringWithOptions:0];
//    auth_String=[NSString stringWithFormat:@"Basic %@",base64Encoded];
//    [defaults setObject:auth_String forKey:@"BasicAuth"];
//    [httpClient setDefaultHeader:@"Authorization" value:auth_String];
//    
//    NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET"
//                                                            path:@"/rest/s1/ft/user"
//                                                      parameters:nil];
//    
//    //====================================================RESPONSE
//   // [DejalBezelActivityView activityViewForView:self->view];
//    
//    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
//    
//    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
//        
//    }];
//    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSError *error = nil;
//        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
//        NSLog(@"User Data===%@",JSON);
//        dictionaryData=JSON;
//        [DejalBezelActivityView removeView];
//           }
//     //==================================================ERROR
//                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//                                         [DejalBezelActivityView removeView];
//                                         NSLog(@"%i====Error %@",[operation.response statusCode],[error description]);
//                                         
//                                         NSError *jsonError;
//                                         NSData *errorData = [[[error userInfo] objectForKey:NSLocalizedRecoverySuggestionErrorKey] dataUsingEncoding:NSUTF8StringEncoding];
//                                         
//                                         if (errorData != nil) {
//                                             
//                                             NSDictionary *json = [NSJSONSerialization JSONObjectWithData:errorData
//                                                                                                  options:NSJSONReadingMutableContainers
//                                                                                                    error:&jsonError];
//                                             
//                                             NSString *strError=[json valueForKey:@"errors"];
//                                             [[[UIAlertView alloc] initWithTitle:@""
//                                                                         message:strError
//                                                                        delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
//                                         }
//                                     }];
//    [operation start];
    
    return dictionaryData;
}

@end
