//
//  PendingNotificationsTableViewController.swift
//  tpg offline
//
//  Created by Rémy Da Costa Faro on 16/01/2018.
//  Copyright © 2018 Rémy Da Costa Faro. All rights reserved.
//

import UIKit
import UserNotifications
import Crashlytics
import Alamofire

class PendingNotificationsTableViewController: UITableViewController {

  var requestStatus: RequestStatus = .loading {
    didSet {
      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
    }
  }

  var pendingNotifications: [[String]] = [] {
    didSet {
      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    title = Text.notifications

    App.log("Show pending notifications")
    App.logEvent("Show pending notifications")

    if App.darkMode {
      self.tableView.backgroundColor = .black
      self.navigationController?.navigationBar.barStyle = .black
      self.tableView.separatorColor = App.separatorColor
    }
    self.navigationItem.rightBarButtonItem = self.editButtonItem
    ColorModeManager.shared.addColorModeDelegate(self)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    pendingNotifications = []
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .none
    dateFormatter.timeStyle = .short

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter
        .current()
        .getPendingNotificationRequests { (requests) in
        for request in requests {
          if let trigger = (request.trigger as? UNCalendarNotificationTrigger) {
            let date = Calendar.current.date(from: trigger.dateComponents) ?? Date()
            self.pendingNotifications.append([
              "\(dateFormatter.string(from: date)) - \(request.content.title)",
              request.content.body,
              request.identifier])
          } else if (request.trigger
            as? UNLocationNotificationTrigger) != nil {
            self.pendingNotifications.append([Text.goMode,
                                              request.content.body,
                                              request.identifier])
          }
        }
      }
    } else {
      for notification in (UIApplication.shared.scheduledLocalNotifications ?? []) {
        pendingNotifications.append([
          dateFormatter.string(from: notification.fireDate ?? Date()),
          notification.alertBody ?? Text.unknowContent,
          notification.identifier ?? ""])
      }
    }

    self.requestStatus = .loading
  }

  deinit {
    ColorModeManager.shared.removeColorModeDelegate(self)
  }

  // MARK: - Table view data source

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(_ tableView: UITableView,
                          numberOfRowsInSection section: Int) -> Int {
    return pendingNotifications.count
  }

  override func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell =
      tableView.dequeueReusableCell(withIdentifier: "pendingNotificationCell",
                                    for: indexPath)

    let titleAttributes: [NSAttributedString.Key: Any] =
      [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline),
       NSAttributedString.Key.foregroundColor: App.textColor]
        as [NSAttributedString.Key: Any]
    let subtitleAttributes: [NSAttributedString.Key: Any] =
      [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .subheadline),
       NSAttributedString.Key.foregroundColor: App.textColor]
        as [NSAttributedString.Key: Any]
    cell.textLabel?.numberOfLines = 0
    cell.detailTextLabel?.numberOfLines = 0
    cell.textLabel?.attributedText =
        NSAttributedString(string: pendingNotifications[indexPath.row][0],
                           attributes: titleAttributes)
    cell.detailTextLabel?.attributedText =
        NSAttributedString(string: pendingNotifications[indexPath.row][1],
                           attributes: subtitleAttributes)
    cell.backgroundColor = App.cellBackgroundColor
    let view = UIView()
    view.backgroundColor = App.cellBackgroundColor.darken(by: 0.1)
    cell.selectedBackgroundView = view

    return cell
  }

  override func tableView(_ tableView: UITableView,
                          canEditRowAt indexPath: IndexPath) -> Bool {
    return !pendingNotifications.isEmpty
  }

  override func tableView(_ tableView: UITableView,
                          commit editingStyle: UITableViewCell.EditingStyle,
                          forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      if !pendingNotifications.isEmpty {
        if #available(iOS 10.0, *) {
          UNUserNotificationCenter
            .current()
            .removePendingNotificationRequests(withIdentifiers:
              [pendingNotifications[indexPath.row][2]])
          pendingNotifications.remove(at: indexPath.row)
        } else {
          guard let notification = UIApplication
            .shared
            .scheduledLocalNotifications?.filter({
              $0.identifier == pendingNotifications[indexPath.row][2]
            })[safe: 0] else {
            return
          }
          UIApplication.shared.cancelLocalNotification(notification)
          pendingNotifications.remove(at: indexPath.row)
        }
        tableView.deleteRows(at: [indexPath], with: .fade)
      }
    }
  }

  override func tableView(_ tableView: UITableView,
                          titleForHeaderInSection section: Int) -> String? {
    return [Text.notifications][section]
  }
}

@available(iOS 10.0, *)
extension PendingNotificationsTableViewController: UNUserNotificationCenterDelegate {
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    // swiftlint:disable:previous line_length
    self.tableView.reloadData()
  }
}
