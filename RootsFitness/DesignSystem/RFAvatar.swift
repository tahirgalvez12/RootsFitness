import SwiftUI

/// Initials-in-rounded-square avatar with a deterministic per-user color
/// (hashed from the username) — rounded square rather than a circle, per
/// the reference design, and used everywhere a profile photo would go once
/// photo upload exists. Keeps avatars visually distinct across a friends
/// list.
struct RFAvatar: View {
    let username: String
    var size: CGFloat = 44

    private var initials: String {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "?" }
        return String(first).uppercased()
    }

    private var color: Color {
        // Desaturated, palette-matched hues — not the old bright
        // blue/orange/teal/red set, which would clash with the sage/ink/
        // rose/wheat "kitchen table" tone.
        let palette: [Color] = [
            Color.rfTextPrimary,
            Color.rfAccent,
            Color.rfAccentSecondary,
            Color(red: 0.36, green: 0.42, blue: 0.33), // sage green, matches mockup's Marisol avatar
        ]
        let hash = username.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return palette[hash % palette.count]
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .fill(color)
            Text(initials)
                .font(.custom("Bricolage Grotesque Bold", size: size * 0.4))
                .foregroundStyle(Color.rfSurfaceElevated)
        }
        .frame(width: size, height: size)
    }
}
