//
//  ListenerViewController.m
//  SafeSound
//
//  Created by Demetri Miller on 10/25/10.
//  Copyright 2010 Demetri Miller. All rights reserved.
//

#import "ListenerViewController.h"
#import "RIOInterface.h"
#import "KeyHelper.h"

#define IS_IPAD	(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

@implementation ListenerViewController

@synthesize currentPitchLabel, currentBandsLabel, listenButton, pitchKey, prevChar, isListening, rioRef;
@synthesize currentFrequency, imageView, drawModeControl, colorModeControl, scaleSlider, textureLengthSlider, logLinModeControl, accelerometer, controlPanelView;

#pragma mark -
#pragma mark Listener Controls
- (IBAction)toggleListening:(id)sender {
	if (isListening) {
		[self stopListener];
		[listenButton setTitle:@"Start" forState:UIControlStateNormal];
	} else {
		[self startListener];
		[listenButton setTitle:@"Stop" forState:UIControlStateNormal];
	}
	
	isListening = !isListening;
}

- (void)startListener {
	[rioRef startListening:self];
}

- (void)stopListener {
	[rioRef stopListening];
}




#pragma mark -
#pragma mark Lifecycle
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    touchCount = 0;
    
    rioRef = [RIOInterface sharedInstance];
    
    currentFrame = 0;
    
    scale = 8.0;
    scaleSlider.value = 8.0;
    
    // init color and draw mode selector
    colorModeControl.selectedSegmentIndex = HSV_COLOR;
    colorMode = HSV_COLOR;
    drawModeControl.selectedSegmentIndex = WAVE_LINE;
    waveDrawMode = WAVE_LINE;
    
    yAxisScale = WAVE_LINEAR_SCALE;
    
    
    for(int i = 0; i < 1024; i++)
    {
        for(int j = 0; j < 1024; j++)
        {
            outputData[i][j][0] = 0x00;
            outputData[i][j][1] = 0x00;
            outputData[i][j][2] = 0x00;
            outputData[i][j][3] = 0xFF;
        }
        cosLookup[i] = cos(M_PI_2 * i/1024.0);
        sinLookup[i] = sin(M_PI_2 * i/1024.0);
    }
    
    pointColor[0] = pointColor[1] = pointColor[2] = pointColor[3] = 0.0;
    
    textureHeight = 128;
    textureLengthSlider.value = 128;
    
    // init accelerometer
    self.accelerometer = [UIAccelerometer sharedAccelerometer];
    self.accelerometer.updateInterval = .1;
    self.accelerometer.delegate = self;
    
    // add tap gesture
    imageView.userInteractionEnabled = true;
    controlPanelView.hidden = false;
    
    UITapGestureRecognizer* singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTap.numberOfTapsRequired = 1;
    singleTap.numberOfTouchesRequired = 1;
    [imageView addGestureRecognizer: singleTap];
}

-(void) handleSingleTap:(UITapGestureRecognizer *)gr {
    NSLog(@"handleSingleTap");
    controlPanelView.hidden = !controlPanelView.hidden;
}
- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    
    accel[0] = acceleration.x;
    accel[1] = acceleration.y;
    accel[2] = acceleration.z;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	currentPitchLabel = nil;
    listenButton = nil;
    [super viewDidUnload];
}

- (void)dealloc {
    
	[super dealloc];
}

#pragma mark -
#pragma mark Key Management
// This method gets called by the rendering function. Update the UI with
// the character type and store it in our string.
- (void)frequencyChangedWithValue:(float)newFrequency{
    
	self.currentFrequency = newFrequency;
    
    pitchUpdateCount++;
    if (pitchUpdateCount % 16 == 0)
        [self performSelectorInBackground:@selector(updateFrequencyLabel) withObject:nil];
    
	/*
	 * If you want to display letter values for pitches, uncomment this code and
	 * add your frequency to pitch mappings in KeyHelper.m
     
     
     KeyHelper *helper = [KeyHelper sharedInstance];
     NSString *closestChar = [helper closestCharForFrequency:newFrequency];
     
     // If the new sample has the same frequency as the last one, we should ignore
     // it. This is a pretty inefficient way of doing comparisons, but it works.
     if (![prevChar isEqualToString:closestChar]) {
     self.prevChar = closestChar;
     if ([closestChar isEqualToString:@"0"]) {
     //	[self toggleListening:nil];
     }
     [self performSelectorInBackground:@selector(updateFrequencyLabel) withObject:nil];
     NSString *appendedString = [key stringByAppendingString:closestChar];
     self.key = [NSMutableString stringWithString:appendedString];
     }
     */
	
	
}

