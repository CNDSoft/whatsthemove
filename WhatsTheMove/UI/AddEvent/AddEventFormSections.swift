//
//  AddEventFormSections.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/5/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI
import PhotosUI
import MapKit

// MARK: - EventNameSection

struct EventNameSection: View {
    
    @Binding var eventName: String
    
    var body: some View {
        FormRowContainer {
            VStack(alignment: .leading, spacing: 0) {
                FormFieldLabel(text: "Event Name")
                
                TextField("", text: $eventName, prompt: Text("Concert, festival, workshop...")
                    .foregroundColor(Color(hex: "55564F")))
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "55564F"))
            }
        }
    }
}

// MARK: - EventImageSection

struct EventImageSection: View {
    
    @Binding var selectedImage: UIImage?
    var existingImageUrl: String?
    let onUploadTapped: () -> Void
    let onDeleteTapped: () -> Void
    
    var body: some View {
        FormRowContainer {
            VStack(alignment: .leading, spacing: 12) {
                FormFieldLabel(text: "Event Image")
                
                if let image = selectedImage {
                    selectedImagePreview(image: image)
                } else if let urlString = existingImageUrl, let url = URL(string: urlString) {
                    existingImagePreview(url: url)
                } else {
                    imageUploadArea
                }
            }
        }
    }
    
    private var imageUploadArea: some View {
        Button(action: onUploadTapped) {
            VStack(spacing: 20) {
                Image("upload-image")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 104, height: 47)
                
                VStack(spacing: 0) {
                    Text("Upload an image")
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "11104B"))
                    
                    Text("PNG, JPG, GIF up to 5MN")
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "55564F"))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
            .padding(.horizontal, 10)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundColor(Color(hex: "4B4B4B"))
            )
        }
        .buttonStyle(.plain)
    }
    
    private func existingImagePreview(url: URL) -> some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "F8F7F1"))
                    .frame(width: 60, height: 60)
                    .overlay(
                        ProgressView()
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Event Image")
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "11104B"))
                
                Text("From saved event")
                    .font(.rubik(.regular, size: 12))
                    .foregroundColor(Color(hex: "55564F"))
            }
            
            Spacer()
            
            Button {
                onDeleteTapped()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "F25454"))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func selectedImagePreview(image: UIImage) -> some View {
        HStack(spacing: 12) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("From my phone")
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "11104B"))
                
                Text(formatImageSize(image))
                    .font(.rubik(.regular, size: 12))
                    .foregroundColor(Color(hex: "55564F"))
            }
            
            Spacer()
            
            Button(action: onDeleteTapped) {
                Image(systemName: "trash")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "55564F"))
            }
            .buttonStyle(.plain)
        }
    }
    
    private func formatImageSize(_ image: UIImage) -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return "Unknown size"
        }
        let sizeInBytes = Double(imageData.count)
        let sizeInMB = sizeInBytes / (1024 * 1024)
        return String(format: "%.1fMB", sizeInMB)
    }
}

// MARK: - DateSection

struct DateSection: View {
    
    @Binding var eventDate: Date?
    @Binding var showDatePicker: Bool
    
