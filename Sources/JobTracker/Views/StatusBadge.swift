import SwiftUI

struct StatusBadge: View {
    let status: ApplicationStatus

    var color: Color {
        switch status {
        case .applied: return .blue
        case .interviewing: return .orange
        case .offer: return .green
        case .rejected: return .red
        case .withdrawn: return .gray
        }
    }

    var body: some View {
        Text(status.rawValue)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
