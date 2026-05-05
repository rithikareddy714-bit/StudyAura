import SwiftUI

struct ContentView: View {
    @StateObject private var store = StudyStore()

    var body: some View {
        HomeView()
            .environmentObject(store)
    }
}
