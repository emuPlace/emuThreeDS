//
//  AuthenticationViewController.swift
//  emuThreeDS
//
//  Created by Antique on 28/7/2023.
//

import Foundation
import UIKit

struct Response : Codable, Hashable {
    struct Subscription : Codable, Hashable {
        let payer_email: String
    }
    
    let current_page : Int
    let data: [Subscription]
}


class AuthenticationViewController : LargeTitleImageViewController, UITextFieldDelegate {
    var emailTextField: MinimalRoundedTextField!
    var authenticateButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField = .init("Email", .all)
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.autocapitalizationType = .none
        emailTextField.delegate = self
        emailTextField.returnKeyType = .done
        view.addSubview(emailTextField)
        
        view.addConstraints([
            emailTextField.topAnchor.constraint(equalTo: (subtitleLabel == nil ? titleLabel : subtitleLabel).safeAreaLayoutGuide.bottomAnchor, constant: 20),
            emailTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            emailTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            emailTextField.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: Delegates
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let window = view.window, let textField = textField as? MinimalRoundedTextField, let text = textField.text else {
            return true
        }
        
        Task {
            let flag = try await BMACAuthenticate.shared.validate(for: text)
            if flag {
                imageView.image = .init(systemName: "lock.open.fill")
                textField.success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                        UserDefaults.standard.setValue(text, forKey: "email")
                        BMACAuthenticate.shared.presentApplication(for: window)
                    })
                }
            } else {
                textField.error()
            }
        }
        
        return true
    }
}
