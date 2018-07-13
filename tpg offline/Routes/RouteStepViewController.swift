//
//  RouteStepViewController.swift
//  tpg offline
//
//  Created by Remy on 08/10/2017.
//  Copyright © 2017 Remy. All rights reserved.
//

import UIKit
import MapKit
import UserNotifications
import MessageUI

class RouteStepViewController: UIViewController {

  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var reminderButton: UIButton!
  @IBOutlet weak var stackView: UIStackView!
  @IBOutlet weak var buttonBackgroundView: UIView!

  var section: RouteConnection.Sections!
  var color: UIColor = .black
  var names: [String] = []

  var titleSelected = "" {
    didSet {
      self.tableView.reloadData()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    title = Text.line(section.journey?.lineCode)

    if section.journey?.compagny == "TPG" {
      self.color = App.color(for: section.journey?.lineCode ?? "")
    } else if section.journey?.compagny == "SBB" {
      title = Text.sbb(line: section.journey?.lineCode)
      self.color = .red
    }

    self.reminderButton.setImage(#imageLiteral(resourceName: "cel-bell").maskWith(color: App.darkMode ?
      color : color.contrast),
                                 for: .normal)
    self.reminderButton.setTitleColor(App.darkMode ? color : color.contrast,
                                      for: .normal)
    self.reminderButton.backgroundColor = App.darkMode ?
      App.cellBackgroundColor : color
    self.reminderButton.cornerRadius = 5

    var coordinates: [CLLocationCoordinate2D] = []
    for step in section.journey?.passList ?? [] {
      let annotation = MKPointAnnotation()
      annotation.coordinate =
        CLLocationCoordinate2D(latitude: step.station.coordinate.x,
                               longitude: step.station.coordinate.y)
      coordinates.append(annotation.coordinate)

      annotation.title =  (App.stops.filter({
        $0.sbbId == step.station.id
      })[safe: 0]?.name) ?? step.station.name

      self.names.append((App.stops.filter({
        $0.sbbId == step.station.id
      })[safe: 0]?.name) ?? step.station.name)

      mapView.addAnnotation(annotation)
    }

    let geodesic = MKPolyline(coordinates: &coordinates, count: coordinates.count)
    mapView.add(geodesic)

    let regionRadius: CLLocationDistance = 2000
    let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinates[0],
                                                              regionRadius,
                                                              regionRadius)
    mapView.setRegion(coordinateRegion, animated: true)

    if UIDevice.current.orientation.isLandscape,
      UIDevice.current.userInterfaceIdiom == .phone {
      self.stackView.axis = .horizontal
    } else {
      self.stackView.axis = .vertical
    }

    if App.darkMode {
      self.tableView.backgroundColor = .black
      self.buttonBackgroundView.backgroundColor = .black
      self.tableView.separatorColor = App.separatorColor
    }

