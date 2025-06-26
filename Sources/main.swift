import Foundation
import Network

import Vapor

let app = try await Application.make(.detect())
var domains: [DomainWatched] = []

@MainActor
func main() async throws {
    let envDomains = ProcessInfo.processInfo.environment["DOMAINS"]?.split(separator: ",").map(String.init) ?? []

    guard !envDomains.isEmpty else {
        print("No domains provided. Set the DOMAINS environment variable as comma-separated values.")
        return
    }

    for domain in envDomains {
        guard !domain.isEmpty else {
            print("[WARN] Skipping empty domain entry.")
            continue
        }

        let domainName = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        domains.append(DomainWatched(domain: domainName, expiryDate: nil))
    }

    await updateDomains()

    // Vapor
    try app.cron.schedule(ComplexJob.self)
    try await app.execute()
}

func updateDomains() async {
    for var domain in await domains {
        do {
            let expiryDate = try await WhoisUtils.getExpiryDate(domain: domain.domain)
            if expiryDate != "?" {
                print("[INFO] Domain: \(domain.domain), Expiry Date: \(expiryDate)")
                if let date = ISO8601DateFormatter().date(from: expiryDate) {
                    domain.expiryDate = date
                } else {
                    print("Invalid date format for domain: \(domain.domain)")
                }
            } else {
                print("Failed to retrieve expiry date for domain: \(domain.domain)")
            }
        } catch {
            print("Error retrieving expiry date for domain \(domain.domain): \(error)")
        }
    }
}

try await main()