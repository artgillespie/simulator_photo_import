//
//  NSFileManager+TSQFileBlocks.h
//  simulator_photo_import
//
//  Created by Art Gillespie on 10/13/12.
//  Copyright (c) 2012 tapsquare, llc. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * return NO to stop iteration
 */

typedef BOOL (^TSQ_filePathBlock)(NSString *path, NSUInteger idx, NSUInteger total);

@interface NSFileManager (TSQFileBlocks)

- (BOOL)TSQ_applyToItemsAtPath:(NSString *)fullPath itemBlock:(TSQ_filePathBlock)itemBlock recurse:(BOOL)recurse;

@end
