import Foundation

struct JSONReporter: Reporter {
    func report(_ report: LintReport) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(report),
           let string = String(data: data, encoding: .utf8) {
            print(string)
        }
    }
}
