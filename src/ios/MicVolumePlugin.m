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
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
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
		
		/*
        float   minDecibels = -60.0f; // Or use -60dB, which I measured in a silent room.
        float   decibels    = [self.recorder averagePowerForChannel:0];



        
        if (decibels < minDecibels)
        {
            level = 0.0f;
        }
        else if (decibels >= 0.0f)
        {
            level = 1.0f;
        }
        else
        {
            float   root            = 2.0f;
            float   minAmp          = powf(10.0f, 0.05f * minDecibels);
            float   inverseAmpRange = 1.0f / (1.0f - minAmp);
            float   amp             = powf(10.0f, 0.05f * decibels);
            float   adjAmp          = (amp - minAmp) * inverseAmpRange;
            
            level = powf(adjAmp, 1.0f / root);
        }
		*/
		
		const double ALPHA = 0.7;
		double peakPowerForChannel = pow(10, (0.05 * [recorder averagePowerForChannel:0]));
		level = ALPHA * peakPowerForChannel + (1.0 - ALPHA) * level;
    }
    
    
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:level],@"volume", nil]];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}



- (void)stop:(CDVInvokedUrlCommand*)command
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategorySoloAmbient error:nil];
    
    if (self.recorder) {
      [self.recorder stop];
    }
}


@end