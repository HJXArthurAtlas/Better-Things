import Testing
@testable import BetterThingsKit

struct BetterThingsKitTests {
    @Test("版本与契约一致且非空")
    func versionMatchesContract() {
        #expect(BetterThingsKit.version == "0.1.0")
        #expect(!BetterThingsKit.version.isEmpty)
    }
}
