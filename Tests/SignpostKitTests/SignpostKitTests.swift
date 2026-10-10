import Testing
@testable import SignpostKit

struct SignpostTests {
    let signpost = Signpost(subsystem: "com.signpostkit.tests", category: "Tests")

    struct TestError: Error {}

    @Test func syncMeasureReturnsResult() {
        let result = signpost.measure("Sync") { 2 + 2 }
        #expect(result == 4)
    }

    @Test func asyncMeasureReturnsResult() async {
        let result = await signpost.measure("Async") {
            try? await Task.sleep(for: .milliseconds(10))
            return "done"
        }
        #expect(result == "done")
    }

    @Test func measureRethrowsErrors() {
        #expect(throws: TestError.self) {
            try signpost.measure("Throwing") { throw TestError() }
        }
    }
}
