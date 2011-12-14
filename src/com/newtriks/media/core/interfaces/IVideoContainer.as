/*
 * Copyright (c) 2011 Simon Bailey <simon@newtriks.com>
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement located at the
 * following url: http://www.newtriks.com/LICENSE.html
 */

package com.newtriks.media.core.interfaces {
import com.newtriks.media.interfaces.IMediaBase;

import flash.events.IEventDispatcher;
import flash.net.NetConnection;

public interface IVideoContainer extends IEventDispatcher {
    function set base(value:IMediaBase):void;

    function get base():IMediaBase;

    function get baseType():String;

    function set baseType(type:String):void

    function get aspectRatio():String

    function set aspectRatio(ratio:String):void

    function get bandwidth():uint;

    function set bandwidth(value:uint):void;

    function get quality():uint;

    function set quality(value:uint):void;

    function get microphoneRate():uint;

    function set microphoneRate(value:uint):void;

    function get microphoneSilenceLevel():uint;

    function set microphoneSilenceLevel(value:uint):void;

    function get fps():uint;

    function set fps(value:uint):void;

    function get client():Object;

    function set client(value:Object):void;

    function get connection():NetConnection;

    function set connection(value:NetConnection):void;

    function get video():IVideoBase;

    function set video(value:IVideoBase):void;

    function get layoutHandler():Function;

    function set layoutHandler(value:Function):void;

    function get metaDataHandler():Function;

    function set metaDataHandler(value:Function):void;

    function get logHandler():Function;

    function set logHandler(value:Function):void;

    function resize():void;

    function setup():void;

    function destroy():void

    function disconnectCameraAndMicrophone():void
}
}
