//
//  SplashView.swift
//  meeco
//
//  Created by Byeongcheol Kim on 6/11/25.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea()
            VStack {
                Image(systemName: "bolt.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
                Text("Meeco")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .bold()
            }
        }
    }
}
