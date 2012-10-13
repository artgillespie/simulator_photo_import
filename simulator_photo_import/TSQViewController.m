//
//  TSQViewController.m
//  simulator_photo_import
//
//  Created by Art Gillespie on 10/3/12.
//  Copyright (c) 2012 tapsquare, llc. All rights reserved.
//

#import "TSQViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

#import "NSFileManager+TSQFileBlocks.h"

NSString * const TSQImageImportPathKey = @"TSQImageImportPath";
NSString * const TSQTraverseSubdirectoriesKey = @"TSQTraverseSubdirectories";

@implementation TSQViewController {
    // unset this flag after importing has started to cancel importing
    BOOL _isRunning;
    __strong NSArray *_mediaExtensions;
    __strong ALAssetsLibrary *_assetsLibrary;
    dispatch_semaphore_t _wait_semaphore;
}

- (void)dealloc {
    _mediaExtensions = nil;
    _assetsLibrary = nil;
    _wait_semaphore = nil;
}

/**
 * Import a single media item. Supports files with .png, .jpg and .mov extensions.
 *
 * @param `mediaPath` - The full path to the media item.
 * @return `YES` if the image or video was saved to the simulator's photo library,
 *         `NO` if not.
 */
- (BOOL)importMediaAtPath:(NSString *)mediaPath fileManager:(NSFileManager *)fileManager {
    NSDictionary *atts = [fileManager attributesOfItemAtPath:mediaPath error:nil];
    if (nil == atts) {
        // this is bad, mmkay?
        return NO;
    }
    if (NO == [[atts objectForKey:NSFileType] isEqualToString:NSFileTypeRegular]) {
        // we're only interested in regular files
        return NO;
    }
    NSString *ext = [mediaPath pathExtension];
    if (NO == [_mediaExtensions containsObject:ext]) {
        // doesn't have an extension we're interested in
        return NO;
    }
    if (NSOrderedSame == [ext compare:@"mov" options:NSCaseInsensitiveSearch]) {
        // handle video
        [_assetsLibrary writeVideoAtPathToSavedPhotosAlbum:[NSURL fileURLWithPath:mediaPath] completionBlock:^(NSURL *assetURL, NSError *error) {
            if (nil != error) {
                [self presentError:[NSString stringWithFormat:NSLocalizedString(@"Error writing image: %@", @""), error]];
            }
            dispatch_semaphore_signal(_wait_semaphore);
        }];
        __unused long result = dispatch_semaphore_wait(_wait_semaphore, DISPATCH_TIME_FOREVER);
        return YES;
    }

    // it's an image
    UIImage *image = [UIImage imageWithContentsOfFile:mediaPath];
    if (nil == image) {
        // or, maybe... not
        return NO;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageView.image = image;
    });

    [_assetsLibrary writeImageToSavedPhotosAlbum:image.CGImage orientation:image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
        if (nil != error) {
            [self presentError:[NSString stringWithFormat:NSLocalizedString(@"Error writing image: %@", @""), error]];
        }
        dispatch_semaphore_signal(_wait_semaphore);
    }];
    __unused long result = dispatch_semaphore_wait(_wait_semaphore, DISPATCH_TIME_FOREVER);
    return YES;
}

- (void)loadImages {
    NSString *topLevelDirectory = [[[NSBundle mainBundle] infoDictionary] valueForKey:TSQImageImportPathKey];
    NSNumber *traverseSubdirs = [[[NSBundle mainBundle] infoDictionary] valueForKey:TSQTraverseSubdirectoriesKey];
    if (nil == topLevelDirectory || nil == traverseSubdirs) {
        [self presentError:NSLocalizedString(@"Make sure you've set 'TSQImageImportPath' and 'TSQTraverseSubdirectories' in Info.plist.", @"")];
        return;
    }
    if (NO == [[NSFileManager defaultManager] fileExistsAtPath:topLevelDirectory]) {
        [self presentError:[NSString stringWithFormat:NSLocalizedString(@"Can't find image import path at %@", @""), topLevelDirectory]];
        return;
    }

    NSFileManager *fileManager = [[NSFileManager alloc] init];
    _isRunning = YES;
    [fileManager TSQ_applyToItemsAtPath:topLevelDirectory itemBlock:^BOOL(NSString *path, NSUInteger idx, NSUInteger total) {
        // update the progress view and label
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.progress = (float)idx/(float)total;
            self.progressLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Importing %d of %d...", @""), idx, total];
        });
        __unused BOOL err = [self importMediaAtPath:path fileManager:fileManager];
        // if the user cancels, this flag is set to `NO` and returning `NO` here
        // will stop the enumeration...
        return _isRunning;
    } recurse:[traverseSubdirs boolValue]];
    _isRunning = NO;

    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Done!", @"")];
        self.progressView.alpha = 0.f;
        [self.startButton setTitle:NSLocalizedString(@"Start", @"") forState:UIControlStateNormal];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _mediaExtensions = @[@"png", @"PNG", @"jpg", @"JPG", @"mov", @"MOV"];
    _assetsLibrary = [[ALAssetsLibrary alloc] init];
    _wait_semaphore = dispatch_semaphore_create(0);
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
