//
//  DatabaseClient.swift
//  pontoon-map
//
//  Created by Niall Fraser on 22/02/2020.
//  Copyright © 2020 PONToon Project. All rights reserved.
//

import Foundation
import UIKit

class DatabaseClient: NSObject, PopupDialogViewControllerDelegate {
    func popupDialogViewControllerDidFinish(_ controller: PopupDialogViewController) {
        
    }
    
    var viewController: UIViewController
    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    private let apiUrl = "Site community API link here"
    private let apiKey = "API_KEY_Here"

    var username = String()
    var password = String()

    private var authorised = false
    
    func login(username: String?, password: String?, withCompletion completion: @escaping (UserData?) -> Void) {
        
        if username == nil || password == nil || password!.count < 1 {
            
            let popup = PopupDialogViewController()
            popup.modalPresentationStyle = .overCurrentContext
            popup.delegate = self
            popup.username = username ?? ""
            popup.setDismissAction({
                
                self.username = popup.emailField.text ?? ""
                self.password = popup.passwordField.text ?? ""
                
                self.getUserInfo() {
                       result in
                    if (result == nil) {
                        self.authorised = false
                    } else {
                        self.authorised = true
                    }
                    completion(result)
                }
            }
            )
            viewController.present(popup, animated: true, completion: nil)
        } else {
            self.username = username!
            self.password = password!
            
            self.getUserInfo() {
                   result in
                if (result == nil) {
                    self.authorised = false
                } else {
                    self.authorised = true
                }
                completion(result)
            }
        }
    }
        
