//
//  MinimalRoundedTextField.swift
//  emuThreeDS
//
//  Created by Antique on 28/7/2023.
//

import Foundation
import UIKit

class MinimalRoundedTextField : UITextField {
    enum Position {
        case top, bottom, middle, all
        
        func cornerMask() -> CACornerMask {
            switch self {
            case .top:
                return [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            case .bottom:
                return [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            case .middle:
                return []
            case .all:
                return [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            }
        }
    }
    
    
    init(_ placeholder: String, _ position: Position, _ cornerRadius: CGFloat = 15) {
        super.init(frame: .zero)
        self.backgroundColor = .secondarySystemBackground
        self.layer.cornerCurve = .continuous
        self.layer.cornerRadius = cornerRadius
        self.layer.maskedCorners = position.cornerMask()
        self.placeholder = placeholder
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 20, dy: 0)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return editingRect(forBounds: bounds)
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return editingRect(forBounds: bounds)
    }
    
    
    func error() {
        UIView.animate(withDuration: 0.5) {
            self.backgroundColor = .systemRed.withAlphaComponent(0.1)
            
            self.layer.borderColor = UIColor.systemRed.cgColor
            self.layer.borderWidth = 2
        } completion: { flag in
            self.reset()
        }
    }
    
    func reset() {
        UIView.animate(withDuration: 0.5) {
            self.backgroundColor = .secondarySystemBackground
            
            self.layer.borderColor = nil
            self.layer.borderWidth = 0
        }
    }
    
    func success(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 1.0) {
            self.backgroundColor = .systemGreen.withAlphaComponent(0.1)
            
            self.layer.borderColor = UIColor.systemGreen.cgColor
            self.layer.borderWidth = 2
        } completion: { flag in
            completion()
        }
    }
}
