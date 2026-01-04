//
//  TimezonePickerView.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 1/4/26.
//  Copyright © 2026 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct TimezonePickerView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTimezone: String
    let onSave: (String) -> Void
    
    @State private var searchText: String = ""
    @State private var tempSelectedTimezone: String = ""
    
    private var filteredTimezones: [String] {
        let allTimezones = TimeZone.knownTimeZoneIdentifiers.sorted()
        
        if searchText.isEmpty {
            return allTimezones
        }
        
        return allTimezones.filter { timezone in
            timezone.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                detectButton
                timezoneList
            }
            .background(Color(hex: "F8F7F1"))
            .navigationTitle("Select Timezone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "11104B"))
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(tempSelectedTimezone)
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "4B7BE2"))
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            tempSelectedTimezone = selectedTimezone
        }
    }
}

// MARK: - Components

private extension TimezonePickerView {
    
    var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(hex: "55564F"))
            
            TextField("Search timezones...", text: $searchText)
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "11104B"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(10)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    var detectButton: some View {
        Button {
            tempSelectedTimezone = TimeZone.current.identifier
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "location.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "4B7BE2"))
                
                Text("Use Device Timezone")
                    .font(.rubik(.medium, size: 14))
                    .foregroundColor(Color(hex: "4B7BE2"))
                
                Spacer()
                
                Text(TimeZone.current.identifier.replacingOccurrences(of: "_", with: " "))
                    .font(.rubik(.regular, size: 12))
                    .foregroundColor(Color(hex: "55564F"))
                    .lineLimit(1)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.white)
        }
        .buttonStyle(.plain)
        .padding(.top, 16)
    }
    
    var timezoneList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredTimezones, id: \.self) { timezone in
                    timezoneRow(timezone)
                }
            }
            .padding(.top, 16)
        }
        .scrollIndicators(.hidden)
    }
    
    func timezoneRow(_ timezone: String) -> some View {
        Button {
            tempSelectedTimezone = timezone
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(timezone.replacingOccurrences(of: "_", with: " "))
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "11104B"))
                    
                    Text(timezoneOffsetString(timezone))
                        .font(.rubik(.regular, size: 12))
                        .foregroundColor(Color(hex: "55564F"))
                }
                
                Spacer()
                
                if tempSelectedTimezone == timezone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "4B7BE2"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.white)
        }
        .buttonStyle(.plain)
    }
    
    func timezoneOffsetString(_ identifier: String) -> String {
        guard let timezone = TimeZone(identifier: identifier) else {
            return ""
        }
        
        let offsetSeconds = timezone.secondsFromGMT()
        let hours = offsetSeconds / 3600
        let minutes = abs((offsetSeconds % 3600) / 60)
        
        let offsetString: String
        if minutes > 0 {
            offsetString = hours >= 0 ? "+\(hours):\(String(format: "%02d", minutes))" : "\(hours):\(String(format: "%02d", minutes))"
        } else {
            offsetString = hours >= 0 ? "+\(hours)" : "\(hours)"
        }
        
        let abbreviation = timezone.abbreviation() ?? ""
        return "GMT\(offsetString) \(abbreviation)"
    }
}

// MARK: - Previews

#Preview {
    TimezonePickerView(
        selectedTimezone: .constant("America/New_York"),
        onSave: { _ in }
    )
}

