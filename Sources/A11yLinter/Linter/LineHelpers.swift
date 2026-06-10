import Foundation

enum LineHelpers {
    /// Returns true if `modifier` is applied to the view starting at `startLine`.
    /// Tracks braces so we know when the view's body ends, then continues across
    /// chained modifier lines (those starting with `.`) which sit after the closing brace.
    static func hasAccessibilityModifier(
        startLine: Int,
        lines: [String],
        modifier: String,
        lookahead: Int = 20
    ) -> Bool {
        let endLine = min(startLine + lookahead, lines.count)
        var braceCount = 0
        var bodyClosed = false

        for i in (startLine - 1)..<endLine {
            let line = lines[i].trimmingCharacters(in: .whitespaces)

            if line.contains(".\(modifier)") {
                return true
            }

            braceCount += line.filter { $0 == "{" }.count
            braceCount -= line.filter { $0 == "}" }.count

            if !bodyClosed, braceCount <= 0, i > startLine - 1 {
                bodyClosed = true
                continue
            }

            // After the view's body has closed, keep scanning only while we
            // remain in the chain of modifiers attached to this element.
            if bodyClosed {
                if line.isEmpty { continue }
                if !line.hasPrefix(".") { break }
            }
        }

        return false
    }

    static func extractIdentifier(startLine: Int, lines: [String]) -> String? {
        let endLine = min(startLine + 20, lines.count)

        for i in (startLine - 1)..<endLine {
            let line = lines[i].trimmingCharacters(in: .whitespaces)

            if line.contains(".accessibilityIdentifier") {
                if let match = line.range(of: "\\.accessibilityIdentifier\\s*\\(\\s*\"([^\"]+)\"\\s*\\)", options: .regularExpression) {
                    let matched = String(line[match])
                    if let idMatch = matched.range(of: "\"([^\"]+)\"", options: .regularExpression) {
                        let id = String(matched[idMatch])
                        return id.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    }
                }
            }
        }

        return nil
    }

    /// Returns the 1-based column of the first non-whitespace character on the line.
    static func leadingColumn(_ line: String) -> Int {
        line.firstIndex(where: { !$0.isWhitespace })
            .map { line.distance(from: line.startIndex, to: $0) + 1 } ?? 1
    }

    /// Returns the 1-based column at which `range` starts within `line`.
    static func column(of range: Range<String.Index>, in line: String) -> Int {
        line.distance(from: line.startIndex, to: range.lowerBound) + 1
    }

    /// Pulls the first numeric width/height/size value out of a single frame() call line.
    static func extractFrameSize(_ line: String) -> Int? {
        guard let range = line.range(of: #"(?:width|height|size).*?(\d+)"#, options: .regularExpression) else {
            return nil
        }
        let matched = String(line[range])
        let numbers = matched.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }
        return Int(numbers.first ?? "0")
    }

    static func shouldSkipLine(_ trimmed: String) -> Bool {
        if trimmed.hasPrefix("//") { return true }
        if trimmed.hasPrefix("/*") || trimmed.hasPrefix("*") { return true }
        if trimmed.hasPrefix("import ") { return true }
        return false
    }
}

extension Violation {
    /// Builds a Violation using the rule's WCAG and EU metadata from config (with sensible fallbacks).
    static func make(
        type: ViolationType,
        file: String,
        line: Int,
        column: Int,
        message: String,
        suggestion: String,
        config: LinterConfig,
        severityOverride: Severity? = nil
    ) -> Violation {
        let rule = config.rule(for: type)
        return Violation(
            file: file,
            line: line,
            column: column,
            type: type,
            severity: severityOverride ?? rule?.severity ?? .warning,
            message: message,
            suggestion: suggestion,
            wcagLevel: rule?.wcagLevel ?? "N/A",
            affectsEUCompliance: rule?.requiresEUCompliance ?? false
        )
    }
}
