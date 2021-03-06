/**
 * Created by IntelliJ IDEA.
 * User: development
 * Date: 14/12/2011
 * Time: 20:17
 * To change this template use File | Settings | File Templates.
 */
package com.newtriks.media.bases {
import com.newtriks.enums.MediaStateEnum;
import com.newtriks.media.core.MediaBase;
import com.newtriks.media.core.MediaBaseConfiguration;
import com.newtriks.utils.CountdownTimer;

import flash.events.Event;
import flash.events.NetStatusEvent;
import flash.net.NetConnection;

import org.osflash.signals.Signal;

public class RecorderBase extends MediaBase {
    public function RecorderBase(configuration:MediaBaseConfiguration) {
        baseType = MediaBase.RECORDER;
        configuration.client(this);
        super(configuration);
    }

    //**********
    //  Signals
    //**********
    private var _mediaStatus:Signal;
    public function get mediaStatus():Signal {
        return _mediaStatus ||= new Signal(MediaStateEnum);
    }

    private var _mediaTypeSignal:Signal;
    public function get mediaTypeSignal():Signal {
        return _mediaTypeSignal ||= new Signal(String);
    }

    private var _storeStream:Signal;
    public function get storeStream():Signal {
        return _storeStream ||= new Signal(String);
    }

    private var _timeLimitCurrentCountSignal:Signal;
    public function get timeLimitCurrentCountSignal():Signal {
        return _timeLimitCurrentCountSignal ||= new Signal(int);
    }

    private var _countdownCountSignal:Signal;
    public function get countdownCountSignal():Signal {
        return _countdownCountSignal ||= new Signal(int);
    }

    private var _cameraLoadedSignal:Signal;
    public function get cameraLoadedSignal():Signal {
        return _cameraLoadedSignal ||= new Signal(Boolean);
    }

    private var _cameraAccessDeniedSignal:Signal;
    public function get cameraAccessDeniedSignal():Signal {
        return _cameraAccessDeniedSignal ||= new Signal();
    }

    private var _bufferFlushStatusSignal:Signal;
    public function get bufferFlushStatusSignal():Signal {
        return _bufferFlushStatusSignal ||= new Signal(String, Number);
    }

    //******
    //  API
    //******
    override public function set connection(value:NetConnection):void {
        super.connection = value;
        setMediaConnection();
    }

    public function startRecording(_streamName:String = ""):void {
        streamName = _streamName;
        if (!countdown)
            publish(streamName);
        else
            startRecordingCountdownTimer();
    }

    override public function unpublish():void {
        super.unpublish();
        if (countdown) stopRecordingCountdownTimer();
    }

    override protected function stopRecording():void {
        super.stopRecording();
        if (countdown) stopRecordingCountdownTimer();
    }

    public function broadcastCamera(useVideo:Boolean):void {
        if (video == null) {
            return;
        }
        if (useVideo) {
            attachCamera();
        }
        else {
            unAttachCamera();
        }
    }

    public function audioOnly(value:Boolean):void {
        broadcastCamera(!value);
        container.visible = !value;
    }

    public function loadSpecificCamera(index:String):void {
        attachCamera(index);
    }

    public function loadSpecificMicrophone(index:int):void {
        setupMicrophone(index);
    }

    override public function destroy():void {
        super.destroy();
        container.removeEventListener(VIDEO, handleAudioOnly);
        container.removeEventListener(AUDIO, handleAudioOnly);
        container.removeEventListener(STOP, handleRecordingStopped);
        container.removeEventListener(START, handleRecordingStarted);
        container.removeEventListener(CAMERA_LOADED, handleCameraLoaded);
        container.removeEventListener(CAMERA_ERROR, handleCameraError);
        container.removeEventListener(CAMERA_ACCESS_DENIED, handleCameraAccessDenied);
        container.removeEventListener(BUFFER_FLUSH_START, handleBufferStatus);
        container.removeEventListener(BUFFER_FLUSHING, handleBufferStatus);
        container.removeEventListener(BUFFER_FLUSH_COMPLETE, handleBufferStatus);
    }

    //***************************
    //  Internal Getters/Setters
    //***************************
    protected function set currentMediaStatus(value:MediaStateEnum):void {
        mediaStatus.dispatch(value);
    }

    //************
    //  Overrides
    //************

    override protected function handleNetStreamStatus(event:NetStatusEvent):void {
        super.handleNetStreamStatus(event);
        var status:String = event.info.code;
        switch (status) {
            case UNPUBLISHED:
                log("Recording successfully written data");
                /**
                 * Flash client has problem when you try to reuse a
                 * NetStream object to publish core and it tends to
                 * generate an errant core/audio packet with a large
                 * time code.  So need to create a new stream each time
                 * we publish.  Wait till we have this event from the
                 * old netstream first. STOP event below will destroy
                 * and perform cleanup!
                 */
                dispatchEvent(new Event(STOP, true));
                break;
        }
    }

    //****************
    //  Class Methods
    //****************
    protected function setMediaConnection():void {
        container.addEventListener(VIDEO, handleAudioOnly);
        container.addEventListener(AUDIO, handleAudioOnly);
        container.addEventListener(STOP, handleRecordingStopped);
        container.addEventListener(START, handleRecordingStarted);
        container.addEventListener(CAMERA_LOADED, handleCameraLoaded);
        container.addEventListener(CAMERA_ERROR, handleCameraError);
        container.addEventListener(CAMERA_ACCESS_DENIED, handleCameraAccessDenied);
        container.addEventListener(BUFFER_FLUSH_START, handleBufferStatus);
        container.addEventListener(BUFFER_FLUSHING, handleBufferStatus);
        container.addEventListener(BUFFER_FLUSH_COMPLETE, handleBufferStatus);
    }

    protected function handleAudioOnly(event:Event):void {
        mediaTypeSignal.dispatch(event.type);
    }

    /**
     * Time limit countdown
     */
    private var timeLimitCountdown:CountdownTimer;

    protected function startTimeLimitTimer():void {
        timeLimitCountdown = new CountdownTimer();
        timeLimitCountdown.addEventListener(CountdownTimer.COUNT, timeLimitCountdownHandler);
        timeLimitCountdown.addEventListener(CountdownTimer.COMPLETE, timeLimitCountdownCompleteHandler);
        timeLimitCountdown.startCountDown(timeLimit, 1000);
    }

    protected function stopTimeLimitTimer():void {
        if(timeLimitCountdown==null) return;
        timeLimitCountdown.removeEventListener(CountdownTimer.COUNT, timeLimitCountdownHandler);
        timeLimitCountdown.removeEventListener(CountdownTimer.COMPLETE, timeLimitCountdownCompleteHandler);
        timeLimitCountdown.stopCountDown();
        timeLimitCountdown = null;
    }

    /**
     * Start recording countdown
     */
    private var recordingCountdownTimer:CountdownTimer;

    protected function startRecordingCountdownTimer():void {
        recordingCountdownTimer = new CountdownTimer();
        recordingCountdownTimer.addEventListener(CountdownTimer.COUNT, recordingCountdownHandler);
        recordingCountdownTimer.addEventListener(CountdownTimer.COMPLETE, recordingCountdownCompleteHandler);
        recordingCountdownTimer.startCountDown(countdown, 1000);
    }

    protected function stopRecordingCountdownTimer():void {
        if(recordingCountdownTimer==null) return;
        recordingCountdownTimer.removeEventListener(CountdownTimer.COUNT, recordingCountdownHandler);
        recordingCountdownTimer.removeEventListener(CountdownTimer.COMPLETE, recordingCountdownCompleteHandler);
        recordingCountdownTimer.stopCountDown();
    }

    //*****************
    //  Event Handlers
    //*****************
    protected function handleRecordingStarted(event:Event):void {
        currentMediaStatus = MediaStateEnum.RecordStarted;
        storeStream.dispatch(streamName);
        if (timeLimit) {
            startTimeLimitTimer();
        }
        log("Started recording: " + streamName + " time limit: " + timeLimit);
    }

    protected function handleRecordingStopped(event:Event):void {
        currentMediaStatus = MediaStateEnum.RecordStopped;
        if (timeLimit && timeLimitCountdown) {
            stopTimeLimitTimer();
        }
        destroy();
    }

    protected function handleCameraLoaded(event:Event):void {
        cameraLoadedSignal.dispatch(true);
    }

    protected function handleCameraError(event:Event):void {
        cameraLoadedSignal.dispatch(false);
    }

    protected function handleCameraAccessDenied(event:Event):void {
        cameraAccessDeniedSignal.dispatch();
    }

    protected function timeLimitCountdownHandler(event:Event):void {
        timeLimitCurrentCountSignal.dispatch(timeLimitCountdown.count);
    }

    protected function timeLimitCountdownCompleteHandler(event:Event):void {
        unpublish();
        stopTimeLimitTimer();
    }

    protected function recordingCountdownHandler(event:Event):void {
        countdownCountSignal.dispatch(recordingCountdownTimer.count);
    }

    protected function recordingCountdownCompleteHandler(event:Event):void {
        recordingCountdownTimer = null;
        publish(streamName);
    }

    protected function handleBufferStatus(event:Event):void {
        bufferFlushStatusSignal.dispatch(event.type, stream.bufferLength);
    }
}
}
