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
    
    @Environment(\.injected) private var injected: DIContainer
    @Environment(\.dismiss) private var dismiss
    
    @State private var eventName: String = ""
    @State private var selectedImage: UIImage?
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var eventDate: Date = Date()
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    @State private var urlLink: String = ""
    @State private var admission: AdmissionType = .free
    @State private var admissionAmount: String = ""
    @State private var requiresRegistration: Bool = false
    @State private var registrationDeadline: Date = Date()
    @State private var selectedCategory: EventCategory?
    @State private var notes: String = ""
    @State private var status: EventStatus = .interested
    
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
    }
}

// MARK: - Header View

private extension AddEventView {
    
    var headerView: some View {
        VStack(spacing: 10) {
            HStack {
                Text("SAVE A NEW EVENT")
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
                    onUploadTapped: { showImageSourceSheet = true },
                    onDeleteTapped: {
                        selectedImage = nil
                        selectedImageItem = nil
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
        .presentationDetents([.height(390)])
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
            Text("Save Event")
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
        
        let event = createEvent(userId: userId)
        let validationErrors = injected.interactors.events.validateEvent(event)
        
        guard validationErrors.isEmpty else {
            errorMessage = validationErrors.joined(separator: "\n")
            showError = true
            return
        }
        
        isSaving = true
        
        Task {
            do {
                try await injected.interactors.events.saveEvent(event, image: selectedImage)
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
    
    func createEvent(userId: String) -> Event {
        let amount = Double(admissionAmount)
        
        return Event(
            userId: userId,
            name: eventName,
            eventDate: eventDate,
            startTime: startTime,
            endTime: endTime,
            urlLink: urlLink.isEmpty ? nil : urlLink,
            admission: admission,
            admissionAmount: admission == .paid ? amount : nil,
            requiresRegistration: requiresRegistration,
            registrationDeadline: requiresRegistration ? registrationDeadline : nil,
            category: selectedCategory,
            notes: notes.isEmpty ? nil : notes,
            status: status
        )
    }
}

// MARK: - Previews

#Preview {
    AddEventView()
        .inject(DIContainer(appState: AppState(), interactors: .stub))
}
