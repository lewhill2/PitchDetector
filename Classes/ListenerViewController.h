//
//  ListenerViewController.h
//  SafeSound
//
//  Created by Demetri Miller on 10/25/10.
//  Copyright 2010 Demetri Miller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScreenCaptureView.h"

@class RIOInterface, FFTView;

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
    WAVE_WALL = 4,
    WAVE_GRADIENT = 5
} WaveDrawMode;


typedef enum {
    WAVE_LINEAR_SCALE = 0,
    WAVE_LOG_SCALE = 1,
    WAVE_SQUARED_SCALE = 2,
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

@interface ListenerViewController : UIViewController  <UIAccelerometerDelegate, UIPickerViewDataSource, UIPickerViewDelegate> {
    
    UILabel *currentPitchLabel;
	UILabel *currentBandsLabel;
	UIButton *listenButton;
    
	BOOL isListening;
	RIOInterface *rioRef;
	
	NSMutableString *pitchKey;
	float currentFrequency;
    float maxPeak;
    int maxBand;
	NSString *prevChar;
    float scale;
    float paramAdjust;
    int pitchUpdateCount;
    
    float cosLookup[1024];
    float sinLookup[1024];

    CGFloat pointColor[4];

    float accel[3];
    NSUInteger touchCount;
    CGPoint touchPoints[20];

    WaveAxisScale yAxisScale;

    int currentFrame;
    int lastFrame;

@public
    float currentBands[1024][1024];
    Byte outputData[1024][1024][4];

}

@property (nonatomic, assign) NSMutableArray* currentValueArray;
@property WaveDrawMode waveDrawMode;
@property ColorMode colorMode;


@property(nonatomic, retain) IBOutlet UIView *controlPanelView;

@property(nonatomic, retain) IBOutlet UILabel *currentPitchLabel;
@property(nonatomic, retain) IBOutlet UILabel *currentBandsLabel;
@property(nonatomic, retain) IBOutlet UIButton *listenButton;

@property(nonatomic, retain) IBOutlet UIButton *recordButton;
@property(nonatomic, retain) IBOutlet UIButton *stopButton;

@property(nonatomic, retain) IBOutlet UIPickerView *modePicker;

@property(nonatomic, retain) IBOutlet UISlider *scaleSlider;
@property(nonatomic, retain) IBOutlet UISlider *paramSlider;

@property(nonatomic, retain) NSMutableString *pitchKey;
@property(nonatomic, retain) NSString *prevChar;
@property(nonatomic, assign) RIOInterface *rioRef;
@property(nonatomic, assign) float currentFrequency;
@property(assign) BOOL isListening;

@property CGColorSpaceRef colorSpace;

@property (nonatomic, retain) UIAccelerometer *accelerometer;

@property (nonatomic, retain) IBOutlet FFTView *fftView;

#pragma mark Listener Controls
- (IBAction)toggleListening:(id)sender;

- (void)startListener;
- (void)stopListener;
-(IBAction)scaleSliderValueChanged:(UISlider *)sender;
-(IBAction)paramSliderValueChanged:(UISlider *)sender;

-(void) handleSingleTap:(UITapGestureRecognizer *)gr;

- (void)frequencyChangedWithValue:(float)newFrequency;
- (void)bandsChangedWithValue:(float*)newBands numBands:(int)n;
- (void)updateFrequencyLabel;

- (void)getPointColor:(CGFloat*)out_color
                    forValue:(float)voltage;
- (void) getPointColorDiscrete:(CGFloat*)out_color
                      forValue:(float)voltage;


-(void) colorImageRow:(int)row;

// screen recording
-(IBAction)startRecording:(id)sender;
-(IBAction)stopRecording:(id)sender;

- (void)drawRect;

+(NSArray*) renderingModes;
+(NSArray*) coloringModes;
+(NSArray*) scalingModes;



@end
