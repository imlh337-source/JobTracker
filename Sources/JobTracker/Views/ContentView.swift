import AppKit
import SwiftUI
import UniformTypeIdentifiers

private let followUpThresholdDays = 14

enum DateRangeFilter: String, CaseIterable, Identifiable {
    case all = "All Time"
    case last7 = "Last 7 Days"
    case last30 = "Last 30 Days"
    case last90 = "Last 90 Days"

    var id: String { rawValue }

    var cutoffDate: Date? {
        let calendar = Calendar.current
        switch self {
        case .all: return nil
        case .last7: return calendar.date(byAdding: .day, value: -7, to: .now)
        case .last30: return calendar.date(byAdding: .day, value: -30, to: .now)
        case .last90: return calendar.date(byAdding: .day, value: -90, to: .now)
        }
    }
}

func needsFollowUp(_ app: JobApplication) -> Bool {
    guard app.status == .applied || app.status == .interviewing else { return false }
    let days = Calendar.current.dateComponents([.day], from: app.updatedAt, to: .now).day ?? 0
    return days >= followUpThresholdDays
}

struct ContentView: View {
    @EnvironmentObject private var store: ApplicationStore

    @State private var searchText = ""
    @State private var statusFilter: ApplicationStatus?
    @State private var dateRangeFilter: DateRangeFilter = .all
    @State private var followUpOnly = false
    @State private var sortOrder: [KeyPathComparator<JobApplication>] = [KeyPathComparator(\.dateApplied, order: .reverse)]
    @State private var showingAddSheet = false
    @State private var editingApplication: JobApplication?
    @State private var pendingDeletion: JobApplication?

    private var dateSortedApplications: [JobApplication] {
        store.applications.sorted { $0.dateApplied > $1.dateApplied }
    }

