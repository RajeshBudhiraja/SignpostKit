import Testing
import os
@testable import SignpostKit

struct SignpostTests {
    let signpost = Signpost(subsystem: "com.signpostkit.tests", category: "Tests")

    struct TestError: Error {}

    // MARK: - measure

    @Test func syncMeasureReturnsResult() {
        let result = signpost.measure("Sync") { 2 + 2 }
        #expect(result == 4)
    }

    @Test func asyncMeasureReturnsResult() async {
        let result = await signpost.measure("Async", "metadata") {
            try? await Task.sleep(nanoseconds: 10_000_000)
            return "done"
        }
        #expect(result == "done")
    }

    @Test func measureRethrowsErrors() {
        #expect(throws: TestError.self) {
            try signpost.measure("Throwing") { throw TestError() }
        }
    }

    // MARK: - begin / end

    @Test func intervalCanEndInAnotherScope() {
        var stored: SignpostInterval? = signpost.begin("Stored", id: .exclusive, "start", privacy: .private)
        stored.take()?.end("finished")
        let isEmpty = stored == nil
        #expect(isEmpty)
    }

    @Test func animationIntervalEnds() {
        let interval = signpost.beginAnimation("Animation")
        interval.end()
    }

    // MARK: - IDs

    @Test func objectIDIsStableForSameObject() {
        final class Cell {}
        let cell = Cell()
        let first = SignpostID.object(cell).resolve(with: signpost.signposter)
        let second = SignpostID.object(cell).resolve(with: signpost.signposter)
        #expect(first == second)
    }

    @Test func uniqueIDsDiffer() {
        let first = SignpostID.unique.resolve(with: signpost.signposter)
        let second = SignpostID.unique.resolve(with: signpost.signposter)
        #expect(first != second)
    }

    @Test func eventsAcceptEveryIDKind() {
        signpost.event("Exclusive")
        signpost.event("Unique", id: .unique, "public")
        signpost.event("Object", id: .object(TestObject()), "private", privacy: .private)
    }

    // MARK: - Configuration

    @Test func disabledSkipsMetadata() {
        var evaluated = false
        func metadata() -> String {
            evaluated = true
            return "expensive"
        }
        Signpost.disabled.event("Event", metadata())
        Signpost.disabled.measure("Measure", metadata()) {}
        #expect(Signpost.disabled.isEnabled == false)
        #expect(evaluated == false)
    }

    @Test func alternativeInitializers() {
        let fromLogger = Signpost(logger: Logger(subsystem: "com.signpostkit.tests", category: "Logger"))
        let pointsOfInterest = Signpost.pointsOfInterest(subsystem: "com.signpostkit.tests")
        fromLogger.event("From logger")
        pointsOfInterest.event("Point of interest")
    }
}

private final class TestObject {}
