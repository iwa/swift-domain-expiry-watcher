import Foundation

struct DomainWatched {
    let domain: String
    var expiryDate: Date?

    init(domain: String, expiryDate: Date?) {
        self.domain = domain
        self.expiryDate = expiryDate
    }
}