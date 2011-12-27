/*
 * Copyright (c) 2011 Simon Bailey <simon@newtriks.com>
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement located at the
 * following url: http://www.newtriks.com/LICENSE.html
 */

package com.newtriks.media.core.interfaces {
import mx.core.IVisualElement;

public interface IVideoControl extends IVisualElement {
    function play(name:String, ...rest):void

    function pause():void

    function resume():void

    function seek(time:Number):void

    function get time():Number
}
}
