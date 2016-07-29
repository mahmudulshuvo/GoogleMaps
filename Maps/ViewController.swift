//
//  ViewController.swift
//  Maps
//
//  Created by SHUVO on 7/21/16.
//  Copyright © 2016 SHUVO. All rights reserved.
//

import UIKit
import GoogleMaps

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GMSMapViewDelegate{
    
    @IBOutlet weak var bckView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var overviewPolyline: Dictionary<NSObject, AnyObject>!
    var selectedRoute: Dictionary<NSObject, AnyObject>!
    var originCoordinate: CLLocationCoordinate2D!
    var destinationCoordinate: CLLocationCoordinate2D!
    var originAddress: String!
    var destinationAddress: String!
    var originMarker: GMSMarker!
    var destinationMarker: GMSMarker!
    var routePolyline: GMSPolyline!
    var mapView: GMSMapView!
    var itemArray = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = UIColor.clearColor()
        
        let camera = GMSCameraPosition.cameraWithLatitude(23.812615,
                                                          longitude: 90.413820,
                                                          zoom: 15)
        
        mapView = GMSMapView.mapWithFrame(CGRectMake(0, 0, 400, 400), camera: camera)
        mapView.myLocationEnabled = true
        mapView.delegate = self
        bckView.addSubview(mapView)
        
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2DMake(23.812615, 90.413820)
        marker.title = "Dhaka"
        marker.snippet = "Bangladesh"
        marker.map = mapView
       // mapView.animateToViewingAngle(80)
    }
    
    
    
    //For table view
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return itemArray.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let myCell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        myCell.textLabel!.font = UIFont(name:"Arial", size:16)
        myCell.textLabel?.numberOfLines = 3
        myCell.textLabel?.text = itemArray[indexPath.row];
        myCell.textLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
        myCell.textLabel?.sizeToFit()
        return myCell;
    }
    
    func updateTable() {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableView.reloadData()
        })
    }
    
    
    @IBAction func btnAction(sender: AnyObject) {
        
        let alert = UIAlertController(title: "Create Route", message: "Connect locations with a route:", preferredStyle: UIAlertControllerStyle.Alert)
        
                alert.addTextFieldWithConfigurationHandler { (textField) -> Void in
                    textField.placeholder = "Origin?"
                }
        
                alert.addTextFieldWithConfigurationHandler { (textField) -> Void in
                    textField.placeholder = "Destination?"
        
                }
        
        
        let createRouteAction = UIAlertAction(title: "Create Route", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
            
            let originText = (alert.textFields![0] as UITextField).text! as String
            let destinationText = (alert.textFields![1] as UITextField).text! as String
            let baseUrl = "https://maps.googleapis.com/maps/api/directions/json?"+"origin="+originText+"&destination="+destinationText+"&mode=driving"
            self.getDirection(baseUrl)
            
            print("on create root")
        }
        
        let closeAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.Cancel) { (alertAction) -> Void in
            print("on closing btn")
            
        }
        
        alert.addAction(createRouteAction)
        alert.addAction(closeAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }

    
    func getDirection(url : String) {
        
       // print(url)
      //  clearRoute()
        itemArray = [String]()
        let directionsURLString = url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        let directionsURL = NSURL(string: directionsURLString!)
        let directionsData = NSData(contentsOfURL: directionsURL!)
        do {
            if let json = try NSJSONSerialization.JSONObjectWithData(directionsData!, options: []) as? [String: AnyObject] {
                if let status = json["status"] as? String {
                    if (status == "OK") {
                        if let routes = json["routes"] as AnyObject? as? [[String: AnyObject]] {
                        //    var counter:Int = 0
                            for r in routes {
                              //  if (counter == 0) {
                                    self.overviewPolyline = r["overview_polyline"] as? [String: AnyObject]
                             //       counter += 1
                           ///     }
                                if let legs = r["legs"] as? [[String: AnyObject]] {
                                    let startLocationDictionary = legs[0]["start_location"] as? [String: AnyObject]
                                    self.originCoordinate = CLLocationCoordinate2DMake(startLocationDictionary!["lat"] as! Double, startLocationDictionary!["lng"] as! Double)
                                    let endLocationDictionary = legs[legs.count - 1]["end_location"] as? [String: AnyObject]
                                    self.destinationCoordinate = CLLocationCoordinate2DMake(endLocationDictionary!["lat"] as! Double, endLocationDictionary!["lng"] as! Double)
                                    for l in legs {
                                        if let steps = l["steps"] as? [[String: AnyObject]] {
                                    //        if (counter == 1) {
                                                for step in steps {
                                                    let distance = step["distance"] as? [String: AnyObject]
                                                    let str = (step["html_instructions"] as! String).stringByReplacingOccurrencesOfString("<[^>]+>", withString: "", options: .RegularExpressionSearch, range: nil)
                                                    let finalString = str+""+" "+""+(distance!["text"] as! String)
                                                    itemArray.append(finalString)
                                   //             }
                                        //       counter += 1
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        catch _ {
            print("error")
        }
        
        configureMapAndMarkersForRoute()
        drawRoute()
        updateTable()
    }
    
    func clearRoute() {
     //   mapView = GMSMapView()
        self.originMarker = nil
        self.destinationMarker = nil
        self.routePolyline = nil
    }
    
    func drawRoute()  {
        
        let route = self.overviewPolyline["points"] as! String
        let path: GMSPath = GMSPath(fromEncodedPath: route)!
        self.routePolyline = GMSPolyline(path: path)
        routePolyline.strokeWidth = 5.0
        routePolyline.geodesic = true
        routePolyline.strokeColor = UIColor.blueColor()
        self.routePolyline.map = self.mapView
    }
    
    func configureMapAndMarkersForRoute() {
        clearRoute()
        mapView.camera = GMSCameraPosition.cameraWithTarget(originCoordinate, zoom: 15.0)
        
        originMarker = GMSMarker(position: self.originCoordinate)
        originMarker.map = self.mapView
        originMarker.icon = GMSMarker.markerImageWithColor(UIColor.greenColor())
        originMarker.title = self.originAddress
        
        destinationMarker = GMSMarker(position: self.destinationCoordinate)
        destinationMarker.map = self.mapView
        destinationMarker.icon = GMSMarker.markerImageWithColor(UIColor.redColor())
        destinationMarker.title = self.destinationAddress
     //   mapView.animateToViewingAngle(80)
        
    }
}



