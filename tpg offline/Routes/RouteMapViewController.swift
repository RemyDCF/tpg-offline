//
//  RouteMapViewController.swift
//  tpg offline
//
//  Created by Rémy DA COSTA FARO on 04/11/2017.
//  Copyright © 2017 Remy. All rights reserved.
//

import UIKit
import MapKit

class RouteMapViewController: UIViewController {

  @IBOutlet weak var mapView: MKMapView!

  var connection: RouteConnection?

  override func viewDidLoad() {
    super.viewDidLoad()

    guard let mapView = self.mapView else { return }

    mapView.delegate = self
    title = Text.map

    ColorModeManager.shared.addColorModeDelegate(self)

    guard let connection = self.connection else { return }

    var allPoints: [CLLocationCoordinate2D] = []
    for section in connection.sections ?? [] {
      var coordinates: [CLLocationCoordinate2D] = []

      for step in section.journey?.passList ?? [] {
        let annotation = MKPointAnnotation()
        annotation.coordinate =
          CLLocationCoordinate2D(latitude: step.station.coordinate.x,
                                 longitude: step.station.coordinate.y)
        coordinates.append(annotation.coordinate)
        allPoints.append(annotation.coordinate)
        annotation.title =  (App.stops.filter({
          $0.sbbId == step.station.id
        })[safe: 0]?.name) ?? step.station.name
        mapView.addAnnotation(annotation)
      }

      let geodesic = MKPolyline(coordinates: &coordinates, count: coordinates.count)
      geodesic.title = section.journey?.lineCode ?? ""
      mapView.add(geodesic)
    }
    
    if allPoints.isEmpty {
      allPoints = [
        CLLocationCoordinate2D(latitude: connection.from.station.coordinate.x,
                               longitude: connection.from.station.coordinate.y),
        CLLocationCoordinate2D(latitude: connection.to.station.coordinate.x,
                               longitude: connection.to.station.coordinate.y)]
      let fromAnnotation = MKPointAnnotation()
      fromAnnotation.title = (App.stops.filter({
        $0.sbbId == connection.from.station.id
      })[safe: 0]?.name) ?? connection.from.station.name
      fromAnnotation.coordinate =
        CLLocationCoordinate2D(latitude: connection.from.station.coordinate.x,
                               longitude: connection.from.station.coordinate.y)
      mapView.addAnnotation(fromAnnotation)
      
      let toAnnotation = MKPointAnnotation()
      toAnnotation.title = (App.stops.filter({
        $0.sbbId == connection.to.station.id
      })[safe: 0]?.name) ?? connection.to.station.name
      toAnnotation.coordinate =
        CLLocationCoordinate2D(latitude: connection.to.station.coordinate.x,
                               longitude: connection.to.station.coordinate.y)
      mapView.addAnnotation(toAnnotation)
      
      let geodesic = MKPolyline(coordinates: &allPoints, count: allPoints.count)
      geodesic.title = "Walk"
      mapView.add(geodesic)
    }

    let regionRadius: CLLocationDistance = 2000
    let coordinateRegion = MKCoordinateRegionMakeWithDistance(allPoints[0],
                                                              regionRadius,
                                                              regionRadius)
    mapView.setRegion(coordinateRegion, animated: true)
  }

  deinit {
    ColorModeManager.shared.removeColorModeDelegate(self)
  }
}

extension RouteMapViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView,
               rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    guard let polyline = overlay as? MKPolyline else {
      return MKOverlayRenderer()
    }

    let polylineRenderer = MKPolylineRenderer(overlay: polyline)
    polylineRenderer.strokeColor = App.color(for: (overlay.title ?? "") ?? "")
    if overlay.title == "Walk" {
      polylineRenderer.strokeColor = .black
    }
    polylineRenderer.lineWidth = 5
    return polylineRenderer
  }
}
