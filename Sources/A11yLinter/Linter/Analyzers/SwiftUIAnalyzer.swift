 import Foundation

struct SwiftUIAnalyzer: Analyzer {
    func analyze(lines: [String], file: String, config: LinterConfig) -> [Violation] {
        var violations: [Violation] = []

        for (index, rawLine) in lines.enumerated() {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            if LineHelpers.shouldSkipLine(trimmed) { continue }
            if trimmed.contains("enum ") || trimmed.contains("struct ") || trimmed.contains("class ") {
                continue
            }

            let lineNumber = index + 1

            checkImage(trimmed: trimmed, lines: lines, file: file, lineNumber: lineNumber, config: config, into: &violations)
            checkTextField(trimmed: trimmed, lines: lines, file: file, lineNumber: lineNumber, config: config, into: &violations)
            checkSwiftUIElements(trimmed: trimmed, lines: lines, file: file, lineNumber: lineNumber, config: config, into: &violations)
        }

        return violations
    }

    private func checkImage(trimmed: String, lines: [String], file: String, lineNumber: Int, config: LinterConfig, into violations: inout [Violation]) {
        guard trimmed.contains("Image(") else { return }
        guard config.isEnabled(.missingImageDescription) else { return }

        // Decorative images explicitly opt out with an empty label
        if trimmed.contains("decorative") { return }

        if !LineHelpers.hasAccessibilityModifier(startLine: lineNumber, lines: lines, modifier: "accessibilityLabel"),
           !LineHelpers.hasAccessibilityModifier(startLine: lineNumber, lines: lines, modifier: "accessibilityHidden") {
            violations.append(.make(
                type: .missingImageDescription,
                file: file,
                line: lineNumber,
                column: LineHelpers.leadingColumn(trimmed),
                message: "Image without accessibility description",
                suggestion: "Add .accessibilityLabel(\"description\") or mark decorative with .accessibilityHidden(true)",
                config: config
            ))
        }
    }

    private func checkTextField(trimmed: String, lines: [String], file: String, lineNumber: Int, config: LinterConfig, into violations: inout [Violation]) {
        guard trimmed.contains("TextField(") || trimmed.contains("SecureField(") else { return }
        guard config.isEnabled(.missingFormLabel) else { return }

        let hasLabel = LineHelpers.hasAccessibilityModifier(startLine: lineNumber, lines: lines, modifier: "accessibilityLabel")
        let hasSurroundingText = hasNearbyText(startLine: lineNumber, lines: lines)

        if !hasLabel && !hasSurroundingText {
            violations.append(.make(
                type: .missingFormLabel,
                file: file,
                line: lineNumber,
                column: LineHelpers.leadingColumn(trimmed),
                message: "TextField missing form label context",
                suggestion: "Add .accessibilityLabel(\"…\") or wrap with a Text() label",
                config: config
            ))
        }
    }

    private func hasNearbyText(startLine: Int, lines: [String]) -> Bool {
        let start = max(0, startLine - 4)
        let end = min(startLine + 1, lines.count)
        for i in start..<end {
            if lines[i].contains("Text(") { return true }
        }
        return false
    }

    private func checkSwiftUIElements(trimmed: String, lines: [String], file: String, lineNumber: Int, config: LinterConfig, into violations: inout [Violation]) {
        for element in SwiftUIElement.allCases {
            checkElement(element.rawValue,
                         elementMeta: element,
                         trimmed: trimmed,
                         lines: lines,
                         file: file,
                         lineNumber: lineNumber,
                         config: config,
                         into: &violations)
        }

        for custom in config.customElements {
            checkElement(custom,
                         elementMeta: nil,
                         trimmed: trimmed,
                         lines: lines,
                         file: file,
                         lineNumber: lineNumber,
                         config: config,
                         into: &violations)
        }
    }

