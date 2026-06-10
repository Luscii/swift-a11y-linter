import Foundation

struct RuleConfig: Codable {
    var enabled: Bool = true
    var severity: Severity
    var wcagLevel: String
    var wcagSection: String?
    var description: String?
    var requiresEUCompliance: Bool
    var minimumSize: Int?
    var minimumRatioAA: Double?
    var minimumRatioAAA: Double?
}

struct ComplianceConfig: Codable {
    var euRegulation: Bool = true
    var wcagLevel: String = "AA"
    var minimumComplianceScore: Double = 80
    var enforceCriticalRules: Bool = true
    var regulations: [String] = []
}

struct OutputConfig: Codable {
    var formats: [String] = ["text", "json", "markdown", "html"]
    var defaultFormat: String = "text"
    var includeSourceCode: Bool = true
    var includeSuggestions: Bool = true
}

struct ScoringConfig: Codable {
    var errorPenalty: Double = 10
    var warningPenalty: Double = 3
    var infoPenalty: Double = 1
    var euRequiredErrorWeight: Double = 2.0
}

struct LinterConfig: Codable {
    var version: String?
    var rules: [String: RuleConfig]
    var compliance: ComplianceConfig
    var excludePaths: [String]
    var output: OutputConfig
    var scoring: ScoringConfig

    var ignoreFiles: [String] = ["Preview", "Mock", "Test"]
    var customElements: [String] = []
    var minIdentifierLength: Int = 3
    var strict: Bool = false
    var requireAll: Bool = false

    enum CodingKeys: String, CodingKey {
        case version, rules, compliance, excludePaths, output, scoring
        case ignoreFiles, customElements, minIdentifierLength, strict, requireAll
    }

    init(
        version: String? = "1.0.0",
        rules: [String: RuleConfig],
        compliance: ComplianceConfig = ComplianceConfig(),
        excludePaths: [String] = LinterConfig.defaultExcludePaths,
        output: OutputConfig = OutputConfig(),
        scoring: ScoringConfig = ScoringConfig(),
        ignoreFiles: [String] = ["Preview", "Mock", "Test"],
        customElements: [String] = [],
        minIdentifierLength: Int = 3,
        strict: Bool = false,
        requireAll: Bool = false
    ) {
        self.version = version
        self.rules = rules
        self.compliance = compliance
        self.excludePaths = excludePaths
        self.output = output
        self.scoring = scoring
        self.ignoreFiles = ignoreFiles
        self.customElements = customElements
        self.minIdentifierLength = minIdentifierLength
        self.strict = strict
        self.requireAll = requireAll
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.version = try container.decodeIfPresent(String.self, forKey: .version)
        self.rules = try container.decodeIfPresent([String: RuleConfig].self, forKey: .rules) ?? LinterConfig.defaultRules
        self.compliance = try container.decodeIfPresent(ComplianceConfig.self, forKey: .compliance) ?? ComplianceConfig()
        self.excludePaths = try container.decodeIfPresent([String].self, forKey: .excludePaths) ?? LinterConfig.defaultExcludePaths
        self.output = try container.decodeIfPresent(OutputConfig.self, forKey: .output) ?? OutputConfig()
        self.scoring = try container.decodeIfPresent(ScoringConfig.self, forKey: .scoring) ?? ScoringConfig()
        self.ignoreFiles = try container.decodeIfPresent([String].self, forKey: .ignoreFiles) ?? ["Preview", "Mock", "Test"]
        self.customElements = try container.decodeIfPresent([String].self, forKey: .customElements) ?? []
        self.minIdentifierLength = try container.decodeIfPresent(Int.self, forKey: .minIdentifierLength) ?? 3
        self.strict = try container.decodeIfPresent(Bool.self, forKey: .strict) ?? false
        self.requireAll = try container.decodeIfPresent(Bool.self, forKey: .requireAll) ?? false
    }

    func rule(for type: ViolationType) -> RuleConfig? {
        rules[type.rawValue]
    }

    func isEnabled(_ type: ViolationType) -> Bool {
        rule(for: type)?.enabled ?? true
    }