    ColorModeManager.shared.addColorModeDelegate(self)
  }

  deinit {
    ColorModeManager.shared.removeColorModeDelegate(self)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

  override func colorModeDidUpdated() {
    super.colorModeDidUpdated()
    self.tableView.backgroundColor = App.darkMode ? .black : .white
    self.buttonBackgroundView.backgroundColor = App.darkMode ? .black : .white
    self.tableView.separatorColor = App.separatorColor
    self.reminderButton.setImage(#imageLiteral(resourceName: "cel-bell").maskWith(color: App.darkMode ?
      color : color.contrast),
                                 for: .normal)
    self.reminderButton.setTitleColor(App.darkMode ? color : color.contrast,
                                      for: .normal)
    self.reminderButton.backgroundColor = App.darkMode ?
      App.cellBackgroundColor : color
    self.tableView.reloadData()
  }

  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    // swiftlint:disable:previous line_length
    if UIDevice.current.orientation.isLandscape,
      UIDevice.current.userInterfaceIdiom == .phone {
      self.stackView.axis = .horizontal
    } else {
      self.stackView.axis = .vertical
    }
  }

  @IBAction func remind() {
    let dateA = Date(timeIntervalSince1970:
      TimeInterval(self.section.departure.departureTimestamp!))
    let date = Calendar.current.dateComponents([.hour,
                                                .minute,
                                                .day,
                                                .month,
                                                .year],
                                               from: Date(),
                                               to: dateA)
    var alertController = UIAlertController(title: Text.reminder,
                                            message: Text.whenReminder,
                                            preferredStyle: .alert)
    if date.remainingMinutes == 0 {
      alertController.title = Text.busIsComming
      alertController.message = Text.cantSetATimer
    } else {
      let leftTime = date.remainingMinutes
      let departureTimeAction = UIAlertAction(title: Text.atDepartureTime,
                                              style: .default) { _ in
        self.setAlert(with: 0)
      }
      alertController.addAction(departureTimeAction)

      if leftTime > 5 {
        let fiveMinutesBeforeAction = UIAlertAction(title: Text.fiveMinutesBefore,
                                                    style: .default) { _ in
          self.setAlert(with: 5)
        }
        alertController.addAction(fiveMinutesBeforeAction)
      }
      if leftTime > 10 {
        let tenMinutesBeforeAction = UIAlertAction(title: Text.tenMinutesBefore,
                                                   style: .default) { _ in
          self.setAlert(with: 10)
        }
        alertController.addAction(tenMinutesBeforeAction)
      }

      let otherAction = UIAlertAction(title: Text.other, style: .default) { _ in
        alertController.dismiss(animated: true, completion: nil)
        alertController = UIAlertController(title: Text.reminder,
                                            message: Text.whenReminder,
                                            preferredStyle: .alert)

        alertController.addTextField { textField in
          textField.placeholder = Text.numberMinutesBeforeDepartures
          textField.keyboardType = .numberPad
          textField.keyboardAppearance = App.darkMode ? .dark : .light
        }

        let okAction = UIAlertAction(title: Text.ok, style: .default) { _ in
          guard let remainingTime =
            Int(alertController.textFields?[0].text ?? "#!?") else { return }
          self.setAlert(with: remainingTime)
        }
        alertController.addAction(okAction)

        let cancelAction = UIAlertAction(title: Text.cancel,
                                         style: .destructive) { _ in
        }
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
      }

      alertController.addAction(otherAction)
    }

    let cancelAction = UIAlertAction(title: Text.cancel, style: .cancel) { _ in }
    alertController.addAction(cancelAction)

    present(alertController, animated: true, completion: nil)
  }

  func setAlert(with timeBefore: Int) {
    let date = Date(timeIntervalSince1970:
      TimeInterval(self.section.departure.departureTimestamp!))
      .addingTimeInterval(TimeInterval(timeBefore * -60))
    let components = Calendar.current.dateComponents([.hour,
                                                      .minute,
                                                      .day,
                                                      .month,
                                                      .year], from: date)

    let destinationName = App.stops.filter({
      $0.nameTransportAPI == section.journey?.to
    })[safe: 0]?.name ?? (section.journey?.to ?? "#?!")

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter
        .current()
        .requestAuthorization(options: [.alert,
                                        .sound]) {(accepted, _) in
        if !accepted {
          print("Notification access denied.")
          return
        }
      }
    } else {
      let type: UIUserNotificationType = [UIUserNotificationType.badge,
                                          UIUserNotificationType.alert,
                                          UIUserNotificationType.sound]
      let setting = UIUserNotificationSettings(types: type, categories: nil)
      UIApplication.shared.registerUserNotificationSettings(setting)
    }

    UIApplication.shared.registerForRemoteNotifications()

    if #available(iOS 10.0, *) {
      let trigger = UNCalendarNotificationTrigger(dateMatching: components,
                                                  repeats: false)
      let content = UNMutableNotificationContent()

      content.title =
        timeBefore == 0 ? Text.busIsCommingNow : Text.minutesLeft(timeBefore)

      content.body = Text.take(line: section.journey?.lineCode, to: destinationName)
      content.sound = UNNotificationSound.default()
      let identifier = "routeNotification-\(String.random(30))"
      let request = UNNotificationRequest(identifier: identifier,
                                          content: content,
                                          trigger: trigger)
      UNUserNotificationCenter.current().add(request) {(error) in
        if let error = error {
          print("Uh oh! We had an error: \(error)")
          let alertController = UIAlertController(title: Text.error,
                                                  message: Text.sorryError,
                                                  preferredStyle: .alert)
          alertController.addAction(UIAlertAction(title: Text.ok,
                                                  style: .default,
                                                  handler: nil))
          alertController.addAction(UIAlertAction(title: Text.sendMail,
                                                  style: .default,
                                                  handler: { (_) in
            let mailComposerVC = MFMailComposeViewController()
            mailComposerVC.mailComposeDelegate = self

            mailComposerVC.setToRecipients(["support@asmartcode.com"])
            mailComposerVC.setSubject("tpg offline - Bug report")
            mailComposerVC.setMessageBody("\(error.localizedDescription)",
              isHTML: false)

            if MFMailComposeViewController.canSendMail() {
              self.present(mailComposerVC, animated: true, completion: nil)
            }
          }))

          self.present(alertController, animated: true, completion: nil)
        } else {
          let message = Text.notificationWillBeSend(minutes: timeBefore)
          let alertController = UIAlertController(title: Text.youWillBeReminded,
                                                  message: message,
                                                  preferredStyle: .alert)
          alertController.addAction(UIAlertAction(title: Text.ok,
                                                  style: .default,
                                                  handler: nil))
          self.present(alertController, animated: true, completion: nil)
        }
      }
    } else {
      let notification = UILocalNotification()
      notification.fireDate = date
      if timeBefore == 0 {
        notification.alertBody = Text.takeNow(line: section.journey?.lineCode,
                                              to: destinationName)
      } else {
        notification.alertBody = Text.take(line: section.journey?.lineCode,
                                           to: destinationName,
                                           in: timeBefore)
      }
      notification.identifier = "routeNotification-\(String.random(30))"
      notification.soundName = UILocalNotificationDefaultSoundName
      UIApplication.shared.scheduleLocalNotification(notification)
    }
  }
}

