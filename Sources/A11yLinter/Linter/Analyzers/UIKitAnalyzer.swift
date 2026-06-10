import Foundation

struct UIKitAnalyzer: Analyzer {
    func analyze(lines: [String], file: String, config: LinterConfig) -> [Violation] {
        var violations: [Violation] = []

        for (index, rawLine) in lines.enumerated() {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            if LineHelpers.shouldSkipLine(trimmed) { continue }
            let lineNumber = index + 1

            if config.isEnabled(.missingImageDescription),
               trimmed.contains("UIImageView("),
               !lineHasAssignment(rawLine, property: "accessibilityLabel") {
                violations.append(.make(
                    type: .missingImageDescription,
                    file: file,
                    line: lineNumber,
                    column: LineHelpers.leadingColumn(rawLine),
                    message: "UIImageView missing accessibilityLabel",
                    suggestion: "imageView.accessibilityLabel = \"description\"",
                    config: config
                ))
            }

            if config.isEnabled(.insufficientTouchTarget),
               trimmed.contains("UIButton(") || trimmed.contains("setFrame") || trimmed.contains(".frame(") {
                if let size = LineHelpers.extractFrameSize(rawLine) {
                    let minimum = config.rule(for: .insufficientTouchTarget)?.minimumSize ?? 44
                    if size < minimum {
                        violations.append(.make(
                            type: .insufficientTouchTarget,
                            file: file,
                            line: lineNumber,
                            column: LineHelpers.leadingColumn(rawLine),
                            message: "Touch target size \(size)pt is less than \(minimum)pt minimum",
                            suggestion: "Increase touch target to at least \(minimum)×\(minimum) points",
                            config: config
                        ))
                    }
                }
            }
        }

        return violations
    }

    private func lineHasAssignment(_ line: String, property: String) -> Bool {
        return line.contains(property) && (line.contains("=") || line.contains(":"))
    }
}
