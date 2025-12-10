//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Cem Sertkaya on 10.12.2025.
//  Copyright © 2025 Alexey Naumov. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    
    private var sharedData = SharedEventData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(red: 248/255, green: 247/255, blue: 241/255, alpha: 1.0)
        
        setupUI()
        extractSharedContent()
    }
    
    private func setupUI() {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 16
        view.addSubview(containerView)
        
        let logoImageView = UIImageView()
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.image = UIImage(named: "wtm-logo")
        containerView.addSubview(logoImageView)
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Saving to WhatsTheMove"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = UIColor(red: 17/255, green: 16/255, blue: 75/255, alpha: 1.0)
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)
        
        let messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.text = "Extracting event details..."
        messageLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        messageLabel.textColor = UIColor(red: 85/255, green: 86/255, blue: 79/255, alpha: 1.0)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        containerView.addSubview(messageLabel)
        
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()
        containerView.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            logoImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            logoImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 60),
            logoImageView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            activityIndicator.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            activityIndicator.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30)
        ])
    }
    
    private func extractSharedContent() {
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            openMainApp()
            return
        }
        
        var hasProcessedContent = false
        let dispatchGroup = DispatchGroup()
        
        for item in inputItems {
            guard let attachments = item.attachments else { continue }
            
            for attachment in attachments {
                if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    dispatchGroup.enter()
                    hasProcessedContent = true
                    
                    attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] data, error in
                        defer { dispatchGroup.leave() }
                        
                        guard error == nil, let url = data as? URL else { return }
                        
                        self?.sharedData.urlLink = url.absoluteString
                        self?.extractMetadata(from: url)
                    }
                } else if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    dispatchGroup.enter()
                    hasProcessedContent = true
                    
                    attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] data, error in
                        defer { dispatchGroup.leave() }
                        
                        guard error == nil else { return }
                        
                        if let url = data as? URL {
                            if let imageData = try? Data(contentsOf: url) {
                                if let image = UIImage(data: imageData) {
                                    if let compressedData = image.jpegData(compressionQuality: 0.7) {
                                        self?.sharedData.imageData = compressedData
                                    } else {
                                        self?.sharedData.imageData = imageData
                                    }
                                } else {
                                    self?.sharedData.imageData = imageData
                                }
                            }
                        } else if let image = data as? UIImage {
                            if let imageData = image.jpegData(compressionQuality: 0.7) {
                                self?.sharedData.imageData = imageData
                            }
                        } else if let imageData = data as? Data {
                            self?.sharedData.imageData = imageData
                        }
                    }
                } else if attachment.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                    dispatchGroup.enter()
                    hasProcessedContent = true
                    
                    attachment.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { [weak self] data, error in
                        defer { dispatchGroup.leave() }
                        
                        guard error == nil, let text = data as? String else { return }
                        
                        if self?.sharedData.title == nil || self?.sharedData.title?.isEmpty == true {
                            self?.sharedData.title = text
                        }
                        if self?.sharedData.description == nil || self?.sharedData.description?.isEmpty == true {
                            self?.sharedData.description = text
                        }
                    }
                }
            }
        }
        
        if !hasProcessedContent {
            openMainApp()
            return
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.openMainApp()
            }
        }
    }
    
    private func extractMetadata(from url: URL) {
        Task {
            do {
                let metadata = try await MetadataExtractor.extractMetadata(from: url)
                await MainActor.run {
                    if sharedData.title == nil || sharedData.title?.isEmpty == true {
                        sharedData.title = metadata.title
                    }
                    if sharedData.description == nil || sharedData.description?.isEmpty == true {
                        sharedData.description = metadata.description
                    }
                    if sharedData.imageData == nil, let imageUrlString = metadata.imageUrl, let imageUrl = URL(string: imageUrlString) {
                        Task {
                            if let imageData = try? Data(contentsOf: imageUrl) {
                                await MainActor.run {
                                    sharedData.imageData = imageData
                                }
                            }
                        }
                    }
                }
            } catch {
            }
        }
    }
    
    private func openMainApp() {
        guard let encodedData = encodeSharedData() else {
            completeRequest()
            return
        }
        
        let urlString = "wtm://add-event?data=\(encodedData)"
        guard let url = URL(string: urlString) else {
            completeRequest()
            return
        }
        
        openURL(url)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.completeRequest()
        }
    }
    
    @objc @discardableResult private func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                if #available(iOS 18.0, *) {
                    application.open(url, options: [:], completionHandler: nil)
                    return true
                } else {
                    return application.perform(#selector(openURL(_:)), with: url) != nil
                }
            }
            responder = responder?.next
        }
        
        extensionContext?.open(url, completionHandler: nil)
        return true
    }
    
    private func encodeSharedData() -> String? {
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(sharedData) else {
            return nil
        }
        return jsonData.base64EncodedString()
    }
    
    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
