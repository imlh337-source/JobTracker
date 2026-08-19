import SwiftUI

struct ApplicationFormView: View {
    @EnvironmentObject private var store: ApplicationStore
    @Environment(\.dismiss) private var dismiss

    var applicationToEdit: JobApplication?

    @State private var company: String = ""
    @State private var role: String = ""
    @State private var reqNumber: String = ""
    @State private var status: ApplicationStatus = .applied
    @State private var dateApplied: Date = .now
    @State private var link: String = ""

    private var isEditing: Bool { applicationToEdit != nil }

    private var isValid: Bool {
        !company.trimmingCharacters(in: .whitespaces).isEmpty &&
        !role.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                TextField("Company", text: $company)
                TextField("Role", text: $role)
                TextField("Req Number", text: $reqNumber)
                Picker("Status", selection: $status) {
                    ForEach(ApplicationStatus.allCases) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                DatePicker("Date Applied", selection: $dateApplied, displayedComponents: .date)
                TextField("Link to Posting", text: $link)
                    .textContentType(.URL)
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(isEditing ? "Save" : "Add") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
            }
            .padding()
        }
        .frame(width: 420, height: 372)
        .onAppear(perform: loadIfEditing)
    }

    private func loadIfEditing() {
        guard let app = applicationToEdit else { return }
        company = app.company
        role = app.role
        reqNumber = app.reqNumber
        status = app.status
        dateApplied = app.dateApplied
        link = app.link
    }

    private func save() {
        if var app = applicationToEdit {
            app.company = company
            app.role = role
            app.reqNumber = reqNumber
            app.status = status
            app.dateApplied = dateApplied
            app.link = link
            store.update(app)
        } else {
            let newApp = JobApplication(
                company: company,
                role: role,
                reqNumber: reqNumber,
                status: status,
                dateApplied: dateApplied,
                link: link
            )
            store.add(newApp)
        }
        dismiss()
    }
}
