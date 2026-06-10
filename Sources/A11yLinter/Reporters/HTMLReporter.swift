import Foundation

struct HTMLReporter: Reporter {
    static let defaultOutputPath = "a11y-report.html"
    let outputPath: String

    init(outputPath: String = HTMLReporter.defaultOutputPath) {
        self.outputPath = outputPath
    }

    func report(_ report: LintReport) {
        let html = render(report)
        do {
            try html.write(toFile: outputPath, atomically: true, encoding: .utf8)
            print("✅ HTML report saved to: \(outputPath)")
        } catch {
            FileHandle.standardError.write("❌ Failed to write HTML report: \(error)\n".data(using: .utf8) ?? Data())
        }
    }

    private func render(_ report: LintReport) -> String {
        let scoreColor = report.complianceScore >= 80 ? "green" : "red"
        var html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <title>Accessibility Lint Report</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; margin: 24px; background: #f5f5f5; color: #1a202c; }
                .summary { background: white; padding: 24px; border-radius: 8px; margin-bottom: 24px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
                .filters { background: white; padding: 16px 24px; border-radius: 8px; margin-bottom: 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); display: flex; gap: 8px; flex-wrap: wrap; align-items: center; }
                .filters strong { margin-right: 8px; }
                .filter-btn { border: 1px solid #cbd5e0; background: #edf2f7; color: #1a202c; padding: 6px 14px; border-radius: 999px; cursor: pointer; font: inherit; font-size: 13px; }
                .filter-btn[aria-pressed="true"] { background: #1a202c; color: white; border-color: #1a202c; }
                .filter-btn:focus-visible { outline: 2px solid #4299e1; outline-offset: 2px; }
                .violation { background: white; padding: 16px; margin: 12px 0; border-left: 4px solid; border-radius: 4px; box-shadow: 0 1px 2px rgba(0,0,0,0.06); }
                .violation.hidden { display: none; }
                .error { border-left-color: #e53e3e; }
                .warning { border-left-color: #f6ad55; }
                .info { border-left-color: #4299e1; }
                .type { font-weight: 700; font-size: 14px; }
                .meta { color: #4a5568; font-size: 12px; margin-top: 4px; }
                .suggestion { margin-top: 12px; padding: 12px; background: #f7fafc; border-radius: 4px; font-style: italic; }
                .score { font-size: 36px; font-weight: 700; }
                .empty-state { background: white; padding: 24px; border-radius: 8px; text-align: center; color: #4a5568; }
                .empty-state.hidden { display: none; }
            </style>
        </head>
        <body>
            <div class="summary">
                <h1>Accessibility Compliance Report</h1>
                <div class="score" style="color: \(scoreColor);">\(String(format: "%.1f", report.complianceScore))%</div>
                <p>Files: \(report.filesScanned) · Lines: \(report.totalLines)</p>
                <p>Errors: \(report.errorCount) · Warnings: \(report.warningCount) · Info: \(report.infoCount)</p>
            </div>
            <div class="filters" role="group" aria-label="Filter violations by severity">
                <strong>Show:</strong>
                <button type="button" class="filter-btn" data-filter="all" aria-pressed="true">All (\(report.violations.count))</button>
                <button type="button" class="filter-btn" data-filter="error" aria-pressed="false">Errors (\(report.errorCount))</button>
                <button type="button" class="filter-btn" data-filter="warning" aria-pressed="false">Warnings (\(report.warningCount))</button>
                <button type="button" class="filter-btn" data-filter="info" aria-pressed="false">Info (\(report.infoCount))</button>
            </div>
            <div id="violations">
        """

        for violation in report.violations {
            html += """

            <div class="violation \(violation.severity.rawValue)" data-severity="\(violation.severity.rawValue)">
                <div class="type">\(violation.type.rawValue)</div>
                <div class="meta">\(violation.file):\(violation.line):\(violation.column) · WCAG \(violation.wcagLevel) · EU: \(violation.affectsEUCompliance ? "required" : "—")</div>
                <p>\(violation.message)</p>
                <div class="suggestion">💡 \(violation.suggestion)</div>
            </div>
            """
        }

        html += """

            </div>
            <div class="empty-state hidden" id="empty-state">No violations of this severity.</div>
            <script>
                (function() {
                    const buttons = document.querySelectorAll('.filter-btn');
                    const violations = document.querySelectorAll('.violation');
                    const emptyState = document.getElementById('empty-state');
                    buttons.forEach(btn => btn.addEventListener('click', () => {
                        const filter = btn.dataset.filter;
                        buttons.forEach(b => b.setAttribute('aria-pressed', b === btn ? 'true' : 'false'));
                        let visible = 0;
                        violations.forEach(v => {
                            const match = filter === 'all' || v.dataset.severity === filter;
                            v.classList.toggle('hidden', !match);
                            if (match) visible++;
                        });
                        emptyState.classList.toggle('hidden', visible > 0);
                    }));
                })();
            </script>
        </body>
        </html>
        """
        return html
    }
}
