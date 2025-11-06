//
//  PDFSelectionView.swift
//  Quran annotate
//
//  Created by Macbook Air on 06/11/2025.
//

import SwiftUI

struct PDFSelectionView: View {
    @Binding var selectedPDF: String?

    var body: some View {
        ZStack {
            // Fond dégradé
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                // Titre
                VStack(spacing: 10) {
                    Text("القرآن الكريم")
                        .font(.system(size: 48, weight: .bold, design: .serif))
                        .foregroundColor(.primary)

                    Text("اختر الرواية")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 60)

                Spacer()

                // Boutons de sélection
                VStack(spacing: 24) {
                    // Bouton Hafs
                    Button(action: {
                        withAnimation {
                            selectedPDF = "Quran"
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("رواية حفص")
                                    .font(.title)
                                    .fontWeight(.semibold)

                                Text("عن عاصم")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.left")
                                .font(.title3)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Bouton Qaloun
                    Button(action: {
                        withAnimation {
                            selectedPDF = "Qaloun"
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("رواية قالون")
                                    .font(.title)
                                    .fontWeight(.semibold)

                                Text("عن نافع")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.left")
                                .font(.title3)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Bouton Warsh
                    Button(action: {
                        withAnimation {
                            selectedPDF = "Warsh"
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("رواية ورش")
                                    .font(.title)
                                    .fontWeight(.semibold)

                                Text("عن نافع")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.left")
                                .font(.title3)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 32)

                Spacer()

                // Footer
                Text("مصحف للقراءة والتدوين")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 40)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

#Preview {
    PDFSelectionView(selectedPDF: .constant(nil))
}
