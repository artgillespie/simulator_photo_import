//
//  TSQViewController.m
//  simulator_photo_import
//
//  Created by Art Gillespie on 10/3/12.
//  Copyright (c) 2012 tapsquare, llc. All rights reserved.
//

#import "TSQViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

#define PHOTO_DIRECTORY @"/Users/artgillespie/Pictures/iPhoto Library/Masters"

BOOL const TRAVERSE_SUBDIRECTORIES = YES;

@interface TSQViewController ()

@end

@implementation TSQViewController

- (void)loadImagesInDirectoryAtPath:(NSString *)directoryPath {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *imageExtensions = @[@"png", @"PNG", @"jpg", @"JPG"];
    NSError *error = nil;
    NSArray *entries = [fileManager contentsOfDirectoryAtPath:directoryPath error:&error];
    if (nil == entries) {
        NSAssert(@"Couldn't get contents of path (%@) Error: %@", directoryPath, error);
    }
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    int current = 0;
    dispatch_semaphore_t wait_semaphore = dispatch_semaphore_create(0);
    for (NSString *path in entries) {
        @autoreleasepool {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.progressView.progress = (float)current/(float)entries.count;
                self.progressLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Importing %d of %d...", @""), current, entries.count];
            });
            ++current;
            NSString *fullPath = [directoryPath stringByAppendingPathComponent:path];
            NSDictionary *atts = [fileManager attributesOfItemAtPath:fullPath error:nil];
            if (nil == atts) {
                // this is bad, mmkay?
                continue;
            }
            if (NO == [[atts objectForKey:NSFileType] isEqualToString:NSFileTypeRegular]) {
                // we're only interested in regular files
                continue;
            }
            NSString *ext = [fullPath pathExtension];
            if (NO == [imageExtensions containsObject:ext]) {
                // doesn't have an extension we're interested in
                continue;
            }
            // okay, it's an image
            UIImage *image = [UIImage imageWithContentsOfFile:fullPath];
            if (nil == image) {
                NSLog(@"File at path %@ return nil image...", fullPath);
                // or, maybe... not
                continue;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = image;
            });

            [library writeImageToSavedPhotosAlbum:image.CGImage orientation:image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
                if (nil != error) {
                    NSLog(@"error writing image: %@", error);
                }
                dispatch_semaphore_signal(wait_semaphore);
            }];
            long result = dispatch_semaphore_wait(wait_semaphore, DISPATCH_TIME_FOREVER);
            if (0 != result) {
                NSLog(@"Timed out waiting for library to write...");
            }
        } // autoreleasepool
    } // for (NSString *path in entries)
}

- (void)loadImages {
    NSString *topLevelDirectory = PHOTO_DIRECTORY;
    [self loadImagesInDirectoryAtPath:topLevelDirectory];
    if (YES == TRAVERSE_SUBDIRECTORIES) {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSError *error = nil;
        NSArray *subDirs = [fileManager subpathsOfDirectoryAtPath:topLevelDirectory error:&error];
        for (NSString *subDir in subDirs) {
            [self loadImagesInDirectoryAtPath:[topLevelDirectory stringByAppendingPathComponent:subDir]];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Done!", @"")];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self loadImages];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
