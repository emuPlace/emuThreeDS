//
//  ResolutionFactorSettingView.swift
//  emuThreeDS
//
//  Created by Antique on 27/6/2023.
//

import SwiftUI

enum ResolutionFactors : Int, CaseIterable, CustomStringConvertible, Identifiable {
    case one = 1, two = 2, three = 3, four = 4, five = 5, six = 6, seven = 7, eight = 8, nine = 9, ten = 10
    
    var description: String {
        switch self {
        case .one:
            return "1"
        case .two:
            return "2"
        case .three:
            return "3"
        case .four:
            return "4"
        case .five:
            return "5"
        case .six:
            return "6"
        case .seven:
            return "7"
        case .eight:
            return "8"
        case .nine:
            return "9"
        case .ten:
            return "10"
        }
    }
    
    var id: Self {
        return self
    }
}

struct ResolutionFactorSettingView: View {
    var impactGenerator: UIImpactFeedbackGenerator
    
    var identifier: String
    var systemName: String
    var title: String
    
    @State var selectedItem: ResolutionFactors = .one
    
    var body: some View {
        VStack(alignment: .leading) {
            if #available(iOS 16, *) {
                Picker(selection: $selectedItem) {
                    ForEach(ResolutionFactors.allCases, id: \.id) { resolution in
                        Text("\(400 * resolution.rawValue)p, \(320 * resolution.rawValue)p x \(240 * resolution.rawValue)p")
                    }
                } label: {
                    Label(title, systemImage: systemName)
                }
                .pickerStyle(.navigationLink)
            } else {
                Picker(selection: $selectedItem) {
                    ForEach(ResolutionFactors.allCases, id: \.id) { resolution in
                        Text("\(400 * resolution.rawValue)p, \(320 * resolution.rawValue)p x \(240 * resolution.rawValue)p")
                    }
                } label: {
                    Label(title, systemImage: systemName)
                }
                .pickerStyle(.menu)
            }
        }
        .onAppear {
            selectedItem = ResolutionFactors(rawValue: UserDefaults.standard.integer(forKey: identifier)) ?? .one
        }
        .onChange(of: selectedItem, perform: { newValue in
            UserDefaults.standard.set(selectedItem.rawValue, forKey: identifier)
            impactGenerator.impactOccurred()
        })
    }
}
