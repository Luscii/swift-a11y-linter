struct MediaAnalyzer: Analyzer {
    func analyze(lines: [String], file: String, config: LinterConfig) -> [Violation] {
        var violations: [Violation] = []

        for (index, rawLine) in lines.enumerated() {
            let lineNumber = index + 1

            if config.isEnabled(.missingVideoSubtitles),
               rawLine.contains("AVPlayer") || rawLine.contains("VideoPlayer") {
                let hasCaptions = LineHelpers.hasAccessibilityModifier(startLine: lineNumber, lines: lines, modifier: "accessibilityHint")
                    || LineHelpers.hasAccessibilityModifier(startLine: lineNumber, lines: lines, modifier: "accessibilityLabel")
                    || rawLine.contains("captions")
                    || rawLine.contains("subtitles")
                if !hasCaptions {
                    violations.append(.make(
                        type: .missingVideoSubtitles,
                        file: file,
                        line: lineNumber,
                        column: LineHelpers.leadingColumn(rawLine),
                        message: "Video element missing captions/subtitles",
                        suggestion: "Provide captions or subtitles for video content",
                        config: config
                    ))
                }
            }

            if config.isEnabled(.autoplayWithoutControl),
               rawLine.contains("autoplay"),
               !rawLine.contains("false") {
                violations.append(.make(
                    type: .autoplayWithoutControl,
                    file: file,
                    line: lineNumber,
                    column: LineHelpers.leadingColumn(rawLine),
                    message: "Media autoplays without user control",
                    suggestion: "Disable autoplay or provide a visible pause control",
                    config: config
                ))
            }
        }

        return violations
    }
}
