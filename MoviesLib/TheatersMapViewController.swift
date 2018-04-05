//
//  TheatersMapViewController.swift
//  MoviesLib
//
//  Created by Usuário Convidado on 02/04/18.
//  Copyright © 2018 EricBrito. All rights reserved.
//

import UIKit
import MapKit

class TheatersMapViewController: UIViewController {

    //MARK: - Lets and Vars
    var currentElement: String!
    var theater: Theater!
    var theaters: [Theater] = []
    lazy var locationManager = CLLocationManager()
    var poiAnnotation: [MKPointAnnotation] = []
    
    //MARK: - IBOutlets
    @IBOutlet weak var mapView: MKMapView!
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        loadXML()
        requestUserLocationAuthorization()
    }

    //MARK: - Custom Methods
    func loadXML() {
        guard let xml = Bundle.main.url(forResource: "theaters", withExtension: "xml"), let xmlParser = XMLParser(contentsOf: xml) else {return}
        xmlParser.delegate = self
        xmlParser.parse()
    }
    
    func addTheaters() {
        for t in theaters {
            let coordinate = CLLocationCoordinate2D(latitude: t.latitude, longitude: t.longitude)
            let annotation = TheaterAnnotation(coordinate: coordinate, title: t.name, subtitle: t.url)
            self.mapView.addAnnotation(annotation)
        }
        
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    
    func requestUserLocationAuthorization() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
//            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = true
            
            switch CLLocationManager.authorizationStatus() {
            case .authorizedAlways, .authorizedWhenInUse:
                print("autorizado")
            case .denied:
                print("nao autorizado")
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .restricted:
                print("restrito")
            }
        }
    }
    
    func getRoute(destination: CLLocationCoordinate2D) {
        let request = MKDirectionsRequest()
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: locationManager.location!.coordinate))
        
        let directions = MKDirections(request: request)
        directions.calculate { (response, error) in
            if error == nil {
                guard let response = response else { return }
                let routes = response.routes.sorted(by: {$0.expectedTravelTime < $1.expectedTravelTime})
                guard let route = routes.first else { return }
                print("Nome da rota: \(route.name) - Distância: \(route.distance) - Duração: \(route.expectedTravelTime)")
                
                for step in route.steps {
                    print("Em \(step.distance), \(step.instructions)")
                }
                
                self.mapView.removeOverlays(self.mapView.overlays)
                self.mapView.add(route.polyline, level: .aboveRoads)
                self.mapView.showAnnotations(self.mapView.annotations, animated: true)
            }
        }
    }
    
    //MARK: - Memory Management
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }


}

//MARK: - XMLParserDelegate Methods
extension TheatersMapViewController : XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "Theater" {
            self.theater = Theater()
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let content = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !content.isEmpty {
            switch self.currentElement {
            case "name":
                self.theater.name = content
            case "address":
                self.theater.address = content
            case "latitude":
                self.theater.latitude = Double(content)!
            case "longitude":
                self.theater.longitude = Double(content)!
            case "url":
                self.theater.url = content
            default:
                break
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Theater" {
            self.theaters.append(self.theater)
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        addTheaters()
    }
}

//MARK: - MapView Delegate Methods
extension TheatersMapViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView: MKAnnotationView!
        
        if annotation is TheaterAnnotation {
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Theater")
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "Theater")
                annotationView.image = UIImage(named: "theaterIcon")
                annotationView.canShowCallout = true
                
                let btLeft = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
                btLeft.setImage(UIImage(named: "car"), for: .normal)
                annotationView.leftCalloutAccessoryView = btLeft
                
                let btRight = UIButton(type: .detailDisclosure)
                annotationView.rightCalloutAccessoryView = btRight
                
            }
            else {
                annotationView.annotation = annotation
            }
        }
        else if annotation is MKPointAnnotation {
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "POI")
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "POI")
                (annotationView as! MKPinAnnotationView).pinTintColor = .blue
                (annotationView as! MKPinAnnotationView).animatesDrop = true
                annotationView.canShowCallout = true
            }
            else {
                annotationView.annotation = annotation
            }
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.leftCalloutAccessoryView {
            self.getRoute(destination: view.annotation!.coordinate)
        }
        else {
            if let webVC = storyboard?.instantiateViewController(withIdentifier: "WebViewController") as? WebViewController {
                webVC.url = view.annotation!.subtitle!
                present(webVC, animated: true, completion: nil)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let camera = MKMapCamera()
        camera.pitch = 80
        camera.altitude = 100
        camera.centerCoordinate = view.annotation!.coordinate
        mapView.setCamera(camera, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
            renderer.fillColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
            return renderer
        }
        else {
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

//MARK: - CLLocation Delegate Methods
extension TheatersMapViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            mapView.showsUserLocation = true
        default:
            break
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("velocidade do usuario \(userLocation.location?.speed ?? 0)")
        let region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 500, 500)
        mapView.setRegion(region, animated: true)
    }
}

//MARK: - UISearchBar Delegate
extension TheatersMapViewController : UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBar.text!
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            if error == nil {
                guard let response = response else { return }
                self.mapView.removeAnnotations(self.poiAnnotation)
                for item in response.mapItems {
                    let place = MKPointAnnotation()
                    place.coordinate = item.placemark.coordinate
                    place.title = item.name
                    place.subtitle = item.phoneNumber
                    self.poiAnnotation.append(place)
                }
                self.mapView.addAnnotations(self.poiAnnotation)
            }
        }
    }
    
    
}
