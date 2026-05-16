import XCTest
@testable import CodeIsland

final class NotchPanelViewTests: XCTestCase {
    func testCollapsedCoreWidthUsesPhysicalNotchOnNotchedDisplays() {
        XCTAssertEqual(
            NotchWidthMetrics.collapsedCoreWidth(
                notchW: 210,
                hasNotch: true,
                notchlessCollapsedWidth: 300
            ),
            210,
            accuracy: 0.001
        )
    }

    func testCollapsedCoreWidthUsesSettingOnNotchlessDisplays() {
        XCTAssertEqual(
            NotchWidthMetrics.collapsedCoreWidth(
                notchW: 210,
                hasNotch: false,
                notchlessCollapsedWidth: 260
            ),
            260,
            accuracy: 0.001
        )
    }

    func testCollapsedCoreWidthClampsNotchlessSetting() {
        XCTAssertEqual(
            NotchWidthMetrics.collapsedCoreWidth(
                notchW: 210,
                hasNotch: false,
                notchlessCollapsedWidth: 20
            ),
            NotchWidthMetrics.minNotchlessCollapsedWidth,
            accuracy: 0.001
        )
        XCTAssertEqual(
            NotchWidthMetrics.collapsedCoreWidth(
                notchW: 210,
                hasNotch: false,
                notchlessCollapsedWidth: 900
            ),
            NotchWidthMetrics.maxNotchlessCollapsedWidth,
            accuracy: 0.001
        )
    }

    func testHoverPreviewWidthCannotBeLessThanRestingWidth() {
        XCTAssertEqual(
            NotchWidthMetrics.hoverPreviewPanelWidth(
                restingPanelWidth: 360,
                hoverPreviewWidthLimit: 260,
                screenLongEdge: 900
            ),
            360,
            accuracy: 0.001
        )
    }

    func testHoverPreviewWidthClampsToScreenLongEdge() {
        XCTAssertEqual(
            NotchWidthMetrics.hoverPreviewPanelWidth(
                restingPanelWidth: 300,
                hoverPreviewWidthLimit: 2000,
                screenLongEdge: 1512
            ),
            1512,
            accuracy: 0.001
        )
    }

    func testHorizontalContentOffsetWorksWhenPanelWindowIsFullScreenWidth() {
        XCTAssertEqual(
            NotchWidthMetrics.horizontalContentOffset(
                requestedOffset: 120,
                contentWidth: 300,
                screenWidth: 1920
            ),
            120,
            accuracy: 0.001
        )
    }

    func testHorizontalContentOffsetClampsToKeepIslandVisible() {
        XCTAssertEqual(
            NotchWidthMetrics.horizontalContentOffset(
                requestedOffset: 1000,
                contentWidth: 300,
                screenWidth: 1920
            ),
            810,
            accuracy: 0.001
        )

        XCTAssertEqual(
            NotchWidthMetrics.horizontalContentOffset(
                requestedOffset: -1000,
                contentWidth: 300,
                screenWidth: 1920
            ),
            -810,
            accuracy: 0.001
        )
    }

    func testShouldTriggerJumpFailureFeedbackWhenAllAttemptsFail() {
        XCTAssertTrue(shouldTriggerJumpFailureFeedback([false, false, false]))
    }

    func testShouldNotTriggerJumpFailureFeedbackWhenAnyAttemptSucceeds() {
        XCTAssertFalse(shouldTriggerJumpFailureFeedback([false, true, false]))
    }

    func testCompactSessionCountUsesTotalAsDenominator() {
        let count = compactSessionCountDisplay(activeSessionCount: 1, totalSessionCount: 1)

        XCTAssertEqual(count.active, 1)
        XCTAssertEqual(count.total, 1)
    }

    func testJumpFailureShakeSequenceUsesFastAlternatingOffsets() {
        XCTAssertEqual(JumpAnimationHelper.shakeSequence, [8, -8, 6, -6, 3, -3, 0])
    }

    func testEvaluateJumpValidationReturnsSuccessWhenCheckSucceeds() async {
        var callCount = 0
        let outcome = await evaluateJumpValidation(
            delays: [1, 1, 1],
            isCancelled: { false },
            sleep: { _ in },
            checkSucceeded: {
                callCount += 1
                return callCount == 2
            }
        )

        XCTAssertEqual(outcome, .success)
    }

