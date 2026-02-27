import Flutter
import UIKit
import AVFoundation
import Photos
import Vision
import AudioToolbox

public class SwiftQrscanPlugin: NSObject, FlutterPlugin, AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private var result: FlutterResult?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var scanWindowView: UIView?
    private var isScanning = false
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "qr_scan", binaryMessenger: registrar.messenger())
        let instance = SwiftQrscanPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.result = result
        
        switch call.method {
        case "generate_barcode":
            generateBarcode(call)
        case "scan_bytes":
            scanBytes(call)
        case "scan_path":
            scanPath(call)
        case "scan_photo":
            checkPhotoPermission()
        case "scan":
            checkCameraPermission()
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - QR Code Generation
    private func generateBarcode(_ call: FlutterMethodCall) {
        let arguments = call.arguments as? [String: Any] ?? [:]
        
        guard let code = arguments["code"] as? String else {
            result?(FlutterError(code: "INVALID_ARGUMENT", message: "Missing 'code'", details: nil))
            return
        }
        
        guard let data = code.data(using: .utf8) else {
            result?(FlutterError(code: "ENCODING_ERROR", message: "Unable to encode 'code'", details: nil))
            return
        }
        
        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else {
            result?(FlutterError(code: "FILTER_ERROR", message: "Unable to create QR filter", details: nil))
            return
        }
        
        qrFilter.setValue(data, forKey: "inputMessage")
        qrFilter.setValue("M", forKey: "inputCorrectionLevel")
        
        guard let ciImage = qrFilter.outputImage else {
            result?(FlutterError(code: "IMAGE_ERROR", message: "Failed to generate QR image", details: nil))
            return
        }
        
        let scale = 400.0 / ciImage.extent.height
        let transformedImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let uiImage = UIImage(ciImage: transformedImage)
        
        guard let byteArray = uiImage.pngData() else {
            result?(FlutterError(code: "CONVERSION_ERROR", message: "Failed to convert image to PNG", details: nil))
            return
        }
        
        result?(byteArray)
    }
    
    // MARK: - Photo Scanning
    private func checkPhotoPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized, .limited:
            openPhotoLibrary()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                if status == .authorized || status == .limited {
                    DispatchQueue.main.async {
                        self?.openPhotoLibrary()
                    }
                } else {
                    self?.result?(FlutterError(code: "PERMISSION_DENIED", message: "Photo library permission denied", details: nil))
                }
            }
        default:
            result?(FlutterError(code: "PERMISSION_DENIED", message: "Photo library permission denied", details: nil))
        }
    }
    
    private func openPhotoLibrary() {
        guard let topViewController = currentViewController() else {
            result?(FlutterError(code: "UNAVAILABLE", message: "View controller unavailable", details: nil))
            return
        }

        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        topViewController.present(picker, animated: true)
    }

    private func scanBytes(_ call: FlutterMethodCall) {
        let arguments = call.arguments as? [String: Any] ?? [:]
        guard let typedData = arguments["bytes"] as? FlutterStandardTypedData else {
            result?(FlutterError(code: "INVALID_ARGUMENT", message: "Missing 'bytes'", details: nil))
            return
        }

        guard let image = UIImage(data: typedData.data),
              let ciImage = CIImage(image: image) else {
            result?(FlutterError(code: "INVALID_IMAGE", message: "Failed to decode image bytes", details: nil))
            return
        }

        detectBarcode(ciImage)
    }

    private func scanPath(_ call: FlutterMethodCall) {
        let arguments = call.arguments as? [String: Any] ?? [:]
        guard let path = arguments["path"] as? String, !path.isEmpty else {
            result?(FlutterError(code: "INVALID_ARGUMENT", message: "Missing 'path'", details: nil))
            return
        }

        let fileURL: URL
        if path.hasPrefix("file://"), let url = URL(string: path) {
            fileURL = url
        } else {
            fileURL = URL(fileURLWithPath: path)
        }

        guard let ciImage = CIImage(contentsOf: fileURL) else {
            result?(FlutterError(code: "INVALID_IMAGE", message: "Failed to load image from path", details: nil))
            return
        }

        detectBarcode(ciImage)
    }
    
    // MARK: - Camera Scanning
    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            setupCameraScan()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCameraScan()
                    } else {
                        self?.result?(FlutterError(code: "CAMERA_DENIED", 
                                                message: "Camera permission required", 
                                                details: nil))
                    }
                }
            }
        default:
            result?(FlutterError(code: "PERMISSION_DENIED", 
                              message: "Camera permission denied", 
                              details: nil))
        }
    }
    
    private func setupCameraScan() {
        guard let viewController = currentViewController() else {
            result?(FlutterError(code: "UNAVAILABLE", 
                              message: "View controller unavailable", 
                              details: nil))
            return
        }
        
        // Create container view
        let scanView = UIView(frame: viewController.view.bounds)
        self.scanWindowView = scanView
        viewController.view.addSubview(scanView)
        
        // Setup capture session
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession?.canAddInput(videoInput) == true else {
            result?(FlutterError(code: "SETUP_FAILED", 
                              message: "Failed to setup camera", 
                              details: nil))
            cleanUpScan()
            return
        }
        
        captureSession?.addInput(videoInput)
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession?.canAddOutput(metadataOutput) == true {
            captureSession?.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            result?(FlutterError(code: "SETUP_FAILED", 
                              message: "Failed to setup metadata output", 
                              details: nil))
            cleanUpScan()
            return
        }
        
        // Setup preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.frame = scanView.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        scanView.layer.addSublayer(previewLayer!)
        
        // Start session
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.startRunning()
            DispatchQueue.main.async {
                self.isScanning = true
            }
        }
        
        // Add close button
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.addTarget(self, action: #selector(closeScanner), for: .touchUpInside)
        closeButton.frame = CGRect(x: 20, y: 50, width: 100, height: 40)
        scanView.addSubview(closeButton)
    }
    
    @objc private func closeScanner() {
        cleanUpScan()
        result?(nil)
    }
    
    private func cleanUpScan() {
        DispatchQueue.main.async {
            self.isScanning = false
            self.captureSession?.stopRunning()
            self.previewLayer?.removeFromSuperlayer()
            self.scanWindowView?.removeFromSuperview()
            self.captureSession = nil
            self.previewLayer = nil
            self.scanWindowView = nil
        }
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
        
        // Return result and clean up
        result?(stringValue)
        cleanUpScan()
    }
    
    // MARK: - Image Picker Delegate
    public func imagePickerController(_ picker: UIImagePickerController, 
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage,
              let ciImage = CIImage(image: image) else {
            result?(FlutterError(code: "INVALID_IMAGE", message: "Failed to process selected image", details: nil))
            return
        }
        
        detectBarcode(ciImage)
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        result?(nil)
    }
    
    // MARK: - QR Code Detection
    private func detectBarcode(_ image: CIImage) {
        let request = VNDetectBarcodesRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                self.result?(FlutterError(code: "DETECTION_ERROR", message: error.localizedDescription, details: nil))
                return
            }
            
            guard let results = request.results as? [VNBarcodeObservation],
                  let qrCode = results.first,
                  let payload = qrCode.payloadStringValue else {
                self.result?(nil)
                return
            }
            
            self.result?(payload)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            self.result?(FlutterError(code: "DETECTION_ERROR", message: error.localizedDescription, details: nil))
        }
    }
}
