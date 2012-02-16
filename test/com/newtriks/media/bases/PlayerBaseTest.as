/**
 * Created by IntelliJ IDEA.
 * User: development
 * Date: 16/02/2012
 * Time: 16:43
 * To change this template use File | Settings | File Templates.
 */
package com.newtriks.media.bases {
import com.newtriks.media.core.MediaBaseConfiguration;

import org.flexunit.asserts.fail;

public class PlayerBaseTest {
    public var instance:PlayerBase;

    [Before]
    public function setUp():void {
        instance = new PlayerBase(config);
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
