import Foundation
import Testing
@testable import A11yLinter

@Suite("A11yLinter")
struct A11yLinterTests {

    // MARK: - SwiftUI rules

    @Test func missingImageLabel() throws {
        let violations = try lint(code: """
        import SwiftUI
        struct V: View {
            var body: some View {
                Image("logo")
            }
        }
        """)
        #expect(violations.contains { $0.type == .missingImageDescription })
    }

    @Test func buttonWithLabelIsClean() throws {
        let violations = try lint(code: """
        import SwiftUI
        struct V: View {
            var body: some View {
                Button(action: {}) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add item")
                .accessibilityIdentifier("addButton")
            }
        }
        """)
        #expect(!violations.contains { $0.type == .missingAccessibilityLabel })
    }

    @Test func smallTouchTarget() throws {
        let violations = try lint(code: """
        import SwiftUI
        struct V: View {
            var body: some View {
                Button("X") { }
                    .frame(width: 30, height: 30)
            }
        }
        """)
        #expect(violations.contains { $0.type == .insufficientTouchTarget })
    }

    @Test func formLabelMissing() throws {
        let violations = try lint(code: """
        import SwiftUI
        struct V: View {
            @State var name = ""
            var body: some View { TextField("name", text: $name) }
        }
        """)
        #expect(violations.contains { $0.type == .missingFormLabel })
    }

    @Test func formLabelPresent() throws {
        let violations = try lint(code: """
        import SwiftUI
        struct V: View {
            @State var name = ""
            var body: some View {
                VStack {
                    Text("Name")
                    TextField("John", text: $name)
                        .accessibilityLabel("Full Name")
                }
            }
        }
        """)
        #expect(!violations.contains { $0.type == .missingFormLabel })
    }

    // MARK: - Element-name false positives (substring matching)

    @Test func deepLinkMethodCallIsNotALink() throws {
        let violations = try lint(code: """
        import SwiftUI
        struct Router {
            func open(_ url: URL) {
                URLSchemeManager.shared.handleDeepLink(url)
            }
        }
        """)
        #expect(!violations.contains { $0.type == .missingAccessibilityIdentifier })
        #expect(!violations.contains { $0.type == .missingAccessibilityHint })
    }

    @Test func methodCallsContainingElementNamesAreNotFlagged() throws {
        let violations = try lint(code: """
        import SwiftUI
        struct ViewModel {
            func update() {
                viewModel.toggleMenu()
                store.resetSlider()
                coordinator.showPicker()
            }
        }
        """)
        #expect(!violations.contains { $0.type == .missingAccessibilityIdentifier })
        #expect(!violations.contains { $0.type == .missingAccessibilityHint })
    }

    @Test func realLinkStillRequiresIdentifier() throws {
        let violations = try lint(code: """
        import SwiftUI
        struct V: View {
            var body: some View {
                Link("Home", destination: URL(string: "https://example.com")!)
            }
        }
        """)
        #expect(violations.contains { $0.type == .missingAccessibilityIdentifier })
    }

    @Test func customTextFieldViewIsNotAFormLabelViolation() throws {
        let violations = try lint(code: """
        import SwiftUI
        struct V: View {
            @State var pw = ""
            var body: some View {
                SecureTextField(text: $pw)
                    .accessibilityIdentifier("passwordField")
                ClearableEmailTextField(text: $pw)
            }
        }
        """)
        #expect(!violations.contains { $0.type == .missingFormLabel })
    }

    @Test func realTextFieldStillRequiresFormLabel() throws {
        let violations = try lint(code: """
        import SwiftUI
        struct V: View {
            @State var name = ""
            var body: some View { TextField("name", text: $name) }
        }
        """)
        #expect(violations.contains { $0.type == .missingFormLabel })
    }

    @Test func customImageViewIsNotAnImageDescriptionViolation() throws {
        let violations = try lint(code: """
        import SwiftUI
        struct V: View {
            var body: some View {
                AvatarImage(user: user)
            }
        }
        """)
        #expect(!violations.contains { $0.type == .missingImageDescription })
    }

