//
//  ContentView.swift
//  QuoteCard
//
//  Main window content
//

import SwiftUI
import SafariServices

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image("LogoIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.accentColor)

            Text("QuoteCard")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Create beautiful quote cards from selected text")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Divider()
                .padding(.vertical)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "1.circle.fill")
                        .foregroundColor(.accentColor)
                    Text("Open Safari and enable the QuoteCard extension")
                }

                HStack {
                    Image(systemName: "2.circle.fill")
                        .foregroundColor(.accentColor)
                    Text("Select text on any webpage")
                }

                HStack {
                    Image(systemName: "3.circle.fill")
                        .foregroundColor(.accentColor)
                    Text("Right-click and choose 'Create QuoteCard'")
                }
            }
            .font(.body)
            .padding()

            Spacer()

            Button("Open Safari Extensions") {
                SFSafariApplication.showPreferencesForExtension(withIdentifier: "com.markallen.QuoteCard.Extension") { error in
                    if let error = error {
                        print("Error opening Safari extension preferences: \(error)")
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(width: 500, height: 500)
    }
}

#Preview {
    ContentView()
}
