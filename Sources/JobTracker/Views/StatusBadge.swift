import SwiftUI

extension ApplicationStatus {
    var color: Color {
        switch self {
        case .applied: return .blue
        case .interviewing: return .orange
        case .offer: return .green
        case .rejected: return .red
        case .withdrawn: return .gray
        }
    }
}

struct StatusBadge: View {
    let status: ApplicationStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(status.color.opacity(0.15))
            .foregroundStyle(status.color)
            .clipShape(Capsule())
    }
}
