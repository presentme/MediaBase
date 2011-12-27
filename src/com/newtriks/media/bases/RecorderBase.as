/**
 * Created by IntelliJ IDEA.
 * User: development
 * Date: 14/12/2011
 * Time: 20:17
 * To change this template use File | Settings | File Templates.
 */
package com.newtriks.media.bases {
import com.newtriks.enums.MediaStateEnum;
import com.newtriks.media.*;
import com.newtriks.media.core.VideoBase;
import com.newtriks.media.core.interfaces.IVideoContainer;
import com.newtriks.media.flex.containers.MediaContainer;
import com.newtriks.media.interfaces.IMediaBase;

import flash.events.Event;
import flash.net.NetConnection;
import flash.net.NetStream;

import org.osflash.signals.Signal;

public class RecorderBase implements IMediaBase {

    public function RecorderBase() {
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

    //******
    //  API
    //******

    private var _container:IVideoContainer;

    public function get container():IVideoContainer {
        return _container;
    }

    public function set container(value:IVideoContainer):void {
        _container = value;
    }

    public function set netconnection(value:NetConnection):void {
        _netconnection = value;
        setMediaConnection(value);
    }

    private var _netconnection:NetConnection;
    public function get netconnection():NetConnection {
        return _netconnection;
    }

    public function get streamTime():Number {
        return stream.time;
    }

    public function get streamName():String {
        return container.video.streamName;
    }

    public function startRecording():void {
        MediaContainer(container).publish();
    }

    public function stopRecording():void {
        MediaContainer(container).unpublish();
    }

    public function broadcastCamera(useVideo:Boolean):void {
        if (container.video == null) return;
        if (useVideo)
            container.video.attachCamera();
        else
            container.video.unAttachCamera();
    }

    public function audioOnly(value:Boolean):void {
        broadcastCamera(!value);
        MediaContainer(container).visible = !value;
    }

    //***************************
    //  Internal Getters/Setters
    //***************************
    protected function set currentMediaStatus(value:MediaStateEnum):void {
        mediaStatus.dispatch(value);
    }

    public function get stream():NetStream {
        return container.video.stream;
    }

    //****************
    //  Class Methods
    //****************

    protected function setMediaConnection(nc:NetConnection):void {
        log("Building Recorder UI...");
        container.baseType = VideoBase.RECORDER;
        // Set NetConnection, component builds on success
        container.connection = nc;
        container.addEventListener(MediaBase.VIDEO, handleAudioOnly);
        container.addEventListener(MediaBase.AUDIO, handleAudioOnly);
        container.addEventListener(MediaBase.STOP, handleRecordingStopped);
        container.addEventListener(MediaBase.START, handleRecordingStarted);
        container.addEventListener(MediaBase.CAMERA_LOADED, handleCameraLoaded);
        container.addEventListener(MediaBase.CAMERA_ERROR, handleCameraError);
    }

    protected function handleAudioOnly(event:Event):void {
        mediaTypeSignal.dispatch(event.type);
    }

    //*****************
    //  Event Handlers
    //*****************

    protected function handleRecordingStarted(event:Event):void {
        currentMediaStatus = MediaStateEnum.RecordStarted;
        storeStream.dispatch(MediaContainer(container).streamName);
        log("Started recording: " + MediaContainer(container).streamName);
    }

    protected function handleRecordingStopped(event:Event):void {
        currentMediaStatus = MediaStateEnum.RecordStopped;
    }

    protected function handleCameraLoaded(event:Event):void {
        // Not much to do here at the moment
    }

    protected function handleCameraError(event:Event):void {
        // Not much to do here at the moment
    }

    //******************
    //  Log
    //******************
    protected function log(val:Object):void {
        MediaContainer(container).logHandler(val.toString());
    }
}
}
