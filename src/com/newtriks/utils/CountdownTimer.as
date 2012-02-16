/**
 * User: newtriks
 * Date: 18/01/2012
 */
package com.newtriks.utils {
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.TimerEvent;
import flash.utils.Timer;

public class CountdownTimer extends EventDispatcher {
    public static const COUNT:String = "CountdownTimer::COUNT";
    public static const COMPLETE:String = "CountdownTimer::COMPLETE";
    private var _timer:Timer;

    public function CountdownTimer() {
    }

    private var _count:int;
    public function get count():int {
        return _count;
    }

    public function set count(value:int):void {
        _count = value;
    }

    public function startCountDown(iterations:int, delay:int):void {
        _timer = new Timer(delay, iterations);
        _timer.addEventListener(TimerEvent.TIMER, timerHandler);
        _timer.addEventListener(TimerEvent.TIMER_COMPLETE, stopCountDown);
        _timer.start();
    }

    public function stopCountDown(event:TimerEvent = null):void {
        if (_timer.running) {
            _timer.stop();
        }
        this.dispatchEvent(new Event(COMPLETE, true));
        _timer.removeEventListener(TimerEvent.TIMER, timerHandler);
        _timer.removeEventListener(TimerEvent.TIMER_COMPLETE, stopCountDown);
    }

    private function timerHandler(e:TimerEvent):void {
        count = _timer.repeatCount - _timer.currentCount;
        this.dispatchEvent(new Event(COUNT, true));
    }
}
}
