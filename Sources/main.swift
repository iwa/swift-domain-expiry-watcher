import Foundation
import Network

struct DomainExpiryWatcher {
    public static func getExpiryDate(domain: String) async throws -> String {
        do {
            let ianaResult = try await DomainExpiryWatcher.lookup(
                domain: domain, host: "whois.iana.org")

            if let ianaResult = ianaResult {
                let originPattern = /(?i)whois:\s*(\S+)/

                if let originMatch = ianaResult.firstMatch(of: originPattern) {
                    let originWhoisUrl = originMatch.1.trimmingCharacters(in: .whitespacesAndNewlines)
                    print("[\(domain)]   Origin WHOIS URL: \(originWhoisUrl)")

                    let whoisResult = try await DomainExpiryWatcher.lookup(domain: domain, host: originWhoisUrl)

                    // get the expiry date from the result
                    if let whoisResult = whoisResult {
                        let expiryPattern = /(?i)Expiry Date:\s*([^\s]+)/

                        if let expiryDateMatch = whoisResult.firstMatch(of: expiryPattern) {
                            let expiryDate = expiryDateMatch.1.trimmingCharacters(in: .whitespacesAndNewlines)
                            print("[\(domain)]   Expiry Date: \(expiryDate)")
                            return expiryDate
                        }
                    } else {
                        print("[\(domain)]   No WHOIS result found")
                    }
                } else {
                    print("[\(domain)]   No origin WHOIS URL found in IANA result")
                }
            } else {
                print("[\(domain)]   No response received")
            }
        } catch {
            print("[\(domain)]   Error: \(error.localizedDescription)")
        }
        return "?"
    }

    public static func lookup(domain: String, host: String) async throws -> String? {
        guard !domain.isEmpty else {
            throw NSError(
                domain: "InvalidDomain", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Domain name cannot be empty."])
        }

        guard !host.isEmpty else {
            throw NSError(
                domain: "InvalidHost", code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid host name."])
        }

        do {
            let result = try await whoisLookup(domain: domain, host: host)
            return result
        } catch {
            print("Error during WHOIS lookup: \(error.localizedDescription)")
        }

        return nil
    }

    static func whoisLookup(domain: String, host: String) async throws -> String {
        let host = NWEndpoint.Host(host)
        let port = NWEndpoint.Port(integerLiteral: 43)
        let connection = NWConnection(host: host, port: port, using: .tcp)

        let result: String = try await withCheckedThrowingContinuation { continuation in
            connection.stateUpdateHandler = { newState in
                switch newState {
                case .ready:
                    let request = "\(domain)\r\n"
                    connection.send(
                        content: request.data(using: .utf8),
                        completion: .contentProcessed { error in
                            if let error = error {
                                print("Error sending data: \(error)")
                                continuation.resume(throwing: error)
                            }

                            receiveData(connection: connection, continuation: continuation)
                        })

                case .failed(let error):
                    print("Connection failed with error: \(error)")
                    connection.cancel()
                    continuation.resume(throwing: error)

                default:
                    break
                }
            }

            connection.start(queue: .global())
        }

        connection.cancel()

        return result
    }

    static func receiveData(
        connection: NWConnection, continuation: CheckedContinuation<String, Error>
    ) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) {
            data, _, isComplete, error in

            if let data = data, !data.isEmpty, let response = String(data: data, encoding: .utf8) {
                continuation.resume(returning: response)
            } else if let error = error {
                continuation.resume(throwing: error)
                return
            } else if isComplete {
                connection.cancel()
                continuation.resume(throwing: NWError.posix(.ECONNRESET))
                return
            }
        }
    }
}

func main() async {
    let domains = ProcessInfo.processInfo.environment["DOMAINS"]?.split(separator: ",").map(String.init) ?? []

    guard !domains.isEmpty else {
        print("No domains provided. Set the DOMAINS environment variable as comma-separated values.")
        return
    }

    for domain in domains {
        guard !domain.isEmpty else {
            print("[WARN] Skipping empty domain entry.")
            continue
        }

        let domain = domain.trimmingCharacters(in: .whitespacesAndNewlines)

        print("\n --- \(domain) ---")
        let expiryDate = try? await DomainExpiryWatcher.getExpiryDate(domain: domain)
        if let expiryDate = expiryDate {
            print("Domain: \(domain), Expiry Date: \(expiryDate)")
        } else {
            print("Failed to retrieve expiry date for domain: \(domain)")
        }
    }
}

Task {
    await main()
    exit(0)
}
dispatchMain()
