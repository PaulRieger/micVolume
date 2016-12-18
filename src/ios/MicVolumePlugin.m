//
//  MicVolumePlugin.m
//  MicVolumePlugin
//


#import "MicVolumePlugin.h"



@implementation MicVolumePlugin

@synthesize recorder;


- (void)start:(CDVInvokedUrlCommand*)command
{
    // Init audio with record capability
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
    
    /*
    // Doubly force audio to come out of speaker
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute,sizeof(audioRouteOverride),&audioRouteOverride);

    // fix issue with audio interrupting video recording - allow audio to mix on top of other media
    UInt32 doSetProperty = 1;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(doSetProperty), &doSetProperty);
    */
    
    // Force audio to come out of speaker
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    
    
    // record audio to /dev/null
    NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];

    // some settings
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithFloat: 44100.0],                 AVSampleRateKey,
                              [NSNumber numberWithInt: kAudioFormatAppleLossless], AVFormatIDKey,
                              [NSNumber numberWithInt: 2],                         AVNumberOfChannelsKey,
                              [NSNumber numberWithInt: AVAudioQualityMax],         AVEncoderAudioQualityKey,
                              nil];


    
    CDVPluginResult* result = nil;
    
    // create a AVAudioRecorder
    NSError *error = nil;
    NSLog(@"before instanciate");
    self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
    NSLog(@"after instanciate");
    
    if (self.recorder) {
        [self.recorder prepareToRecord];
        self.recorder.meteringEnabled = YES;
        [self.recorder record];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"OK"];
    } else {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"ERROR"];
    }
    
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}





- (void)read:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result = nil;
    
    if (self.recorder) {
        [self.recorder updateMeters];
				
		const double ALPHA = 0.7;
		double peakPowerForChannel = pow(10, (0.05 * [recorder averagePowerForChannel:0]));
		level = round(20 * log10(peakPowerForChannel) + 90);
    }
    
    
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:level],@"volume", nil]];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}



- (void)stop:(CDVInvokedUrlCommand*)command
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategorySoloAmbient error:nil];
    
    /*
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_None;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);
    */
    
    if (self.recorder) {
      [self.recorder stop];
    }
}





@end
