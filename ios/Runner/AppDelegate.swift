import Flutter
import UIKit
import PDFKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    private var pdfDocument: PDFDocument?
    private let channelName = "pdf_renderer"
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let pdfChannel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
        
        pdfChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            guard let self = self else { return }
            
            switch call.method {
            case "loadPdfFromUrl":
                if let args = call.arguments as? [String: Any],
                   let url = args["url"] as? String {
                    self.loadPdfFromUrl(url: url, result: result)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "URL is required", details: nil))
                }
                
            case "renderPdfPage":
                if let args = call.arguments as? [String: Any],
                   let pageNumber = args["pageNumber"] as? Int,
                   let width = args["width"] as? Double,
                   let height = args["height"] as? Double {
                    self.renderPdfPage(pageNumber: pageNumber, width: width, height: height, result: result)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Page number, width, and height are required", details: nil))
                }
                
            case "disposePdf":
                self.disposePdf()
                result(nil)
                
            case "enableSecurityFeatures":
                self.enableSecurityFeatures()
                result(nil)
                
            case "disableSecurityFeatures":
                self.disableSecurityFeatures()
                result(nil)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func loadPdfFromUrl(url: String, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            do {
                self.pdfDocument = nil
                
                guard let pdfURL = URL(string: url) else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "INVALID_URL", message: "Invalid URL format", details: nil))
                    }
                    return
                }
                
                let data = try Data(contentsOf: pdfURL)
                
                guard let document = PDFDocument(data: data) else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "PDF_PARSE_ERROR", message: "Failed to parse PDF", details: nil))
                    }
                    return
                }
                
                self.pdfDocument = document
                
                DispatchQueue.main.async {
                    result([
                        "totalPages": document.pageCount,
                        "success": true
                    ])
                }
                
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "PDF_LOAD_ERROR", message: "Failed to load PDF: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    private func renderPdfPage(pageNumber: Int, width: Double, height: Double, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            guard let document = self.pdfDocument else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "PDF_NOT_LOADED", message: "PDF not loaded", details: nil))
                }
                return
            }
            
            guard pageNumber >= 0 && pageNumber < document.pageCount else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "INVALID_PAGE", message: "Invalid page number", details: nil))
                }
                return
            }
            
            guard let page = document.page(at: pageNumber) else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "PAGE_ERROR", message: "Failed to get page", details: nil))
                }
                return
            }
            
            let bounds = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
            
            let image = renderer.image { context in
                UIColor.white.set()
                context.fill(CGRect(x: 0, y: 0, width: width, height: height))
                
                context.cgContext.translateBy(x: 0, y: height)
                context.cgContext.scaleBy(x: 1.0, y: -1.0)
                
                let scaleX = width / bounds.width
                let scaleY = height / bounds.height
                let scale = min(scaleX, scaleY)
                
                let scaledWidth = bounds.width * scale
                let scaledHeight = bounds.height * scale
                let offsetX = (width - scaledWidth) / 2
                let offsetY = (height - scaledHeight) / 2
                
                context.cgContext.translateBy(x: offsetX, y: offsetY)
                context.cgContext.scaleBy(x: scale, y: scale)
                
                page.draw(with: .mediaBox, to: context.cgContext)
            }
            
            guard let imageData = image.pngData() else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "IMAGE_ERROR", message: "Failed to create image data", details: nil))
                }
                return
            }
            
            DispatchQueue.main.async {
                result(FlutterStandardTypedData(bytes: imageData))
            }
        }
    }
    
    private func disposePdf() {
        pdfDocument = nil
    }
    
    private func enableSecurityFeatures() {
        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(
                forName: UIApplication.userDidTakeScreenshotNotification,
                object: nil,
                queue: .main
            ) { _ in
                self.showSecurityAlert()
            }
            
            NotificationCenter.default.addObserver(
                forName: UIScreen.capturedDidChangeNotification,
                object: nil,
                queue: .main
            ) { _ in
                if UIScreen.main.isCaptured {
                    self.showSecurityAlert()
                }
            }
        }
    }
    
    private func disableSecurityFeatures() {
        DispatchQueue.main.async {
            NotificationCenter.default.removeObserver(self, name: UIApplication.userDidTakeScreenshotNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIScreen.capturedDidChangeNotification, object: nil)
        }
    }
    
    private func showSecurityAlert() {
        guard let controller = window?.rootViewController else { return }
        
        let alert = UIAlertController(
            title: "Security Alert",
            message: "Screenshots and screen recording are disabled for this content.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        controller.present(alert, animated: true)
    }
}
