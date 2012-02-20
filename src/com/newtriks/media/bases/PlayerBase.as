/**
 * Created by IntelliJ IDEA.
 * User: development
 * Date: 14/12/2011
 * Time: 20:18
 * To change this template use File | Settings | File Templates.
 */
package com.newtriks.media.bases {
import com.newtriks.enums.MediaStateEnum;
import com.newtriks.media.containers.MediaBaseContainer;
import com.newtriks.media.core.MediaBase;
import com.newtriks.media.core.MediaBaseConfiguration;
import com.newtriks.utils.NumberUtil;

import flash.events.Event;
import flash.net.NetConnection;

import org.osflash.signals.Signal;

public class PlayerBase extends MediaBase {
    private var _cueSeek:Number;

    public function PlayerBase(configuration:MediaBaseConfiguration) {
        baseType = MediaBase.PLAYER;
        configuration.metaDataReceived(updatedMeta);
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

    private var _currentPlaybackTime:Signal;
    public function get currentPlaybackTime():Signal {
        return _currentPlaybackTime ||= new Signal(Number);
    }

    private var _streamError:Signal;
    public function get streamError():Signal {
        return _streamError ||= new Signal();
    }

    private var _streamDuration:Signal;
    public function get streamDuration():Signal {
        return _streamDuration ||= new Signal(Number);
    }

    //******
    //  API
    //******
    override public function set container(value:MediaBaseContainer):void {
        super.container = value;
        container.addEventListener(MediaBase.READY, handleReady);
    }

    override public function set connection(value:NetConnection):void {
        super.connection = value;
        if (value == null) {
            removePlayHandlers();
        }
    }

    private var _autoplay:Boolean;
    public function get autoplay():Boolean {
        return _autoplay;
    }

    public function set autoplay(value:Boolean):void {
        _autoplay = value;
    }

    public function set duration(time:Number):void {
        streamDuration.dispatch(time);
    }

    public function startPlaying(url:String, cue:Number = -1):void {
        _cueSeek = cue;
        if (streamName != url) {
            seekAsynchronous(url);
        }
        else {
            if (streamHasPlayedToEnd) _cueSeek = 0;
            seekSynchronous();
        }
    }

    public function pausePlaying():void {
        if (video == null) return;
        pause();
        removePlayHandlers();
        currentMediaStatus = MediaStateEnum.PlaybackPaused;
    }

    public function audioOnly(value:Boolean):void {
        container.visible = !value;
    }

    //***************************
    //  Internal Getters/Setters
    //***************************
    protected function set currentMediaStatus(value:MediaStateEnum):void {
        mediaStatus.dispatch(value);
    }

    //****************
    //  Class Methods
    //****************
    protected function setFirstPlaybackStartPosition():void {
        if (!_cueSeek && !time) {
            return;
        }
        else {
            if (_cueSeek == 0) {
                resumeStream();
                return;
            }
            else {
                if (_cueSeek == -1) {
                    pausePlaying();
                    return;
                }
            }
        }
        seek(_cueSeek);
    }

    protected function seekAsynchronous(url:String):void {
        loadStream(url);
    }

    protected function seekSynchronous():void {
        if (_cueSeek == -1) {
            resumeStream();
            return;
        }
        pause();
        seek(_cueSeek);
    }

    protected function loadStream(url:String):void {
        try {
            play(url, 0.1);
            addPlayHandlers();
        }
        catch (error:Error) {
            streamErrorHandler(null);
        }
    }

    protected function resumeStream():void {
        resume();
        addPlayHandlers();
    }

    protected function stopPlaying():void {
        if (container.stage == null) {
            return;
        }
        removePlayHandlers(true);
        seek(0);
    }

    protected function dispatchCurrentTime():void {
        currentPlaybackTime.dispatch(time);
    }

    protected function addPlayHandlers():void {
        container.removeEventListener(Event.ENTER_FRAME, handleCurrentStreamTime);
        container.addEventListener(MediaBase.PLAY_START, handleStreamStart);
        container.addEventListener(MediaBase.END, handleStreamEnd);
    }

    protected function removePlayHandlers(ended:Boolean = false):void {
        container.stage.removeEventListener(Event.ENTER_FRAME, handleCurrentStreamTime);
        container.removeEventListener(MediaBase.PLAY_START, handleStreamStart);
        container.removeEventListener(MediaBase.END, handleStreamEnd);
        if (ended) {
            currentMediaStatus = MediaStateEnum.PlaybackStopped;
            pause();
            seek(0);
        }
    }

    // Helpers
    protected function get streamHasPlayedToEnd():Boolean {
        //trace("ENDED: "+NumberUtil.roundNumber(time)+":"+NumberUtil.roundNumber(duration)+"   "+Boolean(NumberUtil.roundNumber(time)>=NumberUtil.roundNumber(duration-0.1)));
        return Boolean(NumberUtil.roundNumber(time) >= NumberUtil.roundNumber(duration - 0.1));
    }

    public function handleAudioOnly(event:Event):void {
        mediaTypeSignal.dispatch(event.type);
    }

    //************
    //  Overrides
    //************

    override public function destroy():void {
        if(stream) stopPlaying();
        super.destroy();
        container.stage.removeEventListener(Event.ENTER_FRAME, handleCurrentStreamTime);
        container.removeEventListener(MediaBase.PLAY_START, handleStreamStart);
        container.removeEventListener(MediaBase.END, handleStreamEnd);
    }

    //*****************
    //  Callback Handlers
    //*****************
    protected function updatedMeta(val:Object):void {
        duration = val.duration;
        setFirstPlaybackStartPosition();
    }

    //*****************
    //  Event Handlers
    //*****************
    protected function handleReady(event:Event):void {
        container.removeEventListener(MediaBase.READY, handleReady);
        if (streamName && streamName.length) {
            startPlaying(streamName);
            streamName = "";
        }
    }

    protected function handleStreamStart(event:Event):void {
        currentMediaStatus = MediaStateEnum.PlaybackStarted;
        if (!container.stage.hasEventListener(Event.ENTER_FRAME)) {
            container.stage.addEventListener(Event.ENTER_FRAME, handleCurrentStreamTime);
        }
        container.removeEventListener(MediaBase.PLAY_START, handleStreamStart);
    }

    protected function handleStreamEnd(event:Event):void {
        stopPlaying();
    }

    protected function handleCurrentStreamTime(event:Event):void {
        if (!streamHasPlayedToEnd) {
            dispatchCurrentTime();
            return;
        }
        log("Stream Ended: stream time = " + NumberUtil.roundNumber(time) + " : duration = " + NumberUtil.roundNumber(duration));
        stopPlaying();
    }

    protected function streamErrorHandler(event:Event):void {
        streamError.dispatch();
    }
}
}
