//
//  EmulationViewController.swift
//  emuThreeDS
//
//  Created by Antique on 18/6/2023.
//

import Foundation
import GameController
import MetalKit
import UIKit

class EmulationViewController : UIViewController, PerformanceStatisticsDelegate {
    var citraWrapper = CitraWrapper.shared()
    var thread: Thread!
    
    var controllerConnected: Bool = false
    
    var leftThumbstickView, rightThumbstickView: ThumbstickView!
    var metalInputView: MetalInputView!
    var emulationSpeedContainerView, gameFpsContainerView: UIView!
    
    var emulationSpeedLabel, gameFpsLabel: UILabel!
    
    var aButton, bButton, xButton, yButton: UIButton!
    var dpadUButton, dpadLButton, dpadDButton, dpadRButton: UIButton!
    var lButton, zlButton, rButton, zrButton, selectButton, startButton: UIButton!
    
    
    override func loadView() {
        metalInputView = MetalInputView(frame: UIScreen.main.bounds)
        view = metalInputView
        citraWrapper.prepare(layer: metalInputView.metalView.layer as! CAMetalLayer)
        citraWrapper.performanceStatisticsDelegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let _ = VirtualController(buttons: [
            .init(position: .init(x: 10, y: 10), size: .init(w: 55, h: 55))
        ])
        
        
        
        
        thread = Thread(target: self, selector: #selector(run), object: nil)
        thread.name = "emuThreeDS"
        thread.qualityOfService = .userInteractive
        thread.threadPriority = 1.0
        
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.GCControllerDidConnect, object: nil, queue: .main) { notification in
            self.toggleVirtualController(0)
            self.toggleThumbsticks(0)
            self.controllerConnected = true
            guard let controller = GCController.current, let extendedGamepad = controller.extendedGamepad else {
                return
            }
            
            self.configurePhysicalController(for: extendedGamepad)
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.GCControllerDidDisconnect, object: nil, queue: .main) { notification in
            self.controllerConnected = false
            self.toggleVirtualController(1)
            self.toggleThumbsticks(1)
        }
        
        
        let tintConfiguration: UIImage.SymbolConfiguration
        let redConfiguration, yellowConfiguration, blueConfiguration, greenConfiguration: UIImage.SymbolConfiguration
        if #available(iOS 15, *) {
            tintConfiguration = UIImage.SymbolConfiguration(hierarchicalColor: .systemGray)
            
            redConfiguration = .init(hierarchicalColor: .systemRed)
            yellowConfiguration = .init(hierarchicalColor: .systemYellow)
            blueConfiguration = .init(hierarchicalColor: .systemBlue)
            greenConfiguration = .init(hierarchicalColor: .systemGreen)
        } else {
            tintConfiguration = .init(scale: .default)
            
            redConfiguration = .init(scale: .default)
            yellowConfiguration = .init(scale: .default)
            blueConfiguration = .init(scale: .default)
            greenConfiguration = .init(scale: .default)
        }
        
