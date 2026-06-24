import Foundation

enum TideDisplayAdjuster {
    static func adjustedHeights(_ heights: [TideHeight], offset: Double) -> [TideHeight] {
        guard offset != 0 else { return heights }
        return heights.map { TideHeight(time: $0.time, height: $0.height + offset) }
    }

    static func adjustedExtremes(_ extremes: [TideExtreme], offset: Double) -> [TideExtreme] {
        guard offset != 0 else { return extremes }
        return extremes.map { TideExtreme(time: $0.time, height: $0.height + offset, kind: $0.kind) }
    }

    static func adjustedState(_ state: TideCurrentState, offset: Double) -> TideCurrentState {
        guard offset != 0 else { return state }
        let adjustedNext = state.nextExtreme.map {
            TideExtreme(time: $0.time, height: $0.height + offset, kind: $0.kind)
        }
        return TideCurrentState(
            height: state.height + offset,
            isRising: state.isRising,
            nextExtreme: adjustedNext,
            coversReferenceDate: state.coversReferenceDate
        )
    }

    static func adjustedSnapshot(_ snapshot: TideSnapshot, offset: Double) -> TideSnapshot {
        guard offset != 0 else { return snapshot }
        return TideSnapshot(
            station: snapshot.station,
            extremes: adjustedExtremes(snapshot.extremes, offset: offset),
            heights: adjustedHeights(snapshot.heights, offset: offset),
            fetchedAt: snapshot.fetchedAt,
            referenceDate: snapshot.referenceDate
        )
    }
}