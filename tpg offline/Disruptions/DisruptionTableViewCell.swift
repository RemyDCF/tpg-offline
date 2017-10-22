//
//  DisruptionTableViewCell.swift
//  tpgoffline
//
//  Created by Remy DA COSTA FARO on 18/06/2017.
//  Copyright © 2017 Remy DA COSTA FARO. All rights reserved.
//

import UIKit

class DisruptionTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    var color: UIColor = .white
    var loading = true
    var timer: Timer?
    var opacity = 0.5

    var disruption: Disruption? = nil {
        didSet {
            guard let disruption = disruption else { return }
            self.color = App.linesColor.filter({ $0.line == disruption.line })[safe: 0]?.color ?? .black

            if self.color.contrast != .white {
                self.color = self.color.darken(by: 0.2)!
            }

            titleLabel.backgroundColor = .white
            descriptionLabel.backgroundColor = .white
            titleLabel.textColor = color
            descriptionLabel.textColor = color

            titleLabel.cornerRadius = 0
            descriptionLabel.cornerRadius = 0

            titleLabel.text = disruption.nature
            if disruption.place != "" {
                titleLabel.text = titleLabel.text?.appending(" - \(disruption.place)")
            }
            descriptionLabel.text = disruption.consequence
            self.loading = false
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        titleLabel.backgroundColor = .gray
        descriptionLabel.backgroundColor = .gray
        titleLabel.text = "   "
        descriptionLabel.text = "\n\n\n"
        titleLabel.cornerRadius = 10
        descriptionLabel.cornerRadius = 10
        titleLabel.clipsToBounds = true
        descriptionLabel.clipsToBounds = true
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.changeOpacity), userInfo: nil, repeats: true)
    }

    @objc func changeOpacity() {
        if loading == false {
            timer?.invalidate()
            titleLabel.alpha = 1
            descriptionLabel.alpha = 1
        } else {
            self.opacity += 0.010
            if self.opacity >= 0.2 {
                self.opacity = 0.1
            }
            var opacity = CGFloat(self.opacity)
            if opacity > 0.5 {
                opacity -= (0.5 - opacity)
            }
            titleLabel.alpha = opacity
            descriptionLabel.alpha = opacity
        }
    }
}