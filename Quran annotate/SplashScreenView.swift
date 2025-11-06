//
//  SplashScreenView.swift
//  Quran annotate
//
//  Created by Macbook Air on 06/11/2025.
//

import SwiftUI

struct SplashScreenView: View {
    @Binding var isLoading: Bool

    var body: some View {
        ZStack {
            // Fond dégradé
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Titre
                Text("القرآن الكريم")
                    .font(.system(size: 56, weight: .bold, design: .serif))
                    .foregroundColor(.primary)

                // Indicateur de chargement
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.primary)

                Text("جاري التحميل...")
                    .font(.title3)
                    .foregroundColor(.secondary)

                Spacer()

                // Footer
                Text("مصحف للقراءة والتدوين")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 40)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            // Simuler un court délai pour afficher le splash screen
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    SplashScreenView(isLoading: .constant(true))
}
