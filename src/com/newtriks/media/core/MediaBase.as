/*
 * Copyright (c) 2011 Simon Bailey <simon@newtriks.com>
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement located at the
 * following url: http://www.newtriks.com/LICENSE.html
 */
package com.newtriks.media.core {
import com.newtriks.media.containers.MediaBaseContainer;
import com.newtriks.utils.CreateUUID;

import flash.events.ActivityEvent;
import flash.events.AsyncErrorEvent;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.NetStatusEvent;
import flash.events.StatusEvent;
import flash.events.TimerEvent;
import flash.media.Camera;
import flash.media.Microphone;
import flash.media.SoundCodec;
import flash.media.SoundTransform;
import flash.media.Video;
import flash.net.NetConnection;
import flash.net.NetStream;
import flash.utils.Timer;
import flash.utils.clearInterval;
import flash.utils.setInterval;

import mx.events.VideoEvent;

import spark.components.Group;

public class MediaBase extends Group {
    public static const WIDE_SCREEN:String = "MediaBase::WIDE";
    public static const STRETCH_SCREEN:String = "MediaBase::STRETCH";
    public static const RECORDER:String = "MediaBase::RECORDER";
    public static const PLAYER:String = "MediaBase::PLAYER";
    // NET CONSTANTS
    public static const CONNECTED:String = "NetConnection.Connect.Success";
    public static const CLOSED:String = "NetConnection.Connect.Closed";
    public static const FAILED:String = "NetConnection.Connect.Failed";
    public static const REJECTED:String = "NetConnection.Connect.Rejected";
    public static const BUFFER_FULL:String = "NetStream.Buffer.Full";
    public static const BUFFER_EMPTY:String = "NetStream.Buffer.Empty";
    public static const BUFFER_FLUSH:String = "NetStream.Buffer.Flush";
    public static const STOPPED:String = "NetStream.Play.Stop";
    public static const COMPLETE:String = "NetStream.Play.Complete";
    public static const PAUSED:String = "NetStream.Pause.Notify";
    public static const PLAYING:String = "NetStream.UnPause.Notify";
    public static const STARTING:String = "NetStream.Play.Start";
    public static const NO_STREAM:String = "NetStream.Play.StreamNotFound";
    public static const UNPUBLISHED:String = "NetStream.Unpublish.Success";
    public static const START_RECORDING:String = "NetStream.Record.Start";
    public static const STOP_RECORDING:String = "NetStream.Record.Stop";
    public static const INVALID_SEEK:String = "NetStream.Seek.InvalidTime";
    // VIDEO CONSTANTS
    public static const READY:String = ":READY";
    public static const TOGGLE:String = "Recorder::TOGGLE";
    public static const START:String = "Recorder::START";
    public static const STOP:String = "Recorder::STOP";
    public static const VIDEO:String = "Recorder::VIDEO";
    public static const AUDIO:String = "Recorder::AUDIO";
    public static const CAMERA_LOADED:String = "Recorder::CAMERA_LOADED";
    public static const CAMERA_ERROR:String = "Recorder::CAMERA_ERROR";
    public static const CAMERA_ACCESS_DENIED:String = "Recorder::CAMERA_ACCESS_DENIED";
    public static const END:String = "Player::END";
    public static const PLAY_START:String = "Player::START";
    public static const SEEK_COMPLETE:String = "Player::SEEK_COMPLETE";
    public static const STREAM_ERROR:String = "Player::ERROR";
    // Net callbacks
    public var onMetaData:Function;
    public var onCuePoint:Function;
    public var onPlayStatus:Function;
    public var onLastSecond:Function;
    public var onTimeCoordInfo:Function;
    private static const MAX_CONNECTION_ATTEMPTS:int = 3;
    // Private class variables
    private var _soundTransform:SoundTransform;
    private var _connectionTimeout:Timer;
    private var _configuration:MediaBaseConfiguration;
    private var _camera:Camera;
    private var _microphone:Microphone;
    private var _flushVideoBufferTimer:Number = 0;

    public function MediaBase(configuration:MediaBaseConfiguration) {
        if (configuration.client == null) {
            configuration.client(this);
        }
        _configuration = configuration;
    }

    /**
     * GETTERS & SETTERS
     */

    public function get configuration():MediaBaseConfiguration {
        return _configuration;
    }

    public function get timeLimit():int {
        return configuration._timeLimit;
    }

    public function get countdown():int {
        return configuration._countdown;
    }

    private var _connection:NetConnection;
    public function get connection():NetConnection {
        return _connection;
    }

    public function set connection(value:NetConnection):void {
        if (value == null) {
            return;
        }
        _connection = value;
        connectNetStream();
    }

    private var _container:MediaBaseContainer;
    public function get container():MediaBaseContainer {
        return _container;
    }

    public function set container(value:MediaBaseContainer):void {
        _container = value;
    }

    private var _baseType:String;
    public function get baseType():String {
        return _baseType;
    }

    public function set baseType(value:String):void {
        _baseType = value;
    }

    private var _stream:NetStream;
    public function get stream():NetStream {
        return _stream;
    }

    private var _videoDisplay:UIVideoDisplay;

    public function get display():UIVideoDisplay {
        return _videoDisplay;
    }

    public function get video():Video {
        return _videoDisplay.video;
    }

    private var _streamName:String;
    public function set streamName(val:String):void {
        _streamName = val;
        if (baseType != PLAYER) {
            return;
        }
        stream.play(val, 0);
    }

    public function get streamName():String {
        return _streamName;
    }

    private var _status:String;
    public function get status():String {
        return _status;
    }

    private var _duration:Number;
    public function get duration():Number {
        return _duration;
    }

    private var _cameraBroadcasting:Boolean = false;
    public function set cameraBroadcasting(value:Boolean):void {
        if (_cameraBroadcasting == value) {
            return;
        }
        _cameraBroadcasting = value;
        log("camera broadcasting: ".concat(value));
        var type:String = (_cameraBroadcasting) ? VIDEO : AUDIO;
        dispatchEvent(new Event(type, true));
    }

    public function get cameraBroadcasting():Boolean {
        return _cameraBroadcasting;
    }

    protected function get camDimensions():Object {
        if (configuration._camWidth) {
            return {width:configuration._camWidth, height:configuration._camHeight};
        }
        return {width:dimensions.width, height:dimensions.height};
    }

    private var _append:Boolean = false;
    public function get append():Boolean {
        return _append;
    }

    public function set append(value:Boolean):void {
        _append = value;
    }

    public function get dimensions():Object {
        var normalAspectRatio:Boolean = configuration._aspectRatio == MediaBase.STRETCH_SCREEN;
        var width:int = normalAspectRatio ? UIVideoDisplay.STRETCH_SCREEN_RECORDING_WIDTH : UIVideoDisplay.WIDE_SCREEN_RECORDING_WIDTH;
        var height:int = normalAspectRatio ? UIVideoDisplay.STRETCH_SCREEN_RECORDING_HEIGHT : UIVideoDisplay.WIDE_SCREEN_RECORDING_HEIGHT;
        return {"width":width, "height":height};
    }

    /**
     * CLASS METHODS
     */

    public function updateLayout():void {
        configuration._layoutCallbackHandler();
    }

    public function resize(w:Number, h:Number):void {
        _videoDisplay.width = w;
        _videoDisplay.height = h;
    }

    public function attachCamera(index:String = ""):void {
        log("setting up camera " + index);
        if (!_camera) {
            try {
                if (index.length) _camera = Camera.getCamera(index);
                else _camera = Camera.getCamera();

                if (_camera) {
                    _camera.setMode(camDimensions.width, camDimensions.height, configuration._fps, false);
                    _camera.setQuality(configuration._bandwidth, configuration._quality);
                    _camera.setKeyFrameInterval(configuration._fps);
                    if (_camera.muted) {
                        _camera.addEventListener(StatusEvent.STATUS, statusHandler);
                        this.dispatchEvent(new Event(CAMERA_ERROR, true));
                        log("Error > camera muted");
                        return;
                    }
                    cameraBroadcasting = true;
                    attachCameraToDisplay();
                    log("success > camera setup");
                    _camera.addEventListener(ActivityEvent.ACTIVITY, firstCameraActivity);
                }
                else {
                    dispatchEvent(new Event(CAMERA_ERROR, true));
                }
            }
            catch (error:Error) {
                log(String(error));
                cameraBroadcasting = false;
                dispatchEvent(new Event(CAMERA_ERROR, true));
            }
        }
        else if (!_isRecording) {
            unAttachCamera();
            attachCamera(index);
        }
    }

    public function unAttachCamera():void {
        if (display) {
            display.detachCamera();
        }
        cameraBroadcasting = false;
        _camera = null;
    }

    protected function attachCameraToDisplay():void {
        if (_camera != null && display != null) {
            log("attaching camera to UIVideoDisplay");
            display.attachCamera(_camera);
        }
    }

    public function setupMicrophone(index:int = -1):void {
        if (_isRecording) return;
        log("setting up microphone");
        try {
            if (index >= 0) _microphone = Microphone.getMicrophone(index);
            else _microphone = Microphone.getMicrophone();
            /**
             * Speex is generally preferred over Nellymoser
             * but FFMPeg doesn't like it
             */
            _microphone.codec = SoundCodec.NELLYMOSER;
            _microphone.rate = configuration._microphoneRate;					// set audio to a more than average quality
            _microphone.setSilenceLevel(configuration._microphoneSilenceLevel); 		// prevent mic from cutting sound off when no sound is detected
            log("success > microphone setup");
        }
        catch (error:Error) {
            log("error > microphone: ".concat(String(error)));
        }
    }

    public function destroy():void {
        disconnectCameraAndMicrophone();
        unAttachCamera();
        if (!_videoDisplay && !_stream) return;
        log("performing cleanup");
        _videoDisplay.destroy();
        if (_stream != null) {
            _stream.removeEventListener(NetStatusEvent.NET_STATUS, handleNetStreamStatus);
            _stream.close();
        }
        _stream = null;
        this.removeElement(_videoDisplay);
        _videoDisplay = null;
    }

    protected function init():void {
        //log("init");
    }

    protected function connectNetStream():void {
        if (_connection.connected) {
            log("connecting NetStream");
            _stream = new NetStream(_connection);
            _stream.addEventListener(NetStatusEvent.NET_STATUS, handleNetStreamStatus);
            _stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncStreamErrorHandler);
            _stream.addEventListener(IOErrorEvent.IO_ERROR, IOStreamErrorHandler);
            _stream.client = configuration._client;
            onMetaData = metaDataHandler;
            onCuePoint = cuePointHandler;
            onPlayStatus = playStatusHandler;
            onTimeCoordInfo = handleTimeCoordInfo;
            onLastSecond = handleLastSecond;
            _stream.bufferTime = configuration._bufferTime;
            _soundTransform = new SoundTransform();
            buildVideoDisplay();
        }
        else {
            _connectionTimeout = new Timer(250, MAX_CONNECTION_ATTEMPTS);
            _connectionTimeout.addEventListener(TimerEvent.TIMER, timerHandler, false, 0, true);
            _connectionTimeout.start();
        }
    }

    private function timerHandler(event:TimerEvent):void {
        log("Connection attempt: " + _connectionTimeout.currentCount.toString());
        if (_connection.connected) {
            connectNetStream();
            _connectionTimeout.stop();
            _connectionTimeout.removeEventListener(TimerEvent.TIMER, timerHandler);
        }
    }

    protected function buildVideoDisplay():void {
        if (!_videoDisplay) {
            log("building UIVideoDisplay");
            _videoDisplay = new UIVideoDisplay();
            _videoDisplay.dimensions = dimensions;
            _videoDisplay.addEventListener(VideoEvent.STATE_CHANGE, videoDisplayStateChange);
            this.addElement(_videoDisplay);
            // Attach net stream
            _videoDisplay.netStream = _stream;
            // Ready to update layout
            updateLayout();
        }
        dispatchEvent(new Event(READY, true));
        if (baseType != MediaBase.RECORDER) {
            resize(this.width, this.height);
        }
        else {
            attachCamera();
            setupMicrophone();
        }
    }

    protected function sendMetadata():void {
        var metaData:Object = new Object();
        metaData.title = streamName;
        metaData.width = camDimensions.width;
        metaData.height = camDimensions.height;
        metaData.hasKeyframes = true;
        metaData.hasMetadata = true;
        metaData.hasVideo = true;
        stream.send("@setDataFrame", "onMetaData", metaData);
    }

    public function publish(name:String):void {
        if (name == "") {
            streamName = "stream_".concat(CreateUUID.createUUID());
        }
        else {
            streamName = name;
        }
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
            stream.publish(streamName, (append ? "append" : "record"));
        }
        dispatchEvent(new Event(START, true));
        _isRecording = true;
    }

    private var _isRecording:Boolean;

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

    public function stopRecording():void {
        log("Stopping recording");
        stream.publish(null);
        _isRecording = false;
    }

    public function buildNewStream():void {
        connection = connection;
    }

    public function disconnectCameraAndMicrophone():void {
        if (!stream) {
            return;
        }
        log("Disconnecting Camera and Microphone from stream");
        stream.attachCamera(null);
        stream.attachAudio(null);
    }

    protected function log(msg:String):void {
        if (configuration._logCallbackHandler == null) {
            return;
        }
        configuration._logCallbackHandler('MediaBase :: '.concat(msg));
    }

    /**
     * EVENT HANDLERS
     */

    protected function handleNetStreamStatus(event:NetStatusEvent):void {
        _status = event.info.code;
        switch (status) {
            case START_RECORDING:
                sendMetadata();
                break;
            case UNPUBLISHED:
                log("Recording successfully written data");
                /**
                 * Flash client has problem when you try to reuse a
                 * NetStream object to publish core and it tends to
                 * generate an errant core/audio packet with a large
                 * time code.  So need to create a new stream each time
                 * we publish.  Wait till we have this event from the
                 * old netstream first.
                 */
                if (configuration._autoReload) {
                    buildNewStream();
                }
                else {
                    destroy();
                }
                // Dispatch to switch state and perform cleanup
                dispatchEvent(new Event(STOP, true));
                break;
            /*case STOPPED:*/
            case COMPLETE:
                dispatchEvent(new Event(END, true));
                break;
            case STOPPED:
                if (stream.bufferLength <= stream.bufferTime) {
                    //dispatchEvent(new Event(END, true));
                }
                break;
            case STARTING:
                dispatchEvent(new Event(PLAY_START, true));
                break;
            case INVALID_SEEK:
            {
                stream.seek(event.info.details);
                return;
            }
                break;
            case NO_STREAM:
                dispatchEvent(new Event(STREAM_ERROR, true));
                break;
            case BUFFER_FULL:
                stream.bufferTime = 15;
                break;
            case BUFFER_EMPTY:
                stream.bufferTime = 2;
                break;
        }
    }

    protected function videoDisplayStateChange(event:VideoEvent):void {
        log("VideoEvent received\n".concat("Render State : ", event.state));
        updateLayout();
    }

    protected function statusHandler(event:StatusEvent):void {
        if (event.code == "Camera.Unmuted") {
            cameraBroadcasting = true;
            attachCameraToDisplay();
            _camera.addEventListener(ActivityEvent.ACTIVITY, firstCameraActivity);
            log("success > camera allowed and setup");
        }
        else {
            if (event.code == "Camera.Muted") {
                this.dispatchEvent(new Event(CAMERA_ACCESS_DENIED, true));
                log("error > camera denied");
            }
        }
    }

    protected function firstCameraActivity(event:ActivityEvent):void {
        this.dispatchEvent(new Event(CAMERA_LOADED, true));
        _camera.removeEventListener(ActivityEvent.ACTIVITY, firstCameraActivity);
    }

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

    protected function asyncStreamErrorHandler(event:AsyncErrorEvent):void {
        _stream.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncStreamErrorHandler);
    }

    protected function IOStreamErrorHandler(event:IOErrorEvent):void {
        _stream.removeEventListener(IOErrorEvent.IO_ERROR, IOStreamErrorHandler);
    }

    protected function seekCompleteHandler(event:Event):void {
        seekTimer.removeEventListener(SeekTimer.COMPLETE, seekCompleteHandler);
        this.dispatchEvent(new Event(SEEK_COMPLETE, true));
    }

    /**
     * CALLBACK HANDLERS
     */

    protected function metaDataHandler(meta:Object):void {
        if (_duration === meta.duration) {
            return;
        }
        configuration._metaDataReceived(meta);
        _duration = meta.duration;
        for (var propName:String in meta) {
            log("Metadata: ".concat(propName, " = ", meta[propName]));
        }
        updateLayout();
    }

    protected function cuePointHandler(obj:Object):void {
        //
    }

    protected function playStatusHandler(obj:Object):void {
        //
    }

    protected function bwDoneHandler():void {
        //
    }

    protected function handleTimeCoordInfo(obj:Object):void {
        /**
         * Returns stream-absolute=0 and have no idea
         * where its implemented and why its thrown?
         * ?FMS4 related?
         * @param o
         */
    }

    protected function handleLastSecond(obj:Object):void {
        //
    }

    public function onNextSegment():void {
        //
    }

    /**
     * Simple controls API
     */

    public function play(name:String, ...rest):void {
        _streamName = name;
        stream.play(name, rest.join(','));
    }

    public function pause():void {
        stream.pause();
    }

    public function resume():void {
        stream.resume();
    }

    private var seekTimer:SeekTimer;

    public function seek(time:Number):void {
        stream.seek(time);
        seekTimer = new SeekTimer(this.stream, time);
        seekTimer.addEventListener(SeekTimer.COMPLETE, seekCompleteHandler);
        seekTimer.start();
    }

    public function get time():Number {
        return stream.time;
    }

    public function set volume(value:Number):void {
        try {
            _soundTransform.volume = value;
            stream.soundTransform = _soundTransform;
        }
        catch (error:Error) {
            log("Error handling mute: ".concat(error.message));
        }
    }
}
}

