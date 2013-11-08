//
//  FFTView.m
//  PitchDetector
//
//  Created by Lewis Hill II on 11/7/13.
//
//

#import <CoreImage/CoreImage.h>
#import "FFTView.h"
#import "ListenerViewController.h"

@implementation FFTView

@synthesize  lvc, imageView, param;


- (id)initWithCoder:(NSCoder*)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        // Do something
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

-(void)logAllFilters {
    NSArray *properties = [CIFilter filterNamesInCategory:
                           kCICategoryBuiltIn];
    NSLog(@"%@", properties);
    for (NSString *filterName in properties) {
        CIFilter *fltr = [CIFilter filterWithName:filterName];
        NSLog(@"%@", [fltr attributes]);
    }
}

-(void)setupFilter
{
    [self logAllFilters];
    
}

-(void)setImage:(UIImage*)image
{
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *ciImage = [CIImage imageWithCGImage:image.CGImage];
    CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone"];
    [filter setValue:ciImage forKey:kCIInputImageKey];
    [filter setValue:[NSNumber numberWithFloat:param] forKey:kCIInputIntensityKey];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    
    CGImageRef cgImage = [context createCGImage:result fromRect:result.extent];
    imageView.image = [UIImage imageWithCGImage:cgImage];
    
//    imageView.image = image;
}

@end
