//
//  MKAPICall.h
//  Field Tracker
//
//  Created by User1 on 3/20/17.
//
//

#import <Foundation/Foundation.h>

@interface MKAPICall : NSObject
+(NSDictionary*)getRequest:(NSString*)methodType
                   forPath:(NSString*)path
             forParameters:(NSDictionary*)jsonInput;

+(NSDictionary*)getLogin:(NSString*)methodType
                   forPath:(NSString*)path
               forDomain:(NSString*)domainName;
@end
