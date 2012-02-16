/**
 * Created by IntelliJ IDEA.
 * User: development
 * Date: 16/02/2012
 * Time: 16:41
 * To change this template use File | Settings | File Templates.
 */
package com.newtriks.media.core {
import org.flexunit.asserts.fail;

public class MediaBaseTest {
    public var instance:MediaBase;

    [Before]
    public function setUp():void {
        instance = new MediaBase(config);
    }

    [After]
    public function tearDown():void {
        instance = null;
    }

    [Test]
    public function should_fail():void {
        fail("Should fail");
    }

    /**
     * Helpers
     */

    private function get config():MediaBaseConfiguration {
        var config:MediaBaseConfiguration=new MediaBaseConfiguration();
        return config;
    }
}
}