    @Test func realImageStillRequiresDescription() throws {
        let violations = try lint(code: """
        import SwiftUI
        struct V: View {
            var body: some View { Image("logo") }
        }
        """)
        #expect(violations.contains { $0.type == .missingImageDescription })
    }

    @Test func videoWithoutCaptions() throws {
        let violations = try lint(code: """
        import SwiftUI
        struct V: View { var body: some View { VideoPlayer(player: player) } }
        """)
        #expect(violations.contains { $0.type == .missingVideoSubtitles })
    }

    @Test func videoWithCaptions() throws {
        let violations = try lint(code: """
        import SwiftUI
        struct V: View {
            var body: some View {
                VideoPlayer(player: player)
                    .accessibilityLabel("Tutorial")
                    .accessibilityHint("Transcript available")
            }
        }
        """)
        #expect(!violations.contains { $0.type == .missingVideoSubtitles })
    }

    @Test func interactiveContainerWithLabelIsClean() throws {
        let violations = try lint(code: """
        import SwiftUI
        struct V: View {
            var body: some View {
                ZStack {
                    Text("Tap me")
                }
                .onTapGesture { }
                .accessibilityLabel("Action button")
            }
        }
        """)
        #expect(!violations.contains { $0.type == .inaccessibleCustomControl })
    }

    @Test func interactiveContainerWithoutLabel() throws {
        let violations = try lint(code: """
        import SwiftUI
        struct V: View {
            var body: some View {
                ZStack {
                    Text("Tap me")
                }
                .onTapGesture { }
            }
        }
        """)
        #expect(violations.contains { $0.type == .inaccessibleCustomControl })
    }

    // MARK: - Compliance scoring

    @Test func complianceScore() {
        let violations: [Violation] = [
            makeViolation(.missingAccessibilityLabel, severity: .error, eu: false),
            makeViolation(.missingAccessibilityLabel, severity: .error, eu: false),
            makeViolation(.missingAccessibilityHint, severity: .warning, eu: false)
        ]
        let scoring = ScoringConfig()
        let score = ComplianceScorer.score(for: violations, scoring: scoring)
        // 2 errors × 10 + 1 warning × 3 = 23; 100 - 23 = 77
        #expect(abs(score - 77.0) < 0.001)
    }

    @Test func complianceScoreEUErrorWeighted() {
        let violations: [Violation] = [
            makeViolation(.missingAccessibilityLabel, severity: .error, eu: true)
        ]
        let scoring = ScoringConfig()
        let score = ComplianceScorer.score(for: violations, scoring: scoring)
        // EU-required error: 10 × 2.0 = 20; 100 - 20 = 80
        #expect(abs(score - 80.0) < 0.001)
    }

    @Test func euComplianceFailsWithErrors() {
        var report = LintReport()
        report.violations = [makeViolation(.missingAccessibilityLabel, severity: .error, eu: true)]
        #expect(report.hasErrors)
    }

    @Test func euCompliancePassesWithOnlyWarnings() {
        var report = LintReport()
        report.violations = [makeViolation(.missingAccessibilityHint, severity: .warning, eu: false)]
        #expect(!report.hasErrors)
    }

    // MARK: - Config loading

    @Test func configLoadFallsBackToDefault() {
        let config = LinterConfig.load(from: "/this/path/does/not/exist.json")
        #expect(!config.rules.isEmpty)
        #expect(config.rule(for: .missingAccessibilityLabel) != nil)
    }

    // MARK: - Helpers

    private func lint(code: String, fileName: String = "Test.swift") throws -> [Violation] {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent(fileName)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try code.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        // Default config excludes "Test" via ignoreFiles, so use a clean config that won't skip.
        var config = LinterConfig.default
        config.ignoreFiles = []
        let linter = AccessibilityLinter(config: config)
        return linter.lint(path: url.path).violations
    }

    private func makeViolation(
        _ type: ViolationType,
        severity: Severity,
        eu: Bool
    ) -> Violation {
        Violation(
            file: "test.swift",
            line: 1,
            column: 1,
            type: type,
            severity: severity,
            message: "test",
            suggestion: "test",
            wcagLevel: "A",
            affectsEUCompliance: eu
        )
    }
}
