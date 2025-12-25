//
//  AddEventView.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/5/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI
import PhotosUI
import UIKit

// MARK: - AddEventView

struct AddEventView: View {
    
    let mode: EventFormMode
    
    @Environment(\.injected) private var injected: DIContainer
    @Environment(\.dismiss) private var dismiss
    
    @State private var eventName: String
    @State private var selectedImage: UIImage?
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var existingImageUrl: String?
    @State private var eventDate: Date?
    @State private var startTime: Date?
    @State private var endTime: Date?
    @State private var urlLink: String
    @State private var admission: AdmissionType
    @State private var admissionAmount: String
    @State private var requiresRegistration: Bool
    @State private var registrationDeadline: Date?
    @State private var location: String
    @State private var selectedCategory: EventCategory?
    @State private var notes: String
    @State private var status: EventStatus
    
    @State private var showCategoryPicker: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var showStartTimePicker: Bool = false
    @State private var showEndTimePicker: Bool = false
    @State private var showDeadlinePicker: Bool = false
    @State private var showImageSourceSheet: Bool = false
    @State private var showCamera: Bool = false
    @State private var showPhotosPicker: Bool = false
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    
    init(mode: EventFormMode = .add, sharedData: SharedEventData? = nil) {
        self.mode = mode
        
        switch mode {
        case .add:
            let title = sharedData?.title ?? ""
            let url = sharedData?.urlLink ?? ""
            let description = sharedData?.description ?? ""
            
            let imageFromData: UIImage? = {
                guard let imageData = sharedData?.imageData else { return nil }
                return UIImage(data: imageData)
            }()
            
            _eventName = State(initialValue: title)
            _selectedImage = State(initialValue: imageFromData)
            _eventDate = State(initialValue: nil)
            _startTime = State(initialValue: nil)
            _endTime = State(initialValue: nil)
            _urlLink = State(initialValue: url)
            _admission = State(initialValue: .free)
            _admissionAmount = State(initialValue: "")
            _requiresRegistration = State(initialValue: false)
            _registrationDeadline = State(initialValue: nil)
            _location = State(initialValue: "")
            _selectedCategory = State(initialValue: nil)
            _notes = State(initialValue: description)
            _status = State(initialValue: .interested)
            
        case .edit(let event):
            _eventName = State(initialValue: event.name)
            _eventDate = State(initialValue: event.eventDate)
            _startTime = State(initialValue: event.startTime)
            _endTime = State(initialValue: event.endTime)
            _urlLink = State(initialValue: event.urlLink ?? "")
            _admission = State(initialValue: event.admission)
            _admissionAmount = State(initialValue: event.admissionAmount != nil ? String(Int(event.admissionAmount!)) : "")
            _requiresRegistration = State(initialValue: event.requiresRegistration)
            _registrationDeadline = State(initialValue: event.registrationDeadline)
            _location = State(initialValue: event.location ?? "")
            _selectedCategory = State(initialValue: event.category)
            _notes = State(initialValue: event.notes ?? "")
            _status = State(initialValue: event.status)
            _existingImageUrl = State(initialValue: event.imageUrl)
        }
    }
    
    var body: some View {
        ZStack {
            Color(hex: "F8F7F1")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                formContent
                saveButton
            }
            
            if isSaving {
                savingOverlay
            }
        }
        .sheet(isPresented: $showImageSourceSheet) {
            imageSourceSheet
        }
        .sheet(isPresented: $showCategoryPicker) {
            categorySheet
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $selectedImageItem, matching: .images)
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(image: $selectedImage)
                .ignoresSafeArea()
        }
        .onChange(of: selectedImageItem) { _, newItem in
            loadImage(from: newItem)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .onAppear {
            loadSharedData()
        }
    }
    
    private func loadSharedData() {
        guard case .add = mode else { return }
        guard let data = injected.appState[\.routing.sharedEventData] else { return }
        
        if let title = data.title, !title.isEmpty {
            eventName = title
        }
        
        if let url = data.urlLink, !url.isEmpty {
            urlLink = url
        }
        
        if let desc = data.description, !desc.isEmpty {
            notes = desc
        }
        
        if let imageData = data.imageData, let image = UIImage(data: imageData) {
            selectedImage = image
            existingImageUrl = nil
        }
    }
}

// MARK: - Header View

private extension AddEventView {
    
    var headerView: some View {
        VStack(spacing: 10) {
            HStack {
                Text(headerTitle)
                    .font(.rubik(.extraBold, size: 20))
                    .foregroundColor(Color(hex: "11104B"))
                    .textCase(.uppercase)
                
                Spacer()
                
                closeButton
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color(hex: "EFEEE7"))
    }
    
    var headerTitle: String {
        switch mode {
        case .add:
            return "SAVE A NEW EVENT"
        case .edit:
            return "EDIT EVENT"
        }
    }
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 32, height: 32)
                
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "11104B"))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Form Content

