//
//  File.swift
//  
//
//  Created by Calvin Chestnut on 2/10/23.
//

import SwiftUI
import Foundation

@available(iOS 16.1, *)
struct ListModel<T: Listable> {
    private let sort: Sort
    private let filters: [FilterOption]
    
    init(sort: Sort = .alphabet, filters: [FilterOption] = .everyone) {
        self.sort = sort
        self.filters = filters
    }
    
    func apply(to inputModels: [T], with account: AccountModel) -> [T] {
        inputModels
            .filter({ $0.include(with: filters, account: account) })
            .shuffled()
            .sorted(with: sort)
    }
}

@available(iOS 16.1, *)
struct BlockList<T: Listable, V: View>: View {
    
    let model: ListModel<T>
    let modelBuilder: () -> [T]
    @ViewBuilder let rowBuilder: ((T) -> V?)
    
    @Binding
    var selected: T?
    
    var context: Context = .column
    
    @State
    var queryString: String = ""
    
    @EnvironmentObject
    var appModel: AppModel
    
    @Binding
    var sort: Sort
    
    init(model: ListModel<T>, modelBuilder: @escaping () -> [T], rowBuilder: @escaping (T) -> V?, selected: Binding<T?>, context: Context, sort: Binding<Sort>) {
        self.model = model
        self.modelBuilder = modelBuilder
        self.rowBuilder = rowBuilder
        self._selected = selected
        self.context = context
        self._sort = sort
    }
    
    var items: [T] {
        model.apply(to: modelBuilder(), with: appModel.accountModel)
            .filter { model in
                guard !queryString.isEmpty else {
                    return true
                }
                guard let queryable = model as? QueryFilterable else {
                    return false
                }
                return queryable.matches(queryString)
            }
    }
    
    var body: some View {
        List(items, selection: $selected, rowContent: rowView(_:))
            .searchable(text: $queryString, placement: .sidebar)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SortOrderMenu(sort: $sort)
                }
            })
    }
    
    @ViewBuilder
    func rowView(_ item: T) -> some View {
        ZStack(alignment: .leading) {
            if context != .profile {
                NavigationLink(value: NavigationDetailView.profile(.init(item.addressName))) {
                    EmptyView()
                }
                .opacity(0)
            }
            
            buildRow(item)
        }
    }
    
    @ViewBuilder
    func buildRow(_ item: T) -> some View {
        if let constructedView = rowBuilder(item) {
            constructedView
        } else {
            ListItem<T>(model: item)
        }
    }
}

@available(iOS 16.1, *)
struct ListItem<T: Listable>: View {
    let model: T
    
    @Environment(\.isSearching) var isSearching
    
    var narrow: Bool {
        isSearching
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if !narrow {
                Spacer()
            }
            Text(model.listTitle)
                .font(.title)
                .bold()
                .padding(.vertical, !narrow ? 8 : 0)
                .padding(.bottom, 4)
                .padding(.trailing, 4)
            
            
            HStack(alignment: .bottom) {
                if !narrow {
                    Text(model.listSubtitle)
                        .font(.headline)
                        .bold()
                    Spacer()
                    Text(model.listCaption ?? "")
                        .font(.subheadline)
                } else {
                    Spacer()
                }
            }
            .padding(.trailing)
        }
        .padding(.vertical)
        .padding(.leading, 32)
        .background(Color.yellow)
        .cornerRadius(24)
        .fontDesign(.serif)
    }
}