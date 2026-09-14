import Flutter
import UIKit
import AVFoundation
import PhotosUI
import Vision
import AudioToolbox

public class SwiftQrscanPlugin: NSObject, FlutterPlugin, AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    /// Result of the in-flight `scan` / `scan_photo` call. These present UI and complete later,
    /// so only one may run at a time; other methods complete immediately with their own result.
    private var pendingResult: FlutterResult?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var scanWindowView: UIView?
    private var isScanning = false
    private let sessionQueue = DispatchQueue(label: "qrscan_plus.capture_session")

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "qr_scan", binaryMessenger: registrar.messenger())
        let instance = SwiftQrscanPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "generate_barcode":
            generateBarcode(call, result: result)
        case "scan_bytes":
            scanBytes(call, result: result)
        case "scan_path":
            scanPath(call, result: result)
        case "scan_photo", "scan":
            guard pendingResult == nil else {
                result(FlutterError(code: "BUSY", message: "A scan is already in progress.", details: nil))
                return
            }
            pendingResult = result
            if call.method == "scan" {
                checkCameraPermission()
            } else {
                openPhotoLibrary()
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Completes the pending `scan` / `scan_photo` call exactly once.
    private func finish(_ value: Any?) {
        let result = pendingResult
        pendingResult = nil
        result?(value)
    }

    // MARK: - QR Code Generation
    private func generateBarcode(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [:]

        guard let code = arguments["code"] as? String, !code.isEmpty else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing 'code'", details: nil))
            return
        }

        guard let data = code.data(using: .utf8) else {
            result(FlutterError(code: "ENCODING_ERROR", message: "Unable to encode 'code'", details: nil))
            return
        }

        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else {
            result(FlutterError(code: "FILTER_ERROR", message: "Unable to create QR filter", details: nil))
            return
        }

        qrFilter.setValue(data, forKey: "inputMessage")
        qrFilter.setValue("M", forKey: "inputCorrectionLevel")

        guard let ciImage = qrFilter.outputImage else {
            result(FlutterError(code: "IMAGE_ERROR", message: "Failed to generate QR image", details: nil))
            return
        }

        // Nearest-neighbour sampling keeps module edges sharp. Render through a CIContext because a
        // CIImage-backed UIImage has no bitmap, so pngData() can return nil for it.
        let scale = 400.0 / ciImage.extent.height
        let scaledImage = ciImage.samplingNearest().transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = CIContext().createCGImage(scaledImage, from: scaledImage.extent),
              let byteArray = UIImage(cgImage: cgImage).pngData() else {
            result(FlutterError(code: "CONVERSION_ERROR", message: "Failed to convert image to PNG", details: nil))
            return
        }

        result(FlutterStandardTypedData(bytes: byteArray))
    }

    // MARK: - Photo Scanning
    private func openPhotoLibrary() {
        guard let topViewController = currentViewController() else {
            finish(FlutterError(code: "UNAVAILABLE", message: "View controller unavailable", details: nil))
            return
        }

        // Both pickers run out of process, so no photo library permission is needed.
        if #available(iOS 14, *) {
            var configuration = PHPickerConfiguration()
            configuration.filter = .images
            configuration.selectionLimit = 1
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            topViewController.present(picker, animated: true)
        } else {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
            topViewController.present(picker, animated: true)
        }
    }

    private func scanBytes(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [:]
        guard let typedData = arguments["bytes"] as? FlutterStandardTypedData else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing 'bytes'", details: nil))
            return
        }

        guard let image = UIImage(data: typedData.data),
              let ciImage = CIImage(image: image) else {
            result(FlutterError(code: "INVALID_IMAGE", message: "Failed to decode image bytes", details: nil))
            return
        }

        detectBarcode(ciImage, completion: result)
    }

    private func scanPath(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [:]
        guard let path = arguments["path"] as? String, !path.isEmpty else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing 'path'", details: nil))
            return
        }

        let fileURL: URL
        if path.hasPrefix("file://"), let url = URL(string: path) {
            fileURL = url
        } else {
            fileURL = URL(fileURLWithPath: path)
        }

        guard let ciImage = CIImage(contentsOf: fileURL) else {
            result(FlutterError(code: "INVALID_IMAGE", message: "Failed to load image from path", details: nil))
            return
        }

        detectBarcode(ciImage, completion: result)
    }

    // MARK: - Camera Scanning
    private func checkCameraPermission() {
        let permissionDenied = FlutterError(code: "PERMISSION_DENIED",
                                            message: "Camera permission denied",
                                            details: nil)

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCameraScan()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCameraScan()
                    } else {
                        self?.finish(permissionDenied)
                    }
                }
            }
        default:
            finish(permissionDenied)
        }
    }

    private func setupCameraScan() {
        guard let viewController = currentViewController() else {
            finish(FlutterError(code: "UNAVAILABLE",
                                message: "View controller unavailable",
                                details: nil))
            return
        }

        let session = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              session.canAddInput(videoInput) else {
            finish(FlutterError(code: "SETUP_FAILED",
                                message: "Failed to setup camera",
                                details: nil))
            return
        }
        session.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        guard session.canAddOutput(metadataOutput) else {
            finish(FlutterError(code: "SETUP_FAILED",
                                message: "Failed to setup metadata output",
                                details: nil))
            return
        }
        session.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]

        // Create container view
        let scanView = UIView(frame: viewController.view.bounds)
        scanView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scanView.backgroundColor = .black

        // Setup preview layer
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = scanView.layer.bounds
        preview.videoGravity = .resizeAspectFill
        scanView.layer.addSublayer(preview)

        // Add close button below the status bar / Dynamic Island
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.addTarget(self, action: #selector(closeScanner), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        scanView.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: scanView.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            closeButton.topAnchor.constraint(equalTo: scanView.safeAreaLayoutGuide.topAnchor, constant: 8),
        ])

        viewController.view.addSubview(scanView)
        captureSession = session
        previewLayer = preview
        scanWindowView = scanView
        isScanning = true

        // startRunning() blocks, so keep it off the main thread.
        sessionQueue.async {
            session.startRunning()
        }
    }

    @objc private func closeScanner() {
        cleanUpScan()
        finish(nil)
    }

    private func cleanUpScan() {
        isScanning = false
        let session = captureSession
        sessionQueue.async {
            session?.stopRunning()
        }
        previewLayer?.removeFromSuperlayer()
        scanWindowView?.removeFromSuperview()
        captureSession = nil
        previewLayer = nil
        scanWindowView = nil
    }

    private func currentViewController() -> UIViewController? {
        let activeScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }

        let keyWindow = activeScene?.windows.first(where: { $0.isKeyWindow })
        var top = keyWindow?.rootViewController

        while let presented = top?.presentedViewController {
            top = presented
        }

        if let nav = top as? UINavigationController {
            return nav.visibleViewController ?? nav
        }
        if let tab = top as? UITabBarController {
            return tab.selectedViewController ?? tab
        }
        return top
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    public func metadataOutput(_ output: AVCaptureMetadataOutput,
                               didOutput metadataObjects: [AVMetadataObject],
                               from connection: AVCaptureConnection) {
        guard isScanning,
              let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else {
            return
        }

        // Vibrate on success
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

        // Clean up and return result
        cleanUpScan()
        finish(stringValue)
    }

    // MARK: - Image Picker Delegate (iOS 13)
    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage,
              let ciImage = CIImage(image: image) else {
            finish(FlutterError(code: "INVALID_IMAGE", message: "Failed to process selected image", details: nil))
            return
        }

        detectBarcode(ciImage) { [weak self] value in
            self?.finish(value)
        }
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        finish(nil)
    }

    // MARK: - QR Code Detection
    /// Detects barcodes off the main thread and calls `completion` on the main thread with the
    /// first payload, `nil` when none is found, or a `FlutterError`.
    private func detectBarcode(_ image: CIImage, completion: @escaping (Any?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let request = VNDetectBarcodesRequest()
            let handler = VNImageRequestHandler(ciImage: image)
            let value: Any?
            do {
                try handler.perform([request])
                value = request.results?.compactMap { $0.payloadStringValue }.first
            } catch {
                value = FlutterError(code: "DETECTION_ERROR", message: error.localizedDescription, details: nil)
            }
            DispatchQueue.main.async {
                completion(value)
            }
        }
    }
}

// MARK: - PHPicker Delegate (iOS 14+)
@available(iOS 14, *)
extension SwiftQrscanPlugin: PHPickerViewControllerDelegate {
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider else {
            finish(nil)
            return
        }

        guard provider.canLoadObject(ofClass: UIImage.self) else {
            finish(FlutterError(code: "INVALID_IMAGE", message: "Selected item is not an image", details: nil))
            return
        }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard let image = object as? UIImage, let ciImage = CIImage(image: image) else {
                    self.finish(FlutterError(code: "INVALID_IMAGE",
                                             message: error?.localizedDescription ?? "Failed to process selected image",
                                             details: nil))
                    return
                }
                self.detectBarcode(ciImage) { value in
                    self.finish(value)
                }
            }
        }
    }
}