    var body: some View {
        FormRowContainer {
            VStack(alignment: .leading, spacing: 0) {
                FormFieldLabel(text: "Date")
                
                Button {
                    if eventDate == nil {
                        eventDate = Date()
                    }
                    showDatePicker.toggle()
                } label: {
                    FormFieldValue(text: eventDate != nil ? formatDate(eventDate!) : "Select date")
                }
                .buttonStyle(.plain)
                
                if showDatePicker, let date = Binding($eventDate) {
                    DatePicker("", selection: date, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter.string(from: date)
    }
}

// MARK: - TimeSection

struct TimeSection: View {
    
    @Binding var startTime: Date?
    @Binding var endTime: Date?
    @Binding var showStartTimePicker: Bool
    @Binding var showEndTimePicker: Bool
    
    var body: some View {
        FormRowContainer {
            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    startTimeField
                    endTimeField
                }
                
                if showStartTimePicker, let time = Binding($startTime) {
                    DatePicker("", selection: time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding(.top, 10)
                }
                
                if showEndTimePicker, let time = Binding($endTime) {
                    DatePicker("", selection: time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding(.top, 10)
                }
            }
        }
    }
    
    private var startTimeField: some View {
        VStack(alignment: .leading, spacing: 0) {
            FormFieldLabel(text: "Start Time")
            
            Button {
                if startTime == nil {
                    startTime = Date()
                }
                showEndTimePicker = false
                showStartTimePicker.toggle()
            } label: {
                FormFieldValue(text: startTime != nil ? formatTime(startTime!) : "Select time")
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var endTimeField: some View {
        VStack(alignment: .leading, spacing: 0) {
            FormFieldLabel(text: "End Time")
            
            Button {
                if endTime == nil {
                    endTime = Date()
                }
                showStartTimePicker = false
                showEndTimePicker.toggle()
            } label: {
                FormFieldValue(text: endTime != nil ? formatTime(endTime!) : "Select time")
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter.string(from: date)
    }
}

// MARK: - URLLinkSection

struct URLLinkSection: View {
    
    @Binding var urlLink: String
    
    var body: some View {
        FormRowContainer {
            VStack(alignment: .leading, spacing: 0) {
                FormFieldLabel(text: "URL/Link")
                
                HStack(spacing: 8) {
                    TextField("", text: $urlLink, prompt: Text("Paste Instagram, Facebook, or event link")
                        .foregroundColor(Color(hex: "55564F")))
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "55564F"))
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    if !urlLink.isEmpty {
                        Button {
                            urlLink = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "55564F"))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - AdmissionSection

struct AdmissionSection: View {
    
    @Binding var admission: AdmissionType
    @Binding var admissionAmount: String
    
    var body: some View {
        FormRowContainer {
            VStack(alignment: .leading, spacing: 10) {
                FormFieldLabel(text: "Admission")
                
                HStack(spacing: 10) {
                    RadioButton(title: "Free", isSelected: admission == .free) {
                        admission = .free
                    }
                    
                    RadioButton(title: "Paid", isSelected: admission == .paid) {
                        admission = .paid
                    }
                }
                
                if admission == .paid {
                    amountInputField
                }
            }
        }
    }
    
    private var amountInputField: some View {
        CapsuleInputField {
            HStack {
                Text("Enter Amount:")
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "55564F"))
                
                Spacer()
                
                HStack(spacing: 5) {
                    TextField("", text: $admissionAmount, prompt: Text("0")
                        .foregroundColor(Color(hex: "55564F")))
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "55564F"))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    
                    Image(Currency.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 14, height: 14)
                        .foregroundColor(Color(hex: "55564F"))
                }
            }
        }
    }
}

// MARK: - RegistrationSection

struct RegistrationSection: View {
    
    @Binding var requiresRegistration: Bool
    @Binding var registrationDeadline: Date?
    @Binding var showDeadlinePicker: Bool
    
    var body: some View {
        FormRowContainer {
            VStack(alignment: .leading, spacing: 10) {
                FormFieldLabel(text: "Registration Required")
                
                HStack(spacing: 10) {
                    RadioButton(title: "Yes", isSelected: requiresRegistration) {
                        requiresRegistration = true
                    }
                    
                    RadioButton(title: "No", isSelected: !requiresRegistration) {
                        requiresRegistration = false
                    }
                }
                
                if requiresRegistration {
                    deadlineInputField
                    
                    if showDeadlinePicker, let deadline = Binding($registrationDeadline) {
                        DatePicker("", selection: deadline, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                    }
                }
            }
        }
    }
    
    private var deadlineInputField: some View {
        CapsuleInputField {
            HStack {
                Text("Deadline:")
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "55564F"))
                
                Spacer()
                
                Button {
                    if registrationDeadline == nil {
                        registrationDeadline = Date()
                    }
                    showDeadlinePicker.toggle()
                } label: {
                    Text(registrationDeadline != nil ? formatDeadline(registrationDeadline!) : "Select deadline")
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "55564F"))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func formatDeadline(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd / MM / yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - CategorySection

struct CategorySection: View {
    
    @Binding var selectedCategory: EventCategory?
    let onDropdownTapped: () -> Void
    
    var body: some View {
        FormRowContainer {
            VStack(alignment: .leading, spacing: 10) {
                FormFieldLabel(text: "Category")
                
                CapsuleDropdown(
                    text: selectedCategory?.rawValue ?? "Select a category",
                    iconName: selectedCategory?.iconName,
                    action: onDropdownTapped
                )
            }
        }
    }
}

// MARK: - NotesSection

struct NotesSection: View {
    
    @Binding var notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            FormFieldLabel(text: "Notes")
            
            TextField("", text: $notes, prompt: Text("Any additional details...")
                .foregroundColor(Color(hex: "55564F")), axis: .vertical)
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "55564F"))
                .lineLimit(3...6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 15)
        .padding(.bottom, 65)
        .background(Color.white)
    }
}

// MARK: - LocationSection

struct LocationSection: View {
    
    @Binding var location: String
    @StateObject private var searchService = LocationSearchService()
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        FormRowContainer {
            VStack(alignment: .leading, spacing: 0) {
                FormFieldLabel(text: "Location")
                
                ZStack(alignment: .topLeading) {
                    TextField("", text: $searchService.searchQuery, prompt: Text("Venue, Address, City...")
                        .foregroundColor(Color(hex: "55564F")))
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "55564F"))
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            if let firstResult = searchService.searchResults.first {
                                selectLocation(firstResult)
                            }
                        }
                    
                    if !searchService.searchResults.isEmpty && isTextFieldFocused {
                        searchResultsOverlay
                    }
                }
                
                if !location.isEmpty && !isTextFieldFocused {
                    selectedLocationView
                }
            }
        }
        .onChange(of: searchService.searchQuery) { _, newValue in
            if newValue.isEmpty {
                location = ""
            }
        }
    }
    
    private var searchResultsOverlay: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: 35)
            
            VStack(spacing: 0) {
                ForEach(searchService.searchResults.prefix(5), id: \.self) { result in
                    Button {
                        selectLocation(result)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.title)
                                .font(.rubik(.medium, size: 14))
                                .foregroundColor(Color(hex: "11104B"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if !result.subtitle.isEmpty {
                                Text(result.subtitle)
                                    .font(.rubik(.regular, size: 12))
                                    .foregroundColor(Color(hex: "55564F"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white)
                    }
                    .buttonStyle(.plain)
                    
                    if result != searchService.searchResults.prefix(5).last {
                        Divider()
                            .background(Color(hex: "EFEEE7"))
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        }
    }
    
    private var selectedLocationView: some View {
        HStack(spacing: 8) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "11104B"))
            
            Text(location)
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "11104B"))
                .lineLimit(2)
            
            Spacer()
            
            Button {
                clearLocation()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "55564F"))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }
    
    private func selectLocation(_ completion: MKLocalSearchCompletion) {
        location = searchService.selectLocation(completion)
        searchService.searchQuery = location
        isTextFieldFocused = false
    }
    
    private func clearLocation() {
        location = ""
        searchService.clearSearch()
    }
}

// MARK: - StatusSection

struct StatusSection: View {
    
    @Binding var status: EventStatus
    
    var body: some View {
        FormRowContainer {
            VStack(alignment: .leading, spacing: 10) {
                FormFieldLabel(text: "Status")
                
                HStack(spacing: 8) {
                    ForEach(EventStatus.allCases, id: \.self) { eventStatus in
                        CompactRadioButton(title: eventStatus.rawValue, isSelected: status == eventStatus) {
                            status = eventStatus
                        }
                    }
                }
            }
        }
    }
}
