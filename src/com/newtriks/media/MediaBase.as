/*
 * Copyright (c) 2011 Simon Bailey <simon@newtriks.com>
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement located at the
 * following url: http://www.newtriks.com/LICENSE.html
 */
package com.newtriks.media
{
import com.newtriks.media.core.VideoBase;
import com.newtriks.media.core.VideoConfigurationVO;
import com.newtriks.utils.CreateUUID;

import flash.events.ActivityEvent;
import flash.events.Event;
import flash.events.NetStatusEvent;
import flash.events.StatusEvent;
import flash.media.Camera;
import flash.media.Microphone;
import flash.media.SoundCodec;
import flash.utils.clearInterval;
import flash.utils.setInterval;

public class MediaBase extends VideoBase
{
    public static const READY:String="MediaBase::READY";
    public static const TOGGLE:String="Recorder::TOGGLE";
    public static const START:String="Recorder::START";
    public static const STOP:String="Recorder::STOP";
    public static const VIDEO:String="Recorder::VIDEO";
    public static const AUDIO:String="Recorder::AUDIO";
    public static const CAMERA_LOADED:String="Recorder::CAMERA_LOADED";
    public static const CAMERA_ERROR:String="Recorder::CAMERA_ERROR";
    public static const CAMERA_ACCESS_DENIED:String="Recorder::CAMERA_ACCESS_DENIED";
    public static const END:String="Player::END";
    public static const PLAY_START:String="Player::START";
    public static const SEEK_COMPLETE:String="Player::SEEK_COMPLETE";
    public static const STREAM_ERROR:String="Player::ERROR";
    private var _camera:Camera;
    private var _microphone:Microphone;
    private var _cameraBroadcasting:Boolean;
    private var _flushVideoBufferTimer:Number=0;

    public function MediaBase(configuration:VideoConfigurationVO)
    {
        if(configuration.client==null)
        {
            configuration.client(this);
        }
        super(configuration);
        init();
    }

    /**
     * GETTERS & SETTERS
     */

    override public function get cameraBroadcasting():Boolean
    {
        return _cameraBroadcasting;
    }

    override public function set cameraBroadcasting(value:Boolean):void
    {
        if(_cameraBroadcasting==value)
        {
            return;
        }
        _cameraBroadcasting=value;
        log("camera broadcasting: ".concat(value));
        var type:String=(_cameraBroadcasting)?VIDEO:AUDIO;
        dispatchEvent(new Event(type, true));
    }

    /**
     * PARENT OVERRIDES
     */

    override protected function buildVideoDisplay():void
    {
        super.buildVideoDisplay();
        dispatchEvent(new Event(MediaBase.READY, true));
        if(baseType!=VideoBase.RECORDER)
        {
            resize(this.width, this.height);
        }
        else
        {
            attachCamera();
            setupMicrophone();
        }
    }

    override protected function handleNetStreamStatus(event:NetStatusEvent):void
    {
        super.handleNetStreamStatus(event);
        switch(status)
        {
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
                if(autoReload)
                {
                    buildNewStream();
                }
                else
                {
                    destroy();
                }
                // Dispatch to switch state and perform cleanup
                dispatchEvent(new Event(MediaBase.STOP, true));
                break;
            /*case STOPPED:*/
            case COMPLETE:
                dispatchEvent(new Event(MediaBase.END, true));
                break;
            case STOPPED:
                if(stream.bufferLength<=stream.bufferTime)
                {
                    //dispatchEvent(new Event(MediaBase.END, true));
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
            case BUFFER_FULL:
                stream.bufferTime=15;
                break;
            case BUFFER_EMPTY:
                stream.bufferTime=2; // Todo
                break;
        }
    }

    override protected function seekCompleteHandler(event:Event):void
    {
        super.seekCompleteHandler(event);
        this.dispatchEvent(new Event(SEEK_COMPLETE, true));
    }

    override public function destroy():void
    {
        disconnectCameraAndMicrophone();
        unAttachCamera();
        super.destroy();
    }

    /**
     * CLASS METHODS
     */

    protected function get camDimensions():Object
    {
        if(camWidth)
        {
            return {width:camWidth, height:camHeight};
        }
        return {width:dimensions.width, height:dimensions.height};
    }

    override public function attachCamera(index:String=""):void
    {
        log("setting up camera "+index);
        if(!_camera)
        {
            try
            {
                if(index.length) _camera=Camera.getCamera(index);
                else _camera=Camera.getCamera();

                if(_camera)
                {
                    _camera.setMode(camDimensions.width, camDimensions.height, fps, false);
                    _camera.setQuality(bandwidth, quality);
                    _camera.setKeyFrameInterval(fps);
                    if(_camera.muted)
                    {
                        _camera.addEventListener(StatusEvent.STATUS, statusHandler);
                        this.dispatchEvent(new Event(MediaBase.CAMERA_ERROR, true));
                        log("Error > camera muted");
                        return;
                    }
                    cameraBroadcasting=true;
                    attachCameraToDisplay();
                    log("success > camera setup");
                    _camera.addEventListener(ActivityEvent.ACTIVITY, firstCameraActivity);
                }
                else
                {
                    dispatchEvent(new Event(MediaBase.CAMERA_ERROR, true));
                }
            }
            catch(error:Error)
            {
                log(String(error));
                cameraBroadcasting=false;
                dispatchEvent(new Event(MediaBase.CAMERA_ERROR, true));
            }
        }
        else if(!_isRecording)
        {
            unAttachCamera();
            attachCamera(index);
        }
    }

    override public function unAttachCamera():void
    {
        if(display)
        {
            display.detachCamera();
        }
        cameraBroadcasting=false;
        _camera=null;
    }

    override public function setupMicrophone(index:int=-1):void
    {
        if(_isRecording) return;
        log("setting up microphone");
        try
        {
            if(index>=0) _microphone=Microphone.getMicrophone(index);
            else _microphone=Microphone.getMicrophone();
            /**
             * Speex is generally preferred over Nellymoser
             * but FFMPeg doesn't like it
             */
            _microphone.codec=SoundCodec.NELLYMOSER;
            _microphone.rate=microphoneRate;					// set audio to a more than average quality
            _microphone.setSilenceLevel(microphoneSilenceLevel); 		// prevent mic from cutting sound off when no sound is detected
            log("success > microphone setup");
        }
        catch(error:Error)
        {
            log("error > microphone: ".concat(String(error)));
        }
    }

    protected function attachCameraToDisplay():void
    {
        if(_camera!=null&&display!=null)
        {
            log("attaching camera to UIVideoDisplay");
            display.attachCamera(_camera);
        }
    }

    /*
     * We are injecting width and height metadata so that upon replay
     * the com.newtriks.editor can scale itself properly
     */
    protected function sendMetadata():void
    {
        var metaData:Object=new Object();
        metaData.title=streamName;
        metaData.width=camDimensions.width;
        metaData.height=camDimensions.height;
        metaData.hasKeyframes=true;
        metaData.hasMetadata=true;
        metaData.hasVideo=true;
        stream.send("@setDataFrame", "onMetaData", metaData);
    }

    public function publish(name:String):void
    {
        if(name=="")
        {
            streamName="stream_".concat(CreateUUID.createUUID());
        }
        else
        {
            streamName=name;
        }
        if(_microphone)
        {
            log("Attaching Microphone to NetStream");
            stream.attachAudio(_microphone);
        }
        if(_camera&&_cameraBroadcasting)
        {
            log("Attaching Camera to NetStream");
            stream.attachCamera(_camera);
        }
        if(_microphone||_camera)
        {
            log("Publishing recorded stream: ".concat(streamName));
            stream.publish(streamName, (append?"append":"record"));
        }
        dispatchEvent(new Event(MediaBase.START, true));
        _isRecording=true;
    }

    private var _isRecording:Boolean;

    public function unpublish():void
    {
        disconnectCameraAndMicrophone();
        var buffLen:Number=stream.bufferLength;
        if(buffLen>0)
        {
            _flushVideoBufferTimer=setInterval(flushVideoBuffer, 250);
            log("Flushing buffer.....");
        }
        else
        {
            stopRecording();
        }
    }

    protected function stopRecording():void
    {
        log("Stopping recording");
        stream.publish(null);
        _isRecording=false;
    }

    public function buildNewStream():void
    {
        super.connection=connection;
    }

    public function disconnectCameraAndMicrophone():void
    {
        if(!stream)
        {
            return;
        }
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
    protected function flushVideoBuffer():void
    {
        var buffLen:Number=stream.bufferLength;
        //trace("Buffer flushing, length:"+buffLen);
        if(!buffLen)
        {
            clearInterval(_flushVideoBufferTimer);
            _flushVideoBufferTimer=0;
            stopRecording();
        }
    }

    protected function statusHandler(event:StatusEvent):void
    {
        if(event.code=="Camera.Unmuted")
        {
            cameraBroadcasting=true;
            attachCameraToDisplay();
            _camera.addEventListener(ActivityEvent.ACTIVITY, firstCameraActivity);
            log("success > camera allowed and setup");
        }
        else
        {
            if(event.code=="Camera.Muted")
            {
                this.dispatchEvent(new Event(MediaBase.CAMERA_ACCESS_DENIED, true));
                log("error > camera denied");
            }
        }
    }

    protected function firstCameraActivity(event:ActivityEvent):void
    {
        this.dispatchEvent(new Event(MediaBase.CAMERA_LOADED, true));
        _camera.removeEventListener(ActivityEvent.ACTIVITY, firstCameraActivity);
    }
}
}
