import Foundation
import AVFoundation
import Vision
import CoreImage
import CoreGraphics

struct OCRLine {
    let raw: String
    let norm: String
    let boundingBox: CGRect
    let frameIndex: Int
}

struct OCRResult {
    let markdown: String
    let preview: String
    let linesCount: Int
    let lines: [OCRLine]
}

final class OCRProcessor {
    private let ciContext = CIContext()
    private let framesPerSecond: Double = 2.0
    private let maxOverlap = 25
    private let recentLimit = 250
    var debugLogging = false

    func processVideo(at url: URL, videoName: String, progress: @escaping @Sendable (Int, Int) async -> Void) async throws -> OCRResult {
        let asset = AVAsset(url: url)
        let durationSeconds = asset.duration.seconds
        guard durationSeconds.isFinite, durationSeconds > 0 else { throw ProcessingError.unableToLoad }

        let totalFrames = max(1, Int(ceil(durationSeconds * framesPerSecond)))
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        var accumulated: [OCRLine] = []
        var recentQueue: [String] = []
        var recentSet = Set<String>()

        for index in 0..<totalFrames {
            try Task.checkCancellation()
            let frameTime = CMTime(seconds: Double(index) / framesPerSecond, preferredTimescale: 600)
            do {
                let cgImage = try generator.copyCGImage(at: frameTime, actualTime: nil)
                if let processed = preprocess(image: cgImage) {
                    let lines = try recognizeLines(in: processed)
                    let paired = lines.map { line in
                        OCRLine(raw: line.text,
                                norm: normalize(line.text),
                                boundingBox: line.boundingBox,
                                frameIndex: index + 1)
                    }
                    append(paired, to: &accumulated, recentQueue: &recentQueue, recentSet: &recentSet, frameIndex: index + 1)
                }
            } catch {
                // skip frames that fail to generate
            }
            await progress(index + 1, totalFrames)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let header = "# MonkScroll Export\n- Video: \(videoName)\n- Exported: \(formatter.string(from: Date()))\n\n"
        let body = accumulated.map(\.raw).joined(separator: "\n")
        let markdown = header + body
        let preview = accumulated.prefix(30).map(\.raw).joined(separator: "\n")
        return OCRResult(markdown: markdown, preview: preview, linesCount: accumulated.count, lines: accumulated)
    }

    private func preprocess(image: CGImage) -> CGImage? {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let topCrop = height * 0.12
        let bottomCrop = height * 0.15
        let croppedHeight = max(1, height - topCrop - bottomCrop)
        let cropRect = CGRect(x: 0, y: bottomCrop, width: width, height: croppedHeight)

        let ciImage = CIImage(cgImage: image)
            .cropped(to: cropRect)
            .applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 0, kCIInputContrastKey: 1.15])
        return ciContext.createCGImage(ciImage, from: ciImage.extent)
    }

    private struct RecognizedLine {
        let text: String
        let boundingBox: CGRect
    }

    private func recognizeLines(in cgImage: CGImage) throws -> [RecognizedLine] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let results = request.results else { return [] }
        let margin: CGFloat = 0.08
        let ordered = results.sorted { first, second in
            if first.boundingBox.maxY == second.boundingBox.maxY {
                return first.boundingBox.minX < second.boundingBox.minX
            }
            return first.boundingBox.maxY > second.boundingBox.maxY
        }

        return ordered.compactMap { observation in
            guard observation.boundingBox.minY > margin, observation.boundingBox.maxY < (1 - margin) else { return nil }
            let text = observation.topCandidates(1).first?.string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let text, !text.isEmpty else { return nil }
            return RecognizedLine(text: text, boundingBox: observation.boundingBox)
        }
    }

    private func append(_ newLines: [OCRLine],
                        to accumulator: inout [OCRLine],
                        recentQueue: inout [String],
                        recentSet: inout Set<String>,
                        frameIndex: Int) {
        guard !newLines.isEmpty else { return }

        let overlap = findOverlap(newLines: newLines, accumulator: accumulator)
        let trimmed = Array(newLines.dropFirst(overlap))

        var added = 0
        for line in trimmed {
            if line.norm.count < 60, recentSet.contains(line.norm) {
                continue
            }
            accumulator.append(line)
            recentQueue.append(line.norm)
            recentSet.insert(line.norm)
            added += 1
            if recentQueue.count > recentLimit {
                let removed = recentQueue.removeFirst()
                if !recentQueue.contains(removed) {
                    recentSet.remove(removed)
                }
            }
        }

        if debugLogging {
            let info = "frame \(frameIndex): in=\(newLines.count) overlapDropped=\(overlap) outAdded=\(added)"
            print("[MonkScroll] \(info)")
        }
    }

    private func findOverlap(newLines: [OCRLine],
                             accumulator: [OCRLine]) -> Int {
        let maxK = min(maxOverlap, newLines.count, accumulator.count)
        guard maxK > 0 else { return 0 }
        for length in stride(from: maxK, through: 1, by: -1) {
            let accSlice = accumulator.suffix(length)
            let newSlice = newLines.prefix(length)
            let matchesAll = zip(accSlice, newSlice).allSatisfy { similar($0.norm, $1.norm) }
            if matchesAll { return length }
        }
        return 0
    }

    private func similar(_ a: String, _ b: String) -> Bool {
        if a == b { return true }
        return wordSetSimilarity(a, b) >= 0.85
    }

    private func wordSetSimilarity(_ a: String, _ b: String) -> Double {
        let setA = Set(a.split(separator: " "))
        let setB = Set(b.split(separator: " "))
        if setA.isEmpty && setB.isEmpty { return 1.0 }
        let intersection = Double(setA.intersection(setB).count)
        let union = Double(setA.union(setB).count)
        return union == 0 ? 0 : intersection / union
    }

    private func normalize(_ line: String) -> String {
        let lower = line.lowercased()
        let trimmed = lower.trimmingCharacters(in: .whitespacesAndNewlines)
        let collapsed = trimmed.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        let replaced = collapsed.replacingOccurrences(of: "[^a-z0-9 ]", with: "", options: .regularExpression)
        let confusionFixed = replaced
            .replacingOccurrences(of: "l", with: "i")
            .replacingOccurrences(of: "1", with: "i")
        return confusionFixed
    }
}

