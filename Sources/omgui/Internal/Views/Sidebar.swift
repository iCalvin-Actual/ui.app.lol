//
//  File.swift
//  
//
//  Created by Calvin Chestnut on 3/8/23.
//

import SwiftUI

struct Sidebar: View {
    
    @Environment(\.horizontalSizeClass)
    var horizontalSize
    @EnvironmentObject
    var sceneModel: SceneModel
    
    @Binding
    var selected: NavigationItem?
    
    @ObservedObject
    var sidebarModel: SidebarModel
    
    init(selected: Binding<NavigationItem?>, model: SidebarModel) {
        self._selected = selected
        self.sidebarModel = model
    }
    
    @State
    var showConfirmLogout: Bool = false
    
    var body: some View {
        NavigationStack {
            List(selection: $selected) {
                ForEach(sidebarModel.sections) { section in
                    let items = sidebarModel.items(for: section)
                    if !items.isEmpty {
                        Section {
                            ForEach(items) { item in
                                item.sidebarView
                                    .tag(item)
                                    .contextMenu(menuItems: {
                                        item.contextMenu(in: sceneModel)
                                    })
                            }
                        } header: {
                            HStack {
                                Text(section.displayName)
                                    .fontDesign(.monospaced)
                                    .font(.subheadline)
                                    .bold()
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .safeAreaInset(edge: .top) {
            if sidebarModel.addressBook.accountModel.signedIn {
                ZStack {
                    NavigationLink(value: NavigationDestination.address(sidebarModel.actingAddress)) {
                        EmptyView()
                    }
                    .opacity(0)
                    
                    ListRow<AddressModel>(model: .init(name: sidebarModel.actingAddress), preferredStyle: .minimal)
                }
                .padding(.horizontal)
            }
        }
        .safeAreaInset(edge: .bottom, content: {
            if !sidebarModel.addressBook.accountModel.signedIn {
                Button {
                    DispatchQueue.main.async {
                        Task {
                            await sidebarModel.addressBook.accountModel.authenticate()
                        }
                    }
                } label: {
                    Label {
                        Text("Sign in")
                    } icon: {
                        Image("prami", bundle: .module)
                            .resizable()
                            .frame(width: 33, height: 33)
                    }
                }
                .bold()
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.lolRandom())
                .cornerRadius(16)
                .padding(.horizontal)
            }
        })
        .alert("Logout", isPresented: $showConfirmLogout) {
            Button("Cancel", role: .cancel) { }
            Button("Yes", role: .destructive) {
                sidebarModel.addressBook.accountModel.logout()
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                ThemedTextView(text: "app.lol")
            }
            ToolbarItem(placement: .topBarTrailing) {
                if sidebarModel.addressBook.accountModel.signedIn {
                    Menu {
                        addressPickerSection
                        
                        Button(role: .destructive) {
                            self.showConfirmLogout.toggle()
                        } label: {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private func isActingAddress(_ address: AddressName) -> Bool {
        sidebarModel.addressBook.actingAddress == address
    }
    
    @ViewBuilder
    private var addressPickerSection: some View {
        if !sidebarModel.addressBook.myAddresses.isEmpty {
            Section {
                ForEach(sidebarModel.addressBook.myAddresses) { address in
                    Button {
                        sidebarModel.addressBook.setActiveAddress(address)
                    } label: {
                        addressOption(address)
                    }
                }
            } header: {
                Text("Select active address")
            }
        }
    }
    
    @ViewBuilder
    private func addressOption(_ address: AddressName) -> some View {
        if isActingAddress(address) {
            Label(address, systemImage: "checkmark")
        } else {
            Label(title: { Text(address) }, icon: { EmptyView() })
        }
    }
}
