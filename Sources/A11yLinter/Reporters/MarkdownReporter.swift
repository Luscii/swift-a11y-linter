struct MarkdownReporter: Reporter {
    func report(_ report: LintReport) {
        print(formatSummary(report))

        let errors = report.violations.filter { $0.severity == .error }
        let warnings = report.violations.filter { $0.severity == .warning }
        let infos = report.violations.filter { $0.severity == .info }

        if !errors.isEmpty {
            print("\n## ❌ Errors\n")
            for v in errors { print(formatViolation(v)) }
        }
        if !warnings.isEmpty {
            print("\n## ⚠️ Warnings\n")
            for v in warnings { print(formatViolation(v)) }
        }
        if !infos.isEmpty {
            print("\n## ℹ️ Info\n")
            for v in infos { print(formatViolation(v)) }
        }
    }

    private func formatSummary(_ report: LintReport) -> String {
        let euReady = report.errorCount == 0 ? "✅ YES" : "❌ NO"
        let wcagPass = report.complianceScore >= 80 ? "✅ PASS" : "❌ FAIL"
        return """
        # 📊 Accessibility Compliance Report

        | Metric | Value |
        |--------|-------|
        | Files Scanned | \(report.filesScanned) |
        | Total Lines | \(report.totalLines) |
        | Errors | \(report.errorCount) |
        | Warnings | \(report.warningCount) |
        | Info | \(report.infoCount) |
        | Compliance Score | \(String(format: "%.1f", report.complianceScore))% |
        | WCAG 2.1 Level AA | \(wcagPass) |
        | EU Regulation Ready | \(euReady) |
        """
    }

    private func formatViolation(_ v: Violation) -> String {
        return """
        **\(v.type.rawValue)** — `\(v.file):\(v.line):\(v.column)`

        > \(v.message)

        💡 *\(v.suggestion)*

        WCAG: \(v.wcagLevel) · EU Compliance: \(v.affectsEUCompliance ? "⚠️ required" : "—")

        ---
        """
    }
}
