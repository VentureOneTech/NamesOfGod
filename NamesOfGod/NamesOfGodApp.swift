//
//  NamesOfGodApp.swift
//  NamesOfGod
//
//  Created by Andre Diamand on 2024
//  Copyright © 2018-2024 Andre Diamand. All rights reserved.
//

import SwiftUI

@main
struct NamesOfGodApp: App {
    @State private var isShowingSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isShowingSplash {
                    SplashScreenView()
                        .onAppear {
                            // Mostra a splash screen por 2 segundos
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    isShowingSplash = false
                                }
                            }
                        }
                } else {
                    ContentView()
                        .transition(.opacity)
                }
            }
        }
    }
}

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            // Fundo gradiente roxo e azul
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.8), // Roxo
                    Color(red: 0.2, green: 0.4, blue: 0.9), // Azul
                    Color(red: 0.1, green: 0.2, blue: 0.6)  // Azul escuro
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: UIDevice.current.userInterfaceIdiom == .pad ? 39 : 30) {
                // Imagem da árvore da vida
                Image("arvoredavida")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 364 : 280, height: UIDevice.current.userInterfaceIdiom == .pad ? 364 : 280)
                    .clipShape(Circle())
                    .shadow(color: Color.primary.opacity(0.3), radius: 20, x: 0, y: 10)
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.3), lineWidth: 3)
                    )
                
                // App Title
                VStack(spacing: UIDevice.current.userInterfaceIdiom == .pad ? 10 : 8) {
                    Text("72 Names of God")
                        .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 42 : 32, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .shadow(color: Color.primary.opacity(0.5), radius: 3, x: 0, y: 2)
                    
                    Text("Kabbalah Power Meditation")
                        .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 23 : 18, weight: .medium, design: .serif))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: Color.primary.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                
                // Indicador de carregamento
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(UIDevice.current.userInterfaceIdiom == .pad ? 1.56 : 1.2)
            }
        }
    }
}
