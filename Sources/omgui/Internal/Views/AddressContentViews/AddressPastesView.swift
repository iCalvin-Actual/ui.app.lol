//
//  File.swift
//  
//
//  Created by Calvin Chestnut on 3/8/23.
//

import SwiftUI

struct AddressPastesView: View {
    @ObservedObject
    var fetcher: AddressPasteBinDataFetcher
    
    var body: some View {
        ListView<PasteModel, PasteRowView, EmptyView>(
            filters: .everyone,
            dataFetcher: fetcher,
            rowBuilder: { PasteRowView(model: $0) }
        )
    }
}
