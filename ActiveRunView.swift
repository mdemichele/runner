import SwiftUI

struct ActiveRunView: View {
    @EnvironmentObject var runManager: RunManager

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Timer
            Text(runManager.formattedElapsed)
                .font(.system(size: 72, weight: .thin, design: .monospaced))
                .monospacedDigit()

            Text("duration")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 40)

            // Distance
            Text(runManager.formattedDistance)
                .font(.system(size: 40, weight: .light, design: .monospaced))
                .monospacedDigit()

            Text("distance")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 32)

            // Pace
            Text(runManager.formattedPace)
                .font(.system(size: 40, weight: .light, design: .monospaced))
                .monospacedDigit()

            Text("min/mile")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            if runManager.locationDenied {
                locationDeniedNotice
                    .padding(.bottom, 24)
            }

            // Controls
            controls
                .padding(.bottom, 48)
        }
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private var controls: some View {
        switch runManager.state {
        case .idle:
            Button(action: runManager.start) {
                label("Start", color: .green)
            }

        case .active:
            HStack(spacing: 32) {
                Button(action: runManager.pause) {
                    label("Pause", color: .orange)
                }
                Button(action: runManager.stop) {
                    label("Stop", color: .red)
                }
            }

        case .paused:
            HStack(spacing: 32) {
                Button(action: runManager.resume) {
                    label("Resume", color: .green)
                }
                Button(action: runManager.stop) {
                    label("Save", color: .blue)
                }
            }
        }
    }

    private var locationDeniedNotice: some View {
        VStack(spacing: 8) {
            Text("Location access is off, so distance and pace can't be measured.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.footnote.weight(.semibold))
        }
        .padding(.horizontal, 32)
    }

    private func label(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.title2.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 120, height: 120)
            .background(color, in: Circle())
    }
}
