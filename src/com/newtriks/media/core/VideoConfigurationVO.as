/** @author: Simon Bailey <simon@newtriks.com> */
package com.newtriks.media.core
{
public class VideoConfigurationVO
{
    public function VideoConfigurationVO(baseType:String)
    {
        _baseType=baseType;
    }

    private var _baseType:String;
    public function get baseType():String
    {
        return _baseType;
    }

    internal var _aspectRatio:String=VideoBase.STRETCH_SCREEN;

    public function aspectRatio(value:String):VideoConfigurationVO
    {
        _aspectRatio=value;
        return this;
    }

    internal var _client:Object;

    public function client(value:Object):VideoConfigurationVO
    {
        _client=value;
        return this;
    }

    internal var _layoutCallbackHandler:Function;

    public function layoutCallbackHandler(value:Function):VideoConfigurationVO
    {
        _layoutCallbackHandler=value;
        return this;
    }

    internal var _logCallbackHandler:Function;

    public function logCallbackHandler(value:Function):VideoConfigurationVO
    {
        _logCallbackHandler=value;
        return this;
    }

    internal var _bandwidth:int;

    public function bandwidth(value:int):VideoConfigurationVO
    {
        _bandwidth=value;
        return this;
    }

    internal var _quality:int;

    public function quality(value:int):VideoConfigurationVO
    {
        _quality=value;
        return this;
    }

    internal var _fps:int;

    public function fps(value:int):VideoConfigurationVO
    {
        _fps=value;
        return this;
    }

    internal var _bufferTime:int;

    public function bufferTime(value:int):VideoConfigurationVO
    {
        _bufferTime=value;
        return this;
    }

    internal var _camWidth:Number;

    public function camWidth(value:Number):VideoConfigurationVO
    {
        _camWidth=value;
        return this;
    }

    internal var _camHeight:Number;

    public function camHeight(value:Number):VideoConfigurationVO
    {
        _camHeight=value;
        return this;
    }

    internal var _microphoneRate:int;

    public function microphoneRate(value:int):VideoConfigurationVO
    {
        _microphoneRate=value;
        return this;
    }

    internal var _microphoneSilenceLevel:int;

    public function microphoneSilenceLevel(value:int):VideoConfigurationVO
    {
        _microphoneSilenceLevel=value;
        return this;
    }

    internal var _metaDataReceived:Function;

    public function metaDataReceived(value:Function):VideoConfigurationVO
    {
        _metaDataReceived=value;
        return this;
    }

    internal var _autoReload:Boolean;

    public function autoReload(value:Boolean):VideoConfigurationVO
    {
        _autoReload=value;
        return this;
    }

    internal var _timeLimit:int;

    public function timeLimit(value:int):VideoConfigurationVO
    {
        _timeLimit=value;
        return this;
    }

    internal var _countdown:int;

    public function countdown(value:int):VideoConfigurationVO
    {
        _countdown=value;
        return this;
    }
}
}