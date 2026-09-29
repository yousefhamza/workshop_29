/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A screen of buttons that deliberately misbehave, to exercise Luciq's reporting.
*/

import SwiftUI
import LuciqSDK

struct ChaosView: View {
    @State private var status = "Tap a button."
    @State private var question = "In one sentence, what causes earthquakes?"
    @State private var answer = ""
    @State private var isAsking = false

    var body: some View {
        NavigationView {
            LuciqTracedView(name: "Chaos") { list }
        }
    }

    private var list: some View {
        List {
                Section {
                    Text(status).font(.footnote).foregroundStyle(.secondary)
                }
                Section("User") {
                    Button("Identify user", action: presentIdentifyAlert)
                }
                Section("Crashes") {
                    Button("Crash") { fatalError("Chaos: deliberate crash") }
                    Button("Handled error", action: reportHandledError)
                    // Luciq's watchdog pings main every 3 s (server-tunable) and needs two missed pings,
                    // so only blocks longer than ~6.25 s are reliably caught. Ignored while a debugger is attached.
                    Button("Freeze (10 s)") { Thread.sleep(forTimeInterval: 10) }
                    Button("Memory hog", action: hogMemory)
                }
                Section("Network") {
                    Button("Slow call") { get("https://dummyjson.com/products?delay=5000") }
                    Button("Server error") { get("https://dummyjson.com/http/500") }
                }
                Section("UI") {
                    NavigationLink("Heavy list") { HeavyList() }
                }
                Section("Ask AI") {
                    TextField("Question", text: $question)
                    Button(isAsking ? "Asking…" : "Ask") { Task { await ask() } }
                        .disabled(isAsking || question.isEmpty)
                    if !answer.isEmpty { Text(answer) }
                }
            }
            .navigationTitle("Chaos")
    }

    // UIAlertController because SwiftUI alerts only take text fields from iOS 16, and the app targets iOS 15.
    private func presentIdentifyAlert() {
        let alert = UIAlertController(title: "Identify user", message: nil, preferredStyle: .alert)
        alert.addTextField {
            $0.placeholder = "Email"
            $0.keyboardType = .emailAddress
            $0.autocapitalizationType = .none
            $0.autocorrectionType = .no
        }
        alert.addTextField { $0.placeholder = "Name" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Identify", style: .default) { _ in
            let email = alert.textFields?[0].text?.trimmingCharacters(in: .whitespaces) ?? ""
            let name = alert.textFields?[1].text?.trimmingCharacters(in: .whitespaces) ?? ""
            guard !email.isEmpty else {
                status = "Email is required to identify a user."
                return
            }
            // No separate user ID in this app, so the email doubles as the ID.
            Luciq.identifyUser(withID: email, email: email, name: name)
            status = "Identified \(name.isEmpty ? email : "\(name) <\(email)>")"
        })

        var top = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        top?.present(alert, animated: true)
    }

    private func reportHandledError() {
        do {
            _ = try JSONDecoder().decode([String].self, from: Data("not json".utf8))
        } catch {
            CrashReporting.error(error as NSError)?.report()
            status = "Reported non-fatal: \(error.localizedDescription)"
        }
    }

    private func get(_ url: String) {
        status = "GET \(url)…"
        Task {
            do {
                let (_, response) = try await URLSession.shared.data(from: URL(string: url)!)
                status = "GET \(url) → \((response as? HTTPURLResponse)?.statusCode ?? 0)"
            } catch {
                status = "GET \(url) failed: \(error.localizedDescription)"
            }
        }
    }

    private func hogMemory() {
        status = "Allocating 50 MB chunks…"
        DispatchQueue.global().async {
            // ponytail: the simulator never OOM-kills, so cap it there to spare the Mac; the real kill needs a device.
            #if targetEnvironment(simulator)
            let limit = 40
            #else
            let limit = Int.max
            #endif
            for _ in 0..<limit {
                MemoryHog.chunks.append(Data(repeating: 1, count: 50 * 1024 * 1024))
            }
            DispatchQueue.main.async {
                status = "Simulator cap hit at \(MemoryHog.chunks.count * 50) MB. Run on a device to get OOM-killed."
            }
        }
    }

    private func ask() async {
        isAsking = true
        defer { isAsking = false }
        do {
            answer = try await AnthropicClient.ask(question)
        } catch {
            answer = "Error: \(error.localizedDescription)"
        }
    }
}

private enum MemoryHog {
    static var chunks: [Data] = []
}

private struct HeavyList: View {
    var body: some View {
        LuciqTracedView(name: "Heavy list") { list }
    }

    private var list: some View {
        List(0..<500, id: \.self) { index in
            HStack {
                AsyncImage(url: URL(string: "https://dummyjson.com/image/120x120?text=\(index)")) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 60, height: 60)
                Text("Image \(index)")
            }
        }
        .navigationTitle("Heavy list")
    }
}

/// Minimal Claude Messages API client (Swift has no official Anthropic SDK).
private enum AnthropicClient {
    struct Failure: LocalizedError {
        let errorDescription: String?
    }

    private struct Response: Decodable {
        struct Block: Decodable {
            let type: String
            let text: String?
        }
        let content: [Block]
        let stop_reason: String?
    }

    static func ask(_ question: String) async throws -> String {
        // ANTHROPIC_API_KEY is injected into Info.plist from Configuration/Secrets.xcconfig (gitignored).
        guard let key = Bundle.main.object(forInfoDictionaryKey: "AnthropicAPIKey") as? String, !key.isEmpty else {
            throw Failure(errorDescription: "Set ANTHROPIC_API_KEY in Configuration/Secrets.xcconfig.")
        }
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("server-side-fallback-2026-07-01", forHTTPHeaderField: "anthropic-beta")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": "claude-opus-5",
            "fallbacks": "default",
            "max_tokens": 16000,
            "messages": [["role": "user", "content": question]]
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            throw Failure(errorDescription: "HTTP \(status): \(String(decoding: data, as: UTF8.self))")
        }
        let message = try JSONDecoder().decode(Response.self, from: data)
        if message.stop_reason == "refusal" {
            throw Failure(errorDescription: "The model declined to answer.")
        }
        return message.content.compactMap { $0.type == "text" ? $0.text : nil }.joined()
    }
}