    static func load(from path: String = "a11y.config.json") -> LinterConfig {
        guard FileManager.default.fileExists(atPath: path),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return .default
        }
        do {
            return try JSONDecoder().decode(LinterConfig.self, from: data)
        } catch {
            let message = "⚠️  Failed to parse config at \(path): \(error). Using defaults.\n"
            FileHandle.standardError.write(Data(message.utf8))
            return .default
        }
    }

    static let defaultExcludePaths = [".build", "Tests", "Examples", "Pods", ".git", "node_modules", ".swiftpm"]

    static let `default` = LinterConfig(
        rules: LinterConfig.defaultRules
    )

    static let defaultRules: [String: RuleConfig] = [
        ViolationType.missingAccessibilityLabel.rawValue: RuleConfig(
            severity: .error,
            wcagLevel: "A",
            wcagSection: "1.1.1",
            description: "Interactive elements must have accessibility labels",
            requiresEUCompliance: true
        ),
        ViolationType.missingImageDescription.rawValue: RuleConfig(
            severity: .error,
            wcagLevel: "A",
            wcagSection: "1.1.1",
            description: "All meaningful images must have descriptions",
            requiresEUCompliance: true
        ),
        ViolationType.missingFormLabel.rawValue: RuleConfig(
            severity: .error,
            wcagLevel: "A",
            wcagSection: "3.3.2",
            description: "Form controls must have associated labels",
            requiresEUCompliance: true
        ),
        ViolationType.missingAccessibilityHint.rawValue: RuleConfig(
            severity: .warning,
            wcagLevel: "AA",
            wcagSection: "3.2.1",
            description: "Complex actions should have hints explaining consequences",
            requiresEUCompliance: false
        ),
        ViolationType.insufficientTouchTarget.rawValue: RuleConfig(
            severity: .error,
            wcagLevel: "AAA",
            wcagSection: "2.5.5",
            description: "Touch targets must be at least 44×44 points",
            requiresEUCompliance: true,
            minimumSize: 44
        ),
        ViolationType.lowContrastRatio.rawValue: RuleConfig(
            severity: .error,
            wcagLevel: "AA",
            wcagSection: "1.4.3",
            description: "Text contrast must be at least 4.5:1 (AA) or 7:1 (AAA)",
            requiresEUCompliance: true,
            minimumRatioAA: 4.5,
            minimumRatioAAA: 7.0
        ),
        ViolationType.colorOnlyIndicator.rawValue: RuleConfig(
            severity: .warning,
            wcagLevel: "A",
            wcagSection: "1.4.1",
            description: "Color must not be the only way to convey information",
            requiresEUCompliance: true
        ),
        ViolationType.inaccessibleCustomControl.rawValue: RuleConfig(
            severity: .warning,
            wcagLevel: "A",
            wcagSection: "4.1.2",
            description: "Custom controls must have proper accessibility semantics",
            requiresEUCompliance: true
        ),
        ViolationType.missingVideoSubtitles.rawValue: RuleConfig(
            severity: .error,
            wcagLevel: "A",
            wcagSection: "1.2.2",
            description: "All videos must have captions or transcripts",
            requiresEUCompliance: true
        ),
        ViolationType.missingAccessibilityIdentifier.rawValue: RuleConfig(
            severity: .info,
            wcagLevel: "N/A",
            wcagSection: "N/A",
            description: "Elements should have accessibility identifiers for testing",
            requiresEUCompliance: false
        ),
        ViolationType.autoplayWithoutControl.rawValue: RuleConfig(
            severity: .warning,
            wcagLevel: "A",
            wcagSection: "2.2.2",
            description: "Autoplaying media must have pause/stop controls",
            requiresEUCompliance: true
        ),
        ViolationType.poorReadingOrder.rawValue: RuleConfig(
            severity: .warning,
            wcagLevel: "A",
            wcagSection: "2.4.3",
            description: "Focus order must be logical and intuitive",
            requiresEUCompliance: true
        ),
        ViolationType.temporalMediaWithoutTranscript.rawValue: RuleConfig(
            severity: .error,
            wcagLevel: "A",
            wcagSection: "1.2.3",
            description: "All audio and video must have transcripts",
            requiresEUCompliance: true
        ),
        ViolationType.identifierTooShort.rawValue: RuleConfig(
            severity: .warning,
            wcagLevel: "N/A",
            description: "Accessibility identifiers should be at least minIdentifierLength characters",
            requiresEUCompliance: false
        ),
        ViolationType.unexpectedAccessibilityHidden.rawValue: RuleConfig(
            severity: .warning,
            wcagLevel: "A",
            description: "Element is marked as accessibilityHidden - verify this is intentional",
            requiresEUCompliance: false
        )
    ]
}
