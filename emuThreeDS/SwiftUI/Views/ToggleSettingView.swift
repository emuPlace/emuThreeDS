//
//  ToggleSettingView.swift
//  emuThreeDS
//
//  Created by Antique on 27/6/2023.
//

import SwiftUI

struct ToggleSettingView: View {
    var impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    var identifier: String
    var systemName: String
    var title: String
    
    @State var isOn: Bool = false
    var isExperimental: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Toggle(isOn: $isOn) {
                Label(title, systemImage: systemName)
            }
            
            if isExperimental {
                Text("Experimental")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .onChange(of: isOn) { newValue in
            UserDefaults.standard.set(newValue, forKey: identifier)
            impactGenerator.impactOccurred()
        }
        .onAppear {
            isOn = UserDefaults.standard.bool(forKey: identifier)
        }
    }
}
