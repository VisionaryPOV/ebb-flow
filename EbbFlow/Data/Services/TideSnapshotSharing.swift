import Foundation

extension SharedTideSnapshotPayload {
    init(snapshot: TideSnapshot) {
        let state = snapshot.currentState
        self.init(
            stationID: snapshot.station.id,
            stationName: snapshot.station.name,
            currentHeight: state.height,
            isRising: state.isRising,
            nextExtremeTime: state.nextExtreme?.time,
            nextExtremeKind: state.nextExtreme?.kind.rawValue,
            nextExtremeHeight: state.nextExtreme?.height,
            fetchedAt: snapshot.fetchedAt
        )
    }
}

extension SharedTideDataStore {
    static func write(_ snapshot: TideSnapshot) {
        write(payload: SharedTideSnapshotPayload(snapshot: snapshot))
    }
}