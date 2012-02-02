/**
 * Created by IntelliJ IDEA.
 * User: development
 * Date: 14/12/2011
 * Time: 21:00
 * To change this template use File | Settings | File Templates.
 */
package com.newtriks.media.interfaces {
import com.newtriks.media.core.interfaces.IVideoContainer;

import flash.events.Event;
import flash.net.NetConnection;
import flash.net.NetStream;

import org.osflash.signals.Signal;

public interface IMediaBase {
    function get mediaStatus():Signal;

    function get mediaTypeSignal():Signal;

    function get container():IVideoContainer;

    function set container(value:IVideoContainer):void;

    function get netconnection():NetConnection;

    function set netconnection(value:NetConnection):void;

    function get streamTime():Number;

    function get streamName():String;

    function audioOnly(value:Boolean):void;
}
}
