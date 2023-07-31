//
//  StereoRenderSettingView.swift
//  emuThreeDS
//
//  Created by Antique on 27/6/2023.
//

import SwiftUI

enum StereoRenderOptions : Int, CaseIterable, CustomStringConvertible, Identifiable {
    case off = 0, sideBySide = 1, anaglyph = 2, interlaced = 3, reverseInterlaced = 4, cardboardVR = 5
    
    var description: String {
        switch self {
        case .off:
            return "Off"
        case .sideBySide:
            return "Side By Side"
        case .anaglyph:
            return "Anaglyph"
        case .interlaced:
            return "Interlaced"
        case .reverseInterlaced:
            return "Reverse Interlaced"
        case .cardboardVR:
            return "Cardboard VR"
        }
    }
    
    var id: Self {
        return self
    }
}

struct StereoRenderSettingView: View {
    var impactGenerator: UIImpactFeedbackGenerator
    
    var identifier: String
    var systemName: String
    var title: String
    
    @State var selectedItem: StereoRenderOptions = .off
    var isExperimental: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            if #available(iOS 16, *) {
                Picker(selection: $selectedItem) {
                    ForEach(StereoRenderOptions.allCases, id: \.id) { stereoRenderOption in
                        Text(stereoRenderOption.description)
                    }
                } label: {
                    Label(title, systemImage: systemName)
                }
                .pickerStyle(.navigationLink)
            } else {
                Picker(selection: $selectedItem) {
                    ForEach(StereoRenderOptions.allCases, id: \.id) { stereoRenderOptions in
                        Text(stereoRenderOptions.description)
                    }
                } label: {
                    Label(title, systemImage: systemName)
                }
                .pickerStyle(.menu)
            }
            
            if isExperimental {
                Text("Experimental")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .onAppear {
            selectedItem = StereoRenderOptions(rawValue: UserDefaults.standard.integer(forKey: identifier)) ?? .off
        }
        .onChange(of: selectedItem, perform: { newValue in
            UserDefaults.standard.set(selectedItem.rawValue, forKey: identifier)
            impactGenerator.impactOccurred()
        })
    }
}