        let smallSymbolConfiguration: UIImage.SymbolConfiguration
        let largeSymbolConfiguration: UIImage.SymbolConfiguration
        if #available(iOS 15, *) {
            smallSymbolConfiguration = .init(pointSize: 32, weight: .regular, scale: .medium).applying(tintConfiguration)
            largeSymbolConfiguration = .init(pointSize: 40, weight: .regular, scale: .large).applying(tintConfiguration)
        } else {
            smallSymbolConfiguration = .init(pointSize: 32, weight: .regular, scale: .medium).applying(tintConfiguration)
            largeSymbolConfiguration = .init(pointSize: 40, weight: .regular, scale: .large).applying(tintConfiguration)
        }
        
        
        // MARK: ABXY
        if #available(iOS 15, *) {
            aButton = button(with: UIImage(systemName: "a.circle.fill", withConfiguration: largeSymbolConfiguration), for: redConfiguration)
        } else {
            aButton = button(with: UIImage(systemName: "a.circle.fill"), for: largeSymbolConfiguration)
        }
        aButton.translatesAutoresizingMaskIntoConstraints = false
        aButton.addAction(UIAction(handler: { action in EmulationInput.buttonA.pressChangedHandler(nil, value: 1, pressed: true) }), for: .touchDown)
        aButton.addAction(UIAction(handler: { action in EmulationInput.buttonA.pressChangedHandler(nil, value: 0, pressed: false) }), for: .touchUpInside)
        view.addSubview(aButton)
        view.addConstraints([
            aButton.widthAnchor.constraint(equalToConstant: 48),
            aButton.heightAnchor.constraint(equalToConstant: 48),
            aButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -112),
            aButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
        
        if #available(iOS 15, *) {
            bButton = button(with: UIImage(systemName: "b.circle.fill", withConfiguration: largeSymbolConfiguration), for: yellowConfiguration)
        } else {
            bButton = button(with: UIImage(systemName: "b.circle.fill"), for: largeSymbolConfiguration)
        }
        bButton.translatesAutoresizingMaskIntoConstraints = false
        bButton.addAction(UIAction(handler: { action in EmulationInput.buttonB.pressChangedHandler(nil, value: 1, pressed: true) }), for: .touchDown)
        bButton.addAction(UIAction(handler: { action in EmulationInput.buttonB.pressChangedHandler(nil, value: 0, pressed: false) }), for: .touchUpInside)
        view.addSubview(bButton)
        view.addConstraints([
            bButton.widthAnchor.constraint(equalToConstant: 48),
            bButton.heightAnchor.constraint(equalToConstant: 48),
            bButton.topAnchor.constraint(equalTo: aButton.bottomAnchor),
            bButton.trailingAnchor.constraint(equalTo: aButton.leadingAnchor)
        ])
        
        if #available(iOS 15, *) {
            xButton = button(with: UIImage(systemName: "x.circle.fill", withConfiguration: largeSymbolConfiguration), for: blueConfiguration)
        } else {
            xButton = button(with: UIImage(systemName: "x.circle.fill"), for: largeSymbolConfiguration)
        }
        xButton.translatesAutoresizingMaskIntoConstraints = false
        xButton.addAction(UIAction(handler: { action in EmulationInput.buttonX.pressChangedHandler(nil, value: 1, pressed: true) }), for: .touchDown)
        xButton.addAction(UIAction(handler: { action in EmulationInput.buttonX.pressChangedHandler(nil, value: 0, pressed: false) }), for: .touchUpInside)
        view.addSubview(xButton)
        view.addConstraints([
            xButton.widthAnchor.constraint(equalToConstant: 48),
            xButton.heightAnchor.constraint(equalToConstant: 48),
            xButton.bottomAnchor.constraint(equalTo: aButton.topAnchor),
            xButton.trailingAnchor.constraint(equalTo: aButton.leadingAnchor)
        ])
        
        if #available(iOS 15, *) {
            yButton = button(with: UIImage(systemName: "y.circle.fill", withConfiguration: largeSymbolConfiguration), for: greenConfiguration)
        } else {
            yButton = button(with: UIImage(systemName: "y.circle.fill"), for: largeSymbolConfiguration)
        }
        yButton.translatesAutoresizingMaskIntoConstraints = false
        yButton.addAction(UIAction(handler: { action in EmulationInput.buttonY.pressChangedHandler(nil, value: 1, pressed: true) }), for: .touchDown)
        yButton.addAction(UIAction(handler: { action in EmulationInput.buttonY.pressChangedHandler(nil, value: 0, pressed: false) }), for: .touchUpInside)
        view.addSubview(yButton)
        view.addConstraints([
            yButton.widthAnchor.constraint(equalToConstant: 48),
            yButton.heightAnchor.constraint(equalToConstant: 48),
            yButton.topAnchor.constraint(equalTo: aButton.topAnchor),
            yButton.trailingAnchor.constraint(equalTo: xButton.leadingAnchor)
        ])
        
        
        // MARK: DPAD
        dpadLButton = button(with: UIImage(systemName: "arrowtriangle.left.circle.fill", withConfiguration: largeSymbolConfiguration))
        dpadLButton.translatesAutoresizingMaskIntoConstraints = false
        dpadLButton.addAction(UIAction(handler: { action in EmulationInput.dpadLeft.pressChangedHandler(nil, value: 1, pressed: true) }), for: .touchDown)
        dpadLButton.addAction(UIAction(handler: { action in EmulationInput.dpadLeft.pressChangedHandler(nil, value: 0, pressed: false) }), for: .touchUpInside)
        view.addSubview(dpadLButton)
        view.addConstraints([
            dpadLButton.widthAnchor.constraint(equalToConstant: 48),
            dpadLButton.heightAnchor.constraint(equalToConstant: 48),
            dpadLButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -112),
            dpadLButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20)
        ])
        
        dpadDButton = button(with: UIImage(systemName: "arrowtriangle.down.circle.fill", withConfiguration: largeSymbolConfiguration))
        dpadDButton.translatesAutoresizingMaskIntoConstraints = false
        dpadDButton.addAction(UIAction(handler: { action in EmulationInput.dpadDown.pressChangedHandler(nil, value: 1, pressed: true) }), for: .touchDown)
        dpadDButton.addAction(UIAction(handler: { action in EmulationInput.dpadDown.pressChangedHandler(nil, value: 0, pressed: false) }), for: .touchUpInside)
        view.addSubview(dpadDButton)
        view.addConstraints([
            dpadDButton.widthAnchor.constraint(equalToConstant: 48),
            dpadDButton.heightAnchor.constraint(equalToConstant: 48),
            dpadDButton.topAnchor.constraint(equalTo: dpadLButton.bottomAnchor),
            dpadDButton.leadingAnchor.constraint(equalTo: dpadLButton.trailingAnchor)
        ])
        
        dpadUButton = button(with: UIImage(systemName: "arrowtriangle.up.circle.fill", withConfiguration: largeSymbolConfiguration))
        dpadUButton.translatesAutoresizingMaskIntoConstraints = false
        dpadUButton.addAction(UIAction(handler: { action in EmulationInput.dpadUp.pressChangedHandler(nil, value: 1, pressed: true) }), for: .touchDown)
        dpadUButton.addAction(UIAction(handler: { action in EmulationInput.dpadUp.pressChangedHandler(nil, value: 0, pressed: false) }), for: .touchUpInside)
        view.addSubview(dpadUButton)
        view.addConstraints([
            dpadUButton.widthAnchor.constraint(equalToConstant: 48),
            dpadUButton.heightAnchor.constraint(equalToConstant: 48),
            dpadUButton.bottomAnchor.constraint(equalTo: dpadLButton.topAnchor),
            dpadUButton.leadingAnchor.constraint(equalTo: dpadLButton.trailingAnchor)
        ])
        
        dpadRButton = button(with: UIImage(systemName: "arrowtriangle.right.circle.fill", withConfiguration: largeSymbolConfiguration))
        dpadRButton.translatesAutoresizingMaskIntoConstraints = false
        dpadRButton.addAction(UIAction(handler: { action in EmulationInput.dpadRight.pressChangedHandler(nil, value: 1, pressed: true) }), for: .touchDown)
        dpadRButton.addAction(UIAction(handler: { action in EmulationInput.dpadRight.pressChangedHandler(nil, value: 0, pressed: false) }), for: .touchUpInside)
        view.addSubview(dpadRButton)
        view.addConstraints([
            dpadRButton.widthAnchor.constraint(equalToConstant: 48),
            dpadRButton.heightAnchor.constraint(equalToConstant: 48),
            dpadRButton.topAnchor.constraint(equalTo: dpadLButton.topAnchor),
            dpadRButton.leadingAnchor.constraint(equalTo: dpadUButton.trailingAnchor)
        ])
        
        
        // MARK: LZLRZR
        lButton = button(with: UIImage(systemName: isLatestOS() ? "l.button.roundedbottom.horizontal.fill" : "l.rectangle.roundedbottom.fill", withConfiguration: largeSymbolConfiguration))
        lButton.translatesAutoresizingMaskIntoConstraints = false
        lButton.addAction(UIAction(handler: { action in EmulationInput.buttonL.pressChangedHandler(nil, value: 1, pressed: true) }), for: .touchDown)
        lButton.addAction(UIAction(handler: { action in EmulationInput.buttonL.pressChangedHandler(nil, value: 0, pressed: false) }), for: .touchUpInside)
        view.addSubview(lButton)
        view.addConstraints([
            lButton.widthAnchor.constraint(equalToConstant: 48),
            lButton.heightAnchor.constraint(equalToConstant: 48),
            lButton.bottomAnchor.constraint(equalTo: dpadUButton.topAnchor, constant: -20),
            lButton.leadingAnchor.constraint(equalTo: dpadLButton.leadingAnchor)
        ])
        
        zlButton = button(with: UIImage(systemName: isLatestOS() ? "zl.button.roundedtop.horizontal.fill" : "zl.rectangle.roundedtop.fill", withConfiguration: largeSymbolConfiguration))
        zlButton.translatesAutoresizingMaskIntoConstraints = false
        zlButton.addAction(UIAction(handler: { action in EmulationInput.buttonZL.pressChangedHandler(nil, value: 1, pressed: true) }), for: .touchDown)
        zlButton.addAction(UIAction(handler: { action in EmulationInput.buttonZL.pressChangedHandler(nil, value: 0, pressed: false) }), for: .touchUpInside)
        view.addSubview(zlButton)
        view.addConstraints([
            zlButton.widthAnchor.constraint(equalToConstant: 56),
            zlButton.heightAnchor.constraint(equalToConstant: 48),
            zlButton.bottomAnchor.constraint(equalTo: dpadUButton.topAnchor, constant: -20),
            zlButton.leadingAnchor.constraint(equalTo: lButton.trailingAnchor, constant: 20)
        ])
        
        rButton = button(with: UIImage(systemName: isLatestOS() ? "r.button.roundedbottom.horizontal.fill" : "r.rectangle.roundedbottom.fill", withConfiguration: largeSymbolConfiguration))
        rButton.translatesAutoresizingMaskIntoConstraints = false
        rButton.addAction(UIAction(handler: { action in EmulationInput.buttonR.pressChangedHandler(nil, value: 1, pressed: true) }), for: .touchDown)
        rButton.addAction(UIAction(handler: { action in EmulationInput.buttonR.pressChangedHandler(nil, value: 0, pressed: false) }), for: .touchUpInside)
        view.addSubview(rButton)
        view.addConstraints([
            rButton.widthAnchor.constraint(equalToConstant: 48),
            rButton.heightAnchor.constraint(equalToConstant: 48),
            rButton.bottomAnchor.constraint(equalTo: xButton.topAnchor, constant: -20),
            rButton.trailingAnchor.constraint(equalTo: aButton.trailingAnchor)
        ])
        
        zrButton = button(with: UIImage(systemName: isLatestOS() ? "zr.button.roundedtop.horizontal.fill" : "zr.rectangle.roundedtop.fill", withConfiguration: largeSymbolConfiguration))
        zrButton.translatesAutoresizingMaskIntoConstraints = false
        zrButton.addAction(UIAction(handler: { action in EmulationInput.buttonZR.pressChangedHandler(nil, value: 1, pressed: true) }), for: .touchDown)
        zrButton.addAction(UIAction(handler: { action in EmulationInput.buttonZR.pressChangedHandler(nil, value: 0, pressed: false) }), for: .touchUpInside)
        view.addSubview(zrButton)
        view.addConstraints([
            zrButton.widthAnchor.constraint(equalToConstant: 56),
            zrButton.heightAnchor.constraint(equalToConstant: 48),
            zrButton.bottomAnchor.constraint(equalTo: xButton.topAnchor, constant: -20),
            zrButton.trailingAnchor.constraint(equalTo: rButton.leadingAnchor, constant: -20)
        ])
        
        
        // MARK: -+
        selectButton = button(with: UIImage(systemName: "minus.circle.fill", withConfiguration: smallSymbolConfiguration))
        selectButton.translatesAutoresizingMaskIntoConstraints = false
        selectButton.addAction(UIAction(handler: { action in EmulationInput.buttonSelect.pressChangedHandler(nil, value: 1, pressed: true) }), for: .touchDown)
        selectButton.addAction(UIAction(handler: { action in EmulationInput.buttonSelect.pressChangedHandler(nil, value: 0, pressed: false) }), for: .touchUpInside)
        view.addSubview(selectButton)
        view.addConstraints([
            selectButton.widthAnchor.constraint(equalToConstant: 40),
            selectButton.heightAnchor.constraint(equalToConstant: 40),
            selectButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            selectButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: -10)
        ])
        
        startButton = button(with: UIImage(systemName: "plus.circle.fill", withConfiguration: smallSymbolConfiguration))
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addAction(UIAction(handler: { action in EmulationInput.buttonStart.pressChangedHandler(nil, value: 1, pressed: true) }), for: .touchDown)
        startButton.addAction(UIAction(handler: { action in EmulationInput.buttonStart.pressChangedHandler(nil, value: 0, pressed: false) }), for: .touchUpInside)
        view.addSubview(startButton)
        view.addConstraints([
            startButton.widthAnchor.constraint(equalToConstant: 40),
            startButton.heightAnchor.constraint(equalToConstant: 40),
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            startButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: 10)
        ])
        
        
        // MARK: LThumbstick/RThumbstick
        leftThumbstickView = ThumbstickView()
        leftThumbstickView.translatesAutoresizingMaskIntoConstraints = false
        leftThumbstickView.alpha = 0
        view.addSubview(leftThumbstickView)
        view.addConstraints([
            leftThumbstickView.topAnchor.constraint(equalTo: dpadRButton.bottomAnchor, constant: 20),
            leftThumbstickView.leadingAnchor.constraint(equalTo: dpadDButton.trailingAnchor, constant: 10),
            leftThumbstickView.widthAnchor.constraint(equalToConstant: 104),
            leftThumbstickView.heightAnchor.constraint(equalTo: leftThumbstickView.widthAnchor)
        ])
        
        rightThumbstickView = ThumbstickView()
        rightThumbstickView.translatesAutoresizingMaskIntoConstraints = false
        rightThumbstickView.alpha = 0
        view.addSubview(rightThumbstickView)
        view.addConstraints([
            rightThumbstickView.topAnchor.constraint(equalTo: yButton.bottomAnchor, constant: 20),
            rightThumbstickView.trailingAnchor.constraint(equalTo: bButton.leadingAnchor, constant: -10),
            rightThumbstickView.widthAnchor.constraint(equalToConstant: 104),
            rightThumbstickView.heightAnchor.constraint(equalTo: rightThumbstickView.widthAnchor)
        ])
        
        
        // MARK: FPS/Emulation Speed Labels
        emulationSpeedContainerView = UIView()
        emulationSpeedContainerView.translatesAutoresizingMaskIntoConstraints = false
        emulationSpeedContainerView.alpha = 0
        emulationSpeedContainerView.backgroundColor = .black.withAlphaComponent(0.75)
        emulationSpeedContainerView.layer.cornerCurve = .continuous
        emulationSpeedContainerView.layer.cornerRadius = 8
        view.addSubview(emulationSpeedContainerView)
        view.addConstraints([
            emulationSpeedContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            emulationSpeedContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10)
        ])
        
        emulationSpeedLabel = UILabel()
        emulationSpeedLabel.translatesAutoresizingMaskIntoConstraints = false
        emulationSpeedContainerView.addSubview(emulationSpeedLabel)
        view.addConstraints([
            emulationSpeedLabel.topAnchor.constraint(equalTo: emulationSpeedContainerView.topAnchor, constant: 3),
            emulationSpeedLabel.leadingAnchor.constraint(equalTo: emulationSpeedContainerView.leadingAnchor, constant: 6),
            emulationSpeedContainerView.bottomAnchor.constraint(equalTo: emulationSpeedLabel.bottomAnchor, constant: 3),
            emulationSpeedContainerView.trailingAnchor.constraint(equalTo: emulationSpeedLabel.trailingAnchor, constant: 6)
        ])
        
        gameFpsContainerView = UIView()
        gameFpsContainerView.translatesAutoresizingMaskIntoConstraints = false
        gameFpsContainerView.alpha = 0
        gameFpsContainerView.backgroundColor = .black.withAlphaComponent(0.75)
        gameFpsContainerView.layer.cornerCurve = .continuous
        gameFpsContainerView.layer.cornerRadius = 8
        view.addSubview(gameFpsContainerView)
        view.addConstraints([
            gameFpsContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            gameFpsContainerView.leadingAnchor.constraint(equalTo: emulationSpeedContainerView.trailingAnchor, constant: 10)
        ])
        
        gameFpsLabel = UILabel()
        gameFpsLabel.translatesAutoresizingMaskIntoConstraints = false
        gameFpsContainerView.addSubview(gameFpsLabel)
        view.addConstraints([
            gameFpsLabel.topAnchor.constraint(equalTo: gameFpsContainerView.topAnchor, constant: 3),
            gameFpsLabel.leadingAnchor.constraint(equalTo: gameFpsContainerView.leadingAnchor, constant: 6),
            gameFpsContainerView.bottomAnchor.constraint(equalTo: gameFpsLabel.bottomAnchor, constant: 3),
            gameFpsContainerView.trailingAnchor.constraint(equalTo: gameFpsLabel.trailingAnchor, constant: 6)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        thread.start()
    }
    
    
    // MARK: Transitions
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if (UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight) && !controllerConnected {
            coordinator.animate { context in
                UIView.animate(withDuration: context.transitionDuration) {
                    self.leftThumbstickView.alpha = 1
                    self.rightThumbstickView.alpha = 1
                }
            }
        } else {
            coordinator.animate { context in
                UIView.animate(withDuration: context.transitionDuration) {
                    self.leftThumbstickView.alpha = 0
                    self.rightThumbstickView.alpha = 0
                }
            }
        }
        
        
        citraWrapper.orientationChanged(UIDevice.current.orientation, with: metalInputView.metalView.layer as! CAMetalLayer)
    }
    
    
    // MARK: Touch
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else {
            return
        }
        
        if touch.view == metalInputView.metalView {
            citraWrapper.touchesBegan(point: touch.location(in: metalInputView.metalView))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first else {
            return
        }
        
        if touch.view == leftThumbstickView {
            EmulationInput.leftThumbstick.valueChangedHandler(nil, x: 0, y: 0)
        } else if touch.view == rightThumbstickView {
            EmulationInput.rightThumstick.valueChangedHandler(nil, x: 0, y: 0)
        }
        
        citraWrapper.touchesEnded()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else {
            return
        }
        
        let thumbSize: CGFloat = 52
        if touch.view == leftThumbstickView {
            let location = touch.location(in: leftThumbstickView)
            let x: Float = Float((location.x - thumbSize) / thumbSize)
            let y: Float = Float(-((location.y - thumbSize) / thumbSize))
            EmulationInput.leftThumbstick.valueChangedHandler(nil, x: x, y: y)
        } else if touch.view == rightThumbstickView {
            let location = touch.location(in: rightThumbstickView)
            let x: Float = Float((location.x - thumbSize) / thumbSize)
            let y: Float = Float(-((location.y - thumbSize) / thumbSize))
            EmulationInput.rightThumstick.valueChangedHandler(nil, x: x, y: y)
        } else if touch.view == metalInputView.metalView {
            citraWrapper.touchesMoved(point: touch.location(in: metalInputView.metalView))
        }
    }
    
    
    func configurePhysicalController(for extendedGamepad: GCExtendedGamepad) {
        extendedGamepad.buttonA.pressedChangedHandler = EmulationInput.buttonA.pressChangedHandler
        extendedGamepad.buttonB.pressedChangedHandler = EmulationInput.buttonB.pressChangedHandler
        extendedGamepad.buttonX.pressedChangedHandler = EmulationInput.buttonX.pressChangedHandler
        extendedGamepad.buttonY.pressedChangedHandler = EmulationInput.buttonY.pressChangedHandler
        
        extendedGamepad.dpad.up.pressedChangedHandler = EmulationInput.dpadUp.pressChangedHandler
        extendedGamepad.dpad.left.pressedChangedHandler = EmulationInput.dpadLeft.pressChangedHandler
        extendedGamepad.dpad.down.pressedChangedHandler = EmulationInput.dpadDown.pressChangedHandler
        extendedGamepad.dpad.right.pressedChangedHandler = EmulationInput.dpadRight.pressChangedHandler
        
        extendedGamepad.leftShoulder.valueChangedHandler = EmulationInput.buttonL.pressChangedHandler
        extendedGamepad.leftTrigger.valueChangedHandler = EmulationInput.buttonZL.pressChangedHandler
        extendedGamepad.rightShoulder.valueChangedHandler = EmulationInput.buttonR.pressChangedHandler
        extendedGamepad.rightTrigger.valueChangedHandler = EmulationInput.buttonZR.pressChangedHandler
        
        extendedGamepad.buttonOptions?.pressedChangedHandler = EmulationInput.buttonSelect.pressChangedHandler
        extendedGamepad.buttonMenu.pressedChangedHandler = EmulationInput.buttonStart.pressChangedHandler
        
        extendedGamepad.leftThumbstick.valueChangedHandler = EmulationInput.leftThumbstick.valueChangedHandler
        extendedGamepad.rightThumbstick.valueChangedHandler = EmulationInput.rightThumstick.valueChangedHandler
    }
    
    func toggleVirtualController(_ show: CGFloat) {
        [aButton, bButton, xButton, yButton].forEach { button in
            guard let button = button else {
                return
            }
            
            UIView.animate(withDuration: 1.0) {
                button.alpha = show
            }
        }
        
        
        [dpadUButton, dpadLButton, dpadDButton, dpadRButton].forEach { button in
            guard let button = button else {
                return
            }
            
            UIView.animate(withDuration: 1.0) {
                button.alpha = show
            }
        }
        
        [lButton, zlButton, rButton, zrButton, selectButton, startButton].forEach { button in
            guard let button = button else {
                return
            }
            
            UIView.animate(withDuration: 1.0) {
                button.alpha = show
            }
        }
    }
    
    
    func toggleThumbsticks(_ show: CGFloat) {
        if UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight {
            UIView.animate(withDuration: 1.0) {
                self.leftThumbstickView.alpha = show
                self.rightThumbstickView.alpha = show
            }
        }
    }
    
    
    // MARK: Run
    @objc func run() {
        citraWrapper.run()
    }
    
    
    func performanceStatisticsDidChange(_ statistics: PerformanceStatistics) {
        DispatchQueue.main.async {
            if self.emulationSpeedContainerView.alpha == 0 && self.gameFpsContainerView.alpha == 0 {
                UIView.animate(withDuration: 1.0) {
                    self.emulationSpeedContainerView.alpha = 1
                    self.gameFpsContainerView.alpha = 1
                }
            }
            
            let attributes: [NSAttributedString.Key : Any] = [
                .font : UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption1).pointSize),
                .foregroundColor : UIColor.systemGreen
            ]
            
            self.emulationSpeedLabel.attributedText = NSAttributedString(string: String(format: "%.0f%@", statistics.emulationSpeed * 100 + 0.5, "%"), attributes: attributes)
            self.gameFpsLabel.attributedText = NSAttributedString(string: String(format: "%.0f FPS", min(max(statistics.gameFps + 0.5, 0), 90)), attributes: attributes)
        }
    }
    
    
    
    
    func button(with image: UIImage?, for configuration: UIImage.SymbolConfiguration? = nil) -> UIButton {
        if #available(iOS 15, *) {
            var buttonConfiguration = UIButton.Configuration.borderless()
            if let configuration = configuration {
                buttonConfiguration.image = image?.applyingSymbolConfiguration(configuration)
                return UIButton(configuration: buttonConfiguration)
            } else {
                buttonConfiguration.image = image
                return UIButton(configuration: buttonConfiguration)
            }
        } else {
            let button = UIButton()
            button.setImage(image, for: .normal)
            return button
        }
    }
    
    
    func isLatestOS() -> Bool {
        if #available(iOS 17, *) {
             return true
        } else {
            return false
        }
    }
}
