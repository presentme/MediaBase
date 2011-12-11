/*
 * Copyright (c) 2011 Simon Bailey <simon@newtriks.com>
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement located at the
 * following url: http://www.newtriks.com/LICENSE.html
 */
package com.newtriks.core.interfaces
{
    import com.newtriks.core.*;

    import flash.media.Video;
    import flash.net.NetConnection;
    import flash.net.NetStream;

    public interface IVideoBase extends IVideoControl
    {
        function get baseType():String

        function get aspectRatio():String

        function get client():Object

        function get bandwidth():uint;

        function get quality():uint;

        function get microphoneRate():uint;

        function get microphoneSilenceLevel():uint;

        function get fps():uint;

        function get connection():NetConnection

        function set connection(value:NetConnection):void

        function get stream():NetStream

        function get display():UIVideoDisplay

        function get video():Video

        function get streamName():String

        function set streamName(val:String):void

        function set volume(value:Number):void

        function get status():String

        function get duration():Number

        function get bufferTime():Number

        function set bufferTime(time:Number):void

        function get bufferEmpty():Boolean

        function attachCamera():void

        function unAttachCamera():void

        function set cameraBroadcasting(value:Boolean):void

        function get cameraBroadcasting():Boolean

        function get append():Boolean

        function set append(value:Boolean):void

        function destroy():void;

        function resize(w:Number, h:Number):void
    }
}
