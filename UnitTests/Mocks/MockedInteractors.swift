//
//  MockedInteractors.swift
//  UnitTests
//
//  Created by Alexey Naumov on 07.11.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import Testing
import SwiftUI
import ViewInspector
@testable import Whats The Move

extension DIContainer.Interactors {
    static func mocked(
        countries: [MockedCountriesInteractor.Action] = [],
        images: [MockedImagesInteractor.Action] = [],
        permissions: [MockedUserPermissionsInteractor.Action] = [],
        auth: [MockedAuthInteractor.Action] = []
    ) -> DIContainer.Interactors {
        self.init(
            images: MockedImagesInteractor(expected: images),
            countries: MockedCountriesInteractor(expected: countries),
            userPermissions: MockedUserPermissionsInteractor(expected: permissions),
            auth: MockedAuthInteractor(expected: auth))
    }
    
    func verify(sourceLocation: SourceLocation = #_sourceLocation) {
        (countries as? MockedCountriesInteractor)?
            .verify(sourceLocation: sourceLocation)
        (images as? MockedImagesInteractor)?
            .verify(sourceLocation: sourceLocation)
        (userPermissions as? MockedUserPermissionsInteractor)?
            .verify(sourceLocation: sourceLocation)
        (auth as? MockedAuthInteractor)?
            .verify(sourceLocation: sourceLocation)
    }
}

// MARK: - CountriesInteractor

struct MockedCountriesInteractor: Mock, CountriesInteractor {
    
    enum Action: Equatable {
        case refreshCountriesList
        case loadCountryDetails(country: DBModel.Country, forceReload: Bool)
    }
    
    let actions: MockActions<Action>
    var detailsResponse: Result<DBModel.CountryDetails, Error> = .failure(MockError.valueNotSet)

    init(expected: [Action]) {
        self.actions = .init(expected: expected)
    }

    func refreshCountriesList() async throws {
        register(.refreshCountriesList)
    }

    func loadCountryDetails(country: DBModel.Country, forceReload: Bool) async throws -> DBModel.CountryDetails {
        register(.loadCountryDetails(country: country, forceReload: forceReload))
        return try detailsResponse.get()
    }
}

// MARK: - ImagesInteractor

struct MockedImagesInteractor: Mock, ImagesInteractor {
    
    enum Action: Equatable {
        case loadImage(URL?)
    }
    
    let actions: MockActions<Action>
    
    init(expected: [Action]) {
        self.actions = .init(expected: expected)
    }
    
    func load(image: LoadableSubject<UIImage>, url: URL?) {
        register(.loadImage(url))
    }
}

// MARK: - UserPermissionsInteractor

final class MockedUserPermissionsInteractor: Mock, UserPermissionsInteractor {
    
    enum Action: Equatable {
        case resolveStatus(Permission)
        case request(Permission)
    }
    
    let actions: MockActions<Action>
    
    init(expected: [Action]) {
        self.actions = .init(expected: expected)
    }
    
    func resolveStatus(for permission: Permission) {
        register(.resolveStatus(permission))
    }
    
    func request(permission: Permission) {
        register(.request(permission))
    }
}

// MARK: - AuthInteractor

struct MockedAuthInteractor: Mock, AuthInteractor {
    
    enum Action: Equatable {
        case signIn(email: String, password: String)
        case signUp(email: String, password: String, name: String)
        case signOut
        case checkAuthStatus
    }
    
    let actions: MockActions<Action>
    var authStatusResponse: Bool = false
    
    init(expected: [Action]) {
        self.actions = .init(expected: expected)
    }
    
    func signIn(email: String, password: String) async throws {
        register(.signIn(email: email, password: password))
    }
    
    func signUp(email: String, password: String, name: String) async throws {
        register(.signUp(email: email, password: password, name: name))
    }
    
    func signOut() async throws {
        register(.signOut)
    }
    
    func checkAuthStatus() async -> Bool {
        register(.checkAuthStatus)
        return authStatusResponse
    }
}
