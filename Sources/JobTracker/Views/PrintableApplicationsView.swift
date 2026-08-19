import SwiftUI

struct PrintableApplicationsView: View {
    let applications: [JobApplication]
    let pageWidth: CGFloat

    private let horizontalPadding: CGFloat = 24
    private let columnFractions: [CGFloat] = [0.22, 0.28, 0.16, 0.16, 0.18]

    private var contentWidth: CGFloat { pageWidth - horizontalPadding * 2 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Job Applications")
                .font(.title2.bold())
            Text("Printed \(Date().formatted(date: .abbreviated, time: .shortened)) · \(applications.count) application\(applications.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
                .padding(.bottom, 12)

            row(["Company", "Role", "Req Number", "Status", "Date Applied"], bold: true)
                .foregroundStyle(.secondary)
            Divider()

            ForEach(applications) { app in
                row([
                    app.company,
                    app.role,
                    app.reqNumber.isEmpty ? "—" : app.reqNumber,
                    app.status.rawValue,
                    app.dateApplied.formatted(date: .abbreviated, time: .omitted)
                ])
                Divider()
            }
        }
        .padding(horizontalPadding)
        .frame(width: pageWidth, alignment: .leading)
    }

    private func row(_ values: [String], bold: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                Text(value)
                    .font(bold ? .caption.bold() : .system(size: 11))
                    .frame(width: contentWidth * columnFractions[index], alignment: .leading)
            }
        }
        .padding(.vertical, 5)
    }
}
