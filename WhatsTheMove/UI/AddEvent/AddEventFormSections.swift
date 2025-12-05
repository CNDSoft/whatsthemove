//
//  AddEventFormSections.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/5/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI
import PhotosUI

// MARK: - EventNameSection

struct EventNameSection: View {
    
    @Binding var eventName: String
    
    var body: some View {
        FormRowContainer {
            VStack(alignment: .leading, spacing: 0) {
                FormFieldLabel(text: "Event Name")
                
                TextField("Concert, festival, workshop...", text: $eventName)
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "55564F"))
            }
        }
    }
}

// MARK: - EventImageSection

struct EventImageSection: View {
    
    @Binding var selectedImage: UIImage?
    let onUploadTapped: () -> Void
    let onDeleteTapped: () -> Void
    
    var body: some View {
        FormRowContainer {
            VStack(alignment: .leading, spacing: 5) {
                FormFieldLabel(text: "Event Image")
                
                imageUploadArea
                
                if selectedImage != nil {
                    selectedImagePreview
                }
            }
        }
    }
    
    private var imageUploadArea: some View {
        Button(action: onUploadTapped) {
            VStack(spacing: 20) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "55564F"))
                
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
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundColor(Color(hex: "4B4B4B"))
            )
        }
        .buttonStyle(.plain)
    }
    
    private var selectedImagePreview: some View {
        HStack(spacing: 15) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text("From my phone")
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "55564F"))
                
                Text("Selected")
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "55564F"))
            }
            
            Spacer()
            
            Button(action: onDeleteTapped) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "55564F"))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - DateSection

struct DateSection: View {
    
    @Binding var eventDate: Date
    @Binding var showDatePicker: Bool
    
    var body: some View {
        FormRowContainer {
            VStack(alignment: .leading, spacing: 0) {
                FormFieldLabel(text: "Date")
                
                Button {
                    showDatePicker.toggle()
                } label: {
                    FormFieldValue(text: formatDate(eventDate))
                }
                .buttonStyle(.plain)
                
                if showDatePicker {
                    DatePicker("", selection: $eventDate, displayedComponents: .date)
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
    
    @Binding var startTime: Date
    @Binding var endTime: Date
    @Binding var showStartTimePicker: Bool
    @Binding var showEndTimePicker: Bool
    
    var body: some View {
        FormRowContainer {
            HStack(alignment: .top) {
                startTimeField
                endTimeField
            }
        }
    }
    
    private var startTimeField: some View {
        VStack(alignment: .leading, spacing: 0) {
            FormFieldLabel(text: "Start Time")
            
            Button {
                showStartTimePicker.toggle()
            } label: {
                FormFieldValue(text: formatTime(startTime))
            }
            .buttonStyle(.plain)
            
            if showStartTimePicker {
                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var endTimeField: some View {
        VStack(alignment: .leading, spacing: 0) {
            FormFieldLabel(text: "End Time")
            
            Button {
                showEndTimePicker.toggle()
            } label: {
                FormFieldValue(text: formatTime(endTime))
            }
            .buttonStyle(.plain)
            
            if showEndTimePicker {
                DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
            }
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
                
                TextField("Paste Instagram, Facebook, or event link", text: $urlLink)
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "55564F"))
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
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
                    TextField("0", text: $admissionAmount)
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "55564F"))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    
                    Text("$")
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "55564F"))
                }
            }
        }
    }
}

// MARK: - RegistrationSection

struct RegistrationSection: View {
    
    @Binding var requiresRegistration: Bool
    @Binding var registrationDeadline: Date
    @Binding var showDeadlinePicker: Bool
    
    var body: some View {
        FormRowContainer {
            VStack(alignment: .leading, spacing: 10) {
                FormFieldLabel(text: "Requires Registration")
                
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
                    
                    if showDeadlinePicker {
                        DatePicker("", selection: $registrationDeadline, displayedComponents: .date)
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
                    showDeadlinePicker.toggle()
                } label: {
                    Text(formatDeadline(registrationDeadline))
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
            
            TextField("Any additional details...", text: $notes, axis: .vertical)
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
