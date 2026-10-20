import Foundation

/// A one-time sync request opened from the Stride web app:
/// `stridehealth://sync?host=http://192.168.1.20:8000&id=<32 hex characters>&days=28`
struct SyncRequest: Equatable {
    static let scheme = "stridehealth"

    /// Address of the Stride Jac server, as reachable from this iPhone.
    let host: URL
    /// Unguessable request ID issued by the server. It is the SDK user ID and API key.
    let id: String
    /// How many days of Apple Health history to send.
    let days: Int

    init?(url: URL) {
        guard url.scheme?.lowercased() == Self.scheme, url.host == "sync",
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else { return nil }
        func value(_ name: String) -> String? { items.first { $0.name == name }?.value }

        guard let hostText = value("host"),
              let parts = URLComponents(string: hostText),
              let scheme = parts.scheme?.lowercased(), scheme == "http" || scheme == "https",
              let hostName = parts.host, !hostName.isEmpty,
              parts.user == nil, parts.password == nil, parts.query == nil, parts.fragment == nil,
              parts.path.isEmpty || parts.path == "/",
              let host = URL(string: scheme + "://" + (hostName.contains(":") ? "[\(hostName)]" : hostName) + (parts.port.map { ":\($0)" } ?? ""))
        else { return nil }
        // Plain HTTP is only allowed to the local network, matching NSAllowsLocalNetworking.
        if scheme == "http" && !Self.isLocalNetwork(hostName) { return nil }

        guard let id = value("id"), id.count == 32, id.allSatisfy({ $0.isHexDigit && !$0.isUppercase }) else { return nil }
        guard let days = Int(value("days") ?? "28"), (1...90).contains(days) else { return nil }

        self.host = host
        self.id = id
        self.days = days
    }

    /// Whether the connection to `host` is unencrypted.
    var isPlainHTTP: Bool { host.scheme == "http" }

    /// Host and port shown to the person before they allow the sync.
    var displayHost: String {
        (host.host ?? host.absoluteString) + (host.port.map { ":\($0)" } ?? "")
    }

    static func isLocalNetwork(_ host: String) -> Bool {
        let name = host.lowercased()
        if name == "localhost" || name.hasSuffix(".local") || !name.contains(".") && !name.contains(":") { return true }
        let octets = name.split(separator: ".", omittingEmptySubsequences: false).compactMap { UInt8($0) }
        guard octets.count == 4, name.split(separator: ".").count == 4 else { return false }
        switch (octets[0], octets[1]) {
        case (10, _), (127, _), (192, 168), (169, 254): return true
        case (172, 16...31): return true
        default: return false
        }
    }
}
