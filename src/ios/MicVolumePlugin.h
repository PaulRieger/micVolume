//
//  MicVolumePlugin.h
//  MicVolumePlugin

#import <Cordova/CDV.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

@interface MicVolumePlugin : CDVPlugin {
	AVAudioRecorder *recorder;
    double level;
}

@property (nonatomic, retain) AVAudioRecorder* recorder;


- (void)start:(CDVInvokedUrlCommand *)command;
- (void)read:(CDVInvokedUrlCommand *)command;
- (void)stop:(CDVInvokedUrlCommand *)command;

@end