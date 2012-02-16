package {
import flash.display.Sprite;

import org.flexunit.internals.TraceListener;
import org.flexunit.listeners.CIListener;
import org.flexunit.runner.FlexUnitCore;

[SWF(width="500", height="375", backgroundColor="#000000")]
public class MediaBaseTestRunner extends Sprite {
    private var core:FlexUnitCore;

    public function MediaBaseTestRunner() {
        core = new FlexUnitCore();
        core.visualDisplayRoot = this;
        core.addListener(new CIListener());
        core.addListener(new TraceListener());
        core.run(MediaBaseTestSuite);
    }
}
}