//
//  FFTImageView.h
//  PitchDetector
//
//  Created by Lewis Hill II on 11/7/13.
//
//

#import <UIKit/UIKit.h>
#import "ListenerViewController.h"
#import "ScreenCaptureView.h"

@interface FFTView : ScreenCaptureView
@property (nonatomic, retain) IBOutlet ListenerViewController *lvc;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;

- (void)drawRect:(CGRect)rect;

@end
