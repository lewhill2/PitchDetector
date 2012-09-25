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

@synthesize currentPitchLabel;
@synthesize currentBandsLabel;
@synthesize listenButton;
@synthesize key;
@synthesize prevChar;
@synthesize isListening;
@synthesize	rioRef;
@synthesize currentFrequency;
@synthesize imageView;

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
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	self.currentFrequency = newFrequency;
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
	
	[pool drain];
	pool = nil;
	
}

- (void)bandsChangedWithValue:(float*)newBands:(int)n
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    float maxValItr = 0.0;
    int maxBandItr = 0;
    
    for ( int i = 0; i < n; i+=2 )
    {
        currentBands[currentFrame][i/2] = newBands[i];

        if(currentBands[currentFrame][i/2] > maxValItr )
        {
            maxValItr = currentBands[currentFrame][i/2];
            maxBandItr = i;
        }
    }
    self->maxBand = maxBandItr;
    self->maxPeak = maxValItr;
    currentFrame = (currentFrame++) % 1024;
    
	[self performSelectorInBackground:@selector(updateBandsLabel) withObject:nil];
	[self performSelectorInBackground:@selector(drawRect) withObject:nil];
	[pool drain];
	pool = nil;
    
}
		 
- (void)updateFrequencyLabel {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	self.currentPitchLabel.text = [NSString stringWithFormat:@"%f", self.currentFrequency];
	[self.currentPitchLabel setNeedsDisplay];
	[pool drain];
	pool = nil;
}

- (void)updateBandsLabel {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	self.currentBandsLabel.text = [NSString stringWithFormat:@"maxPeak = %f maxBand = %d", self->maxPeak, self->maxBand];
	[self.currentBandsLabel setNeedsDisplay];
	[pool drain];
	pool = nil;
}

- (void)drawRect
{
    
    UIGraphicsBeginImageContext(imageView.image.size);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    
    // fill the background of the square with grey
    CGContextSetRGBFillColor(currentContext, 0.5,0.5,0.5,1.0);
    //CGContextFillRect(currentContext, imageView.image.size);
    
    CGAffineTransform flipVertical =
        CGAffineTransformMake(1, 0, 0, -1, 0, imageView.image.size.height);
    CGContextConcatCTM(currentContext, flipVertical);

    float width = imageView.image.size.width;
    float width_convert = width / 1024;    
    
    for(int i = 0; i < 1024; i++)
    {
        CGContextBeginPath(currentContext);
        
        CGFloat pointColor[] = { 1.0f, 1.0f, 1.0f, 1.0f };
        
        [self getPointColor:pointColor forValue:currentBands[currentFrame][i]];
        
        bool drawWhite = YES;
        if(drawWhite == YES)
            CGContextSetRGBStrokeColor(currentContext, pointColor[0],
                                       pointColor[1], pointColor[2], pointColor[3]);
        else
        {
            CGFloat shiftedColor[] = { 1.0f, 1.0f, 1.0f, 1.0f };

            [self transformColor:pointColor
                         toColor:shiftedColor
                             byH:currentBands[currentFrame][i]/self->maxPeak];
            
            CGContextSetStrokeColor(currentContext, shiftedColor);

             NSLog(@"%f, %f, %f, %f/n",shiftedColor[0], shiftedColor[1], shiftedColor[2], shiftedColor[3]);
        }
        CGContextMoveToPoint(currentContext, i * width_convert, 0.0f);
        CGContextAddLineToPoint(currentContext, i * width_convert, currentBands[currentFrame][i] );
        CGContextStrokePath(currentContext);

    }
    
    imageView.image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext(); // Add this line.
}

-(void) getPointColor:(CGFloat*)out_color
          forValue:(float)voltage
{
    if(voltage > 100)
    {
        out_color[0] = 1.0;
        out_color[1] = 0.2;
        out_color[2] = 0.5;
        out_color[3] = 1.0;
    }
    else if(voltage > 50)
    {
        out_color[0] = 0.3;
        out_color[1] = 1.0;
        out_color[2] = 0.2;
        out_color[3] = 1.0;
    }
    else if(voltage > 0)
    {
        out_color[0] = 0.2;
        out_color[1] = 0.1;
        out_color[2] = 1.0;
        out_color[3] = 1.0;
    }
    
}

-(void) transformColor:(CGFloat[])in_color
               toColor:(CGFloat[])out_color
                   byH:(float)H
{
    float U = cos(H*M_PI/180);
    float W = sin(H*M_PI/180);
    
    out_color[0] = (.701*U+.168*W)*in_color[0]
    + (-.587*U+.330*W)*in_color[1]
    + (-.114*U-.497*W)*in_color[2];

    out_color[1] = (-.299*U-.328*W)*in_color[0]
    + (.413*U+.035*W)*in_color[1]
    + (-.114*U+.292*W)*in_color[2];
    
    out_color[2] = (-.3*U+1.25*W)*in_color[0]
    + (-.588*U-1.05*W)*in_color[1]
    + (.886*U-.203*W)*in_color[2];
    
    out_color[3] = in_color[3];
}



@end
