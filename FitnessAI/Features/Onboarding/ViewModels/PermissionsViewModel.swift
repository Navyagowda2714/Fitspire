//
//  PermissionsViewModel.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//
import Foundation
import AVFoundation
import UserNotifications

struct PermissionItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: String
    var isGranted: Bool = false
}

@MainActor
final class PermissionsViewModel: ObservableObject {
    @Published var permissions: [PermissionItem] = []
    @Published var allPermissionsHandled: Bool = false

    init() {
        permissions = [
            PermissionItem(title: "Camera", subtitle: "For real-time pose detection", icon: "camera.viewfinder", color: "534AB7"),
            PermissionItem(title: "Notifications", subtitle: "Workout reminders and alerts", icon: "bell.badge", color: "1D9E75"),
            PermissionItem(title: "HealthKit", subtitle: "Read and save workout data", icon: "heart.text.square", color: "D85A30")
        ]
    }

    func requestAllPermissions() async {
        await requestCamera()
        await requestNotifications()
        allPermissionsHandled = true
    }

    private func requestCamera() async {
        let status = await AVCaptureDevice.requestAccess(for: .video)
        updatePermission(title: "Camera", granted: status)
    }

    private func requestNotifications() async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        updatePermission(title: "Notifications", granted: granted)
    }

    private func updatePermission(title: String, granted: Bool) {
        if let index = permissions.firstIndex(where: { $0.title == title }) {
            permissions[index].isGranted = granted
        }
    }
}