    private func checkElement(
        _ elementName: String,
        elementMeta: SwiftUIElement?,
        trimmed: String,
        lines: [String],
        file: String,
        lineNumber: Int,
        config: LinterConfig,
        into violations: inout [Violation]
    ) {
        let patterns = [
            "\(elementName)\\s*\\(",
            "\(elementName)\\s*\\{",
            "\(elementName)<"
        ]

        var matchRange: Range<String.Index>?
        for pattern in patterns {
            if let range = trimmed.range(of: pattern, options: .regularExpression) {
                matchRange = range
                break
            }
        }
        guard let range = matchRange else { return }
        let column = LineHelpers.column(of: range, in: trimmed)

        let requiresIdentifier = config.requireAll || (elementMeta?.requiresIdentifier ?? false)
        let requiresLabel = elementMeta?.requiresLabel ?? true

        if requiresIdentifier && config.isEnabled(.missingAccessibilityIdentifier) {
            let hasIdentifier = LineHelpers.hasAccessibilityModifier(startLine: lineNumber, lines: lines, modifier: "accessibilityIdentifier")
            if !hasIdentifier {
                let severity: Severity? = config.strict ? .error : nil
                violations.append(.make(
                    type: .missingAccessibilityIdentifier,
                    file: file,
                    line: lineNumber,
                    column: column,
                    message: "\(elementName) is missing accessibility identifier",
                    suggestion: "Add .accessibilityIdentifier(\"uniqueId\")",
                    config: config,
                    severityOverride: severity
                ))
            } else if let id = LineHelpers.extractIdentifier(startLine: lineNumber, lines: lines),
                      id.count < config.minIdentifierLength,
                      config.isEnabled(.identifierTooShort) {
                violations.append(.make(
                    type: .identifierTooShort,
                    file: file,
                    line: lineNumber,
                    column: column,
                    message: "\(elementName) identifier '\(id)' is shorter than \(config.minIdentifierLength) characters",
                    suggestion: "Use a longer, more descriptive identifier",
                    config: config
                ))
            }
        }

        if requiresLabel && config.isEnabled(.missingAccessibilityLabel) && elementName == "Button" {
            // Buttons need explicit accessibility labels when they wrap a non-text child (e.g. an Image)
            if !LineHelpers.hasAccessibilityModifier(startLine: lineNumber, lines: lines, modifier: "accessibilityLabel"),
               buttonWrapsNonText(startLine: lineNumber, lines: lines) {
                violations.append(.make(
                    type: .missingAccessibilityLabel,
                    file: file,
                    line: lineNumber,
                    column: column,
                    message: "Button missing accessibilityLabel",
                    suggestion: "Add .accessibilityLabel(\"action description\")",
                    config: config
                ))
            }
        }

        if config.isEnabled(.missingAccessibilityHint) {
            let hasHint = LineHelpers.hasAccessibilityModifier(startLine: lineNumber, lines: lines, modifier: "accessibilityHint")
            if !hasHint && (elementMeta?.requiresIdentifier ?? false) {
                violations.append(.make(
                    type: .missingAccessibilityHint,
                    file: file,
                    line: lineNumber,
                    column: column,
                    message: "\(elementName) could benefit from an accessibility hint",
                    suggestion: "Add .accessibilityHint(\"Double tap to perform action\")",
                    config: config
                ))
            }
        }

        if config.isEnabled(.unexpectedAccessibilityHidden) {
            let hasHidden = LineHelpers.hasAccessibilityModifier(startLine: lineNumber, lines: lines, modifier: "accessibilityHidden")
            if hasHidden {
                violations.append(.make(
                    type: .unexpectedAccessibilityHidden,
                    file: file,
                    line: lineNumber,
                    column: column,
                    message: "\(elementName) is marked as accessibilityHidden - verify this is intentional",
                    suggestion: "Confirm the element should be hidden from assistive technologies",
                    config: config
                ))
            }
        }
    }

    private func buttonWrapsNonText(startLine: Int, lines: [String]) -> Bool {
        let endLine = min(startLine + 5, lines.count)
        for i in (startLine - 1)..<endLine {
            let line = lines[i]
            if line.contains("Image(") { return true }
            if line.contains("Symbol(") { return true }
        }
        return false
    }
}
