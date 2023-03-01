import SwiftUI


@MainActor
@available(iOS 16.1, *)
class AppModel: ObservableObject {
    
    nonisolated static let clientId: String = "5e171c460ba4b7a7ceaf86295ac169d2"
    nonisolated static let clientSecret: String = "6937ec29a6811d676615d783ab071bb8"
    nonisolated static let clientRedirect: String = "app-omg-lol://oauth"
    
    @ObservedObject
    internal var modelFetcher: AppModelDataFetcher
    
    @Published
    public var accountModel: AccountModel = .init()
                        
    @AppStorage("app.lol.auth", store: .standard)
    private var authKey: String = ""
    
    @AppStorage("app.lol.theme", store: .standard)
    private var selectedTheme: String = "unsupported"
    
    private var profileModels: [AddressName: AddressDetailsDataFetcher] = [:]
    
    internal var fetchConstructor: FetchConstructor
    
    internal init(interface: OMGDataInterface) {
        self.fetchConstructor = FetchConstructor(interface: interface)
        self.modelFetcher = fetchConstructor.appModelDataFetcher()

        Task {
            fetch()
        }
    }
    
    private func fetch() {
        Task {
            await self.modelFetcher.update()
        }
        
        // Fetch pinned addresses
        
        // Fetch self addresses
    }
    
    internal func login(_ authKey: String) {
        self.authKey = authKey
        // Fetch addresses for account
        // Add addresses to pinned list
        // Fetch app.lol settings for addresses
    }
    
    internal func addressDetails(_ address: AddressName) -> AddressDetailsDataFetcher {
        if let model = profileModels[address] {
            return model
        } else {
            let newModel = fetchConstructor.addressDetailsFetcher(address)
            profileModels[address] = newModel
            return newModel
        }
    }
}

@available(iOS 16.1, *)
@available(macCatalyst 16.1, *)
internal extension AppModel {
    var directory: [AddressModel] { modelFetcher.directory }
}

