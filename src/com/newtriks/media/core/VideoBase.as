/*
 * Copyright (c) 2011 Simon Bailey <simon@newtriks.com>
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement located at the
 * following url: http://www.newtriks.com/LICENSE.html
 */
package com.newtriks.media.core {
import com.newtriks.media.core.interfaces.IVideoBase;

import flash.events.AsyncErrorEvent;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.NetStatusEvent;
import flash.events.TimerEvent;
import flash.media.SoundTransform;
import flash.media.Video;
import flash.net.NetConnection;
import flash.net.NetStream;
import flash.utils.Timer;

import mx.events.VideoEvent;

import spark.components.Group;

public class VideoBase extends Group implements IVideoBase {
    public static const WIDE_SCREEN:String = "VideoBase::WIDE";
    public static const STRETCH_SCREEN:String = "VideoBase::STRETCH";
    public static const RECORDER:String = "VideoBase::RECORDER";
    public static const PLAYER:String = "VideoBase::PLAYER";
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
    // Net callbacks
    public var onMetaData:Function;
    public var onCuePoint:Function;
    public var onPlayStatus:Function;
    public var onLastSecond:Function;
    public var onTimeCoordInfo:Function;
    private static const MAX_CONNECTION_ATTEMPTS:uint = 3;
    // Private class variables
    private var _soundTransform:SoundTransform;
    private var _connectionTimeout:Timer;
    private var _configuration:VideoConfigurationVO;

    public function VideoBase(configuration:VideoConfigurationVO) {
        _configuration = configuration;
    }

    /**
     * GETTERS & SETTERS
     */

    public function get data():VideoConfigurationVO {
        return _configuration;
    }

    public function get baseType():String {
        return data.baseType;
    }

    public function get aspectRatio():String {
        return data._aspectRatio;
    }

    public function get client():Object {
        return data._client ||= this;
    }

    public function get bandwidth():uint {
        return data._bandwidth;
    }

    public function get quality():uint {
        return data._quality;
    }

    public function get fps():uint {
        return data._fps;
    }

    public function get microphoneRate():uint {
        return data._microphoneRate;
    }

    public function get microphoneSilenceLevel():uint {
        return data._microphoneSilenceLevel;
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

    private var _bufferTime:Number = 1; // buffer!
    public function get bufferTime():Number {
        return _bufferTime;
    }

    public function set bufferTime(value:Number):void {
        _bufferTime = value;
    }

    private var _bufferEmpty:Boolean;
    public function get bufferEmpty():Boolean {
        return _bufferEmpty;
    }

    private var _cameraBroadcasting:Boolean = false;
    public function set cameraBroadcasting(value:Boolean):void {
        _cameraBroadcasting = value;
    }

    public function get cameraBroadcasting():Boolean {
        return _cameraBroadcasting;
    }

    private var _append:Boolean = false;
    public function get append():Boolean {
        return _append;
    }

    public function set append(value:Boolean):void {
        _append = value;
    }

    public function get dimensions():Object {
        var normalAspectRatio:Boolean = aspectRatio == VideoBase.STRETCH_SCREEN;
        var width:uint = normalAspectRatio ? UIVideoDisplay.STRETCH_SCREEN_RECORDING_WIDTH : UIVideoDisplay.WIDE_SCREEN_RECORDING_WIDTH;
        var height:uint = normalAspectRatio ? UIVideoDisplay.STRETCH_SCREEN_RECORDING_HEIGHT : UIVideoDisplay.WIDE_SCREEN_RECORDING_HEIGHT;
        return {"width":width, "height":height};
    }

    /**
     * CLASS METHODS
     */

    public function updateLayout():void {
        data._layoutCallbackHandler();
    }

    public function resize(w:Number, h:Number):void {
        _videoDisplay.width = w;
        _videoDisplay.height = h;
    }

    public function attachCamera():void {
    }

    public function unAttachCamera():void {
    }

    public function destroy():void {
        log("performing cleanup");
        _videoDisplay.destroy();
        _stream.removeEventListener(NetStatusEvent.NET_STATUS, handleNetStreamStatus);
        if (_stream != null) {
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
            _stream.client = client;
            onMetaData = metaDataHandler;
            onCuePoint = cuePointHandler;
            onPlayStatus = playStatusHandler;
            onTimeCoordInfo = handleTimeCoordInfo;
            onLastSecond = handleLastSecond;
            _stream.bufferTime = bufferTime;
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
        log("building UIVideoDisplay");
        if (!_videoDisplay) {
            _videoDisplay = new UIVideoDisplay();
            _videoDisplay.dimensions = dimensions;
            _videoDisplay.addEventListener(VideoEvent.STATE_CHANGE, videoDisplayStateChange);
            this.addElement(_videoDisplay);
            // Attach net stream
            _videoDisplay.netStream = _stream;
            // Ready to update layout
            updateLayout();
        }
    }

    protected function log(msg:String):void {
        if (data._logCallbackHandler == null) {
            return;
        }
        data._logCallbackHandler('VideoBase :: '.concat(msg));
    }

    /**
     * EVENT HANDLERS
     */

    protected function handleNetStreamStatus(event:NetStatusEvent):void {
        _status = event.info.code;
        switch (_status) {
            case BUFFER_FLUSH:
                _bufferEmpty = true;
                break;
            case BUFFER_FULL:
                _bufferEmpty = false;
                break;
            case BUFFER_EMPTY:
                // ignore
                break;
            default:
                log("netstream status: ".concat(_status));
                break;
        }
    }

    protected function videoDisplayStateChange(event:VideoEvent):void {
        log("VideoEvent received\n".concat("Render State : ", event.state));
        updateLayout();
    }

    protected function asyncStreamErrorHandler(event:AsyncErrorEvent):void {
        _stream.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncStreamErrorHandler);
    }

    protected function IOStreamErrorHandler(event:IOErrorEvent):void {
        _stream.removeEventListener(IOErrorEvent.IO_ERROR, IOStreamErrorHandler);
    }

    protected function seekCompleteHandler(event:Event):void {
        seekTimer.removeEventListener(SeekTimer.COMPLETE, seekCompleteHandler);
    }

    /**
     * CALLBACK HANDLERS
     */

    protected function metaDataHandler(meta:Object):void {
        if (_duration === meta.duration) {
            return;
        }
        data._metaDataReceived(meta);
        _duration = meta.duration;
        for (var propName:String in meta) {
            log("Meta data: ".concat(propName, " = ", meta[propName]));
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



