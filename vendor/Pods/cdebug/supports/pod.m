
// dummy for cocoapod

#import "debug.h"

@interface __cocoapod_cdebug: NSObject

@end

@implementation __cocoapod_cdebug

- (void)test {
    dprintf(@"Hello %@", @"World");
    dlog(1, @"Hello %@", @"World");
    dassert(true);
    dassertlog(true, @"This will now shown");
}

@end