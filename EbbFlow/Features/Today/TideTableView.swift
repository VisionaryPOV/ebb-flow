import SwiftUI

struct TideTableView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Highs & Lows")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Menu("Columns") {
                    ForEach(TideTableColumn.allCases, id: \.self) { column in
                        Button {
                            appModel.toggleTableColumn(column)
                        } label: {
                            Label(column.header, systemImage: appModel.tableColumns.contains(column) ? "checkmark" : "")
                        }
                    }
                }
                .foregroundStyle(.white)
            }

            ForEach(appModel.tableRows) { row in
                HStack {
                    if appModel.tableColumns.contains(.kind), let kind = row.kind {
                        Label(kind.label, systemImage: kind == .high ? "arrow.up" : "arrow.down")
                    }
                    if appModel.tableColumns.contains(.time) {
                        Text(TideDataTransformer.formatShortTime(row.time, timeZone: appModel.exportTimeZone))
                    }
                    Spacer()
                    if appModel.tableColumns.contains(.height) {
                        Text(String(format: "%.1f ft", row.height))
                            .monospacedDigit()
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel(row.kind.map { AccessibilityLabels.extreme(TideExtreme(time: row.time, height: row.height, kind: $0)) } ?? AccessibilityLabels.tideHeight(row.height))
            }
        }
    }

}