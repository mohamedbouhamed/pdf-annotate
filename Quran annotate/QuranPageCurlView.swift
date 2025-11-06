//
//  QuranPageCurlView.swift
//  Quran annotate
//
//  Created by Macbook Air on 06/11/2025.
//

import SwiftUI
import UIKit
import PDFKit
import PencilKit

// UIPageViewController avec page curl pour le Coran
class QuranPageCurlViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    var pdfDocument: PDFDocument?
    var isLandscape: Bool = false
    var isAnnotationMode: Bool = false
    var drawings: [Int: PKDrawing] = [:]
    var onPageChanged: ((Int) -> Void)?
    var currentPageIndex: Int = 0

    init(pdfDocument: PDFDocument, isLandscape: Bool) {
        self.pdfDocument = pdfDocument
        self.isLandscape = isLandscape

        // Configuration du spine selon l'orientation
        let spineLocation: UIPageViewController.SpineLocation = isLandscape ? .mid : .min

        // IMPORTANT: transitionStyle = .pageCurl pour l'animation de livre réaliste
        super.init(
            transitionStyle: .pageCurl,  // ← C'est ici qu'on force .pageCurl !
            navigationOrientation: .horizontal,
            options: [
                .spineLocation: NSNumber(value: spineLocation.rawValue)
            ]
        )

        self.dataSource = self
        self.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }

    func goToPage(_ pageIndex: Int, animated: Bool = false) {
        guard let pdfDocument = pdfDocument,
              pageIndex >= 0,
              pageIndex < pdfDocument.pageCount else { return }

        currentPageIndex = pageIndex

        let viewControllers: [UIViewController]

        if isLandscape {
            // En paysage : 2 pages
            let adjustedIndex = (pageIndex % 2 == 0) ? pageIndex : pageIndex - 1
            viewControllers = createViewControllers(startingAt: adjustedIndex, count: 2)
        } else {
            // En portrait : 1 page
            viewControllers = createViewControllers(startingAt: pageIndex, count: 1)
        }

        guard !viewControllers.isEmpty else { return }

        setViewControllers(viewControllers, direction: .forward, animated: animated)
    }

    private func createViewControllers(startingAt index: Int, count: Int) -> [UIViewController] {
        guard let pdfDocument = pdfDocument else { return [] }

        var controllers: [UIViewController] = []

        for i in 0..<count {
            let pageIndex = index + i
            guard pageIndex < pdfDocument.pageCount,
                  let page = pdfDocument.page(at: pageIndex) else { continue }

            let pageVC = PDFPageWithAnnotationViewController(
                page: page,
                pageIndex: pageIndex,
                drawing: drawings[pageIndex] ?? PKDrawing(),
                isAnnotationMode: isAnnotationMode
            )

            pageVC.onDrawingChanged = { [weak self] drawing in
                self?.drawings[pageIndex] = drawing
            }

            controllers.append(pageVC)
        }

        return controllers
    }

    func updateOrientation(_ isLandscape: Bool) {
        guard self.isLandscape != isLandscape else { return }

        self.isLandscape = isLandscape

        // Recréer le pageViewController avec le bon spine location
        let spineLocation: UIPageViewController.SpineLocation = isLandscape ? .mid : .min

        // Note: On ne peut pas changer les options après init
        // Il faudrait recréer complètement le view controller
        // Pour l'instant, on reste sur la même page
        goToPage(currentPageIndex, animated: false)
    }

    // MARK: - UIPageViewControllerDataSource

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let pageVC = viewController as? PDFPageWithAnnotationViewController,
              let pdfDocument = pdfDocument else { return nil }

        let step = isLandscape ? 2 : 1
        let previousIndex = pageVC.pageIndex - step

        guard previousIndex >= 0 else { return nil }

        let controllers = createViewControllers(startingAt: previousIndex, count: 1)
        return controllers.first
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let pageVC = viewController as? PDFPageWithAnnotationViewController,
              let pdfDocument = pdfDocument else { return nil }

        let step = isLandscape ? 2 : 1
        let nextIndex = pageVC.pageIndex + step

        guard nextIndex < pdfDocument.pageCount else { return nil }

        let controllers = createViewControllers(startingAt: nextIndex, count: 1)
        return controllers.first
    }

    // MARK: - UIPageViewControllerDelegate

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed,
           let visibleVC = viewControllers?.first as? PDFPageWithAnnotationViewController {
            currentPageIndex = visibleVC.pageIndex
            onPageChanged?(visibleVC.pageIndex)
        }
    }
}

