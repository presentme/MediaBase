/**
 * Created by IntelliJ IDEA.
 * User: development
 * Date: 14/12/2011
 * Time: 22:55
 * To change this template use File | Settings | File Templates.
 */
package com.newtriks.media.interfaces {
import org.osflash.signals.Signal;

public interface IPlayerBase extends IMediaBase {
    function get currentPlaybackTime():Signal;

    function get streamError():Signal;

    function get autoplay():Boolean;

    function set autoplay(value:Boolean):void;

    function set duration(time:Number):void;

    function startPlaying(url:String, cue:Number = 0):void;

    function pausePlaying():void;
}
}
