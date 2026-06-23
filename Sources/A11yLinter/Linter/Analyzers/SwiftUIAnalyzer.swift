import Foundation

struct SwiftUIAnalyzer: Analyzer {
    /// Per-line state shared by the individual element checks.
    private struct Context {
        let trimmed: String
        let lines: [String]
        let file: String
        let lineNumber: Int
        let config: LinterConfig

        func hasModifier(_ modifier: String) -> Bool {
            LineHelpers.hasAccessibilityModifier(startLine: lineNumber, lines: lines, modifier: modifier)
        }
    }

    func analyze(lines: [String], file: String, config: LinterConfig) -> [Violation] {
        var violations: [Violation] = []

        for (index, rawLine) in lines.enumerated() {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            if LineHelpers.shouldSkipLine(trimmed) { continue }
            if trimmed.contains("enum ") || trimmed.contains("struct ") || trimmed.contains("class ") {
                continue
            }

            let ctx = Context(
                trimmed: trimmed,
                lines: lines,
                file: file,
                lineNumber: index + 1,
                config: config
            )
            checkImage(ctx, into: &violations)
            checkTextField(ctx, into: &violations)
            checkSwiftUIElements(ctx, into: &violations)
        }

        return violations
    }

    private func checkImage(_ ctx: Context, into violations: inout [Violation]) {
        guard ctx.trimmed.contains("Image(") else { return }
        guard ctx.config.isEnabled(.missingImageDescription) else { return }

        // Decorative images explicitly opt out with an empty label
        if ctx.trimmed.contains("decorative") { return }

        if !ctx.hasModifier("accessibilityLabel"), !ctx.hasModifier("accessibilityHidden") {
            violations.append(.make(
                type: .missingImageDescription,
                file: ctx.file,
                line: ctx.lineNumber,
                column: LineHelpers.leadingColumn(ctx.trimmed),
                message: "Image without accessibility description",
                suggestion: "Add .accessibilityLabel(\"description\") or mark decorative with .accessibilityHidden(true)",
                config: ctx.config
            ))
        }
    }

    private func checkTextField(_ ctx: Context, into violations: inout [Violation]) {
        guard ctx.trimmed.contains("TextField(") || ctx.trimmed.contains("SecureField(") else { return }
        guard ctx.config.isEnabled(.missingFormLabel) else { return }

        let hasLabel = ctx.hasModifier("accessibilityLabel")
        let hasSurroundingText = hasNearbyText(startLine: ctx.lineNumber, lines: ctx.lines)

        if !hasLabel && !hasSurroundingText {
            violations.append(.make(
                type: .missingFormLabel,
                file: ctx.file,
                line: ctx.lineNumber,
                column: LineHelpers.leadingColumn(ctx.trimmed),
                message: "TextField missing form label context",
                suggestion: "Add .accessibilityLabel(\"…\") or wrap with a Text() label",
                config: ctx.config
            ))
        }
    }

    private func hasNearbyText(startLine: Int, lines: [String]) -> Bool {
        let start = max(0, startLine - 4)
        let end = min(startLine + 1, lines.count)
        return (start..<end).contains { lines[$0].contains("Text(") }
    }

    private func checkSwiftUIElements(_ ctx: Context, into violations: inout [Violation]) {
        for element in SwiftUIElement.allCases {
            checkElement(element.rawValue, meta: element, ctx: ctx, into: &violations)
        }

        for custom in ctx.config.customElements {
            checkElement(custom, meta: nil, ctx: ctx, into: &violations)
        }
    }

    private func checkElement(_ elementName: String, meta: SwiftUIElement?, ctx: Context, into violations: inout [Violation]) {
        // Element name must be a standalone token, not a substring of a larger
        // identifier (e.g. `Link` inside `handleDeepLink`) or a member call (e.g. `obj.Menu`).
        let boundary = "(?<![A-Za-z0-9_.])"
        let patterns = [
            "\(boundary)\(elementName)\\s*\\(",
            "\(boundary)\(elementName)\\s*\\{",
            "\(boundary)\(elementName)<"
        ]

        var matchRange: Range<String.Index>?
        for pattern in patterns {
            if let range = ctx.trimmed.range(of: pattern, options: .regularExpression) {
                matchRange = range
                break
            }
        }
        guard let range = matchRange else { return }
        let column = LineHelpers.column(of: range, in: ctx.trimmed)

        checkIdentifier(elementName, meta: meta, column: column, ctx: ctx, into: &violations)
        checkButtonLabel(elementName, meta: meta, column: column, ctx: ctx, into: &violations)
        checkHint(elementName, meta: meta, column: column, ctx: ctx, into: &violations)
        checkHidden(elementName, column: column, ctx: ctx, into: &violations)
    }

