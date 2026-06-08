//
//  MainView.swift
//  meeco
//
//  Created by Byeongcheol Kim on 6/11/25.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome to the Main App")
                    .font(.title)
                NavigationLink("Go to Details", destination: DetailView())
            }
            .navigationTitle("Home")
        }
    }
}
