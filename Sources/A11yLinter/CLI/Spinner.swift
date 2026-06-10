import Foundation

final class Spinner: @unchecked Sendable {
    private static let frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
    private let task: Task<Void, Never>

    private init(message: String) {
        task = Task.detached(priority: .background) {
            var i = 0
            while !Task.isCancelled {
                let frame = Spinner.frames[i % Spinner.frames.count]
                FileHandle.standardError.write(Data("\r\(frame) \(message)...".utf8))
                i += 1
                try? await Task.sleep(for: .milliseconds(80))
            }
        }
    }

    static func start(message: String) -> Spinner {
        Spinner(message: message)
    }

    func stop() {
        task.cancel()
        FileHandle.standardError.write(Data("\r\u{1B}[2K".utf8))
    }
}
