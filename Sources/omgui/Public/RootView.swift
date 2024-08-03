//
//  ContentView.swift
//  appDOTlol
//
//  Created by Calvin Chestnut on 3/5/23.
//

import Blackbird
import SwiftUI

@MainActor
struct RootView: View {
    
    @AppStorage("app.lol.auth")
    var authKey: String = ""
    @AppStorage("app.lol.blocked")
    var localBlockedAddresses: String = ""
    @AppStorage("app.lol.cache.myAddresses")
    var localAddressesCache: String = ""
    @AppStorage("app.lol.cache.pinned")
    var currentlyPinnedAddresses: String = "adam&&&app"
    @AppStorage("app.lol.cache.name")
    var myName: String = ""
    
    @SceneStorage("app.lol.address")
    var actingAddress: String = ""
    
    @Environment(\.blackbirdDatabase)
    var db
    @EnvironmentObject
    var fetcher: FetchConstructor

    
    var body: some View {
        SplitView()
            .environment(
                SceneModel(
                    fetcher: fetcher,
                    authKey: $authKey,
                    localBlocklist: $localBlockedAddresses,
                    pinnedAddresses: $currentlyPinnedAddresses,
                    myAddresses: $localAddressesCache,
                    myName: $myName,
                    actingAddress: $actingAddress
                )
            )
    }
}

struct ContentView_Previews: PreviewProvider {
    @StateObject
    static var database = try! Blackbird.Database.inMemoryDatabase()
    
    static var previews: some View {
        RootView()
    }
}
