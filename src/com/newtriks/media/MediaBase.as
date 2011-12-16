/*
 * Copyright (c) 2011 Simon Bailey <simon@newtriks.com>
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement located at the
 * following url: http://www.newtriks.com/LICENSE.html
 */
package com.newtriks.media {
import com.newtriks.media.core.VideoBase;
import com.newtriks.media.core.VideoConfigurationVO;
import com.newtriks.utils.CreateUUID;

import flash.events.ActivityEvent;
import flash.events.Event;
import flash.events.NetStatusEvent;
import flash.events.StatusEvent;
import flash.media.Camera;
import flash.media.H264Level;
import flash.media.H264Profile;
import flash.media.H264VideoStreamSettings;
import flash.media.Microphone;
import flash.media.SoundCodec;
import flash.utils.clearInterval;
import flash.utils.setInterval;

public class MediaBase extends VideoBase {
    public static const TOGGLE:String = "Recorder::TOGGLE";
    public static const START:String = "Recorder::START";
    public static const STOP:String = "Recorder::STOP";
    public static const VIDEO:String = "Recorder::VIDEO";
    public static const AUDIO:String = "Recorder::AUDIO";
    public static const CAMERA_LOADED:String = "Recorder::CAMERA_LOADED";
    public static const CAMERA_ERROR:String = "Recorder::CAMERA_ERROR";
    public static const END:String = "Player::END";
    public static const PLAY_START:String = "Player::START";
    public static const SEEK_COMPLETE:String = "Player::SEEK_COMPLETE";
    public static const STREAM_ERROR:String = "Player::ERROR";
    private var _camera:Camera;
    private var _microphone:Microphone;
    private var _cameraBroadcasting:Boolean;
    private var _flushVideoBufferTimer:Number = 0;
    private var _h264Settings:H264VideoStreamSettings;

    public function MediaBase(configuration:VideoConfigurationVO) {
        if (configuration.client == null) {
            configuration.client(this);
        }
        super(configuration);
        init();
    }

    /**
     * GETTERS & SETTERS
     */

    override public function get cameraBroadcasting():Boolean {
        return _cameraBroadcasting;
    }

    override public function set cameraBroadcasting(value:Boolean):void {
        if (_cameraBroadcasting == value) {
            return;
        }
        _cameraBroadcasting = value;
        log("camera broadcasting: ".concat(value));
        var type:String = (_cameraBroadcasting) ? VIDEO : AUDIO;
        dispatchEvent(new Event(type, true));
    }

    /**
     * PARENT OVERRIDES
     */

    override protected function init():void {
        if (baseType == VideoBase.RECORDER) {
            attachCamera();
            setupMicrophone();
            bufferTime = 20;
        }
        super.init();
    }

    override protected function buildVideoDisplay():void {
        super.buildVideoDisplay();
        if (baseType != VideoBase.RECORDER) {
            resize(this.width, this.height);
            return;
        }
        attachCameraToDisplay();
    }

    override protected function handleNetStreamStatus(event:NetStatusEvent):void {
        super.handleNetStreamStatus(event);
        switch (status) {
            case VideoBase.START_RECORDING:
                sendMetadata();
                break;
            case VideoBase.STOP_RECORDING:
                if (bufferEmpty) {
                    dispatchEvent(new Event(MediaBase.TOGGLE));
                }
                break;
            case VideoBase.UNPUBLISHED:
                log("Recording successfully written data");
                /**
                 * Flash client has problem when you try to reuse a
                 * NetStream object to publish core and it tends to
                 * generate an errant core/audio packet with a large
                 * time code.  So need to create a new stream each time
                 * we publish.  Wait till we have this event from the
                 * old netstream first.
                 */
                buildNewStream();
                // Dispatch to switch state and perform cleanup
                dispatchEvent(new Event(MediaBase.STOP, true));
                break;
            /*case STOPPED:*/
            case COMPLETE:
                dispatchEvent(new Event(MediaBase.END, true));
                break;
            case STOPPED:
                if (stream.bufferLength <= stream.bufferTime) {
                    dispatchEvent(new Event(MediaBase.END, true));
                }
                break;
            case STARTING:
                dispatchEvent(new Event(MediaBase.PLAY_START, true));
                break;
            case INVALID_SEEK:
            {
                stream.seek(event.info.details);
                return;
            }
                break;
            case NO_STREAM:
                dispatchEvent(new Event(MediaBase.STREAM_ERROR, true));
                break;
        }
    }

    override protected function seekCompleteHandler(event:Event):void {
        super.seekCompleteHandler(event);
        this.dispatchEvent(new Event(SEEK_COMPLETE, true));
    }

    override public function destroy():void {
        disconnectCameraAndMicrophone();
        unAttachCamera();
        super.destroy();
    }

    /**
     * CLASS METHODS
     */

    override public function attachCamera():void {
        log("setting up camera");
        if (!_camera) {
            try {
                _camera = Camera.getCamera();
                if (_camera) {
                    _camera.setMode(dimensions.width, dimensions.height, fps, false);
                    _camera.setQuality(bandwidth, quality);
                    _camera.setKeyFrameInterval(fps / 2);
                    cameraBroadcasting = true;
                    attachCameraToDisplay();
                    configureEncoder();
                    log("success > camera setup");
                    if (_camera.muted) {
                        /*                            Security.showSettings(SecurityPanel.PRIVACY);
                         _camera.addEventListener(StatusEvent.STATUS, statusHandler);*/
                    }
                    _camera.addEventListener(ActivityEvent.ACTIVITY, firstCameraActivity);
                }
                else {
                    throw Error("error > no camera detected");
                }
            }
            catch (error:Error) {
                log(String(error));
                cameraBroadcasting = false;
                dispatchEvent(new Event(CAMERA_ERROR, true));
            }
        }
    }

    override public function unAttachCamera():void {
        display.detachCamera();
        cameraBroadcasting = false;
        _camera = null;
    }

    protected function setupMicrophone():void {
        log("setting up microphone");
        try {
            _microphone = Microphone.getMicrophone();
            /**
             * Speex is generally preferred over Nellymoser
             * but FFMPeg doesn't like it
             */
            _microphone.codec = SoundCodec.SPEEX;
            _microphone.rate = microphoneRate;					// set audio to a more than average quality
            _microphone.setSilenceLevel(microphoneSilenceLevel); 		// prevent mic from cutting sound off when no sound is detected
            log("success > microphone setup");
        }
        catch (error:Error) {
            log("error > microphone: ".concat(String(error)));
        }
    }

    protected function attachCameraToDisplay():void {
        if (_camera != null && display != null) {
            log("attaching camera to UIVideoDisplay");
            display.attachCamera(_camera);
        }
    }

    public function configureEncoder():void {
        _h264Settings = new H264VideoStreamSettings();
        _h264Settings.setProfileLevel(H264Profile.BASELINE, H264Level.LEVEL_3_1);

        /*ALTHOUGH FUTURE VERSIONS OF FLASH PLAYER SHOULD SUPPORT SETTING ENCODING PARAMETERS
         ON h264Settings BY USING THE setQuality() and setMode() METHODS, FOR NOW YOU MUST SET
         SET THE PARAMETERS ON THE CAMERA FOR: BANDWITH, QUALITY, HEIGHT, WIDTH, AND FRAMES PER SECOND.

         h264Settings.setQuality(30000, 90);
         h264Settings.setMode(320, 240, 30);*/
        stream.videoStreamSettings = _h264Settings;
    }

    /*
     * We are injecting width and height metadata so that upon replay
     * the com.newtriks.editor can scale itself properly
     */
    protected function sendMetadata():void {
        var metaData:Object = new Object();
        metaData.codec = stream.videoStreamSettings.codec;
        metaData.profile = _h264Settings.profile;
        metaData.level = _h264Settings.level;
        metaData.fps = _camera.fps;
        metaData.title = streamName;
        metaData.width = dimensions.width;
        metaData.height = dimensions.height;
        metaData.keyFrameInterval = _camera.keyFrameInterval;
        metaData.hasKeyframes = true;
        metaData.hasMetadata = true;
        metaData.hasVideo = true;
        metaData.copyright = "Newtriks LTD, 2011";
        stream.send("@setDataFrame", "onMetaData", metaData);
    }

    public function publish():void {
        streamName = "stream_".concat(CreateUUID.createUUID());
        if (_microphone) {
            log("Attaching Microphone to NetStream");
            stream.attachAudio(_microphone);
        }
        if (_camera && _cameraBroadcasting) {
            log("Attaching Camera to NetStream");
            stream.attachCamera(_camera);
        }
        if (_microphone || _camera) {
            log("Publishing recorded stream: ".concat(streamName));
            stream.publish("mp4:".concat(streamName, ".f4v"), (append ? "append" : "record"));
        }
        dispatchEvent(new Event(MediaBase.START, true));
    }

    public function unpublish():void {
        disconnectCameraAndMicrophone();
        var buffLen:Number = stream.bufferLength;
        if (buffLen > 0) {
            _flushVideoBufferTimer = setInterval(flushVideoBuffer, 250);
            log("Flushing buffer.....");
        }
        else {
            stopRecording();
        }
    }

    protected function stopRecording():void {
        log("Stopping recording");
        stream.publish(null);
    }

    public function buildNewStream():void {
        super.connection = connection;
    }

    public function disconnectCameraAndMicrophone():void {
        log("Disconnecting Camera and Microphone from stream");
        stream.attachCamera(null);
        stream.attachAudio(null);
    }

    /**
     * EVENT HANDLERS
     */
    /**
     * Run every 250ms to check the progress of the flushing
     * status of the core buffer.  Once empty then close
     * publishing stream.
     */
    protected function flushVideoBuffer():void {
        var buffLen:Number = stream.bufferLength;
        //trace("Buffer flushing, length:"+buffLen);
        if (!buffLen) {
            clearInterval(_flushVideoBufferTimer);
            _flushVideoBufferTimer = 0;
            stopRecording();
        }
    }

    protected function statusHandler(event:StatusEvent):void {
        if (event.code == "Camera.Unmuted") {
            _camera.removeEventListener(StatusEvent.STATUS, statusHandler);
        }
    }

    protected function firstCameraActivity(event:ActivityEvent):void {
        this.dispatchEvent(new Event(CAMERA_LOADED, true));
        _camera.removeEventListener(ActivityEvent.ACTIVITY, firstCameraActivity);
    }
}
}
