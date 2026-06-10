struct Violation: Codable {
    let file: String
    let line: Int
    let column: Int
    let type: ViolationType
    let severity: Severity
    let message: String
    let suggestion: String
    let wcagLevel: String
    let affectsEUCompliance: Bool
}
