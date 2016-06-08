//
//  SettingsTableViewController.swift
//  tpg offline
//
//  Created by Rémy Da Costa Faro on 20/12/2015.
//  Copyright © 2016 Rémy Da Costa Faro. All rights reserved.
//

import UIKit
import SwiftyJSON
import ChameleonFramework
import FontAwesomeKit
import Onboard
import Alamofire
import MRProgress
import SCLAlertView
import SafariServices

class SettingsTableViewController: UITableViewController {
    
    var rowsList = [
        [FAKFontAwesome.barsIconWithSize(20), "Choix du menu par défaut".localized(), "showChoixDuMenuParDefault"],
        [FAKFontAwesome.locationArrowIconWithSize(20), "Localisation".localized(), "showLocationMenu"],
        [FAKFontAwesome.infoCircleIconWithSize(20), "Crédits".localized(), "showCredits"],
        [FAKFontAwesome.githubIconWithSize(20), "Page GitHub du projet".localized(), "showGitHub"],
        [FAKFontAwesome.graduationCapIconWithSize(20), "Revoir le tutoriel".localized(), "showTutoriel"]
    ]
    
    let premiumRowList = [
        [FAKFontAwesome.paintBrushIconWithSize(20), "Thèmes".localized(), "showThemesMenu"],
        [FAKFontAwesome.refreshIconWithSize(20), "Actualiser les départs (Offline)".localized(), "actualiserDeparts"]
    ]
    
    let nonPremiumRowList = [
        [FAKFontAwesome.starIconWithSize(20), "Premium".localized(), "showPremium"]
    ]
    
    let defaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshTheme()
        if (AppValues.premium == true) {
            rowsList += premiumRowList
        }
        else {
            rowsList += nonPremiumRowList
        }
        
