struct ColorAnalyzer: Analyzer {
    func analyze(lines: [String], file: String, config: LinterConfig) -> [Violation] {
        guard config.isEnabled(.colorOnlyIndicator) else { return [] }

        var violations: [Violation] = []
        for (index, rawLine) in lines.enumerated() {
            let lineNumber = index + 1
            if rawLine.contains("\"Color only indicates\"") ||
               (rawLine.contains("color:") && !rawLine.contains("icon") && !rawLine.contains("text")) {
                violations.append(.make(
                    type: .colorOnlyIndicator,
                    file: file,
                    line: lineNumber,
                    column: LineHelpers.leadingColumn(rawLine),
                    message: "Information conveyed by color alone",
                    suggestion: "Add a text label, icon, or pattern alongside the color",
                    config: config
                ))
            }
        }
        return violations
    }
}
