protocol Analyzer {
    func analyze(lines: [String], file: String, config: LinterConfig) -> [Violation]
}
