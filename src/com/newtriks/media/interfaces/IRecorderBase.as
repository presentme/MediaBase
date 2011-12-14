/**
 * Created by IntelliJ IDEA.
 * User: development
 * Date: 14/12/2011
 * Time: 22:55
 * To change this template use File | Settings | File Templates.
 */
package com.newtriks.media.interfaces {
import org.osflash.signals.Signal;

public interface IRecorderBase extends IMediaBase {
    function get storeStream():Signal;

    function startRecording():void;

    function stopRecording():void;

    function broadcastCamera(useVideo:Boolean):void;
}
}
