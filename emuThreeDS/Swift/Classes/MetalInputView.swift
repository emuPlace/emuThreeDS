//
//  MetalInputView.swift
//  emuThreeDS
//
//  Created by Antique on 21/6/2023.
//

import Foundation
import MetalKit
import UIKit

class MetalInputView: UIView {
    var _inputView: UIView?
    var metalView: MTKView!


    override init(frame: CGRect) {
        super.init(frame: frame)
        
        metalView = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        metalView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(metalView)
        addConstraints([
            metalView.topAnchor.constraint(equalTo: topAnchor),
            metalView.leadingAnchor.constraint(equalTo: leadingAnchor),
            metalView.bottomAnchor.constraint(equalTo: bottomAnchor),
            metalView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override var canResignFirstResponder: Bool {
        return true
    }
    
    override var inputView: UIView? {
        set {
            _inputView = newValue
        }
        
        get {
            return _inputView
        }
    }
}
