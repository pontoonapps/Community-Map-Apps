//
//  PopupDialogViewController.swift
//  pontoon-map
//
//  Created by Niall Fraser on 18/10/2020.
//  Copyright © 2020 PONToon Project. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

public protocol PopupDialogViewControllerDelegate: NSObjectProtocol {
    func popupDialogViewControllerDidFinish(_ controller: PopupDialogViewController)
 }

open class PopupDialogViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    open weak var delegate: PopupDialogViewControllerDelegate?
    
    let textView = UITextView()
    let dialog = UIView()
    let emailField = UITextField(frame:CGRect(x: 10, y: 0, width: 140, height: 30))
    let passwordField = UITextField(frame:CGRect(x: 10, y: 0, width: 140, height: 30))
    var username = String()
    var actionCode: (() -> Void)?

    
    open override func loadView() {
    super.loadView()
        
        let image = UIImage(named: "Interreg-PONToon-logo.png")
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 170)
            ])
        
        textView.backgroundColor = .white
        textView.textAlignment = .center
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = NSTextAlignment.center

        let attributedString = NSMutableAttributedString(string: NSLocalizedString("Project PONToon, Partnership Opportunities using New Technologies fostering sOcial and ecOnomic inclusioN 2017-2021, is a 5.8 million euro digital upskilling collaboration between participants in Southern England and Northern France. The project is 69% funded by the European Regional Development Fund, Interreg France (Channel) England programme and is delivered by 11 partners, The University of Portsmouth (lead), Amiens Métropole, Aspex, ADICE, Digital Peninsula Network, Devon Mind, Eastleigh Borough Council, GIP-FCIP de l'académie de Caen, MEFP, TRAJECTIO and WSX Enterprise.\n\nFor more information please \0click here.", comment:""), attributes: [NSAttributedString.Key.paragraphStyle : paragraphStyle])
        
        var length = attributedString.string.count
        var location = attributedString.string.distance(from: attributedString.string.startIndex, to:attributedString.string.lastIndex(of: "\0")!)
        attributedString.addAttribute(.link, value: "https://pontoonproject.eu/", range: NSRange(location: location, length: length - location))
        textView.attributedText = attributedString
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.font = UIFont.systemFont(ofSize: 12)
        textView.sizeToFit()
        textView.delegate = self
        
        let loginText = UILabel()
        loginText.textColor = .black
        loginText.text = NSLocalizedString("Login", comment:"")
        loginText.font = UIFont.systemFont(ofSize: 18)
        
        emailField.textColor = .black
        emailField.attributedPlaceholder = NSAttributedString(string: "Email",
                                                              attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        emailField.keyboardType = .emailAddress
        emailField.text = username
        let emailView = UIView()
        emailView.layer.borderWidth = 1
        emailView.layer.borderColor = UIColor.lightGray.cgColor
        emailView.layer.cornerRadius = 5
        emailView.addSubview(emailField)
        NSLayoutConstraint.activate([
            emailView.heightAnchor.constraint(equalToConstant: 30),
            emailView.widthAnchor.constraint(equalToConstant: 160)
        ])
        
        passwordField.textColor = .black
        passwordField.attributedPlaceholder = NSAttributedString(string: "Password",
                                                              attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        passwordField.isSecureTextEntry = true
        let passwordView = UIView()
        passwordView.layer.borderWidth = 1
        passwordView.layer.borderColor = UIColor.lightGray.cgColor
        passwordView.layer.cornerRadius = 5
        passwordView.addSubview(passwordField)
        NSLayoutConstraint.activate([
            passwordView.heightAnchor.constraint(equalToConstant: 30),
            passwordView.widthAnchor.constraint(equalToConstant: 160)
        ])
        
        let title = "OK"
        let okButton = UIButton()
        okButton.setTitle(title, for: UIControl.State())
        okButton.setTitleColor(.darkText, for: .normal)
    
    let loginView = UIStackView(arrangedSubviews: [loginText, emailView, passwordView])
    loginView.alignment = .center
    loginView.axis = .vertical
    loginView.spacing = 4
    NSLayoutConstraint.activate([
        loginView.heightAnchor.constraint(equalToConstant: 90)
    ])
        
        let textView2 = UITextView()
        textView2.delegate = self
        textView2.backgroundColor = .white
        textView2.textAlignment = .center
        let attributedString2 = NSMutableAttributedString(string: NSLocalizedString("If you dont have an account\n\0click here to sign up", comment:""), attributes: [NSAttributedString.Key.paragraphStyle : paragraphStyle])
        length = attributedString2.string.count
        location = attributedString2.string.distance(from: attributedString2.string.startIndex, to:attributedString2.string.lastIndex(of: "\0")!)
        attributedString2.addAttribute(.link, value: "https://pontoonapps.com/signup.php", range: NSRange(location: location, length: length - location))
        textView2.attributedText = attributedString2
        textView2.isScrollEnabled = false
        textView2.isEditable = false
        textView2.font = UIFont.systemFont(ofSize: 12)
        
        dialog.backgroundColor = .white
        dialog.frame.size = CGSize(width: 340, height: 600)
        dialog.center = view.center
        view.addSubview(dialog)
        
        let stack = UIStackView(arrangedSubviews: [loginView, imageView, textView, textView2])
        stack.frame = CGRect(x: 20, y: 20, width: dialog.frame.width-40, height: dialog.frame.height-40)

        stack.alignment = .center
        stack.axis = .vertical
        stack.spacing = 1
        dialog.addSubview(stack)
        stack.backgroundColor = .white
        view.backgroundColor = .clear
    
        NSLayoutConstraint.activate([
            loginView.widthAnchor.constraint(equalToConstant: stack.frame.width)
        ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        let safariVC = SFSafariViewController(url: URL)
        present(safariVC, animated: true, completion: nil)
        return false
    }
    
    @objc func orientationChanged() {
        dialog.center = view.center
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.emailField.delegate = self
        self.passwordField.delegate = self
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        textView.sizeToFit()
    }
    
    public func setDismissAction(_ action: @escaping () -> Void) {
        self.actionCode = action
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if emailField.text!.count > 0 && passwordField.text!.count > 0 {
            actionCode?()
            delegate?.popupDialogViewControllerDidFinish(self)
            dismiss(animated: true)
        } else {
            textField.resignFirstResponder()
            if textField == emailField {
                passwordField.becomeFirstResponder()
            }
        }
        return true
    }
    
}
