import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ApplicationStore

    @State private var searchText = ""
    @State private var statusFilter: ApplicationStatus?
    @State private var showingAddSheet = false
    @State private var editingApplication: JobApplication?
    @State private var pendingDeletion: JobApplication?

    private var sortedApplications: [JobApplication] {
        store.applications.sorted { $0.dateApplied > $1.dateApplied }
    }

    private var filteredApplications: [JobApplication] {
        sortedApplications.filter { app in
            let matchesStatus = statusFilter == nil || app.status == statusFilter
            let matchesSearch = searchText.isEmpty ||
                app.company.localizedCaseInsensitiveContains(searchText) ||
                app.role.localizedCaseInsensitiveContains(searchText) ||
                app.reqNumber.localizedCaseInsensitiveContains(searchText)
            return matchesStatus && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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
    }

    private func printApplications() {
        let printInfo = NSPrintInfo.shared
        printInfo.topMargin = 36
        printInfo.bottomMargin = 36
        printInfo.leftMargin = 36
        printInfo.rightMargin = 36
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .automatic

        let pageWidth = printInfo.paperSize.width - printInfo.leftMargin - printInfo.rightMargin
        let printableView = PrintableApplicationsView(applications: sortedApplications, pageWidth: pageWidth)
        let hostingView = NSHostingView(rootView: printableView)
        hostingView.frame = NSRect(x: 0, y: 0, width: pageWidth, height: 0)
        hostingView.layoutSubtreeIfNeeded()
        hostingView.frame = NSRect(x: 0, y: 0, width: pageWidth, height: max(hostingView.fittingSize.height, 1))

        let operation = NSPrintOperation(view: hostingView, printInfo: printInfo)
        operation.showsPrintPanel = true
        operation.showsProgressPanel = true
        operation.run()
    }

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
            Spacer()
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

    private var table: some View {
        Table(filteredApplications) {
            TableColumn("Company") { app in
                Text(app.company)
            }
            TableColumn("Role") { app in
                Text(app.role)
            }
            TableColumn("Req Number") { app in
                Text(app.reqNumber.isEmpty ? "—" : app.reqNumber)
                    .foregroundStyle(app.reqNumber.isEmpty ? .secondary : .primary)
            }
            TableColumn("Status") { app in
                StatusBadge(status: app.status)
            }
            TableColumn("Date Applied") { app in
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
