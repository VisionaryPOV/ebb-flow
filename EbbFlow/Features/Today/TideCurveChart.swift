import Charts
import SwiftUI

struct TideCurveChart: View {
    let points: [TideChartPoint]
    @Binding var selectedDate: Date
    let fillLevel: Double
    var showsWeeklyWave: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            if showsWeeklyWave {
                WeeklyWaveFillShape(levels: points.map(\.normalizedY))
                    .fill(
                        LinearGradient(
                            colors: [
                                EbbFlowTheme.deepTeal.opacity(0.55),
                                EbbFlowTheme.deepTeal.opacity(0.10)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: points.count)
            } else {
                WaveFillShape(level: fillLevel)
                    .fill(
                        LinearGradient(
                            colors: [
                                EbbFlowTheme.deepTeal.opacity(0.55),
                                EbbFlowTheme.deepTeal.opacity(0.15)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .animation(.spring(response: 0.5, dampingFraction: 0.75), value: fillLevel)
            }

            Chart(points) { point in
                LineMark(
                    x: .value("Time", point.time),
                    y: .value("Height", point.height)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(EbbFlowTheme.foamWhite)

                AreaMark(
                    x: .value("Time", point.time),
                    y: .value("Height", point.height)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [EbbFlowTheme.deepTeal.opacity(0.45), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                if let selected = selectedPoint {
                    RuleMark(x: .value("Selected", selected.time))
                        .foregroundStyle(.white.opacity(0.6))
                    PointMark(
                        x: .value("Selected", selected.time),
                        y: .value("Height", selected.height)
                    )
                    .foregroundStyle(.white)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: showsWeeklyWave ? 7 : 4)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: showsWeeklyWave ? .dateTime.weekday(.abbreviated) : .dateTime.hour())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let height = value.as(Double.self) {
                            Text(String(format: "%.1f", height))
                                .font(.caption2.monospacedDigit())
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    updateSelection(at: value.location, proxy: proxy, geometry: geometry)
                                }
                        )
                }
            }
        }
        .frame(height: showsWeeklyWave ? 280 : 260)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var selectedPoint: TideChartPoint? {
        guard !points.isEmpty else { return nil }
        return points.min { lhs, rhs in
            abs(lhs.time.timeIntervalSince(selectedDate)) < abs(rhs.time.timeIntervalSince(selectedDate))
        }
    }

    private func updateSelection(
        at location: CGPoint,
        proxy: ChartProxy,
        geometry: GeometryProxy
    ) {
        guard let plotFrame = proxy.plotFrame else { return }
        let origin = geometry[plotFrame].origin
        let xPosition = location.x - origin.x
        guard let date: Date = proxy.value(atX: xPosition) else { return }
        selectedDate = date
    }
}

private struct WaveFillShape: Shape {
    var level: Double

    var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let fillHeight = rect.height * CGFloat(level)
        path.addRect(CGRect(x: 0, y: rect.height - fillHeight, width: rect.width, height: fillHeight))
        return path
    }
}

private struct WeeklyWaveFillShape: Shape {
    var levels: [Double]

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(levels.first ?? 0, levels.last ?? 0) }
        set { }
    }

    func path(in rect: CGRect) -> Path {
        guard !levels.isEmpty else { return Path() }
        var path = Path()
        let stepX = rect.width / CGFloat(max(levels.count - 1, 1))
        path.move(to: CGPoint(x: 0, y: rect.height))
        for (index, level) in levels.enumerated() {
            let x = CGFloat(index) * stepX
            let y = rect.height - CGFloat(level) * rect.height
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path
    }
}