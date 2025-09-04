//
//  ContentView.swift
//  NamesOfGod
//
//  Created by Andre Diamand on 2024
//  Copyright © 2018-2024 Andre Diamand. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var namesViewModel = NamesOfGodViewModel()
    
    var body: some View {
        ZStack {
            // Background adaptativo para modo dark/light
            Color(uiColor: UIColor.systemBackground)
                .ignoresSafeArea()
            
            // View principal dos nomes
            NamesOfGodView(viewModel: namesViewModel)
        }
        // .preferredColorScheme(.light) // Removido para permitir modo dark automático
    }
}

#Preview {
    ContentView()
}
