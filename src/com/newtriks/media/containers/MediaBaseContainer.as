/*
 * Copyright (c) 2011 Simon Bailey <simon@newtriks.com>
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement located at the
 * following url: http://www.newtriks.com/LICENSE.html
 */
package com.newtriks.media.containers {
import com.newtriks.media.core.MediaBase;

import spark.components.SkinnableContainer;

public class MediaBaseContainer extends SkinnableContainer {
    private var _mediaBase:MediaBase;
    public function get mediaBase():MediaBase {
        return _mediaBase;
    }

    public function set mediaBase(value:MediaBase):void {
        _mediaBase = value;
        _mediaBase.container = this;
        setup();
    }

    public function setup():void {
        if (contains(mediaBase)) {
            destroy();
        }
        addElement(mediaBase);
    }

    public function destroy():void {
        if (mediaBase == null) {
            return;
        }
        mediaBase.destroy();
        this.removeAllElements();
    }
}
}