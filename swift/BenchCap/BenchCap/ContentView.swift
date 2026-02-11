//
//  ContentView.swift
//  BenchCap
//
//  Created by David McDougal on 2/6/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Subject.name)]) private var subjects: [Subject]
    @State private var newName: String = ""
    @State private var newSpecies: String = ""
    @State private var newProtocol: String = ""
    @State private var showAddRecord: Bool = false
    private let speciesOptions = ["Rat", "Mouse"]
    private let protocolOptions = ["25-009", "25-033"]
    @State private var showingExport = false
    @State private var exportDocument: ExportDocument?
    @State private var showingSurgicalCSV = false
    @State private var showingAnesthesiaCSV = false
    @State private var showingCorrectionsCSV = false
    @State private var csvDocument: CSVDocument?

    private var homeBanner: some View {
        Image("BenchCapBanner")
            .resizable()
            .scaledToFit()
            .frame(width: 420, height: 140, alignment: .leading)
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
            .padding(.bottom, Theme.spacingM)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Theme.spacingL) {
                homeBanner

                HomeAddRecordPanel(
                    showAddRecord: $showAddRecord,
                    newName: $newName,
                    newSpecies: $newSpecies,
                    newProtocol: $newProtocol,
                    speciesOptions: speciesOptions,
                    protocolOptions: protocolOptions,
                    saveAction: addSubject
                )

                RecordListView(subjects: subjects, deleteAction: deleteSubjects)

                Spacer()
            }
            .padding(Theme.spacingM)
            .background(Theme.formBackground.ignoresSafeArea())
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu("Export") {
                        Button("JSON Export") {
                            exportDocument = exportData()
                            showingExport = exportDocument != nil
                        }
                        Button("Surgical Logs CSV") {
                            csvDocument = CSVDocument(data: surgicalLogsCSV())
                            showingSurgicalCSV = csvDocument != nil
                        }
                        Button("Anesthesia CSV") {
                            csvDocument = CSVDocument(data: anesthesiaCSV())
                            showingAnesthesiaCSV = csvDocument != nil
                        }
                        Button("Corrections CSV") {
                            csvDocument = CSVDocument(data: correctionsCSV())
                            showingCorrectionsCSV = csvDocument != nil
                        }
                    }
                }
            }
            .fileExporter(
                isPresented: $showingExport,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "benchcap_export"
            ) { _ in }
            .fileExporter(
                isPresented: $showingSurgicalCSV,
                document: csvDocument,
                contentType: .commaSeparatedText,
                defaultFilename: "surgical_logs"
            ) { _ in }
            .fileExporter(
                isPresented: $showingAnesthesiaCSV,
                document: csvDocument,
                contentType: .commaSeparatedText,
                defaultFilename: "anesthesia_records"
            ) { _ in }
            .fileExporter(
                isPresented: $showingCorrectionsCSV,
                document: csvDocument,
                contentType: .commaSeparatedText,
                defaultFilename: "corrections"
            ) { _ in }
        }
    }


    private func addSubject() {
        guard !newName.isEmpty, !newSpecies.isEmpty, !newProtocol.isEmpty else { return }
        let subject = Subject(name: newName, species: newSpecies, protocolNumber: newProtocol)
        context.insert(subject)
        try? context.save()
        newName = ""
        newSpecies = ""
        newProtocol = ""
    }

    private func deleteSubjects(at offsets: IndexSet) {
        for index in offsets {
            context.delete(subjects[index])
        }
        try? context.save()
    }

    private func exportData() -> ExportDocument? {
        let payload = ExportPayload(subjects: subjects)
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        return ExportDocument(data: data)
    }

    private func surgicalLogsCSV() -> Data? {
        let headers = [
            "execution_id",
            "subject_id",
            "recordCreatedAt",
            "surgery_date",
            "weight_g",
            "PI_name",
            "surgeon_name",
            "protocol_number",
            "species",
            "procedure_name",
            "anesthesia_start",
            "isoflurane_start",
            "surgery_start",
            "surgery_end",
            "return_to_cage_time",
            "completion_state",
            "completedAt",
            "deviation_note",
            "notes",
            "carprofen_dose_ml",
            "carprofen_admin_time",
            "bupi_lido_dose_ml",
            "bupi_lido_admin_time"
        ]

        var rows: [[String]] = []
        for subject in subjects {
            let logs = subject.instruments.filter { $0.instrument.instrumentType == .surgicalLog }
            for instance in logs {
                rows.append([
                    instance.id.uuidString,
                    subject.id.uuidString,
                    isoString(instance.recordCreatedAt),
                    isoString(instance.surgeryDate),
                    instance.weightGrams,
                    "", // PI_name not captured
                    instance.surgeon,
                    subject.protocolNumber,
                    subject.species,
                    instance.procedureType,
                    isoString(instance.anesthesiaStart),
                    isoString(instance.isofluraneStartTime),
                    isoString(instance.surgeryStart),
                    isoString(instance.surgeryEnd),
                    isoString(instance.returnToCage),
                    instance.completionState.rawValue,
                    "", // completedAt not captured
                    instance.deviations,
                    instance.observations,
                    instance.carprofenDoseML,
                    isoString(instance.carprofenAdminTime),
                    instance.bupiLidoDoseML,
                    isoString(instance.bupiLidoAdminTime)
                ])
            }
        }

        return CSVWriter.makeCSV(headers: headers, rows: rows)
    }

    private func anesthesiaCSV() -> Data? {
        let headers = [
            "anesthesia_id",
            "execution_id",
            "subject_id",
            "agent_name",
            "dose",
            "dose_units",
            "route",
            "time_administered"
        ]

        var rows: [[String]] = []
        for subject in subjects {
            let logs = subject.instruments.filter { $0.instrument.instrumentType == .surgicalLog }
            for instance in logs {
                if instance.anesthesiaStart != nil {
                    rows.append([
                        UUID().uuidString,
                        instance.id.uuidString,
                        subject.id.uuidString,
                        "",
                        "",
                        "",
                        "",
                        isoString(instance.anesthesiaStart)
                    ])
                }
            }
        }

        return CSVWriter.makeCSV(headers: headers, rows: rows)
    }

    private func correctionsCSV() -> Data? {
        let headers = [
            "correction_id",
            "execution_id",
            "subject_id",
            "createdAt",
            "author_initials",
            "text"
        ]

        var rows: [[String]] = []
        for subject in subjects {
            let logs = subject.instruments.filter { $0.instrument.instrumentType == .surgicalLog }
            for instance in logs {
                for note in instance.corrections {
                    rows.append([
                        note.id.uuidString,
                        instance.id.uuidString,
                        subject.id.uuidString,
                        isoString(note.createdAt),
                        note.authorInitials ?? "",
                        note.text
                    ])
                }
            }
        }

        return CSVWriter.makeCSV(headers: headers, rows: rows)
    }

    private func isoString(_ date: Date?) -> String {
        guard let date else { return "" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    private func ensureSurgicalInstrument() -> Instrument {
        let descriptor = FetchDescriptor<Instrument>()
        if let existing = (try? context.fetch(descriptor))?.first(where: { $0.instrumentType == .surgicalLog }) {
            return existing
        }
        let instrument = Instrument(name: "Surgical Log", instrumentType: .surgicalLog)
        context.insert(instrument)
        try? context.save()
        return instrument
    }

    private func createInstance(for subject: Subject) {
        let instrument = ensureSurgicalInstrument()
        let instance = InstrumentInstance(instrument: instrument, subject: subject, recordCreatedAt: Date())
        context.insert(instance)
        try? context.save()
    }
}

struct SurgicalLogView: View {
    @Environment(\.modelContext) private var context
    @Bindable var instance: InstrumentInstance
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showCorrectionSheet = false
    @State private var correctionText: String = ""
    @State private var correctionInitials: String = ""
    private let surgeonOptions = ["McDougal", "Spann", "Narez-Velasquez", "Johnston", "DePrimo"]
    private let procedureOptions = ["mini pump implantation", "wound clip removal", "vascular catheterization", "Vas. Cath + pump impl.", "Other", "Sham pump"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingL) {
                SectionHeader(title: "Surgery")
                FormRow(label: "Surgery Date", required: true) {
                    HStack {
                        DatePicker(
                            "Surgery Date",
                            selection: Binding(
                                get: { instance.surgeryDate ?? Date() },
                                set: { instance.surgeryDate = $0 }
                            ),
                            displayedComponents: [.date]
                        )
                        .labelsHidden()
                        .disabled(isReadOnly)
                        Button("Clear") { instance.surgeryDate = nil }
                            .buttonStyle(CompactButton())
                            .disabled(isReadOnly || instance.surgeryDate == nil)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                SectionHeader(title: "Subject")
                FormRow(label: "Subject ID") {
                    Text(instance.subject.name)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                FormRow(label: "Species") {
                    Text(instance.subject.species)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                FormRow(label: "Protocol #") {
                    Text(instance.subject.protocolNumber)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                FormRow(label: "Weight (g)", required: true) {
                    TextField("Weight", text: $instance.weightGrams)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .disabled(isReadOnly)
                        .multilineTextAlignment(.trailing)
                        .entryFieldStyle()
                }

                SectionHeader(title: "Surgical Details")
                FormRow(label: "Surgeon", required: true) {
                    VStack(alignment: .leading, spacing: Theme.spacingXS) {
                        ForEach(surgeonOptions, id: \.self) { option in
                            RadioRow(label: option, value: option, selection: $instance.surgeon, isReadOnly: isReadOnly)
                        }
                        if !isReadOnly {
                            Button("Clear selection") { instance.surgeon = "" }
                                .buttonStyle(.plain)
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .padding(.top, Theme.spacingXS)
                        }
                    }
                    .frame(maxWidth: Theme.controlColumnWidth, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                FormRow(label: "Procedure Type", required: true) {
                    VStack(alignment: .leading, spacing: Theme.spacingXS) {
                        ForEach(procedureOptions, id: \.self) { option in
                            RadioRow(label: option, value: option, selection: $instance.procedureType, isReadOnly: isReadOnly)
                        }
                        if !isReadOnly {
                            Button("Clear selection") { instance.procedureType = "" }
                                .buttonStyle(.plain)
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .padding(.top, Theme.spacingXS)
                        }
                    }
                    .frame(maxWidth: Theme.controlColumnWidth, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                FormRow(label: "Analgesic Required") {
                    Toggle("", isOn: $instance.analgesicRequired)
                        .labelsHidden()
                        .disabled(isReadOnly)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                SectionHeader(title: "Analgesics")
                TimestampRow(
                    title: "Isoflurane start",
                    date: $instance.isofluraneStartTime,
                    isReadOnly: isReadOnly,
                    required: instance.analgesicRequired
                )
                FormRow(label: "Carprofen dose (mL)", required: instance.analgesicRequired) {
                    TextField("Carprofen dose", text: $instance.carprofenDoseML)
                        .textFieldStyle(.plain)
                        .keyboardType(.decimalPad)
                        .disabled(isReadOnly || !instance.analgesicRequired)
                        .multilineTextAlignment(.trailing)
                        .entryFieldStyle()
                }
                TimestampRow(
                    title: "Carprofen admin time",
                    date: $instance.carprofenAdminTime,
                    isReadOnly: isReadOnly,
                    required: instance.analgesicRequired
                )
                FormRow(label: "Bupi/Lido dose (mL)", required: instance.analgesicRequired) {
                    TextField("Bupi/Lido dose", text: $instance.bupiLidoDoseML)
                        .textFieldStyle(.plain)
                        .keyboardType(.decimalPad)
                        .disabled(isReadOnly || !instance.analgesicRequired)
                        .multilineTextAlignment(.trailing)
                        .entryFieldStyle()
                }
                TimestampRow(
                    title: "Bupi/Lido admin time",
                    date: $instance.bupiLidoAdminTime,
                    isReadOnly: isReadOnly,
                    required: instance.analgesicRequired
                )

                SectionHeader(title: "Required Timestamps")
                timeSection

                SectionHeader(title: "Derived")
                derivedSection

                SectionHeader(title: "Observations / Complications")
                FormRow(label: "Notes") {
                    TextField("Notes", text: $instance.observations, axis: .vertical)
                        .textFieldStyle(.plain)
                        .disabled(isReadOnly)
                        .multilineTextAlignment(.trailing)
                        .entryFieldStyle()
                }

                SectionHeader(title: "Deviations")
                FormRow(label: "Deviation Note") {
                    TextField("Describe deviations", text: $instance.deviations, axis: .vertical)
                        .textFieldStyle(.plain)
                        .disabled(isReadOnly)
                        .multilineTextAlignment(.trailing)
                        .entryFieldStyle()
                }

                SectionHeader(title: "Completion")
                HStack {
                    Text("Status")
                        .font(Theme.labelFont)
                        .foregroundStyle(Theme.labelColor)
                    Spacer()
                    StatusPill(state: instance.completionState)
                }
                Button("Mark Complete") {
                    attemptCompletion()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isReadOnly)

                SectionHeader(title: "Corrections")
                correctionsSection
            }
            .padding(Theme.spacingM)
            .background(Theme.formBackground)
        }
        .navigationTitle("Surgical Log")
        .benchCapBannerToolbar()
        .alert("Completion Blocked", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showCorrectionSheet) {
            NavigationStack {
                Form { 
                    Section("Correction") {
                        TextField("Details", text: $correctionText, axis: .vertical)
                            .entryFieldStyle()
                        TextField("Initials (optional)", text: $correctionInitials)
                            .entryFieldStyle()
                    }
                }
                .navigationTitle("Add Correction")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showCorrectionSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { saveCorrection() }
                            .disabled(correctionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .benchCapBannerToolbar()
            }
        }
        .onDisappear {
            persist()
        }
        .onAppear {
            refreshAnalgesicDosesIfNeeded()
        }
        .onChange(of: instance.weightGrams) { _ in
            refreshAnalgesicDosesIfNeeded()
        }
        .onChange(of: instance.analgesicRequired) { required in
            if required { refreshAnalgesicDosesIfNeeded() }
        }
    }

    private var timeSection: some View {
        VStack(spacing: Theme.spacingS) {
            TimestampRow(title: "Anesthesia start", date: $instance.anesthesiaStart, isReadOnly: isReadOnly, required: true)
            TimestampRow(title: "Surgery start", date: $instance.surgeryStart, isReadOnly: isReadOnly, required: true)
            TimestampRow(title: "Surgery end", date: $instance.surgeryEnd, isReadOnly: isReadOnly, required: true)
            TimestampRow(title: "Return to cage", date: $instance.returnToCage, isReadOnly: isReadOnly, required: true)
        }
    }

    private var derivedSection: some View {
        VStack(spacing: Theme.spacingS) {
            FormRow(label: "Surgery duration") {
                Text(durationText(instance.surgeryDurationMinutes))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            FormRow(label: "Recovery duration") {
                Text(durationText(instance.recoveryDurationMinutes))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private func durationText(_ minutes: Int?) -> String {
        guard let minutes else { return "—" }
        return "\(minutes) min"
    }

    private func weightValue() -> Double? {
        Double(instance.weightGrams.trimmingCharacters(in: .whitespaces))
    }

    private func formattedDose(_ value: Double) -> String {
        String(format: "%.2f", (value * 100).rounded() / 100)
    }

    private func updateAnalgesicDosesFromWeight() {
        guard let weight = weightValue(), weight > 0 else { return }
        let factor = weight / 100.0
        instance.carprofenDoseML = formattedDose(factor * 0.1)
        instance.bupiLidoDoseML = formattedDose(factor * 0.14)
    }

    private func refreshAnalgesicDosesIfNeeded() {
        if instance.analgesicRequired {
            updateAnalgesicDosesFromWeight()
        }
    }

    private func attemptCompletion() {
        let missing = requiredMissing()
        if !missing.isEmpty {
            alertMessage = "Missing required: " + missing.joined(separator: ", ")
            showAlert = true
            return
        }

        let deviationNote = instance.deviations.trimmingCharacters(in: .whitespacesAndNewlines)
        instance.completionState = deviationNote.isEmpty ? .complete : .completedWithDeviations
        persist()
    }

    private func requiredMissing() -> [String] {
        var missing: [String] = []
        if instance.surgeryDate == nil { missing.append("surgery date") }
        let weightTrimmed = instance.weightGrams.trimmingCharacters(in: .whitespaces)
        if weightTrimmed.isEmpty || Double(weightTrimmed) == nil { missing.append("weight") }
        if instance.surgeon.trimmingCharacters(in: .whitespaces).isEmpty { missing.append("surgeon") }
        if instance.procedureType.trimmingCharacters(in: .whitespaces).isEmpty { missing.append("procedure type") }
        if instance.anesthesiaStart == nil { missing.append("anesthesia start") }
        if instance.surgeryStart == nil { missing.append("surgery start") }
        if instance.surgeryEnd == nil { missing.append("surgery end") }
        if instance.returnToCage == nil { missing.append("return to cage") }
        if instance.analgesicRequired {
            if instance.isofluraneStartTime == nil { missing.append("isoflurane start") }
            if instance.carprofenDoseML.trimmingCharacters(in: .whitespaces).isEmpty { missing.append("carprofen dose") }
            if instance.carprofenAdminTime == nil { missing.append("carprofen admin time") }
            if instance.bupiLidoDoseML.trimmingCharacters(in: .whitespaces).isEmpty { missing.append("bupi/lido dose") }
            if instance.bupiLidoAdminTime == nil { missing.append("bupi/lido admin time") }
        }
        return missing
    }

    private func persist() {
        try? context.save()
    }

    private var isReadOnly: Bool {
        instance.completionState != .incomplete
    }

    private var sortedCorrections: [CorrectionNote] {
        instance.corrections.sorted { $0.createdAt > $1.createdAt }
    }

    private var correctionsSection: some View {
        Section("Corrections") {
            if sortedCorrections.isEmpty {
                Text("No corrections yet").foregroundStyle(.secondary)
            } else {
                ForEach(sortedCorrections) { note in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.text)
                        HStack {
                            Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let initials = note.authorInitials, !initials.isEmpty {
                                Text("· \(initials)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            if isReadOnly {
                Button("Add Correction") { showCorrectionSheet = true }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private func saveCorrection() {
        let trimmed = correctionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let note = CorrectionNote(
            text: trimmed,
            authorInitials: correctionInitials.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : correctionInitials,
            instance: instance,
            createdAt: Date()
        )
        context.insert(note)
        instance.corrections.append(note)
        try? context.save()
        correctionText = ""
        correctionInitials = ""
        showCorrectionSheet = false
    }
}

struct TimestampRow: View {
    let title: String
    @Binding var date: Date?
    var isReadOnly: Bool = false
    var required: Bool = false

    var body: some View {
        FormRow(label: title, required: required) {
            VStack(alignment: .trailing, spacing: Theme.spacingXS) {
                Text(dateText)
                    .font(Theme.valueFont)
                    .foregroundStyle(Theme.labelColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                HStack(spacing: Theme.spacingS) {
                    Button("Now") { date = .now }
                        .disabled(isReadOnly)
                        .buttonStyle(CompactButton())
                    Button("Clear") { date = nil }
                        .disabled(isReadOnly)
                        .buttonStyle(CompactButton())
                }
            }
        }
    }

    private var dateText: String {
        if let date {
            return date.formatted(date: .abbreviated, time: .shortened)
        } else {
            return "Not set"
        }
    }
}

private struct HomeAddRecordPanel: View {
    @Binding var showAddRecord: Bool
    @Binding var newName: String
    @Binding var newSpecies: String
    @Binding var newProtocol: String
    let speciesOptions: [String]
    let protocolOptions: [String]
    let saveAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            Button(action: { withAnimation { showAddRecord.toggle() } }) {
                HStack {
                    Text("Add Record")
                        .font(.headline)
                    Spacer()
                    Image(systemName: showAddRecord ? "chevron.up" : "chevron.down")
                }
            }
            .buttonStyle(.borderedProminent)

            if showAddRecord {
                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    FormRow(label: "Animal ID", required: true) {
                        TextField("Animal ID", text: $newName)
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.trailing)
                            .entryFieldStyle()
                    }
                    FormRow(label: "Species", required: true) {
                        VStack(alignment: .leading, spacing: Theme.spacingXS) {
                            ForEach(speciesOptions, id: \.self) { option in
                                RadioRow(label: option, value: option, selection: $newSpecies)
                            }
                        }
                        .frame(maxWidth: Theme.controlColumnWidth, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    FormRow(label: "Protocol #", required: true) {
                        VStack(alignment: .leading, spacing: Theme.spacingXS) {
                            ForEach(protocolOptions, id: \.self) { option in
                                RadioRow(label: option, value: option, selection: $newProtocol)
                            }
                        }
                        .frame(maxWidth: Theme.controlColumnWidth, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    Button("Save Record") {
                        saveAction()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newName.isEmpty || newSpecies.isEmpty || newProtocol.isEmpty)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

private struct RecordListView: View {
    let subjects: [Subject]
    var deleteAction: (IndexSet) -> Void

    var body: some View {
        List {
            ForEach(subjects) { subject in
                NavigationLink {
                    RecordDetailView(subject: subject)
                } label: {
                    RecordRow(subject: subject)
                }
            }
            .onDelete(perform: deleteAction)
        }
        .listStyle(.plain)
    }
}

private struct RecordRow: View {
    let subject: Subject

    private var logs: [InstrumentInstance] {
        subject.instruments
            .filter { $0.instrument.instrumentType == .surgicalLog }
            .sorted { $0.recordCreatedAt > $1.recordCreatedAt }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(subject.name)
                    .font(.headline)
                Spacer()
                if let latest = logs.first {
                    StatusPill(state: latest.completionState)
                }
            }
            HStack(spacing: Theme.spacingS) {
                Text(subject.species)
                    .font(.subheadline)
                Text("Protocol \(subject.protocolNumber)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !logs.isEmpty {
                Text("\(logs.count) surgical log\(logs.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Theme.spacingXS)
    }
}

private struct RecordDetailView: View {
    @Environment(\.modelContext) private var context
    let subject: Subject

    private var logs: [InstrumentInstance] {
        subject.instruments
            .filter { $0.instrument.instrumentType == .surgicalLog }
            .sorted { $0.recordCreatedAt > $1.recordCreatedAt }
    }

    var body: some View {
        List {
            Section {
                infoRow(title: "Animal ID", value: subject.name)
                infoRow(title: "Species", value: subject.species)
                infoRow(title: "Protocol #", value: subject.protocolNumber)
            }

            Section("Surgical Logs") {
                if logs.isEmpty {
                    Text("No surgical logs yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(logs) { instance in
                        NavigationLink {
                            SurgicalLogView(instance: instance)
                        } label: {
                            surgicalLogRow(instance)
                        }
                    }
                }
            }
        }
        .navigationTitle("Record")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Create Surgical Log") {
                    createInstance()
                }
            }
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(Theme.labelFont)
                .foregroundStyle(Theme.labelColor)
            Spacer()
            Text(value)
                .font(Theme.valueFont)
        }
    }

    private func surgicalLogRow(_ instance: InstrumentInstance) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(instance.surgeryDate.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "Date not set")
                Spacer()
                StatusPill(state: instance.completionState)
            }
            let subtitle = [instance.surgeon, instance.procedureType]
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .joined(separator: " · ")
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func ensureSurgicalInstrument() -> Instrument {
        let descriptor = FetchDescriptor<Instrument>()
        if let existing = (try? context.fetch(descriptor))?.first(where: { $0.instrumentType == .surgicalLog }) {
            return existing
        }
        let instrument = Instrument(name: "Surgical Log", instrumentType: .surgicalLog)
        context.insert(instrument)
        try? context.save()
        return instrument
    }

    private func createInstance() {
        let instrument = ensureSurgicalInstrument()
        let instance = InstrumentInstance(instrument: instrument, subject: subject, recordCreatedAt: Date())
        context.insert(instance)
        try? context.save()
    }
}

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    static var writableContentTypes: [UTType] { [.commaSeparatedText] }

    var data: Data

    init?(data: Data?) {
        guard let data else { return nil }
        self.data = data
    }

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

enum CSVWriter {
    static func makeCSV(headers: [String], rows: [[String]]) -> Data? {
        var lines: [String] = []
        lines.append(headers.map { escape($0) }.joined(separator: ","))
        for row in rows {
            lines.append(row.map { escape($0) }.joined(separator: ","))
        }
        return lines.joined(separator: "\n").data(using: .utf8)
    }

    private static func escape(_ field: String) -> String {
        var needsQuotes = field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r")
        var value = field.replacingOccurrences(of: "\"", with: "\"\"")
        if needsQuotes {
            value = "\"\(value)\""
        }
        return value
    }
}

struct ExportPayload: Codable {
    let subjects: [SubjectPayload]

    init(subjects: [Subject]) {
        self.subjects = subjects.map { SubjectPayload(subject: $0) }
    }
}

struct SubjectPayload: Codable {
    let id: UUID
    let name: String
    let species: String
    let protocolNumber: String
    let instruments: [InstrumentInstancePayload]

    init(subject: Subject) {
        self.id = subject.id
        self.name = subject.name
        self.species = subject.species
        self.protocolNumber = subject.protocolNumber
        self.instruments = subject.instruments.map { InstrumentInstancePayload(instance: $0) }
    }
}

struct InstrumentInstancePayload: Codable {
    let id: UUID
    let recordCreatedAt: Date
    let surgeon: String
    let procedureType: String
    let surgeryDate: Date?
    let weightGrams: String
    let analgesicRequired: Bool
    let isofluraneStartTime: Date?
    let carprofenDoseML: String
    let carprofenAdminTime: Date?
    let bupiLidoDoseML: String
    let bupiLidoAdminTime: Date?
    let observations: String
    let deviations: String
    let completionState: CompletionState
    let anesthesiaStart: Date?
    let surgeryStart: Date?
    let surgeryEnd: Date?
    let returnToCage: Date?
    let surgeryDurationMinutes: Int?
    let recoveryDurationMinutes: Int?
    let corrections: [CorrectionNotePayload]

    init(instance: InstrumentInstance) {
        self.id = instance.id
        self.recordCreatedAt = instance.recordCreatedAt
        self.surgeon = instance.surgeon
        self.procedureType = instance.procedureType
        self.surgeryDate = instance.surgeryDate
        self.weightGrams = instance.weightGrams
        self.analgesicRequired = instance.analgesicRequired
        self.isofluraneStartTime = instance.isofluraneStartTime
        self.carprofenDoseML = instance.carprofenDoseML
        self.carprofenAdminTime = instance.carprofenAdminTime
        self.bupiLidoDoseML = instance.bupiLidoDoseML
        self.bupiLidoAdminTime = instance.bupiLidoAdminTime
        self.observations = instance.observations
        self.deviations = instance.deviations
        self.completionState = instance.completionState
        self.anesthesiaStart = instance.anesthesiaStart
        self.surgeryStart = instance.surgeryStart
        self.surgeryEnd = instance.surgeryEnd
        self.returnToCage = instance.returnToCage
        self.surgeryDurationMinutes = instance.surgeryDurationMinutes
        self.recoveryDurationMinutes = instance.recoveryDurationMinutes
        self.corrections = instance.corrections.map { CorrectionNotePayload(note: $0) }
    }
}

struct CorrectionNotePayload: Codable {
    let id: UUID
    let createdAt: Date
    let text: String
    let authorInitials: String?

    init(note: CorrectionNote) {
        self.id = note.id
        self.createdAt = note.createdAt
        self.text = note.text
        self.authorInitials = note.authorInitials
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Subject.self, Instrument.self, InstrumentInstance.self, TimeNode.self, FieldEntry.self, CorrectionNote.self], inMemory: true)
}