extension RouteStepViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView,
               rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if overlay is MKPolyline {
      let polylineRenderer = MKPolylineRenderer(overlay: overlay)
      polylineRenderer.strokeColor = self.color
      polylineRenderer.lineWidth = 5
      return polylineRenderer
    }

    return MKOverlayRenderer()
  }

  func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    guard let annotation = view.annotation else {
      return
    }
    titleSelected = (annotation.title ?? "") ?? ""
    if let index = self.names.index(of: titleSelected) {
      self.tableView.scrollToRow(at: IndexPath(row: index, section: 0),
                                 at: .top,
                                 animated: true)
    }
    let regionRadius: CLLocationDistance = 2000
    let coordinateRegion = MKCoordinateRegionMakeWithDistance(annotation.coordinate,
                                                              regionRadius,
                                                              regionRadius)
    mapView.setRegion(coordinateRegion, animated: true)
  }

  func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
    titleSelected = ""
  }
}

extension RouteStepViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView,
                 numberOfRowsInSection section: Int) -> Int {
    return self.section.journey?.passList.count ?? 0
  }

  func tableView(_ tableView: UITableView,
                 cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "stepRow",
                                             for: indexPath)

    var titleAttributes =
      [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .headline),
       NSAttributedStringKey.foregroundColor: App.textColor]
        as [NSAttributedStringKey: Any]
    var subtitleAttributes =
      [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .subheadline),
       NSAttributedStringKey.foregroundColor: App.textColor]
        as [NSAttributedStringKey: Any]
    cell.textLabel?.numberOfLines = 0
    cell.detailTextLabel?.numberOfLines = 0

    let routeResultsStop = self.section.journey?.passList[indexPath.row]

    let name = (App.stops.filter({
      $0.sbbId == routeResultsStop?.station.id ?? ""
    })[safe: 0]?.name) ?? (routeResultsStop?.station.name ?? "")

    if titleSelected == name {
      if App.darkMode {
        cell.backgroundColor = App.cellBackgroundColor
        titleAttributes[.foregroundColor] = self.color
        subtitleAttributes[.foregroundColor] = self.color
      } else {
        cell.backgroundColor = self.color
        titleAttributes[.foregroundColor] = self.color.contrast
        subtitleAttributes[.foregroundColor] = self.color.contrast
      }
    } else {
      cell.backgroundColor = App.cellBackgroundColor
    }

    cell.textLabel?.attributedText = NSAttributedString(string: name,
                                                        attributes: titleAttributes)
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .none
    dateFormatter.timeStyle = .short
    let hour: Date
    if let departureTimestamp = routeResultsStop?.departureTimestamp {
      hour = Date(timeIntervalSince1970: TimeInterval(departureTimestamp))
    } else {
      hour = Date(timeIntervalSince1970: TimeInterval(
        routeResultsStop?.arrivalTimestamp ?? 0))
    }

    cell.detailTextLabel?.attributedText =
      NSAttributedString(string: dateFormatter.string(from: hour),
                         attributes: subtitleAttributes)

    if App.darkMode {
      let selectedView = UIView()
      selectedView.backgroundColor = .black
      cell.selectedBackgroundView = selectedView
    } else {
      let selectedView = UIView()
      selectedView.backgroundColor = UIColor.white.darken(by: 0.1)
      cell.selectedBackgroundView = selectedView
    }

    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let row = tableView.cellForRow(at: indexPath)
    titleSelected = row?.textLabel?.text ?? ""
    guard let annotiation = mapView.annotations.filter({
      $0.title ?? "#" == titleSelected
    })[safe: 0] else {
      return
    }
    mapView.selectAnnotation(annotiation, animated: true)
    let regionRadius: CLLocationDistance = 200
    let coordinateRegion = MKCoordinateRegionMakeWithDistance(annotiation.coordinate,
                                                              regionRadius,
                                                              regionRadius)
    mapView.setRegion(coordinateRegion, animated: true)
  }
}

extension RouteStepViewController: MFMailComposeViewControllerDelegate {
  func mailComposeController(_ controller: MFMailComposeViewController,
                             didFinishWith result: MFMailComposeResult, error: Error?) {
    // swiftlint:disable:previous line_length
    controller.dismiss(animated: true, completion: nil)
  }
}
