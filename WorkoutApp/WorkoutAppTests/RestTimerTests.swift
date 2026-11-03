import XCTest
@testable import WorkoutApp

final class RestTimerTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_000_000)

    func testRemainingTimeComesFromEndDateNotTicks() {
        var timer = RestTimer()
        timer.start(seconds: 90, now: start)

        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.remainingSeconds(at: start), 90)
        // e.g. the phone was locked for 70 seconds; no ticks happened in between
        XCTAssertEqual(timer.remainingSeconds(at: start.addingTimeInterval(70)), 20)
        XCTAssertFalse(timer.isFinished(at: start.addingTimeInterval(89)))
        XCTAssertTrue(timer.isFinished(at: start.addingTimeInterval(95)))
        XCTAssertEqual(timer.remainingSeconds(at: start.addingTimeInterval(95)), 0)
    }

    func testPauseFreezesAndResumeContinues() {
        var timer = RestTimer()
        timer.start(seconds: 60, now: start)
        timer.pause(now: start.addingTimeInterval(20))

        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.remainingSeconds(at: start.addingTimeInterval(500)), 40)

        let resumeAt = start.addingTimeInterval(500)
        timer.resume(defaultSeconds: 60, now: resumeAt)
        XCTAssertEqual(timer.remainingSeconds(at: resumeAt.addingTimeInterval(10)), 30)
    }

    func testResumeWithNothingPausedStartsFresh() {
        var timer = RestTimer()
        timer.resume(defaultSeconds: 75, now: start)
        XCTAssertEqual(timer.remainingSeconds(at: start), 75)
    }

    func testResetClearsEverything() {
        var timer = RestTimer()
        timer.start(seconds: 60, now: start)
        timer.reset()

        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.remainingSeconds(at: start), 0)
        XCTAssertFalse(timer.isFinished(at: start.addingTimeInterval(100)))
    }

    func testParsesPlanRestText() {
        XCTAssertEqual(RestTimer.seconds(fromRestText: "90s"), 90)
        XCTAssertEqual(RestTimer.seconds(fromRestText: "60-75s"), 60)
        XCTAssertEqual(RestTimer.seconds(fromRestText: "2 minutes"), 120)
        XCTAssertEqual(RestTimer.seconds(fromRestText: "2 min"), 120)
        XCTAssertEqual(RestTimer.seconds(fromRestText: "Steady"), 60)
    }
}
