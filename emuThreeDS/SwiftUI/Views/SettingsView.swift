//
//  SettingsView.swift
//  emuThreeDS
//
//  Created by Antique on 27/6/2023.
//

import Foundation
import SwiftUI

/*
 
 WHY MUST SWIFTUI SUCK SO MUCH FOR BACKWARDS COMPATIBILITY
 or am i dumb?
 - dev
 
 */

struct SettingsView: View {
    var impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        NavigationView {
            List(content: {
                if #available(iOS 15, *) {
                    Section {
                        ToggleSettingView(identifier: "use_cpu_jit", systemName: "cpu", title: "Enable JIT")
                        ToggleSettingView(identifier: "use_hle", systemName: "brain", title: "Enable HLE")
                        StepperSettingView(impactGenerator: impactGenerator, identifier: "cpu_clock_percentage", systemName: "percent", title: "CPU Clock", minValue: 5, maxValue: 400)
                        ToggleSettingView(identifier: "is_new_3ds", systemName: "star", title: "Use New 3DS")
                        ToggleSettingView(identifier: "enable_logging", systemName: "ladybug", title: "Enable Logging")
                    } header: {
                        Text("Core")
                    }
                    .headerProminence(.increased)
                    
                    Section {
                        ToggleSettingView(identifier: "async_shader_compilation", systemName: "square.stack.3d.down.forward", title: "Async Shader Compilation")
                        ToggleSettingView(identifier: "async_presentation", systemName: "videoprojector", title: "Async Presentation")
                        ToggleSettingView(identifier: "use_hw_shader", systemName: "square.stack.3d.down.forward", title: "Enable HW Shaders")
                        ToggleSettingView(identifier: "use_vsync_new", systemName: "clock.arrow.2.circlepath", title: "Enable VSync New")
                        ToggleSettingView(identifier: "shaders_accurate_mul", systemName: "target", title: "Shaders Accurate Mul")
                        ToggleSettingView(identifier: "use_shader_jit", systemName: "bolt.badge.clock", title: "Enable Shader JIT")
                        ResolutionFactorSettingView(impactGenerator: impactGenerator, identifier: "resolution_factor", systemName: "aspectratio", title: "Resolution")
                        LayoutOptionSettingView(impactGenerator: impactGenerator, identifier: "portrait_layout_option", systemName: "iphone", title: "Portrait Layout")
                        LayoutOptionSettingView(impactGenerator: impactGenerator, identifier: "landscape_layout_option", systemName: "iphone.landscape", title: "Landscape Layout")
                    } header: {
                        Text("Renderer")
                    }
                    .headerProminence(.increased)
                    
                    Section {
                        ToggleSettingView(identifier: "swap_screen", systemName: "rectangle.2.swap", title: "Swap Screen")
                        ToggleSettingView(identifier: "upright_screen", systemName: "leaf", title: "Upright Screen")
                        StereoRenderSettingView(impactGenerator: impactGenerator, identifier: "render_3d", systemName: "view.3d", title: "Stereo Render")
                        StepperSettingView(impactGenerator: impactGenerator, identifier: "factor_3d", systemName: "textformat.123", title: "3D Factor", minValue: 0, maxValue: 100)
                        ToggleSettingView(identifier: "dump_textures", systemName: "arrow.down.doc", title: "Dump Textures")
                        ToggleSettingView(identifier: "custom_textures", systemName: "doc.text.magnifyingglass", title: "Custom Textures")
                        ToggleSettingView(identifier: "preload_textures", systemName: "arrow.down.doc", title: "Preload Textures")
                        ToggleSettingView(identifier: "async_custom_loading", systemName: "leaf", title: "Async Custom Loading")
                    } header: {
                        Text("Renderer (cont.)")
                    }
                    .headerProminence(.increased)
                } else {
                    Section {
                        ToggleSettingView(identifier: "use_cpu_jit", systemName: "cpu", title: "Enable JIT")
                        ToggleSettingView(identifier: "use_hle", systemName: "brain", title: "Enable HLE")
                        StepperSettingView(impactGenerator: impactGenerator, identifier: "cpu_clock_percentage", systemName: "percent", title: "CPU Clock", minValue: 5, maxValue: 400)
                        ToggleSettingView(identifier: "is_new_3ds", systemName: "star", title: "Use New 3DS")
                        ToggleSettingView(identifier: "enable_logging", systemName: "ladybug", title: "Enable Logging")
                    } header: {
                        Text("Core")
                    }
                    
                    Section {
                        ToggleSettingView(identifier: "async_shader_compilation", systemName: "square.stack.3d.down.forward", title: "Async Shader Compilation")
                        ToggleSettingView(identifier: "async_presentation", systemName: "videoprojector", title: "Async Presentation")
                        ToggleSettingView(identifier: "use_hw_shader", systemName: "square.stack.3d.down.forward", title: "Enable HW Shaders")
                        ToggleSettingView(identifier: "use_vsync_new", systemName: "clock.arrow.2.circlepath", title: "Enable VSync New")
                        ToggleSettingView(identifier: "shaders_accurate_mul", systemName: "target", title: "Shaders Accurate Mul")
                        ToggleSettingView(identifier: "use_shader_jit", systemName: "bolt.badge.clock", title: "Enable Shader JIT")
                        ResolutionFactorSettingView(impactGenerator: impactGenerator, identifier: "resolution_factor", systemName: "aspectratio", title: "Resolution")
                        LayoutOptionSettingView(impactGenerator: impactGenerator, identifier: "portrait_layout_option", systemName: "iphone", title: "Portrait Layout")
                        LayoutOptionSettingView(impactGenerator: impactGenerator, identifier: "landscape_layout_option", systemName: "iphone.landscape", title: "Landscape Layout")
                    } header: {
                        Text("Renderer")
                    }
                    
                    Section {
                        ToggleSettingView(identifier: "swap_screen", systemName: "rectangle.2.swap", title: "Swap Screen")
                        ToggleSettingView(identifier: "upright_screen", systemName: "leaf", title: "Upright Screen")
                        StereoRenderSettingView(impactGenerator: impactGenerator, identifier: "render_3d", systemName: "view.3d", title: "Stereo Render")
                        StepperSettingView(impactGenerator: impactGenerator, identifier: "factor_3d", systemName: "textformat.123", title: "3D Factor", minValue: 0, maxValue: 100)
                        ToggleSettingView(identifier: "dump_textures", systemName: "arrow.down.doc", title: "Dump Textures")
                        ToggleSettingView(identifier: "custom_textures", systemName: "doc.text.magnifyingglass", title: "Custom Textures")
                        ToggleSettingView(identifier: "preload_textures", systemName: "arrow.down.doc", title: "Preload Textures")
                        ToggleSettingView(identifier: "async_custom_loading", systemName: "leaf", title: "Async Custom Loading")
                    } header: {
                        Text("Renderer (cont.)")
                    }
                }
            })
            .navigationTitle("Settings")
        }
        .onAppear {
            if !UserDefaults.standard.bool(forKey: "configuredSettings-1065-3") {
                // Core
                UserDefaults.standard.set(false, forKey: "use_cpu_jit")
                UserDefaults.standard.set(true, forKey: "use_hle")
                UserDefaults.standard.set(100, forKey: "cpu_clock_percentage")
                UserDefaults.standard.set(true, forKey: "is_new_3ds")
                UserDefaults.standard.setValue(true, forKey: "enable_logging")
                
                // Renderer
                UserDefaults.standard.set(false, forKey: "async_shader_compilation")
                UserDefaults.standard.set(true, forKey: "async_presentation")
                UserDefaults.standard.set(true, forKey: "use_hw_shader")
                UserDefaults.standard.setValue(true, forKey: "use_vsync_new")
                UserDefaults.standard.setValue(true, forKey: "shaders_accurate_mul")
                UserDefaults.standard.setValue(true, forKey: "use_shader_jit")
                UserDefaults.standard.set(2, forKey: "resolution_factor")
                UserDefaults.standard.set(5, forKey: "portrait_layout_option")
                UserDefaults.standard.set(6, forKey: "landscape_layout_option")
                
                UserDefaults.standard.set(false, forKey: "swap_screen")
                UserDefaults.standard.set(false, forKey: "upright_screen")
                
                UserDefaults.standard.setValue(0, forKey: "render_3d")
                UserDefaults.standard.setValue(0, forKey: "factor_3d")
                UserDefaults.standard.setValue(false, forKey: "dump_textures")
                UserDefaults.standard.setValue(false, forKey: "custom_textures")
                UserDefaults.standard.setValue(false, forKey: "async_custom_loading")
                
                UserDefaults.standard.set(true, forKey: "configuredSettings-1065-3")
            }
        }
    }
}
