/**
 * Created by IntelliJ IDEA.
 * User: development
 * Date: 16/02/2012
 * Time: 16:44
 * To change this template use File | Settings | File Templates.
 */
package com.newtriks.media.core {
import org.flexunit.asserts.fail;

public class MediaBaseConfigurationTest {
    public var instance:MediaBaseConfiguration;

    [Before]
    public function setUp():void {
        instance = new MediaBaseConfiguration();
    }

    [After]
    public function tearDown():void {
        instance = null;
    }

    [Test]
    public function should_fail():void {
        fail("Should fail");
    }
}
}
