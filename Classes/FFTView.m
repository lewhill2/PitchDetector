//
//  FFTView.m
//  PitchDetector
//
//  Created by Lewis Hill II on 11/7/13.
//
//

#import "FFTView.h"
#import "ListenerViewController.h"

@implementation FFTView

@synthesize  lvc, imageView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    [lvc drawRect];
}

@end