    func getPins(withCompletion completion: @escaping ([Pin]?) -> Void) {
        
        let config = URLSessionConfiguration.default
        let userPasswordString = "\(username):\(password)"
        let userPasswordData = userPasswordString.data(using: String.Encoding.utf8)
        let base64EncodedCredential = userPasswordData!.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
        let authString = "Basic \(base64EncodedCredential)"
        config.httpAdditionalHeaders = ["Authorization" : authString]
        
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: .main)
        let url = URL(string: apiUrl+"pins"+apiKey)!
        let task = session.dataTask(with: url, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            guard let data = data else {
                completion(nil)
                return
            }
            //debugPrint(data)
            let pinData = try? JSONDecoder().decode([Pin].self, from: data)
            completion(pinData)
        })
        task.resume()
    }
        
    func getUserInfo(withCompletion completion: @escaping (UserData?) -> Void) {
        
        let config = URLSessionConfiguration.default
        let userPasswordString = "\(username):\(password)"
        let userPasswordData = userPasswordString.data(using: String.Encoding.utf8)
        let base64EncodedCredential = userPasswordData!.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
        let authString = "Basic \(base64EncodedCredential)"
        config.httpAdditionalHeaders = ["Authorization" : authString]
        
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: .main)
        let url = URL(string: apiUrl+"login"+apiKey)!
        let task = session.dataTask(with: url, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            guard let data = data else {
                completion(nil)
                return
            }
            //debugPrint(data)
            let userData = try? JSONDecoder().decode(UserData.self, from: data)
            completion(userData)
        })
        task.resume()
    }
    

    func postPin(_ pin: Pin, withCompletion completion: @escaping (String?) -> Void) {
        
        var uploadData: Data?
        do {
            uploadData = try JSONEncoder().encode(pin)
            if pin.id ?? 0 < 0 {
                let decoded = try JSONSerialization.jsonObject(with: uploadData!, options: [])
                if var dictFromJSON = decoded as? [String:Any] {
                    dictFromJSON.removeValue(forKey: "id")
                    uploadData = try JSONSerialization.data(withJSONObject: dictFromJSON)//, options: .prettyPrinted
                }
            }
        }
      catch {
            debugPrint("encode failed")
        }

        //    print(String(data: uploadData!, encoding: .utf8)!)


        let url = URL(string: apiUrl+"pins"+apiKey)!
        
          let config = URLSessionConfiguration.default
          let userPasswordString = "\(username):\(password)"
          let userPasswordData = userPasswordString.data(using: String.Encoding.utf8)
          let base64EncodedCredential = userPasswordData!.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
          let authString = "Basic \(base64EncodedCredential)"
          config.httpAdditionalHeaders = ["Authorization" : authString]
        
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: .main)
        request.httpBody = uploadData

            let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
                if error != nil {
                    completion(nil)
                } else {
                    let dataString = String(bytes: data ?? Data(), encoding: String.Encoding.utf8)
                    completion(dataString)
                }
            })
          task.resume()
          
      }
      

      func deletePin(_ id: Int, withCompletion completion: @escaping (String?) -> Void) {
          
          var uploadData: Data?
          do {
            uploadData = try JSONEncoder().encode(Pin(id: id))
              
          }
        catch {
              debugPrint("encode failed")
          }

              print(String(data: uploadData!, encoding: .utf8)!)


          let url = URL(string: apiUrl+"pins/delete"+apiKey)!
          
            let config = URLSessionConfiguration.default
            let userPasswordString = "\(username):\(password)"
            let userPasswordData = userPasswordString.data(using: String.Encoding.utf8)
            let base64EncodedCredential = userPasswordData!.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
            let authString = "Basic \(base64EncodedCredential)"
            config.httpAdditionalHeaders = ["Authorization" : authString]
          
              var request = URLRequest(url: url)
              request.httpMethod = "POST"
          request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
          request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
          let session = URLSession(configuration: config, delegate: nil, delegateQueue: .main)
          request.httpBody = uploadData

              let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
                  let dataString = String(bytes: data ?? Data(), encoding: String.Encoding.utf8)
                  completion(dataString)
              })
            task.resume()
            
        }
    
    
    func getCentreUsers(withCompletion completion: @escaping ([String]?) -> Void) {
        
        let config = URLSessionConfiguration.default
        let userPasswordString = "\(username):\(password)"
        let userPasswordData = userPasswordString.data(using: String.Encoding.utf8)
        let base64EncodedCredential = userPasswordData!.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
        let authString = "Basic \(base64EncodedCredential)"
        config.httpAdditionalHeaders = ["Authorization" : authString]
        
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: .main)
        let url = URL(string: apiUrl+"training-centre/users"+apiKey)!
        let task = session.dataTask(with: url, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            guard let data = data else {
                completion(nil)
                return
            }
            debugPrint(data)
            let emailList = try? JSONDecoder().decode([String].self, from: data)
            completion(emailList)
        })
        task.resume()
    }
    
    
    func addCentreUser(_ userEmail: String, withCompletion completion: @escaping (String?) -> Void) {
        
        var uploadData: Data?
        do {
            struct AddData: Codable {
                var add: [String]
            }
            let addData = AddData(add: [userEmail])
            uploadData = try JSONEncoder().encode(addData)
        }
      catch {
            debugPrint("encode failed")
        }

          let url = URL(string: apiUrl+"training-centre/users"+apiKey)!
          let config = URLSessionConfiguration.default
          let userPasswordString = "\(username):\(password)"
          let userPasswordData = userPasswordString.data(using: String.Encoding.utf8)
          let base64EncodedCredential = userPasswordData!.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
          let authString = "Basic \(base64EncodedCredential)"
          config.httpAdditionalHeaders = ["Authorization" : authString]
        
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: .main)
        request.httpBody = uploadData

            let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
                if error != nil {
                    completion(nil)
                } else {
                    let dataString = String(bytes: data ?? Data(), encoding: String.Encoding.utf8)
                    completion(dataString)
                }
            })
          task.resume()
          
      }
      
    
      func removeUserCentre(_ centreEmail: String, withCompletion completion: @escaping (String?) -> Void) {
          
          var uploadData: Data?
          do {
              struct RemoveData: Codable {
                  var email: String
              }
              let removeData = RemoveData(email: centreEmail)
              uploadData = try JSONEncoder().encode(removeData)
          }
        catch {
              debugPrint("encode failed")
          }

            let url = URL(string: apiUrl+"user/training-centres/remove"+apiKey)!
            let config = URLSessionConfiguration.default
            let userPasswordString = "\(username):\(password)"
            let userPasswordData = userPasswordString.data(using: String.Encoding.utf8)
            let base64EncodedCredential = userPasswordData!.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
            let authString = "Basic \(base64EncodedCredential)"
            config.httpAdditionalHeaders = ["Authorization" : authString]
          
              var request = URLRequest(url: url)
              request.httpMethod = "POST"
          request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
          request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
          let session = URLSession(configuration: config, delegate: nil, delegateQueue: .main)
          request.httpBody = uploadData

              let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
                  if error != nil {
                      completion(nil)
                  } else {
                      let dataString = String(bytes: data ?? Data(), encoding: String.Encoding.utf8)
                      completion(dataString)
                  }
              })
            task.resume()
            
        }
          
        
      func removeCentreUser(_ userEmail: String, withCompletion completion: @escaping (String?) -> Void) {
          
          var uploadData: Data?
          do {
              struct RemoveData: Codable {
                  var remove: [String]
              }
              let removeData = RemoveData(remove: [userEmail])
              uploadData = try JSONEncoder().encode(removeData)
          }
        catch {
              debugPrint("encode failed")
          }

            let url = URL(string: apiUrl+"training-centre/users"+apiKey)!
            let config = URLSessionConfiguration.default
            let userPasswordString = "\(username):\(password)"
            let userPasswordData = userPasswordString.data(using: String.Encoding.utf8)
            let base64EncodedCredential = userPasswordData!.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
            let authString = "Basic \(base64EncodedCredential)"
            config.httpAdditionalHeaders = ["Authorization" : authString]
          
              var request = URLRequest(url: url)
              request.httpMethod = "POST"
          request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
          request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
          let session = URLSession(configuration: config, delegate: nil, delegateQueue: .main)
          request.httpBody = uploadData

              let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
                  if error != nil {
                      completion(nil)
                  } else {
                      let dataString = String(bytes: data ?? Data(), encoding: String.Encoding.utf8)
                      completion(dataString)
                  }
              })
            task.resume()
            
        }
        
        
        func getUserCentres(withCompletion completion: @escaping ([TrainingCentre]?) -> Void) {
            
            let config = URLSessionConfiguration.default
            let userPasswordString = "\(username):\(password)"
            let userPasswordData = userPasswordString.data(using: String.Encoding.utf8)
            let base64EncodedCredential = userPasswordData!.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
            let authString = "Basic \(base64EncodedCredential)"
            config.httpAdditionalHeaders = ["Authorization" : authString]
            
            let session = URLSession(configuration: config, delegate: nil, delegateQueue: .main)
            let url = URL(string: apiUrl+"user/training-centres"+apiKey)!
            let task = session.dataTask(with: url, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
                guard let data = data else {
                    completion(nil)
                    return
                }
                //debugPrint(data)
                let centres = try? JSONDecoder().decode([TrainingCentre].self, from: data)
                completion(centres)
            })
            task.resume()
        }
}
