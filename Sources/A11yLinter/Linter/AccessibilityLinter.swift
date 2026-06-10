import Foundation

final class AccessibilityLinter {
    private let config: LinterConfig
    private let verbose: Bool
    private let analyzers: [Analyzer]

    init(config: LinterConfig = .default, verbose: Bool = false) {
        self.config = config
        self.verbose = verbose
        self.analyzers = [
            SwiftUIAnalyzer(),
            UIKitAnalyzer(),
            ColorAnalyzer(),
            MediaAnalyzer(),
            CustomControlAnalyzer()
        ]
    }

    func lint(path: String) -> LintReport {
        var report = LintReport()
        let fileManager = FileManager.default

        if isDirectory(path) {
            guard let enumerator = fileManager.enumerator(atPath: path) else { return report }
            while let file = enumerator.nextObject() as? String {
                guard file.hasSuffix(".swift") else { continue }
                let fullPath = (path as NSString).appendingPathComponent(file)
                lintIfApplicable(path: fullPath, report: &report)
            }
        } else if path.hasSuffix(".swift") {
            lintIfApplicable(path: path, report: &report)
        }

        report.complianceScore = ComplianceScorer.score(for: report.violations, scoring: config.scoring)
        return report
    }

    func lint(files: [String]) -> LintReport {
        var report = LintReport()
        for file in files where file.hasSuffix(".swift") {
            lintIfApplicable(path: file, report: &report)
        }
        report.complianceScore = ComplianceScorer.score(for: report.violations, scoring: config.scoring)
        return report
    }

    private func isDirectory(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        return isDir.boolValue
    }

    private func shouldExcludePath(_ path: String) -> Bool {
        for pattern in config.excludePaths where pattern.isEmpty == false {
            if path.contains(pattern) { return true }
        }
        return false
    }

    private func lintIfApplicable(path: String, report: inout LintReport) {
        if shouldExcludePath(path) {
            report.filesSkipped += 1
            if verbose { print("⏭️  Excluded: \(path)") }
            return
        }

        for ignored in config.ignoreFiles where path.contains(ignored) {
            report.filesSkipped += 1
            if verbose { print("⏭️  Skipped (ignoreFiles): \(path)") }
            return
        }

        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            report.filesSkipped += 1
            return
        }

        if !isSwiftUIOrUIKitFile(content) {
            report.filesSkipped += 1
            if verbose { print("⏭️  Not a SwiftUI/UIKit file: \(path)") }
            return
        }

        let lines = content.components(separatedBy: .newlines)
        report.filesScanned += 1
        report.totalLines += lines.count
        if verbose { print("✓ Checking: \(path)") }

        for analyzer in analyzers {
            report.violations.append(contentsOf: analyzer.analyze(lines: lines, file: path, config: config))
        }
    }

    private func isSwiftUIOrUIKitFile(_ content: String) -> Bool {
        return content.contains("import SwiftUI")
            || content.contains("import UIKit")
            || content.contains(": View")
            || content.contains("View {")
    }
}