// ViewController pour une page PDF avec canvas d'annotation
class PDFPageWithAnnotationViewController: UIViewController {

    let pageIndex: Int
    private let pdfView: PDFView
    private let canvasView: PassthroughCanvasView
    private var drawing: PKDrawing
    private var isAnnotationMode: Bool

    var onDrawingChanged: ((PKDrawing) -> Void)?

    init(page: PDFPage, pageIndex: Int, drawing: PKDrawing, isAnnotationMode: Bool) {
        self.pageIndex = pageIndex
        self.drawing = drawing
        self.isAnnotationMode = isAnnotationMode

        // PDF View
        self.pdfView = PDFView()
        let doc = PDFDocument()
        doc.insert(page, at: 0)
        pdfView.document = doc
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.backgroundColor = .systemBackground

        // Canvas View
        self.canvasView = PassthroughCanvasView()
        canvasView.drawing = drawing
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.allowPassthrough = !isAnnotationMode

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        // Ajouter les vues
        view.addSubview(pdfView)
        view.addSubview(canvasView)

        pdfView.translatesAutoresizingMaskIntoConstraints = false
        canvasView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: view.topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            canvasView.topAnchor.constraint(equalTo: view.topAnchor),
            canvasView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Configuration du PKToolPicker natif
        if let window = view.window {
            let toolPicker = PKToolPicker.shared(for: window)
            toolPicker?.addObserver(canvasView)

            // Afficher le toolPicker si en mode annotation
            if isAnnotationMode {
                canvasView.becomeFirstResponder()
                toolPicker?.setVisible(true, forFirstResponder: canvasView)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Sauvegarder le dessin quand la page disparaît
        if !canvasView.drawing.bounds.isEmpty {
            onDrawingChanged?(canvasView.drawing)
        }
    }

    func updateAnnotationMode(_ enabled: Bool) {
        isAnnotationMode = enabled
        canvasView.allowPassthrough = !enabled

        if let window = view.window, let toolPicker = PKToolPicker.shared(for: window) {
            if enabled {
                canvasView.becomeFirstResponder()
                toolPicker.setVisible(true, forFirstResponder: canvasView)
            } else {
                toolPicker.setVisible(false, forFirstResponder: canvasView)
                canvasView.resignFirstResponder()
            }
        }
    }
}

// SwiftUI Wrapper
struct QuranPageCurlView: UIViewControllerRepresentable {
    let pdfDocument: PDFDocument
    @Binding var currentPage: Int
    @Binding var isAnnotationMode: Bool
    @Binding var isLandscape: Bool
    @Binding var drawings: [Int: PKDrawing]

    func makeUIViewController(context: Context) -> QuranPageCurlViewController {
        let vc = QuranPageCurlViewController(pdfDocument: pdfDocument, isLandscape: isLandscape)
        vc.drawings = drawings
        vc.isAnnotationMode = isAnnotationMode

        vc.onPageChanged = { pageIndex in
            DispatchQueue.main.async {
                currentPage = pageIndex
            }
        }

        vc.goToPage(currentPage, animated: false)

        return vc
    }

    func updateUIViewController(_ uiViewController: QuranPageCurlViewController, context: Context) {
        uiViewController.isAnnotationMode = isAnnotationMode
        uiViewController.updateOrientation(isLandscape)

        // Mettre à jour le mode annotation sur les pages visibles
        if let visibleVCs = uiViewController.viewControllers {
            for vc in visibleVCs {
                if let pageVC = vc as? PDFPageWithAnnotationViewController {
                    pageVC.updateAnnotationMode(isAnnotationMode)
                }
            }
        }

        // Mettre à jour la page si changée
        if uiViewController.currentPageIndex != currentPage {
            uiViewController.goToPage(currentPage, animated: true)
        }

        // Synchroniser les dessins
        drawings = uiViewController.drawings
    }
}
