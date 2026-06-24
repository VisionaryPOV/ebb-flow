import Foundation

enum TideLiveActivityAction: Equatable {
    case requestNew
    case updateExisting
    case endAndRequest
}

enum TideLiveActivityLifecycle {
    static func action(
        existingStationID: String?,
        newStationID: String,
        hasExistingActivity: Bool
    ) -> TideLiveActivityAction {
        guard hasExistingActivity else { return .requestNew }
        guard let existingStationID else { return .updateExisting }
        if existingStationID == newStationID {
            return .updateExisting
        }
        return .endAndRequest
    }
}