import AppKit
import Foundation

private let localSendAppPath = "/Applications/LocalSend.app"
private let scopedDomain = "scoped.localsend.internal"

private func showError(_ message: String) -> Never {
    let application = NSApplication.shared
    application.setActivationPolicy(.prohibited)

    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = "LocalSend Launcher"
    alert.informativeText = message
    alert.addButton(withTitle: "OK")
    alert.runModal()

    exit(EXIT_FAILURE)
}

let appURL = URL(fileURLWithPath: localSendAppPath, isDirectory: true)
let infoURL = appURL.appendingPathComponent("Contents/Info.plist")

guard FileManager.default.fileExists(atPath: localSendAppPath) else {
    showError("LocalSend was not found at /Applications/LocalSend.app. Install LocalSend first, then open this launcher again.")
}

guard
    let info = NSDictionary(contentsOf: infoURL),
    let executableName = info["CFBundleExecutable"] as? String,
    !executableName.isEmpty
else {
    showError("The executable name could not be read from LocalSend's Info.plist.")
}

let executableURL = appURL
    .appendingPathComponent("Contents/MacOS")
    .appendingPathComponent(executableName)

guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
    showError("LocalSend's executable is missing or cannot be run:\n\(executableURL.path)")
}

let child = Process()
child.executableURL = executableURL
child.arguments = []

// Only the LocalSend child receives this environment. Remove inherited proxy
// server variables, then keep the narrowly scoped LocalSend bypass variables.
var childEnvironment = ProcessInfo.processInfo.environment
for key in [
    "HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY",
    "http_proxy", "https_proxy", "all_proxy"
] {
    childEnvironment.removeValue(forKey: key)
}
childEnvironment["NO_PROXY"] = scopedDomain
childEnvironment["no_proxy"] = scopedDomain
child.environment = childEnvironment

do {
    try child.run()
} catch {
    showError("LocalSend could not be started:\n\(error.localizedDescription)")
}

// LocalSend continues running after this short-lived launcher exits.
exit(EXIT_SUCCESS)
