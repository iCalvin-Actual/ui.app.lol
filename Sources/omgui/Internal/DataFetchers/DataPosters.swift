//
//  File.swift
//  omgui
//
//  Created by Calvin Chestnut on 7/29/24.
//

import Combine
import SwiftUI


@MainActor
class DraftPoster<D: SomeDraftable>: Request {
    var address: AddressName
    let credential: APICredential
    
    @Published
    var draft: D.Draft
    var originalDraft: D.Draft?
    
    @Published
    var result: D?
    
    var navigationTitle: String {
        "New"
    }
    
    init(_ address: AddressName, draft: D.Draft, interface: DataInterface, credential: APICredential) {
        self.address = address
        self.credential = credential
        self.draft = draft
        self.originalDraft = draft
        super.init(interface: interface)
    }
    
    func deletePresented() {
        // Override
    }
}

class MDDraftPoster<D: MDDraftable>: DraftPoster<D> {
    
    var mdDraft: D.MDDraftItem
    override var draft: D.Draft {
        get {
            mdDraft as! D.Draft
        }
        set {
            guard let md = newValue as? D.MDDraftItem else {
                return
            }
            mdDraft = md
        }
    }
    
    init?(_ address: AddressName, draftItem: D.MDDraftItem, interface: DataInterface, credential: APICredential) {
        self.mdDraft = draftItem
        super.init(address, draft: draftItem as! D.Draft, interface: interface, credential: credential)
    }
}

class NamedDraftPoster<D: NamedDraftable>: DraftPoster<D> {
    let title: String
    
    let onPost: (D) -> Void
    
    @Published
    var namedDraft: D.NamedDraftItem
    
    override var draft: D.Draft {
        get {
            namedDraft as! D.Draft
        }
        set {
            guard let named = newValue as? D.NamedDraftItem else {
                return
            }
            namedDraft = named
        }
    }
    
    init(
        _ address: AddressName,
        title: String,
        content: String = "",
        interface: DataInterface,
        credential: APICredential,
        onPost: ((D) -> Void)? = nil
    ) {
        self.title = title
        let namedDraft = D.NamedDraftItem(address: address, name: title, content: content, listed: true)
        self.namedDraft = namedDraft
        self.onPost = onPost ?? { _ in }
        super.init(
            address,
            draft: namedDraft as! D.Draft,
            interface: interface,
            credential: credential
        )
    }
    
    override func deletePresented() {
        print("Delete")
    }
}

class ProfileDraftPoster: MDDraftPoster<AddressProfile> {
    override var navigationTitle: String {
        "webpage"
    }
    
    @MainActor
    override func throwingRequest() async throws {
        loading = true
        let draftedAddress = address
        let _ = try await interface.saveAddressProfile(
            draftedAddress,
            content: draft.content,
            credential: credential
        )
        originalDraft = draft
        fetchFinished()
    }
}

class NowDraftPoster: MDDraftPoster<NowModel> {
    override var navigationTitle: String {
        "/now"
    }
    
    override func throwingRequest() async throws {
        let draftedAddress = address
        let _ = try await interface.saveAddressNow(
            draftedAddress,
            content: draft.content,
            credential: credential
        )
        originalDraft = draft
        fetchFinished()
    }
}

class PasteDraftPoster: NamedDraftPoster<PasteModel> {
    override var navigationTitle: String {
        if originalDraft == nil {
            return "new paste"
        }
        return "edit"
    }
    
    @MainActor
    override func throwingRequest() async throws {
        let draftedAddress = draft.address
        if let originalName = originalDraft?.name, !originalName.isEmpty, draft.name != originalName {
            try await interface.deletePaste(originalName, from: draftedAddress, credential: credential)
        }
        if let result = try await interface.savePaste(draft, to: draftedAddress, credential: credential) {
            self.result = result
            onPost(result)
        }
        fetchFinished()
    }
}

class PURLDraftPoster: NamedDraftPoster<PURLModel> {
    override var navigationTitle: String {
        if originalDraft == nil {
            return "new PURL"
        }
        return "edit"
    }
    override func throwingRequest() async throws {
        let draftedAddress = draft.address
        if let originalName = originalDraft?.name, !originalName.isEmpty, draft.name != originalName {
            try await interface.deletePURL(originalName, from: draftedAddress, credential: credential)
        }
        if let result = try await interface.savePURL(draft, to: draftedAddress, credential: credential) {
            self.result = result
            onPost(result)
        }
        fetchFinished()
    }
    
    var destination: String
    
    init(
        _ address: AddressName = .autoUpdatingAddress,
        title: String = "",
        value: String = "",
        interface: DataInterface,
        credential: APICredential = "",
        onPost: ((PURLModel) -> Void)? = nil
    ) {
        destination = value
        super.init(
            address,
            title: title,
            content: value,
            interface: interface,
            credential: credential,
            onPost: onPost
        )
    }
    
    func newDraft() -> PURLDraftPoster {
        .init(
            address,
            title: title,
            value: destination,
            interface: interface,
            credential: credential,
            onPost: onPost
        )
    }
}

@MainActor
class StatusDraftPoster: DraftPoster<StatusModel> {
    override var navigationTitle: String {
        if originalDraft == nil {
            if address != .autoUpdatingAddress {
                return address.addressDisplayString
            }
            return "new status"
        }
        return "edit"
    }
    
    override func throwingRequest() async throws {
        let draftedAddress = draft.address
        if let posted = try await interface.saveStatusDraft(draft, to: draftedAddress, credential: credential) {
            withAnimation { [weak self] in
                guard let self else {
                    return
                }
                result = posted
                draft = .init(address: address, content: "", emoji: "")
            }
        }
        
        fetchFinished()
    }
    
    func fetchCurrentValue() async {
        guard let id = draft.id else {
            loading = false
            return
        }
        let draftedAddress = address
        if let status = try? await interface.fetchAddressStatus(id, from: draftedAddress) {
            draft.emoji = status.emoji ?? ""
            draft.content = status.status
            draft.externalUrl = status.link?.absoluteString
            loading = false
            threadSafeSendUpdate()
        } else {
            loading = false
        }
    }
    
    override func deletePresented() {
        guard let presented = result else {
            return
        }
        let patchDraft = StatusModel.Draft(model: presented, id: presented.id)
        Task { [weak self] in
            guard let self else { return }
            let draftedAddress = draft.address
            let backup = try await interface.deleteAddressStatus(patchDraft, from: draftedAddress, credential: credential)
            withAnimation {
                if let backup {
                    self.draft = .init(model: backup)
                }
                self.result = nil
            }
        }
    }
}