
//
//  ArretsTableViewController.swift
//  tpg offline
//
//  Created by Alice on 16/11/2015.
//  Copyright © 2015 dacostafaro. All rights reserved.
//

import UIKit
import SwiftyJSON
import ChameleonFramework
import FontAwesomeKit
import CoreLocation
import SwiftLocation

class ArretsTableViewController: UITableViewController {
    var arretsLocalisation = [Arret]()
    var filtredResults = [Arret]()
    let searchController = UISearchController(searchResultsController: nil)
    let locationManager = CLLocationManager()
    let tpgUrl = tpgURL()
    let defaults = NSUserDefaults.standardUserDefaults()
    var arretsKeys: [String] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.tintColor = UIColor.whiteColor()
        self.refreshControl?.backgroundColor = UIColor.flatOrangeColorDark()
        self.refreshControl!.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl!)
        
        requestLocation()
        
        // Result Search Controller
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        searchController.searchBar.barTintColor = UIColor.flatOrangeColorDark()
        searchController.searchBar.placeholder = "Rechercher parmi les arrets"
        searchController.searchBar.tintColor = UIColor.whiteColor()
        tableView.tableHeaderView = self.searchController.searchBar
        
        navigationController?.navigationBar.barTintColor = UIColor.flatOrangeColorDark()
        navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        arretsKeys = [String](AppValues.arrets.keys)
        arretsKeys.sortInPlace({ (string1, string2) -> Bool in
            if string1.lowercaseString < string2.lowercaseString {
                return true
            }
            return false
        })
        
        /*if(traitCollection.forceTouchCapability == .Available){
            registerForPreviewingWithDelegate(self, sourceView: view)
        }*/
        previewer = registerForPreviewingWithDelegate(self, sourceView: view)
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refresh(sender:AnyObject)
    {
        requestLocation()
        tableView.reloadData()
        self.refreshControl!.endRefreshing()
    }
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if searchController.active {
            return 1
        }
        else {
            return 3
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if searchController.active {
            return self.filtredResults.count
        }
        else {
            if section == 0 {
                return arretsLocalisation.count
            }
            else if section == 1 {
                if (AppValues.arretsFavoris == nil) {
                    return 0
                }
                else {
                    return AppValues.arretsFavoris.count
                }
            }
            else {
                return AppValues.arrets.count
            }
        }
    }
    
    func requestLocation() {
        do {
            self.arretsLocalisation = []
            var accurency = Accuracy.Block
            if self.defaults.integerForKey("locationAccurency") == 1 {
                accurency = Accuracy.House
            }
            else if self.defaults.integerForKey("locationAccurency") == 2 {
                accurency = Accuracy.Room
            }
            try SwiftLocation.shared.currentLocation(accurency, timeout: 20, onSuccess: { (location) -> Void in
                /*if let dataArretsLocalisation = self.tpgUrl.getStopsbyLocation(location!) {
                    self.arretsLocalisation = JSON(data: dataArretsLocalisation)
                    self.tableView.reloadData()

                
                }*/
                print("Résultat de la localisation")
                
                if self.defaults.integerForKey("proximityDistance") == 0 {
                    self.defaults.setInteger(500, forKey: "proximityDistance")
                }
                
                for x in [Arret](AppValues.arrets.values) {
                    x.distance = location!.distanceFromLocation(x.location)

                    if (location!.distanceFromLocation(x.location) <= Double(self.defaults.integerForKey("proximityDistance"))) {
                        
                        self.arretsLocalisation.append(x)
                        print(x.stopCode)
                        print(String(location!.distanceFromLocation(x.location)))
                    }
                }
                self.arretsLocalisation.sortInPlace({ (arret1, arret2) -> Bool in
                    if arret1.distance < arret2.distance {
                        return true
                    }
                    else {
                        return false
                    }
                })
                self.tableView.reloadData()
                
                }, onFail: { (error) -> Void in
                    print("Erreur de localisation")
            })
        } catch (let error) {
            print("Error \(error)")
        }
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if !searchController.active {
            let cell = tableView.dequeueReusableCellWithIdentifier("arretsCell", forIndexPath: indexPath)
            if indexPath.section == 0 {
                let iconLocation = FAKFontAwesome.locationArrowIconWithSize(20)
                iconLocation.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor())
                cell.accessoryView = UIImageView(image: iconLocation.imageWithSize(CGSize(width: 20, height: 20)))
                cell.textLabel?.text = arretsLocalisation[indexPath.row].nomComplet
                cell.detailTextLabel!.text = "~" + String(Int(arretsLocalisation[indexPath.row].distance!)) + "m"
            }
            else if indexPath.section == 1 {
                let iconFavoris = FAKFontAwesome.starIconWithSize(20)
                iconFavoris.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor())
                cell.accessoryView = UIImageView(image: iconFavoris.imageWithSize(CGSize(width: 20, height: 20)))
                cell.textLabel?.text = AppValues.arretsFavoris[AppValues.nomCompletsFavoris[indexPath.row]]?.titre
                cell.detailTextLabel?.text = AppValues.arretsFavoris[AppValues.nomCompletsFavoris[indexPath.row]]?.sousTitre
            }
            else {
                let iconCheveron = FAKFontAwesome.chevronRightIconWithSize(15)
                iconCheveron.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor())
                cell.accessoryView = UIImageView(image: iconCheveron.imageWithSize(CGSize(width: 20, height: 20)))
                cell.textLabel?.text = AppValues.arrets[arretsKeys[indexPath.row]]!.titre
                cell.detailTextLabel!.text = AppValues.arrets[arretsKeys[indexPath.row]]!.sousTitre
            }
            
            let backgroundView = UIView()
            backgroundView.backgroundColor = UIColor.flatOrangeColorDark()
            cell.selectedBackgroundView = backgroundView
            
            return cell
            
        }
        else {
            let cell = tableView.dequeueReusableCellWithIdentifier("arretsCell", forIndexPath: indexPath)
            let iconCheveron = FAKFontAwesome.chevronRightIconWithSize(15)
            iconCheveron.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor())
            
            cell.textLabel?.text = filtredResults[indexPath.row].titre
            cell.detailTextLabel!.text = filtredResults[indexPath.row].sousTitre
            cell.accessoryView = UIImageView(image: iconCheveron.imageWithSize(CGSize(width: 20, height: 20)))
            
            return cell
        }
        
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "afficherProchainsDeparts") {
            let departsArretsViewController:DepartsArretTableViewController = (segue.destinationViewController) as! DepartsArretTableViewController
            if searchController.active {
                departsArretsViewController.arret = filtredResults[(tableView.indexPathForSelectedRow?.row)!]
            }
            else {
                if tableView.indexPathForSelectedRow!.section == 0 {
                    departsArretsViewController.arret = arretsLocalisation[tableView.indexPathForSelectedRow!.row]
                }
                else if tableView.indexPathForSelectedRow!.section == 1 {
                    departsArretsViewController.arret = AppValues.arretsFavoris[AppValues.nomCompletsFavoris[tableView.indexPathForSelectedRow!.row]]
                }
                else {
                    departsArretsViewController.arret = AppValues.arrets[self.arretsKeys[(tableView.indexPathForSelectedRow?.row)!]]
                }
            }
        }
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    func filterContentForSearchText(searchText: String) {
        filtredResults = [Arret](AppValues.arrets.values).filter { arret in
            return arret.nomComplet.lowercaseString.containsString(searchText.lowercaseString)
        }
        filtredResults.sortInPlace { (arret1, arret2) -> Bool in
            if arret1.nomComplet.lowercaseString < arret2.nomComplet.lowercaseString {
                return true
            }
            else {
                return false
            }
        }
        
        tableView.reloadData()
    }
}

extension ArretsTableViewController: UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}

extension ArretsTableViewController : UIViewControllerPreviewingDelegate {
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = tableView.indexPathForRowAtPoint(location) else { return nil }
        
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) else { return nil }
        
        guard let detailVC = storyboard?.instantiateViewControllerWithIdentifier("departsArretTableViewController") as? DepartsArretTableViewController else { return nil }
        
        if searchController.active {
            detailVC.arret = filtredResults[indexPath.row]
        }
        else {
            if indexPath.section == 0 {
                detailVC.arret = arretsLocalisation[indexPath.row]
            }
            else if indexPath.section == 1 {
                detailVC.arret = AppValues.arretsFavoris[AppValues.nomCompletsFavoris[indexPath.row]]
            }
            else {
                detailVC.arret = AppValues.arrets[self.arretsKeys[indexPath.row]]
            }
        }
        previewingContext.sourceRect = cell.frame
        return detailVC
    }

    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        
        showViewController(viewControllerToCommit, sender: self)
        
    }
}