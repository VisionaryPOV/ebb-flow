import SwiftUI

struct TodayView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                chartSection
                extremesTable
            }
            .padding()
        }
        .background(skyBackground.ignoresSafeArea())
        .navigationTitle("Today")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    appModel.toggleFavorite()
                } label: {
                    Image(systemName: appModel.isFavorite ? "star.fill" : "star")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await appModel.loadDefaultStation() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .scrollEdgeEffectStyle(.hard, for: .top)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appModel.selectedStation.name)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Text("Datum: \(appModel.selectedStation.datum) · Predictions only")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.75))
            TideStatusHUD(state: appModel.currentState)
        }
    }

    @ViewBuilder
    private var chartSection: some View {
        if appModel.isLoading {
            ProgressView("Reading the water…")
                .frame(maxWidth: .infinity, minHeight: 260)
        } else if let snapshot = appModel.snapshot {
            let points = TideCurvePointGenerator.chartPoints(from: snapshot.heights)
            let fill = WaveFillCalculator.fillLevel(
                for: snapshot.heights,
                at: appModel.selectedChartDate
            )
            TideCurveChart(
                points: points,
                selectedDate: $appModel.selectedChartDate,
                fillLevel: fill
            )
        } else if let error = appModel.errorMessage {
            Text(error)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 120)
        }
    }

    private var extremesTable: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Highs & Lows")
                .font(.headline)
                .foregroundStyle(.white)

            if let extremes = appModel.snapshot?.extremes {
                ForEach(extremes) { extreme in
                    HStack {
                        Label(extreme.kind.label, systemImage: extreme.kind == .high ? "arrow.up" : "arrow.down")
                        Spacer()
                        Text(formattedTime(extreme.time))
                        Text(String(format: "%.1f ft", extreme.height))
                            .monospacedDigit()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var skyBackground: some View {
        let stops = SkyGradientEngine.stops(for: Date())
        return LinearGradient(
            stops: stops.map { .init(color: $0.color, location: $0.location) },
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}