    private func checkIdentifier(
        _ elementName: String,
        meta: SwiftUIElement?,
        column: Int,
        ctx: Context,
        into violations: inout [Violation]
    ) {
        let requiresIdentifier = ctx.config.requireAll || (meta?.requiresIdentifier ?? false)
        guard requiresIdentifier, ctx.config.isEnabled(.missingAccessibilityIdentifier) else { return }

        if !ctx.hasModifier("accessibilityIdentifier") {
            let severity: Severity? = ctx.config.strict ? .error : nil
            violations.append(.make(
                type: .missingAccessibilityIdentifier,
                file: ctx.file,
                line: ctx.lineNumber,
                column: column,
                message: "\(elementName) is missing accessibility identifier",
                suggestion: "Add .accessibilityIdentifier(\"uniqueId\")",
                config: ctx.config,
                severityOverride: severity
            ))
        } else if let id = LineHelpers.extractIdentifier(startLine: ctx.lineNumber, lines: ctx.lines),
                  id.count < ctx.config.minIdentifierLength,
                  ctx.config.isEnabled(.identifierTooShort) {
            violations.append(.make(
                type: .identifierTooShort,
                file: ctx.file,
                line: ctx.lineNumber,
                column: column,
                message: "\(elementName) identifier '\(id)' is shorter than \(ctx.config.minIdentifierLength) characters",
                suggestion: "Use a longer, more descriptive identifier",
                config: ctx.config
            ))
        }
    }

    private func checkButtonLabel(
        _ elementName: String,
        meta: SwiftUIElement?,
        column: Int,
        ctx: Context,
        into violations: inout [Violation]
    ) {
        let requiresLabel = meta?.requiresLabel ?? true
        guard requiresLabel, ctx.config.isEnabled(.missingAccessibilityLabel), elementName == "Button" else { return }

        // Buttons need explicit accessibility labels when they wrap a non-text child (e.g. an Image)
        guard !ctx.hasModifier("accessibilityLabel"),
              buttonWrapsNonText(startLine: ctx.lineNumber, lines: ctx.lines) else { return }

        violations.append(.make(
            type: .missingAccessibilityLabel,
            file: ctx.file,
            line: ctx.lineNumber,
            column: column,
            message: "Button missing accessibilityLabel",
            suggestion: "Add .accessibilityLabel(\"action description\")",
            config: ctx.config
        ))
    }

    private func checkHint(
        _ elementName: String,
        meta: SwiftUIElement?,
        column: Int,
        ctx: Context,
        into violations: inout [Violation]
    ) {
        guard ctx.config.isEnabled(.missingAccessibilityHint) else { return }
        guard !ctx.hasModifier("accessibilityHint"), meta?.requiresIdentifier ?? false else { return }

        violations.append(.make(
            type: .missingAccessibilityHint,
            file: ctx.file,
            line: ctx.lineNumber,
            column: column,
            message: "\(elementName) could benefit from an accessibility hint",
            suggestion: "Add .accessibilityHint(\"Double tap to perform action\")",
            config: ctx.config
        ))
    }

    private func checkHidden(
        _ elementName: String,
        column: Int,
        ctx: Context,
        into violations: inout [Violation]
    ) {
        guard ctx.config.isEnabled(.unexpectedAccessibilityHidden) else { return }
        guard ctx.hasModifier("accessibilityHidden") else { return }

        violations.append(.make(
            type: .unexpectedAccessibilityHidden,
            file: ctx.file,
            line: ctx.lineNumber,
            column: column,
            message: "\(elementName) is marked as accessibilityHidden - verify this is intentional",
            suggestion: "Confirm the element should be hidden from assistive technologies",
            config: ctx.config
        ))
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
