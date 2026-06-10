enum ComplianceScorer {
    static func score(for violations: [Violation], scoring: ScoringConfig) -> Double {
        var penalty: Double = 0
        for violation in violations {
            let base: Double
            switch violation.severity {
            case .error: base = scoring.errorPenalty
            case .warning: base = scoring.warningPenalty
            case .info: base = scoring.infoPenalty
            }
            let multiplier = (violation.severity == .error && violation.affectsEUCompliance)
                ? scoring.euRequiredErrorWeight
                : 1.0
            penalty += base * multiplier
        }
        return max(0, 100 - penalty)
    }
}
