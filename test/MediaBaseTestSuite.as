package {
import com.newtriks.media.bases.PlayerBaseTest;
import com.newtriks.media.bases.RecorderBaseTest;
import com.newtriks.media.core.MediaBaseConfigurationTest;
import com.newtriks.media.core.MediaBaseTest;

[Suite]
[RunWith("org.flexunit.runners.Suite")]
public class MediaBaseTestSuite {
    public var _playerBaseTest:PlayerBaseTest;
    public var _recorderBaseTest:RecorderBaseTest;
    public var _mediaBaseConfigurationTest:MediaBaseConfigurationTest;
    public var _mediaBaseTest:MediaBaseTest;
}
}