struct XcodeReporter: Reporter {
    func report(_ report: LintReport) {
        for violation in report.violations {
            let level: String
            switch violation.severity {
            case .error: level = "error"
            case .warning: level = "warning"
            case .info: level = "note"
            }
            print("\(violation.file):\(violation.line):\(violation.column): \(level): \(violation.message)")
        }

        if report.violations.isEmpty {
            print("✅ No accessibility violations found!")
        }
    }
}
