
import UIKit
import MapKit
import GoogleMaps
import SafariServices

class ViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate, UITextViewDelegate {
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var userButton: UIButton!
    @IBOutlet weak var categoryButton: UIButton!
    @IBOutlet weak var sourceTextView: UITextView!
    @IBOutlet weak var descriptionLabel: UITextView!
    @IBOutlet weak var addressTextView: UITextView!
    @IBOutlet weak var phoneTextView: UITextView!
    @IBOutlet weak var websiteTextView: UITextView!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var categorySelector: UISegmentedControl!
    @IBOutlet weak var infoViewTop: NSLayoutConstraint!
    @IBOutlet weak var mapViewBottom: NSLayoutConstraint!
    
    var SelectorOffset: CGFloat = 77
    var activeViewHeight: CGFloat = 0
    var selectedCategory: Int = 0
    
    let category: Array<String> = [
        NSLocalizedString("None", comment: ""),
        NSLocalizedString("Childcare", comment: ""),
        NSLocalizedString("Community Centre", comment: ""),
        NSLocalizedString("Cultural Sites", comment: ""),
        NSLocalizedString("Dentist", comment: ""),
        NSLocalizedString("Doctors Surgery", comment: ""),
        NSLocalizedString("Education", comment: ""),
        NSLocalizedString("Health", comment: ""),
        NSLocalizedString("Hospital / A&E", comment: ""),
        NSLocalizedString("Library", comment: ""),
        NSLocalizedString("Practical Life", comment: ""),
        NSLocalizedString("Transport", comment: ""),
        NSLocalizedString("Creative", comment: ""),
        NSLocalizedString("Sports/Exercise", comment: ""),
        NSLocalizedString("Social", comment: ""),
        NSLocalizedString("Other", comment: "")
    ]
    
    struct PinStatus {
        var email: String?
        var hide: Bool?
    }
    
    var username: String?
    var password: String?
    
    var pins: [Pin]!
    var userData: UserData!
    var hidePinDict: [String: Bool] = [:]
    var emailList: [String]?
    var user = true
    
    var tapGestureRecognizer:UITapGestureRecognizer!
    var locationManager: CLLocationManager!
    var client: DatabaseClient!
    var editMarker: GMSMarker!
    
    var newPin: Pin!
 
    func mapView(_ mapView: GMSMapView, didTapAt: CLLocationCoordinate2D) {
        clearDetails()
        slideDown()
    }
    
    func clearDetails() {
        sourceTextView.text = ""
        descriptionLabel.text = ""
        addressTextView.text = ""
        phoneTextView.text = ""
        websiteTextView.text = ""
        notesTextView.text = ""
    }
    
    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        let marker = GMSMarker()
        marker.position = coordinate
        marker.title = NSLocalizedString("Add Pin?", comment: "")
        marker.map = mapView
        
