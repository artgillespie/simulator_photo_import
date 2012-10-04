//
//  TSQViewController.h
//  simulator_photo_import
//
//  Created by Art Gillespie on 10/3/12.
//  Copyright (c) 2012 tapsquare, llc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TSQViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) IBOutlet UILabel *progressLabel;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;

@end
