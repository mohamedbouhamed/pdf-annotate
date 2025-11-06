//
//  AnnotationCanvasView.swift
//  Quran annotate
//
//  Created by Macbook Air on 06/11/2025.
//

import SwiftUI
import PencilKit
import PDFKit

// Canvas personnalisé qui laisse passer les touches au PDFView quand inactif
class PassthroughCanvasView: PKCanvasView {
    var allowPassthrough = true

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Si allowPassthrough est true, laisser passer les touches au view en dessous
        if allowPassthrough {
            return nil
        }
        return super.hitTest(point, with: event)
    }
}

// Vue avec support complet d'annotations via PencilKit et page curl natif
struct AnnotationCanvasView: UIViewRepresentable {
    let pdfDocument: PDFDocument
    @Binding var currentPage: Int
    @Binding var isAnnotationMode: Bool
    @Binding var isLandscape: Bool
    @Binding var drawings: [Int: PKDrawing] // Dictionnaire de dessins par page

    typealias UIViewType = UIView

    class Coordinator: NSObject {
        var parent: AnnotationCanvasView
        var pdfView: PDFView?
        var canvasView: PassthroughCanvasView?
        var toolPicker: PKToolPicker?
        var observer: NSObjectProtocol?

        init(_ parent: AnnotationCanvasView) {
            self.parent = parent
        }

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPDFPage = pdfView.currentPage else {
                return
            }

            // Sauvegarder le dessin de la page actuelle avant de changer
            if let canvasView = canvasView, !canvasView.drawing.bounds.isEmpty {
                let oldPage = parent.currentPage
                parent.drawings[oldPage] = canvasView.drawing
            }

            // Mettre à jour la page
            let index = parent.pdfDocument.index(for: currentPDFPage)
            DispatchQueue.main.async {
                self.parent.currentPage = index
                // Charger le dessin de la nouvelle page
                if let drawing = self.parent.drawings[index] {
                    self.canvasView?.drawing = drawing
                } else {
                    self.canvasView?.drawing = PKDrawing()
                }
            }
        }


    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()

        // Configuration PDFView
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true

        // Mode d'affichage selon l'orientation
        // En paysage : 2 pages côte à côte (spine au milieu)
        // En portrait : 1 page
        pdfView.displayMode = isLandscape ? .twoUp : .singlePage
        pdfView.displaysAsBook = true // Toujours en mode livre pour le bon ordre des pages

        // Configuration pour l'arabe (droite à gauche)
        // displaysRTL = false pour que swipe DROITE = avancer (comportement naturel)
        pdfView.displaysRTL = false
        pdfView.displayDirection = .horizontal

        pdfView.backgroundColor = UIColor.systemBackground
        pdfView.translatesAutoresizingMaskIntoConstraints = false

        // ACTIVER L'ANIMATION PAGE CURL NATIVE D'iOS (comme Apple Books)
        let spineLocation: UIPageViewController.SpineLocation = isLandscape ? .mid : .min
        let options: [UIPageViewController.OptionsKey: Any] = [
            .spineLocation: NSNumber(value: spineLocation.rawValue)
        ]
        pdfView.usePageViewController(true, withViewOptions: options)

        // Configuration PencilKit Canvas (par-dessus le PDF)
        let canvasView = PassthroughCanvasView()
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        canvasView.drawingPolicy = .anyInput // Permet le doigt ET l'Apple Pencil
        canvasView.allowPassthrough = !isAnnotationMode // Laisser passer quand pas en mode annotation

        // Ajouter les vues
        containerView.addSubview(pdfView)
        containerView.addSubview(canvasView)

