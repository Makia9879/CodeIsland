import XCTest
@testable import CodeIsland
import CodeIslandCore

@MainActor
final class AppStateCompletionFlowTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: SettingsKey.autoExpandOnCompletion)
        UserDefaults.standard.removeObject(forKey: SettingsKey.smartSuppress)
        super.tearDown()
    }

    func testStopEventAutoShowsCompletionCardUsingRegisteredDefault() throws {
        UserDefaults.standard.removeObject(forKey: SettingsKey.autoExpandOnCompletion)

        let appState = AppState()
        let event = try makeHookEvent([
            "hook_event_name": "Stop",
            "session_id": "s-complete",
            "_source": "claude",
            "last_assistant_message": "done"
        ])

        appState.handleEvent(event)

        XCTAssertEqual(appState.surface, .completionCard(sessionId: "s-complete"))
        XCTAssertEqual(appState.activeSessionId, "s-complete")
    }

    func testTaskCompleteEventAutoShowsCompletionCard() throws {
        let appState = AppState()
        let event = try makeHookEvent([
            "hook_event_name": "TaskComplete",
            "session_id": "s-task-complete",
            "_source": "cline",
            "summary": "task complete"
        ])

        appState.handleEvent(event)

        XCTAssertEqual(appState.surface, .completionCard(sessionId: "s-task-complete"))
        XCTAssertEqual(appState.activeSessionId, "s-task-complete")
    }

    func testStopEventRespectsExplicitAutoExpandDisabled() throws {
        UserDefaults.standard.set(false, forKey: SettingsKey.autoExpandOnCompletion)

        let appState = AppState()
        let event = try makeHookEvent([
            "hook_event_name": "Stop",
            "session_id": "s-complete",
            "_source": "claude",
        ])

        appState.handleEvent(event)

        XCTAssertEqual(appState.surface, .collapsed)
    }

    private func makeHookEvent(_ payload: [String: Any]) throws -> HookEvent {
        let data = try JSONSerialization.data(withJSONObject: payload)
        return try XCTUnwrap(HookEvent(from: data))
    }
}
