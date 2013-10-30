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
    HSV_COLOR = 2,
    DISCRETE_SCALE = 3,
    GREY_SCALE = 4
} ColorMode;

typedef enum {
    WAVE_LINE = 0,
    WAVE_TEXTURE = 1,
    WAVE_FLOWER = 2,
    WAVE_BLOCKS = 3,
    WAVE_WALL = 4
} WaveDrawMode;


typedef enum {
    WAVE_LINEAR_SCALE = 0,
    WAVE_LOG_SCALE = 1
} WaveAxisScale;


typedef struct
{
    double r;       // percent [0 - 1]
    double g;       // percent [0 - 1]
    double b;       // percent [0 - 1]
    double a;       // percent [0 - 1]
} RGBA;

typedef struct
{
    double h;       // angle in degrees [0 - 360]
    double s;       // percent [0 - 1]
    double v;       // percent [0 - 1]
} HSV;

@interface ListenerViewController : UIViewController  <UIAccelerometerDelegate> {
    
    UILabel *currentPitchLabel;
	UILabel *currentBandsLabel;
	UIButton *listenButton;
	UIImageView* imageView;
    
	BOOL isListening;
	RIOInterface *rioRef;
	
	NSMutableString *pitchKey;
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
    
    float accel[3];
    
    WaveDrawMode waveDrawMode;
    ColorMode colorMode;
    WaveAxisScale yAxisScale;
    
    CGPoint touchPoints[20];
    int touchCount;
}

@property(nonatomic, retain) IBOutlet UIView *controlPanelView;

@property(nonatomic, retain) IBOutlet UILabel *currentPitchLabel;
@property(nonatomic, retain) IBOutlet UILabel *currentBandsLabel;
@property(nonatomic, retain) IBOutlet UIButton *listenButton;
@property(nonatomic, retain) IBOutlet UISlider *scaleSlider;
@property(nonatomic, retain) IBOutlet UISlider *textureLengthSlider;
@property(nonatomic, retain) IBOutlet UISegmentedControl *drawModeControl;
@property(nonatomic, retain) IBOutlet UISegmentedControl *logLinModeControl;
@property(nonatomic, retain) IBOutlet UISegmentedControl *colorModeControl;

@property(nonatomic, retain) NSMutableString *pitchKey;
@property(nonatomic, retain) NSString *prevChar;
@property(nonatomic, assign) RIOInterface *rioRef;
@property(nonatomic, assign) float currentFrequency;
@property(nonatomic, assign) IBOutlet UIImageView* imageView;
@property(assign) BOOL isListening;

@property (nonatomic, retain) UIAccelerometer *accelerometer;



#pragma mark Listener Controls
- (IBAction)toggleListening:(id)sender;
- (void)startListener;
- (void)stopListener;
-(IBAction)scaleValueChanged:(UISlider *)sender;
-(IBAction)textureLengthValueChanged:(UISlider *)sender;
-(IBAction)drawModeChangedAction:(id)sender;
-(IBAction)logLinModeControlChangedAction:(id)sender;
-(IBAction)colorModeChangedAction:(id)sender;
-(void) handleSingleTap:(UITapGestureRecognizer *)gr;

- (void)frequencyChangedWithValue:(float)newFrequency;
- (void)bandsChangedWithValue:(float*)newBands numBands:(int)n;
- (void)updateFrequencyLabel;
- (void)drawRect;

- (void)getPointColor:(CGFloat*)out_color
             forValue:(float)voltage;
-(void) getPointColorDiscrete:(CGFloat*)out_color
                    forValue:(float)voltage;


-(void) colorImageRow:(int)row;


@end
