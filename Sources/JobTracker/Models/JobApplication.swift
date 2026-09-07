import Foundation

enum ApplicationStatus: String, Codable, CaseIterable, Identifiable {
    case applied = "Applied"
    case interviewing = "Interviewing"
    case offer = "Offer"
    case rejected = "Rejected"
    case withdrawn = "Withdrawn"

    var id: String { rawValue }
}

struct JobApplication: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var company: String = ""
    var role: String = ""
    var reqNumber: String = ""
    var status: ApplicationStatus = .applied
    var dateApplied: Date = .now
    var link: String = ""
    var createdAt: Date = .now
    var updatedAt: Date = .now

    init(
        id: UUID = UUID(),
        company: String = "",
        role: String = "",
        reqNumber: String = "",
        status: ApplicationStatus = .applied,
        dateApplied: Date = .now,
        link: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.company = company
        self.role = role
        self.reqNumber = reqNumber
        self.status = status
        self.dateApplied = dateApplied
        self.link = link
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        company = try container.decodeIfPresent(String.self, forKey: .company) ?? ""
        role = try container.decodeIfPresent(String.self, forKey: .role) ?? ""
        reqNumber = try container.decodeIfPresent(String.self, forKey: .reqNumber) ?? ""
        status = try container.decodeIfPresent(ApplicationStatus.self, forKey: .status) ?? .applied
        dateApplied = try container.decodeIfPresent(Date.self, forKey: .dateApplied) ?? .now
        link = try container.decodeIfPresent(String.self, forKey: .link) ?? ""
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? dateApplied
    }
}
