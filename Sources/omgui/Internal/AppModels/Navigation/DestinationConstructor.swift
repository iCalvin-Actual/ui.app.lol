//
//  File.swift
//  
//
//  Created by Calvin Chestnut on 3/10/23.
//

import SwiftUI

@MainActor
struct DestinationConstructor {
    let addressBook: AddressBook
    let accountModel: AccountModel
    let fetchConstructor: FetchConstructor

    @ViewBuilder
    func destination(_ destination: NavigationDestination? = nil) -> some View {
        appliedDestination(destination)
            .environment(addressBook)
    }
    
    @ViewBuilder
    func appliedDestination(_ destination: NavigationDestination? = nil) -> some View {
        let destination = destination ?? .community
        switch destination {
        case .directory:
            DirectoryView(fetcher: addressBook.directoryFetcher)
        case .community:
            CommunityView(addressBook: addressBook)
        case .address(let name):
            AddressSummaryView(addressSummaryFetcher: addressBook.addressSummary(name), allowEditing: addressBook.actingAddress == name, selectedPage: .profile, address: name)
                .toolbarRole(.editor)
        case .webpage(let name):
            AddressProfileView(address: name)
        case .now(let name):
            AddressNowView(address: name)
        case .blocked:
            ListView<AddressModel, ListRow<AddressModel>, EmptyView>(filters: .none, data: addressBook.constructBlocklist().listItems, rowBuilder: { _ in return nil as ListRow<AddressModel>? })
        case .following:
            FollowingView(addressBook)
        case .followingAddresses:
            if let fetcher = addressBook.followingFetcher {
                ListView<AddressModel, ListRow<AddressModel>, EmptyView>(filters: .none, data: fetcher.listItems, rowBuilder: { _ in return nil as ListRow<AddressModel>? })
            }
        case .followingStatuses:
            if let fetcher = addressBook.followingStatusLogFetcher {
                StatusList(fetcher: fetcher, addresses: fetcher.addresses)
            }
        case .addressFollowing(let name):
            ListView<AddressModel, ListRow<AddressModel>, EmptyView>(filters: .none, data: fetchConstructor.followingFetcher(for: name, credential: accountModel.credential(for: name, in: addressBook)).listItems, rowBuilder: { _ in return nil as ListRow<AddressModel>? })
        case .nowGarden:
            GardenView(fetcher: addressBook.gardenFetcher)
        case .pastebin(let address):
            AddressPasteView(fetcher: addressBook.addressSummary(address).pasteFetcher)
        case .purls(let address):
            AddressPURLsView(address: address)
        case .purl(let address, title: let title):
            PURLView(address: address, title: title)
        case .paste(let address, title: let title):
            PasteView(address: address, title: title)
        case .statusLog(let address):
            StatusList(fetcher: addressBook.addressSummary(address).statusFetcher, addresses: [address])
        case .status(let address, id: let id):
            StatusView(fetcher: fetchConstructor.statusFetcher(id, from: address))
        case .account:
            AccountView(addressBook: addressBook, accountModel: accountModel)
        case .myStatuses:
            MyStatusesView(singleAddress: false, addressBook: addressBook, accountModel: accountModel)
        case .myPURLs:
            MyPURLsView(singleAddress: false, addressBook: addressBook, accountModel: accountModel)
        case .editPURL(let address, title: let title):
            if let credential = accountModel.credential(for: address, in: addressBook) {
                NamedItemDraftView(fetcher: fetchConstructor.draftPurlPoster(title, for: address, credential: credential))
            } else {
                // Unauthorized
                EmptyView()
            }
        case .myPastes:
            MyPastesView(singleAddress: false, addressBook: addressBook, accountModel: accountModel)
        case .editPaste(let address, title: let title):
            if let credential = accountModel.credential(for: address, in: addressBook) {
                NamedItemDraftView(fetcher: fetchConstructor.draftPastePoster(title, for: address, credential: credential))
            } else {
                // Unauthorized
                EmptyView()
            }
//        case .editWebpage(let name):
//            if let poster = addressBook.profilePoster(for: name) {
//                EditPageView(poster: poster)
//            } else {
//                // Unauthenticated
//                EmptyView()
//            }
//        case .editNow(let name):
//            if let poster = addressBook.nowPoster(for: name) {
//                EditPageView(poster: poster)
//            } else {
//                // Unauthenticated
//                EmptyView()
//            }
        case .editStatus(let address, id: let id):
            if address == .autoUpdatingAddress && id.isEmpty {
                StatusDraftView(draftPoster: fetchConstructor.draftStatusPoster(for: address, credential: accountModel.authKey))
            } else if let credential = accountModel.credential(for: address, in: addressBook) {
                StatusDraftView(draftPoster: fetchConstructor.draftStatusPoster(id, for: address, credential: credential))
            } else {
                // Unauthenticated
                EmptyView()
            }
        case .addressStatuses:
            MyStatusesView(singleAddress: true, addressBook: addressBook, accountModel: accountModel)
        case .addressPURLs:
            MyPURLsView(singleAddress: true, addressBook: addressBook, accountModel: accountModel)
        case .addressPastes:
            MyPastesView(singleAddress: true, addressBook: addressBook, accountModel: accountModel)
        default:
            EmptyView()
        }
    }
}
