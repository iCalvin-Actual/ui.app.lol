//
//  SwiftUIView.swift
//  
//
//  Created by Calvin Chestnut on 6/17/24.
//

import SwiftUI

@MainActor
struct NavigationView: View {
    @Environment(\.horizontalSizeClass)
    var horizontalSizeClass
    
    var body: some View {
        SplitView()
    }
    
    @ViewBuilder
    var appropriateNavigation: some View {
        switch horizontalSizeClass {
        case .compact:
            TabBar()
        default:
            SplitView()
        }
    }
}

#Preview {
    NavigationView()
}
