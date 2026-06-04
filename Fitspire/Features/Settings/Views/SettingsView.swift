//
//  SettingsView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 06/05/2026.
//


//
//  SettingsView.swift
//  Fitspire
//
//  Created by Navyashree Byregowda on 06/05/2026.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showPrivacySheet = false
    @State private var showExportSheet  = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBG.ignoresSafeArea()
                List {
                    // MARK: - Profile
                    Section {
                        profileRow
                            .listRowBackground(Color.appBG2)
                    } header: { sectionHeader("Profile") }

                    // MARK: - App settings
                    Section {
                        notificationsRow
                            .listRowBackground(Color.appBG2)
                        healthKitRow
                            .listRowBackground(Color.appBG2)
                        cloudSyncRow
                            .listRowBackground(Color.appBG2)
                    } header: { sectionHeader("App settings") }

                    // MARK: - Privacy
                    Section {
                        Button { showPrivacySheet = true } label: {
                            SettingsRow(icon: "lock.shield.fill", iconColor: "534AB7",
                                        title: "Privacy and data",
                                        subtitle: "See what data Fitspire stores")
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.appBG2)

                        Button { Task { await viewModel.exportData(context: context) } } label: {
                            SettingsRow(icon: "square.and.arrow.up.fill", iconColor: "1D9E75",
                                        title: "Export my data",
                                        subtitle: "Download all your data as JSON",
                                        isLoading: viewModel.isExporting)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.appBG2)
                    } header: { sectionHeader("Privacy") }

                    // MARK: - About
                    Section {
                        SettingsRow(icon: "info.circle.fill", iconColor: "888780",
                                    title: "Version", subtitle: "Fitspire 1.0.0 (Build 1)")
                            .listRowBackground(Color.appBG2)

                        Link(destination: URL(string: "https://github.com/Navyagowda2714/CH-7-Champagne")!) {
                            SettingsRow(icon: "chevron.left.forwardslash.chevron.right",
                                        iconColor: "888780",
                                        title: "Source code", subtitle: "View on GitHub")
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.appBG2)
                    } header: { sectionHeader("About") }

                    // MARK: - Account
                    Section {
                        Button { viewModel.showDeleteConfirm = true } label: {
                            SettingsRow(icon: "trash.fill", iconColor: "D85A30",
                                        title: "Delete account",
                                        subtitle: "Permanently delete all your data",
                                        isDanger: true)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.appBG2)

                        Button { appState.signOut() } label: {
                            SettingsRow(icon: "rectangle.portrait.and.arrow.right",
                                        iconColor: "888780",
                                        title: "Sign out",
                                        subtitle: "You can sign back in anytime")
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.appBG2)
                    } header: { sectionHeader("Account") }

                    // Disclaimer
                    Section {
                        Text("Fitspire provides general fitness and nutrition guidance only. It is not medical advice. Consult a qualified healthcare professional before starting any new workout or nutrition programme.")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.appT3)
                            .listRowBackground(Color.clear)
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.large)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .alert("Delete all data?", isPresented: $viewModel.showDeleteConfirm) {
                    Button("Delete everything", role: .destructive) {
                        Task { await viewModel.deleteAllData(context: context, appState: appState) }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This permanently deletes your profile, scan history, workout plans, and meal plans. This cannot be undone.")
                }
                .alert("Export ready", isPresented: $viewModel.showExportSuccess) {
                    if viewModel.exportURL != nil { Button("Share") { showExportSheet = true } }
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Your data has been exported successfully.")
                }
                .sheet(isPresented: $showPrivacySheet) { PrivacyDataView() }
                .sheet(isPresented: $showExportSheet) {
                    if let url = viewModel.exportURL { ShareSheet(items: [url]) }
                }
            }
        }
        .onAppear { viewModel.checkNotificationStatus() }
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.appT3)
            .tracking(0.8)
    }

    private var profileRow: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.appLime.opacity(0.15))
                    .frame(width: 46, height: 46)
                Text(String(appState.userProfile?.name.prefix(1) ?? "A"))
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Color.appLime)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(appState.userProfile?.name ?? "Your profile")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text(appState.selectedGoal?.rawValue ?? "No goal set")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appT3)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(Color.appT4)
        }
        .padding(.vertical, 4)
    }

    private var notificationsRow: some View {
        Button { viewModel.openNotificationSettings() } label: {
            SettingsRow(icon: "bell.badge.fill", iconColor: "BA7517",
                        title: "Notifications",
                        subtitle: viewModel.notificationsEnabled ? "Enabled" : "Tap to enable in Settings",
                        showChevron: true)
        }
        .buttonStyle(.plain)
    }

    private var healthKitRow: some View {
        Button { viewModel.openHealthSettings() } label: {
            SettingsRow(icon: "heart.fill", iconColor: "D85A30",
                        title: "Apple Health",
                        subtitle: "Manage HealthKit permissions",
                        showChevron: true)
        }
        .buttonStyle(.plain)
    }

    private var cloudSyncRow: some View {
        HStack {
            SettingsRow(icon: "icloud.fill", iconColor: "378ADD",
                        title: "iCloud sync",
                        subtitle: viewModel.cloudSyncEnabled ? "Your data syncs to iCloud" : "Data stored on device only")
            Spacer()
            Toggle("", isOn: $viewModel.cloudSyncEnabled)
                .labelsHidden()
                .tint(Color.appCyan)
                .onChange(of: viewModel.cloudSyncEnabled) { _, _ in viewModel.toggleCloudSync() }
        }
    }
}

// MARK: - SettingsRow

struct SettingsRow: View {
    let icon:        String
    let iconColor:   String
    let title:       String
    let subtitle:    String
    var showChevron: Bool = false
    var isDanger:    Bool = false
    var isLoading:   Bool = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: iconColor).opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: iconColor))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isDanger ? Color.appMove : .white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appT3)
            }
            Spacer()
            if isLoading {
                SwiftUI.ProgressView().scaleEffect(0.8)
            } else if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appT3)
            }
        }
        .padding(.vertical, 4)
    }
}
