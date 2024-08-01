//
//  File.swift
//  
//
//  Created by Calvin Chestnut on 3/5/23.
//

import Blackbird
import Combine
import SwiftUI

@MainActor
class AccountModel: ObservableObject {
    @AppStorage("app.lol.auth", store: .standard)
    var authKey: String = ""
    
    @AppStorage("app.lol.addresses.cache", store: .standard)
    private var localAddressesCache: String = ""
    public var localAddresses: [String] {
        get {
            localAddressesCache.split(separator: "&&&").map({ String($0) })
        }
        set {
            localAddressesCache = newValue.joined(separator: "&&&")
        }
    }
    
    @ObservedObject
    private var authenticationFetcher: AccountAuthDataFetcher
    
    @ObservedObject
    public var pinnedAddressFetcher: PinnedListDataFetcher
    
    private var accountInfoFetcher: AccountInfoDataFetcher?
    
    @Published
    public var myAddressesFetcher: AccountAddressDataFetcher?
    
    public let globalBlocklistFetcher: AddressBlockListDataFetcher
    public let localBloclistFetcher: LocalBlockListDataFetcher
    
    var myAddresses: [AddressName] {
        let fetchedAddresses = myAddressesFetcher?.results.map { $0.addressName } ?? []
        guard !fetchedAddresses.isEmpty else {
            return localAddresses
        }
        return fetchedAddresses
    }
    var globalBlocked: [AddressName] {
        globalBlocklistFetcher.results.map { $0.addressName }
    }
    var localBlocked: [AddressName] {
        localBloclistFetcher.results.map { $0.addressName }
    }
    
    let interface: DataInterface
    let database: Blackbird.Database
    
    var loaded: Bool = false
    var loading: Bool = false
    
    var error: Error?
    
    var requests: [AnyCancellable] = []
    
    var publicProfileCache: [AddressName: AddressSummaryDataFetcher] = [:]
    
    var pinned: [AddressName] {
        pinnedAddressFetcher.results.map { $0.addressName }
    }
    func isPinned(_ address: AddressName) -> Bool {
        pinned.contains(address)
    }
    func pin(_ address: AddressName) {
        pinnedAddressFetcher.pin(address)
    }
    func removePin(_ address: AddressName) {
        pinnedAddressFetcher.removePin(address)
    }
    
    init(client: ClientInfo, interface: DataInterface, database: Blackbird.Database) {
        self.authenticationFetcher = AccountAuthDataFetcher(
            client: client,
            interface: interface
        )
        
        self.interface = interface
        self.database = database
        self.pinnedAddressFetcher = PinnedListDataFetcher(interface: interface)
        self.globalBlocklistFetcher = AddressBlockListDataFetcher(address: "app", credential: nil, interface: interface, db: database)
        self.localBloclistFetcher = LocalBlockListDataFetcher(interface: interface)
        
        subscribe()
        
        Task {
            await perform()
        }
    }
    
    @MainActor
    func subscribe() {
        authenticationFetcher.$authToken
            .sink { newValue in
                let newValue = newValue ?? ""
                guard !newValue.isEmpty else {
                    return
                }
                Task { [weak self] in
                    await self?.login(newValue)
                }
            }
            .store(in: &requests)
    }
    
    func perform() async {
        loading = true
        threadSafeSendUpdate()
        do {
            try await throwingRequest()
        } catch {
            handle(error)
        }
    }
    
    func login(_ incomingAuthKey: APICredential) async {
        authKey = incomingAuthKey
        await perform()
    }
    
    func logout() async {
        self.authKey = ""
        self.localAddresses = []
        await self.perform()
    }
    
    func throwingRequest() async throws {
        guard !authKey.isEmpty else {
            accountInfoFetcher = nil
            threadSafeSendUpdate()
            return
        }
        myAddressesFetcher = AccountAddressDataFetcher(credential: authKey, interface: interface, db: database)
        myAddressesFetcher?.objectWillChange.sink { [weak self] _ in
            guard let self = self else { return }
            self.handleAddresses(self.myAddresses)
        }
        .store(in: &requests)
        
        self.accountInfoFetcher = AccountInfoDataFetcher(address: "application", interface: interface, credential: authKey)
        self.accountInfoFetcher?.objectWillChange.sink { [self] _ in
            self.threadSafeSendUpdate()
        }
        .store(in: &self.requests)
    }
    
    func fetchFinished() {
        loaded = true
        loading = false
        threadSafeSendUpdate()
    }
    
    func handle(_ incomingError: Error) {
        loaded = false
        loading = false
        error = incomingError
        threadSafeSendUpdate()
    }
    
    func handleAddresses(_ incomingAddresses: [AddressName]) {
        incomingAddresses.forEach { address in
            publicProfileCache[address] = AddressSummaryDataFetcher(name: address, interface: interface, database: database)
        }
        threadSafeSendUpdate()
    }
    
    func threadSafeSendUpdate() {
        objectWillChange.send()
    }
    
    var welcomeText: String {
        guard let accountName = accountInfoFetcher?.accountName else {
            return "Welcome"
        }
        return "Welcome, \(accountName)"
    }
    
    var displayName: String {
        accountInfoFetcher?.accountName ?? ""
    }
    
    var signedIn: Bool {
        !authKey.isEmpty
    }
    
    func authenticate() async {
        await logout()
        authenticationFetcher.perform()
    }
    
    public func credential(for address: AddressName, in addressBook: AddressBook) -> APICredential? {
        guard !authKey.isEmpty, addressBook.myAddresses.contains(address) else {
            return nil
        }
        return authKey
    }
    
    var listItems: [AddressModel] {
        get { myAddressesFetcher?.results ?? [] }
        set { }
    }
}
