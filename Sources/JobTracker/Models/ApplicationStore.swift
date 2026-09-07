import Foundation

@MainActor
final class ApplicationStore: ObservableObject {
    @Published private(set) var applications: [JobApplication] = []

    private let fileURL: URL

    init() {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("JobTracker", isDirectory: true)
        try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
        fileURL = supportDir.appendingPathComponent("applications.json")
        load()
    }

    func add(_ application: JobApplication) {
        applications.append(application)
        save()
    }

    func update(_ application: JobApplication) {
        guard let index = applications.firstIndex(where: { $0.id == application.id }) else { return }
        var updated = application
        updated.updatedAt = .now
        applications[index] = updated
        save()
    }

    func delete(_ application: JobApplication) {
        applications.removeAll { $0.id == application.id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        applications = (try? decoder.decode([JobApplication].self, from: data)) ?? []
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(applications) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