private extension AddEventView {
    
    var formContent: some View {
        ScrollView {
            VStack(spacing: 1) {
                EventNameSection(eventName: $eventName)
                EventImageSection(
                    selectedImage: $selectedImage,
                    existingImageUrl: existingImageUrl,
                    onUploadTapped: { showImageSourceSheet = true },
                    onDeleteTapped: {
                        selectedImage = nil
                        selectedImageItem = nil
                        existingImageUrl = nil
                    }
                )
                DateSection(eventDate: $eventDate, showDatePicker: $showDatePicker)
                TimeSection(
                    startTime: $startTime,
                    endTime: $endTime,
                    showStartTimePicker: $showStartTimePicker,
                    showEndTimePicker: $showEndTimePicker
                )
                URLLinkSection(urlLink: $urlLink)
                AdmissionSection(admission: $admission, admissionAmount: $admissionAmount)
                RegistrationSection(
                    requiresRegistration: $requiresRegistration,
                    registrationDeadline: $registrationDeadline,
                    showDeadlinePicker: $showDeadlinePicker
                )
                LocationSection(location: $location)
                CategorySection(
                    selectedCategory: $selectedCategory,
                    onDropdownTapped: { showCategoryPicker = true }
                )
                NotesSection(notes: $notes)
                StatusSection(status: $status)
            }
            .background(Color(hex: "F4F4F4"))
        }
    }
}

// MARK: - Sheets

private extension AddEventView {
    
    var imageSourceSheet: some View {
        ImageSourceSheetView(
            onCameraTapped: {
                showImageSourceSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showCamera = true
                }
            },
            onPhotoLibraryTapped: {
                showImageSourceSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showPhotosPicker = true
                }
            }
        )
        .presentationDetents([.height(160)])
        .presentationDragIndicator(.visible)
        .presentationBackground(.white)
    }
    
    var categorySheet: some View {
        CategoriesView(
            selectedCategory: $selectedCategory,
            onDismiss: { showCategoryPicker = false }
        )
        .presentationDetents([.height(508)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.white)
    }
}

// MARK: - Save Button

private extension AddEventView {
    
    var saveButton: some View {
        Button {
            saveEvent()
        } label: {
            Text(saveButtonText)
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "F8F7F1"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "11104B"))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
    }
    
    var saveButtonText: String {
        switch mode {
        case .add:
            return "Save Event"
        case .edit:
            return "Update Event"
        }
    }
    
    var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Saving...")
                    .font(.rubik(.medium, size: 16))
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(Color(hex: "11104B"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Side Effects

private extension AddEventView {
    
    func loadImage(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = image
                    existingImageUrl = nil
                }
            }
        }
    }
    
    func saveEvent() {
        guard let userId = injected.appState[\.userData.userId] else {
            errorMessage = "Please sign in to save events"
            showError = true
            return
        }
        
        guard eventDate != nil else {
            errorMessage = "Event date is required"
            showError = true
            return
        }
        
        let event: Event
        switch mode {
        case .add:
            event = createEvent(userId: userId)
        case .edit(let existingEvent):
            event = createEvent(userId: userId, existingEventId: existingEvent.id, existingImageUrl: existingEvent.imageUrl)
        }
        
        let validationErrors = injected.interactors.events.validateEvent(event)
        
        guard validationErrors.isEmpty else {
            errorMessage = validationErrors.joined(separator: "\n")
            showError = true
            return
        }
        
        isSaving = true
        
        Task {
            do {
                switch mode {
                case .add:
                    try await injected.interactors.events.saveEvent(event, image: selectedImage)
                case .edit:
                    try await injected.interactors.events.updateEvent(event, newImage: selectedImage)
                }
                
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    func createEvent(userId: String, existingEventId: String? = nil, existingImageUrl: String? = nil) -> Event {
        let amount = Double(admissionAmount)
        
        guard let date = eventDate else {
            fatalError("Event date is required")
        }
        
        return Event(
            id: existingEventId ?? UUID().uuidString,
            userId: userId,
            name: eventName,
            imageUrl: existingImageUrl,
            eventDate: date,
            startTime: startTime,
            endTime: endTime,
            urlLink: urlLink.isEmpty ? nil : urlLink,
            admission: admission,
            admissionAmount: admission == .paid ? amount : nil,
            requiresRegistration: requiresRegistration,
            registrationDeadline: requiresRegistration ? registrationDeadline : nil,
            category: selectedCategory,
            notes: notes.isEmpty ? nil : notes,
            location: location.isEmpty ? nil : location,
            status: status
        )
    }
}

// MARK: - Previews

#Preview {
    AddEventView()
        .inject(DIContainer(appState: AppState(), interactors: .stub))
}
