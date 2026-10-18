import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText = ""
    @State private var categoryFilter: MovementCategory?
    @State private var selectedExercise: Exercise?

    private var filtered: [Exercise] {
        ExerciseDatabase.all
            .filter { categoryFilter == nil || $0.category == categoryFilter }
            .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(store.t("library_title"))
                    .font(DF.display(28))
                    .foregroundColor(DT.fg)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ChipButton(label: store.t("all"), isActive: categoryFilter == nil) { categoryFilter = nil }
                        ForEach(MovementCategory.allCases, id: \.self) { cat in
                            ChipButton(label: cat.label(store.language), isActive: categoryFilter == cat) {
                                categoryFilter = categoryFilter == cat ? nil : cat
                            }
                        }
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(DT.fgFaint)
                    TextField(store.t("search_exercise"), text: $searchText)
                        .foregroundColor(DT.fg)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(DT.fgFaint)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(DT.surface)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(DT.line, lineWidth: 1))

                if filtered.isEmpty {
                    EmptyStateView(icon: "🔍", text: store.t("no_exercises_match"))
                } else {
                    VStack(spacing: 8) {
                        ForEach(filtered) { ex in
                            Button { selectedExercise = ex } label: {
                                libraryRow(ex)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .cardStyle()
                }
            }
            .padding(16)
        }
        .background(DT.bg)
        .sheet(item: $selectedExercise) { ExerciseDetailView(exercise: $0) }
    }

    private func libraryRow(_ ex: Exercise) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(ex.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(DT.fg)
                Text("\(ex.pattern.label(store.language)) · \(ex.category.label(store.language))")
                    .font(.system(size: 12))
                    .foregroundColor(DT.fgMuted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(DT.fgFaint)
        }
        .padding(.vertical, 4)
    }
}
