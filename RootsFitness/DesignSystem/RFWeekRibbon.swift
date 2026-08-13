import SwiftUI

/// Seven small rounded marks showing a week of activity as texture, not a
/// score — filled ink for an active day, rose for "today," and a faint
/// hairline-colored mark for a missed day. Deliberately has no numeric
/// readout alongside it: a gap costs nothing and there's no streak count to
/// protect, per the reference design's restraint principle.
struct RFWeekRibbon: View {
    /// Seven days, oldest to newest (index 0 = 6 days ago, index 6 = today).
    let activeDays: [Bool]
    var markWidth: CGFloat = 3
    var markHeight: CGFloat = 11

    var body: some View {
        HStack(spacing: 3) {
            ForEach(activeDays.indices, id: \.self) { index in
                let isToday = index == activeDays.count - 1
                RoundedRectangle(cornerRadius: markWidth / 2, style: .continuous)
                    .fill(color(isActive: activeDays[index], isToday: isToday))
                    .frame(width: markWidth, height: markHeight)
            }
        }
    }

    private func color(isActive: Bool, isToday: Bool) -> Color {
        if isToday { return .rfAccent }
        return isActive ? Color.rfTextPrimary : Color.rfHairline
    }
}

/// A 5-week grid variant for the profile screen's "Showing up" section —
/// same marks, stacked one week per row.
struct RFWeekGrid: View {
    /// Rows of 7 booleans each, oldest week first, newest week last.
    let weeks: [[Bool]]

    var body: some View {
        VStack(spacing: 5) {
            ForEach(weeks.indices, id: \.self) { weekIndex in
                let isLastWeek = weekIndex == weeks.count - 1
                HStack(spacing: 5) {
                    ForEach(weeks[weekIndex].indices, id: \.self) { dayIndex in
                        let isToday = isLastWeek && dayIndex == weeks[weekIndex].count - 1
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(color(isActive: weeks[weekIndex][dayIndex], isToday: isToday))
                            .frame(maxWidth: .infinity)
                            .frame(height: 14)
                    }
                }
            }
        }
    }

    private func color(isActive: Bool, isToday: Bool) -> Color {
        if isToday { return .rfAccent }
        return isActive ? Color.rfTextPrimary : Color.rfHairline
    }
}
