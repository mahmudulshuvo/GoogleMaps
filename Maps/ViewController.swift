//
//  ViewController.swift
//  Maps
//
//  Created by SHUVO on 7/21/16.
//  Copyright © 2016 SHUVO. All rights reserved.
//

import UIKit
import GoogleMaps

class ViewController: UIViewController {
  

    @IBOutlet weak var bckView: UIView!
    var mapView: GMSMapView!
    var coordinates = [[String:AnyObject]]()
    var polylines = [AnyObject]()
    var duration = [AnyObject]()
    var routePolyline: GMSPolyline!
    var originCoordinate: CLLocationCoordinate2D!
    var timer: NSTimer!
    var counter: Int = 0
    var route: String = ""
    var dValue: String = ""
    var myStringArr = [String]()
    var time:Double = 0.0

    
    override func viewDidLoad() {
        super.viewDidLoad()
        let camera = GMSCameraPosition.cameraWithLatitude(23.747504, longitude: 90.369203, zoom: 15)
        mapView = GMSMapView.mapWithFrame(CGRectMake(0, 0, 600, 600), camera: camera)
        bckView.addSubview(mapView)
        bckView.sizeToFit()
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2DMake(23.747504, 90.369203)
        marker.title = "Pizza Hut"
        marker.snippet = "Dhanmondi"
        marker.map = mapView
        marker.icon = GMSMarker.markerImageWithColor(UIColor.greenColor())

    }
    
    
    @IBAction func btnAction(sender: AnyObject) {

        let baseUrl = "https://maps.googleapis.com/maps/api/directions/json?"+"origin="+"23.747504,90.369203"+"&destination="+"Mirpur"+"&mode=DRIVING"
        self.getDirection(baseUrl)
    }
    
    func getDirection(url : String) {

        let directionsURLString = url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        let directionsURL = NSURL(string: directionsURLString!)
        let directionsData = NSData(contentsOfURL: directionsURL!)
        do {
            if let json = try NSJSONSerialization.JSONObjectWithData(directionsData!, options: []) as? [String: AnyObject] {
                print("json data \(json)")
                if let status = json["status"] as? String {
                    if (status == "OK") {
                        if let routes = json["routes"] as AnyObject? as? [[String: AnyObject]] {
                            for r in routes {
                                if let legs = r["legs"] as? [[String: AnyObject]] {
                                    for l in legs {
                                        if let steps = l["steps"] as? [[String: AnyObject]] {
                                                for step in steps {
                                                    self.coordinates.append((step["end_location"] as? [String: AnyObject])!)
                                                    self.polylines.append((step["polyline"] as? [String: AnyObject])!)
                                                    self.duration.append((step["duration"] as? [String: AnyObject])!)
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
        
        if (self.counter < self.coordinates.count) {
            self.originCoordinate = CLLocationCoordinate2DMake(self.coordinates[counter]["lat"] as! Double, self.coordinates[counter]["lng"] as! Double)
            route = self.polylines[counter]["points"] as! String
            dValue = self.duration[counter]["text"] as! String
            myStringArr = dValue.componentsSeparatedByString(" ")
            time = Double(myStringArr[0])!
            time *= 60
            print("coordinates \(self.coordinates[counter]) and route \(route)")
            counter += 1
            self.timer = NSTimer.scheduledTimerWithTimeInterval(time, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)
        }
    }
    
    func update() {
        
        timer.invalidate()
        upDateMarker(self.originCoordinate)
        drawPolyline(route)
        if (self.counter < self.coordinates.count) {
            self.originCoordinate = CLLocationCoordinate2DMake(self.coordinates[counter]["lat"] as! Double, self.coordinates[counter]["lng"] as! Double)
            route = self.polylines[counter]["points"] as! String
            dValue = self.duration[counter]["text"] as! String
            myStringArr = dValue.componentsSeparatedByString(" ")
            time = Double(myStringArr[0])!
            time *= 60
            print("coordinates \(self.coordinates[counter]) and route \(route)")
            counter += 1
            self.timer = NSTimer.scheduledTimerWithTimeInterval(time, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)
        }
        
        else {
            timer.invalidate()
            counter = 0
        }
        
    }

    
    func upDateMarker(coordinates : CLLocationCoordinate2D)  {
        var originMarker: GMSMarker!
         mapView.camera = GMSCameraPosition.cameraWithTarget(originCoordinate, zoom: 15.0)
        originMarker = GMSMarker(position: self.originCoordinate)
        originMarker.map = self.mapView
        originMarker.icon = GMSMarker.markerImageWithColor(UIColor.redColor())
    }
    
    func  drawPolyline(route : String) {
        
        let path: GMSPath = GMSPath(fromEncodedPath: route)!
        self.routePolyline = GMSPolyline(path: path)
        routePolyline.strokeWidth = 5.0
        routePolyline.geodesic = true
        routePolyline.strokeColor = UIColor.blueColor()
        self.routePolyline.map = self.mapView
        
    }
    
}


