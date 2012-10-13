//
//  TSQViewController.m
//  simulator_photo_import
//
//  Created by Art Gillespie on 10/3/12.
//  Copyright (c) 2012 tapsquare, llc. All rights reserved.
//

#import "TSQViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

NSString * const TSQImageImportPathKey = @"TSQImageImportPath";
NSString * const TSQTraverseSubdirectoriesKey = @"TSQTraverseSubdirectories";

@implementation TSQViewController {
    // unset this flag after importing has started to cancel importing
    BOOL _isRunning;
}

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
                // or, maybe... not
                continue;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = image;
            });

            [library writeImageToSavedPhotosAlbum:image.CGImage orientation:image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
                if (nil != error) {
                    [self presentError:[NSString stringWithFormat:NSLocalizedString(@"Error writing image: %@", @""), error]];
                }
                dispatch_semaphore_signal(wait_semaphore);
            }];
            __unused long result = dispatch_semaphore_wait(wait_semaphore, DISPATCH_TIME_FOREVER);
            if (NO == _isRunning) {
                break;
            }
        } // autoreleasepool
    } // for (NSString *path in entries)
}

- (void)loadImages {
    NSString *topLevelDirectory = [[[NSBundle mainBundle] infoDictionary] valueForKey:TSQImageImportPathKey];
    NSNumber *traverseSubdirs = [[[NSBundle mainBundle] infoDictionary] valueForKey:TSQTraverseSubdirectoriesKey];
    if (nil == topLevelDirectory || nil == traverseSubdirs) {
        [self presentError:NSLocalizedString(@"Make sure you've set 'TSQImageImportPath' and 'TSQTraverseSubdirectories' in Info.plist and try again", @"")];
        return;
    }
    if (NO == [[NSFileManager defaultManager] fileExistsAtPath:topLevelDirectory]) {
        [self presentError:[NSString stringWithFormat:NSLocalizedString(@"Can't find image import path at %@", @""), topLevelDirectory]];
        return;
    }
    [self loadImagesInDirectoryAtPath:topLevelDirectory];
    if (YES == [traverseSubdirs boolValue]) {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSError *error = nil;
        NSArray *subDirs = [fileManager subpathsOfDirectoryAtPath:topLevelDirectory error:&error];
        for (NSString *subDir in subDirs) {
            [self loadImagesInDirectoryAtPath:[topLevelDirectory stringByAppendingPathComponent:subDir]];
            if (NO == _isRunning) {
                break;
            }
        }
    }
    _isRunning = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Done!", @"")];
        self.progressView.alpha = 0.f;
        [self.startButton setTitle:NSLocalizedString(@"Start", @"") forState:UIControlStateNormal];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.progressLabel.text = @"";
    self.progressView.progress = 0.f;
    self.progressView.alpha = 0.f;
    _isRunning = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction)startButton:(id)sender {
    if (NO == _isRunning) {
        [self.startButton setTitle:NSLocalizedString(@"Stop", @"") forState:UIControlStateNormal];
        _isRunning = YES;
        self.progressView.alpha = 1.f;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self loadImages];
        });
    } else {
        _isRunning = NO;
        self.progressView.alpha = 0.f;
        self.progressLabel.text = @"";
        [self.startButton setTitle:NSLocalizedString(@"Start", @"") forState:UIControlStateNormal];
    }
}

- (void)presentError:(NSString *)msg {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
                                                    message:msg
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                          otherButtonTitles:nil];

    if (YES == [NSThread isMainThread]) {
        [alert show];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert show];
        });
    }
}
@end