import com.newtriks.utils.NumberUtil;

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.TimerEvent;
import flash.net.NetStream;
import flash.utils.Timer;

class SeekTimer extends EventDispatcher {
    public static const COMPLETE:String = "SeekTimer::COMPLETE";

    public function SeekTimer(stream:NetStream, seekTime:Number) {
        _progressTimer = new Timer(50);
        _stream = stream;
        _seekTime = seekTime;
    }

    private var _progressTimer:Timer;
    private var _stream:NetStream;
    private var _seekTime:Number;

    internal function start():void {
        _progressTimer.addEventListener(TimerEvent.TIMER, progressTimer_handler);
        _progressTimer.start();
    }

    internal function stop():void {
        _progressTimer.stop();
        _progressTimer.removeEventListener(TimerEvent.TIMER, progressTimer_handler);
        _progressTimer = null;
    }

    internal function progressTimer_handler(event:TimerEvent):void {
        var seekComplete:Boolean = compare(_stream.time, _seekTime);
        if (!seekComplete) return;
        this.dispatchEvent(new Event(COMPLETE, true));
        this.stop();
    }

    internal function compare(current:Number, expected:Number):Boolean {
        var seekTimeEqualsCurrentStreamTime:Boolean = NumberUtil.roundNumber(current) == NumberUtil.roundNumber(expected);
        var seekTimeAndCurrentStreamTimeLessThanZero:Boolean = Boolean(Math.floor(_stream.time) < 1 && _seekTime < 1);

        return (seekTimeAndCurrentStreamTimeLessThanZero || seekTimeEqualsCurrentStreamTime);
    }
}