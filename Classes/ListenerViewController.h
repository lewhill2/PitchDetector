//
//  ListenerViewController.h
//  SafeSound
//
//  Created by Demetri Miller on 10/25/10.
//  Copyright 2010 Demetri Miller. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RIOInterface;

typedef enum {
    PEAK_HIGHLIGHT = 0,
    CHROMATIC_SCALE = 1,
    DRAW_WHITE = 2
} ColorMode;

typedef enum {
    WAVE_LINE = 0,
    WAVE_TEXTURE = 1,
    WAVE_FLOWER = 2
} WaveDrawMode;


typedef enum {
    WAVE_LINEAR_SCALE = 0,
    WAVE_LOG_SCALE = 1
} WaveAxisScale;

@interface ListenerViewController : UIViewController {
    
    UILabel *currentPitchLabel;
	UILabel *currentBandsLabel;
	UIButton *listenButton;
	UIImageView* imageView;
    
	BOOL isListening;
	RIOInterface *rioRef;
	
	NSMutableString *key;
	float currentFrequency;
    float maxPeak;
    int maxBand;
    int currentFrame;
    int lastFrame;
	NSString *prevChar;
    float scale;
    int textureHeight;
    int pitchUpdateCount;
    
    float currentBands[1024][1024];
    Byte outputData[1024][1024][4];
    CGFloat pointColor[4];
    
    float cosLookup[1024];
    float sinLookup[1024];
    
    WaveDrawMode waveDrawMode;
    ColorMode colorMode;
    WaveAxisScale yAxisScale;
}

@property(nonatomic, retain) IBOutlet UILabel *currentPitchLabel;
@property(nonatomic, retain) IBOutlet UILabel *currentBandsLabel;
@property(nonatomic, retain) IBOutlet UIButton *listenButton;
@property(nonatomic, retain) IBOutlet UISlider *scaleSlider;
@property(nonatomic, retain) IBOutlet UISlider *textureLengthSlider;
@property(nonatomic, retain) IBOutlet UIStepper *colorStepper;
@property(nonatomic, retain) IBOutlet UISegmentedControl *drawMode;
@property(nonatomic, retain) IBOutlet UISegmentedControl *logLinMode;

@property(nonatomic, retain) NSMutableString *key;
@property(nonatomic, retain) NSString *prevChar;
@property(nonatomic, assign) RIOInterface *rioRef;
@property(nonatomic, assign) float currentFrequency;
@property(nonatomic, assign) IBOutlet UIImageView* imageView;
@property(assign) BOOL isListening;


#pragma mark Listener Controls
- (IBAction)toggleListening:(id)sender;
- (void)startListener;
- (void)stopListener;
-(IBAction)sliderValueChanged:(UISlider *)sender;
-(IBAction)textureLengthValueChanged:(UISlider *)sender;
-(IBAction)drawModeChangedAction:(id)sender;
-(IBAction)logLinModeChangedAction:(id)sender;
-(IBAction)colorModeChangedAction:(id)sender;

- (void)frequencyChangedWithValue:(float)newFrequency;
- (void)bandsChangedWithValue:(float*)newBands:(int)n;
- (void)updateFrequencyLabel;
- (void)drawRect;
- (void)getPointColor:(CGFloat*)out_color
             forValue:(float)voltage;

-(void) colorImageRow:(int)row;

@end
