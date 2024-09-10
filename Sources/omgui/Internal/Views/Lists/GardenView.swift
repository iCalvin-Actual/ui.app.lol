//
//  File 2.swift
//  
//
//  Created by Calvin Chestnut on 3/15/23.
//

import SwiftUI

struct GardenView: View {
    
    @ObservedObject
    var fetcher: NowGardenDataFetcher
    
    var body: some View {
        ListView<NowListing, GardenItemView, EmptyView>(dataFetcher: fetcher, rowBuilder: { GardenItemView(model: $0) })
            .toolbarRole(.editor)
    }
}

struct GardenItemView: View {
    var model: NowListing
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(model.listTitle)
                    .font(.title3)
                    .bold()
                    .foregroundColor(.black)
                Spacer()
                AddressIconView(address: model.addressName)
            }
            
            let subtitle = model.listSubtitle
            let caption = model.listCaption ?? ""
            let hasMoreText: Bool = !subtitle.isEmpty || !caption.isEmpty
            if hasMoreText {
                HStack(alignment: .bottom) {
                    Text(subtitle)
                        .font(.subheadline)
                        .fontDesign(.monospaced)
                        .foregroundColor(.black.opacity(0.8))
                        .bold()
                    Spacer()
                    Text(caption)
                        .foregroundColor(.gray.opacity(0.6))
                        .font(.subheadline)
                        .fontDesign(.rounded)
                }
            }
        }
        .asCard(color: .lolRandom(model.listTitle), padding: 4, radius: 8)
        .fontDesign(.serif)
        .padding(2)
    }
}