    func testEvaluateJumpValidationReturnsFailedWhenAllChecksFail() async {
        let outcome = await evaluateJumpValidation(
            delays: [1, 1, 1],
            isCancelled: { false },
            sleep: { _ in },
            checkSucceeded: { false }
        )

        XCTAssertEqual(outcome, .failed)
    }

    func testEvaluateJumpValidationReturnsCancelledBeforeCheckRuns() async {
        var checksRan = 0
        let outcome = await evaluateJumpValidation(
            delays: [1, 1, 1],
            isCancelled: { true },
            sleep: { _ in },
            checkSucceeded: {
                checksRan += 1
                return false
            }
        )

        XCTAssertEqual(outcome, .cancelled)
        XCTAssertEqual(checksRan, 0)
    }

    func testClickJumpCollapseTimelineShowsClickRingWhenCursorReachesClickPoint() {
        let timeline = clickJumpCollapsePreviewTimeline(progress: 0.26)

        XCTAssertGreaterThan(timeline.expand, 0.95)
        XCTAssertTrue(timeline.showClickRing)
        XCTAssertEqual(timeline.cursorX, 0, accuracy: 0.001)
        XCTAssertEqual(timeline.cursorY, 0, accuracy: 0.001)
    }

    func testClickJumpCollapseTimelineMovesCursorToClickPointFaster() {
        let timeline = clickJumpCollapsePreviewTimeline(progress: 0.08)

        XCTAssertEqual(timeline.cursorX, 0, accuracy: 0.001)
        XCTAssertEqual(timeline.cursorY, 0, accuracy: 0.001)
    }

    func testClickJumpCollapseTimelineMovesCursorFullyOffscreenBeforeExpandStarts() {
        let timeline = clickJumpCollapsePreviewTimeline(progress: 0.80)

        XCTAssertEqual(timeline.cursorX, 34, accuracy: 0.001)
        XCTAssertEqual(timeline.cursorY, 28, accuracy: 0.001)
        XCTAssertLessThanOrEqual(timeline.expand, 0.001)
    }

    func testClickJumpCollapseTimelineStartsExpandAfterCursorIsAlreadyOffscreen() {
        let timeline = clickJumpCollapsePreviewTimeline(progress: 0.85)

        XCTAssertGreaterThan(timeline.expand, 0.3)
        XCTAssertEqual(timeline.cursorX, 34, accuracy: 0.001)
        XCTAssertEqual(timeline.cursorY, 28, accuracy: 0.001)
    }

    func testClickJumpCollapseTimelineUsesMouseLeaveLikeCollapseSpeed() {
        let timeline = clickJumpCollapsePreviewTimeline(progress: 0.38)

        XCTAssertGreaterThan(timeline.expand, 0.5)
        XCTAssertLessThan(timeline.expand, 0.7)
    }

    func testClickJumpCollapseTimelineUsesMouseLeaveLikeExpandSpeed() {
        let timeline = clickJumpCollapsePreviewTimeline(progress: 0.93)

        XCTAssertGreaterThanOrEqual(timeline.expand, 0.999)
    }

    func testClickJumpCollapseTimelineHoldsCollapsedStateForMiddleWindow() {
        let timeline = clickJumpCollapsePreviewTimeline(progress: 0.60)

        XCTAssertLessThanOrEqual(timeline.expand, 0.001)
        XCTAssertEqual(timeline.cursorX, 0, accuracy: 0.001)
        XCTAssertEqual(timeline.cursorY, 0, accuracy: 0.001)
    }

    func testClickJumpCollapseTimelineLoopSeamIsSmooth() {
        let start = clickJumpCollapsePreviewTimeline(progress: 0)
        let end = clickJumpCollapsePreviewTimeline(progress: 1)

        XCTAssertEqual(start.expand, end.expand, accuracy: 0.001)
        XCTAssertEqual(start.cursorX, end.cursorX, accuracy: 0.001)
        XCTAssertEqual(start.cursorY, end.cursorY, accuracy: 0.001)
    }

    func testClickJumpCollapseTimelineLowersClickPoint() {
        let timeline = clickJumpCollapsePreviewTimeline(progress: 0.26)
        XCTAssertEqual(timeline.clickPointY, 16.0, accuracy: 0.1)
    }

}
