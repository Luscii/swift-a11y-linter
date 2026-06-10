struct CustomControlAnalyzer: Analyzer {
    func analyze(lines: [String], file: String, config: LinterConfig) -> [Violation] {
        guard config.isEnabled(.inaccessibleCustomControl) else { return [] }

        var violations: [Violation] = []
        for (index, rawLine) in lines.enumerated() {
            let lineNumber = index + 1
            let isStack = rawLine.contains("ZStack")
                || rawLine.contains("HStack")
                || rawLine.contains("VStack")
            guard isStack else { continue }

            guard isInteractive(startLine: lineNumber, lines: lines) else { continue }

            if !LineHelpers.hasAccessibilityModifier(startLine: lineNumber, lines: lines, modifier: "accessibilityElement"),
               !LineHelpers.hasAccessibilityModifier(startLine: lineNumber, lines: lines, modifier: "accessibilityLabel"),
               !LineHelpers.hasAccessibilityModifier(startLine: lineNumber, lines: lines, modifier: "accessibilityHidden") {
                violations.append(.make(
                    type: .inaccessibleCustomControl,
                    file: file,
                    line: lineNumber,
                    column: LineHelpers.leadingColumn(rawLine),
                    message: "Interactive container lacks accessibility wrapper",
                    suggestion: "Add .accessibilityElement(children: .combine) or .accessibilityLabel(\"…\")",
                    config: config
                ))
            }
        }
        return violations
    }

    private func isInteractive(startLine: Int, lines: [String]) -> Bool {
        let endLine = min(startLine + 10, lines.count)
        for i in (startLine - 1)..<endLine {
            let line = lines[i]
            if line.contains("onTapGesture") || line.contains("onLongPressGesture") {
                return true
            }
        }
        return false
    }
}
