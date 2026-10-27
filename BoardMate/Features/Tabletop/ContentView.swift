//
//  ContentView.swift
//  BoardMate
//
//  Created by 양호준 on 10/27/26.
//

import SwiftUI

struct ContentView: View {
    let session: BoardMateSession

    var body: some View {
        TabletopView(session: session)
    }
}
