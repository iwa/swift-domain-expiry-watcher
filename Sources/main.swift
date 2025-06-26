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
    try app.cron.schedule(UpdateDomainsJob.self)
    try await app.execute()
}

func updateDomains() async {
    for var domain in await domains {
        do {
            let expiryDate = try await WhoisUtils.getExpiryDate(domain: domain.domain)
            if expiryDate != "?" {
                print("[INFO] Domain: \(domain.domain), Expiry Date: \(expiryDate)")

                let date = try? Date.ISO8601FormatStyle(includingFractionalSeconds: false).parse(expiryDate)
                let dateFracSeconds = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(expiryDate)

                if let date = date {
                    domain.expiryDate = date
                    print("[INFO]     \(date.formatted(.dateTime.year(.twoDigits).month(.twoDigits).day(.twoDigits)))")
                } else if let dateFracSeconds = dateFracSeconds {
                    domain.expiryDate = dateFracSeconds
                    print("[INFO]     \(dateFracSeconds.formatted(.dateTime.year(.twoDigits).month(.twoDigits).day(.twoDigits)))")
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