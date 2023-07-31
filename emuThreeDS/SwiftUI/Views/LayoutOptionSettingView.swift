//
//  LayoutOptionSettingView.swift
//  emuThreeDS
//
//  Created by Antique on 27/6/2023.
//

import SwiftUI

enum LayoutOptions : Int, CaseIterable, CustomStringConvertible, Identifiable {
    case defaultOption = 0, singleScreen = 1, largeScreen = 2, sideScreen = 3, mobilePortrait = 5, mobileLandscape = 6
    
    var description: String {
        switch self {
        case .defaultOption:
            return "Default"
        case .singleScreen:
            return "Single Screen"
        case .largeScreen:
            return "Large Screen"
        case .sideScreen:
            return "Side Screen"
        case .mobilePortrait:
            return "Portrait"
        case .mobileLandscape:
            return "Landscape"
        }
    }
    
    var id: Self {
        return self
    }
}

struct LayoutOptionSettingView: View {
    var impactGenerator: UIImpactFeedbackGenerator
    
    var identifier: String
    var systemName: String
    var title: String
    
    @State var selectedItem: LayoutOptions = .defaultOption
    var isExperimental: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            if #available(iOS 16, *) {
                Picker(selection: $selectedItem) {
                    ForEach(LayoutOptions.allCases, id: \.id) { layoutOption in
                        Text(layoutOption.description)
                    }
                } label: {
                    Label(title, systemImage: systemName)
                }
                .pickerStyle(.navigationLink)
            } else {
                Picker(selection: $selectedItem) {
                    ForEach(LayoutOptions.allCases, id: \.id) { layoutOption in
                        Text(layoutOption.description)
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
            selectedItem = LayoutOptions(rawValue: UserDefaults.standard.integer(forKey: identifier)) ?? .defaultOption
        }
        .onChange(of: selectedItem, perform: { newValue in
            UserDefaults.standard.set(selectedItem.rawValue, forKey: identifier)
            impactGenerator.impactOccurred()
        })
    }
}
