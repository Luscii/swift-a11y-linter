struct CLIReporter: Reporter {
    func report(_ report: LintReport) {
        if report.violations.isEmpty {
            print("✅ No accessibility violations found! (\(report.filesScanned) files scanned)")
            print(String(format: "📊 Compliance score: %.1f%%", report.complianceScore))
            return
        }

        print("⚠️  Found \(report.violations.count) accessibility violation(s):\n")

        for violation in report.violations {
            let icon: String
            switch violation.severity {
            case .error: icon = "❌"
            case .warning: icon = "⚠️ "
            case .info: icon = "ℹ️ "
            }
            print("\(icon) \(violation.file):\(violation.line):\(violation.column): \(violation.severity.rawValue): \(violation.message) [\(violation.type.rawValue) · WCAG \(violation.wcagLevel)]")
            print("    💡 \(violation.suggestion)")
        }

        print("")
        print("📊 Files scanned:  \(report.filesScanned)")
        print("❌ Errors:         \(report.errorCount)")
        print("⚠️  Warnings:       \(report.warningCount)")
        print("ℹ️  Info:           \(report.infoCount)")
        print(String(format: "📈 Compliance:     %.1f%%", report.complianceScore))
    }
}
