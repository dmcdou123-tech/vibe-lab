import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation
import UIKit
import Combine

struct ContentView: View {
    @StateObject private var viewModel = MonkScrollViewModel()
    @State private var showingSourceDialog = false
    @State private var showingPhotosPicker = false
    @State private var showingDocumentPicker = false
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showingShareSheet = false
    @State private var showingVersionAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                header
                modePicker
                importButton

                if let info = viewModel.videoInfoText {
                    infoCard(text: info)
                }

                statusRow

                if viewModel.isProcessing {
                    progressCard
                }

                if viewModel.canExport {
                    exportCard
                }

                Spacer()
            }
            .padding()
            .navigationTitle("MonkScroll")
            .photosPicker(isPresented: $showingPhotosPicker, selection: $photosPickerItem, matching: .any(of: [.videos]))
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker { urls in
                    viewModel.handleDocument(urls: urls)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = viewModel.exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .onChange(of: photosPickerItem) { item in
                if let item { viewModel.handlePhotosPickerItem(item) }
            }
            .confirmationDialog("Import Screen Recording", isPresented: $showingSourceDialog) {
                Button("Photos") { showingPhotosPicker = true }
                Button("Files") { showingDocumentPicker = true }
                Button("Cancel", role: .cancel) {}
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingVersionAlert = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityLabel("App Version")
                }
            }
            .alert("MonkScroll Version", isPresented: $showingVersionAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(versionLabel)
            }
        }
    }

    private var importButton: some View {
        Button {
            showingSourceDialog = true
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.down.on.square")
                Text("Import Screen Recording").fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor.opacity(0.12))
            .foregroundStyle(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(viewModel.isProcessing)
    }

    private var modePicker: some View {
        Picker("Capture Mode", selection: $viewModel.captureMode) {
            Text("Generic").tag(CaptureMode.generic)
            Text("ChatGPT iOS").tag(CaptureMode.chatGPTiOS)
        }
        .pickerStyle(.segmented)
    }

    private var versionLabel: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "Version \(short) (Build \(build))"
    }

    private var statusRow: some View {
        HStack {
            Circle()
                .fill(viewModel.isProcessing ? Color.orange : Color.green)
                .frame(width: 10, height: 10)
            Text(viewModel.statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            if viewModel.canExport {
                Button("Start Over") { viewModel.reset() }
                    .font(.subheadline)
            }
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProgressView(value: viewModel.progressValue, total: viewModel.progressTotal)
            Text(viewModel.progressLabel)
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack {
                Button(role: .destructive) { viewModel.cancelProcessing() } label: {
                    Label("Cancel", systemImage: "xmark.circle")
                }
                Spacer()
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var exportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview (first ~30 lines)")
                .font(.headline)
            ScrollView {
                Text(viewModel.markdownPreview.isEmpty ? "Preview ready after processing." : viewModel.markdownPreview)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
            .frame(minHeight: 200, maxHeight: 260)
            HStack {
                Button {
                    showingShareSheet = true
                } label: {
                    Label("Export .md", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button("Start Over") { viewModel.reset() }
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("One-tap video → Markdown")
                .font(.title3.weight(.semibold))
            Text("Import a screen recording, we OCR at 2 fps, stitch text, and hand you a shareable .md.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func infoCard(text: String) -> some View {
        HStack {
            Image(systemName: "film")
            Text(text)
            Spacer()
        }
        .font(.subheadline)
        .padding(10)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

@MainActor
final class MonkScrollViewModel: ObservableObject {
    struct ProgressState {
        let current: Int
        let total: Int
    }

    @Published var statusMessage: String = "Ready to import"
    @Published var progress: ProgressState?
    @Published var isProcessing: Bool = false
    @Published var markdownPreview: String = ""
    @Published var exportURL: URL?
    @Published var canExport: Bool = false
    @Published var selectedVideoName: String?
    @Published var selectedVideoDuration: Double?
    @Published var captureMode: CaptureMode = .generic

    private let processor = OCRProcessor()
    private var processingTask: Task<Void, Never>?

    var progressValue: Double { Double(progress?.current ?? 0) }
    var progressTotal: Double { Double(progress?.total ?? 1) }
    var progressLabel: String {
        if let progress { return "Processing frame \(progress.current)/\(progress.total)" }
        return statusMessage
    }

    var videoInfoText: String? {
        guard let name = selectedVideoName, let duration = selectedVideoDuration else { return nil }
        return "\(name) • \(formatDuration(seconds: duration))"
    }

    func handlePhotosPickerItem(_ item: PhotosPickerItem) {
        statusMessage = "Loading from Photos..."
        cancelProcessing()
        Task.detached { [weak self] in
            guard let self else { return }
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw ProcessingError.unableToLoad
                }
                let ext = item.supportedContentTypes.first?.preferredFilenameExtension ?? "mov"
                let savedURL = try self.persistVideoData(data, suggestedExtension: ext)
                let duration = AVAsset(url: savedURL).duration.seconds
                await MainActor.run {
                    self.selectedVideoName = savedURL.lastPathComponent
                    self.selectedVideoDuration = duration
                    self.startProcessing(url: savedURL)
                }
            } catch is CancellationError {
                await MainActor.run { self.statusMessage = "Cancelled" }
            } catch {
                await MainActor.run { self.statusMessage = "Load failed: \(error.localizedDescription)" }
            }
        }
    }

    func handleDocument(urls: [URL]) {
        guard let url = urls.first else { return }
        statusMessage = "Importing from Files..."
        cancelProcessing()
        Task.detached { [weak self] in
            guard let self else { return }
            do {
                let sandboxed = try self.copyVideoToSandbox(from: url)
                let duration = AVAsset(url: sandboxed).duration.seconds
                await MainActor.run {
                    self.selectedVideoName = sandboxed.lastPathComponent
                    self.selectedVideoDuration = duration
                    self.startProcessing(url: sandboxed)
                }
            } catch is CancellationError {
                await MainActor.run { self.statusMessage = "Cancelled" }
            } catch {
                await MainActor.run { self.statusMessage = "Import failed: \(error.localizedDescription)" }
            }
        }
    }

    func startProcessing(url: URL) {
        processingTask?.cancel()
        Task { @MainActor in
            self.isProcessing = true
            self.canExport = false
            self.markdownPreview = ""
            self.exportURL = nil
            self.progress = nil
            self.statusMessage = "Preparing video..."
        }

        let videoName = url.lastPathComponent
        let mode = self.captureMode
        processingTask = Task.detached { [weak self] in
            guard let self else { return }
            do {
                let result = try await self.processor.processVideo(at: url, videoName: videoName) { current, total in
                    await MainActor.run {
                        self.progress = ProgressState(current: current, total: total)
                        self.statusMessage = "Processing frame \(current)/\(total)"
                    }
                }
                let finalMarkdown: String
                let preview: String

                if mode == .chatGPTiOS {
                    let post = ChatGPTIOSPostProcessor()
                    let processed = post.process(lines: result.lines,
                                                 source: "ChatGPT iOS",
                                                 captureMethod: url.pathExtension.lowercased() == "mov" ? "video" : "screenshots")
                    finalMarkdown = processed.markdown
                    preview = processed.preview
                } else {
                    finalMarkdown = result.markdown
                    preview = result.preview
                }

                let exportURL = try self.writeMarkdown(finalMarkdown)
                await MainActor.run {
                    self.markdownPreview = preview
                    self.exportURL = exportURL
                    self.canExport = true
                    self.isProcessing = false
                    self.statusMessage = "Finished (\(result.linesCount) lines)"
                }
            } catch is CancellationError {
                await MainActor.run {
                    self.statusMessage = "Cancelled"
                    self.isProcessing = false
                    self.progress = nil
                }
            } catch {
                await MainActor.run {
                    self.statusMessage = "Error: \(error.localizedDescription)"
                    self.isProcessing = false
                    self.progress = nil
                }
            }
        }
    }

    func cancelProcessing() {
        processingTask?.cancel()
    }

    func reset() {
        processingTask?.cancel()
        selectedVideoName = nil
        selectedVideoDuration = nil
        progress = nil
        isProcessing = false
        markdownPreview = ""
        exportURL = nil
        canExport = false
        statusMessage = "Ready to import"
    }

    nonisolated private func persistVideoData(_ data: Data, suggestedExtension: String) throws -> URL {
        let ext = allowedExtension(from: suggestedExtension)
        let folder = try ensureImportFolder()
        let filename = "import_\(UUID().uuidString.prefix(6)).\(ext)"
        let url = folder.appendingPathComponent(filename)
        try data.write(to: url)
        return url
    }

    nonisolated private func copyVideoToSandbox(from url: URL) throws -> URL {
        let ext = allowedExtension(from: url.pathExtension)
        let folder = try ensureImportFolder()
        let filename = url.deletingPathExtension().lastPathComponent
        let dest = folder.appendingPathComponent("\(filename)_copy.\(ext)")

        var accessGranted = false
        if url.startAccessingSecurityScopedResource() { accessGranted = true }
        defer { if accessGranted { url.stopAccessingSecurityScopedResource() } }

        if FileManager.default.fileExists(atPath: dest.path) {
            try? FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.copyItem(at: url, to: dest)
        return dest
    }

    nonisolated private func ensureImportFolder() throws -> URL {
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("ImportedVideos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    nonisolated private func allowedExtension(from ext: String) -> String {
        let lower = ext.lowercased()
        if lower == "mp4" || lower == "mov" { return lower }
        return "mov"
    }

    nonisolated private func writeMarkdown(_ text: String) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmm"
        let filename = "MonkScroll_\(formatter.string(from: Date())).md"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func formatDuration(seconds: Double) -> String {
        guard seconds.isFinite else { return "--" }
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02dm %02ds", minutes, secs)
    }
}

enum ProcessingError: Error {
    case unableToLoad
}

enum CaptureMode: String, Identifiable, CaseIterable {
    case generic
    case chatGPTiOS

    var id: String { rawValue }
}

struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: ([URL]) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: [.movie, .mpeg4Movie, .quickTimeMovie], asCopy: true)
        controller.allowsMultipleSelection = false
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onPick: ([URL]) -> Void
        init(onPick: @escaping ([URL]) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
    }
}

#Preview {
    ContentView()
}
