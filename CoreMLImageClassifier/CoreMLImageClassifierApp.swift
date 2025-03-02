//
//  CoreMLImageClassifierApp.swift
//  CoreMLImageClassifier
//
//  Created by Joanna Kang on 21/02/2025.
//

import SwiftUI

@main
struct CoreMLImageClassifierApp: App {
    var body: some Scene {
        WindowGroup{
            TabView {
                ContentView()
                    .tabItem{
                        Label("Home", systemImage: "house.fill")
                    }
                VisionView()
                    .tabItem{
                        Label("Vision", systemImage: "photo")
                    }
            }
        }
    }
}
