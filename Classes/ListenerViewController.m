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

@implementation ListenerViewController

@synthesize currentPitchLabel, currentBandsLabel, listenButton, key, prevChar, isListening, rioRef;
@synthesize currentFrequency, imageView,drawMode, colorStepper, scaleSlider, textureLengthSlider, logLinMode, accelerometer;

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
    rioRef = [RIOInterface sharedInstance];
    
    currentFrame = 0;
    
    scale = 8.0;
    scaleSlider.value = 8.0;
    
    colorMode = DRAW_WHITE;
    waveDrawMode = WAVE_FLOWER;
    drawMode.selectedSegmentIndex = 2;
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

- (void)bandsChangedWithValue:(float*)newBands:(int)n
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

    for(int i = 0; i < 1024; i++) // across the columns.
    {
        float value = scale * log2(currentBands[row][i]);
        
        // determine color for drawing mode
        if( colorMode == DRAW_WHITE )
        {
            [self getPointColor:pointColor forValue:value];
            
            outputData[row][i][0] = (Byte) pointColor[0]*255;
            outputData[row][i][1] = (Byte) pointColor[1]*255;
            outputData[row][i][2] = (Byte) pointColor[2]*255;
            outputData[row][i][3] = 0xFF;

        }
        else if( colorMode == PEAK_HIGHLIGHT )
        {
            ;
            const CGFloat* colors =
                CGColorGetComponents([UIColor colorWithHue:(value + 0.5)
                                               saturation:1.0
                                               brightness:1.0
                                                    alpha:1.0].CGColor );
            
            outputData[row][i][0] = (Byte) colors[0] * 255;
            outputData[row][i][1] = (Byte) colors[1] * 255;
            outputData[row][i][2] = (Byte) colors[2] * 255;
            outputData[row][i][3] = 0xFF;
        }
        else if( colorMode == CHROMATIC_SCALE )
        {
            
            const CGFloat* colors =
            CGColorGetComponents([UIColor colorWithHue:((float)i)/1024.0
                                            saturation:value
                                             brightness:1.0
                                                  alpha:1.0].CGColor );
            outputData[row][i][0] = (Byte) colors[0] * 255;
            outputData[row][i][1] = (Byte) colors[1] * 255;
            outputData[row][i][2] = (Byte) colors[2] * 255;
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
            if( colorMode == DRAW_WHITE )
            {
                [self getPointColor:pointColor forValue:currentBands[currentFrame][i]];
                
                CGContextSetRGBStrokeColor(currentContext, pointColor[0],
                                           pointColor[1], pointColor[2], pointColor[3]);
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
        float xBegin = width/2;
        float yBegin = height/2;

        for(int i = 0; i < 1024; i++)
        {
            CGContextBeginPath(currentContext);
            
            // determine color for drawing mode
            if( colorMode == DRAW_WHITE )
            {
                [self getPointColor:pointColor forValue:currentBands[currentFrame][i]];
                
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
            
            float cosVal = cosLookup[i];
            float sinVal = sinLookup[i];
            
            float xEnd = xBegin + cosVal * val/2;
            float yEnd = yBegin + sinVal * val/2;
            CGContextMoveToPoint(currentContext, xBegin, yBegin);
            CGContextAddLineToPoint(currentContext, xEnd, yEnd);

            xEnd = xBegin - cosVal * val/2;
            yEnd = yBegin + sinVal * val/2;
            CGContextMoveToPoint(currentContext, xBegin, yBegin);
            CGContextAddLineToPoint(currentContext, xEnd, yEnd);

            xEnd = xBegin - cosVal * val/2;
            yEnd = yBegin - sinVal * val/2;
            CGContextMoveToPoint(currentContext, xBegin, yBegin);
            CGContextAddLineToPoint(currentContext, xEnd, yEnd);

            xEnd = xBegin + cosVal * val/2;
            yEnd = yBegin - sinVal * val/2;
            CGContextMoveToPoint(currentContext, xBegin, yBegin);
            CGContextAddLineToPoint(currentContext, xEnd, yEnd);

            CGContextStrokePath(currentContext);

            
        }
        
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
        
        if(self->waveDrawMode == WAVE_BLOCKS)
        {
            for(int i = lastFrame; i <= currentFrame; i++)
            {
                [self colorImageRow:i];
                if (i > textureHeight)
                    i =  i % textureHeight;
            }
            lastFrame = currentFrame;
        }
        
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
    
    UIGraphicsEndImageContext(); // Add this line.
}

-(void) getPointColor:(CGFloat*)out_color
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

-(IBAction)sliderValueChanged:(UISlider *)sender
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
    if (drawMode.selectedSegmentIndex == 0)
        waveDrawMode = WAVE_LINE;
    else if (drawMode.selectedSegmentIndex == 1)
        waveDrawMode = WAVE_TEXTURE;
    else if (drawMode.selectedSegmentIndex == 2)
        waveDrawMode = WAVE_FLOWER;
    else if (drawMode.selectedSegmentIndex == 3)
        waveDrawMode = WAVE_BLOCKS;

}

-(IBAction)logLinModeChangedAction:(id)sender
{
    if (logLinMode.selectedSegmentIndex == 0)
        yAxisScale = WAVE_LINEAR_SCALE;
    else
        yAxisScale = WAVE_LOG_SCALE;
}


-(IBAction)colorModeChangedAction:(id)sender
{
    if(colorStepper.value == 0)
        colorMode = PEAK_HIGHLIGHT;
    else if(colorStepper.value == 1)
        colorMode = CHROMATIC_SCALE;
    else if(colorStepper.value == 2)
        colorMode = DRAW_WHITE;
}


@end