- (void)bandsChangedWithValue:(float*)newBands numBands:(int)n;
{
    
    currentFrame++;
    currentFrame = (currentFrame % textureHeight);
    
    for ( int i = 0; i < n; i+=2 )
        currentBands[currentFrame][i/2] = newBands[i];
    
    // compute/update freq and peak every 16 frames
    if( currentFrame % 16 == 0) // compute max val infrequently
    {
        float maxValItr = 0.0;
        int maxBandItr = 0;
        
        for ( int i = 0; i < n; i+=2 )
        {
            if(currentBands[currentFrame][i/2] > maxValItr )
            {
                maxValItr = currentBands[currentFrame][i/2];
                maxBandItr = i;
            }
            self->maxBand = maxBandItr;
            self->maxPeak = maxValItr;
        }
        
        [self performSelectorInBackground:@selector(updateBandsLabel) withObject:nil];
    }
    
    // draw the image every other frame
    if( currentFrame % 2 == 0) // compute max val and image infrequently
    {
        [self performSelectorInBackground:@selector(drawRect) withObject:nil];
    }
}

// this fills in the pixels across one row (timepoint) of the data.
-(void) colorImageRow:(int)row
{
    assert(row < 1024);
    
    const CGFloat* colors;
    float value;
    
    
    for(int i = 0; i < 1024; i++) // across the columns.
    {
        value = scale * currentBands[row][i];
        
        // determine color for drawing mode
        if( colorMode == HSV_COLOR )
        {
            [self getPointColor:pointColor forValue:value*scale];
            outputData[row][i][0] = (int) (pointColor[0]*255.0);
            outputData[row][i][1] = (int) (pointColor[1]*255.0);
            outputData[row][i][2] = (int) (pointColor[2]*255.0);
            outputData[row][i][3] = 0xFF;
        }
        else if( colorMode == DISCRETE_SCALE )
        {
            [self getPointColorDiscrete:pointColor forValue:value*scale];
            outputData[row][i][0] = (int) (pointColor[0]*255.0);
            outputData[row][i][1] = (int) (pointColor[1]*255.0);
            outputData[row][i][2] = (int) (pointColor[2]*255.0);
            outputData[row][i][3] = 0xFF;
        }
        else if( colorMode == GREY_SCALE )
        {
            outputData[row][i][0] = (int) (scale * value * 255.0);
            outputData[row][i][1] = (int) (scale * value * 255.0);
            outputData[row][i][2] = (int) (scale * value * 255.0);
            outputData[row][i][3] = 0xFF;
            
        }
        else if( colorMode == PEAK_HIGHLIGHT )
        {
            colors = CGColorGetComponents([UIColor colorWithHue:value*scale
                                                     saturation:1.0
                                                     brightness:1.0
                                                          alpha:1.0].CGColor );
            
            outputData[row][i][0] = (int) ((1.0 - colors[0]) * 255.0);
            outputData[row][i][1] = (int) ((1.0 - colors[1]) * 255.0);
            outputData[row][i][2] = (int) ((1.0 - colors[2]) * 255.0);
            outputData[row][i][3] = 0xFF;
        }
        else if( colorMode == CHROMATIC_SCALE )
        {
            
            colors = CGColorGetComponents([UIColor colorWithHue:((float)i)/1024.0
                                                     saturation:value*scale
                                                     brightness:1.0
                                                          alpha:1.0].CGColor );
            outputData[row][i][0] = (int) (colors[0] * 255.0);
            outputData[row][i][1] = (int) (colors[1] * 255.0);
            outputData[row][i][2] = (int) (colors[2] * 255.0);
            outputData[row][i][3] = 0xFF;
            
        }
    }
}