        let alert = UIAlertController(title: NSLocalizedString("Add Pin here?", comment: ""), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .cancel, handler: { action in
            marker.map = nil
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { action in
            self.selectCategory(0) { category in
                self.addNewPin(coordinate, pin: nil, category: category)
                marker.map = nil
            }
        }))
        self.present(alert, animated: true)
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        slideUp()
        if UIApplication.shared.canOpenURL(URL(string:"http://")!) {
            if #available(iOS 10.0, *) {
                let data = marker.userData as? Pin
                if data != nil {
                    var address: String = ""
                    var tmp = data?.address_line_1
                    if tmp?.count ?? 0 > 0 {
                        address = tmp!
                    }
                    tmp = data?.address_line_2
                    if tmp?.count ?? 0 > 0 {
                        if address.count > 0 {
                            address += ", "
                        }
                        address += tmp!
                    }
                    tmp = data?.postcode
                    if tmp?.count ?? 0 > 0 {
                        if address.count > 0 {
                            address += ", "
                        }
                        address += tmp!
                    }
                    addressTextView.text = address + "\n"
                    let website = data?.website
                    if website?.count ?? 0 > 0 {
                        websiteTextView.text = website
                    }
                    let phone = data?.phone
                    if phone?.count ?? 0 > 0 {
                        phoneTextView.text = phone
                    }
                    let description = data?.description
                    if description?.count ?? 0 > 0 {
                        descriptionLabel.text = description
                        descriptionLabel.isHidden = false
                    } else {
                        descriptionLabel.isHidden = true
                    }
                    if !(data?.userPin ?? true) {
                        let source = data?.training_centre_email
                        if source?.count ?? 0 > 0 {
                            let centre = userData.traingingCentres?.first(where: {$0.email == source})
                            if centre != nil {
                                sourceTextView.text = centre?.name?.first ?? ""
                                if sourceTextView.text.count > 0 {
                                    sourceTextView.text.append(" ")
                                }
                                sourceTextView.text.append(centre?.name?.last ?? "")
                            } else {
                                sourceTextView.text = source
                            }
                        } else {
                            sourceTextView.text = source
                        }
                        sourceTextView.isHidden = false
                    } else {
                        sourceTextView.isHidden = true
                    }
                    let notes = data?.notes
                    if notes?.count ?? 0 > 0 {
                        notesTextView.text = notes
                    }
                }
            } else {
                // Fallback on earlier versions
            }
        }
        return false
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        let alert = UIAlertController(title: NSLocalizedString("Pin Actions", comment:""), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment:""), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Directions", comment:""), style: .default, handler: {action in
            self.directions(marker: marker)
        }))
        
        let pin = marker.userData as! Pin
        if (pin.userPin ?? true) || !self.user {
            alert.addAction(UIAlertAction(title: NSLocalizedString("Edit", comment:""), style: .default, handler: {action in
                self.editMarker = marker
                self.selectCategory(pin.category ?? 0) { category in
                    self.addNewPin(CLLocationCoordinate2D(latitude: pin.latitude ?? 0, longitude: pin.longitude ?? 0), pin:pin, category: category)
                }
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment:""), style: .destructive, handler: {action in
                let alert = UIAlertController(title: NSLocalizedString("Delete pin?", comment:""), message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment:""), style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: NSLocalizedString("DELETE", comment:""), style: .destructive, handler: {action in
                    marker.map = nil
                    if pin.id != nil {
                        self.client.deletePin(pin.id!) { result in
                            self.pins.removeAll(where: {$0.id == pin.id})
                            self.savePinData()
                        }
                    }
                }))
                self.present(alert, animated: true)
            }))
        }
        self.present(alert, animated: true)
    }
    
    func directions(marker: GMSMarker) {
        var latitude = 50.793740
        var longitude = -1.106184
        var name = ""
        let data = marker.userData as? Pin
        if data != nil {
            latitude = data?.latitude ?? 0
            longitude = data?.longitude ?? 0
            name = data?.name ?? ""
        }
        
        // open in google map app
        if UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(URL(string: "comgooglemaps://?saddr=&daddr=\(latitude),\(longitude)&directionsmode=transit")!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]),
