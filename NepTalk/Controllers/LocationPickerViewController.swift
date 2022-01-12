//
//  LocationPickerViewController.swift
//  NepTalk
//
//  Created by Kshitiz Bista on 2022-01-09.
//

import UIKit
import CoreLocation
import MapKit

class LocationPickerViewController: UIViewController {
    
    public var completion: ((CLLocationCoordinate2D) -> Void)?
    private var coordinates: CLLocationCoordinate2D?
    private var isPickable = true
    
    private let map: MKMapView = {
        let map = MKMapView()
        return map
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    init(coordinates: CLLocationCoordinate2D? = nil) {
        self.coordinates = coordinates
        isPickable = false
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        if isPickable {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(sendButtonTapped))
            map.isUserInteractionEnabled = true
            let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapMap))
            gesture.numberOfTouchesRequired = 1
            gesture.numberOfTouchesRequired = 1
            map.addGestureRecognizer(gesture)
        } else {
            guard let coordinates = coordinates else {
                return
            }
            let pin = MKPointAnnotation()
            pin.coordinate = coordinates
            map.addAnnotation(pin)
        }
        tabBarController?.tabBar.isHidden = true
        view.addSubview(map)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
    }
    
    @objc private func sendButtonTapped() {
        guard let coordinates = coordinates else {
            return
        }
        navigationController?.popViewController(animated: true)
        completion?(coordinates)
    }
    
    @objc private func didTapMap(_ gesture: UITapGestureRecognizer) {
        let locationInView = gesture.location(in: map)
        coordinates = map.convert(locationInView, toCoordinateFrom: map)
        map.annotations.forEach { annotation in
            map.removeAnnotation(annotation)
        }
        // drop pin on that location
        let pin = MKPointAnnotation()
        pin.coordinate = coordinates!
        map.addAnnotation(pin)
    }
}
