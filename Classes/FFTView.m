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
    
    /*
    NSMutableArray *currentValueArray = lvc.currentValueArray;

    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    
    if (lvc.waveDrawMode == WAVE_BLOCKS)
    {
        NSUInteger totalCells = currentValueArray.count;
        NSUInteger width = (int) sqrt(totalCells);
        NSUInteger height = (int) sqrt(totalCells);
        float sq_height = rect.size.height / height;
        float sq_width = rect.size.width / width;
        
        for ( NSNumber* number in currentValueArray)
        {
            NSUInteger index = [currentValueArray indexOfObject:number];
            NSUInteger i = index / width;
            NSUInteger j = index % width;
            
            float x = rect.size.width / width * i;
            float y = rect.size.height / height * j;
            
            [self setRGBAForNumber:number inContext:contextRef];

            CGRectMake( x, y, sq_width, sq_height);
            CGContextFillRect(contextRef, rect);
        }
    }
     */
    
}

-(void) setRGBAForNumber:(NSNumber*)number inContext:(CGContextRef)contextRef
{
    CGContextSetRGBFillColor(contextRef, cos(number.floatValue), sin(number.floatValue), tan(number.floatValue), 1.0 );
    CGContextSetRGBStrokeColor(contextRef, sin(number.floatValue), cos(number.floatValue), tan(number.floatValue), 1.0 );
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
