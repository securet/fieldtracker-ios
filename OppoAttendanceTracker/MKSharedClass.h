//
//  MKSharedClass.h
//  OppoAttendanceTracker
//
//  Created by User1 on 12/22/16.
//
//

#import <Foundation/Foundation.h>

@interface MKSharedClass : NSObject

+(MKSharedClass*)shareManager;

@property NSInteger valueForStoreEditVC;// To Check Store Edit Or Add 0 - Edit/ 1 - Add

@property NSDictionary *dictForStoreSelected;
@property NSMutableDictionary *dictForCheckInLoctn;

@end
