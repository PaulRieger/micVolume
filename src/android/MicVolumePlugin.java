package com.dekwilde.micVolume;

import android.media.MediaRecorder;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

// used by audio

public class MicVolumePlugin extends CordovaPlugin {
    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        try {
            if (action.equals("start")) {
                start(callbackContext);
            } else if (action.equals("read")) {
                read(callbackContext);
            } else if (action.equals("stop")) {
                stop(callbackContext);
            } else {
                callbackContext.error("Unsupported action");
            }

      /*
      JSONObject returnObj = new JSONObject();
      returnObj.put("title", "you should still be seeing this");
          callbackContext.success(returnObj); // pass return object back here
          */
            return true;
        } catch (Exception e) {
            System.err.println("Exception: " + e.getMessage());
            callbackContext.error(e.getMessage());
            return false;
        }
    }

    static final private double EMA_FILTER = 0.6;

    private MediaRecorder mRecorder = null;
    private double mEMA = 0.0;

    private void start(CallbackContext callbackContext) {
        if (mRecorder == null) {
            mRecorder = new MediaRecorder();
            mRecorder.setAudioSource(MediaRecorder.AudioSource.MIC);
            mRecorder.setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP);
            mRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB);
            mRecorder.setOutputFile("/dev/null");
            try {
                mRecorder.prepare();
            } catch (java.io.IOException ioe) {
                android.util.Log.e("[Monkey]", "IOException: " + android.util.Log.getStackTraceString(ioe));

            } catch (java.lang.SecurityException e) {
                android.util.Log.e("[Monkey]", "SecurityException: " + android.util.Log.getStackTraceString(e));
            }
            try {
                mRecorder.start();
            } catch (java.lang.SecurityException e) {
                android.util.Log.e("[Monkey]", "SecurityException: " + android.util.Log.getStackTraceString(e));
            }
            mEMA = 0.0;
        }

        callbackContext.success();
    }

    private void read(CallbackContext callbackContext) throws JSONException {

        JSONObject returnObj = new JSONObject();
        double amplitude = 0.0;

        if (mRecorder != null)
            amplitude = (mRecorder.getMaxAmplitude() / 32767.0);

        returnObj.put("volume", amplitude);
        callbackContext.success(returnObj);
    }

    private void stop(CallbackContext callbackContext) {
        if (mRecorder != null) {
            mRecorder.stop();
            mRecorder.release();
            mRecorder = null;
        }

        callbackContext.success();
    }
}
