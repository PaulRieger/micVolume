micVolume
=========

Phonegap plugin for reading ambient noise level through microphone.

Thanks for shukriadams to beginning this project

Supported platforms
-------------------
Android

iOS


Using
-----
Add to your build flow :
  cordova plugin add https://github.com/dekwilde/micVolume.git


    audioPoll.start(succesCallback, errorCallback);

    audioPoll.read(function(reading){
        console.log(reading.volume);
    }, errorCallback);

    audioPoll.stop(succesCallback, errorCallback);

In all cases, errorCallback passes back either an error message string or object with an error message string in it.
