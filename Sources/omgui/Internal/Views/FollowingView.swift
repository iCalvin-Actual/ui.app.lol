//
//  File.swift
//  
//
//  Created by Calvin Chestnut on 3/13/23.
//

import Combine
import SwiftUI

struct FollowingView: View {
    
    @ObservedObject
    var addressBook: AddressBook
    
    var requests: [AnyCancellable] = []
    
    @State
    var needsRefresh: Bool = false
    
    init(_ addressBook: AddressBook) {
        self.addressBook = addressBook
    }
    
    var body: some View {
        followingView
            .onAppear(perform: { needsRefresh = false })
    }
    
    @ViewBuilder
    var followingView: some View {
        StatusList(addresses: addressBook.following)
    }
    
    @ViewBuilder
    var signedOutView: some View {
        Text("Signed Out")
    }
}