        // Contraintes pour remplir le conteneur
        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: containerView.topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            pdfView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            canvasView.topAnchor.constraint(equalTo: containerView.topAnchor),
            canvasView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            canvasView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])

        // Configuration du PKToolPicker (la toolbar native d'iOS)
        if let window = containerView.window {
            let toolPicker = PKToolPicker.shared(for: window)
            toolPicker?.addObserver(canvasView)
            context.coordinator.toolPicker = toolPicker
        } else {
            // Si pas encore de window, on le fera dans updateUIView
            let toolPicker = PKToolPicker()
            toolPicker.addObserver(canvasView)
            context.coordinator.toolPicker = toolPicker
        }

        // Les gestes sont gérés nativement par PDFView avec usePageViewController
        // Le page curl fonctionne automatiquement

        // Stocker les références
        context.coordinator.pdfView = pdfView
        context.coordinator.canvasView = canvasView

        // Observer les changements de page
        context.coordinator.observer = NotificationCenter.default.addObserver(
            forName: .PDFViewPageChanged,
            object: pdfView,
            queue: .main
        ) { notification in
            context.coordinator.pageChanged(notification)
        }

        // Aller à la page initiale
        if let page = pdfDocument.page(at: currentPage) {
            pdfView.go(to: page)
        }

        // Charger le dessin initial si existant
        if let drawing = drawings[currentPage] {
            canvasView.drawing = drawing
        }

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let pdfView = context.coordinator.pdfView,
              let canvasView = context.coordinator.canvasView else {
            return
        }

        // Mettre à jour le parent dans le coordinator
        context.coordinator.parent = self

        // S'assurer que le toolPicker est initialisé avec la window
        if context.coordinator.toolPicker == nil, let window = uiView.window {
            let toolPicker = PKToolPicker.shared(for: window)
            toolPicker?.addObserver(canvasView)
            context.coordinator.toolPicker = toolPicker
        }

        // Afficher/masquer le PKToolPicker natif selon le mode annotation
        if let toolPicker = context.coordinator.toolPicker {
            if isAnnotationMode {
                canvasView.becomeFirstResponder()
                toolPicker.setVisible(true, forFirstResponder: canvasView)
            } else {
                toolPicker.setVisible(false, forFirstResponder: canvasView)
                canvasView.resignFirstResponder()
            }
        }

        // Activer/désactiver le mode annotation
        canvasView.allowPassthrough = !isAnnotationMode // Laisser passer les gestes au PDF si pas en mode annotation
        canvasView.drawingPolicy = isAnnotationMode ? .anyInput : .pencilOnly

        // Mettre à jour le mode d'affichage selon l'orientation
        let newDisplayMode: PDFDisplayMode = isLandscape ? .twoUp : .singlePage
        if pdfView.displayMode != newDisplayMode {
            // Sauvegarder la page actuelle avant de changer le mode
            let savedPageIndex = pdfDocument.index(for: pdfView.currentPage!)

            pdfView.displayMode = newDisplayMode
            pdfView.displaysAsBook = true // Toujours en mode livre

            // Reconfigurer usePageViewController avec le bon spine location
            let spineLocation: UIPageViewController.SpineLocation = isLandscape ? .mid : .min
            let options: [UIPageViewController.OptionsKey: Any] = [
                .spineLocation: NSNumber(value: spineLocation.rawValue)
            ]
            pdfView.usePageViewController(true, withViewOptions: options)

            // Restaurer la page actuelle (rester sur la même page)
            if let page = pdfDocument.page(at: savedPageIndex) {
                pdfView.go(to: page)
            }
        }

        // Mettre à jour la page si nécessaire
        if let page = pdfDocument.page(at: currentPage),
           pdfView.currentPage != page {
            // Sauvegarder le dessin actuel
            if !canvasView.drawing.bounds.isEmpty {
                let oldIndex = pdfDocument.index(for: pdfView.currentPage!)
                drawings[oldIndex] = canvasView.drawing
            }

            // Changer de page avec animation
            UIView.animate(withDuration: 0.3) {
                pdfView.go(to: page)
            }

            // Charger le nouveau dessin
            if let drawing = drawings[currentPage] {
                canvasView.drawing = drawing
            } else {
                canvasView.drawing = PKDrawing()
            }
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        if let observer = coordinator.observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