    private var filteredApplications: [JobApplication] {
        let filtered = store.applications.filter { app in
            let matchesStatus = statusFilter == nil || app.status == statusFilter
            let matchesSearch = searchText.isEmpty ||
                app.company.localizedCaseInsensitiveContains(searchText) ||
                app.role.localizedCaseInsensitiveContains(searchText) ||
                app.reqNumber.localizedCaseInsensitiveContains(searchText)
            let matchesDate = dateRangeFilter.cutoffDate.map { app.dateApplied >= $0 } ?? true
            let matchesFollowUp = !followUpOnly || needsFollowUp(app)
            return matchesStatus && matchesSearch && matchesDate && matchesFollowUp
        }
        return filtered.sorted(using: sortOrder)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dashboard
                Divider()
                filterBar
                Divider()
                if filteredApplications.isEmpty {
                    emptyState
                } else {
                    table
                }
            }
            .navigationTitle("Job Applications")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        exportCSV()
                    } label: {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        printApplications()
                    } label: {
                        Label("Print", systemImage: "printer")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("Add Application", systemImage: "plus")
                    }
                }
            }
            .searchable(text: $searchText, placement: .toolbar, prompt: "Search company or role")
        }
        .sheet(isPresented: $showingAddSheet) {
            ApplicationFormView()
                .environmentObject(store)
        }
        .sheet(item: $editingApplication) { app in
            ApplicationFormView(applicationToEdit: app)
                .environmentObject(store)
        }
        .alert("Delete Application?", isPresented: Binding(
            get: { pendingDeletion != nil },
            set: { if !$0 { pendingDeletion = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingDeletion = nil }
            Button("Delete", role: .destructive) {
                if let app = pendingDeletion {
                    store.delete(app)
                }
                pendingDeletion = nil
            }
        } message: {
            if let app = pendingDeletion {
                Text("This will remove your \(app.role) application at \(app.company).")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .newApplicationRequested)) { _ in
            showingAddSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .printApplicationsRequested)) { _ in
            printApplications()
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportCSVRequested)) { _ in
            exportCSV()
        }
    }

    // MARK: - Dashboard

    private var dashboard: some View {
        let apps = store.applications
        let total = apps.count
        let counts = Dictionary(grouping: apps, by: { $0.status }).mapValues(\.count)
        let responded = apps.filter { $0.status != .applied }.count
        let responseRate = total == 0 ? 0 : Int((Double(responded) / Double(total) * 100).rounded())
        let followUps = apps.filter(needsFollowUp).count

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                statTile(title: "Total", value: "\(total)", color: .primary)
                ForEach(ApplicationStatus.allCases) { status in
                    statTile(title: status.rawValue, value: "\(counts[status] ?? 0)", color: status.color)
                }
                statTile(title: "Response Rate", value: "\(responseRate)%", color: .purple)
                if followUps > 0 {
                    statTile(title: "Needs Follow-Up", value: "\(followUps)", color: .orange)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }

    private func statTile(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .fixedSize()
    }

    // MARK: - Print & Export

    private func printApplications() {
        let printInfo = NSPrintInfo.shared
        printInfo.topMargin = 36
        printInfo.bottomMargin = 36
        printInfo.leftMargin = 36
        printInfo.rightMargin = 36
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .automatic

        let pageWidth = printInfo.paperSize.width - printInfo.leftMargin - printInfo.rightMargin
        let printableView = PrintableApplicationsView(applications: dateSortedApplications, pageWidth: pageWidth)
        let hostingView = NSHostingView(rootView: printableView)
        hostingView.frame = NSRect(x: 0, y: 0, width: pageWidth, height: 0)
        hostingView.layoutSubtreeIfNeeded()
        hostingView.frame = NSRect(x: 0, y: 0, width: pageWidth, height: max(hostingView.fittingSize.height, 1))

        let operation = NSPrintOperation(view: hostingView, printInfo: printInfo)
        operation.showsPrintPanel = true
        operation.showsProgressPanel = true
        operation.run()
    }

    private func exportCSV() {
        let panel = NSSavePanel()
        panel.title = "Export Applications"
        panel.nameFieldStringValue = "JobApplications.csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var lines = ["Company,Role,Req Number,Status,Date Applied,Link"]
        for app in dateSortedApplications {
            let fields = [
                app.company,
                app.role,
                app.reqNumber,
                app.status.rawValue,
                dateFormatter.string(from: app.dateApplied),
                app.link
            ]
            lines.append(fields.map(csvEscape).joined(separator: ","))
        }
        let csv = lines.joined(separator: "\n")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
    }

    private func csvEscape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }

    // MARK: - Filters

    private var filterBar: some View {
        HStack(spacing: 8) {
            filterChip(label: "All", isSelected: statusFilter == nil) {
                statusFilter = nil
            }
            ForEach(ApplicationStatus.allCases) { status in
                filterChip(label: status.rawValue, isSelected: statusFilter == status) {
                    statusFilter = status
                }
            }
            filterChip(label: "Needs Follow-Up", isSelected: followUpOnly) {
                followUpOnly.toggle()
            }

            Spacer()

            Picker("", selection: $dateRangeFilter) {
                ForEach(DateRangeFilter.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 150)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private func filterChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.callout)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                .foregroundStyle(isSelected ? Color.accentColor : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "briefcase")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(store.applications.isEmpty ? "No applications yet" : "No matches")
                .font(.title3)
            if store.applications.isEmpty {
                Button("Add Your First Application") {
                    showingAddSheet = true
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Table

    private var table: some View {
        Table(filteredApplications, sortOrder: $sortOrder) {
            TableColumn("Company", value: \.company)
            TableColumn("Role", value: \.role)
            TableColumn("Req Number", value: \.reqNumber) { app in
                Text(app.reqNumber.isEmpty ? "—" : app.reqNumber)
                    .foregroundStyle(app.reqNumber.isEmpty ? .secondary : .primary)
            }
            TableColumn("Status", value: \.status.rawValue) { app in
                HStack(spacing: 6) {
                    StatusBadge(status: app.status)
                    if needsFollowUp(app) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                            .help("No update in \(followUpThresholdDays)+ days")
                    }
                }
            }
            TableColumn("Date Applied", value: \.dateApplied) { app in
                Text(app.dateApplied.formatted(date: .abbreviated, time: .omitted))
            }
            TableColumn("Link") { app in
                if let url = URL(string: app.link), !app.link.isEmpty {
                    Link("Open", destination: url)
                } else {
                    Text("—").foregroundStyle(.secondary)
                }
            }
        }
        .contextMenu(forSelectionType: JobApplication.ID.self) { ids in
            if let id = ids.first, let app = filteredApplications.first(where: { $0.id == id }) {
                Button("Edit") { editingApplication = app }
                Button("Delete", role: .destructive) { pendingDeletion = app }
            }
        } primaryAction: { ids in
            if let id = ids.first, let app = filteredApplications.first(where: { $0.id == id }) {
                editingApplication = app
            }
        }
    }
}
