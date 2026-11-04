// Build: xcrun swiftc -parse-as-library tools/make_onboarding_demo.swift -o /tmp/aie-demo-encoder
// Run: /tmp/aie-demo-encoder <export-directory> <resource-directory>
// Preview: /tmp/aie-demo-encoder <existing-demo.mp4> <separate-preview-directory>
// Frames come from --export-onboarding-demo, which renders the app's actual SwiftUI views.
import AppKit
import AVFoundation
import ImageIO
import UniformTypeIdentifiers

@main enum MakeOnboardingDemo {
    static func main() async throws {
        guard CommandLine.arguments.count == 3 else { fatalError("Expected exported frames and resource directory") }
        let source = URL(fileURLWithPath: CommandLine.arguments[1])
        let output = URL(fileURLWithPath: CommandLine.arguments[2])
        let preview = source.pathExtension.lowercased() == "mp4"
        let video = preview ? AVURLAsset(url: source) : nil
        let generator = video.map { AVAssetImageGenerator(asset: $0) }
        generator?.appliesPreferredTrackTransform = true
        generator?.requestedTimeToleranceBefore = .zero
        generator?.requestedTimeToleranceAfter = .zero
        if let video {
            let duration = try await video.load(.duration).seconds
            let audio = try await video.loadTracks(withMediaType: .audio)
            guard abs(duration - 8) < 0.05, audio.isEmpty else { throw CocoaError(.coderInvalidValue) }
        }
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let scenes: [(String, Double)] = [("search-0", 0.2), ("search-1", 0.2), ("search-2", 0.2),
                                        ("search-3", 2.4), ("reuse-choice", 2), ("reuse-compare-text", 3)]
        for theme in (preview ? ["light"] : ["light", "dark"]) {
            let images = try scenes.compactMap { scene -> CGImage? in
                guard !preview else { return nil }
                let data = try Data(contentsOf: source.appendingPathComponent(theme + "/" + scene.0 + ".png"))
                guard let image = NSBitmapImageRep(data: data)?.cgImage else { throw CocoaError(.fileReadCorruptFile) }
                return image
            }
            let name = preview ? source.deletingPathExtension().lastPathComponent + "-labels-preview" : "OnboardingDemo-\(theme)"
            let url = output.appendingPathComponent(name + ".mp4")
            if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
            let gifURL = output.appendingPathComponent("OnboardingDemo-\(theme).gif")
            let gif = preview ? nil : CGImageDestinationCreateWithURL(gifURL as CFURL, UTType.gif.identifier as CFString, images.count, nil)
            if !preview && gif == nil {
                throw CocoaError(.fileWriteUnknown)
            }
            if let gif {
                CGImageDestinationSetProperties(gif, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
            }
            let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
            let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: 1280, AVVideoHeightKey: 720,
                AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 1_500_000,
                                                  AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel],
            ])
            let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: 1280, kCVPixelBufferHeightKey as String: 720,
                kCVPixelBufferCGImageCompatibilityKey as String: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            ])
            writer.add(input)
            guard writer.startWriting() else { throw writer.error! }
            writer.startSession(atSourceTime: .zero)
            var frame = 0
            for (index, scene) in scenes.enumerated() {
                let count = Int((scene.1 * 30).rounded())
                for localFrame in 0..<count {
                    while !input.isReadyForMoreMediaData {
                        if writer.status == .failed { throw writer.error! }
                        try await Task.sleep(nanoseconds: 5_000_000)
                    }
                    var buffer: CVPixelBuffer?
                    guard let pool = adaptor.pixelBufferPool,
                          CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer) == kCVReturnSuccess,
                          let buffer else { throw CocoaError(.fileWriteUnknown) }
                    CVPixelBufferLockBaseAddress(buffer, [])
                    guard let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: 1280, height: 720,
                        bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else { throw CocoaError(.fileWriteUnknown) }
                    let shade: CGFloat = theme == "dark" ? 0.18 : 0.94
                    context.setFillColor(CGColor(gray: shade, alpha: 1)); context.fill(CGRect(x: 0, y: 0, width: 1280, height: 720))
                    func draw(_ image: CGImage, search: Bool, alpha: CGFloat) {
                        context.saveGState(); context.setAlpha(alpha)
                        // Focus on the search field and actual result rows; reuse windows are shown in full.
                        let visible = search ? image.cropping(to: CGRect(x: 0, y: 0, width: image.width, height: Int(Double(image.width) * 9 / 16)))! : image
                        let scale = min(1248 / CGFloat(visible.width), 688 / CGFloat(visible.height))
                        let size = CGSize(width: CGFloat(visible.width) * scale, height: CGFloat(visible.height) * scale)
                        context.interpolationQuality = .high
                        context.draw(visible, in: CGRect(x: (1280 - size.width) / 2, y: (720 - size.height) / 2, width: size.width, height: size.height))
                        context.restoreGState()
                    }
                    if let generator {
                        let (image, _) = try await generator.image(at: CMTime(value: Int64(frame), timescale: 30))
                        context.draw(image, in: CGRect(x: 0, y: 0, width: 1280, height: 720))
                    } else {
                        let blend = index >= 4 ? min(1, CGFloat(localFrame + 1) / 6) : 1
                        if blend < 1 { draw(images[index - 1], search: index - 1 < 4, alpha: 1) }
                        draw(images[index], search: index < 4, alpha: blend)
                    }
                    if !preview && index == 3 && localFrame == 0, let poster = context.makeImage(),
                       let data = NSBitmapImageRep(cgImage: poster).representation(using: .png, properties: [:]) {
                        try data.write(to: output.appendingPathComponent("OnboardingDemo-\(theme).png"))
                    }
                    if localFrame == count - 1, let gif, let image = context.makeImage() {
                        let gifContext = CGContext(data: nil, width: 960, height: 540, bitsPerComponent: 8,
                            bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
                        gifContext.interpolationQuality = .high
                        gifContext.draw(image, in: CGRect(x: 0, y: 0, width: 960, height: 540))
                        CGImageDestinationAddImage(gif, gifContext.makeImage()!,
                            [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: scene.1]] as CFDictionary)
                    }
                    drawLabel(at: Double(frame) / 30, in: context)
                    CVPixelBufferUnlockBaseAddress(buffer, [])
                    guard adaptor.append(buffer, withPresentationTime: CMTime(value: Int64(frame), timescale: 30)) else { throw writer.error ?? CocoaError(.fileWriteUnknown) }
                    frame += 1
                }
            }
            if let gif, !CGImageDestinationFinalize(gif) { throw CocoaError(.fileWriteUnknown) }
            input.markAsFinished()
            await writer.finishWriting()
            guard writer.status == .completed else { throw writer.error ?? CocoaError(.fileWriteUnknown) }
            let asset = AVURLAsset(url: url)
            let duration = try await asset.load(.duration).seconds
            let audio = try await asset.loadTracks(withMediaType: .audio)
            guard abs(duration - 8) < 0.05, audio.isEmpty else { throw CocoaError(.coderInvalidValue) }
            print("\(url.lastPathComponent): \(frame) frames, \(duration)s, silent, 1280x720")
        }
    }

    private static func drawLabel(at time: Double, in context: CGContext) {
        let title: String, start: Double, end: Double
        if time < 3 {
            (title, start, end) = ("找你所想", 0, 3)
        } else if time < 5 {
            (title, start, end) = ("咔哒一下", 3, 5)
        } else {
            (title, start, end) = ("焕然一新", 5, 8)
        }
        let entrance = max(0, min(1, (time - start) / 0.25))
        let easedEntrance = entrance * entrance * (3 - 2 * entrance)
        let fadeOut = max(0, min(1, (end - time) / 0.1))
        guard easedEntrance * fadeOut > 0 else { return }
        let text = NSAttributedString(string: title, attributes: [
            .font: NSFont.systemFont(ofSize: 36, weight: .semibold),
            .foregroundColor: NSColor(calibratedWhite: 0.16, alpha: 1),
        ])
        let width = ceil(text.size().width) + 48
        // This lower-middle space is clear in all three existing scenes.
        let rect = CGRect(x: (1280 - width) / 2, y: 164, width: width, height: 72)
        context.saveGState()
        let scale = CGFloat(0.96 + 0.04 * easedEntrance)
        context.translateBy(x: rect.midX, y: rect.midY)
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: -rect.midX, y: -rect.midY)
        context.setAlpha(CGFloat(easedEntrance * fadeOut))
        let capsule = CGPath(roundedRect: rect, cornerWidth: 36, cornerHeight: 36, transform: nil)
        context.setShadow(offset: CGSize(width: 0, height: -1), blur: 5, color: CGColor(gray: 0, alpha: 0.08))
        context.setFillColor(CGColor(gray: 1, alpha: 0.95))
        context.addPath(capsule)
        context.fillPath()
        context.setShadow(offset: .zero, blur: 0, color: nil)
        context.setStrokeColor(CGColor(red: 0.47, green: 0.70, blue: 0.94, alpha: 0.85))
        context.setLineWidth(2)
        context.addPath(capsule)
        context.strokePath()
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        text.draw(at: NSPoint(x: rect.minX + 24, y: rect.midY - text.size().height / 2))
        NSGraphicsContext.restoreGraphicsState()
        context.restoreGState()
    }
}
