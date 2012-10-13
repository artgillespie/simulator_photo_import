//
//  NSFileManager+TSQFileBlocks.m
//  simulator_photo_import
//
//  Created by Art Gillespie on 10/13/12.
//  Copyright (c) 2012 tapsquare, llc. All rights reserved.
//

#import "NSFileManager+TSQFileBlocks.h"

@implementation NSFileManager (TSQFileBlocks)

- (BOOL)TSQ_applyToItemsAtPath:(NSString *)fullPath itemBlock:(TSQ_filePathBlock)itemBlock recurse:(BOOL)recurse {
    NSArray *paths = nil;
    if (NO == recurse) {
        // shallow
        paths = [self contentsOfDirectoryAtPath:fullPath error:nil];
    } else {
        paths = [self subpathsAtPath:fullPath];
    }
    NSUInteger ii = 0;
    for (NSString *path in paths) {
        @autoreleasepool {
            if(NO == itemBlock([fullPath stringByAppendingPathComponent:path], ii, paths.count)) {
                break;
            }
            ++ii;
        }
    }
    return YES;
}

@end
