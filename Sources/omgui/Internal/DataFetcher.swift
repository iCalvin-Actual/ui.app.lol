//
//  File.swift
//  
//
//  Created by Calvin Chestnut on 3/5/23.
//

import AuthenticationServices
import Foundation

class DataFetcher: NSObject, ObservableObject {
    let interface: DataInterface
    
    @Published
    var loaded: Bool = false
    @Published
    var loading: Bool = false
    
    var error: Error?
    
    init(interface: DataInterface, autoLoad: Bool = true) {
        self.interface = interface
        super.init()
        if autoLoad {
            Task {
                await update()
            }
        }
    }
    
    func update() async {
        do {
            try await throwingUpdate()
        } catch {
            handle(error)
        }
    }
    
    func throwingUpdate() async throws {
        DispatchQueue.main.async {
            self.loading = true
        }
    }
    
    func fetchFinished() {
        DispatchQueue.main.async {
            self.loaded = true
            self.loading = false
            self.objectWillChange.send()
        }
    }
    
    func handle(_ error: Error) {
        self.loaded = false
        self.loading = false
        self.error = error
        self.objectWillChange.send()
    }
}

class AccountAuthDataFetcher: DataFetcher, ASWebAuthenticationPresentationContextProviding {
    private var webSession: ASWebAuthenticationSession?
    
    @Published
    var authToken: String?
    
    init(client: ClientInfo, interface: DataInterface) {
        super.init(interface: interface, autoLoad: false)
        guard let url = interface.authURL() else {
            return
        }
        self.webSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: client.urlScheme
        ) { (url, error) in
            guard let url = url else {
                if let error = error {
                    print("Error \(error)")
                } else {
                    print("Unknown error")
                }
                return
            }
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
            
            guard let code = components?.queryItems?.filter ({ $0.name == "code" }).first?.value else {
                return
            }
            Task {
                let token = try await interface.fetchAccessToken(
                    authCode: code,
                    clientID: client.id,
                    clientSecret: client.secret,
                    redirect: client.redirectUrl
                )
                self.authToken = token
            }
        }
        self.webSession?.presentationContextProvider = self
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
    
    override func throwingUpdate() async throws {
        self.webSession?.start()
    }
}

class ListDataFetcher<T: Listable>: DataFetcher {
    
    @Published
    var listItems: [T] = []
    
    init(items: [T] = [], interface: DataInterface) {
        self.listItems = items
        super.init(interface: interface)
        self.loaded = items.isEmpty
    }
}

class AddressDirectoryDataFetcher: ListDataFetcher<AddressModel> {
    override func throwingUpdate() async throws {
        try await super.throwingUpdate()
        Task {
            do {
                let directory = try await interface.fetchAddressDirectory()
                DispatchQueue.main.async {
                    self.listItems = directory.map({ AddressModel(name: $0) })
                    self.fetchFinished()
                }
            } catch {
                self.handle(error)
            }
        }
    }
}

class AccountAddressDataFetcher: ListDataFetcher<AddressModel> {
    private let credential: String
    
    init(interface: DataInterface, credential: APICredential) {
        self.credential = credential
        super.init(items: [], interface: interface)
    }
    
    override func throwingUpdate() async throws {
        try await super.throwingUpdate()
        Task {
            do {
                self.listItems = try await interface.fetchAccountAddresses(credential).map({ AddressModel(name: $0) })
                self.fetchFinished()
            } catch {
                self.handle(error)
            }
        }
    }
}

class AddressBioDataFetcher: DataFetcher {
    let address: AddressName
    
    @Published
    var bio: AddressBioModel?
    
    init(address: AddressName, interface: DataInterface) {
        self.address = address
        super.init(interface: interface)
    }
    
    override func throwingUpdate() async throws {
        try await super.throwingUpdate()
        Task {
            let bio = try await interface.fetchAddressBio(address)
            DispatchQueue.main.async {
                self.bio = bio
                self.fetchFinished()
            }
        }
    }
}

class AddressFollowingDataFetcher: ListDataFetcher<AddressModel> {
    let address: AddressName
    
    init(address: AddressName, interface: DataInterface) {
        self.address = address
        super.init(interface: interface)
    }
    
    override func throwingUpdate() async throws {
        try await super.throwingUpdate()
        Task {
            guard let content = try await interface.fetchPaste("app.lol.following", from: address)?.content else {
                self.fetchFinished()
                return
            }
            let list = content.split(separator: "\n").map({ String($0) })
            DispatchQueue.main.async {
                self.listItems = list.map({ AddressModel(name: $0) })
                self.fetchFinished()
            }
        }
    }
}

class AddressBlockListDataFetcher: ListDataFetcher<AddressModel> {
    let address: AddressName
    
    init(address: AddressName, interface: DataInterface) {
        self.address = address
        super.init(interface: interface)
    }
    
    override func throwingUpdate() async throws {
        try await super.throwingUpdate()
        Task {
            guard let content = try await interface.fetchPaste("app.lol.blockList", from: address)?.content else {
                self.fetchFinished()
                return
            }
            let list = content.split(separator: "\n").map({ String($0) })
            DispatchQueue.main.async {
                self.listItems = list.map({ AddressModel(name: $0) })
                self.fetchFinished()
            }
        }
    }
}

