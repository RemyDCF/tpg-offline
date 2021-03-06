//
//  RouteResultsTableViewCell.swift
//  tpg offline
//
//  Created by Rémy Da Costa Faro on 10/09/2017.
//  Copyright © 2018 Rémy Da Costa Faro. All rights reserved.
//

import UIKit

class RouteResultsTableViewCell: UITableViewCell {

  @IBOutlet weak var departureStopLabel: UILabel!
  @IBOutlet weak var departureHourLabel: UILabel!
  @IBOutlet weak var arrivalStopLabel: UILabel!
  @IBOutlet weak var arrivalHourLabel: UILabel!
  @IBOutlet weak var durationLabel: UILabel!
  @IBOutlet weak var numberOfConnectionsImageView: UIImageView!
  @IBOutlet weak var numberOfConnectionsLabel: UILabel!
  @IBOutlet weak var isWalking: UIImageView!
  @IBOutlet var images: [UIImageView]!

  var loading = true
  var timer: Timer?
  var opacity = 0.5

  var connection: RouteConnection? = nil {
    didSet {
      loading = true
      guard let connection = connection else {
        self.numberOfConnectionsLabel.text = "--"
        self.departureHourLabel.text = "--:--"
        self.arrivalHourLabel.text = "--:--"
        self.durationLabel.text = "--:--"
        self.departureStopLabel.text = ""
        self.arrivalStopLabel.text = ""

        self.timer = Timer.scheduledTimer(timeInterval: 0.1,
                                          target: self,
                                          selector: #selector(self.changeOpacity),
                                          userInfo: nil,
                                          repeats: true)
        return
      }

      durationLabel.alpha = 1
      numberOfConnectionsLabel.alpha = 1
      departureHourLabel.alpha = 1
      arrivalHourLabel.alpha = 1
      durationLabel.alpha = 1

      self.numberOfConnectionsLabel.textColor = App.textColor
      self.departureHourLabel.textColor = App.textColor
      self.arrivalHourLabel.textColor = App.textColor
      self.durationLabel.textColor = App.textColor
      self.departureStopLabel.textColor = App.textColor
      self.arrivalStopLabel.textColor = App.textColor
      self.backgroundColor = App.cellBackgroundColor

      departureStopLabel.text = connection.from.station.name.toStopName
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "HH:mm"
      departureHourLabel.text = dateFormatter.string(from:
        Date(timeIntervalSince1970:
          TimeInterval(connection.from.departureTimestamp ?? 0)))
      arrivalStopLabel.text = connection.to.station.name.toStopName
      arrivalHourLabel.text = dateFormatter.string(from: Date(timeIntervalSince1970:
        TimeInterval(connection.to.arrivalTimestamp ?? 0)))
      let duration = connection.duration ?? ""
      let indexStartOfText = duration.index(duration.startIndex, offsetBy: 3)
      let indexEndOfText = duration.index(duration.endIndex, offsetBy: -3)
      durationLabel.text = String(duration[indexStartOfText..<indexEndOfText])

      numberOfConnectionsImageView.isHidden = connection.sections?.count == 1
      numberOfConnectionsLabel.isHidden = connection.sections?.count == 1
      numberOfConnectionsLabel.text = "\(connection.sections?.count ?? 0 - 1)"

      isWalking.isHidden = !((connection.sections ?? [])
        .map({ $0.walk == nil }).contains(false))

      loading = false
      self.accessoryType = .disclosureIndicator

      for image in images {
        image.image = image.image?.maskWith(color: App.textColor)
      }

      if App.darkMode {
        let selectedView = UIView()
        selectedView.backgroundColor = .black
        self.selectedBackgroundView = selectedView
      } else {
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.white.darken(by: 0.1)
        self.selectedBackgroundView = selectedView
      }
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()

    self.backgroundColor = App.cellBackgroundColor

    numberOfConnectionsLabel.text = "--"
    departureHourLabel.text = "--:--"
    arrivalHourLabel.text = "--:--"
    durationLabel.text = "--:--"

    self.numberOfConnectionsLabel.textColor = App.textColor
    self.departureHourLabel.textColor = App.textColor
    self.arrivalHourLabel.textColor = App.textColor
    self.durationLabel.textColor = App.textColor
    self.departureStopLabel.textColor = App.textColor
    self.arrivalStopLabel.textColor = App.textColor

    timer = Timer.scheduledTimer(timeInterval: 0.1,
                                 target: self,
                                 selector: #selector(self.changeOpacity),
                                 userInfo: nil,
                                 repeats: true)
  }

  @objc func changeOpacity() {
    if loading == false {
      timer?.invalidate()
      for view in images {
        view.alpha = 1
      }
      durationLabel.alpha = 1
      numberOfConnectionsLabel.alpha = 1
      departureHourLabel.alpha = 1
      arrivalHourLabel.alpha = 1
      durationLabel.alpha = 1
    } else {
      self.opacity += 0.010
      if self.opacity >= 0.2 {
        self.opacity = 0.1
      }
      var opacity = CGFloat(self.opacity)
      if opacity > 0.5 {
        opacity -= (0.5 - opacity)
      }
      for view in images {
        view.alpha = opacity
      }
      durationLabel.alpha = opacity
      numberOfConnectionsLabel.alpha = opacity
      departureHourLabel.alpha = opacity
      arrivalHourLabel.alpha = opacity
      durationLabel.alpha = opacity
    }
  }
}
