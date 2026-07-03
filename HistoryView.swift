import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var runManager: RunManager

    var body: some View {
        NavigationStack {
            Group {
                if runManager.history.isEmpty {
                    ContentUnavailableView(
                        "No Runs Yet",
                        systemImage: "figure.run",
                        description: Text("Your completed runs will appear here.")
                    )
                } else {
                    List {
                        ForEach(runManager.history) { run in
                            RunRow(run: run)
                        }
                        .onDelete(perform: runManager.deleteRuns)
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

private struct RunRow: View {
    let run: Run

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Self.dateFormatter.string(from: run.date))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 24) {
                stat(value: run.formattedDuration, label: "time")
                stat(value: run.formattedDistance, label: "distance")
                stat(value: run.formattedPace, label: "pace")
            }
        }
        .padding(.vertical, 4)
    }

    private func stat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.system(.body, design: .monospaced).weight(.medium))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
