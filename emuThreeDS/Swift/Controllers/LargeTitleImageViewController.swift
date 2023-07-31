//
//  LargeTitleImageViewController.swift
//  emuThreeDS
//
//  Created by Antique on 28/7/2023.
//

import Foundation
import UIKit

class LargeTitleImageViewController : UIViewController {
    var imageView: UIImageView!
    var image: UIImage?
    
    var titleLabel, subtitleLabel: UILabel!
    var titleString: String
    var subtitleString: String?
    
    
    init(_ image: UIImage?, _ title: String, _ subtitle: String?) {
        self.image = image
        self.titleString = title
        self.subtitleString = subtitle
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        imageView = .init(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        
        var largeTitleFont, subtitleFont: UIFont
        if #available(iOS 17, *) {
            largeTitleFont = .preferredFont(forTextStyle: .extraLargeTitle)
            subtitleFont = .preferredFont(forTextStyle: .title3)
        } else {
            largeTitleFont = .preferredFont(forTextStyle: .largeTitle)
            subtitleFont = .preferredFont(forTextStyle: .body)
        }
        
        titleLabel = .init()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.attributedText = .init(string: titleString, attributes: [
            .font : UIFont.boldSystemFont(ofSize: largeTitleFont.pointSize),
            .foregroundColor : UIColor.label
        ])
        view.addSubview(titleLabel)
        
        if let subtitleString {
            subtitleLabel = .init()
            subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
            subtitleLabel.attributedText = .init(string: subtitleString, attributes: [
                .font : subtitleFont,
                .foregroundColor : UIColor.secondaryLabel,
            ])
            subtitleLabel.numberOfLines = 3
            view.addSubview(subtitleLabel)
        }
        
        view.addConstraints([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20), // imageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.safeAreaLayoutGuide.bottomAnchor, constant: 20),
            // titleLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20), // titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
        ])
        
        if subtitleString != nil {
            view.addConstraints([
                subtitleLabel.topAnchor.constraint(equalTo: titleLabel.safeAreaLayoutGuide.bottomAnchor, constant: 10),
                // subtitleLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
                subtitleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20), // subtitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
                subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
            ])
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(false)
    }
}