class StatusLogDataFetcher: ListDataFetcher<StatusModel> {
    let addresses: [AddressName]
    
    init(addresses: [AddressName] = [], statuses: [StatusModel] = [], interface: DataInterface) {
        self.addresses = addresses
        super.init(items: statuses, interface: interface)
    }
    
    override func throwingUpdate() async throws {
        try await super.throwingUpdate()
        if addresses.isEmpty {
            Task {
                let statuses = try await interface.fetchStatusLog()
                DispatchQueue.main.async {
                    self.listItems = statuses
                    self.fetchFinished()
                }
            }
        } else {
            Task {
                let statuses = try await interface.fetchAddressStatuses(addresses: addresses)
                DispatchQueue.main.async {
                    self.listItems = statuses
                    self.fetchFinished()
                }
            }
        }
    }
}

class NowGardenDataFetcher: ListDataFetcher<NowListing> {
    override func throwingUpdate() async throws {
        try await super.throwingUpdate()
        Task {
            let garden = try await interface.fetchNowGarden()
            self.listItems = garden
            self.fetchFinished()
        }
    }
}

class AddressProfileDataFetcher: DataFetcher {
    
    let addressName: AddressName
    
    var html: String?
    
    init(name: AddressName, interface: DataInterface) {
        self.addressName = name
        super.init(interface: interface)
    }
    
    override func throwingUpdate() async throws {
        try await super.throwingUpdate()
        Task {
            let profile = try await interface.fetchAddressProfile(addressName)
            self.html = profile?.content
            self.fetchFinished()
        }
    }
    
    var theme: String {
        return ""
    }
}

class AddressNowDataFetcher: DataFetcher {
    let addressName: AddressName
    
    var content: String?
    var updated: Date?
    
    var listed: Bool?
    
    init(name: AddressName, interface: DataInterface) {
        self.addressName = name
        super.init(interface: interface)
    }
    
    override func throwingUpdate() async throws {
        try await super.throwingUpdate()
        Task {
            let now = try await interface.fetchAddressNow(addressName)
            self.content = now?.content
            self.updated = now?.updated
            self.listed = now?.listed
            self.fetchFinished()
        }
    }
}

class AddressPasteBinDataFetcher: ListDataFetcher<PasteModel> {
    let addressName: AddressName
    
    init(name: AddressName, pastes: [PasteModel] = [], interface: DataInterface) {
        self.addressName = name
        super.init(items: pastes, interface: interface)
    }
    
    override func throwingUpdate() async throws {
        try await super.throwingUpdate()
        Task {
            let pastes = try await interface.fetchAddressPastes(addressName)
            DispatchQueue.main.async {
                self.listItems = pastes
                self.fetchFinished()
            }
        }
    }
}

class AddressPURLsDataFetcher: ListDataFetcher<PURLModel> {
    let addressName: AddressName
    
    init(name: AddressName, purls: [PURLModel] = [], interface: DataInterface) {
        self.addressName = name
        super.init(items: purls, interface: interface)
    }
    
    override func throwingUpdate() async throws {
        try await super.throwingUpdate()
        Task {
            let purls = try await interface.fetchAddressPURLs(addressName)
            DispatchQueue.main.async {
                self.listItems = purls
                self.fetchFinished()
            }
        }
    }
}

class AddressSummaryDataFetcher: DataFetcher {
    
    let addressName: AddressName
    
    var verified: Bool?
    var url: URL?
    var registered: Date?
    
    var profileFetcher: AddressProfileDataFetcher
    var nowFetcher: AddressNowDataFetcher
    var purlFetcher: AddressPURLsDataFetcher
    var pasteFetcher: AddressPasteBinDataFetcher
    var statusFetcher: StatusLogDataFetcher
    var bioFetcher: AddressBioDataFetcher
    
    init(
        name: AddressName,
        profileFetcher: AddressProfileDataFetcher? = nil,
        nowFetcher: AddressNowDataFetcher? = nil,
        purlFetcher: AddressPURLsDataFetcher? = nil,
        pasteFetcher: AddressPasteBinDataFetcher? = nil,
        interface: DataInterface
    ) {
        self.addressName = name
        self.profileFetcher = profileFetcher ?? .init(name: name, interface: interface)
        self.nowFetcher = nowFetcher ?? .init(name: name, interface: interface)
        self.purlFetcher = purlFetcher ?? .init(name: name, interface: interface)
        self.pasteFetcher = pasteFetcher ?? .init(name: name, interface: interface)
        self.statusFetcher = .init(addresses: [name], interface: interface)
        self.bioFetcher = .init(address: name, interface: interface)
        super.init(interface: interface)
    }
    
    override func throwingUpdate() async throws {
        try await super.throwingUpdate()
        Task {
            verified = false
            registered = Date()
            url = URL(string: "https://\(addressName).omg.lol")
            let info = try await interface.fetchAddressInfo(addressName)
            self.verified = false
            self.registered = info.registered
            self.url = info.url
            
            try await profileFetcher.throwingUpdate()
            try await nowFetcher.throwingUpdate()
            try await purlFetcher.throwingUpdate()
            try await pasteFetcher.throwingUpdate()
            try await statusFetcher.throwingUpdate()
            try await bioFetcher.throwingUpdate()
            self.fetchFinished()
        }
    }
}
