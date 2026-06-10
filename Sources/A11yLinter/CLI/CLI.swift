import Foundation

enum CLI {
    static let version = "2.0.0"

    static func run() {
        let arguments = CommandLine.arguments

        if arguments.contains("--help") || arguments.contains("-h") {
            printHelp()
            exit(0)
        }
        if arguments.contains("--version") {
            print("swift-a11y-linter version \(version)")
            exit(0)
        }

        let strict = arguments.contains("--strict")
        let requireAll = arguments.contains("--require-all")
        let verbose = arguments.contains("--verbose") || arguments.contains("-v")
        let configPath = extractArgValue(arguments, flag: "--config") ?? "a11y.config.json"
        let reporterType = extractArgValue(arguments, flag: "--reporter") ?? "cli"

        var path = "."
        for arg in arguments.dropFirst() where !arg.hasPrefix("-") {
            path = arg
            break
        }

        var config = LinterConfig.load(from: configPath)
        if strict { config.strict = true }
        if requireAll { config.requireAll = true }

        if verbose {
            print("🔍 swift-a11y-linter")
            print("📁 Linting path: \(path)")
            print("⚙️  Config: \(configPath)")
            print("📝 Reporter: \(reporterType)")
            print("")
        }

        let showProgress = isatty(fileno(stderr)) != 0 && !verbose

        let total = countSwiftFiles(at: path, config: config)
        let label = total == 1 ? "file" : "files"
        let banner = """
        🔍 swift-a11y-linter starting...
        📂 Discovered \(total) Swift \(label) in \(path)

        """
        FileHandle.standardError.write(Data(banner.utf8))

        let linter = AccessibilityLinter(config: config, verbose: verbose)
        let clock = ContinuousClock()
        let start = clock.now

        let spinner = showProgress ? Spinner.start(message: "Linting") : nil
        let report = linter.lint(path: path)
        let elapsed = clock.now - start
        spinner?.stop()

        reporter(for: reporterType).report(report)

        FileHandle.standardError.write(Data("⏱️  Completed in \(format(elapsed)) (\(report.filesScanned) file(s))\n".utf8))

        if config.strict && report.hasErrors {
            exit(1)
        }
    }

    static func countSwiftFiles(at path: String, config: LinterConfig) -> Int {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: path, isDirectory: &isDir) else { return 0 }

        if !isDir.boolValue {
            return path.hasSuffix(".swift") ? 1 : 0
        }

        guard let enumerator = fm.enumerator(atPath: path) else { return 0 }
        var count = 0
        while let file = enumerator.nextObject() as? String {
            guard file.hasSuffix(".swift") else { continue }
            let excluded = config.excludePaths.contains { pattern in
                !pattern.isEmpty && file.contains(pattern)
            }
            if excluded { continue }
            count += 1
        }
        return count
    }

    static func format(_ duration: Duration) -> String {
        let seconds = Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
        if seconds < 1 {
            return String(format: "%.0f ms", seconds * 1000)
        }
        return String(format: "%.2f s", seconds)
    }

    static func reporter(for type: String) -> Reporter {
        switch type.lowercased() {
        case "github": return GitHubReporter()
        case "json": return JSONReporter()
        case "xcode": return XcodeReporter()
        case "markdown", "md": return MarkdownReporter()
        case "html": return HTMLReporter()
        default: return CLIReporter()
        }
    }

    static func extractArgValue(_ arguments: [String], flag: String) -> String? {
        guard let index = arguments.firstIndex(of: flag),
              index + 1 < arguments.count else {
            return nil
        }
        return arguments[index + 1]
    }

    static func printHelp() {
        print("""
        swift-a11y-linter — SwiftUI / UIKit Accessibility Linter
        WCAG 2.1 Level AA · EU Accessibility Act compliance checker

        USAGE:
            swift-a11y-linter <path> [options]

        ARGUMENTS:
            <path>                  Swift file or directory to scan (default: current directory)

        OPTIONS:
            --config <path>         Path to JSON config file (default: a11y.config.json)
            --reporter <type>       Output format: cli, json, github, xcode, markdown, html (default: cli)
            --strict                Exit with code 1 on any error severity violation
            --require-all           Require accessibility identifiers on all elements
            --verbose, -v           Print detailed progress information
            --version               Show version
            -h, --help              Show this help

        REPORTERS:
            cli       Pretty terminal output (default)
            json      Machine-readable JSON
            github    GitHub Actions annotations (::error file=...)
            xcode     Xcode build phase format (file:line:col: error: msg)
            markdown  Markdown report
            html      Full HTML report written to a11y-report.html

        EXAMPLES:
            swift-a11y-linter Sources/
            swift-a11y-linter Sources/ --strict --reporter github
            swift-a11y-linter MyView.swift --reporter html
            swift-a11y-linter . --config custom.json --reporter json
        """)
    }
}
