//
//  PDFAnnotationView.swift
//  Quran annotate
//
//  Created by Macbook Air on 06/11/2025.
//

import SwiftUI
import PDFKit

// Vue PDF avec toolbar d'annotations complet
struct AnnotatablePDFView: UIViewRepresentable {
    let pdfDocument: PDFDocument
    @Binding var currentPage: Int
    @Binding var isAnnotationMode: Bool

    class Coordinator: NSObject, PDFViewDelegate {
        var parent: AnnotatablePDFView
        var observer: NSObjectProtocol?

        init(_ parent: AnnotatablePDFView) {
            self.parent = parent
        }

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPDFPage = pdfView.currentPage else {
                return
            }

            let index = parent.pdfDocument.index(for: currentPDFPage)
            DispatchQueue.main.async {
                self.parent.currentPage = index
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()

        // Configuration de base
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        pdfView.displaysRTL = true
        pdfView.backgroundColor = UIColor.systemBackground

        // Délégué
        pdfView.delegate = context.coordinator

        // Activer les interactions utilisateur pour les annotations
        pdfView.isUserInteractionEnabled = true

        // Observer les changements de page
        context.coordinator.observer = NotificationCenter.default.addObserver(
            forName: .PDFViewPageChanged,
            object: pdfView,
            queue: .main
        ) { notification in
            context.coordinator.pageChanged(notification)
        }

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Mettre à jour le parent dans le coordinator
        context.coordinator.parent = self

        // Activer/désactiver le mode annotation
        if #available(iOS 13.0, *) {
            // Le mode markup permet les annotations natives
            // Note: iOS PDFKit ne supporte pas directement isInMarkupMode
            // mais on peut utiliser des gestes pour ajouter des annotations
        }

        // Mettre à jour la page si nécessaire
        if let page = pdfDocument.page(at: currentPage),
           pdfView.currentPage != page {
            UIView.animate(withDuration: 0.3) {
                pdfView.go(to: page)
            }
        }
    }

    static func dismantleUIView(_ uiView: PDFView, coordinator: Coordinator) {
        if let observer = coordinator.observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// Toolbar d'annotation
struct AnnotationToolbar: View {
    @Binding var selectedTool: AnnotationTool
    @Binding var selectedColor: Color
    @Binding var isAnnotationMode: Bool

    enum AnnotationTool: String, CaseIterable {
        case highlighter = "highlighter"
        case pen = "pencil"
        case text = "text.bubble"
        case eraser = "eraser"

        var displayName: String {
            switch self {
            case .highlighter: return "تظليل"
            case .pen: return "قلم"
            case .text: return "نص"
            case .eraser: return "ممحاة"
            }
        }
    }

    let colors: [Color] = [.yellow, .green, .blue, .red, .orange, .purple]

    var body: some View {
        VStack(spacing: 0) {
            // Sélecteur d'outils
            HStack(spacing: 15) {
                ForEach(AnnotationTool.allCases, id: \.self) { tool in
                    Button(action: {
                        selectedTool = tool
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tool.rawValue)
                                .font(.title3)
                            Text(tool.displayName)
                                .font(.caption2)
                        }
                        .foregroundColor(selectedTool == tool ? .blue : .primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(selectedTool == tool ? Color.blue.opacity(0.1) : Color.clear)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Sélecteur de couleurs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(colors, id: \.self) { color in
                        Button(action: {
                            selectedColor = color
                        }) {
                            Circle()
                                .fill(color)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}