completionHandler: nil)
            } else {
                // Fallback on earlier versions
                UIApplication.shared.openURL(NSURL(string:"comgooglemaps://?saddr=&daddr=\(latitude),\(longitude)&directionsmode=transit")! as URL)
            }
        } else { // open in apple map
            let coordinate = CLLocationCoordinate2DMake(latitude, longitude)
            let region = MKCoordinateRegion.init(center: coordinate, span: MKCoordinateSpan.init(latitudeDelta: 0.01, longitudeDelta: 0.02))
            let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = name
            if #available(iOS 9.0, *) {
                let options = [
                    MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: region.center),
                    MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: region.span),
                    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeTransit] as [String : Any]
                mapItem.openInMaps(launchOptions: options)
            } else {
                // Fallback on earlier versions
                let options = [
                    MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: region.center),
                    MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: region.span)]
                mapItem.openInMaps(launchOptions: options)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation = locations.last
        let camera = GMSCameraPosition.camera(withLatitude: userLocation!.coordinate.latitude,
                                              longitude: userLocation!.coordinate.longitude, zoom: 14.0)
        mapView.camera = camera
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        
        locationManager.stopUpdatingLocation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
  override func loadView() {
    super.loadView()
    
    client = DatabaseClient(viewController: self)
    loadUserDatafile()
    loadCentres()
    
    locationManager = CLLocationManager()
    locationManager.delegate = self
    locationManager.requestWhenInUseAuthorization()
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.startUpdatingLocation()
    
    let camera = GMSCameraPosition.camera(withLatitude: 50.793740, longitude: -1.106184, zoom: 14.0)
    mapView.camera = camera
    mapView.bringSubviewToFront(logoutButton)
    logoutButton.isHidden = true
    mapView.bringSubviewToFront(userButton)
    userButton.isHidden = true
    mapView.bringSubviewToFront(infoView)
    mapView.settings.myLocationButton = false
    mapView.isMyLocationEnabled = false
    mapView.delegate = self
    
    clearDetails()
    websiteTextView.delegate = self
    
    let tap = UITapGestureRecognizer(target: self, action: #selector(tapFunction))
    addressTextView.addGestureRecognizer(tap)
    
    setCategoryButtonTitle()
    
    view.isUserInteractionEnabled = false
    view.alpha = 0.3
  }
    
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        let safariVC = SFSafariViewController(url: URL)
        present(safariVC, animated: true, completion: nil)
        return false
    }
 
    @objc func handleCategoryChanged() {
        setCategoryButtonTitle()
        mapView.clear()
        addMarkers()
        
        clearDetails()
        slideDown()
    }

    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(true)
        
        if activeViewHeight == 0 {
            self.infoViewTop.constant = 0
            activeViewHeight = self.mapView.frame.height+self.mapView.frame.minY+55
            
            if #available(iOS 11.0, *) {
                SelectorOffset += view.safeAreaInsets.bottom
            }
            
            self.mapViewBottom.constant = SelectorOffset - self.mapView.frame.minY
        }
        
        login()
        
        clearDetails()
        slideDown()
       }
    
    @IBAction func logoutButtonPressed(_ sender: Any) {
        view.isUserInteractionEnabled = false
        self.userButton.isHidden = true
        view.alpha = 0.3
        if password != nil {
            self.password = ""
            self.saveUserDatafile()
        }
        login()
    }
    
    @IBAction func userButtonPressed(_ sender: Any) {
        if self.userData.role == "recruiter" {
            self.client.getCentreUsers() { result in
                if result != nil {
                    self.emailList = result
                    self.performSegue(withIdentifier: "seguePresentUserView", sender: self)
                } else {
                    let alert = UIAlertController(title: NSLocalizedString("User data", comment:""), message: NSLocalizedString("Couldn't get data, please try again.", comment:""), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment:""), style: .default, handler: { action in
                    }))
                    self.present(alert, animated: true)
                }
            }
        } else {
            self.client.getUserCentres() { result in
                if result != nil {
                    let tempCentres = (result! as [TrainingCentre]?)
                    self.checkForNewCentres(tempCentres)
                    self.userData.traingingCentres = result
                    self.saveCentres()
                    self.performSegue(withIdentifier: "seguePresentUserView", sender: nil)
                } else {
                    let alert = UIAlertController(title: NSLocalizedString("User data", comment:""), message: NSLocalizedString("Couldn't get data, please try again.", comment:""), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment:""), style: .default, handler: { action in
                    }))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    @IBAction func categoryButtonPressed(_ sender: Any) {
        self.selectCategory(selectedCategory, edit: false) { category in
            self.selectedCategory = category
            self.handleCategoryChanged()
        }
    }
    
    func setCategoryButtonTitle() {
        if selectedCategory == 0 {
            categoryButton.setTitle(NSLocalizedString("All Pins", comment:""), for: .normal)
        } else {
            categoryButton.setTitle(category[selectedCategory], for: .normal)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == "seguePresentUserView" {
            let destinationVC = segue.destination as! UserTableViewController
            destinationVC.client = self.client
            destinationVC.userData = self.userData
            if self.userData.role == "recruiter" {
                destinationVC.emailList = self.emailList
            }
        }
    }
    
    func refreshPins() {
        self.client.getPins() { result in
            if result != nil {
                self.pins = result
                self.savePinData()
                self.handleCategoryChanged()
            } else {
                let alert = UIAlertController(title: NSLocalizedString("User data", comment:""), message: NSLocalizedString("Couldn't update data.", comment:""), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment:""), style: .default, handler: { action in
                }))
                self.present(alert, animated: true)
            }
        }
    }
    
    func checkForNewCentres(_ tempCentres: [TrainingCentre]?) {
        //check for changes
        var newCentreList = ""
        for centre in tempCentres! {
            if self.userData.traingingCentres?.first(where: {$0.email == centre.email}) == nil {
                if centre.name?.first?.count ?? 0 > 0 {
                    newCentreList += (centre.name?.first)!
                }
                if centre.name?.last?.count ?? 0 > 0 {
                    newCentreList += " " + (centre.name?.last)! + "\n"
                }
            }
        }
        if newCentreList.count > 0 {
            let alert = UIAlertController(title: NSLocalizedString("New Centre", comment:""), message: NSLocalizedString("You have been added to:", comment:"")+"\n"+newCentreList, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment:""), style: .default, handler: { action in
            }))
            self.present(alert, animated: true)
        }
    }
    
    func login() {
        client.login(username: username, password: password) {
            result in
            if result != nil {
                self.view.isUserInteractionEnabled = true
                self.view.alpha = 1.0
                self.userButton.isHidden = false
                if self.userData == nil {
                    self.userData = result // update
                } else {
                    self.userData.role = (result! as UserData).role
                }
                if self.userData.role == "recruiter" {
                    self.user = false
                    self.userButton.setTitle(NSLocalizedString("Users", comment:""), for: .normal)
                    self.userData = result // update
                } else {
                    self.user = true
                    self.userButton.setTitle(NSLocalizedString("Centres", comment:""), for: .normal)
                    self.client.getUserCentres() { result in
                       if result != nil {
                        let tempCentres = (result! as [TrainingCentre]?)
                        self.checkForNewCentres(tempCentres)
                        self.userData.traingingCentres = result
                        self.saveCentres()
                       }
                    }
                }
                self.username = self.client.username
                self.password = self.client.password
                self.saveUserDatafile()
                self.loadHideDict()
                self.logoutButton.setTitle(NSLocalizedString("Logout", comment:""), for: .normal)
                self.logoutButton.isHidden = false
                self.requestPinData()
            } else {
                self.password = nil
                let alert = UIAlertController(title: NSLocalizedString("Login", comment:""), message: NSLocalizedString("Login not recognised, please try again.", comment:""), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment:""), style: .cancel, handler: { action in
                    self.view.isUserInteractionEnabled = true
                    self.view.alpha = 1.0
                    self.loadPinData()
                    self.addMarkers()
                    self.logoutButton.setTitle(NSLocalizedString("Login", comment:""), for: .normal)
                    self.logoutButton.isHidden = false
                }))
                alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment:""), style: .default, handler: { action in
                    self.login()
                }))
                self.present(alert, animated: true)
            }
        }
    }
    
    
    func requestPinData() {
        client.getPins() {
            result in
            if result != nil {
                self.pins = result
                self.addMarkers()
                self.savePinData()
            } else {
                self.password = nil
                let alert = UIAlertController(title: NSLocalizedString("Pin data", comment:""), message: NSLocalizedString("Couldn't get data, please try again.", comment:""), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment:""), style: .cancel, handler: { action in
                }))
                alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment:""), style: .default, handler: { action in
                    self.requestPinData()
                }))
                self.present(alert, animated: true)
            }
        }
    }
    
    func addMarkers() {
        let cat = selectedCategory
        var color = UInt32()
        switch cat {
        case 1:
            color = 0xe01d1d
        case 2:
            color = 0xe05e1d
        case 3:
            color = 0xe0c01d
        case 4:
            color = 0xace01d
        case 5:
            color = 0x4ee01d
        case 6:
            color = 0x1de06e
        case 7:
            color = 0x1de0c0
        case 8:
            color = 0x1d9fe0
        case 9:
            color = 0x1d34e0
        case 10:
            color = 0x6b1de0
        case 11:
            color = 0xb31de0
        case 12:
            color = 0xe01db3
        default:
            color = 0xffffff
        }
        
        if pins != nil {
            for pin in pins {
                addMarker(pin, cat: cat)
            }
        }
    }
    
    func addMarker(_ pin: Pin, cat: Int) {
        if pin.latitude != 0 && pin.longitude != 0 && (cat == 0 || cat == pin.category)  {

            let source = pin.training_centre_email
            if source?.count ?? 0 > 0 {
                if hidePinDict[source!] == true {
                    return
                }
            }
                    
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: pin.latitude ?? 0, longitude: pin.longitude ?? 0)
            marker.title = pin.name
            marker.userData = pin
            switch pin.category {
            case 1: //Childcare
                marker.icon = GMSMarker.markerImage(with: UIColor(hex: 0xe01d1d, alpha: 1.0))
            case 2: //Community Centre
                marker.icon = GMSMarker.markerImage(with: UIColor(hex: 0xe05e1d, alpha: 1.0))
            case 3: //Cultural sites
                marker.icon = GMSMarker.markerImage(with: UIColor(hex: 0xe0c01d, alpha: 1.0))
            case 4: //Dentist
                marker.icon = GMSMarker.markerImage(with: UIColor(hex: 0xace01d, alpha: 1.0))
            case 5: //Doctors Surgery
                marker.icon = GMSMarker.markerImage(with: UIColor(hex: 0x4ee01d, alpha: 1.0))
            case 6: //Education
                marker.icon = GMSMarker.markerImage(with: UIColor(hex: 0x1de06e, alpha: 1.0))
            case 7: //Health
                marker.icon = GMSMarker.markerImage(with: UIColor(hex: 0x1de0c0, alpha: 1.0))
            case 8: //Hospital / A&E
                marker.icon = GMSMarker.markerImage(with: UIColor(hex: 0x1d9fe0, alpha: 1.0))
            case 9: //Library
                marker.icon = GMSMarker.markerImage(with: UIColor(hex: 0x1d34e0, alpha: 1.0))
            case 10: //Practical Life
                marker.icon = GMSMarker.markerImage(with: UIColor(hex: 0x6b1de0, alpha: 1.0))
            case 11: //Transport
                marker.icon = GMSMarker.markerImage(with: UIColor(hex: 0xb31de0, alpha: 1.0))
            case 12: //Other
                marker.icon = GMSMarker.markerImage(with: UIColor(hex: 0xe01db3, alpha: 1.0))
            default:
                marker.icon = GMSMarker.markerImage(with: UIColor.black)
            }
            marker.map = mapView
        }
    }
    
    @objc func tapFunction() {
        var latitude = 50.796101
        var longitude = -1.0931
        var name = ""
        
        let data = mapView.selectedMarker?.userData as? Pin
        if data != nil {
            latitude = data?.latitude ?? 0
            longitude = data?.longitude ?? 0
            name = data?.name ?? ""
        }
        
        // open in google map app
        if UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(URL(string: "comgooglemaps://?saddr=&daddr=\(latitude),\(longitude)&directionsmode=transit")!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]),
                                          completionHandler: nil)
            } else {
                // Fallback on earlier versions
                UIApplication.shared.openURL(NSURL(string:"comgooglemaps://?saddr=&daddr=\(latitude),\(longitude)&directionsmode=transit")! as URL)
            }
        } else { // open in apple map
            let coordinate = CLLocationCoordinate2DMake(latitude, longitude)
            let region = MKCoordinateRegion.init(center: coordinate, span: MKCoordinateSpan.init(latitudeDelta: 0.01, longitudeDelta: 0.02))
            let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = name
            if #available(iOS 9.0, *) {
                let options = [
                    MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: region.center),
                    MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: region.span),
                    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeTransit] as [String : Any]
                mapItem.openInMaps(launchOptions: options)
            } else {
                // Fallback on earlier versions
                let options = [
                    MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: region.center),
                    MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: region.span)]
                mapItem.openInMaps(launchOptions: options)
            }
        }
    }
    
    func slideUp() {
        if self.infoViewTop.constant >= 0 {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                self.infoViewTop.constant = -160
                var infoViewFrame = self.infoView.frame
                infoViewFrame.origin.y = self.activeViewHeight-270
                self.infoView.frame = infoViewFrame
            }, completion: { finished in
            })
        }
    }
    func slideDown() {
        if self.infoViewTop.constant < 0 {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                self.infoViewTop.constant = 0
                var infoViewFrame = self.infoView.frame
                infoViewFrame.origin.y = self.activeViewHeight-40
                self.infoView.frame = infoViewFrame
            }, completion: { finished in
            })
        }
    }
    
    func addNewPin(_ coordinate: CLLocationCoordinate2D, pin: Pin?, category: Int) {
        let alert = UIAlertController(title: NSLocalizedString("Add Pin", comment:""), message: nil, preferredStyle: .alert)
        var actionName = NSLocalizedString("Add", comment:"")
        
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = NSLocalizedString("Name", comment:"")
            textField.keyboardType = .alphabet
        })
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = NSLocalizedString("Description", comment:"")
            textField.keyboardType = .alphabet
        })
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = NSLocalizedString("Phone", comment:"")
            textField.keyboardType = .phonePad
        })
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = NSLocalizedString("Website", comment:"")
            textField.keyboardType = .URL
        })
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = NSLocalizedString("Email", comment:"")
            textField.keyboardType = .emailAddress
        })
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = NSLocalizedString("Address line 1", comment:"")
            textField.keyboardType = .asciiCapable
        })
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = NSLocalizedString("Address line 2", comment:"")
            textField.keyboardType = .asciiCapable
        })
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = NSLocalizedString("Postcode", comment:"")
            textField.keyboardType = .asciiCapable
        })
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = NSLocalizedString("Notes", comment:"")
            textField.keyboardType = .alphabet
        })
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment:""), style: .cancel, handler: nil))
        if pin != nil {
            alert.title = NSLocalizedString("Edit Pin", comment:"")
            actionName = NSLocalizedString("Update", comment:"")
            alert.textFields![0].text = pin?.name
            alert.textFields![1].text = pin?.description
            alert.textFields![2].text = pin?.phone
            alert.textFields![3].text = pin?.website
            alert.textFields![4].text = pin?.email
            alert.textFields![5].text = pin?.address_line_1
            alert.textFields![6].text = pin?.address_line_2
            alert.textFields![7].text = pin?.postcode
            alert.textFields![8].text = pin?.notes
        }
        alert.addAction(UIAlertAction(title: actionName, style: .default, handler: { action in
            
            self.newPin = Pin(
                name: alert.textFields?.first?.text ?? "",
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                category: category,
                description: alert.textFields![1].text ?? "",
                phone: alert.textFields![2].text ?? "",
                website: alert.textFields![3].text ?? "",
                email: alert.textFields![4].text ?? "",
                address_line_1: alert.textFields![5].text ?? "",
                address_line_2: alert.textFields![6].text ?? "",
                postcode: alert.textFields![7].text ?? "",
                notes: alert.textFields![8].text ?? ""
            )
            if pin != nil && pin?.id != nil {
                self.newPin.id = pin!.id
            } else {
                self.newPin.id = -1
            }
            if actionName == NSLocalizedString("Update", comment:"") {
                self.editMarker.userData = self.newPin
                let index = self.pins.firstIndex(where: {$0.name == pin?.name})
                if index != nil {
                    self.pins[index!] = self.newPin
                }
                self.slideDown()
                self.mapView.clear()
                self.addMarkers()
            } else {
                self.pins.append(self.newPin)
            }

            self.savePinData()
            self.handleCategoryChanged()
            self.postNewPin()
        }))
        self.present(alert, animated: true)
    }
    
    func postNewPin() {
        self.client.postPin(self.newPin) {
               result in
            if (result == nil) {
                let alert = UIAlertController(title: NSLocalizedString("Error", comment:""), message: NSLocalizedString("Failed to post, try again", comment:""), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment:""), style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: NSLocalizedString("Retry", comment:""), style: .default, handler: {action in
                    self.postNewPin()
                }))
                self.present(alert, animated: true)
            } else {
                self.addMarker(self.newPin, cat:
                                self.selectedCategory + 1)
            }
        }
    }
    
    func selectCategory(_ current: Int, edit: Bool = true, completion:  @escaping (Int) -> Void) {
        let alert = UIAlertController(title: NSLocalizedString("Select Pin Category", comment:""), message: nil, preferredStyle: .alert)

        if !edit {
            let action = UIAlertAction(title: NSLocalizedString("All Pins", comment:""), style: .default, handler: {action in
                completion(0)
            })
            if current == 0 {
                action.titleTextColor = .red
            }
            alert.addAction(action)
        } else
        if current != 0 {
            let action = UIAlertAction(title: NSLocalizedString("Keep Current", comment:""), style: .default, handler: {action in
                completion(current)
            })
            action.titleTextColor = .red
            alert.addAction(action)
        }
        
        for i in 1...category.count-1 {
            let action = UIAlertAction(title: self.category[i], style: .default, handler: {action in
                completion(i)
            })
            if i == current {
                action.titleTextColor = .red
            }
            alert.addAction(action)
        }
        
        self.present(alert, animated: true)
    }
    
    
    //files
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func loadUserDatafile() {
        let filename = self.getDocumentsDirectory().appendingPathComponent("user.dat")
        do {
            let data = try String(contentsOf: filename)
            let array = data.components(separatedBy: ",")
            self.username = array.first
            self.password = array.last
        } catch {
            debugPrint("No user file")
        }
    }
    
    func saveUserDatafile() {
        let filename = self.getDocumentsDirectory().appendingPathComponent("user.dat")
        let string = self.username!+","+self.password!

        do {
            try string.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
        } catch {
        }
    }
    
    func savePinData() {
        let filename = self.getDocumentsDirectory().appendingPathComponent("pins.dat")
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self.pins) {
            do {
                try encoded.write(to: filename)
            } catch {
            }
        }
    }
    
    func loadPinData() {
        let filename = self.getDocumentsDirectory().appendingPathComponent("pins.dat")
        let data = NSData(contentsOf: filename)
        if data != nil {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([Pin].self, from: data! as Data)
            {
                self.pins = decoded
            }
        }
    }
    
    func saveCentres() {
        let filename = self.getDocumentsDirectory().appendingPathComponent("centres.dat")
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self.userData) {
            do {
                try encoded.write(to: filename)
            } catch {
            }
        }
    }
    
    func loadCentres() {
        let filename = self.getDocumentsDirectory().appendingPathComponent("centres.dat")
        let data = NSData(contentsOf: filename)
        if data != nil {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode(UserData.self, from: data! as Data)
            {
                self.userData = decoded
            }
        }
    }
    
    func saveHideDict() {
        let filename = self.getDocumentsDirectory().appendingPathComponent("hide.dat")
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self.hidePinDict) {
            do {
                try encoded.write(to: filename)
            } catch {
            }
        }
    }
    
    func loadHideDict() {
        let filename = self.getDocumentsDirectory().appendingPathComponent("hide.dat")
        let data = NSData(contentsOf: filename)
        if data != nil {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([String: Bool].self, from: data! as Data)
            {
                self.hidePinDict = decoded
            }
        }
    }
}


fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}

extension UIAlertAction {
    var titleTextColor: UIColor? {
        get {
            return self.value(forKey: "titleTextColor") as? UIColor
        } set {
            self.setValue(newValue, forKey: "titleTextColor")
        }
    }
}

extension UIColor {

    convenience init(hex: UInt32, alpha: CGFloat) {
        let red = CGFloat((hex & 0xFF0000) >> 16)/256.0
        let green = CGFloat((hex & 0xFF00) >> 8)/256.0
        let blue = CGFloat(hex & 0xFF)/256.0

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