// MARK: - ChatGPT iOS specialized post-processing

struct ChatGPTIOSPostProcessor {
    struct Message {
        let role: Role
        let text: String
    }

    enum Role: String {
        case user = "User"
        case assistant = "Assistant"
        case unknown = "Unknown"
    }

    struct Output {
        let markdown: String
        let preview: String
    }

    func process(lines: [OCRLine], source: String, captureMethod: String) -> Output {
        let cleaned = suppressUI(from: lines)
        let deduped = removeOverlaps(cleaned)
        let messages = buildMessages(from: deduped)
        let markdown = renderMarkdown(messages: messages,
                                      source: source,
                                      captureMethod: captureMethod)
        let preview = messages.prefix(2).enumerated().map { idx, message in
            let turn = String(format: "%02d", idx + 1)
            return "### Turn \(turn) — \(message.role.rawValue)\n\(message.text)"
        }.joined(separator: "\n\n")
        return Output(markdown: markdown, preview: preview)
    }

    private func suppressUI(from lines: [OCRLine]) -> [OCRLine] {
        let blacklist = Set([
            "home","message","messages","back","share","copy link","more","menu","search","settings","new chat","voice","profile","history","send a message","done","cancel","powered by gpt","rate this answer","dislike","like","regenerate","typing","typing…","typing...","editor","product","debug","integrate","window","help","build settings","signing capabilities","package dependencies","open in xcode","create pull request","copy","commit","staged","unstaged","iphone","simulator","running","build failed","chatgpt"
        ])

        let topCropHeight: CGFloat = 0.14
        let bottomCropStart: CGFloat = 0.82

        return lines.filter { line in
            // Drop top/bottom UI chrome
            if line.boundingBox.minY < topCropHeight { return false }
            if line.boundingBox.maxY > bottomCropStart { return false }

            let key = normalize(line.raw)
            if blacklist.contains(key) { return false }

            // Heuristic: short UI-y strings
            let tokens = key.split(separator: " ")
            if tokens.count <= 2 {
                let menuish = key.range(of: #"^(home|search|settings|back|edit|copy|share|menu)$"#, options: .regularExpression) != nil
                if menuish { return false }
            }
            return true
        }
    }

    private func normalize(_ text: String) -> String {
        let lower = text.lowercased()
        let trimmed = lower.trimmingCharacters(in: .whitespacesAndNewlines)
        let collapsed = trimmed.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        let cleaned = collapsed.replacingOccurrences(of: "[^a-z0-9 ]", with: "", options: .regularExpression)
        return cleaned
    }

    private func removeOverlaps(_ lines: [OCRLine]) -> [OCRLine] {
        let grouped = Dictionary(grouping: lines, by: \.frameIndex)
            .sorted { $0.key < $1.key }
            .map(\.value)

        var result: [OCRLine] = []
        for block in grouped {
            let tail = result.suffix(30).map(\.norm)
            let head = block.prefix(30).map(\.norm)
            let overlap = overlapLength(tail: tail, head: head)
            let trimmed = Array(block.dropFirst(overlap))
            result.append(contentsOf: trimmed)
        }
        return result
    }

    private func overlapLength(tail: [String], head: [String]) -> Int {
        let maxK = min(30, tail.count, head.count)
        guard maxK > 0 else { return 0 }
        for length in stride(from: maxK, through: 3, by: -1) {
            let tailSlice = tail.suffix(length)
            let headSlice = head.prefix(length)
            let matches = zip(tailSlice, headSlice).allSatisfy { similarity($0, $1) >= 0.88 }
            if matches { return length }
        }
        return 0
    }

    private func buildMessages(from lines: [OCRLine]) -> [Message] {
        guard !lines.isEmpty else { return [] }
        let heights = lines.map { $0.boundingBox.height }.sorted()
        let medianHeight = heights[heights.count / 2]
        let gapThreshold = max(medianHeight * 1.8, 0.02)

        var messages: [Message] = []
        var current: [OCRLine] = []

        func flush() {
            guard !current.isEmpty else { return }
            let role = inferRole(for: current)
            let text = assembleText(for: current)
            messages.append(Message(role: role, text: text))
            current.removeAll(keepingCapacity: true)
        }

        let ordered = lines.sorted { $0.boundingBox.maxY > $1.boundingBox.maxY }
        var previous: OCRLine?
        for line in ordered {
            if let prev = previous {
                let gap = prev.boundingBox.minY - line.boundingBox.maxY
                if gap > gapThreshold {
                    flush()
                }
            }
            appendLine(line, to: &current)
            previous = line
        }
        flush()
        return messages
    }

    private func appendLine(_ line: OCRLine, to current: inout [OCRLine]) {
        if isCodeCandidate(line, existing: current) {
            current.append(line)
            return
        }
        current.append(line)
    }

    private func assembleText(for lines: [OCRLine]) -> String {
        guard !lines.isEmpty else { return "" }

        var blocks: [String] = []
        var buffer: [OCRLine] = []
        var inCode = false
        var codeHashes = Set<String>()
        var proseStreak = 0

        func flushBuffer(asCode: Bool) {
            guard !buffer.isEmpty else { return }
            let text = buffer.map(\.raw).joined(separator: "\n")
            if asCode {
                let hash = codeHash(for: buffer)
                if codeHashes.contains(hash) {
                    buffer.removeAll(keepingCapacity: true)
                    return
                }
                codeHashes.insert(hash)

                let fence = "```" + (guessLanguage(from: buffer) ?? "text")
                let truncated = isLikelyTruncated(buffer)
                let codeBody = truncated ? text + "\n// [truncated]" : text
                blocks.append("\(fence)\n\(codeBody)\n```")
            } else {
                blocks.append(text)
            }
            buffer.removeAll(keepingCapacity: true)
        }

        for line in lines {
            let codeLike = isCodeLine(line.raw)
            if codeLike {
                proseStreak = 0
            } else {
                proseStreak += 1
            }

            if codeLike != inCode && (codeLike || proseStreak > 2) {
                flushBuffer(asCode: inCode)
                inCode = codeLike
            }
            buffer.append(line)
        }
        flushBuffer(asCode: inCode)
        return blocks.joined(separator: "\n\n")
    }

    private func codeHash(for lines: [OCRLine]) -> String {
        let sample = lines.prefix(8).map(\.norm).joined(separator: "|")
        return String(sample.hashValue)
    }

    private func isLikelyTruncated(_ lines: [OCRLine]) -> Bool {
        guard let last = lines.last?.raw.trimmingCharacters(in: .whitespaces) else { return false }
        if last.hasSuffix("```") { return false }
        let goodEndings: [Character] = ["}", "]", ";", ".", ")", "\"", "'"]
        return !goodEndings.contains(last.last ?? " ")
    }

    private func inferRole(for lines: [OCRLine]) -> Role {
        guard let bounds = boundingBox(for: lines) else { return .unknown }
        let center = bounds.midX
        let width = bounds.width

        if center > 0.6 && width < 0.45 { return .user }
        if width > 0.55 || center < 0.55 { return .assistant }
        return .unknown
    }

    private func boundingBox(for lines: [OCRLine]) -> CGRect? {
        guard let first = lines.first else { return nil }
        var rect = first.boundingBox
        for line in lines.dropFirst() {
            rect = rect.union(line.boundingBox)
        }
        return rect
    }

    private func similarity(_ a: String, _ b: String) -> Double {
        if a == b { return 1.0 }
        let tokensA = Set(a.split(separator: " "))
        let tokensB = Set(b.split(separator: " "))
        if tokensA.isEmpty || tokensB.isEmpty { return 0 }
        let inter = Double(tokensA.intersection(tokensB).count)
        let uni = Double(tokensA.union(tokensB).count)
        return uni == 0 ? 0 : inter / uni
    }

    private func isCodeCandidate(_ line: OCRLine, existing: [OCRLine]) -> Bool {
        guard existing.count >= 2 else { return false }
        let last = existing.suffix(2)
        let margins = last.map { $0.boundingBox.minX }
        let avgMargin = margins.reduce(0, +) / CGFloat(margins.count)
        let marginDelta = abs(avgMargin - line.boundingBox.minX)
        let uniformMargin = marginDelta < 0.02
        let codey = isCodeLine(line.raw)
        return uniformMargin && codey
    }

    private func isCodeLine(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.contains("```") { return true }
        let symbols = CharacterSet(charactersIn: "{}[]();=<>").union(.punctuationCharacters)
        let symbolRatio = Double(trimmed.unicodeScalars.filter { symbols.contains($0) }.count) / Double(max(1, trimmed.count))
        let digitRatio = Double(trimmed.unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) }.count) / Double(max(1, trimmed.count))
        return symbolRatio > 0.15 || digitRatio > 0.3
    }

    private func guessLanguage(from lines: [OCRLine]) -> String? {
        let joined = lines.map(\.raw).joined(separator: " ")
        if joined.contains("import SwiftUI") { return "swift" }
        if joined.contains("{") && joined.contains("}") && joined.contains("func") { return "swift" }
        if joined.contains("\"") && joined.contains(":") && joined.contains("{") { return "json" }
        if joined.contains("pip install") || joined.contains("python") { return "bash" }
        return nil
    }

    private func renderMarkdown(messages: [Message], source: String, captureMethod: String) -> String {
        var lines: [String] = []
        lines.append("---")
        lines.append("source: \(source)")
        lines.append("capture_method: \(captureMethod.isEmpty ? "unknown" : captureMethod)")
        lines.append("mode: chatGPTiOS")
        lines.append("notes: ui_cropped, ui_filtered, overlap_deduped, block_segmented, code_blocks_preserved")
        lines.append("---")
        lines.append("")
        lines.append("## Conversation Capture")

        for (idx, message) in messages.enumerated() {
            lines.append("### Turn \(String(format: "%02d", idx + 1)) — \(message.role.rawValue)")
            lines.append(message.text)
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }
}

