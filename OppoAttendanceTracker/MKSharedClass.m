//
//  MKSharedClass.m
//  OppoAttendanceTracker
//
//  Created by User1 on 12/22/16.
//
//

#import "MKSharedClass.h"

@implementation MKSharedClass

@synthesize valueForStoreEditVC;
@synthesize dictForStoreSelected;
@synthesize dictForCheckInLoctn;


static MKSharedClass *instance = nil;

+(MKSharedClass *)shareManager
{
    @synchronized(self)
    {
        if(instance==nil)
        {
            instance= [MKSharedClass new];
        }
    }
    return instance;
}
@end
