//
//  UserTableViewController.swift
//  pontoon-map
//
//  Created by Niall Fraser on 19/04/2020.
//  Copyright © 2020 PONToon Project. All rights reserved.
//

import UIKit

class UserTableViewController: UITableViewController {
    
    var emailList: [String]?
    var userData: UserData?
    var client: DatabaseClient?
    var mainVC: ViewController?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: "UserTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "userCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DefaultCell")
        tableView.sectionHeaderHeight = 80
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        mainVC = self.presentingViewController as? ViewController
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.frame = CGRect(x: 0 , y: 0, width: tableView.frame.width, height: tableView.sectionHeaderHeight)
        
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("Done", comment: ""), for: .normal)
        button.frame = CGRect(x: view.frame.width - 80, y: view.frame.origin.y, width: 80, height: view.frame.height/2)
        button.addTarget(self, action: #selector(donePressed), for: .touchUpInside)
        view.addSubview(button)
        
        let label = UILabel()
        label.numberOfLines = 2
        if userData?.role == "recruiter" {
            label.text = NSLocalizedString("Users registered with you", comment: "")
        } else {
            label.text = NSLocalizedString("Training Centres you are registered with", comment: "")
        }
        label.textAlignment = .center
        label.frame = CGRect(x: view.frame.origin.x, y: view.frame.origin.y + button.frame.height/2, width: view.frame.width, height: view.frame.height)
        view.addSubview(label)
        
        return view
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if userData?.role == "recruiter" {
            return (emailList?.count ?? 0) + 1
        } else {
            return userData?.traingingCentres?.count ?? 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if userData?.role == "recruiter" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath)
            if (indexPath.row < emailList!.count) {
                cell.textLabel?.text = emailList?[indexPath.row]
            } else {
                cell.textLabel?.text = NSLocalizedString("Add User", comment: "")
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! UserTableViewCell
            let name = userData?.traingingCentres?[indexPath.row].name
            let combinedName = (name?.first ?? "") + " " + (name?.last ?? "")
            cell.textLabel?.text = combinedName
            cell.setPinVisible(!(mainVC?.hidePinDict[(userData?.traingingCentres?[indexPath.row].email!)!] ?? false), finalCallback: {() -> Void in
                self.mainVC?.hidePinDict[(self.userData?.traingingCentres?[indexPath.row].email!)!] = !cell.pinVisible.isOn
                self.mainVC?.refreshPins()
                self.mainVC?.saveHideDict()
            })
            cell.selectionStyle = .none
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if userData?.role == "recruiter" {
            if (indexPath.row < emailList!.count) {
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if userData?.role == "recruiter" {
                client?.removeCentreUser((emailList?[indexPath.row])!) { result in
                    self.emailList?.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
            } else {
                client?.removeUserCentre((userData?.traingingCentres?[indexPath.row].email)!) { result in
                    self.mainVC?.hidePinDict[(self.userData?.traingingCentres?[indexPath.row].email!)!] = nil
                    self.userData?.traingingCentres?.remove(at: indexPath.row)
                    self.mainVC?.saveCentres()
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    self.mainVC?.refreshPins()
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if userData?.role == "recruiter" {
            if (indexPath.row == emailList!.count) {
                let alert = UIAlertController(title: NSLocalizedString("Add User", comment:""), message: nil, preferredStyle: .alert)
                
                alert.addTextField(configurationHandler: { textField in
                    textField.placeholder = NSLocalizedString("Email", comment:"")
                })
                
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment:""), style: .default, handler: { action in
                }))
                    
                alert.addAction(UIAlertAction(title: NSLocalizedString("Enter", comment:""), style: .default, handler: { action in
                    
                    let email = alert.textFields?.first?.text ?? ""
                    self.client?.addCentreUser(email) { result in
                        if (result != nil) {
                        } else {
                            let alert = UIAlertController(title: NSLocalizedString("Add User Failed", comment:""), message: nil, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: NSLocalizedString("Enter", comment:""), style: .default, handler: { action in
                            }))
                            self.present(alert, animated: true)
                        }
                        self.emailList?.append(email)
                        tableView.insertRows(at: [indexPath], with: .automatic)
                    }
                }))
                self.present(alert, animated: true)
            }
        }
    }
    
    @objc func donePressed() {
        self.dismiss(animated: true, completion: nil)
    }

}
