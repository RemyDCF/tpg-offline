//
//  RouteResults.swift
//  tpg offline
//
//  Created by Rémy Da Costa Faro on 10/09/2017.
//  Copyright © 2018 Rémy Da Costa Faro. All rights reserved.
//

import Foundation

struct RouteResults: Decodable {
  var connections: [RouteConnection]
}

struct RouteConnection: Decodable {
  var duration: String?
  var from: RouteResultsStops
  var to: RouteResultsStops
  var sections: [Sections]?

  struct RouteResultsStops: Decodable {
    struct Station: Decodable {
      var id: String
      var name: String
      var coordinate: Coordinate

      struct Coordinate: Decodable {
        var x: Double
        var y: Double
      }
    }

    var departureTimestamp: Int?
    var arrivalTimestamp: Int?
    var station: Station
  }

  struct Sections: Decodable {
    struct Walk: Decodable {
      var duration: Int?
    }

    struct Journey: Decodable {
      var lineCode: String
      var compagny: String
      var category: String
      var to: String
      var passList: [RouteResultsStops]

      public init(lineCode: String,
                  compagny: String,
                  category: String,
                  to: String,
                  passList: [RouteResultsStops]) {
        self.lineCode = lineCode
        self.compagny = compagny
        self.category = category
        self.to = to
        self.passList = passList
      }

      enum CodingKeys: String, CodingKey {
        case lineCode = "number"
        case compagny = "operator"
        case category
        case to
        case passList
      }

      init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let lineCode = try container.decode(String.self, forKey: .lineCode)
        let compagny = try container.decode(String.self, forKey: .compagny)
        let category = try container.decode(String.self, forKey: .category)
        let to = try container.decode(String.self, forKey: .to)
        var passList =
          try container.decode([RouteResultsStops].self, forKey: .passList)

        for (index, result) in passList.enumerated() {
          guard let stop = App.stops
            .filter({ $0.sbbId == result.station.id })[safe: 0] else {
              continue
          }
          var localisations = stop.localisations
          for (index, localisation) in localisations.enumerated() {
            localisations[index].destinations = localisation.destinations.filter({
              $0.line == lineCode &&
              $0.destinationTransportAPI == to
            })
          }
          localisations = localisations.filter({ !$0.destinations.isEmpty })
          guard let localisation = localisations[safe: 0] else {
            continue
          }
          passList[index].station.coordinate.x =
            localisation.location.coordinate.latitude
          passList[index].station.coordinate.y =
            localisation.location.coordinate.longitude
        }

        self.init(lineCode: lineCode,
                  compagny: compagny,
                  category: category,
                  to: to,
                  passList: passList)
      }
    }

    var walk: Walk?
    var journey: Journey?
    var departure: RouteResultsStops
    var arrival: RouteResultsStops
  }
}
