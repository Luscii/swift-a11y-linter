struct LintReport: Codable {
    var violations: [Violation] = []
    var filesScanned: Int = 0
    var filesSkipped: Int = 0
    var totalLines: Int = 0
    var complianceScore: Double = 100.0

    var errorCount: Int { violations.lazy.filter { $0.severity == .error }.count }
    var warningCount: Int { violations.lazy.filter { $0.severity == .warning }.count }
    var infoCount: Int { violations.lazy.filter { $0.severity == .info }.count }

    var hasErrors: Bool { errorCount > 0 }
}
