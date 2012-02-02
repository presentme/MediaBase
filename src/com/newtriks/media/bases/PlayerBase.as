/**
 * Created by IntelliJ IDEA.
 * User: development
 * Date: 14/12/2011
 * Time: 20:18
 * To change this template use File | Settings | File Templates.
 */
package com.newtriks.media.bases
{
import com.newtriks.enums.MediaStateEnum;
import com.newtriks.media.MediaBase;
import com.newtriks.media.core.VideoBase;
import com.newtriks.media.core.interfaces.IVideoContainer;
import com.newtriks.media.flex.containers.MediaContainer;
import com.newtriks.media.interfaces.IPlayerBase;
import com.newtriks.utils.NumberUtil;

import flash.events.Event;
import flash.net.NetConnection;
import flash.net.NetStream;

import org.osflash.signals.Signal;

public class PlayerBase implements IPlayerBase
{
    private var _cueSeek:Number;
    private var _streamName:String;

    public function PlayerBase()
    {
        _streamName="";
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

    private var _currentPlaybackTime:Signal;
    public function get currentPlaybackTime():Signal
    {
        return _currentPlaybackTime||=new Signal(Number);
    }

    private var _streamError:Signal;
    public function get streamError():Signal
    {
        return _streamError||=new Signal();
    }

    private var _streamDuration:Signal;
    public function get streamDuration():Signal
    {
        return _streamDuration||=new Signal(Number);
    }

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
        _container.metaDataHandler=updatedMeta;
        _container.addEventListener(MediaBase.READY, handleReady);
    }

    public function set netconnection(value:NetConnection):void
    {
        _netconnection=value;
        if(value==null)
        {
            removePlayHandlers();
        }
        setMediaConnection(value);
    }

    private var _netconnection:NetConnection;
    public function get netconnection():NetConnection
    {
        return _netconnection;
    }

    private var _autoplay:Boolean;
    public function get autoplay():Boolean
    {
        return _autoplay;
    }

    public function set autoplay(value:Boolean):void
    {
        _autoplay=value;
    }

    private var _duration:Number;
    public function set duration(time:Number):void
    {
        _duration=time;
        streamDuration.dispatch(time);
    }

    public function get streamTime():Number
    {
        return stream.time;
    }

    public function get streamName():String
    {
        return container.video.streamName;
    }

    public function startPlaying(url:String, cue:Number=-1):void
    {
        currentPlaybackTime.dispatch(cue);
        _cueSeek=cue;
        try
        {
            if(container.video.streamName!=url)
            {
                seekAsynchronous(url);
            }
            else
            {
                seekSynchronous();
            }
        }
        catch(error:Error)
        {
            _streamName=url;
        }
    }

    public function pausePlaying():void
    {
        if(container.video==null) return;
        container.video.pause();
        removePlayHandlers();
        currentMediaStatus=MediaStateEnum.PlaybackPaused;
    }

    public function audioOnly(value:Boolean):void
    {
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
        log("Building Player UI...");
        container.baseType=VideoBase.PLAYER;
        // Set NetConnection, component builds on success
        container.connection=nc;
    }

    protected function setFirstPlaybackStartPosition():void
    {
        if(!_cueSeek&&!streamTime)
        {
            return;
        }
        else
        {
            if(_cueSeek==0)
            {
                resumeStream();
                return;
            }
            else
            {
                if(_cueSeek==-1)
                {
                    pausePlaying();
                    return;
                }
            }
        }
        seek(_cueSeek);
    }

    protected function seekAsynchronous(url:String):void
    {
        loadStream(url);
    }

    protected function seekSynchronous():void
    {
        if(_cueSeek==-1)
        {
            resumeStream();
            return;
        }
        container.video.pause();
        seek(_cueSeek);
    }

    protected function loadStream(url:String):void
    {
        try
        {
            container.video.play(url);
            addPlayHandlers();
        }
        catch(error:Error)
        {
            streamErrorHandler(null);
        }
    }

    protected function resumeStream():void
    {
        container.video.resume();
        addPlayHandlers();
    }

    public function seek(time:Number):void
    {
        _cueSeek=time;
        trace("Seek to: ".concat(time, " and play till: ", this._duration));
        container.addEventListener(MediaBase.SEEK_COMPLETE, seekCompleteHandler);
        container.video.seek(time);
    }

    protected function stopPlaying():void
    {
        if(MediaContainer(container).stage==null)
        {
            return;
        }
        removePlayHandlers(true);
        container.video.seek(0);
    }

    protected function dispatchCurrentTime():void
    {
        currentPlaybackTime.dispatch(streamTime);
    }

    protected function addPlayHandlers():void
    {
        MediaContainer(container).removeEventListener(Event.ENTER_FRAME, handleCurrentStreamTime);
        container.addEventListener(MediaBase.PLAY_START, handleStreamStart);
        container.addEventListener(MediaBase.END, handleStreamEnd);
    }

    protected function removePlayHandlers(ended:Boolean=false):void
    {
        MediaContainer(container).stage.removeEventListener(Event.ENTER_FRAME, handleCurrentStreamTime);
        container.removeEventListener(MediaBase.PLAY_START, handleStreamStart);
        container.removeEventListener(MediaBase.END, handleStreamEnd);
        if(ended)
        {
            currentMediaStatus=MediaStateEnum.PlaybackStopped;
            container.video.pause();
            container.video.seek(0);
        }
    }

    // Helpers
    protected function get streamHasPlayedToEnd():Boolean
    {
        //trace("ENDED: "+NumberUtil.roundNumber(stream.time)+":"+NumberUtil.roundNumber(_duration)+"   "+Boolean(NumberUtil.roundNumber(stream.time)>=NumberUtil.roundNumber(_duration-0.1)));
        return Boolean(NumberUtil.roundNumber(stream.time)>=NumberUtil.roundNumber(_duration-0.1));
    }

    public function handleAudioOnly(event:Event):void
    {
        mediaTypeSignal.dispatch(event.type);
    }

    //*****************
    //  Callback Handlers
    //*****************
    protected function updatedMeta(val:Object):void
    {
        if(isNaN(_duration))
        {
            duration=val.duration;
        }
        setFirstPlaybackStartPosition();
    }

    //*****************
    //  Event Handlers
    //*****************
    protected function handleReady(event:Event):void
    {
        _container.removeEventListener(MediaBase.READY, handleReady);
        if(_streamName.length)
        {
            startPlaying(_streamName);
            _streamName="";
        }
    }

    protected function handleStreamStart(event:Event):void
    {
        currentMediaStatus=MediaStateEnum.PlaybackStarted;
        if(!MediaContainer(container).stage.hasEventListener(Event.ENTER_FRAME))
        {
            MediaContainer(container).stage.addEventListener(Event.ENTER_FRAME, handleCurrentStreamTime);
        }
        container.removeEventListener(MediaBase.PLAY_START, handleStreamStart);
    }

    protected function handleStreamEnd(event:Event):void
    {
        stopPlaying();
    }

    protected function handleCurrentStreamTime(event:Event):void
    {
        if(!streamHasPlayedToEnd)
        {
            dispatchCurrentTime();
            return;
        }
        log("Stream Ended: stream time = "+NumberUtil.roundNumber(stream.time)+" : duration = "+NumberUtil.roundNumber(_duration));
        stopPlaying();
    }

    protected function seekCompleteHandler(event:Event):void
    {
        container.removeEventListener(MediaBase.SEEK_COMPLETE, seekCompleteHandler);
        resumeStream();
    }

    protected function streamErrorHandler(event:Event):void
    {
        streamError.dispatch();
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
