//
//  File.swift
//  
//
//  Created by Calvin Chestnut on 3/8/23.
//

import Combine
import SwiftUI

struct StatusList: View {
    let fetcher: StatusLogDataFetcher
    
    @Environment(SceneModel.self)
    var sceneModel: SceneModel
    @Environment(\.horizontalSizeClass)
    var sizeClass
    
    let filters: [FilterOption] = []
    
    var menuBuilder: ContextMenuBuilder<StatusModel>?
    
    var body: some View {
        ModelBackedListView<StatusModel, StatusRowView, EmptyView>(
            filters: .everyone,
            dataFetcher: fetcher,
            rowBuilder: { StatusRowView(model: $0) }
        )
        .toolbarRole(.editor)
    }
}