#if DEBUG
struct ChatGPTIOSPostProcessorChecks {
    static func run() {
        let processor = ChatGPTIOSPostProcessor()
        let lineA = OCRLine(raw: "Hello world", norm: "hello world", boundingBox: CGRect(x: 0.1, y: 0.8, width: 0.7, height: 0.05), frameIndex: 1)
        let lineB = OCRLine(raw: "How are you?", norm: "how are you", boundingBox: CGRect(x: 0.1, y: 0.72, width: 0.7, height: 0.05), frameIndex: 1)
        let out = processor.process(lines: [lineA, lineB], source: "ChatGPT iOS", captureMethod: "video")
        assert(out.markdown.contains("Turn 01"))

        let block1 = OCRLine(raw: "first line", norm: "first line", boundingBox: CGRect(x: 0.1, y: 0.6, width: 0.7, height: 0.05), frameIndex: 1)
        let block2 = OCRLine(raw: "second line", norm: "second line", boundingBox: CGRect(x: 0.1, y: 0.5, width: 0.7, height: 0.05), frameIndex: 1)
        let overlap1 = OCRLine(raw: "second line", norm: "second line", boundingBox: CGRect(x: 0.1, y: 0.4, width: 0.7, height: 0.05), frameIndex: 2)
        let trimmed = processor.process(lines: [block1, block2, overlap1], source: "ChatGPT iOS", captureMethod: "video")
        assert(!trimmed.markdown.contains("second line\nsecond line"))

        let top = OCRLine(raw: "Top", norm: "top", boundingBox: CGRect(x: 0.1, y: 0.9, width: 0.7, height: 0.03), frameIndex: 1)
        let bottom = OCRLine(raw: "Bottom", norm: "bottom", boundingBox: CGRect(x: 0.1, y: 0.4, width: 0.7, height: 0.03), frameIndex: 1)
        let segmented = processor.process(lines: [top, bottom], source: "ChatGPT iOS", captureMethod: "video")
        assert(segmented.markdown.contains("Turn 02"))

        let chrome = OCRLine(raw: "Build Settings", norm: "build settings", boundingBox: CGRect(x: 0.1, y: 0.9, width: 0.7, height: 0.03), frameIndex: 1)
        let kept = processor.process(lines: [chrome, lineA], source: "ChatGPT iOS", captureMethod: "video")
        assert(!kept.markdown.lowercased().contains("build settings"))

        let code1 = OCRLine(raw: "func hello() {", norm: "func hello", boundingBox: CGRect(x: 0.12, y: 0.7, width: 0.6, height: 0.03), frameIndex: 1)
        let code2 = OCRLine(raw: " print(\"hi\")", norm: "print hi", boundingBox: CGRect(x: 0.12, y: 0.66, width: 0.6, height: 0.03), frameIndex: 1)
        let prose = OCRLine(raw: "Next paragraph.", norm: "next paragraph", boundingBox: CGRect(x: 0.15, y: 0.5, width: 0.6, height: 0.04), frameIndex: 1)
        let processedCode = processor.process(lines: [code1, code2, prose], source: "ChatGPT iOS", captureMethod: "video").markdown
        assert(processedCode.contains("```"))
    }
}
#endif
