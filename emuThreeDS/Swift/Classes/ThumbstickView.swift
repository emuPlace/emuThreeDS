//
//  ThumbstickView.swift
//  emuThreeDS
//
//  Created by Antique on 20/6/2023.
//

import Foundation
import UIKit

class ThumbstickView : UIView {
    var thumbView: UIView!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        layer.cornerCurve = .continuous
        
        thumbView = UIView()
        thumbView.translatesAutoresizingMaskIntoConstraints = false
        thumbView.alpha = 0.25
        thumbView.backgroundColor = .systemGray
        thumbView.isUserInteractionEnabled = false
        thumbView.layer.cornerCurve = .continuous
        thumbView.layer.masksToBounds = true
        thumbView.layer.borderColor = UIColor.systemGray.cgColor
        thumbView.layer.borderWidth = 3
        addSubview(thumbView)
        sendSubviewToBack(thumbView)
        addConstraints([
            thumbView.topAnchor.constraint(equalTo: topAnchor, constant: 3),
            thumbView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3),
            thumbView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3),
            thumbView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -3)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.width / 2
        thumbView.layer.cornerRadius = thumbView.frame.width / 2
    }
}
