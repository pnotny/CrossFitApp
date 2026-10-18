import SwiftUI

/// Měsíční kalendář odjetých tréninků — otevírá se z Historie jako sheet.
/// Puntík u dne (barva podle typu dne, stejně jako jinde v appce) se zobrazí
/// jen tam, kde byl trénink skutečně odškrtnutý jako splněný (ne jen uložený).
struct CalendarSheetView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var monthAnchor: Date = Date()
    @State private var selectedWorkout: Workout?

    private static let weekdayLabels = ["Po", "Út", "St", "Čt", "Pá", "So", "Ne"]
    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "cs_CZ")
        f.dateFormat = "LLLL yyyy"
        return f
    }()

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    /// Mapa "yyyy-MM-dd" → trénink, jen pro skutečně odjeté tréninky.
    private var completedByDate: [String: Workout] {
        Dictionary(uniqueKeysWithValues: store.history.filter { $0.isCompleted }.map { ($0.date, $0) })
    }

    /// Buňky měsíční mřížky (7 sloupců, týden od pondělí) — nil = prázdná buňka na okraji.
    private var daysGrid: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthAnchor) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start) // ne=1..so=7
        let leadingBlank = (firstWeekday + 5) % 7 // posun tak, aby mřížka začínala pondělím

        var days: [Date?] = Array(repeating: nil, count: leadingBlank)
        var cursor = monthInterval.start
        while cursor < monthInterval.end {
            days.append(cursor)
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                monthHeader

                HStack(spacing: 0) {
                    ForEach(Self.weekdayLabels, id: \.self) { label in
                        Text(label)
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(DT.fgFaint)
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(Array(daysGrid.enumerated()), id: \.offset) { _, day in
                        if let day {
                            dayCell(day)
                        } else {
                            Color.clear.frame(height: 42)
                        }
                    }
                }

                Spacer()
            }
            .padding(16)
            .background(DT.bg)
            .navigationTitle("Kalendář")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Zavřít") { dismiss() } }
            }
            .sheet(item: $selectedWorkout) { HistoryWorkoutDetailView(workout: $0) }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                if let prev = calendar.date(byAdding: .month, value: -1, to: monthAnchor) { monthAnchor = prev }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(DT.fgMuted)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(Self.monthFormatter.string(from: monthAnchor).capitalized)
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(DT.fg)

            Spacer()

            Button {
                if let next = calendar.date(byAdding: .month, value: 1, to: monthAnchor) { monthAnchor = next }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(DT.fgMuted)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let dateString = DateUtils.dateString(from: day)
        let workout = completedByDate[dateString]
        let isToday = dateString == DateUtils.todayString()

        return Button {
            selectedWorkout = workout
        } label: {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.system(size: 13, weight: isToday ? .heavy : .semibold))
                    .foregroundColor(isToday ? DT.accentText : DT.fg)
                Circle()
                    .fill(workout?.dayType.color ?? .clear)
                    .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(isToday ? DT.surface : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(workout == nil)
    }
}