- (void)updateFrequencyLabel {
	[self.currentPitchLabel setText:[NSString stringWithFormat:@"%.2f", self.currentFrequency]];
}

- (void)updateBandsLabel {
    [self.currentBandsLabel setText:[NSString stringWithFormat:@"peak %3.2f (%d)", self->maxPeak, self->maxBand]];
}

- (void)drawRect
{
    
    UIGraphicsBeginImageContext(imageView.frame.size);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    
    // fill the background of the square with grey
    CGContextSetRGBFillColor(currentContext, accel[0], accel[1], accel[2],1.0);
    CGContextFillRect(currentContext, imageView.frame);
    
    //  draw multi touches
    CGContextSetRGBFillColor(currentContext, 255, 0, 255, 0.9);
    CGContextSetRGBStrokeColor(currentContext, 255, 0, 0, 0.9);
    
    // draw the dots
    for(int i = 0; i < touchCount; i++)
    {
        CGRect ellipseRect = CGRectMake(touchPoints[i].x, touchPoints[i].y, 40, 40);
        CGContextFillEllipseInRect(currentContext, ellipseRect);
    }
    
    // calculate midpoint of touches
    float xSum = 0;
    float ySum = 0;
    for(int i = 0; i < touchCount; i++)
    {
        xSum += touchPoints[i].x;
        ySum += touchPoints[i].y;
    }
    float xAvg = xSum / touchCount;
    float yAvg = ySum / touchCount;
    
    // connect the dots
    if(touchCount > 0)
    {
        CGContextBeginPath(currentContext);
        for(int i = 0; i < touchCount; i++)
        {
            CGContextMoveToPoint(currentContext, xAvg, yAvg);
            CGContextAddLineToPoint(currentContext, touchPoints[i].x, touchPoints[i].y);
        }
        CGContextClosePath(currentContext);
        CGContextStrokePath(currentContext);
    }
    
    // flip the image
    CGAffineTransform flipVertical =
    CGAffineTransformMake(1, 0, 0, -1, 0, imageView.image.size.height);
    CGContextConcatCTM(currentContext, flipVertical);
    
    float width = imageView.frame.size.width;
    float height = imageView.frame.size.height;
    
    if( waveDrawMode == WAVE_LINE )
    {
        
        float width_convert = width / 1024;
        float val = 0.0;
        
        for(int i = 0; i < 1024; i++)
        {
            CGContextBeginPath(currentContext);
            
            // determine color for drawing mode
            if( colorMode == HSV_COLOR )
            {
                [self getPointColor:pointColor forValue:currentBands[currentFrame][i]];
                CGContextSetRGBStrokeColor(currentContext, pointColor[0],
                                           pointColor[1], pointColor[2], pointColor[3]);
            }
            else if( colorMode == DISCRETE_SCALE )
            {
                [self getPointColorDiscrete:pointColor forValue:currentBands[currentFrame][i]];
                CGContextSetRGBStrokeColor(currentContext, pointColor[0],
                                           pointColor[1], pointColor[2], pointColor[3]);
            }
            else if( colorMode == GREY_SCALE )
            {
                float val = scale * currentBands[currentFrame][i] * 255.0;
                CGContextSetRGBStrokeColor(currentContext, val, val, val, 1.0);
            }
            else if( colorMode == PEAK_HIGHLIGHT )
            {
                CGContextSetStrokeColorWithColor(
                                                 currentContext,
                                                 [UIColor colorWithHue:currentBands[currentFrame][i]/(maxPeak + 0.5)
                                                            saturation:1.0
                                                            brightness:1.0
                                                                 alpha:1.0].CGColor);
            }
            else if( colorMode == CHROMATIC_SCALE )
            {
                CGContextSetStrokeColorWithColor(
                                                 currentContext,
                                                 [UIColor colorWithHue:((float)i)/1024.0
                                                            saturation:1.0
                                                            brightness:1.0
                                                                 alpha:1.0].CGColor);
            }
            
            if(yAxisScale == WAVE_LOG_SCALE)
                val = scale * log2(currentBands[currentFrame][i]);
            else if(yAxisScale == WAVE_LINEAR_SCALE)
                val = scale * currentBands[currentFrame][i];
            
            float xPos = i * width_convert;
            
            // draw this line segment
            CGContextMoveToPoint(currentContext, xPos, 0.0f);
            CGContextAddLineToPoint(currentContext, xPos, val);
            CGContextStrokePath(currentContext);
        }
        
        UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
        [imageView performSelectorOnMainThread:@selector(setImage:) withObject:newImage waitUntilDone:NO];
    }
    
    if( waveDrawMode == WAVE_FLOWER)
    {
        float val = 0.0;
        float x1, y1, x2, y2, x3, y3, x4, y4;
        float cosVal;
        float sinVal;

        
        for(int i = 0; i < 1024; i++)
        {
            CGContextBeginPath(currentContext);
            
            // determine color for drawing mode
            if( colorMode == HSV_COLOR )
            {
                [self getPointColor:pointColor forValue:currentBands[currentFrame][i]];
                CGContextSetRGBStrokeColor(currentContext, pointColor[0],pointColor[1], pointColor[2], pointColor[3]);
            }
            else if( colorMode == GREY_SCALE )
            {
                float val = scale * currentBands[currentFrame][i] * 255.0;
                CGContextSetRGBStrokeColor(currentContext, val, val, val, 1.0);
            }
            else if( colorMode == DISCRETE_SCALE )
            {
                [self getPointColorDiscrete:pointColor forValue:currentBands[currentFrame][i]];
                CGContextSetRGBStrokeColor(currentContext, pointColor[0],pointColor[1], pointColor[2], pointColor[3]);
            }
            else if( colorMode == PEAK_HIGHLIGHT )
            {
                CGContextSetStrokeColorWithColor(currentContext,
                                                 [UIColor colorWithHue:currentBands[currentFrame][i]/(maxPeak + 0.5)
                                                            saturation:1.0
                                                            brightness:1.0
                                                                 alpha:1.0].CGColor);
            }
            else if( colorMode == CHROMATIC_SCALE )
            {
                CGContextSetStrokeColorWithColor(currentContext,
                                                 [UIColor colorWithHue:(float)i/1024.0
                                                            saturation:1.0
                                                            brightness:1.0
                                                                 alpha:1.0].CGColor);
            }
            
            if(yAxisScale == WAVE_LOG_SCALE)
                val = scale * log2(currentBands[currentFrame][i]);
            else if(yAxisScale == WAVE_LINEAR_SCALE)
                val = scale * currentBands[currentFrame][i];
            
            cosVal = cosLookup[i];
            sinVal = sinLookup[i];
            
            x1 = width/2 + cosVal * val/2;
            y1 = height/2 + sinVal * val/2;
            x2 = width/2 - cosVal * val/2;
            y2 = height/2 - sinVal * val/2;
            x3 = width/2 + cosVal * val/2;
            y3 = height/2 - sinVal * val/2;
            x4 = width/2 - cosVal * val/2;
            y4 = height/2 + sinVal * val/2;
            
            CGContextMoveToPoint(currentContext, x1, y1);
            CGContextAddLineToPoint(currentContext, x2, y2);
            CGContextMoveToPoint(currentContext, x3, y3);
            CGContextAddLineToPoint(currentContext, x4, y4);

            CGContextStrokePath(currentContext);
        }
        
        // save image
        UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
        [imageView performSelectorOnMainThread:@selector(setImage:) withObject:newImage waitUntilDone:NO];
        
    }
    
    if(waveDrawMode == WAVE_TEXTURE)
    {
        if(self->waveDrawMode == WAVE_TEXTURE)
        {
            for(int i = lastFrame; i <= currentFrame; i++)
            {
                [self colorImageRow:i];
                if (i > textureHeight)
                    i =  i % textureHeight;
            }
            lastFrame = currentFrame;
        }
        
        const int w = 1024;
        const int h = textureHeight;
        CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
        CGContextRef bitmapContext=CGBitmapContextCreate(outputData, w, h, 8, 4*w, colorSpace,  kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
        CFRelease(colorSpace);
        CGImageRef cgImage=CGBitmapContextCreateImage(bitmapContext);
        CGContextRelease(bitmapContext);
        
        UIImage * newImage = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
        
        [imageView performSelectorOnMainThread:@selector(setImage:) withObject:newImage waitUntilDone:NO];
        
    }
    
    if(waveDrawMode == WAVE_BLOCKS)
    {
        
        [self colorImageRow:currentFrame];
        
        const int w = 32;
        const int h = 32;
        
        CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
        CGContextRef bitmapContext=CGBitmapContextCreate(outputData[currentFrame], w, h, 8, 4*w, colorSpace,  kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
        CFRelease(colorSpace);
        CGImageRef cgImage=CGBitmapContextCreateImage(bitmapContext);
        CGContextRelease(bitmapContext);
        
        UIImage * newImage = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
        
        [imageView performSelectorOnMainThread:@selector(setImage:) withObject:newImage waitUntilDone:NO];
        
    }

    if(waveDrawMode == WAVE_WALL)
    {
        
        [self colorImageRow:currentFrame];
        
        const int w = 1;
        const int h = 1024;
        
        CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
        CGContextRef bitmapContext=CGBitmapContextCreate(outputData[currentFrame], w, h, 8, 4*w, colorSpace,  kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
        CFRelease(colorSpace);
        CGImageRef cgImage=CGBitmapContextCreateImage(bitmapContext);
        CGContextRelease(bitmapContext);
        
        UIImage * newImage = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
        
        [imageView performSelectorOnMainThread:@selector(setImage:) withObject:newImage waitUntilDone:NO];
        
    }
    
    
    
    
    UIGraphicsEndImageContext(); // Add this line.
}

-(void) getPointColorDiscrete:(CGFloat*)out_color
                     forValue:(float)voltage
{
    
    if(voltage > 150)
    {
        out_color[0] = 1.0;
        out_color[1] = 0.2;
        out_color[2] = 0.2;
        out_color[3] = 1.0;
    }
    else if(voltage > 50)
    {
        out_color[0] = 0.3;
        out_color[1] = 1.0;
        out_color[2] = 0.2;
        out_color[3] = 1.0;
    }
    else if(voltage > 10)
    {
        out_color[0] = 0.3;
        out_color[1] = 0.15;
        out_color[2] = 1.0;
        out_color[3] = 1.0;
    }
    else if(voltage > 0)
    {
        out_color[0] = 0.1;
        out_color[1] = 0.0;
        out_color[2] = 0.8;
        out_color[3] = 1.0;
    }
}

-(void) getPointColor:(CGFloat*)out_color
             forValue:(float)voltage
{
    HSV value;
    value.h = voltage;
    value.s = 1.0;
    value.v = 1.0;
    
    RGBA rgba = [self RGBfromHSV:value];
    
    out_color[0] = rgba.r;
    out_color[1] = rgba.g;
    out_color[2] = rgba.b;
}

- (RGBA)RGBfromHSV:(HSV)value
{
    double      hh, p, q, t, ff;
    long        i;
    RGBA        out;
    out.a       = 1;
    
    if (value.s <= 0.0) // < is bogus, just shuts up warnings
    {
        if (isnan(value.h)) // value.h == NAN
        {
            out.r = value.v;
            out.g = value.v;
            out.b = value.v;
            return out;
        }
        
        // error - should never happen
        out.r = 0.0;
        out.g = 0.0;
        out.b = 0.0;
        return out;
    }
    
    hh = value.h;
    if(hh >= 360.0) hh = 0.0;
    hh /= 60.0;
    i = (long)hh;
    ff = hh - i;
    p = value.v * (1.0 - value.s);
    q = value.v * (1.0 - (value.s * ff));
    t = value.v * (1.0 - (value.s * (1.0 - ff)));
    
    switch(i)
    {
        case 0:
            out.r = value.v;
            out.g = t;
            out.b = p;
            break;
        case 1:
            out.r = q;
            out.g = value.v;
            out.b = p;
            break;
        case 2:
            out.r = p;
            out.g = value.v;
            out.b = t;
            break;
            
        case 3:
            out.r = p;
            out.g = q;
            out.b = value.v;
            break;
        case 4:
            out.r = t;
            out.g = p;
            out.b = value.v;
            break;
        case 5:
        default:
            out.r = value.v;
            out.g = p;
            out.b = q;
            break;
    }
    return out;
}

-(IBAction)scaleValueChanged:(UISlider *)sender
{
    scale = sender.value;
    [self.currentBandsLabel performSelectorOnMainThread:@selector(setText:)
                                             withObject:[NSString stringWithFormat:@"Scale = %.2f", scale]
                                          waitUntilDone:NO];
}

-(IBAction)textureLengthValueChanged:(UISlider *)sender
{
    textureHeight = sender.value;
    if(textureHeight < 0)
        textureHeight = 4;
    [self.currentBandsLabel performSelectorOnMainThread:@selector(setText:)
                                             withObject:[NSString stringWithFormat:@"TextureLength = %d", textureHeight]
                                          waitUntilDone:NO];
}

- (IBAction)drawModeChangedAction:(id)sender
{
    if (drawModeControl.selectedSegmentIndex == 0)
        waveDrawMode = WAVE_LINE;
    else if (drawModeControl.selectedSegmentIndex == 1)
        waveDrawMode = WAVE_TEXTURE;
    else if (drawModeControl.selectedSegmentIndex == 2)
        waveDrawMode = WAVE_FLOWER;
    else if (drawModeControl.selectedSegmentIndex == 3)
        waveDrawMode = WAVE_BLOCKS;
    else if (drawModeControl.selectedSegmentIndex == 4)
        waveDrawMode = WAVE_WALL;
    
}

-(IBAction)logLinModeControlChangedAction:(id)sender
{
    if (logLinModeControl.selectedSegmentIndex == 0)
        yAxisScale = WAVE_LINEAR_SCALE;
    else
        yAxisScale = WAVE_LOG_SCALE;
}


-(IBAction)colorModeChangedAction:(id)sender
{
    if(colorModeControl.selectedSegmentIndex == 0)
        colorMode = PEAK_HIGHLIGHT;
    
    else if(colorModeControl.selectedSegmentIndex == 1)
        colorMode = CHROMATIC_SCALE;
    
    else if(colorModeControl.selectedSegmentIndex == 2)
        colorMode = HSV_COLOR;
    
    else if(colorModeControl.selectedSegmentIndex == 3)
        colorMode = DISCRETE_SCALE;
    
    else if(colorModeControl.selectedSegmentIndex == 4)
        colorMode = GREY_SCALE;

}

-(void) printTouches
{
    for(int i = 0; i < touchCount; i++)
        NSLog(@"Touch %i = %f, %f",i, touchPoints[i].x, touchPoints[i].y);
}

- (void) touchesBegan:(NSSet *) touches withEvent:(UIEvent *) event
{
    int count = 0;
	for (UITouch *touch in touches)
	{
		CGPoint pt = [touch locationInView:imageView];
        touchPoints[count] = pt;
        count++;
	}
    touchCount = [touches count];
}

- (void) touchesMoved:(NSSet *) touches withEvent:(UIEvent *) event
{
    int count = 0;
    for (UITouch *touch in touches)
    {
        CGPoint pt = [touch locationInView:imageView];
        touchPoints[count] = pt;
        count++;
    }
    touchCount = [touches count];
    
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    int count = 0;
    for (UITouch *touch in touches)
    {
        CGPoint pt = [touch locationInView:imageView];
        touchPoints[count] = pt;
        count++;
    }
    touchCount = [touches count];
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self touchesEnded:touches withEvent:event];
    touchCount = 0;
}

@end
