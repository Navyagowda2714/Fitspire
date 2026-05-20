//
//  PermissionsView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

//
//  PermissionsView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

import SwiftUI
import AVFoundation
import UserNotifications

struct PermissionsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = PermissionsViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Allow access")
                    .font(.system(size: 28, weight: .medium))
                Text("FitnessAI needs these to work.\nYou can change them in Settings anytime.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appT3)
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 32)

            VStack(spacing: 0) {
                ForEach(viewModel.permissions) { perm in
                    PermissionRowView(permission: perm)
                    if perm.id != viewModel.permissions.last?.id {
                        Divider().padding(.leading, 72)
                    }
                }
            }
            .background(Color.appBG)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
            )
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 8) {
                Button {
                    Task { await viewModel.requestAllPermissions() }
                } label: {
                    Text("Allow all and continue")
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.appLime)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Text("You can enable individual permissions in Settings anytime.")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onChange(of: viewModel.allPermissionsHandled) { _, handled in
            if handled {
                appState.markOnboardingComplete()
            }
        }
    }
}

struct PermissionRowView: View {
    let permission: PermissionItem

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: permission.color).opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: permission.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: permission.color))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(permission.title)
                    .font(.system(size: 14, weight: .medium))
                Text(permission.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appT3)
            }
            Spacer()
            Image(systemName: permission.isGranted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundStyle(
                    permission.isGranted
                    ? Color.appGood
                    : Color.secondary.opacity(0.4)
                )
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
    }
}
