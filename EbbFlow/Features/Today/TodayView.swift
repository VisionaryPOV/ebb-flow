import SwiftUI

struct TodayView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                chartScalePicker
                chartSection
                lunarSection
                TideTableView(appModel: appModel)
            }
            .padding()
        }
        .background(skyBackground.ignoresSafeArea())
        .navigationTitle("Today")
        .toolbar { toolbarContent }
        .scrollEdgeEffectStyle(.hard, for: .top)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { appModel.toggleFavorite() } label: {
                Image(systemName: appModel.isFavorite ? "star.fill" : "star")
            }
            .accessibilityLabel(appModel.isFavorite ? "Remove favorite" : "Add favorite")
        }
        ToolbarItem(placement: .topBarTrailing) {
            ShareLink(item: appModel.exportCSV, preview: SharePreview("Tide CSV")) {
                Image(systemName: "square.and.arrow.up")
            }
            .accessibilityLabel("Export tide data")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button { Task { await appModel.loadDefaultStation() } } label: {
                Image(systemName: "arrow.clockwise")
            }
            .accessibilityLabel("Refresh tides")
        }
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

    private var chartScalePicker: some View {
        Picker("Range", selection: Binding(
            get: { appModel.chartScale },
            set: { newScale in Task { await appModel.setChartScale(newScale) } }
        )) {
            ForEach(ChartTimeScale.allCases) { scale in
                Text(scale.label).tag(scale)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var chartSection: some View {
        if appModel.isLoading {
            ProgressView("Reading the water…")
                .frame(maxWidth: .infinity, minHeight: 260)
        } else if !appModel.filteredHeights.isEmpty {
            let points = TideCurvePointGenerator.chartPoints(
                from: appModel.filteredHeights,
                in: appModel.chartRange
            )
            let fill = WaveFillCalculator.fillLevel(
                for: appModel.snapshot?.heights ?? [],
                at: appModel.selectedChartDate,
                in: appModel.chartRange
            )
            TideCurveChart(
                points: points,
                selectedDate: $appModel.selectedChartDate,
                fillLevel: fill,
                chartScale: appModel.chartScale
            )
            .ebbFlowAccessibilityLabel(AccessibilityLabels.tideHeight(appModel.currentState.height))
        } else if let error = appModel.errorMessage {
            Text(error)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 120)
        }
    }

    @ViewBuilder
    private var lunarSection: some View {
        if let (phase, solar, windows) = appModel.lunarContext {
            VStack(alignment: .leading, spacing: 8) {
                Text("Sky & Energy")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("\(phase.label) · Sunrise \(formattedTime(solar.sunrise)) · Sunset \(formattedTime(solar.sunset))")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                if let top = windows.first {
                    Text("\(top.label) · score \(String(format: "%.0f%%", top.score * 100))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .padding(12)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
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