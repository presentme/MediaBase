/** @author: Simon Bailey <simon@newtriks.com> */
package com.newtriks.media.core {
import flash.media.SoundCodec;

public class MediaBaseConfiguration {
    internal var _aspectRatio:String = MediaBase.STRETCH_SCREEN;

    public function aspectRatio(value:String):MediaBaseConfiguration {
        _aspectRatio = value;
        return this;
    }

    internal var _client:Object;

    public function client(value:Object):MediaBaseConfiguration {
        _client = value;
        return this;
    }

    internal var _layoutCallbackHandler:Function;

    public function layoutCallbackHandler(value:Function):MediaBaseConfiguration {
        _layoutCallbackHandler = value;
        return this;
    }

    internal var _logCallbackHandler:Function;

    public function logCallbackHandler(value:Function):MediaBaseConfiguration {
        _logCallbackHandler = value;
        return this;
    }

    internal var _bandwidth:int = 32768;

    public function bandwidth(value:int):MediaBaseConfiguration {
        _bandwidth = value;
        return this;
    }

    internal var _quality:int = 0;

    public function quality(value:int):MediaBaseConfiguration {
        _quality = value;
        return this;
    }

    internal var _fps:int = 15;

    public function fps(value:int):MediaBaseConfiguration {
        _fps = value;
        return this;
    }

    internal var _bufferTime:int = 20;

    public function bufferTime(value:int):MediaBaseConfiguration {
        _bufferTime = value;
        return this;
    }

    internal var _camWidth:Number;

    public function camWidth(value:Number):MediaBaseConfiguration {
        _camWidth = value;
        return this;
    }

    internal var _camHeight:Number;

    public function camHeight(value:Number):MediaBaseConfiguration {
        _camHeight = value;
        return this;
    }

    internal var _microphoneRate:int = 22;

    public function microphoneRate(value:int):MediaBaseConfiguration {
        _microphoneRate = value;
        return this;
    }

    internal var _microphoneSilenceLevel:int = 0;

    public function microphoneSilenceLevel(value:int):MediaBaseConfiguration {
        _microphoneSilenceLevel = value;
        return this;
    }

    internal var _metaDataReceived:Function;

    public function metaDataReceived(value:Function):MediaBaseConfiguration {
        _metaDataReceived = value;
        return this;
    }

    internal var _autoReload:Boolean = false;

    public function autoReload(value:Boolean):MediaBaseConfiguration {
        _autoReload = value;
        return this;
    }

    internal var _timeLimit:int = 0;

    public function timeLimit(value:int):MediaBaseConfiguration {
        _timeLimit = value;
        return this;
    }

    internal var _countdown:int = 0;

    public function countdown(value:int):MediaBaseConfiguration {
        _countdown = value;
        return this;
    }

    internal var _soundCodec:String = SoundCodec.NELLYMOSER;

    public function soundCodec(value:String):MediaBaseConfiguration {
        _soundCodec = value;
        return this;
    }

    internal var _appendRecording:Boolean = false;

    public function appendRecording(value:Boolean):MediaBaseConfiguration {
        _appendRecording = value;
        return this;
    }
}
}