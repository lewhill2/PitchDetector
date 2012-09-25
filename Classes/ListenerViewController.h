//
//  ListenerViewController.h
//  SafeSound
//
//  Created by Demetri Miller on 10/25/10.
//  Copyright 2010 Demetri Miller. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RIOInterface;

@interface ListenerViewController : UIViewController {
    IBOutlet UILabel *currentPitchLabel;
	IBOutlet UILabel *currentBandsLabel;
	IBOutlet UIButton *listenButton;
	IBOutlet UIImageView* imageView;

	BOOL isListening;
	RIOInterface *rioRef;
	
	NSMutableString *key;
	float currentFrequency;
    float maxPeak;
    int maxBand;
    int currentFrame;
	NSString *prevChar;
    
    float currentBands[1024][1024];
}

@property(nonatomic, retain) UILabel *currentPitchLabel;
@property(nonatomic, retain) UILabel *currentBandsLabel;
@property(nonatomic, retain) UIButton *listenButton;
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

- (void)frequencyChangedWithValue:(float)newFrequency;
- (void)bandsChangedWithValue:(float*)newBands:(int)n;
- (void)updateFrequencyLabel;
- (void)drawRect;
- (void)transformColor:(CGFloat[])in_color
               toColor:(CGFloat[])out_color
                   byH:(float)H;
-(void) getPointColor:(CGFloat*)out_color
          forValue:(float)voltage;



@end
