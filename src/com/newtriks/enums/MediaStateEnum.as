/**
 * Created by IntelliJ IDEA.
 * User: development
 * Date: 11/12/2011
 * Time: 23:00
 * To change this template use File | Settings | File Templates.
 */
package com.newtriks.enums {
import com.newtriks.utils.Enum;

public class MediaStateEnum {
    public static const Playback:MediaStateEnum = new MediaStateEnum();
    public static const PlaybackStarted:MediaStateEnum = new MediaStateEnum();
    public static const PlaybackPaused:MediaStateEnum = new MediaStateEnum();
    public static const PlaybackStopped:MediaStateEnum = new MediaStateEnum();
    public static const Record:MediaStateEnum = new MediaStateEnum();
    public static const RecordStarted:MediaStateEnum = new MediaStateEnum();
    public static const RecordStopped:MediaStateEnum = new MediaStateEnum();

    public static function toString(state:MediaStateEnum):String {
        return Enum.getName(MediaStateEnum, state);
    }
}
}
