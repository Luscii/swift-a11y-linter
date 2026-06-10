struct GitHubReporter: Reporter {
    func report(_ report: LintReport) {
        for violation in report.violations {
            let level: String
            switch violation.severity {
            case .error: level = "error"
            case .warning: level = "warning"
            case .info: level = "notice"
            }
            print("::\(level) file=\(violation.file),line=\(violation.line),col=\(violation.column),title=\(violation.type.rawValue)::\(violation.message)")
        }

        if report.violations.isEmpty {
            print("::notice::✅ No accessibility violations found! (\(report.filesScanned) files scanned)")
        } else {
            print("::warning::Found \(report.violations.count) accessibility violation(s) — compliance \(String(format: "%.1f", report.complianceScore))%")
        }
    }
}
