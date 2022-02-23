//
//  ContentView.swift
//  CustomVideoSeeker2
//
//  Created by Stanley Pan on 2022/02/23.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        NavigationView {
            HomeView()
                .navigationTitle("")
                .navigationBarHidden(true)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
