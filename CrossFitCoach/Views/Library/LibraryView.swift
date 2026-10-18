import SwiftUI

struct LibraryView: View {
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
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ChipButton(label: "Vše", isActive: categoryFilter == nil) { categoryFilter = nil }
                            ForEach(MovementCategory.allCases, id: \.self) { cat in
                                ChipButton(label: cat.label, isActive: categoryFilter == cat) {
                                    categoryFilter = categoryFilter == cat ? nil : cat
                                }
                            }
                        }
                    }

                    if filtered.isEmpty {
                        EmptyStateView(icon: "🔍", text: "Žádné cviky neodpovídají filtru.")
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
            .navigationTitle("Cviky")
            .background(DT.bg)
            .searchable(text: $searchText, prompt: "Hledat cvik")
            .sheet(item: $selectedExercise) { ExerciseDetailView(exercise: $0) }
        }
    }

    private func libraryRow(_ ex: Exercise) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(ex.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(DT.fg)
                Text("\(ex.pattern.label) · \(ex.category.label)")
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
