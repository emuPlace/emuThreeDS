//
//  StepperSettingView.swift
//  emuThreeDS
//
//  Created by Antique on 27/6/2023.
//

import SwiftUI

struct StepperSettingView: View {
    var impactGenerator: UIImpactFeedbackGenerator
    
    var identifier: String
    var systemName: String
    var title: String

    @State var value: Int = 100
    var minValue: Int = 0
    var maxValue: Int = 100
    
    var isExperimental: Bool = false
    
    var body: some View {
        VStack {
            Stepper(value: $value, in: minValue...maxValue, step: 5) {
                HStack {
                    VStack(alignment: .leading) {
                        Label(title, systemImage: systemName)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("\(value)%")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if isExperimental {
                Text("Experimental")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .onAppear {
            let percentage = UserDefaults.standard.integer(forKey: identifier)
            value = percentage == 0 ? 100 : percentage
        }
        .onChange(of: value) { newValue in
            UserDefaults.standard.set(newValue, forKey: identifier)
            impactGenerator.impactOccurred()
        }
    }
}
