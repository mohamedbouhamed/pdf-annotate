//
//  QuranPDFViewModel.swift
//  Quran annotate
//
//  Created by Macbook Air on 06/11/2025.
//

import Foundation
import PDFKit
import SwiftUI
import Combine

class QuranPDFViewModel: ObservableObject {
    @Published var pdfDocument: PDFDocument?
    @Published var currentPage: Int = 0
    @Published var totalPages: Int = 0
    @Published var isLandscape: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        loadPDF()
        setupOrientationObserver()
    }

    private func setupOrientationObserver() {
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateOrientation()
            }
            .store(in: &cancellables)

        // Mise à jour initiale
        updateOrientation()
    }

    private func updateOrientation() {
        let orientation = UIDevice.current.orientation
        DispatchQueue.main.async {
            self.isLandscape = orientation.isLandscape
        }
    }

    private func loadPDF() {
        guard let url = Bundle.main.url(forResource: "Quran", withExtension: "pdf") else {
            print("❌ Erreur: Impossible de trouver le fichier PDF")
            return
        }

        guard let document = PDFDocument(url: url) else {
            print("❌ Erreur: Impossible de charger le PDF")
            return
        }

        self.pdfDocument = document
        self.totalPages = document.pageCount
        print("✅ PDF chargé avec succès: \(totalPages) pages")
    }

    func goToPage(_ pageNumber: Int) {
        guard pageNumber >= 0 && pageNumber < totalPages else { return }
        currentPage = pageNumber
    }

    func nextPage() {
        // Navigation RTL: suivant = page précédente (vers la gauche)
        if currentPage > 0 {
            currentPage -= 1
        }
    }

    func previousPage() {
        // Navigation RTL: précédent = page suivante (vers la droite)
        if currentPage < totalPages - 1 {
            currentPage += 1
        }
    }
}
