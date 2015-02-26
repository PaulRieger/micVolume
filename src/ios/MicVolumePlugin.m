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
    
    
    // Doubly force audio to come out of speaker
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);
    
    
    
    // fix issue with audio interrupting video recording - allow audio to mix on top of other media
    UInt32 doSetProperty = 1;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(doSetProperty), &doSetProperty);
    
    
    // add listener for audio input changes
    AudioSessionAddPropertyListener (kAudioSessionProperty_AudioRouteChange, onAudioRouteChange, nil );
    AudioSessionAddPropertyListener (kAudioSessionProperty_AudioInputAvailable, onAudioRouteChange, nil );
    

    
    
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
		level = ALPHA * peakPowerForChannel + (1.0 - ALPHA) * level;
    }
    
    
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:level],@"volume", nil]];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}



- (void)stop:(CDVInvokedUrlCommand*)command
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategorySoloAmbient error:nil];
    
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_None;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);
    
    
    if (self.recorder) {
      [self.recorder stop];
    }
}




void onAudioRouteChange (void* clientData, AudioSessionPropertyID inID, UInt32 dataSize, const void* inData) {
    
    if( IS_DEBUGGING == YES ) {
        NSLog(@"==== Audio Harware Status ====");
        NSLog(@"Current Input:  %@", [AudioRouter getAudioSessionInput]);
        NSLog(@"Current Output: %@", [AudioRouter getAudioSessionOutput]);
        NSLog(@"Current hardware route: %@", [AudioRouter getAudioSessionRoute]);
        NSLog(@"==============================");
    }
    
    if( IS_DEBUGGING_EXTRA_INFO == YES ) {
        NSLog(@"==== Audio Harware Status (EXTENDED) ====");
        CFDictionaryRef dict = (CFDictionaryRef)inData;
        CFNumberRef reason = CFDictionaryGetValue(dict, kAudioSession_RouteChangeKey_Reason);
        CFDictionaryRef oldRoute = CFDictionaryGetValue(dict, kAudioSession_AudioRouteChangeKey_PreviousRouteDescription);
        CFDictionaryRef newRoute = CFDictionaryGetValue(dict, kAudioSession_AudioRouteChangeKey_CurrentRouteDescription);
        NSLog(@"Audio old route: %@", oldRoute);
        NSLog(@"Audio new route: %@", newRoute);
        NSLog(@"=========================================");
    }
 
}


- (NSString*) getAudioSessionInput {
    UInt32 routeSize;
    AudioSessionGetPropertySize(kAudioSessionProperty_AudioRouteDescription, &routeSize);
    CFDictionaryRef desc; // this is the dictionary to contain descriptions
    
    // make the call to get the audio description and populate the desc dictionary
    AudioSessionGetProperty (kAudioSessionProperty_AudioRouteDescription, &routeSize, &desc);
    
    // the dictionary contains 2 keys, for input and output. Get output array
    CFArrayRef outputs = CFDictionaryGetValue(desc, kAudioSession_AudioRouteKey_Inputs);
    
    // the output array contains 1 element - a dictionary
    CFDictionaryRef diction = CFArrayGetValueAtIndex(outputs, 0);
    
    // get the output description from the dictionary
    CFStringRef input = CFDictionaryGetValue(diction, kAudioSession_AudioRouteKey_Type);
    return [NSString stringWithFormat:@"%@", input];
}

- (NSString*) getAudioSessionOutput {
    UInt32 routeSize;
    AudioSessionGetPropertySize(kAudioSessionProperty_AudioRouteDescription, &routeSize);
    CFDictionaryRef desc; // this is the dictionary to contain descriptions
    
    // make the call to get the audio description and populate the desc dictionary
    AudioSessionGetProperty (kAudioSessionProperty_AudioRouteDescription, &routeSize, &desc);
    
    // the dictionary contains 2 keys, for input and output. Get output array
    CFArrayRef outputs = CFDictionaryGetValue(desc, kAudioSession_AudioRouteKey_Outputs);
    
    // the output array contains 1 element - a dictionary
    CFDictionaryRef diction = CFArrayGetValueAtIndex(outputs, 0);
    
    // get the output description from the dictionary
    CFStringRef output = CFDictionaryGetValue(diction, kAudioSession_AudioRouteKey_Type);
    return [NSString stringWithFormat:@"%@", output];
}

- (NSString*) getAudioSessionRoute {
    /*
     returns the current session route:
     * ReceiverAndMicrophone
     * HeadsetInOut
     * Headset
     * HeadphonesAndMicrophone
     * Headphone
     * SpeakerAndMicrophone
     * Speaker
     * HeadsetBT
     * LineInOut
     * Lineout
     * Default
     */
    
    UInt32 rSize = sizeof (CFStringRef);
    CFStringRef route;
    AudioSessionGetProperty (kAudioSessionProperty_AudioRoute, &rSize, &route);
    
    if (route == NULL) {
        NSLog(@"Silent switch is currently on");
        return @"None";
    }
    return [NSString stringWithFormat:@"%@", route];
}







@end