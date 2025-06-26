import Foundation
import Network

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
        let expiryDate = try? await WhoisUtils.getExpiryDate(domain: domain)
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
