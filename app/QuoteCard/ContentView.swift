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

            Text("appName", tableName: "Localizable")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("appTagline", tableName: "Localizable")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Divider()
                .padding(.vertical)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Image(systemName: "1.circle.fill")
                        .foregroundColor(.accentColor)
                    Text("step1", tableName: "Localizable")
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(alignment: .top) {
                    Image(systemName: "2.circle.fill")
                        .foregroundColor(.accentColor)
                    Text("step2", tableName: "Localizable")
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(alignment: .top) {
                    Image(systemName: "3.circle.fill")
                        .foregroundColor(.accentColor)
                    Text("step3", tableName: "Localizable")
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .font(.body)
            .padding()

            Spacer()

            Button(String(localized: "openSafariExtensions", table: "Localizable")) {
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
