/*
 * Copyright (c) 2011 Simon Bailey <simon@newtriks.com>
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement located at the
 * following url: http://www.newtriks.com/LICENSE.html
 */
package com.newtriks.media.flex.containers
{
import com.newtriks.media.core.interfaces.IVideoBase;
import com.newtriks.media.core.interfaces.IVideoContainer;
import com.newtriks.media.interfaces.IMediaBase;

import flash.net.NetConnection;

import spark.components.SkinnableContainer;

public class VideoContainer extends SkinnableContainer implements IVideoContainer
{
    private var _baseType:String;
    public function set baseType(type:String):void
    {
        if(_baseType==type)
        {
            return;
        }
        _baseType=type;
        destroy();
    }

    private var _base:IMediaBase;
    public function get base():IMediaBase
    {
        return _base;
    }

    public function set base(value:IMediaBase):void
    {
        _base=value;
    }

    public function get baseType():String
    {
        return _baseType;
    }

    private var _aspectRatio:String;
    public function set aspectRatio(ratio:String):void
    {
        _aspectRatio=ratio;
    }

    public function get aspectRatio():String
    {
        return _aspectRatio;
    }

    private var _client:Object;
    public function get client():Object
    {
        return _client;
    }

    public function set client(value:Object):void
    {
        if(value==null)
        {
            return;
        }
        _client=value;
    }

    private var _connection:NetConnection;
    public function get connection():NetConnection
    {
        return _connection;
    }

    public function set connection(value:NetConnection):void
    {
        if(value==null&&_video!=null)
        {
            _connection=null;
            _video.destroy();
            this.removeAllElements();
            _video=null;
            return;
        }
        _connection=value;
        setup();
    }

    private var _video:IVideoBase;
    public function get video():IVideoBase
    {
        return _video;
    }

    public function set video(value:IVideoBase):void
    {
        if(value==null)
        {
            return;
        }
        _video=value;
    }

    public function get layoutHandler():Function
    {
        return _layoutHandler;
    }

    private var _layoutHandler:Function;
    public function set layoutHandler(value:Function):void
    {
        if(value==null)
        {
            return;
        }
        _layoutHandler=value;
    }

    private var _logHandler:Function;
    public function get logHandler():Function
    {
        return _logHandler;
    }

    public function set logHandler(value:Function):void
    {
        _logHandler=value;
    }

    private var _metaDataHandler:Function;
    public function get metaDataHandler():Function
    {
        return _metaDataHandler;
    }

    public function set metaDataHandler(value:Function):void
    {
        _metaDataHandler=value;
    }

    public function resize():void
    {
        _video.resize(this.width, this.height);
    }

    public function setup():void
    {
    }

    public function destroy():void
    {
        if(_video==null)
        {
            return;
        }
        _video.destroy();
        this.removeAllElements();
        _video=null;
        setup();
    }

    public function disconnectCameraAndMicrophone():void
    {
    }

    private var _bandwidth:uint=32768;
    public function get bandwidth():uint
    {
        return _bandwidth;
    }

    public function set bandwidth(value:uint):void
    {
        _bandwidth=value;
    }

    private var _quality:uint=0;
    public function get quality():uint
    {
        return _quality;
    }

    public function set quality(value:uint):void
    {
        _quality=value;
    }

    private var _microphoneRate:uint=22;
    public function get microphoneRate():uint
    {
        return _microphoneRate;
    }

    public function set microphoneRate(value:uint):void
    {
        _microphoneRate=value;
    }

    private var _microphoneSilenceLevel:uint=0;
    public function get microphoneSilenceLevel():uint
    {
        return _microphoneSilenceLevel;
    }

    public function set microphoneSilenceLevel(value:uint):void
    {
        _microphoneSilenceLevel=value;
    }

    private var _fps:uint=15;
    public function get fps():uint
    {
        return _fps;
    }

    public function set fps(value:uint):void
    {
        _fps=value;
    }

    private var _camWidth:Number;
    public function get camWidth():Number
    {
        return _camWidth;
    }

    public function set camWidth(value:Number):void
    {
        _camWidth=value;
    }

    private var _camHeight:Number;
    public function get camHeight():Number
    {
        return _camHeight;
    }

    public function set camHeight(value:Number):void
    {
        _camHeight=value;
    }

    private var _bufferTime:uint=20;
    public function get bufferTime():uint
    {
        return _bufferTime;
    }

    public function set bufferTime(value:uint):void
    {
        _bufferTime=value;
    }

    private var _autoReload:Boolean=false;
    public function get autoReload():Boolean
    {
        return _autoReload;
    }

    public function set autoReload(value:Boolean):void
    {
        _autoReload=value;
    }

    private var _timeLimit:int=0;
    public function get timeLimit():int
    {
        return _timeLimit;
    }

    public function set timeLimit(value:int):void
    {
        _timeLimit=value;
    }

    private var _countdown:int=0;
    public function get countdown():int
    {
        return _countdown;
    }

    public function set countdown(value:int):void
    {
        _countdown=value;
    }
}
}