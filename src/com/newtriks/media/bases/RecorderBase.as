/**
 * Created by IntelliJ IDEA.
 * User: development
 * Date: 14/12/2011
 * Time: 20:17
 * To change this template use File | Settings | File Templates.
 */
package com.newtriks.media.bases
{
import com.newtriks.enums.MediaStateEnum;
import com.newtriks.media.*;
import com.newtriks.media.core.VideoBase;
import com.newtriks.media.core.interfaces.IVideoContainer;
import com.newtriks.media.flex.containers.MediaContainer;
import com.newtriks.media.interfaces.IMediaBase;
import com.newtriks.utils.CountdownTimer;

import flash.events.Event;
import flash.net.NetConnection;
import flash.net.NetStream;

import org.osflash.signals.Signal;

public class RecorderBase implements IMediaBase
{
    public function RecorderBase()
    {
    }

    //**********
    //  Signals
    //**********
    private var _mediaStatus:Signal;
    public function get mediaStatus():Signal
    {
        return _mediaStatus||=new Signal(MediaStateEnum);
    }

    private var _mediaTypeSignal:Signal;
    public function get mediaTypeSignal():Signal
    {
        return _mediaTypeSignal||=new Signal(String);
    }

    private var _storeStream:Signal;
    public function get storeStream():Signal
    {
        return _storeStream||=new Signal(String);
    }

    private var _timeLimitCurrentCountSignal:Signal;
    public function get timeLimitCurrentCountSignal():Signal
    {
        return _timeLimitCurrentCountSignal||=new Signal(int);
    }

    private var _countdownCountSignal:Signal;
    public function get countdownCountSignal():Signal
    {
        return _countdownCountSignal||=new Signal(int);
    }

    private var _cameraLoadedSignal:Signal;
    public function get cameraLoadedSignal():Signal
    {
        return _cameraLoadedSignal||=new Signal(Boolean);
    }

    private var _cameraAccessDeniedSignal:Signal;
    public function get cameraAccessDeniedSignal():Signal
    {
        return _cameraAccessDeniedSignal||=new Signal();
    }

    private var _streamName:String;

    //******
    //  API
    //******
    private var _container:IVideoContainer;
    public function get container():IVideoContainer
    {
        return _container;
    }

    public function set container(value:IVideoContainer):void
    {
        _container=value;
    }

    public function set netconnection(value:NetConnection):void
    {
        _netconnection=value;
        setMediaConnection(value);
    }

    private var _netconnection:NetConnection;
    public function get netconnection():NetConnection
    {
        return _netconnection;
    }

    public function get streamTime():Number
    {
        return stream.time;
    }

    public function get streamName():String
    {
        return container.video.streamName;
    }

    public function startRecording(streamName:String=""):void
    {
        _streamName=streamName;
        if(!container.countdown)
            MediaContainer(container).publish(_streamName);
        else
            startRecordingCountdownTimer();
    }

    public function stopRecording():void
    {
        MediaContainer(container).unpublish();
        if(container.countdown) stopRecordingCountdownTimer();
    }

    public function broadcastCamera(useVideo:Boolean):void
    {
        if(container.video==null)
        {
            return;
        }
        if(useVideo)
        {
            container.video.attachCamera();
        }
        else
        {
            container.video.unAttachCamera();
        }
    }

    public function audioOnly(value:Boolean):void
    {
        broadcastCamera(!value);
        MediaContainer(container).visible=!value;
    }

    //***************************
    //  Internal Getters/Setters
    //***************************
    protected function set currentMediaStatus(value:MediaStateEnum):void
    {
        mediaStatus.dispatch(value);
    }

    protected function get stream():NetStream
    {
        return container.video.stream;
    }

    //****************
    //  Class Methods
    //****************
    protected function setMediaConnection(nc:NetConnection):void
    {
        log("Building Recorder UI...");
        container.baseType=VideoBase.RECORDER;
        container.addEventListener(MediaBase.VIDEO, handleAudioOnly);
        container.addEventListener(MediaBase.AUDIO, handleAudioOnly);
        container.addEventListener(MediaBase.STOP, handleRecordingStopped);
        container.addEventListener(MediaBase.START, handleRecordingStarted);
        container.addEventListener(MediaBase.CAMERA_LOADED, handleCameraLoaded);
        container.addEventListener(MediaBase.CAMERA_ERROR, handleCameraError);
        container.addEventListener(MediaBase.CAMERA_ACCESS_DENIED, handleCameraAccessDenied);
        // Set NetConnection, component builds on success
        container.connection=nc;
    }

    protected function handleAudioOnly(event:Event):void
    {
        mediaTypeSignal.dispatch(event.type);
    }

    /**
     * Time limit countdown
     */
    private var timeLimitCountdown:CountdownTimer;

    protected function startTimeLimitTimer():void
    {
        timeLimitCountdown=new CountdownTimer();
        timeLimitCountdown.addEventListener(CountdownTimer.COUNT, timeLimitCountdownHandler);
        timeLimitCountdown.addEventListener(CountdownTimer.COMPLETE, timeLimitCountdownCompleteHandler);
        timeLimitCountdown.startCountDown(container.timeLimit, 1000);
    }

    protected function stopTimeLimitTimer():void
    {
        timeLimitCountdown.removeEventListener(CountdownTimer.COUNT, timeLimitCountdownHandler);
        timeLimitCountdown.removeEventListener(CountdownTimer.COMPLETE, timeLimitCountdownCompleteHandler);
        timeLimitCountdown.stopCountDown();
    }

    /**
     * Start recording countdown
     */
    private var recordingCountdownTimer:CountdownTimer;

    protected function startRecordingCountdownTimer():void
    {
        recordingCountdownTimer=new CountdownTimer();
        recordingCountdownTimer.addEventListener(CountdownTimer.COUNT, recordingCountdownHandler);
        recordingCountdownTimer.addEventListener(CountdownTimer.COMPLETE, recordingCountdownCompleteHandler);
        recordingCountdownTimer.startCountDown(container.countdown, 1000);
    }

    protected function stopRecordingCountdownTimer():void
    {
        recordingCountdownTimer.removeEventListener(CountdownTimer.COUNT, recordingCountdownHandler);
        recordingCountdownTimer.removeEventListener(CountdownTimer.COMPLETE, recordingCountdownCompleteHandler);
        recordingCountdownTimer.stopCountDown();
    }

    //*****************
    //  Event Handlers
    //*****************
    protected function handleRecordingStarted(event:Event):void
    {
        currentMediaStatus=MediaStateEnum.RecordStarted;
        storeStream.dispatch(MediaContainer(container).streamName);
        if(container.timeLimit)
        {
            startTimeLimitTimer();
        }
        log("Started recording: "+MediaContainer(container).streamName+" time limit: "+container.timeLimit);
    }

    protected function handleRecordingStopped(event:Event):void
    {
        currentMediaStatus=MediaStateEnum.RecordStopped;
        if(container.timeLimit)
        {
            stopTimeLimitTimer();
        }
    }

    protected function handleCameraLoaded(event:Event):void
    {
        cameraLoadedSignal.dispatch(true);
    }

    protected function handleCameraError(event:Event):void
    {
        cameraLoadedSignal.dispatch(false);
    }

    protected function handleCameraAccessDenied(event:Event):void
    {
        cameraAccessDeniedSignal.dispatch();
    }

    protected function timeLimitCountdownHandler(event:Event):void
    {
        timeLimitCurrentCountSignal.dispatch(timeLimitCountdown.count);
    }

    protected function timeLimitCountdownCompleteHandler(event:Event):void
    {
        MediaContainer(container).unpublish();
        stopTimeLimitTimer();
    }

    protected function recordingCountdownHandler(event:Event):void
    {
        countdownCountSignal.dispatch(recordingCountdownTimer.count);
        if(recordingCountdownTimer.count==1) MediaContainer(container).publish(_streamName);
    }

    protected function recordingCountdownCompleteHandler(event:Event):void
    {
        stopRecordingCountdownTimer();
    }

    //******************
    //  Log
    //******************
    protected function log(val:Object):void
    {
        MediaContainer(container).logHandler(val.toString());
    }
}
}
