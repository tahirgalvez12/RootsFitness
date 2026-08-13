import SwiftUI

/// Initials-in-circle avatar with a deterministic per-user color (hashed
/// from the username), used everywhere a profile photo would go once photo
/// upload exists. Keeps avatars visually distinct across a friends list.
struct RFAvatar: View {
    let username: String
    var size: CGFloat = 44

    private var initials: String {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "?" }
        return String(first).uppercased()
    }

    private var color: Color {
        let palette: [Color] = [
            .rfAccent,
            .rfAccentSecondary,
            Color("PostWeight"),
            Color("PostMeal"),
        ]
        let hash = username.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return palette[hash % palette.count]
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.18))
            Text(initials)
                .font(.system(size: size * 0.42, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
    }
}
