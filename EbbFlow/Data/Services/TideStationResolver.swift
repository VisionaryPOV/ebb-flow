import Foundation

enum TideStationResolver {
    static func makeStation(from record: NOAAStationRecord) -> TideStation {
        TideStation(
            id: record.id,
            name: record.name,
            latitude: record.lat,
            longitude: record.lng,
            datum: "MLLW"
        )
    }

    static func makeStation(
        id: String,
        name: String,
        latitude: Double,
        longitude: Double,
        datum: String = "MLLW"
    ) -> TideStation {
        TideStation(
            id: id,
            name: name,
            latitude: latitude,
            longitude: longitude,
            datum: datum
        )
    }
}