//
//  AddressSummaryDataFetchers.swift
//  omgui
//
//  Created by Calvin Chestnut on 7/29/24.
//

import Blackbird
import Combine
import Foundation
import SwiftUI

class AddressSummaryDataFetcher: DataFetcher {
    
    let addressBook: AddressBook
    let database: Blackbird.Database
    
    var addressName: AddressName
    
    var verified: Bool?
    var url: URL?
    var registered: Date?
    
    var iconURL: URL? {
        addressName.addressIconURL
    }
    
    var statuses: [String: StatusDataFetcher] = [:]
    var purls: [String: AddressPURLDataFetcher] = [:]
    var pastes: [String: AddressPasteDataFetcher] = [:]
    
    var iconFetcher: AddressIconDataFetcher
    var profileFetcher: AddressProfileDataFetcher
    var nowFetcher: AddressNowDataFetcher
    var purlFetcher: AddressPURLsDataFetcher
    var pasteFetcher: AddressPasteBinDataFetcher
    var statusFetcher: StatusLogDataFetcher
    var bioFetcher: AddressBioDataFetcher
    
    var followingFetcher: AddressFollowingDataFetcher
    
    init(
        name: AddressName,
        addressBook: AddressBook,
        interface: DataInterface,
        database: Blackbird.Database
    ) {
        self.addressBook = addressBook
        self.database = database
        self.addressName = name
        let isMine = addressBook.myAddresses.contains(name)
        let credential: APICredential? = isMine ? addressBook.apiKey : nil
        self.iconFetcher = .init(address: name, interface: interface, db: database)
        self.profileFetcher = .init(name: name, credential: nil, interface: interface, db: database)
        self.nowFetcher = .init(name: name, interface: interface, db: database)
        self.purlFetcher = .init(name: name, credential: credential, addressBook: addressBook, interface: interface, db: database)
        self.pasteFetcher = .init(name: name, credential: credential, addressBook: addressBook, interface: interface, db: database)
        self.statusFetcher = .init(addresses: [name], addressBook: addressBook, interface: interface, db: database)
        self.bioFetcher = .init(address: name, interface: interface)
        self.followingFetcher = .init(address: name, credential: credential, interface: interface)
        
        super.init(interface: interface)
    }
    
    func configure(name: AddressName, _ automation: AutomationPreferences = .init()) {
        self.addressName = name
        
        let credential: APICredential? = addressBook.apiKey
        self.iconFetcher = .init(address: name, interface: interface, db: database)
        self.profileFetcher = .init(name: name, credential: credential, interface: interface, db: database)
        self.nowFetcher = .init(name: name, interface: interface, db: database)
        self.purlFetcher = .init(name: name, credential: credential, addressBook: addressBook, interface: interface, db: database)
        self.pasteFetcher = .init(name: name, credential: credential, addressBook: addressBook, interface: interface, db: database)
        self.statusFetcher = .init(addresses: [name], addressBook: addressBook, interface: interface, db: database)
        self.bioFetcher = .init(address: name, interface: interface)
        self.followingFetcher = .init(address: name, credential: credential, interface: interface)
        
        super.configure(automation)
    }
    
    override func perform() async {
        guard !addressName.isEmpty else {
            return
        }
        await super.perform()
        
        await iconFetcher.updateIfNeeded(forceReload: true)
        await profileFetcher.updateIfNeeded(forceReload: true)
        await nowFetcher.updateIfNeeded(forceReload: true)
        await purlFetcher.updateIfNeeded(forceReload: true)
        await pasteFetcher.updateIfNeeded(forceReload: true)
        await statusFetcher.updateIfNeeded(forceReload: true)
        await bioFetcher.updateIfNeeded(forceReload: true)
        await followingFetcher.updateIfNeeded(forceReload: true)
        
        await fetchFinished()
    }
    
    override func throwingRequest() async throws {
        guard !addressName.isEmpty else {
            return
        }
        url = URL(string: "https://\(addressName).omg.lol")
        let info = try await interface.fetchAddressInfo(addressName)
        self.verified = false
        self.registered = info.date
        self.url = info.url
        
        await self.fetchFinished()
    }
    
    func statusFetcher(for id: String) -> StatusDataFetcher {
        guard let fetcher = statuses[id] else {
            let newFetcher = StatusDataFetcher(id: id, from: addressName, interface: interface, db: database)
            statuses[id] = newFetcher
            return newFetcher
        }
        return fetcher
    }
    
    func purlFetcher(for id: String) -> AddressPURLDataFetcher {
        guard let fetcher = purls[id] else {
            let newFetcher = AddressPURLDataFetcher(name: addressName, title: id, credential: addressBook.credential(for: addressName), interface: interface, db: database)
            purls[id] = newFetcher
            return newFetcher
        }
        return fetcher
    }
    
    func pasteFetcher(for id: String) -> AddressPasteDataFetcher {
        guard let fetcher = pastes[id] else {
            let newFetcher = AddressPasteDataFetcher(name: addressName, title: id, credential: addressBook.credential(for: addressName), interface: interface, db: database)
            pastes[id] = newFetcher
            return newFetcher
        }
        return fetcher
    }
}

class AddressPrivateSummaryDataFetcher: AddressSummaryDataFetcher {
    let blockedFetcher: AddressBlockListDataFetcher
    
//    @ObservedObject
//    var profilePoster: ProfileDraftPoster
//    @ObservedObject
//    var nowPoster: NowDraftPoster
    
    override init(
        name: AddressName,
        addressBook: AddressBook,
        interface: DataInterface,
        database: Blackbird.Database
    ) {
        self.blockedFetcher = .init(address: name, credential: addressBook.apiKey, interface: interface)
        
//        self.profilePoster = .init(
//            name,
//            draftItem: .init(
//                address: name,
//                content: "",
//                publish: true
//            ),
//            interface: interface,
//            credential: credential
//        )!
//        self.nowPoster = .init(
//            name,
//            draftItem: .init(
//                address: name,
//                content: "",
//                listed: true
//            ),
//            interface: interface,
//            credential: credential
//        )!
        
        super.init(name: name, addressBook: addressBook, interface: interface, database: database)
        
        self.profileFetcher = .init(name: addressName, credential: nil, interface: interface, db: database)
        self.followingFetcher = .init(address: addressName, credential: addressBook.apiKey, interface: interface)
        
        self.purlFetcher = .init(name: addressName, credential: addressBook.apiKey, addressBook: addressBook, interface: interface, db: database)
        self.pasteFetcher = .init(name: addressName, credential: addressBook.apiKey, addressBook: addressBook, interface: interface, db: database)
    }
    
    override func perform() async {
        guard !addressName.isEmpty else {
            return
        }
        await blockedFetcher.perform()
        await super.perform()
    }
}