        if !defaults.boolForKey("tutorial") && !(NSProcessInfo.processInfo().arguments.contains("-donotask")) {
            afficherTutoriel()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        refreshTheme()
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowsList.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("parametresCell", forIndexPath: indexPath)
        
        cell.textLabel!.text = (rowsList[indexPath.row][1] as! String)
        let iconCheveron = FAKFontAwesome.chevronRightIconWithSize(15)
        iconCheveron.addAttribute(NSForegroundColorAttributeName, value: AppValues.textColor)
        cell.accessoryView = UIImageView(image: iconCheveron.imageWithSize(CGSize(width: 20, height: 20)))
        let icone = rowsList[indexPath.row][0] as! FAKFontAwesome
        icone.addAttribute(NSForegroundColorAttributeName, value: AppValues.textColor)
        cell.imageView?.image = icone.imageWithSize(CGSize(width: 20, height: 20))
        cell.backgroundColor = AppValues.primaryColor
        cell.textLabel?.textColor = AppValues.textColor
        
        let view = UIView()
        view.backgroundColor = AppValues.secondaryColor
        cell.selectedBackgroundView = view
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if rowsList[indexPath.row][2] as! String == "showTutoriel" {
            afficherTutoriel()
        }
        else if rowsList[indexPath.row][2] as! String == "actualiserDeparts" {
            actualiserDeparts()
        }
        else if rowsList[indexPath.row][2] as! String == "showGitHub" {
            if #available(iOS 9.0, *) {
                let safariViewController = SFSafariViewController(URL: NSURL(string: "https://github.com/RemyDCF/tpg-offline")!, entersReaderIfAvailable: true)
                if ContrastColorOf(AppValues.primaryColor, returnFlat: true) == FlatWhite() {
                    safariViewController.view.tintColor = AppValues.primaryColor
                }
                else {
                    safariViewController.view.tintColor = AppValues.textColor
                }
                presentViewController(safariViewController, animated: true, completion: nil)
            } else {
                performSegueWithIdentifier("showGitHub", sender: self)
            }
        }
        else {
            performSegueWithIdentifier(rowsList[indexPath.row][2] as! String, sender: self)
        }
    }
    
    func actualiserDeparts() {
        tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow!, animated: true)
        let alerte = SCLAlertView()
        alerte.addButton("OK, démarrer") {
            CATransaction.begin()
            
            let progressBar = MRProgressOverlayView.showOverlayAddedTo(self.view.window, title: "Chargement", mode: .DeterminateCircular, animated: true)
            if ContrastColorOf(AppValues.secondaryColor, returnFlat: true) == FlatWhite() {
                progressBar.tintColor = AppValues.secondaryColor
                progressBar.titleLabel!.textColor = AppValues.secondaryColor
            }
            else {
                progressBar.tintColor = AppValues.textColor
                progressBar.titleLabel!.textColor = AppValues.textColor
            }
            
            CATransaction.setCompletionBlock({
                Alamofire.request(.GET, "https://raw.githubusercontent.com/RemyDCF/tpg-offline/master/iOS/Departs/listeDeparts.json").validate().responseJSON { response in
                    switch response.result {
                    case .Success:
                        if let value = response.result.value {
                            var compteur = 0
                            var ok = 0
                            let json = JSON(value)
                            for (_, subJson) in json {
                                Alamofire.download(.GET, "https://raw.githubusercontent.com/RemyDCF/tpg-offline/master/iOS/Departs/\(subJson.stringValue)", destination: { (temporaryURL, response) -> NSURL in
                                    let fileManager = NSFileManager.defaultManager()
                                    let directoryURL = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                                    let pathComponent = response.suggestedFilename
                                    
                                    if NSFileManager.defaultManager().fileExistsAtPath(directoryURL.URLByAppendingPathComponent(pathComponent!).path!) {
                                        try! NSFileManager.defaultManager().removeItemAtURL(directoryURL.URLByAppendingPathComponent(pathComponent!))
                                    }
                                    
                                    return directoryURL.URLByAppendingPathComponent(pathComponent!)
                                }).response { _, _, _, error in
                                    if error != nil {
                                        Alamofire.download(.GET, "https://raw.githubusercontent.com/RemyDCF/tpg-offline/master/iOS/Departs/\(subJson.stringValue)", destination: { (temporaryURL, response) -> NSURL in
                                            let fileManager = NSFileManager.defaultManager()
                                            let directoryURL = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                                            let pathComponent = response.suggestedFilename
                                            
                                            if NSFileManager.defaultManager().fileExistsAtPath(directoryURL.URLByAppendingPathComponent(pathComponent!).path!) {
                                                try! NSFileManager.defaultManager().removeItemAtURL(directoryURL.URLByAppendingPathComponent(pathComponent!))
                                            }
                                            
                                            return directoryURL.URLByAppendingPathComponent(pathComponent!)
                                        }).response { _, _, _, error in
                                            if error != nil {
                                                Alamofire.download(.GET, "https://raw.githubusercontent.com/RemyDCF/tpg-offline/master/iOS/Departs/\(subJson.stringValue)", destination: { (temporaryURL, response) -> NSURL in
                                                    let fileManager = NSFileManager.defaultManager()
                                                    let directoryURL = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                                                    let pathComponent = response.suggestedFilename
                                                    
                                                    if NSFileManager.defaultManager().fileExistsAtPath(directoryURL.URLByAppendingPathComponent(pathComponent!).path!) {
                                                        try! NSFileManager.defaultManager().removeItemAtURL(directoryURL.URLByAppendingPathComponent(pathComponent!))
                                                    }
                                                    
                                                    return directoryURL.URLByAppendingPathComponent(pathComponent!)
                                                }).response { _, _, _, error in
                                                    if error != nil {
                                                        Alamofire.download(.GET, "https://raw.githubusercontent.com/RemyDCF/tpg-offline/master/iOS/Departs/\(subJson.stringValue)", destination: { (temporaryURL, response) -> NSURL in
                                                            let fileManager = NSFileManager.defaultManager()
                                                            let directoryURL = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                                                            let pathComponent = response.suggestedFilename
                                                            
                                                            if NSFileManager.defaultManager().fileExistsAtPath(directoryURL.URLByAppendingPathComponent(pathComponent!).path!) {
                                                                try! NSFileManager.defaultManager().removeItemAtURL(directoryURL.URLByAppendingPathComponent(pathComponent!))
                                                            }
                                                            
                                                            return directoryURL.URLByAppendingPathComponent(pathComponent!)
                                                        }).response { _, _, _, error in
                                                            if error != nil {
                                                                compteur += 1
                                                            } else {
                                                                ok += 1
                                                            }
                                                            progressBar.setProgress(Float(Int(ok + compteur) * 100) / Float(json.count) / 100, animated: true)
                                                            CATransaction.flush()
                                                            
                                                            if compteur + ok == json.count {
                                                                progressBar.dismiss(true)
                                                                let alerte2 = SCLAlertView()
                                                                if compteur != 0 {
                                                                    alerte2.showWarning("Opération terminée", subTitle: "L'opération est terminée. Toutrefois, nous n'avons pas pu télécharger les départs pour \(compteur) arrêts.", closeButtonTitle: "Fermer")
                                                                }
                                                                else {
                                                                    alerte2.showSuccess("Opération terminée", subTitle: "L'opération s'est terminée avec succès.", closeButtonTitle: "Fermer")
                                                                }
                                                            }
                                                        }
                                                    } else {
                                                        ok += 1
                                                    }
                                                    progressBar.setProgress(Float(Int(ok + compteur) * 100) / Float(json.count) / 100, animated: true)
                                                    CATransaction.flush()
                                                    
                                                    if compteur + ok == json.count {
                                                        progressBar.dismiss(true)
                                                        let alerte2 = SCLAlertView()
                                                        if compteur != 0 {
                                                            alerte2.showWarning("Opération terminée", subTitle: "L'opération est terminée. Toutrefois, nous n'avons pas pu télécharger les départs pour \(compteur) arrêts.", closeButtonTitle: "Fermer")
                                                        }
                                                        else {
                                                            alerte2.showSuccess("Opération terminée", subTitle: "L'opération s'est terminée avec succès.", closeButtonTitle: "Fermer")
                                                        }
                                                    }
                                                }
                                            } else {
                                                ok += 1
                                            }
                                            progressBar.setProgress(Float(Int(ok + compteur) * 100) / Float(json.count) / 100, animated: true)
                                            CATransaction.flush()
                                            
                                            if compteur + ok == json.count {
                                                progressBar.dismiss(true)
                                                let alerte2 = SCLAlertView()
                                                if compteur != 0 {
                                                    alerte2.showWarning("Opération terminée", subTitle: "L'opération est terminée. Toutrefois, nous n'avons pas pu télécharger les départs pour \(compteur) arrêts.", closeButtonTitle: "Fermer")
                                                }
                                                else {
                                                    alerte2.showSuccess("Opération terminée", subTitle: "L'opération s'est terminée avec succès.", closeButtonTitle: "Fermer")
                                                }
                                            }
                                        }
                                    } else {
                                        ok += 1
                                    }
                                    progressBar.setProgress(Float(Int(ok + compteur) * 100) / Float(json.count) / 100, animated: true)
                                    CATransaction.flush()
                                    
                                    if compteur + ok == json.count {
                                        progressBar.dismiss(true)
                                        let alerte2 = SCLAlertView()
                                        if compteur != 0 {
                                            alerte2.showWarning("Opération terminée", subTitle: "L'opération est terminée. Toutrefois, nous n'avons pas pu télécharger les départs pour \(compteur) arrêts.", closeButtonTitle: "Fermer")
                                        }
                                        else {
                                            alerte2.showSuccess("Opération terminée", subTitle: "L'opération s'est terminée avec succès.", closeButtonTitle: "Fermer")
                                        }
                                    }
                                }
                            }
                            
                        }
                    case .Failure(_):
                        progressBar.dismiss(true)
                        let alerte = SCLAlertView()
                        alerte.showError("Pas de réseau", subTitle: "Vous n'êtes pas connecté au réseau. Pour actualiser les départs, merci de vous connecter au réseau.", closeButtonTitle: "Fermer", duration: 10)
                    }
                }
            })
            
            CATransaction.commit()
        }
        alerte.showInfo("Actualisation", subTitle: "Vous allez actualiser les départs. Attention : Nous vous recommandons d'utiliser le wifi pour éviter d'utiliser votre forfait data (50 Mo). Cette opération peut prendre plusieurs minutes et n'est pas annulable. Veuillez également laisser l'application au premier plan pour ne pas interrompre le téléchargement.", closeButtonTitle: "Annuler")
    }
    
    func afficherTutoriel() {
        let rect = CGRectMake(0.0, 0.0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetFillColorWithColor(context, AppValues.primaryColor.CGColor)
        
        CGContextFillRect(context, rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let page1 = OnboardingContentViewController (title: "Bienvenue dans tpg offline".localized(), body: "tpg offline est une application qui facilite vos déplacements avec les transports publics genevois, même sans réseau.".localized(), image: nil, buttonText: "Continuer".localized(), actionBlock: nil)
        
        let iconeI = FAKIonIcons.iosClockIconWithSize(50)
        iconeI.addAttribute(NSForegroundColorAttributeName, value: AppValues.textColor)
        let page2 = OnboardingContentViewController (title: "Départs".localized(), body: "Le menu Départs vous informe des prochains départs pour un arrêt.".localized(), image: iconeI.imageWithSize(CGSize(width: 50, height: 50)), buttonText: "Continuer".localized(), actionBlock: nil)
        var iconeF = FAKFontAwesome.globeIconWithSize(50)
        iconeF.addAttribute(NSForegroundColorAttributeName, value: AppValues.textColor)
        let page3 = OnboardingContentViewController (title: "Mode offline".localized(), body: "Le Mode offline vous permet de connaitre les horaires à un arrêt même si vous n’avez pas de réseau.".localized(), image: iconeF.imageWithSize(CGSize(width: 50, height: 50)), buttonText: "Continuer".localized(), actionBlock: nil)
        iconeF = FAKFontAwesome.warningIconWithSize(50)
        
        iconeF.addAttribute(NSForegroundColorAttributeName, value: AppValues.textColor)
        let page4 = OnboardingContentViewController (title: "Avertissement".localized(), body: "Sans réseau, tpg offline ne permet pas d’avoir des horaires garantis ni de connaitre les possibles perturbations du réseau. \rtpg offline ne peut aucunement être tenu pour responsable en cas de retard, d’avance, ni de connection manquée.".localized(), image: iconeF.imageWithSize(CGSize(width: 50, height: 50)), buttonText: "J'ai compris, continuer".localized(), actionBlock: nil)
        iconeF = FAKFontAwesome.mapSignsIconWithSize(50)
        iconeF.addAttribute(NSForegroundColorAttributeName, value: AppValues.textColor)
        let page5 = OnboardingContentViewController (title: "Itinéraires".localized(), body: "l’application propose un menu Itinéraires. Vous pouvez vous déplacer très facilement grâce à cette fonction.".localized(), image: iconeF.imageWithSize(CGSize(width: 50, height: 50)), buttonText: "Continuer".localized(), actionBlock: nil)
        iconeF = FAKFontAwesome.mapIconWithSize(50)
        iconeF.addAttribute(NSForegroundColorAttributeName, value: AppValues.textColor)
        let page6 = OnboardingContentViewController (title: "Plans".localized(), body: "Tous les plans des tpg sont disponibles dans le menu Plans.".localized(), image: iconeF.imageWithSize(CGSize(width: 50, height: 50)), buttonText: "Continuer".localized(), actionBlock: nil)
        iconeF = FAKFontAwesome.warningIconWithSize(50)
        iconeF.addAttribute(NSForegroundColorAttributeName, value: AppValues.textColor)
        let page7 = OnboardingContentViewController (title: "Incidents".localized(), body: "Soyez avertis en cas de perturbations sur le réseau tpg grâce au menu Incidents.".localized(), image: iconeF.imageWithSize(CGSize(width: 50, height: 50)), buttonText: "Continuer".localized(), actionBlock: nil)
        iconeF = FAKFontAwesome.bellOIconWithSize(50)
        iconeF.addAttribute(NSForegroundColorAttributeName, value: AppValues.textColor)
        let page8 = OnboardingContentViewController (title: "Rappels".localized(), body: "Dans les menus Départs et Itinéraires, faite glisser un des horaires proposés vers la gauche pour être notifié(e) d’un départ et éviter de rater votre transport ou votre connection.".localized(), image: iconeF.imageWithSize(CGSize(width: 50, height: 50)), buttonText: "Continuer".localized(), actionBlock: nil)
        iconeF = FAKFontAwesome.githubIconWithSize(50)
        iconeF.addAttribute(NSForegroundColorAttributeName, value: AppValues.textColor)
        let page9 = OnboardingContentViewController (title: "Open Source", body: "tpg offline est Open Source. Vous pouvez donc modifier et améliorer l’application si vous le souhaitez.\rSi vous avez des idées ou que vous trouvez un bug, n'hésitez pas à consulter notre projet sur GitHub. (https://github.com/RemyDCF/tpg-offline)".localized(), image: iconeF.imageWithSize(CGSize(width: 50, height: 50)), buttonText: "Continuer".localized(), actionBlock: nil)
        iconeF = FAKFontAwesome.ellipsisHIconWithSize(50)
        iconeF.addAttribute(NSForegroundColorAttributeName, value: AppValues.textColor)
        let page10 = OnboardingContentViewController (title: "Et beaucoup d'autres choses".localized(), body: "D'autres surprises vous attendent dans l'application. Alors, partez à l'aventure et bon voyage !".localized(), image: iconeF.imageWithSize(CGSize(width: 50, height: 50)), buttonText: "Terminer".localized(), actionBlock: { (onboardingvc) in
            self.dismissViewControllerAnimated(true, completion: nil)
            if !self.defaults.boolForKey("tutorial") {
                self.defaults.setBool(true, forKey: "tutorial")
                self.tabBarController?.selectedIndex = 0
            }
        })
        
        page1.movesToNextViewController = true
        page2.movesToNextViewController = true
        page3.movesToNextViewController = true
        page4.movesToNextViewController = true
        page5.movesToNextViewController = true
        page6.movesToNextViewController = true
        page7.movesToNextViewController = true
        page8.movesToNextViewController = true
        page9.movesToNextViewController = true
        
        let onboardingVC = OnboardingViewController(backgroundImage: image, contents: [page1, page2, page3, page4, page5, page6, page7, page8, page9, page10])
        onboardingVC.titleTextColor = AppValues.textColor
        onboardingVC.bodyTextColor = AppValues.textColor
        onboardingVC.buttonTextColor = AppValues.textColor
        onboardingVC.pageControl.pageIndicatorTintColor = AppValues.secondaryColor
        onboardingVC.pageControl.currentPageIndicatorTintColor = AppValues.textColor
        onboardingVC.skipButton.setTitleColor(AppValues.textColor, forState: .Normal)
        onboardingVC.bodyFontSize = 18
        onboardingVC.shouldMaskBackground = false
        onboardingVC.shouldFadeTransitions = true
        onboardingVC.allowSkipping = true
        onboardingVC.skipButton.setTitle("Passer".localized(), forState: .Normal)
        onboardingVC.skipHandler = {
            self.dismissViewControllerAnimated(true, completion: nil)
            if !self.defaults.boolForKey("tutorial") {
                self.defaults.setBool(true, forKey: "tutorial")
                self.tabBarController?.selectedIndex = 0
            }
        }
        presentViewController(onboardingVC, animated: true, completion: nil)
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showGitHub" {
            let destinationViewController: WebViewController = (segue.destinationViewController) as! WebViewController
            destinationViewController.url = "https://github.com/RemyDCF/tpg-offline"
        }
    }
}
