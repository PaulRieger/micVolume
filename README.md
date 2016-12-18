micVolume
=========

Phonegap plugin for reading ambient noise level through the microphone.

Thanks to shukriadams for beginning this project.

Supported platforms
-------------------
Android

iOS


Using
-----
Add to your build flow :
  cordova plugin add https://github.com/PaulRieger/micVolume.git


    window.micVolume.start(succesCallback, errorCallback);

    window.micVolume.read(function(reading){
        console.log(reading.volume);
    }, errorCallback);

    window.micVolume.stop(succesCallback, errorCallback);

In all cases, errorCallback passes back either an error message string or object with an error message string in it.
